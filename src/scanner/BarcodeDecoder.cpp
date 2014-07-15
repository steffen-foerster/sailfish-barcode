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
#include <QStandardPaths>
#include <QDir>
#include <QImage>
#include "qzxing/qzxing.h"
#include "BarcodeDecoder.h"
#include "ImagePostProcessing.h"

BarcodeDecoder::BarcodeDecoder(QObject *parent) : QObject(parent)
{
    // prepare cache directory
    QString cacheFolderLocation = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    cacheCaptureLocation = cacheFolderLocation + "/capture_qrcode.jpg";
    QDir cacheDir(cacheFolderLocation);

    if (!cacheDir.exists()) {
        cacheDir.mkpath(".");
    }

    // ZXing
    decoder = new QZXing();
}

BarcodeDecoder::~BarcodeDecoder() {
    delete decoder;
    decoder = 0;
}

void BarcodeDecoder::setDecoderFormat(const QString &format) {
    qDebug() << "using decoder format: " + format;
    if (format == "QR") {
        decoder->setDecoder(QZXing::DecoderFormat_QR_CODE);
    }
    else if (format == "EAN") {
        decoder->setDecoder(QZXing::DecoderFormat_EAN_8 | QZXing::DecoderFormat_EAN_13);
    }
    else {
        qDebug() << "unknown decoder format: " + format;
    }
}

QString BarcodeDecoder::getCaptureLocation() const {
    return cacheCaptureLocation;
}

QString BarcodeDecoder::decodeBarcodeFromCache() {
    QImage img(cacheCaptureLocation);

    // improve image to get better decoding result
    QImage * origin = &img;
    QImage * improvedImage = ImagePostProcessing::improveImage(origin);

    QVariantHash result = decoder->decodeImageEx((*improvedImage));

    delete improvedImage;

    return result["content"].toString();
}
