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

BarcodeDecoder::BarcodeDecoder(QObject *parent)
    : QObject(parent)
    // ZXing
    , decoder(new QZXing())
{
    // prepare cache directory
    QString cacheFolderLocation = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + "/codereader";
    cacheCaptureLocation = cacheFolderLocation + "/screenshot.jpg";
    qDebug() << "screenshot location: " << cacheCaptureLocation;

    QDir cacheDir(cacheFolderLocation);

    if (!cacheDir.exists()) {
        cacheDir.mkpath(".");
    }
}

BarcodeDecoder::~BarcodeDecoder() {
    delete decoder;
}

void BarcodeDecoder::setDecoderFormat(const int &format) {
    qDebug() << "using decoder format: " << format;
    if (format == CodeFormat_QR_CODE) {
        decoder->setDecoder(QZXing::DecoderFormat_QR_CODE);
    }
    else if (format == CodeFormat_EAN) {
        decoder->setDecoder(QZXing::DecoderFormat_EAN_8 | QZXing::DecoderFormat_EAN_13);
    }
    else if (format == CodeFormat_UPC) {
        decoder->setDecoder(QZXing::DecoderFormat_UPC_A | QZXing::DecoderFormat_UPC_E);
    }
    else if (format == CodeFormat_DATA_MATRIX) {
        decoder->setDecoder(QZXing::DecoderFormat_DATA_MATRIX);
    }
    else if (format == CodeFormat_CODE_39_128) {
        decoder->setDecoder(QZXing::DecoderFormat_CODE_39 | QZXing::DecoderFormat_CODE_128);
    }
    else if (format == CodeFormat_ITF) {
        decoder->setDecoder(QZXing::DecoderFormat_ITF);
    }
    else if (format == CodeFormat_Aztec) {
        decoder->setDecoder(QZXing::DecoderFormat_Aztec);
    }
    else {
        qDebug() << "unknown decoder format: " + format;
    }
}

QString BarcodeDecoder::getCaptureLocation() const {
    return cacheCaptureLocation;
}

QVariantHash BarcodeDecoder::decodeBarcodeFromCache() {
    QImage img(cacheCaptureLocation);
    QVariantHash result = decoder->decodeImageEx(img);
    return result;
}
QVariantHash BarcodeDecoder::decodeBarcodeFromImage(QImage &img) {
    QVariantHash result = decoder->decodeImageEx(img);
    return result;
}
