/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Toolbar

Item {
    implicitWidth:      mainLayout.width + _widthMargin

    property var  _activeVehicle:           QGroundControl.multiVehicleManager.activeVehicle
    property real _toolIndicatorMargins:    ScreenTools.defaultFontPixelHeight * 0.3
    property real _widthMargin:             _toolIndicatorMargins * 2

    Rectangle {
        width:              parent.width
        height:             parent.height * 0.8
        anchors.centerIn:   parent
        color:              qgcPal.windowTransparent
        radius:             ScreenTools.defaultFontPixelHeight / 4
        border.color:       qgcPal.groupBorder
        border.width:       1

        Row {
            id:                 mainLayout
            anchors.margins:    _toolIndicatorMargins
            anchors.left:       parent.left
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            spacing:            ScreenTools.defaultFontPixelWidth

            Repeater {
                id:     appRepeater
                model:  QGroundControl.corePlugin.toolBarIndicators

                Loader {
                    anchors.top:        parent.top
                    anchors.bottom:     parent.bottom
                    source:             modelData
                    visible:            item.showIndicator
                }
            }

            Repeater {
                id:     toolIndicatorsRepeater
                model:  _activeVehicle ? _activeVehicle.toolIndicators : []

                Loader {
                    anchors.top:        parent.top
                    anchors.bottom:     parent.bottom
                    source:             modelData
                    visible:            item.showIndicator
                }
            }
        }
    }
}
