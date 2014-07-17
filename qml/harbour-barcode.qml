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

import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"

ApplicationWindow
{
    id: window

    function getVersion() {
        return "0.1.1";
    }

    function openInDefaultBrowser(url) {
            console.log("opening URL: " + url)
            infoPanel.showText(qsTr("Opening in default browser ..."), 500, 2000)
            Qt.openUrlExternally(url)
        }

    initialPage: Component { MainPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")

    // infoPanel borrowed from https://github.com/veskuh/Tweetian/blob/sailfish-port/qml/tweetian-harmattan/main.qml - Thanks!
    Rectangle {
        id: infoPanel

        width: parent.width
        height: infoText.height + 2 * Theme.paddingMedium

        color: Theme.highlightBackgroundColor
        opacity: 0.0
        z: 10

        function showText(text, delayTime, closeTime) {
            infoText.text = text;
            console.log("INFO: " + text);

            delayTimer.interval = !delayTime ? 0 : delayTime;
            closeTimer.interval = !closeTime ? 5000 : closeTime;

            delayTimer.restart();
        }

        function showError(error) {
            var msg = error.errorMessage + "\n" + error.detailMessage;
            showText(msg);
        }

        function performShow() {
            infoPanel.opacity = 1;
            infoPanel.visible = true;
            closeTimer.restart();
        }

        Label {
            id: infoText
            anchors.top: parent.top
            anchors.topMargin: Theme.paddingMedium
            x: Theme.paddingMedium
            width: parent.width - 2 * Theme.paddingMedium
            color: Theme.primaryColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

        Behavior on opacity { FadeAnimation {} }
        Behavior on visible { FadeAnimation {} }

        Timer {
            id: closeTimer
            interval: 6000
            onTriggered: {
                infoPanel.opacity = 0.0
                infoPanel.visible = false
            }
        }

        Timer {
            id: delayTimer
            onTriggered: {
                infoPanel.performShow();
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                closeTimer.stop()
                infoPanel.opacity = 0.0
                infoPanel.visible = false
            }
        }
    }
}


