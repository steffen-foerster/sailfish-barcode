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
#include "CaptureImageProvider.h"
#include <QProcess>
#include <QPainter>
#include <QBrush>
#include <QStandardPaths>
#include <QtDBus/QDBusMessage>
#include <QtDBus/QDBusConnection>
#include <QGuiApplication>
#include <QQuickWindow>

#include <iostream>
#include <fstream>

AutoBarcodeScanner::AutoBarcodeScanner(QObject * parent)
    : QObject(parent)
    , m_decoder(new BarcodeDecoder(this))
    , m_camera(new QCamera(this))
    , m_imageCapture(new QCameraImageCapture(m_camera, this))
    , m_flagComponentComplete(false)
    , m_flagScanRunning(false)
    , m_flagScanAbort(false)
    , m_flashState(false)
    , m_timeoutTimer(new QTimer(this))
    , m_markerColor(QColor(0, 255, 0)) // default green
{
    qDebug() << "start init AutoBarcodeScanner";

    m_camera->exposure()->setExposureCompensation(1.0);
    m_camera->exposure()->setExposureMode(QCameraExposure::ExposureAuto);
    m_camera->exposure()->setFlashMode(QCameraExposure::FlashOff);

    m_camera->focus()->zoomTo(1.0, 3.0);
    m_camera->focus()->setFocusMode(QCameraFocus::ContinuousFocus);
    m_camera->focus()->setFocusPointMode(QCameraFocus::FocusPointAuto);

    createConnections();
    m_timeoutTimer->setSingleShot(true);
    connect(m_timeoutTimer, SIGNAL(timeout()), this, SLOT(slotScanningTimeout()));

    QGuiApplication *app = qobject_cast<QGuiApplication*>(qApp);

       foreach (QWindow *win, app->allWindows()) {
           QQuickWindow *quickWin = qobject_cast<QQuickWindow*>(win);
           if (quickWin) {
               m_mainWindow = quickWin;
           }
       }
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

    if (m_flashState) {
        toggleFlash();
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
        qDebug() << "camera has been started already";
    }
}

void AutoBarcodeScanner::toggleFlash() {
    qDebug() << "camera has state: " << m_camera->state();

    if (isJollaCameraRunning()) {
        return;
    }

    m_flashState = !m_flashState;
    writeFlashMode(m_flashState);
    emit flashStateChanged(m_flashState);
}

void AutoBarcodeScanner::writeFlashMode(int flashMode) {
    std::ofstream io;
    io.open("/sys/kernel/debug/flash_adp1650/mode");
    io << flashMode;
    io.close();
}

void AutoBarcodeScanner::zoomTo(qreal digitalZoom) {
    m_camera->focus()->zoomTo(1.0, digitalZoom);
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

void AutoBarcodeScanner::stopScanning() {
    // stopping a running scanning process
    m_scanProcessMutex.lock();
    if (m_flagScanRunning) {
        m_flagScanAbort = true;
        qDebug() << "m_scanProcessStopped.wait";
        m_scanProcessStopped.wait(&m_scanProcessMutex);
    }
    m_scanProcessMutex.unlock();
}

bool AutoBarcodeScanner::isJollaCameraRunning() {
    QProcess process;
    QString cmd = "pidof";
    QStringList args("jolla-camera");
    process.start(cmd, args);

    bool result = false;
    if (process.waitForFinished()) {
        result = (process.exitStatus() == QProcess::NormalExit &&
                  process.exitCode() == 0);
    }

    if (result) {
        emit error(AutoBarcodeScanner::JollaCameraRunning);
    }
    return result;
}

/**
 * Runs in a pooled thread.
 */
void AutoBarcodeScanner::processDecode() {
    qDebug() << "processDecode() is called from " << QThread::currentThread();

    bool scanActive = true;
    QString code;
    QVariantHash result;

    while (scanActive) {
        // timeout timer and deconstructor can abort scan process
        m_scanProcessMutex.lock();
        scanActive = !m_flagScanAbort;
        if (!scanActive) {
            qDebug() << "decoding aborted";
        }
        m_scanProcessMutex.unlock();

        if (scanActive) {
            QImage screenshot = m_mainWindow->grabWindow();
            //maybe
            //saveDebugImage(screenshot, "debug_screenshot.jpg");

            // crop the image - we need only the viewfinder
            QImage copy = screenshot.copy(m_viewFinderRect);
            //maybe
            //copy.save(m_decoder->getCaptureLocation());
            //saveDebugImage(copy, "debug_cropped.jpg");



            qDebug() << "decoding cropped screenshot ...";
            result = m_decoder->decodeBarcodeFromImage(copy);

            copy.save(m_decoder->getCaptureLocation());
            code = result["content"].toString();

            if (code.isEmpty()) {
                // try the other orientation for 1D bar code
                QTransform transform;
                transform.rotate(90);
                copy = copy.transformed(transform);
                //maybe still do it in debug
                copy.save(m_decoder->getCaptureLocation());
                saveDebugImage(copy, "debug_transformed.jpg");

                qDebug() << "decoding rotated screenshot ...";
                result = m_decoder->decodeBarcodeFromImage(copy);
                code = result["content"].toString();
            }

            if (!code.isEmpty()) {
                m_timeoutTimer->stop();
                scanActive = false;
                qDebug() << "bar code found";
            }
        }
    }

    if (!result.empty()) {
        QList<QVariant> points = result["points"].toList();
        markLastCaptureImage(points);
    }

    qDebug() << "decoding has been finished, result: " + code;
    emit decodingFinished(code);

    m_scanProcessMutex.lock();
    m_flagScanRunning = false;
    m_timeoutTimer->stop();

    // wake deconstructor or stopScanning method
    qDebug() << "m_scanProcessStopped.wakeAll";
    m_scanProcessStopped.wakeAll();
    m_scanProcessMutex.unlock();
}

void AutoBarcodeScanner::createScreeshot() {
    if (QFileInfo::exists(m_decoder->getCaptureLocation())) {
        bool removed = QFile::remove(m_decoder->getCaptureLocation());
        qDebug() << "old screeshot file removed: " << removed;
    }

    QDBusMessage m = QDBusMessage::createMethodCall("org.nemomobile.lipstick", "/org/nemomobile/lipstick/screenshot", "org.nemomobile.lipstick", "saveScreenshot");
    m << m_decoder->getCaptureLocation();
    QDBusMessage reply = QDBusConnection::sessionBus().call(m);
    qDebug() << "reply of method call <screenshot>: " << reply;
}

void AutoBarcodeScanner::saveDebugImage(QImage &image, const QString &fileName) {
    QString imageLocation = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + "/codereader/" + fileName;
    image.save(imageLocation);
    qDebug() << "image saved: " << imageLocation;
}

void AutoBarcodeScanner::markLastCaptureImage(QList<QVariant> &points) {
    QImage lastScreenshot(m_decoder->getCaptureLocation());
    QPainter painter(&lastScreenshot);
    painter.setPen(m_markerColor);

    qDebug() << "recognized points: " << points.size();
    for (int i = 0; i < points.size(); i++) {
        QPoint p = points[i].toPoint();
        painter.fillRect(QRect(p.x()-3, p.y()-15, 6, 30), QBrush(m_markerColor));
        painter.fillRect(QRect(p.x()-15, p.y()-3, 30, 6), QBrush(m_markerColor));
    }
    painter.end();

    // rotate to screen orientation
    if (lastScreenshot.width() > lastScreenshot.height()) {
        qDebug() << "rotating image ...";
        QTransform transform;
        transform.rotate(270);
        lastScreenshot = lastScreenshot.transformed(transform);
        qDebug() << "rotation finished";
    }

    CaptureImageProvider::setMarkedImage(lastScreenshot);
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

