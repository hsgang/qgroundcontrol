/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                      2.12
import QtQuick.Layouts              1.12

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0
import QGroundControl.Controls      1.0
import QGroundControl.Palette       1.0

Rectangle {
    id:                 telemetryPanel
    height:             telemetryLayout.height + _toolsMargin
    width:              telemetryLayout.width + (_toolsMargin * 2)
    color:              Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5) //"transparent"
    radius:             ScreenTools.defaultFontPixelWidth / 2

    property bool       editMode: false

    DeadMouseArea { anchors.fill: parent }

    RowLayout {
        id:                 telemetryLayout
        anchors.margins:    _toolsMargin * 0.5
        anchors.bottom:     parent.bottom
        anchors.left:       parent.left

        RowLayout {
            visible: telemetryPanel.editMode || valueArea.settingsUnlocked

            QGCColoredImage {
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
        }

        QGCMouseArea {
            id:                         mouseArea
            x:                          valueArea.x
            y:                          valueArea.y
            width:                      valueArea.width
            height:                     valueArea.height
            onClicked:                  telemetryPanel.editMode = !telemetryPanel.editMode
            //propagateComposedEvents:    true
        }

        HorizontalFactValueGrid {
            id:                     valueArea
            userSettingsGroup:      telemetryBarUserSettingsGroup
            defaultSettingsGroup:   telemetryBarDefaultSettingsGroup
        }
    }
}
