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

import "../js/Settings.js" as Settings
import "../js/History.js" as History

Item {
    id: root

    height: mainView.height; width: mainView.width

    Column {
        id: col
        width: parent.width
        height: childrenRect.height
        spacing: Theme.paddingLarge

        anchors {
            left: parent.left;
            right: parent.right
            leftMargin: Theme.paddingLarge
            rightMargin: Theme.paddingLarge
        }

        IconTextSwitch {
            checked: Settings.getBoolean(Settings.keys.SOUND)
            text: qsTr("Detection sound")
            icon.source: "image://theme/icon-m-speaker"
            onCheckedChanged: {
                Settings.setBoolean(Settings.keys.SOUND, checked)
            }
        }

        IconTextSwitch {
            checked: Settings.getBoolean(Settings.keys.SCAN_ON_START)
            text: qsTr("Scan on start")
            icon.source: "image://theme/icon-m-play"
            onCheckedChanged: {
                Settings.setBoolean(Settings.keys.SCAN_ON_START, checked)
            }
        }

        SectionHeader {
            text: qsTr("History")
        }

        Slider {
            id: historySizeSlider

            property int count: History.getHistorySize()

            width: parent.width
            minimumValue: 0
            maximumValue: 100
            value: Settings.get(Settings.keys.HISTORY_SIZE)
            stepSize: 10
            label: qsTr("Max history size (saved values: %1)").arg(count)
            valueText: value === 0 ? qsTr("deactivated") : qsTr("%1 items").arg(value)
            onSliderValueChanged: {
                var currentSize = History.getHistorySize()
                if (value < currentSize) {
                    historyConfirmButtons.visible = true
                }
                else {
                    historyConfirmButtons.visible = false
                    Settings.set(Settings.keys.HISTORY_SIZE, value)
                }
            }
        }

        Row {
            id: historyConfirmButtons
            width: parent.width
            visible: false

            Button {
                width: parent.width / 2
                text: qsTr("Confirm resize")
                onClicked: {
                    History.applyNewHistorySize(historySizeSlider.value)
                    Settings.set(Settings.keys.HISTORY_SIZE, historySizeSlider.value)
                    historyConfirmButtons.visible = false
                    historySizeSlider.count = History.getHistorySize()
                }
            }

            Button {
                width: parent.width / 2
                text: qsTr("Cancel")
                onClicked: {
                    historyConfirmButtons.visible = false
                }
            }

            Behavior on visible {
                FadeAnimation {}
            }
        }
    }
}
