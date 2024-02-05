/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.11
import QtQuick.Layouts  1.11

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.Controllers           1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.FactControls          1.0

//-------------------------------------------------------------------------
Item {
    id:             _root
    width:          vehicleRow.width
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator: _activeVehicle.parameterManager.parametersReady
    property real _margins:     ScreenTools.defaultFontPixelHeight / 2
    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    Row {
        id: vehicleRow
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: ScreenTools.defaultFontPixelWidth / 2

        QGCColoredImage {
            id:                 roiIcon
            width:              height
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            sourceSize.height:  height
            source:             "/qmlimages/vehicleQuadRotor.svg"
            color:              _activeVehicle.readyToFlyAvailable && _activeVehicle.readyToFly ? qgcPal.colorGreen : qgcPal.text
            fillMode:           Image.PreserveAspectFit
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorDrawer(vehicleIndicatorPage)
    }

    Component {
        id: vehicleIndicatorPage

        VehicleIndicatorPage {

        }
    }
}
