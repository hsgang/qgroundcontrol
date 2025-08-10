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

Rectangle {
    id:                 modeChangedIndicator
    anchors.margins:    ScreenTools.defaultFontPixelHeight
    height:             modeIndicatorCol.height * 1.1
    width:              modeIndicatorCol.width * 1.2
    color:              Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
    radius:             ScreenTools.defaultFontPixelWidth * 1.7
    visible:            false

    property var  _activeVehicle:       QGroundControl.multiVehicleManager.activeVehicle
    property var  flightMode:       _activeVehicle && _activeVehicle.flightMode

    onFlightModeChanged: {
        _activeVehicle ? modeChangedIndicator.visible = true : ""
        _activeVehicle ? opacityAnimator.restart() : ""
    }

    OpacityAnimator {
        id: opacityAnimator
        target: modeChangedIndicator;
        from: 1;
        to: 0;
        duration: 3000;
        easing.type: Easing.InQuint;
        running: true;
    }

    Column {
        id:         modeIndicatorCol
        spacing:    ScreenTools.defaultFontPixelHeight * 0.2
        anchors.centerIn: parent

        QGCLabel {
            anchors.horizontalCenter:   parent.horizontalCenter
            color:                      qgcPal.textHighlight
            font.pointSize:             ScreenTools.mediumFontPointSize
            text:                       qsTr("Switched to")
        }

        QGCLabel {
            anchors.horizontalCenter:   parent.horizontalCenter
            color:                      qgcPal.textHighlight
            font.pointSize:             ScreenTools.largeFontPointSize * 1.5
            font.weight:                Font.DemiBold
            text:                       flightMode
        }
    }
}

