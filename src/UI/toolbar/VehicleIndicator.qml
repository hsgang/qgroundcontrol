/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

//-------------------------------------------------------------------------
Item {
    id:             control
    width:          vehicleRow.width
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator:        _activeVehicle.parameterManager.parametersReady
    property real _margins:             ScreenTools.defaultFontPixelHeight / 2
    property var _activeVehicle:        QGroundControl.multiVehicleManager.activeVehicle
    property bool _communicationLost:   _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false

    Row {
        id: vehicleRow
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: ScreenTools.defaultFontPixelHeight / 5

        QGCColoredImage {
            id:                 roiIcon
            width:              height
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            anchors.margins:    ScreenTools.defaultFontPixelHeight / 4
            source:             "/qmlimages/vehicleQuadRotor.svg"
            color:              _activeVehicle.readyToFlyAvailable && _activeVehicle.readyToFly && !_communicationLost ? qgcPal.windowTransparentText : qgcPal.colorGrey
            fillMode:           Image.PreserveAspectFit
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            QGCLabel {
                anchors.left:   parent.left
                color:          qgcPal.buttonText
                font.pointSize: ScreenTools.smallFontPointSize
                text:           _activeVehicle ? "ID"+_activeVehicle.id : ""
            }

            QGCLabel {
                anchors.left:   parent.left
                color:          qgcPal.buttonText
                font.pointSize: ScreenTools.defaultFontPointSize
                text:           _activeVehicle ? _activeVehicle.imuTemp.valueString + "°C" : ""
            }
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorDrawer(vehicleIndicatorPage, control)
    }

    Component {
        id: vehicleIndicatorPage

        VehicleIndicatorPage {

        }
    }
}
