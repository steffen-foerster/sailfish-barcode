/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#include <QDebug>
#include "AutoBarcodeScanner.h"
#include <QProcess>
#include <QStandardPaths>
#include <QtDBus/QDBusMessage>
#include <QtDBus/QDBusConnection>

AutoBarcodeScanner::AutoBarcodeScanner(QObject * parent) : QObject(parent)
{
    qDebug() << "start init AutoBarcodeScanner";

    m_camera = new QCamera(this);
    m_decoder = new BarcodeDecoder(this);
    m_imageCapture = new QCameraImageCapture(m_camera, this);

    m_camera->exposure()->setExposureCompensation(2.0);
    m_camera->exposure()->setExposureMode(QCameraExposure::ExposureAuto);
    m_camera->exposure()->setFlashMode(QCameraExposure::FlashOff);

    m_camera->focus()->zoomTo(1.0, 3.0);
    m_camera->focus()->setFocusMode(QCameraFocus::ContinuousFocus);
    m_camera->focus()->setFocusPointMode(QCameraFocus::FocusPointAuto);

    m_flagComponentComplete = false;
    m_flagScanRunning = false;
    m_flagScanAbort = false;

    createConnections();
    createTimer();
}

AutoBarcodeScanner::~AutoBarcodeScanner() {
    qDebug() << "AutoBarcodeScanner::~AutoBarcodeScanner";

    // stopping a running scanning process
    m_scanProcessMutex.lock();
    if (m_flagScanRunning) {
        m_flagScanAbort = true;
        qDebug() << "m_scanProcessStopped.wait";
        m_scanProcessStopped.wait(&m_scanProcessMutex);
    }
    m_scanProcessMutex.unlock();

    if (m_camera->state() == QCamera::ActiveState) {
        qDebug() << "stopping camera ...";
        m_camera->stop();
    }
}

void AutoBarcodeScanner::createConnections() {
    // error handling
    connect(m_camera, SIGNAL(error(QCamera::Error)), this, SLOT(slotCameraError(QCamera::Error)));

    // for debugging
    connect(m_camera, SIGNAL(statusChanged(QCamera::Status)),
            this, SLOT(slotStatusChanged(QCamera::Status)));
    connect(m_camera, SIGNAL(stateChanged(QCamera::State)),
            this, SLOT(slotStateChanged(QCamera::State)));
}

void AutoBarcodeScanner::createTimer() {
    m_timeoutTimer = new QTimer(this);
    m_timeoutTimer->setSingleShot(true);
    connect(m_timeoutTimer, SIGNAL(timeout()), this, SLOT(slotScanningTimeout()));
}

void AutoBarcodeScanner::classBegin() {
}

void AutoBarcodeScanner::componentComplete() {
    m_flagComponentComplete = true;
}

void AutoBarcodeScanner::setDecoderFormat(int format) {
    m_decoder->setDecoderFormat(format);
}

void AutoBarcodeScanner::startCamera() {
    qDebug() << "camera has state: " << m_camera->state();

    if (isJollaCameraRunning()) {
        qDebug() << "jolla camera is running";
        emit error(AutoBarcodeScanner::JollaCameraRunning);
        return;
    }

    if (m_camera->state() != QCamera::ActiveState) {
        if (m_camera->availability() != QMultimedia::Available) {
            qDebug() << "camera is not available";
            emit error(AutoBarcodeScanner::CameraUnavailable);
            return;
        }

        qDebug() << "starting camera ...";
        m_camera->start();
    }
    else {
        qDebug() << "camera is already started";
    }
}

void AutoBarcodeScanner::slotStateChanged(QCamera::State state) {
    qDebug() << "camera state changed: " << state;

    if (m_camera->state() == QCamera::ActiveState) {
        emit cameraStarted();
    }
}

void AutoBarcodeScanner::startScanning(int timeout) {
    if (m_flagScanRunning) {
        qDebug() << "abort: scan is running";
        return;
    }

    if (isJollaCameraRunning()) {
        qDebug() << "jolla camera is running";
        emit error(AutoBarcodeScanner::JollaCameraRunning);
        return;
    }

    if (m_camera->availability() != QMultimedia::Available) {
        qDebug() << "camera is not available";
        emit error(AutoBarcodeScanner::CameraUnavailable);
        return;
    }

    m_flagScanRunning = true;
    m_flagScanAbort = false;
    m_timeoutTimer->start(timeout);

    QtConcurrent::run(this, &AutoBarcodeScanner::processDecode);
}

bool AutoBarcodeScanner::isJollaCameraRunning() {
    QProcess *process = new QProcess();
    QString cmd = "/bin/sh";
    QStringList args;
    args << "-c" << "ps -A | grep jolla-camera";
    process->start(cmd, args);

    bool result = false;
    if (process->waitForFinished()) {
        QString output = "";
        output.append(process->readAllStandardOutput());
        qDebug() << "result of ps command: " << output;
        result = output.contains("jolla-camera", Qt::CaseInsensitive);
    }
    delete process;
    return result;
}

/**
 * Runs in a pooled thread.
 */
void AutoBarcodeScanner::processDecode() {
    qDebug() << "processDecode() is called from " << QThread::currentThread();

    bool scanActive = true;
    QString code = "";

    while (scanActive) {
        // timeout timer and deconstructor can abort scan process
        m_scanProcessMutex.lock();
        scanActive = !m_flagScanAbort;
        if (!scanActive) {
            qDebug() << "decoding aborted";
        }
        m_scanProcessMutex.unlock();

        if (scanActive) {
            QDBusMessage m = QDBusMessage::createMethodCall("org.nemomobile.lipstick", "/org/nemomobile/lipstick/screenshot", "org.nemomobile.lipstick", "saveScreenshot");
            m << m_decoder->getCaptureLocation();
            QDBusConnection::sessionBus().call(m);

            QImage screenshot(m_decoder->getCaptureLocation());

            // crop the image - we need only the viewfinder
            QImage copy = screenshot.copy(m_viewFinderRect);
            copy.save(m_decoder->getCaptureLocation());

            code = m_decoder->decodeBarcodeFromCache();

            if (!code.length()) {
                // try for 1D bar code the other orientation
                QTransform transform;
                transform.rotate(90);
                copy = copy.transformed(transform);
                copy.save(m_decoder->getCaptureLocation());

                code = m_decoder->decodeBarcodeFromCache();
            }

            if (code.length()) {
                m_timeoutTimer->stop();
                scanActive = false;
                qDebug() << "bar code found";
            }
        }
    }

    qDebug() << "decoding has been finished, result: " + code;
    emit decodingFinished(code);


    m_scanProcessMutex.lock();
    m_flagScanRunning = false;

    // wake deconstructor
    qDebug() << "m_scanProcessStopped.wakeAll";
    m_scanProcessStopped.wakeAll();
    m_scanProcessMutex.unlock();
}

void AutoBarcodeScanner::slotScanningTimeout() {
    m_scanProcessMutex.lock();
    m_flagScanAbort = true;
    qDebug() << "decoding aborted by timeout";
    m_scanProcessMutex.unlock();
}

// ------------------------------------------------------------
// Error handling
// ------------------------------------------------------------

void AutoBarcodeScanner::slotCameraError(QCamera::Error value) {
    qDebug() << "camera error occured: " + value;
    m_flagScanRunning = false;

    emit error(AutoBarcodeScanner::CameraError);
}

// ------------------------------------------------------------
// debugging
// ------------------------------------------------------------

void AutoBarcodeScanner::slotStatusChanged(QCamera::Status status) {
    qDebug() << "camera status changed: " << status;
}

