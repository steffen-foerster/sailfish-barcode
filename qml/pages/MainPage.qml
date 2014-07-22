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
import Sailfish.Silica 1.0
import "../components"

Page {
    id: mainPage

    function applyResult(result) {
        console.log("result from scan page: " + result)

        if (result.length > 0) {
            Clipboard.text = result
            resultText.text = result
        }

        var urls = result.match(/^http[s]*:\/\/.{3,500}$/);
        clickableResult.enabled = (urls && urls.length > 0);
    }

    SilicaFlickable {
        id: mainPageFlickable
        anchors.fill: parent
        contentHeight: columnMain.height

        PullDownMenu {
            MenuItem {
                text: qsTr("About CodeReader")
                onClicked: {
                    pageStack.push("AboutPage.qml");
                }
            }
        }

        Column {
            id: columnMain
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                id: header
                title: qsTr("CodeReader")
            }

            Label {
                id: label
                anchors {
                    left: parent.left
                    margins: Theme.paddingLarge
                }
                width: parent.width
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeMedium
                text: qsTr("Last result (copied to clipboard):")
            }

            BackgroundItem {
                id: clickableResult
                contentHeight: resultText.height
                height: contentHeight
                width: mainPageFlickable.width
                anchors {
                    left: parent.left
                }
                enabled: false

                Label {
                    id: resultText
                    anchors {
                        left: parent.left
                        margins: Theme.paddingLarge
                    }
                    color: clickableResult.highlighted ? Theme.highlightColor : Theme.primaryColor
                    font.pixelSize: Theme.fontSizeLarge
                    font.underline: clickableResult.enabled
                    wrapMode: Text.Wrap
                    width: parent.width
                    text: ""
                }

                onClicked: {
                    openInDefaultBrowser(resultText.text);
                }
            }

            Label {
                id: warning
                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingLarge
                    rightMargin: Theme.paddingLarge
                }
                width: parent.width - 2 * Theme.paddingLarge
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeMedium
                text: qsTr("Note: This app prevents a scan if the Jolla Camera app is running. \
This restriction helps to avoid an interference of the Camera app.")
                wrapMode: Text.Wrap
            }
        }
    }

    Column {
        id: columnButton
        width: parent.width
        spacing: Theme.paddingLarge
        anchors {
            bottom: parent.bottom
        }

        ComboBox {
            id: codeFormat

            anchors {
                horizontalCenter: parent.horizontalCenter
            }
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

        Button {
            anchors {
                horizontalCenter: parent.horizontalCenter
            }
            text: qsTr("Scan")
            onClicked: {
                var scanPage = pageStack.push("ScanPage.qml",
                    {format:codeFormat.currentIndex, formatName:codeFormat.currentItem.text});
                scanPage.scanned.connect(applyResult);
            }
        }
    }
}
