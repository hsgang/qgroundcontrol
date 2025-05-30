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
import QGroundControl.ScreenTools
import QGroundControl.Toolbar
import QGroundControl.Controls

//-------------------------------------------------------------------------
//-- Toolbar Indicators
Row {
    id:                 indicatorRow
    anchors.top:        parent.top
    anchors.bottom:     parent.bottom
    anchors.margins:    _toolIndicatorMargins
    spacing:            ScreenTools.defaultFontPixelWidth

    property var  _activeVehicle:           QGroundControl.multiVehicleManager.activeVehicle
    property real _toolIndicatorMargins:    ScreenTools.defaultFontPixelHeight * 0.66

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

//    Repeater {
//        model: _activeVehicle ? _activeVehicle.modeIndicators : []
//        Loader {
//            anchors.top:        parent.top
//            anchors.bottom:     parent.bottom
//            source:             modelData
//            visible:            item.showIndicator
//        }
//    }

//    Repeater {
//        id:     appRepeater
//        model:  QGroundControl.corePlugin.toolBarIndicators
//        Loader {
//            anchors.top:        parent.top
//            anchors.bottom:     parent.bottom
//            source:             modelData
//            visible:            item.showIndicator
//        }
//    }
}
