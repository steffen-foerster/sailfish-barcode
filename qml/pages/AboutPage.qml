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
    id: aboutPage

    SilicaFlickable {
        id: aboutPageFlickable
        anchors.fill: parent
        contentHeight: aboutColumn.height

        Column {
            PageHeader {
                title: qsTr("About CodeReader")
            }

            id: aboutColumn
            anchors { left: parent.left; right: parent.right }
            height: childrenRect.height

            LabelText {
                anchors {
                    left: parent.left
                    margins: Theme.paddingLarge
                }
                label: qsTr("About CodeReader")
                text: qsTr("This app demonstrates a bar code reader for Sailfish OS. \
I hope it is useful for other projects. CodeReader is open source and licensed under the MIT License.")
                separator: true
            }

            LabelText {
                anchors {
                    left: parent.left
                    margins: Theme.paddingLarge
                }
                label: qsTr("Restriction")
                text: qsTr("This app prevents a scan if the Jolla Camera app is running. \
This restriction helps to avoid an interference of the Camera app.")
                separator: true
            }

            LabelText {
                anchors {
                    left: parent.left
                    margins: Theme.paddingLarge
                }
                label: qsTr("Version")
                text: getVersion()
                separator: true
            }

            LabelText {
                anchors {
                    left: parent.left
                    margins: Theme.paddingLarge
                }
                label: qsTr("Author")
                text: "Steffen Förster"
                separator: true
            }

            LabelText {
                anchors {
                    left: parent.left
                    margins: Theme.paddingLarge
                }
                label: qsTr("Contributors")
                text: "Diego Russo, Åke Engelbrektson, Dominik Chrástecký, Miklós Márton"
                separator: true
            }

            BackgroundItem {
                id: clickableUrl
                contentHeight: labelUrl.height
                height: contentHeight
                width: aboutPageFlickable.width
                anchors {
                    left: parent.left
                }

                LabelText {
                    id: labelUrl
                    anchors {
                        left: parent.left
                        margins: Theme.paddingLarge
                    }
                    label: qsTr("Source code")
                    text: "https://github.com/steffen-foerster/sailfish-barcode"
                    color: clickableUrl.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                onClicked: {
                    openInDefaultApp("https://github.com/steffen-foerster/sailfish-barcode");
                }
            }

            LabelText {
                anchors {
                    left: parent.left
                    margins: Theme.paddingLarge
                }
                label: qsTr("References")
                text: qsTr("This project uses code and ideas of other projects, see README.md on Github.")
                separator: true
            }

            LabelText {
                anchors {
                    left: parent.left
                    margins: Theme.paddingLarge
                }
                label: qsTr("Supported 1D/2D bar codes")
                text: qsTr("Image source: http://wikipedia.de")
                separator: false
            }

            ListModel {
                id: imageModel
                ListElement {
                    name: "QR code"
                    imgSrc: "img/qr-code_240.png"
                }
                ListElement {
                    name: "Aztec"
                    imgSrc: "img/aztec_240.png"
                }
                ListElement {
                    name: "Data Matrix"
                    imgSrc: "img/datamatrix_240.png"
                }
                ListElement {
                    name: "Code 128"
                    imgSrc: "img/code-128_240.png"
                }
                ListElement {
                    name: "EAN 13"
                    imgSrc: "img/ean-13_240.png"
                }
                ListElement {
                    name: "Interleaved 2/5"
                    imgSrc: "img/interleaved_240.png"
                }
                ListElement {
                    name: "UPC-A"
                    imgSrc: "img/upc_240.png"
                }
            }

            SilicaGridView {
                id: grid
                width: parent.width
                height: 180 * Math.ceil(imageModel.length / 2)
                cellWidth: Screen.width / 2
                cellHeight: 180
                quickScroll: false
                interactive: false
                model: imageModel
                Component.onCompleted: {
                    if (Screen.width / 5 > 180) {
                        grid.cellWidth = Screen.width / 5;
                        grid.height = grid.cellHeight * Math.ceil(imageModel.count / 5);
                    }
                    else if (Screen.width / 4 > 180) {
                        grid.cellWidth = Screen.width / 4;
                        grid.height = grid.cellHeight * Math.ceil(imageModel.count / 4);
                    }
                    else if (Screen.width / 3 > 180) {
                        grid.cellWidth = Screen.width / 3;
                        grid.height = grid.cellHeight * Math.ceil(imageModel.count / 3);
                    }
                }

                delegate: Item {
                    width: grid.cellWidth
                    height: grid.cellHeight

                    Image {
                        source: imgSrc;
                        anchors {
                            centerIn: parent
                        }

                        Text {
                            text: name;
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: "black"
                            anchors {
                                bottomMargin: 2
                                bottom: parent.bottom
                                horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }
        }
    }

    VerticalScrollDecorator { flickable: aboutPageFlickable }
}
