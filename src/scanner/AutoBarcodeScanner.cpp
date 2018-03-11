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
#include <QtQuick/QQuickWindow>

#include <fstream>

AutoBarcodeScanner::AutoBarcodeScanner(QObject * parent)
    : QObject(parent)
    , m_decoder(new BarcodeDecoder(this))
    , m_viewFinderItem(NULL)
    , m_flagScanRunning(false)
    , m_flagScanAbort(false)
    , m_flashState(false)
    , m_timeoutTimer(new QTimer(this))
    , m_markerColor(QColor(0, 255, 0)) // default green
{
    qDebug() << "start init AutoBarcodeScanner";

    createConnections();
    m_timeoutTimer->setSingleShot(true);
    connect(m_timeoutTimer, SIGNAL(timeout()), this, SLOT(slotScanningTimeout()));
}

AutoBarcodeScanner::~AutoBarcodeScanner() {
    qDebug() << "AutoBarcodeScanner::~AutoBarcodeScanner";

    // stopping a running scanning process
    stopScanning();
    m_scanFuture.waitForFinished();

    if (m_flashState) {
        toggleFlash();
    }
}

void AutoBarcodeScanner::createConnections() {
    // Handled on the main thread
    connect(this, SIGNAL(decodingDone(QImage,QVariantList,QString)),
            this, SLOT(slotDecodingDone(QImage,QVariantList,QString)),
            Qt::QueuedConnection);
    // Forward needImage emitted by the decoding thread
    connect(this, SIGNAL(needImage()), this, SLOT(slotGrabImage()), Qt::QueuedConnection);
}

void AutoBarcodeScanner::slotGrabImage()
{
    if (m_viewFinderItem && m_flagScanRunning) {
        QQuickWindow* window = m_viewFinderItem->window();
        if (window) {
            qDebug() << "grabbing image";
            QImage image = window->grabWindow();
            if (!image.isNull() && m_flagScanRunning) {
                qDebug() << image;
                m_scanProcessMutex.lock();
                m_captureImage = image;
                m_scanProcessEvent.wakeAll();
                m_scanProcessMutex.unlock();
            }
        }
    }
}

void AutoBarcodeScanner::setViewFinderRect(QRect rect)
{
    if (m_viewFinderRect != rect) {
        qDebug() << rect;
        // m_viewFinderRect is accessed by processDecode() thread
        m_scanProcessMutex.lock();
        m_viewFinderRect = rect;
        m_scanProcessMutex.unlock();
    }
}

void AutoBarcodeScanner::setViewFinderItem(QObject* value) {
    QQuickItem* item = qobject_cast<QQuickItem*>(value);
    if (m_viewFinderItem != item) {
        m_viewFinderItem = item;
        emit viewFinderItemChanged();
    }
}

void AutoBarcodeScanner::setDecoderFormat(int format) {
    m_decoder->setDecoderFormat(format);
}

void AutoBarcodeScanner::toggleFlash() {
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

void AutoBarcodeScanner::startScanning(int timeout) {
    if (!m_flagScanRunning) {
        m_flagScanRunning = true;
        m_flagScanAbort = false;
        m_timeoutTimer->start(timeout);
        m_captureImage = QImage();
        m_scanFuture = QtConcurrent::run(this, &AutoBarcodeScanner::processDecode);
    }
}

void AutoBarcodeScanner::stopScanning() {
    // stopping a running scanning process
    m_scanProcessMutex.lock();
    if (m_flagScanRunning) {
        m_flagScanAbort = true;
        m_scanProcessEvent.wakeAll();
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
    return result;
}

/**
 * Runs in a pooled thread.
 */
void AutoBarcodeScanner::processDecode() {
    qDebug() << "processDecode() is called from " << QThread::currentThread();

    QString code;
    QVariantHash result;
    QImage image;

    m_scanProcessMutex.lock();
    while (!m_flagScanAbort && code.isEmpty()) {
        emit needImage();
        QRect viewFinderRect;
        while (m_captureImage.isNull() && !m_flagScanAbort) {
            m_scanProcessEvent.wait(&m_scanProcessMutex);
        }
        if (!m_flagScanAbort) {
            image = m_captureImage;
            m_captureImage = QImage();
        }
        viewFinderRect = m_viewFinderRect;
        m_scanProcessMutex.unlock();

        if (!image.isNull()) {
            // crop the image - we need only the viewfinder
            image = image.copy(viewFinderRect);
            saveDebugImage(image, "debug_screenshot.jpg");
            qDebug() << "decoding screenshot ...";
            result = m_decoder->decodeBarcode(image);
            code = result["content"].toString();

            if (code.isEmpty()) {
                // try the other orientation for 1D bar code
                QTransform transform;
                transform.rotate(90);
                image = image.transformed(transform);
                saveDebugImage(image, "debug_transformed.jpg");
                qDebug() << "decoding rotated screenshot ...";
                result = m_decoder->decodeBarcode(image);
                code = result["content"].toString();
            }
        }
        m_scanProcessMutex.lock();
    }
    m_scanProcessMutex.unlock();

    qDebug() << "decoding has been finished, result: " + code;
    emit decodingDone(code.isEmpty() ? QImage() : image, result["points"].toList(), code);
}

void AutoBarcodeScanner::slotDecodingDone(QImage image, QVariantList points, const QString code) {
    qDebug() << "decoding has been finished:" << code;
    if (!image.isNull()) {
        qDebug() << "image:" << image;
        qDebug() << "points:" << points;
        markLastCaptureImage(image, points);
    }
    m_captureImage = QImage();
    m_timeoutTimer->stop();
    m_flagScanRunning = false;
    emit decodingFinished(code);
}

void AutoBarcodeScanner::saveDebugImage(QImage &image, const QString &fileName) {
    QString imageLocation = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + "/codereader/" + fileName;
    if (image.save(imageLocation)) {
        qDebug() << "image saved: " << imageLocation;
    }
}

void AutoBarcodeScanner::markLastCaptureImage(QImage image, QVariantList points) {
    QPainter painter(&image);
    painter.setPen(m_markerColor);

    qDebug() << "recognized points: " << points.size();
    for (int i = 0; i < points.size(); i++) {
        QPoint p = points[i].toPoint();
        painter.fillRect(QRect(p.x()-3, p.y()-15, 6, 30), QBrush(m_markerColor));
        painter.fillRect(QRect(p.x()-15, p.y()-3, 30, 6), QBrush(m_markerColor));
    }
    painter.end();

    // rotate to screen orientation
    if (image.width() > image.height()) {
        qDebug() << "rotating image ...";
        QTransform transform;
        transform.rotate(270);
        image = image.transformed(transform);
        qDebug() << "rotation finished";
    }

    CaptureImageProvider::setMarkedImage(image);
}

void AutoBarcodeScanner::slotScanningTimeout() {
    m_scanProcessMutex.lock();
    m_flagScanAbort = true;
    qDebug() << "decoding aborted by timeout";
    m_scanProcessEvent.wakeAll();
    m_scanProcessMutex.unlock();
}
