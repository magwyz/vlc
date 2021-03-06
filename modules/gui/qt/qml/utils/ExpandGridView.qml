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
    property alias modelTop: topView.model
    property alias modelBottom: bottomView.model
    property int modelCount: 0

    property alias delegateTop: topView.delegate
    property alias delegateBottom: bottomView.delegate

    property int currentIndex: 0

    /// the id of the item to be expanded
    property int expandIndex: -1
    //delegate to display the extended item
    property Component expandDelegate: Item{}

    //signals emitted when selected items is updated from keyboard
    signal selectionUpdated( int keyModifiers, int oldIndex,int newIndex )
    signal selectAll()
    signal actionAtIndex(int index)

    property alias contentY: flickable.contentY
    property alias interactive: flickable.interactive
    property alias clip: flickable.clip
    property alias contentHeight: flickable.contentHeight
    property alias contentWidth: flickable.contentWidth

    //compute a delta that can be applied to grid elements to obtain an horizontal distribution
    function shiftX( index ) {
        var rightSpace = width - (flickable._colCount * root.cellWidth)
        return ((index % flickable._colCount) + 1) * (rightSpace / (flickable._colCount + 1))
    }

    property variant _retractCallback
    property int _newExpandIndex: -1

    property double _expandRetractSpeed: 1.

    function switchExpandItem(index) {
        if (index === expandIndex)
            _newExpandIndex = -1
        else
            _newExpandIndex = index

        if (expandIndex !== -1) {
            animateRetractItem.duration = expandItem.height / _expandRetractSpeed
            animateRetractItem.start()
        }
        else
            expandIndex = _newExpandIndex
    }

    function _expand() {
        if (expandIndex !== -1) {
            //move viewport to see expanded item at top
            var newContentY = Math.min(
                flickable._rowOfIndex(root.expandIndex) * root.cellHeight,
                Math.max(flickable.contentHeight + expandItem.height - flickable.height, 0)
            )
            animateFlickableContentY(newContentY)

            // Expand the item
            animateExpandItem.stop()
            animateExpandItem.duration = expandItem.height / _expandRetractSpeed
            animateExpandItem.to = expandItem.height
            animateExpandItem.start()
        }
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

    Connections {
        target: expandItem
        onHeightChanged: {
            _expand()
        }
    }

    Flickable {
        id: flickable

        anchors.fill: parent
        clip: true

        //ScrollBar.vertical: ScrollBar { }

        //disable bound behaviors to avoid visual artifacts around the expand delegate
        boundsBehavior: Flickable.StopAtBounds


        // number of elements per row, for internal computation
        property int _colCount: Math.floor(width / root.cellWidth)
        property int _bottomContentY: flickable.contentY + flickable.height

        property bool _expandActive: root.expandIndex !== -1

        contentHeight: col.height

        function _rowOfIndex( index ) {
            return Math.ceil( (index + 1) / flickable._colCount) - 1
        }

        //from KeyNavigableGridView
        function _yOfIndex( index ) {
            return flickable._rowOfIndex(index) * root.cellHeight
        }

        Column {
            id: col
            width: parent.width
            spacing: 0

            //Gridview visible above the expanded item
            GridView {
                id: topView
                clip: true
                interactive: false

                focus: !flickable._expandActive

                highlightFollowsCurrentItem: false
                currentIndex: root.currentIndex

                cellWidth: root.cellWidth
                cellHeight: root.cellHeight

                anchors.left: parent.left
                anchors.right: parent.right

                states: [
                    //expand is unactive or below the view
                    State {
                        name: "noexpand"
                        when: !flickable._expandActive
                        PropertyChanges {
                            target: topView
                            height: contentHeight
                        }
                    },
                    //expand is active and within the view
                    State {
                        name: "expand"
                        when: flickable._expandActive
                        PropertyChanges {
                            target: topView
                            height: flickable._yOfIndex( root.expandIndex ) + root.cellHeight
                        }
                    }
                ]
            }
            //Expanded item view
            Flickable {
                id: panel

                clip: true
                width: parent.width
                height: 0

                Loader {
                    id: expandItem
                    sourceComponent: root.expandDelegate
                    focus: flickable._expandActive
                    anchors.left: parent.left
                    anchors.right: parent.right
                    onLoaded: console.log("onLoaded")
                }
            }



            //Gridview visible below the expand item
            GridView {
                id: bottomView
                clip: true
                interactive: false
                highlightFollowsCurrentItem: false

                cellWidth: root.cellWidth
                cellHeight: root.cellHeight

                anchors.left: parent.left
                anchors.right: parent.right

                states: [
                    //expand is unactive or below the view
                    State {
                        name: "noexpand"
                        when: !flickable._expandActive
                        PropertyChanges {
                            target: bottomView
                            visible: false
                            enabled: false
                        }
                    },
                    //expand is active and within the view
                    State {
                        name: "expand"
                        when: flickable._expandActive
                        PropertyChanges {
                            target: bottomView
                            contentY: flickable._yOfIndex( root.expandIndex ) + root.cellHeight
                            height: contentHeight - contentY
                            visible: true
                            enabled: true
                        }
                    }
                ]
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

    onExpandIndexChanged: {
        _expand()
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
