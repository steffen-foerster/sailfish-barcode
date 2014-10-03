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

Page {
    id: historyPage

    SilicaListView {
        id: historyList

        property Item contextMenu

        anchors.fill: parent
        width: parent.width
        spacing: 0

        PullDownMenu {
            MenuItem {
                text: qsTr("Remove all")
                onClicked: {
                    removeAll();
                }
            }
        }

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
                var historyItem = historyList.get(index)
                if (Utils.isLink(historyItem.value)) {
                    openInDefaultApp(historyItem.value)
                }
                else {
                    pageStack.push("TextPage.qml", {text: historyItem.value})
                }
            }

            onPressAndHold: {
                if (!bookmarkList.contextMenu) {
                    bookmarkList.contextMenu =
                            contextMenuComponent.createObject(bookmarkList)
                }
                bookmarkList.contextMenu.index = index
                bookmarkList.contextMenu.show(wrapper);
            }

            Column {
                id: itemColumn
                Rectangle {
                    height: Theme.paddingLarge / 2
                    width: wrapper.ListView.view.width
                    opacity: 0
                }
                Label {
                    id: lbTitle
                    anchors {
                        left: parent.left
                        margins: Theme.paddingLarge
                    }
                    color: wrapper.highlighted ? Theme.highlightColor : Theme.primaryColor
                    font {
                        pixelSize: Theme.fontSizeSmall
                        bold: model.toread === 'yes'
                    }
                    wrapMode: Text.Wrap
                    text: model.title
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
                    text: Utils.formatTimestamp(model.time)
                    Image {
                        anchors {
                            verticalCenter: lbCreated.verticalCenter
                            left: lbCreated.right
                            leftMargin: Theme.paddingMedium
                        }
                        height: Theme.iconSizeSmall
                        fillMode: Image.PreserveAspectFit
                        source: "image://theme/icon-m-device-lock"
                        visible: model.shared === 'no'
                    }
                }
                Rectangle {
                    height: Theme.paddingLarge / 2
                    width: wrapper.ListView.view.width
                    opacity: 0
                }
            }
        }

        Component {
            id: contextMenuComponent
            ContextMenu {
                property variant index

                MenuItem {
                    text: qsTr("Open in default browser")
                    onClicked: {
                        openInDefaultBrowser(bookmarkModel.get(index).href);
                    }
                }
                MenuItem {
                    text: qsTr("Delete")
                    onClicked: {
                        remorse.execute(bookmarkList.contextMenu.parent,
                                        "Deleting",
                                        getDeleteFunction(bookmarkModel, index),
                                        3000)
                    }
                    visible: root.state === "PINBOARD" || root.state === "PHONE"
                }
                MenuItem {
                    text: qsTr("Copy URL to clipboard")
                    onClicked: {
                        Clipboard.text = bookmarkModel.get(index).href
                    }
                }

                function getDeleteFunction(model, index) {
                    // Removing from list destroys the ListElement so we need a copy
                    var itemToDelete = Bookmark.copy(model.get(index));
                    var f = function() {
                        model.remove(index);
                        getServiceManager().deleteBookmark(itemToDelete,
                            function() {
                                window.bookmarksUpdated();
                            },
                            function(error) {
                                bookmarkModel.insert(index, itemToDelete)
                                infoPanel.showError(error);
                            }
                        )
                    }
                    return f;
                }
            }
        }

        RemorseItem { id: remorse }

        VerticalScrollDecorator {}

        ViewPlaceholder {
            id: placeHolder
            enabled: histroyModel.count === 0
            text: qsTr("History is empty")
        }
    }
}
