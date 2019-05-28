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

import "qrc:///style/"
import "qrc:///utils/" as Utils

Utils.NavigableFocusScope {

    id: root

    width: content.width
    height: content.height

    property variant contentModel

    property bool expanded: false

    onExpandedChanged: {
        if (expanded) {
            searchBox.focus = true
            searchBox.placeholderText = qsTr("filter")
            filter.KeyNavigation.right = searchBox
            animateExpand.start()
        }
        else {
            searchBox.placeholderText = ""
            searchBox.text = ""
            filter.focus = true
            filter.KeyNavigation.right = null
            animateRetract.start()
        }
    }

    onActiveFocusChanged: {
        if (!activeFocus)
            expanded = false
    }

    PropertyAnimation {
        id: animateExpand;
        target: searchBox;
        properties: "width"
        duration: 200
        to: VLCStyle.widthSearchInput
    }

    PropertyAnimation {
        id: animateRetract;
        target: searchBox;
        properties: "width"
        duration: 200
        to: 0
    }

    MouseArea {
        id: mouseArea
        hoverEnabled: true

        onEntered: {
            if (!animateRetract.running)
                expanded = true
        }

        onExited: {
            if (!animateExpand.running)
                expanded = false
        }

        Row {
            id: content

            Utils.IconToolButton {
                id: filter

                size: VLCStyle.icon_normal
                text: VLCIcons.topbar_filter
                focus: true

                onClicked: {
                    expanded = !expanded
                }
            }

            TextField {
                id: searchBox

                anchors.verticalCenter: parent.verticalCenter

                font.pixelSize: VLCStyle.fontSize_normal

                color: VLCStyle.colors.buttonText
                width: 0

                background: Rectangle {
                    color: VLCStyle.colors.button
                    border.color: {
                        if ( searchBox.text.length < 3 && searchBox.text.length !== 0 )
                            return VLCStyle.colors.alert
                        else if ( searchBox.activeFocus )
                            return VLCStyle.colors.accent
                        else
                            return VLCStyle.colors.buttonBorder
                   }
                }

                onTextChanged: {
                    if (contentModel !== undefined)
                        contentModel.searchPattern = text;
                }
            }
        }
    }
}
