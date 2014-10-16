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

import "../components"

Page {
    id: settingsPage

    PageHeader {
        id: pageTitle
        title: qsTr("Settings %1/2").arg(mainView.currentIndex + 1)
    }

    Rectangle {
        id: settingsContent
        color: Theme.rgba(Theme.highlightColor, 0.1)

        anchors {
            topMargin: Screen.width * 1/3
            top: pageTitle.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
    }

    Rectangle {
        anchors {
            topMargin: Screen.width * 1/3
            top: pageTitle.bottom
        }
        color: Theme.highlightColor
        height: 2
        width: parent.width
        x: 0
    }

    SlideshowView {
        id: mainView

        itemWidth: width
        itemHeight: height
        height: Screen.height - (pageTitle.height + (Screen.width * 1/3 + Theme.paddingLarge)
                                 + viewIndicator.height + tabHeader.childrenRect.height)
        clip:true

        anchors {
            topMargin: (Screen.width * 1/3 + Theme.paddingLarge)
            top: pageTitle.bottom
            left: parent.left
            right: parent.right
        }
        model: VisualItemModel {
            Settings1View { id: settings1View }
            Settings2View { id: settings2View }
        }
    }

    Rectangle {
        id: viewIndicator
        anchors.top: mainView.bottom
        color: Theme.highlightColor
        height: Theme.paddingSmall
        width: mainView.width / mainView.count
        x: mainView.currentIndex * width
        z: 2

        Behavior on x {
            NumberAnimation {
                duration: 200
            }
        }
    }

    Rectangle {
        anchors.top: mainView.bottom
        color: "black"
        opacity: 0.5
        height: Theme.paddingMedium
        width: mainView.width
        z: 1
    }

    Row {
        id: tabHeader
        anchors.top: viewIndicator.bottom

        Repeater {
            model: [qsTr("Scan and history"), qsTr("Marker")]
            Rectangle {
                color: "black"
                height: Theme.paddingLarge * 2
                width: mainView.width / mainView.count

                Label {
                    anchors.centerIn: parent
                    text: modelData
                    color: Theme.highlightColor
                    font {
                        bold: true
                        pixelSize: Theme.fontSizeExtraSmall
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var selectedIndex = parent.x === 0 ? 0 : 1
                        console.log("selected index: ", selectedIndex)
                        console.log("mainView.currentIndex: ", mainView.currentIndex)
                        if (selectedIndex !== mainView.currentIndex) {
                            mainView.incrementCurrentIndex()
                        }
                    }
                }
            }
        }
    }
}
