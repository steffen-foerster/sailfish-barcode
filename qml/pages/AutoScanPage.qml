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
import harbour.barcode.AutoBarcodeScanner 1.0

import "../js/Settings.js" as Settings
import "../js/History.js" as History

Page {
    id: scanPage

    property variant scanner
    property Item viewFinder
    property variant beep

    property bool settingsInitialized: false

    property int seconds
    property int scanDuration: 20

    property int viewFinder_x: scanPage.width / 6
    property int viewFinder_y: Theme.paddingLarge * 2
    property int viewFinder_width: scanPage.width * (2/3)
    property int viewFinder_height: viewFinder_width * (4/3)

    function createScanner() {
        if (scanner) {
            console.log("scanner has been already created ...")
            return
        }

        console.log("creating scanner and viewfinder ...")
        scanner = scannerComponent.createObject(scanPage)
        scanner.setViewFinderRect(viewFinder_x, viewFinder_y, viewFinder_width, viewFinder_height)
        viewFinder = viewFinderComponent.createObject(parentViewFinder)
        viewFinder.source = scanner

        beep = beepComponent.createObject(scanPage)

        scanner.startCamera()
    }

    function destroyScanner() {
        if (!scanner) {
            console.log("scanner has been already destroyed ...")
            return
        }

        console.log("destroying scanner and viewfinder ...")
        viewFinder.destroy()
        scanner.destroy()
        scanner = null

        beep.destroy()

        stateInactive()
    }

    function applyResult(result) {
        console.log("result from scan page: " + result)

        if (result.length > 0) {
            Clipboard.text = result
            clickableResult.setValue(result)
            History.addHistoryValue(result)
            beep.play()
        }
    }

    function startScan() {
        seconds = scanDuration

        viewFinder.children[0].source = ""
        viewFinder.children[0].visible = false

        setMarkerColor()

        stateScanning()
        scanDelayTimer.restart() // we need time to hide the marked image
    }

    function setMarkerColor() {
        var markerColor = Settings.get(Settings.keys.MARKER_COLOR)
        console.log("marker color: ", markerColor)

        var red =  parseInt(markerColor.substr(1, 2), 16)
        var green =  parseInt(markerColor.substr(3, 2), 16)
        var blue =  parseInt(markerColor.substr(5, 2), 16)

        console.log("red: ", red, " green: ", green, " blue: ", blue)
        scanner.setMarkerColor(red, green, blue)
    }

    function stateInactive() {
        state = "INACTIVE"
        labelUpdateTimer.running = false
        statusText.text = ""
        actionButton.enabled = false
    }

    function stateReady() {
        state = "READY"
        labelUpdateTimer.running = false
        actionButton.text = qsTr("Scan")
        actionButton.visible = true
        actionButton.enabled = true
        zoomSlider.enabled = true
    }

    function stateScanning() {
        state = "SCANNING"
        labelUpdateTimer.running = true
        statusText.text = qsTr("Scan in progress for %1 seconds!").arg(seconds)
        clickableResult.clear()
        actionButton.text = qsTr("Abort")
    }

    function stateJollaCamera() {
        state = "JOLLA_CAMERA"
        clickableResult.clear()
        statusText.text = qsTr("Please close the Jolla Camera app.")
        actionButton.visible = false
        actionButton.enabled = false
        zoomSlider.enabled = false
    }

    function stateAbort() {
        state = "ABORT"
        actionButton.enabled = false
        scanner.stopScanning()
    }

    state: "INACTIVE"

    onStatusChanged: {
        if (scanPage.status === PageStatus.Active) {
            console.log("Page is ACTIVE")

            if (!settingsInitialized) {
                Settings.initialize();
                settingsInitialized = true
            }

            createScanner()

            // update changeable values
            beep.muted = !Settings.getBoolean(Settings.keys.SOUND)
            scanPage.scanDuration = Settings.get(Settings.keys.SCAN_DURATION)
            zoomSlider.value = Settings.get(Settings.keys.DIGITAL_ZOOM)
        }
        else if (scanPage.status === PageStatus.Inactive) {
            console.log("Page is INACTIVE")
            // stop scanning if page is not active
            destroyScanner()
        }
    }

    Timer {
        id: scanDelayTimer
        interval: 500;
        repeat: false
        onTriggered: {
            scanner.startScanning(scanDuration * 1000)
        }
    }

    Timer {
        id: resultViewTimer
        interval: 0;
        repeat: false
        onTriggered: {
            if (viewFinder) {
                viewFinder.children[0].source = ""
                viewFinder.children[0].visible = false
            }
        }
    }

    Timer {
        id: labelUpdateTimer
        interval: 1000;
        repeat: true
        onTriggered: {
            seconds --
            statusText.text = qsTr("Scan in progress for %1 seconds!").arg(seconds)
        }
    }

    Connections {
        target: Qt.application
        onActiveChanged: {
            if (Qt.application.active && scanPage.status === PageStatus.Active) {
                console.log("application state changed to ACTIVE and AutoScanPage is active")
                createScanner()
            }
            else if (!Qt.application.active) {
                console.log("application state changed to INACTIVE")
                // if the application is deactivated we have to stop the camera and destroy the scanner object
                // because of power consumption issues and impact to the camera application
                destroyScanner()
            }
        }
    }

    Component {
        id: scannerComponent

        AutoBarcodeScanner {

            onCameraStarted: {
                console.log("camera is started")
                stateReady()
            }

            onDecodingFinished: {
                console.log("decoding finished, code: ", code)
                labelUpdateTimer.running = false
                statusText.text = ""
                if (scanPage.state !== "ABORT") {
                    if (code.length > 0) {
                        applyResult(code)

                        var resultViewDuration = Settings.get(Settings.keys.RESULT_VIEW_DURATION)
                        if (resultViewDuration > 0) {
                            viewFinder.children[0].source = "image://scanner/marked"
                            viewFinder.children[0].visible = true
                            resultViewTimer.interval = resultViewDuration * 1000
                            resultViewTimer.restart()
                        }
                    }
                    else {
                        statusText.text = qsTr("No code detected! Try again.")
                    }
                }
                stateReady()
            }

            onError: {
                console.log("scanning failed: ", errorCode)
                if (errorCode === AutoBarcodeScanner.JollaCameraRunning) {
                    stateJollaCamera()
                }
                else {
                    statusText.text = qsTr("Scanning failed (code: %1)! Try again.").arg(errorCode)
                    stateReady()
                }
            }
        }
    }

    Component {
        id: viewFinderComponent

        VideoOutput {
            anchors.fill: parent
            //focus: visible // to receive focus when visible
            fillMode: VideoOutput.PreserveAspectFit
            orientation: -90

            Image {
                id: markerImage
                anchors.fill: parent
                z: 2
                source: ""
                visible: false
                cache: false
            }
        }
    }

    Component {
        id: beepComponent

        SoundEffect {
            source: "sound/beep.wav"
            volume: 1.0
            muted: false
        }
    }

    SilicaFlickable {
        id: scanPageFlickable
        anchors.fill: parent
        contentHeight: flickableColumn.height

        PullDownMenu {
            id: menu
            MenuItem {
                text: qsTr("About CodeReader")
                onClicked: {
                    pageStack.push("AboutPage.qml");
                }
            }
            MenuItem {
                text: qsTr("Settings")
                onClicked: {
                    pageStack.push("SettingsPage.qml");
                }
            }
        }

        Column {
            id: flickableColumn
            width: parent.width
            spacing: Theme.paddingLarge

            anchors {
                top: parent.top
                topMargin: Theme.paddingLarge * 2
            }

            Item {
                id: parentViewFinder

                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 2/3
                height: ((parent.width * 2/3) / 3) * 4
            }

            Row {
                width: parent.width - Theme.paddingLarge * 2
                anchors.horizontalCenter: parent.horizontalCenter

                // doesn't work
                /*
                IconButton {
                    id: flash

                    property bool checked: false

                    icon.source: checked
                                 ? "image://theme/icon-camera-flash-on"
                                 : "image://theme/icon-camera-flash-off"
                    onClicked: {
                        var success = scanner.toggleFlash(flash.checked)
                        if (!success) {
                            checked = !checked
                        }
                    }
                }
                */

                Slider {
                    id: zoomSlider
                    width: parent.width
                    minimumValue: 1.0
                    maximumValue: 7.0
                    value: 1
                    stepSize: 1
                    onValueChanged: {
                        scanner.zoomTo(value)
                        saveZoomDelay.restart()
                    }

                    Timer {
                        id: saveZoomDelay
                        interval: 500
                        onTriggered: {
                            Settings.set(Settings.keys.DIGITAL_ZOOM, zoomSlider.value)
                        }

                    }
                }
            }

            Text {
                id: statusText
                text: ""
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - Theme.paddingLarge * 2
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.Center
                color: Theme.highlightColor
            }

            BackgroundItem {
                id: clickableResult

                property bool isLink: false

                property string text: ""

                function setValue(text) {
                    var urls = text.match(/^(http[s]*:\/\/.{3,500}|www\..{3,500}|sms:\+\d{5,})$/);
                    var vcard = text.match(/^(.+VCARD.+)$/);
                    // is a known url scheme and not a vcard
                    if (urls && urls.length > 0 && !(vcard && vcard.length > 0)) {
                        setLink(text)
                    }
                    else {
                        setText(text)
                    }
                }

                function clear() {
                    clickableResult.enabled = false
                    clickableResult.isLink = false
                    clickableResult.text = ""
                    resultText.text = ""
                    resultText.width = rowResult.width - clipboardImg.width - 2 * Theme.paddingLarge
                }

                function setLink(link) {
                    clickableResult.enabled = true
                    clickableResult.isLink = true
                    clickableResult.text = link
                    resultText.text = link
                    resultText.width = rowResult.width - clipboardImg.width - 2 * Theme.paddingLarge
                }

                function setText(text) {
                    clickableResult.enabled = true
                    clickableResult.isLink = false
                    clickableResult.text = text
                    var shortenText = text.replace("\n", " ")
                    resultText.text = shortenText.length > 15 ? shortenText.substr(0, 15) + "..." : shortenText
                    resultText.width =
                            rowResult.width - clipboardImg.width - arrowRightImg.width - 2 * Theme.paddingLarge
                }

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
                            top: clipboardImg.top
                        }
                        color: clickableResult.highlighted
                               ? Theme.highlightColor
                               : Theme.primaryColor
                        font.pixelSize: Theme.fontSizeMedium
                        font.underline: clickableResult.isLink
                        truncationMode: TruncationMode.Fade
                        width: parent.width - clipboardImg.width - 2 * Theme.paddingLarge
                        text: ""
                    }

                    Image {
                        id: arrowRightImg
                        source: "image://theme/icon-m-right"
                        visible: clickableResult.text.length > 0 && !clickableResult.isLink
                        anchors {
                            leftMargin: Theme.paddingLarge
                        }
                    }
                }

                onClicked: {
                    if (clickableResult.isLink) {
                        openInDefaultBrowser(clickableResult.text);
                    }
                    else {
                        pageStack.push("TextPage.qml", {text: clickableResult.text});
                    }
                }
            }
        }
    }

    VerticalScrollDecorator { flickable: scanPageFlickable }

    Rectangle {
        width: parent.width
        height: actionButton.height + Theme.paddingLarge * 2
        anchors {
            bottom: parent.bottom
        }
        z: 10
        color: "black"

        Button {
            id: actionButton
            anchors {
                centerIn: parent
            }
            z: 11
            onClicked: {
                if (scanPage.state === "READY") {
                    startScan()
                }
                else if (scanPage.state === "SCANNING") {
                    stateAbort()
                }
            }
            text: ""
            enabled: false
        }
    }

    /*
    states: [
        State {
            name: "INACTIVE"
            PropertyChanges {target: labelUpdateTimer; running: false; restoreEntryValues: false}
            PropertyChanges {target: statusText; text: ""; restoreEntryValues: false}
        },
        State {
            name: "READY"
            PropertyChanges {target: labelUpdateTimer; running: false; restoreEntryValues: false}
            PropertyChanges {target: actionButton; text: qsTr("Scan"); restoreEntryValues: false}
        },
        State {
            name: "SCANNING"
            PropertyChanges {target: labelUpdateTimer; running: true; restoreEntryValues: false}
            PropertyChanges {target: statusText; text: qsTr("Scan in progress for %1 seconds!").arg(seconds); restoreEntryValues: false}
            PropertyChanges {target: resultText; text: ""; restoreEntryValues: false}
            PropertyChanges {target: clickableResult; enabled: false; restoreEntryValues: false}
            PropertyChanges {target: actionButton; text: qsTr("Abort"); restoreEntryValues: false}
        },
        State {
            name: "JOLLA_CAMERA"
            PropertyChanges {target: actionButton; enabled: false; restoreEntryValues: true}
            PropertyChanges {target: zoomSlider; enabled: false; restoreEntryValues: true}
            PropertyChanges {target: resultText; text: ""; restoreEntryValues: false}
        },
        State {
            name: "ABORT"
        }
    ]
    */
}
