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

#include <QCamera>
#include <QCameraImageCapture>
#include <QCameraExposure>
#include <QCameraFocus>
#include <QThread>
#include <QColor>
#include <QtConcurrent>
#include <QtQml/qqmlparserstatus.h>
#include "BarcodeDecoder.h"

#include <iostream>
#include <fstream>

class AutoBarcodeScanner : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)

public:
    AutoBarcodeScanner(QObject *parent = 0);
    virtual ~AutoBarcodeScanner();

    // see qdeclarativecamera_p.h
    Q_PROPERTY(QObject *mediaObject READ mediaObject NOTIFY mediaObjectChanged SCRIPTABLE false DESIGNABLE false)

    Q_PROPERTY(bool flashState READ flashState)

    Q_INVOKABLE void startScanning(int timeout);
    Q_INVOKABLE void stopScanning();
    Q_INVOKABLE void toggleFlash();
    Q_INVOKABLE void zoomTo(qreal digitalZoom);
    Q_INVOKABLE void setDecoderFormat(int format);

    Q_INVOKABLE void setViewFinderRect(int x, int y, int width, int height) {
        m_viewFinderRect = QRect(x, y, width, height);
    }

    Q_INVOKABLE void setMarkerColor(int red, int green, int blue) {
        m_markerColor = QColor(red, green, blue);
    }

    // page have to stop the camera if application is deactivated
    Q_INVOKABLE void startCamera();

    Q_ENUMS(ErrorCode)
    Q_ENUMS(AutoBarcodeScanner::CodeFormat)

    // must be public, to start in new thread
    void processDecode();

    // see qdeclarativecamera_p.h
    QObject *mediaObject() { return m_camera; }

    bool flashState() const { return m_flashState; }

    enum ErrorCode {
        LockFailed,
        CameraUnavailable,
        CaptureFailed,
        CameraError,
        JollaCameraRunning
    };

signals:
    void cameraStarted();
    void decodingFinished(const QString &code);
    void error(ErrorCode errorCode);
    void mediaObjectChanged();
    void flashStateChanged(bool currentState);

public slots:
    void slotScanningTimeout();
    void slotCameraError(QCamera::Error value);
    void slotStatusChanged(QCamera::Status status);
    void slotStateChanged(QCamera::State state);


protected:
    // see qdeclarativecamera_p.h
    void classBegin();
    void componentComplete();

private:
    void createConnections();
    bool isJollaCameraRunning();
    void markLastCaptureImage(QList<QVariant> &points);
    void writeFlashMode(int flashMode);
    void createScreeshot();
    void saveDebugImage(QImage &image, const QString &fileName);

    BarcodeDecoder* m_decoder;
    QCamera* m_camera;
    QCameraImageCapture* m_imageCapture;
    bool m_flagComponentComplete;
    bool m_flagScanRunning;
    bool m_flagScanAbort;
    bool m_flashState;
    QTimer* m_timeoutTimer;

    QMutex m_scanProcessMutex;
    QWaitCondition m_scanProcessStopped;

    // options
    QRect m_viewFinderRect;
    QColor m_markerColor;
};

#endif // AUTOBARCODESCANNER_H
