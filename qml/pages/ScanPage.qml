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

import QtQuick 2.1
import QtMultimedia 5.0
import Sailfish.Silica 1.0
import harbour.barcode.BarcodeScanner 1.0

Page {
    id: scanPage

    // decoder format: "QR", "EAN"
    property string format

    signal scanned(variant result)

    onStatusChanged: {
        if (status === PageStatus.Active) {
            console.log("Page is ACTIVE")
            scanner.startCamera()
        }
    }

    Connections {
        target: Qt.application
        onActiveChanged: {
            if (Qt.application.active) {
                console.log("application state changed to ACTIVE")
                // a deactivated application stops the camera so we have to start it again
                scanner.startCamera()
            }
            else {
                console.log("application state changed to INACTIVE")
                // if the application is deactivated we have to stop the camera because of power
                // consumption issues and impact to the camera application
                scanner.stopCamera()
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                id: header
                title: qsTr("Scan %1 code").arg(format)
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 2/3
                height: ((parent.width * 2/3) / 3) * 4

                BarcodeScanner {
                    id: scanner

                    onDecodingFinished: {
                        console.log("decoding finished, code: ", code)
                        if (code.length > 0) {
                            pageStack.navigateBack()
                            scanPage.scanned(code)
                        }
                        else {
                            statusText.text = qsTr("No code detected! Try again.")
                        }
                        busyIndicator.running = false
                    }

                    onError: {
                        console.log("scanning failed: ", errorCode)
                        statusText.text = qsTr("Scanning failed (code: %1)! Try again.").arg(errorCode)
                        busyIndicator.running = false
                    }
                }

                VideoOutput {
                    id: viewFinder
                    source: scanner
                    anchors.fill: parent
                    focus : visible // to receive focus and capture key events when visible
                    fillMode: VideoOutput.PreserveAspectFit
                    orientation: -90

                    MouseArea {
                        anchors.fill: parent;
                        onClicked: {
                            statusText.text = qsTr("Scan in progress!")
                            busyIndicator.running = true
                            scanner.setDecoderFormat(format)
                            scanner.startScanning()
                        }
                    }
                }

                Rectangle {
                    anchors {
                        horizontalCenter: viewFinder.horizontalCenter
                        verticalCenter: viewFinder.verticalCenter
                    }

                    width: viewFinder.width * 0.7
                    height: viewFinder.height * 0.7
                    z: 2
                    border {
                        color: "red" //Theme.highlightColor
                        width: 4
                    }
                    color: "transparent"
                }
            }

            Text {
                id: statusText
                text: qsTr("Tap on viewfinder to scan")
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - Theme.paddingLarge * 2
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.Center
                color: Theme.highlightColor
            }

            Text {
                text: qsTr("The bar code should be smaller than the red border.")
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - Theme.paddingLarge * 2
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.Center
                color: Theme.secondaryHighlightColor
            }

            BusyIndicator {
                id: busyIndicator
                visible: running
                running: false
                anchors.horizontalCenter: parent.horizontalCenter
                size: BusyIndicatorSize.Large
            }
        }
    }
}
