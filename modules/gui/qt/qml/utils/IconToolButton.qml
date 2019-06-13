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

ToolButton {
    id: control
    property color color: control.checked
                        ? (control.activeFocus ? VLCStyle.colors.accent : VLCStyle.colors.bgHover )
                        : VLCStyle.colors.buttonText
    property int size: VLCStyle.icon_normal

    property color highlightColor: VLCStyle.colors.accent

    padding: 0

    contentItem: Item {

        Rectangle {
            anchors.fill: parent
            visible: control.activeFocus || control.hovered || control.highlighted
            color: highlightColor
        }

        Label {
            text: control.text
            color: control.color

            anchors.centerIn: parent

            font.pixelSize: control.size
            font.family: VLCIcons.fontFamily

            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
    }

    background: Rectangle {
        implicitHeight: control.size
        implicitWidth: control.size
        color: "transparent"
    }
}
