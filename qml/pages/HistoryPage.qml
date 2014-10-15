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

import "../js/History.js" as History
import "../js/Utils.js" as Utils

Page {
    id: historyPage

    function getValueText(value) {
        if (Utils.isLink(value)) {
            return value
        }
        else {
            return Utils.removeLineBreak(value)
        }
    }

    Component.onCompleted: {
        var values = History.getAllHistoryValues()
        for (var i = 0; i < values.length; i++) {
            historyModel.append(values[i])
        }
    }

    SilicaListView {
        id: historyList

        property Item contextMenu

        anchors.fill: parent

        width: parent.width
        spacing: 0

        header: commonHeader

        model: ListModel {
            id: historyModel
        }

        delegate: ListItem {
            id: wrapper
            property bool menuOpen: {
                historyList.contextMenu != null
                        && historyList.contextMenu.parent === wrapper
            }

            contentHeight: {
                menuOpen ? historyList.contextMenu.height + itemColumn.height
                         : itemColumn.height
            }

            onClicked: {
                var historyItem = historyModel.get(index)
                if (Utils.isLink(historyItem.value)) {
                    openInDefaultApp(historyItem.value)
                }
                else {
                    pageStack.push("TextPage.qml", {text: historyItem.value})
                }
            }

            onPressAndHold: {
                if (!historyList.contextMenu) {
                    historyList.contextMenu = contextMenuComponent.createObject(historyList)
                }
                historyList.contextMenu.index = index
                historyList.contextMenu.show(wrapper)
            }

            ListView.onRemove: RemoveAnimation {
                target: wrapper
            }

            Column {
                id: itemColumn
                Rectangle {
                    height: Theme.paddingLarge / 2
                    width: wrapper.ListView.view.width
                    opacity: 0
                }
                Label {
                    id: lbValue
                    anchors {
                        left: parent.left
                        margins: Theme.paddingLarge
                    }
                    color: wrapper.highlighted ? Theme.highlightColor : Theme.primaryColor
                    font {
                        pixelSize: Theme.fontSizeSmall
                    }
                    truncationMode: TruncationMode.Fade
                    text: getValueText(model.value)
                    width: wrapper.ListView.view.width - (2 * Theme.paddingLarge)
                }
                Label {
                    id: lbCreated
                    anchors {
                        left: parent.left
                        margins: Theme.paddingLarge
                    }
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    text: Utils.formatTimestamp(model.timestamp)
                }
                Rectangle {
                    height: Theme.paddingLarge / 2
                    width: wrapper.ListView.view.width
                    opacity: 0
                }
            }
        }

        PullDownMenu {
            visible: historyModel.count > 0
            MenuItem {
                text: qsTr("Delete all")
                onClicked: {
                    remorsePopup.execute(qsTr("Deleting all"),
                        function() {
                            History.removeAllHistoryValues()
                            historyModel.clear()
                        },
                        5000)
                }
            }
        }

        Component {
            id: contextMenuComponent
            ContextMenu {
                property variant index

                MenuItem {
                    text: qsTr("Delete")
                    onClicked: {
                        remorse.execute(historyList.contextMenu.parent,
                                        qsTr("Deleting"),
                                        getDeleteFunction(historyModel, index),
                                        2000)
                    }
                }
                MenuItem {
                    text: qsTr("Copy to clipboard")
                    onClicked: {
                        Clipboard.text = historyModel.get(index).value
                    }
                }

                function getDeleteFunction(model, index) {
                    // Removing from list destroys the ListElement so we need a copy
                    var valueToDelete = History.copyValue(model.get(index));
                    var f = function() {
                        model.remove(index)
                        History.removeHistoryValue(valueToDelete)
                    }
                    return f
                }
            }
        }

        RemorseItem {
            id: remorse
        }

        RemorsePopup {
            id: remorsePopup
        }

        VerticalScrollDecorator {
            parent: view
            flickable: view
        }

        ViewPlaceholder {
            id: placeHolder
            enabled: historyModel.count === 0
            text: qsTr("History is empty")
        }
    }

    Component {
        id: commonHeader

        Column {
            width: historyPage.width

            PageHeader {
                title: qsTr("History")
                height: Theme.itemSizeLarge
            }
        }
    }
}
