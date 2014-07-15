/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster

This class uses code from
http://developer.nokia.com/community/wiki/Image_editing_techniques_and_algorithms_using_Qt

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
#include <QColor>
#include <QImage>
#include "ImagePostProcessing.h"

// TODO: remove unused code if scanning is stable

/**
 * Improves the given image for the decoding process.
 */
QImage * ImagePostProcessing::improveImage(QImage *origin) {
    QImage scaledImage = origin->scaled(640, origin->height(), Qt::KeepAspectRatio, Qt::FastTransformation);
    //scaledImage.save("/home/nemo/.cache/harbour-marker/harbour-marker/scaled.jpg", "JPG");

    QImage * greyedImage = greyScale(&scaledImage);
    //greyedImage->save("/home/nemo/.cache/harbour-marker/harbour-marker/greyed.jpg", "JPG");

    //QImage * sharpenedImage = greyScale(greyedImage);
    //sharpenedImage->save("/home/nemo/.cache/harbour-marker/harbour-marker/sharpened.jpg", "JPG");

    return greyedImage;
}

/**
 * Converting the given image to grey scale.
 */
QImage * ImagePostProcessing::greyScale(QImage *origin){
    QImage * newImage = new QImage(origin->width(), origin->height(), QImage::Format_ARGB32);

    for(int y = 0; y < newImage->height(); y++){
        QRgb * line = (QRgb *)origin->scanLine(y);

        for (int x = 0; x < newImage->width(); x++) {
            // method: averaging
            //int gray = (qRed(line[x]) + qGreen(line[x]) + qBlue(line[x]))/3;

            // method: luma
            //int gray = (0.2126 * qRed(line[x]) + 0.7152 * qGreen(line[x]) + 0.0722 * qBlue(line[x])) / 3;

            // method: decomposition using maximum values
            int gray = qMax(qMax(qRed(line[x]), qGreen(line[x])), qBlue(line[x]));

            newImage->setPixel(x, y, qRgb(gray, gray, gray));
        }
    }

    return newImage;
}

/**
 * Sharpening of the given image.
 */
QImage * ImagePostProcessing::sharpen(QImage *origin){
    QImage * newImage = new QImage(* origin);

    int kernel [5][5]= {{0,0,0,0,0},
                        {0,0,-2,0,0},
                        {0,-2,15,-2,0},
                        {0,0,-2,0,0},
                        {0,0,1,0,0}};
    int kernelSize = 5;
    int sumKernel = 7;

    /*
    int kernel [3][3]= {{0,-1,0},
                        {-1,5,-1},
                        {0,-1,0}};
    int kernelSize = 3;
    int sumKernel = 1;
    */

    int r,g,b;
    QColor color;

    for(int x = kernelSize/2; x < newImage->width()-(kernelSize/2); x++){
        for(int y = kernelSize/2; y < newImage->height()-(kernelSize/2); y++){

            r = 0;
            g = 0;
            b = 0;

            for(int i = -kernelSize/2; i<= kernelSize/2; i++){
                for(int j = -kernelSize/2; j<= kernelSize/2; j++){
                    color = QColor(origin->pixel(x+i, y+j));
                    r += color.red() * kernel[kernelSize/2+i][kernelSize/2+j];
                    g += color.green() * kernel[kernelSize/2+i][kernelSize/2+j];
                    b += color.blue() * kernel[kernelSize/2+i][kernelSize/2+j];
                }
            }

            r = qBound(0, r/sumKernel, 255);
            g = qBound(0, g/sumKernel, 255);
            b = qBound(0, b/sumKernel, 255);

            newImage->setPixel(x, y, qRgb(r,g,b));
        }
    }
    return newImage;
}
