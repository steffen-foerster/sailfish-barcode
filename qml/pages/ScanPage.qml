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

    property variant scanner

    property Item viewFinder

    function createScanner() {
        if (scanner) {
            console.log("scanner has been already created ...")
            return
        }

        console.log("creating scanner ...")
        scanner = scannerComponent.createObject(scanPage)
        viewFinder = viewFinderComponent.createObject(parentViewFinder)
        viewFinder.source = scanner
        viewFinder.startScan.connect(slotStartScan);
        scanner.startCamera()
    }

    function destroyScanner() {
        if (!scanner) {
            console.log("scanner has been already destroyed ...")
            return
        }

        console.log("destroying scanner ...")
        viewFinder.destroy()
        scanner.destroy()
        scanner = null
    }

    function applyResult(result) {
        console.log("result from scan page: " + result)

        if (result.length > 0) {
            Clipboard.text = result
            resultText.text = result
        }

        var urls = result.match(/^http[s]*:\/\/.{3,500}$/);
        clickableResult.enabled = (urls && urls.length > 0);
    }

    function slotStartScan() {
        statusText.text = qsTr("Scan in progress!")
        resultText.text = ""
        clickableResult.enabled = false
        viewFinder.running = true
        console.log("using format: " + codeFormat.currentIndex)
        scanner.setDecoderFormat(codeFormat.currentIndex)
        scanner.startScanning()
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            console.log("Page is ACTIVE")
            createScanner()
        }
    }

    Connections {
        target: Qt.application
        onActiveChanged: {
            if (Qt.application.active) {
                console.log("application state changed to ACTIVE")
                createScanner()
            }
            else {
                console.log("application state changed to INACTIVE")
                // if the application is deactivated we have to stop the camera and destroy the scanner object
                // because of power consumption issues and impact to the camera application
                viewFinder.running = false
                destroyScanner()
            }
        }
    }

    Component {
        id: scannerComponent

        BarcodeScanner {

            onCameraStarted: {
                console.log("camera is started")
                statusText.text = qsTr("Tap on viewfinder to scan")
            }

            onDecodingFinished: {
                console.log("decoding finished, code: ", code)
                if (code.length > 0) {
                    applyResult(code)
                    statusText.text = qsTr("Tap on viewfinder to scan")
                }
                else {
                    statusText.text = qsTr("No code detected! Try again.")
                }
                viewFinder.running = false
            }

            onError: {
                console.log("scanning failed: ", errorCode)
                if (errorCode === BarcodeScanner.JollaCameraRunning) {
                    statusText.text = qsTr("Please close the Jolla Camera app.")
                }
                else {
                    statusText.text = qsTr("Scanning failed (code: %1)! Try again.").arg(errorCode)
                }
                viewFinder.running = false
            }
        }
    }

    Component {
        id: viewFinderComponent

        VideoOutput {

            property alias running: busyIndicator.running

            signal startScan()

            anchors.fill: parent
            focus : visible // to receive focus and capture key events when visible
            fillMode: VideoOutput.PreserveAspectFit
            orientation: -90

            MouseArea {
                anchors.fill: parent;
                onClicked: {
                    startScan()
                }
            }

            BusyIndicator {
                id: busyIndicator
                visible: running
                running: false
                anchors.centerIn: parent
                size: BusyIndicatorSize.Large
            }
        }    
    }

    SilicaFlickable {
        id: scanPageFlickable
        anchors.fill: parent
        contentHeight: flickableColumn.height

        PullDownMenu {
            MenuItem {
                text: qsTr("About CodeReader")
                onClicked: {
                    pageStack.push("AboutPage.qml");
                }
            }
        }

        Column {
            id: flickableColumn
            width: parent.width
            spacing: Theme.paddingLarge

            anchors {
                top: parent.top
                topMargin: Theme.paddingLarge
            }

            ComboBox {
                id: codeFormat
                width: parent.width
                label: "Code Format"

                menu: ContextMenu {
                    MenuItem { text: "QR code" }
                    MenuItem { text: "EAN-8 / EAN-13" }
                    MenuItem { text: "UPC-A / UPC-E" }
                    MenuItem { text: "Data Matrix" }
                    MenuItem { text: "Code-39 / Code-128" }
                    MenuItem { text: "ITF" }
                    MenuItem { text: "Aztec" }
                }
            }

            Item {
                id: parentViewFinder

                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 2/3
                height: ((parent.width * 2/3) / 3) * 4

                Rectangle {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        verticalCenter: parent.verticalCenter
                    }

                    width: viewFinder ? viewFinder.width * 0.7 : 0
                    height: viewFinder ? viewFinder.height * 0.7 : 0
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

            BackgroundItem {
                id: clickableResult
                contentHeight: rowResult.height
                height: contentHeight
                width: scanPageFlickable.width
                anchors {
                    left: parent.left
                }
                enabled: false

                Row {
                    id: rowResult
                    width: parent.width - 2 * Theme.paddingLarge
                    height: Math.max(clipboardImg.contentHeight, resultText.contentHeight)
                    spacing: Theme.paddingLarge
                    anchors {
                        left: parent.left
                        right: parent.right
                        margins: Theme.paddingLarge
                    }

                    Image {
                        id: clipboardImg
                        source: "image://theme/icon-m-clipboard"
                        visible: resultText.text.length > 0
                        anchors {
                            leftMargin: Theme.paddingLarge
                        }
                    }

                    Label {
                        id: resultText
                        anchors {
                            leftMargin: Theme.paddingLarge
                            verticalCenter: clipboardImg.verticalCenter
                        }
                        color: clickableResult.highlighted ? Theme.highlightColor : Theme.primaryColor
                        font.pixelSize: Theme.fontSizeMedium
                        font.underline: clickableResult.enabled
                        wrapMode: Text.Wrap
                        width: parent.width - clipboardImg.width - 2 * Theme.paddingLarge
                        text: ""
                    }
                }

                onClicked: {
                    openInDefaultBrowser(resultText.text);
                }
            }
        }
    }

    VerticalScrollDecorator { flickable: scanPageFlickable }
}
