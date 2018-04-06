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

#ifndef BARCODEDECODER_H
#define BARCODEDECODER_H

#include <QObject>
#include <QString>
#include "qzxing/qzxing.h"

class BarcodeDecoder : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString captureLocation READ getCaptureLocation)

public:
    explicit BarcodeDecoder(QObject *parent = 0);
    virtual ~BarcodeDecoder();

    QVariantHash decodeBarcodeFromCache();
    QVariantHash decodeBarcodeFromImage(QImage &img);
    void setDecoderFormat(const int &format);
    QString getCaptureLocation() const;

    enum CodeFormat {
        CodeFormat_QR_CODE = 0,
        CodeFormat_EAN = 1,
        CodeFormat_UPC = 2,
        CodeFormat_DATA_MATRIX = 3,
        CodeFormat_CODE_39_128 = 4,
        CodeFormat_ITF = 5,
        CodeFormat_Aztec = 6
    };

signals:

public slots:

private:
    QString cacheCaptureLocation;
    class QZXing *decoder;

};

#endif // BARCODEDECODER_H
