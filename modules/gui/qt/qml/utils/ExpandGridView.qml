/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/
import QtQuick 2.11
import QtQuick.Controls 2.4

NavigableFocusScope {
    id: root

    /// cell Width
    property int cellWidth: 100
    // cell Height
    property int cellHeight: 100

    //margin to apply
    property int marginBottom: root.cellHeight / 2
    property int marginTop: root.cellHeight / 3

    //model to be rendered, model has to be passed twice, as they cannot be shared between views
    property alias model: topView.model
    property variant modelTop
    property int modelCount: 0

    property int currentIndex: 0

    /// the id of the item to be expanded
    property int expandIndex: -1
    //delegate to display the extended item
    property Component customDelegate: Item{}
    property Component expandDelegate: Item{}

    //signals emitted when selected items is updated from keyboard
    signal selectionUpdated( int keyModifiers, int oldIndex,int newIndex )
    signal selectAll()
    signal actionAtIndex(int index)

    property variant _retractCallback
    property int _newExpandIndex: -1

    property double _expandRetractSpeed: 1.

    function switchExpandItem(index) {
        if (index === expandIndex)
            _newExpandIndex = -1
        else
            _newExpandIndex = index

        expandIndex = _newExpandIndex
    }

    PropertyAnimation {
        id: animateRetractItem;
        target: panel;
        properties: "height"
        to: 0
        onStopped: {
            expandIndex = _newExpandIndex
        }
    }

    PropertyAnimation {
        id: animateExpandItem;
        target: panel;
        properties: "height"
        from: 0
    }

        // number of elements per row, for internal computation
        property int _colCount: Math.floor(width / root.cellWidth)
        property int _bottomContentY: contentY + height

        property bool _expandActive: root.expandIndex !== -1

        function _rowOfIndex( index ) {
            return Math.ceil( (index + 1) / flickable._colCount) - 1
        }

        //from KeyNavigableGridView
        function _yOfIndex( index ) {
            return flickable._rowOfIndex(index) * root.cellHeight
        }


            //Gridview visible above the expanded item
            Flickable {
                id: topView
                clip: true

                property variant model
                property Item expandItem: root.expandDelegate.createObject(contentItem, {"visible": false})

                anchors.fill: parent

                onWidthChanged: { layout() }
                onHeightChanged: { layout() }
                onContentYChanged: { layout() }

                function getNbItemsPerRow() {
                    return Math.max(Math.floor(width / root.cellWidth), 1)
                }

                function getItemRowCol(id) {
                    var nbItemsPerRow = getNbItemsPerRow()
                    var rowId = Math.floor(id / nbItemsPerRow)
                    var colId = id % nbItemsPerRow
                    return [colId, rowId]
                }

                function getItemPos(id) {
                    var rowCol = getItemRowCol(id)
                    return [rowCol[0] * root.cellWidth, rowCol[1] * root.cellHeight]
                }

                function getTopGridEndId() {
                    var ret
                    if (root.expandIndex !== -1) {
                        var rowCol = getItemRowCol(root.expandIndex)
                        var rowId = rowCol[1] + 1
                        ret = rowId * getNbItemsPerRow()
                    } else {
                        ret = model.count
                    }
                    return ret
                }

                property variant idChildrenMap: ({})

                function getFirstAndLastInstanciatedItemIds() {
                    var contentYWithoutExpand = contentY
                    if (root.expandIndex !== -1) {
                        if (contentY >= expandItem.y && contentY < expandItem.y + expandItem.height)
                            contentYWithoutExpand = expandItem.y
                        if (contentY >= expandItem.y + expandItem.height)
                            contentYWithoutExpand = contentY - expandItem.height
                    }

                    var rowId = Math.floor(contentYWithoutExpand / root.cellHeight)
                    var firstId = Math.max(rowId * getNbItemsPerRow(), 0)

                    rowId = Math.ceil((contentYWithoutExpand + height) / root.cellHeight)
                    var lastId = Math.min(rowId * getNbItemsPerRow(), model.count - 1)
                    console.log([firstId, lastId])
                    return [firstId, lastId]
                }

                function getChild(id, toUse) {
                    var ret
                    if (id in idChildrenMap) {
                        ret = idChildrenMap[id]
                    }
                    else {
                        /*if (toUse.length === 0)
                            throw "Not enough created delegates: " + Object.keys(idChildrenMap).length;*/
                        ret = toUse.pop()
                        idChildrenMap[id] = ret
                    }

                    if (ret === undefined)
                        throw "could not get child"

                    return ret
                }

                function layout() {
                    var i
                    var topGridEndId = getTopGridEndId()

                    var f_l = getFirstAndLastInstanciatedItemIds()
                    var nbItems = f_l[1] - f_l[0]
                    var firstId = f_l[0]
                    var lastId = f_l[1]

                    // Clean the no longer used ids
                    var toKeep = {}
                    var toUse = []
                    for (var id in idChildrenMap) {
                        var val = idChildrenMap[id]
                        if (id >= firstId && id < lastId)
                            toKeep[id] = val
                        else {
                            toUse.push(val)
                            val.visible = false
                        }
                    }
                    idChildrenMap = toKeep

                    /*console.log("nbItems", nbItems)

                    console.log("toKeep: ", Object.keys(toKeep).length)
                    console.log("toUse: ", toUse.length)

                    console.log("firstId", firstId)
                    console.log("lastId", lastId)
                    console.log("topGridEndId", topGridEndId)*/

                    // Create delegates if we do not have enough
                    if (nbItems > toUse.length + Object.keys(toKeep).length) {
                        var toCreate = nbItems - (toUse.length + Object.keys(toKeep).length)
                        console.log("tocreate", toCreate)
                        for (i = 0; i < toCreate; ++i) {
                            val = root.customDelegate.createObject(contentItem);
                            toUse.push(val)
                        }
                    }

                    for (i = firstId; i < Math.min(topGridEndId, lastId); ++i) {
                        var pos = getItemPos(i)
                        var item = getChild(i, toUse)
                        item.model = model.items.get(i).model
                        item.index = i
                        item.x = pos[0]
                        item.y = pos[1]
                        item.visible = true
                    }

                    expandItem.y = getItemPos(topGridEndId)[1]

                    for (i = topGridEndId; i < lastId; ++i) {
                        pos = getItemPos(i)
                        item = getChild(i, toUse)
                        item.model = model.items.get(i).model
                        item.index = i
                        item.x = pos[0]
                        item.y = pos[1] + expandItem.height
                        item.visible = true
                    }

                    var newContentHeight = getItemPos(model.count - 1)[1] + root.cellHeight
                    if (root.expandIndex != -1)
                        newContentHeight += expandItem.height

                    contentHeight = newContentHeight
                }

                Connections {
                    target: model.items
                    onChanged: {
                        topView.layout()
                    }
                }

                Connections {
                    target: root
                    onExpandIndexChanged: {
                        if (root.expandIndex !== -1)
                            topView.expandItem.visible = true
                        else
                            topView.expandItem.visible = false
                        topView.layout()
                    }
                }

                Connections {
                    target: topView.expandItem
                    onHeightChanged: {
                        topView.layout()
                    }
                }
            }

    PropertyAnimation {
        id: animateContentY;
        target: flickable;
        properties: "contentY"
    }

    function animateFlickableContentY( newContentY ) {
        animateContentY.stop()
        if (newContentY === flickable.contentY) {
            console.log("newContentY === flickable.contentY: ", newContentY)
            flickable.contentY = newContentY
        } else {
            animateContentY.duration = Math.abs(newContentY - flickable.contentY) / 0.5
            animateContentY.to = newContentY
            animateContentY.start()
        }
    }

    onCurrentIndexChanged: {
        var newContentY = flickable.contentY;
        if ( flickable._yOfIndex(root.currentIndex) + root.cellHeight > flickable._bottomContentY) {
            console.log("onCurrentIndexChanged")
            //move viewport to see expanded item bottom
            newContentY = Math.min(
                        flickable._yOfIndex(root.currentIndex) + root.cellHeight - flickable.height,
                        flickable.contentHeight - flickable.height)
        } else if (flickable._yOfIndex(root.currentIndex) < flickable.contentY) {
            //move viewport to see expanded item at top
            newContentY = Math.max(
                        flickable._yOfIndex(root.currentIndex),
                        0)
        }

        animateFlickableContentY(newContentY)
    }

    Keys.onPressed: {
        var newIndex = -1
        if (event.key === Qt.Key_Right || event.matches(StandardKey.MoveToNextChar)) {
            if ((root.currentIndex + 1) % flickable._colCount !== 0) {//are we not at the end of line
                newIndex = Math.min(root.modelCount - 1, root.currentIndex + 1)
            }
        } else if (event.key === Qt.Key_Left || event.matches(StandardKey.MoveToPreviousChar)) {
            if (root.currentIndex % flickable._colCount !== 0) {//are we not at the begining of line
                newIndex = Math.max(0, root.currentIndex - 1)
            }
        } else if (event.key === Qt.Key_Down || event.matches(StandardKey.MoveToNextLine) ||event.matches(StandardKey.SelectNextLine) ) {
            if (Math.floor(root.currentIndex / flickable._colCount) !== Math.floor(root.modelCount / flickable._colCount)) { //we are not on the last line
                newIndex = Math.min(root.modelCount - 1, root.currentIndex + flickable._colCount)
            }
        } else if (event.key === Qt.Key_PageDown || event.matches(StandardKey.MoveToNextPage) ||event.matches(StandardKey.SelectNextPage)) {
            newIndex = Math.min(root.modelCount - 1, root.currentIndex + flickable._colCount * 5)
        } else if (event.key === Qt.Key_Up || event.matches(StandardKey.MoveToPreviousLine) ||event.matches(StandardKey.SelectPreviousLine)) {
             if (Math.floor(root.currentIndex / flickable._colCount) !== 0) { //we are not on the first line
                newIndex = Math.max(0, root.currentIndex - flickable._colCount)
             }
        } else if (event.key === Qt.Key_PageUp || event.matches(StandardKey.MoveToPreviousPage) ||event.matches(StandardKey.SelectPreviousPage)) {
            newIndex = Math.max(0, root.currentIndex - flickable._colCount * 5)
        }

        if (newIndex != -1 && newIndex != root.currentIndex) {
            event.accepted = true
            var oldIndex = currentIndex
            currentIndex = newIndex
            root.selectionUpdated(event.modifiers, oldIndex, newIndex)
        }

        if (!event.accepted)
            defaultKeyAction(event, currentIndex)
    }

    Keys.onReleased: {
        if (event.matches(StandardKey.SelectAll)) {
            event.accepted = true
            root.selectAll()
        } else if (event.key === Qt.Key_Space || event.matches(StandardKey.InsertParagraphSeparator)) { //enter/return/space
            event.accepted = true
            root.actionAtIndex(root.currentIndex)
        }
    }
}
