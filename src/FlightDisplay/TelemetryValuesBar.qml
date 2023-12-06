/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Vehicle
import QGroundControl.Controls
import QGroundControl.Palette

Rectangle {
    id:                 telemetryPanel
    height:             telemetryLayout.height + (_toolsMargin * 2)
    width:              telemetryLayout.width + (_toolsMargin * 2)
    color:              Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5) //"transparent"
    radius:             ScreenTools.defaultFontPixelWidth / 2

    DeadMouseArea { anchors.fill: parent }

    RowLayout {
        id:                 telemetryLayout
        anchors.margins:    _toolsMargin
        anchors.bottom:     parent.bottom
        anchors.left:       parent.left

        QGCColoredImage {
            visible:            mouseArea.containsMouse || valueArea.settingsUnlocked
            source:             valueArea.settingsUnlocked ? "/res/LockOpen.svg" : "/res/pencil.svg"
            mipmap:             true
            width:              ScreenTools.minTouchPixels * 0.75
            height:             width
            sourceSize.width:   width
            color:              qgcPal.text
            fillMode:           Image.PreserveAspectFit

            QGCMouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onClicked:    valueArea.settingsUnlocked = !valueArea.settingsUnlocked
            }
        }

        HorizontalFactValueGrid {
            id:                     valueArea
            userSettingsGroup:      telemetryBarUserSettingsGroup
            defaultSettingsGroup:   telemetryBarDefaultSettingsGroup
        }
    }

    QGCMouseArea {
        id:                         mouseArea
        x:                          telemetryLayout.x
        y:                          telemetryLayout.y
        width:                      valueArea.settingsUnlocked ? (telemetryLayout.width - ScreenTools.minTouchPixels / 2) : telemetryLayout.width
        height:                     valueArea.settingsUnlocked ? (telemetryLayout.height - ScreenTools.minTouchPixels / 2) : telemetryLayout.height
        hoverEnabled:               !ScreenTools.isMobile
        propagateComposedEvents:    true

        onClicked: (mouse) => {
            if (ScreenTools.isMobile && !valueArea.settingsUnlocked) {
                valueArea.settingsUnlocked = true
                mouse.accepted = true
            } else {
                mouse.accepted = false
            }
        }
    }
}
