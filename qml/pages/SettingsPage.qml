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

Page {
    id: settingsPage

    Column {
        width: parent.width
        spacing: Theme.paddingLarge

        anchors {
            fill: parent
            leftMargin: Theme.paddingLarge
            rightMargin: Theme.paddingLarge
        }

        PageHeader {
            title: qsTr("Settings")
        }

        Slider {
            id: timeSlider
            width: parent.width
            minimumValue: 5.0
            maximumValue: 60.0
            value: Settings.get(Settings.keys.SCAN_DURATION)
            stepSize: 5
            label: qsTr("Scan duration")
            valueText: qsTr("%1 sec.").arg(value)
            onSliderValueChanged: {
                Settings.set(Settings.keys.SCAN_DURATION, value)
            }
        }

        IconTextSwitch {
            id: beepSwitch
            checked: Settings.getBoolean(Settings.keys.SOUND)
            text: qsTr("Detection sound")
            icon.source: "image://theme/icon-m-speaker"
            onCheckedChanged: {
                Settings.setBoolean(Settings.keys.SOUND, checked)
            }
        }
    }
}
