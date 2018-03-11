/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster

Some ideas are borrowed from qdeclarativecamera.cpp and qdeclarativecamera.h
(https://git.gitorious.org/qt/qtmultimedia.git)

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

#ifndef AUTOBARCODESCANNER_H
#define AUTOBARCODESCANNER_H

#include <QColor>
#include <QtConcurrent>
#include <QtQuick/QQuickItem>
#include "BarcodeDecoder.h"

class AutoBarcodeScanner : public QObject
{
    Q_OBJECT

public:
    AutoBarcodeScanner(QObject *parent = 0);
    virtual ~AutoBarcodeScanner();

    Q_PROPERTY(QObject* viewFinderItem READ viewFinderItem WRITE setViewFinderItem NOTIFY viewFinderItemChanged)
    Q_PROPERTY(bool flashState READ flashState NOTIFY flashStateChanged)

    Q_INVOKABLE void startScanning(int timeout);
    Q_INVOKABLE void stopScanning();
    Q_INVOKABLE void toggleFlash();
    Q_INVOKABLE void setDecoderFormat(int format);

    Q_INVOKABLE void setMarkerColor(int red, int green, int blue) {
        m_markerColor = QColor(red, green, blue);
    }

    Q_INVOKABLE bool isJollaCameraRunning();
    Q_INVOKABLE void setViewFinderRect(QRect rect);

    Q_ENUMS(AutoBarcodeScanner::CodeFormat)

    // must be public, to start in new thread
    void processDecode();

    bool flashState() const { return m_flashState; }
    QObject* viewFinderItem() const { return m_viewFinderItem; }

    void setViewFinderItem(QObject* item);

signals:
    void decodingDone(QImage image, QVariantList points, QString code);
    void decodingFinished(QString code);
    void flashStateChanged(bool currentState);
    void viewFinderItemChanged();
    void needImage();

public slots:
    void slotScanningTimeout();
    void slotDecodingDone(QImage image, QVariantList points, QString code);
    void slotGrabImage();

private:
    void createConnections();
    void markLastCaptureImage(QImage image, QVariantList points);
    void writeFlashMode(int flashMode);
    static void saveDebugImage(QImage &image, const QString &fileName);

    BarcodeDecoder* m_decoder;
    QImage m_captureImage;
    QQuickItem* m_viewFinderItem;
    bool m_flagScanRunning;
    bool m_flagScanAbort;
    bool m_flashState;
    QTimer* m_timeoutTimer;

    QMutex m_scanProcessMutex;
    QWaitCondition m_scanProcessEvent;
    QFuture<void> m_scanFuture;

    // options
    QRect m_viewFinderRect;
    QColor m_markerColor;
};

#endif // AUTOBARCODESCANNER_H
