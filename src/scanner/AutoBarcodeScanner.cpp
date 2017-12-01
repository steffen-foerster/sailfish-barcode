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
#include <QImage>
#include <QVideoProbe>
#include <QStandardPaths>
#include <QtDBus/QDBusMessage>
#include <QtDBus/QDBusConnection>

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
    , m_currentFrame(QImage())
    , m_probe(new QVideoProbe(this))
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
    connect(m_camera, SIGNAL(statusChanged(QCamera::Status)), this, SLOT(slotStatusChanged(QCamera::Status)));
    connect(m_camera, SIGNAL(stateChanged(QCamera::State)), this, SLOT(slotStateChanged(QCamera::State)));

    // video probe
    connect(m_probe, SIGNAL(videoFrameProbed(QVideoFrame)), this, SLOT(slotFrameAvailable(QVideoFrame)));
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

        // it's not working on SailfishOS 2.1.3.7
        bool success = m_probe->setSource(m_camera);
        qDebug() << "source is valid: " << success;

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

    m_currentFrame = QImage();

    QtConcurrent::run(this, &AutoBarcodeScanner::processDecode);
}

void AutoBarcodeScanner::stopScanning() {
    // stopping a running scanning process
    m_scanProcessMutex.lock();
    if (m_flagScanRunning) {
        m_flagScanAbort = true;

        //m_camera->stop();
        //m_camera->start();

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
    bool frameAvailable = false;
    QImage frame;
    QString code;
    QVariantHash result;

    while (scanActive) {
        // timeout timer and deconstructor can abort scan process
        m_scanProcessMutex.lock();
        scanActive = !m_flagScanAbort;
        if (!scanActive) {
            qDebug() << "decoding aborted";
        }

        if (!m_currentFrame.isNull()) {
            frameAvailable = true;
            qDebug() << "frame is available";
            frame = QImage(m_currentFrame);
        }

        m_scanProcessMutex.unlock();

        if (scanActive && frameAvailable) {
            qDebug() << "decoding frame ...";
            result = m_decoder->decodeBarcode(frame);
            code = result["content"].toString();

            if (code.isEmpty()) {
                // try the other orientation for 1D bar code
                QTransform transform;
                transform.rotate(90);
                frame = frame.transformed(transform);

                qDebug() << "decoding rotated frame ...";
                result = m_decoder->decodeBarcode(frame);
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
        markLastCaptureImage(points, frame);
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

void AutoBarcodeScanner::markLastCaptureImage(QList<QVariant> &points, QImage frame) {
    QPainter painter(&frame);
    painter.setPen(m_markerColor);

    qDebug() << "recognized points: " << points.size();
    for (int i = 0; i < points.size(); i++) {
        QPoint p = points[i].toPoint();
        painter.fillRect(QRect(p.x()-3, p.y()-15, 6, 30), QBrush(m_markerColor));
        painter.fillRect(QRect(p.x()-15, p.y()-3, 30, 6), QBrush(m_markerColor));
    }
    painter.end();

    // rotate to screen orientation
    if (frame.width() > frame.height()) {
        qDebug() << "rotating image ...";
        QTransform transform;
        transform.rotate(270);
        frame = frame.transformed(transform);
        qDebug() << "rotation finished";
    }

    CaptureImageProvider::setMarkedImage(frame);
}

void AutoBarcodeScanner::slotScanningTimeout() {
    m_scanProcessMutex.lock();
    m_flagScanAbort = true;
    qDebug() << "decoding aborted by timeout";
    m_scanProcessMutex.unlock();
}

void AutoBarcodeScanner::slotFrameAvailable(QVideoFrame frame) {
    qDebug() << "slotFrameAvailable ...";
    if (frame.isValid()) {
        qDebug() << "clone frame ...";
        QVideoFrame cloneFrame(frame);
        qDebug() << "map frame ...";
        cloneFrame.map(QAbstractVideoBuffer::ReadOnly);
        qDebug() << "build image ...";
        const QImage image(cloneFrame.bits(),
                           cloneFrame.width(),
                           cloneFrame.height(),
                           QVideoFrame::imageFormatFromPixelFormat(cloneFrame .pixelFormat()));
        qDebug() << "unmap frame ...";
        cloneFrame.unmap();
        qDebug() << "frame is valid";

        m_scanProcessMutex.lock();
        m_currentFrame = image;
        m_scanProcessMutex.unlock();
    } else {
        qDebug() << "frame isn't valid";
    }
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

