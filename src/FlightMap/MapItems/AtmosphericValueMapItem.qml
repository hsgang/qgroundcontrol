/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick              2.3
import QtLocation           5.3
import QtPositioning        5.3
import QtGraphicalEffects   1.0
import QtQuick.Layouts  1.2

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0
import QGroundControl.Controls      1.0
import QGroundControl.MultiVehicleManager 1.0

/// Marker for displaying a vehicle location on the map
MapQuickItem {
    property var    vehicle                                                         /// Vehicle object, undefined for ADSB vehicle
    property var    map
    property double altitude:       Number.NaN                                      ///< NAN to not show
    property string callsign:       ""                                              ///< Vehicle callsign
    property double heading:        vehicle ? vehicle.heading.value : Number.NaN    ///< Vehicle heading, NAN for none
    property real   size:           _adsbVehicle ? _adsbSize : _uavSize * 0.5            /// Size for icon
    property bool   alert:          false                                           /// Collision alert

    anchorPoint.x:  vehicleItem.width  / 2
    anchorPoint.y:  vehicleItem.height / 2
    visible:        coordinate.isValid

    property var    _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property real   _uavSize:       ScreenTools.defaultFontPixelHeight * 5
    property var    _map:           map
    property bool   _multiVehicle:  QGroundControl.multiVehicleManager.vehicles.count > 1

    property real _temperatureValue:  _activeVehicle ? _activeVehicle.atmosphericSensor.temperature.rawValue.toFixed(1) : 0
    property real _humidityValue:  _activeVehicle ? _activeVehicle.atmosphericSensor.humidity.rawValue.toFixed(1) : 0
    property real _pressureValue:  _activeVehicle ? _activeVehicle.atmosphericSensor.pressure.rawValue.toFixed(1) : 0
    property real _windDirValue:  _activeVehicle ? _activeVehicle.atmosphericSensor.windDir.rawValue.toFixed(1) : 0
    property real _windSpdValue:  _activeVehicle ? _activeVehicle.atmosphericSensor.windSpd.rawValue.toFixed(1) : 0


    sourceItem: Item {
        id:         vehicleItem
//        width:      atmosphericValueBar.width
//        height:     atmosphericValueBar.height
//        anchors.horizontalCenter: parent.horizontalCenter
//        anchors.top: parent.bottom
//        anchors.topMargin: _margins * 2

//        Rectangle {
//            id:                 vehicleShadow
//            anchors.fill:       vehicleIcon
//            color:              Qt.rgba(1,1,1,1)
//            radius:             width * 0.5
//            visible:            false
//        }

        Rectangle {
            id:         atmosphericValueBar
            height:     atmosphericValueGrid.height + ScreenTools.defaultFontPixelHeight * 0.2
            width:      atmosphericValueGrid.width + ScreenTools.defaultFontPixelWidth * 2
            anchors.horizontalCenter: parent.horizontalCenter
            //anchors.verticalCenter: parent.verticalCenter
            anchors.top: parent.bottom
            anchors.topMargin: ScreenTools.defaultFontPixelHeight * 2
            color:      "#80000000"
            radius:     _margins

            property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
            property real _temperatureValue:  _activeVehicle ? _activeVehicle.atmosphericSensor.temperature.rawValue.toFixed(1) : 0
            property real _humidityValue:  _activeVehicle ? _activeVehicle.atmosphericSensor.humidity.rawValue.toFixed(1) : 0
            property real _pressureValue:  _activeVehicle ? _activeVehicle.atmosphericSensor.pressure.rawValue.toFixed(1) : 0
            property real _windDirValue:  _activeVehicle ? _activeVehicle.atmosphericSensor.windDir.rawValue.toFixed(1) : 0
            property real _windSpdValue:  _activeVehicle ? _activeVehicle.atmosphericSensor.windSpd.rawValue.toFixed(1) : 0

            GridLayout {
                id:                 atmosphericValueGrid
                anchors.margins:    ScreenTools.defaultFontPixelHeight
                rowSpacing:      ScreenTools.defaultFontPixelWidth
                anchors.horizontalCenter: atmosphericValueBar.horizontalCenter
                anchors.verticalCenter:   atmosphericValueBar.verticalCenter
                columns: 3

                QGCLabel { text: qsTr("Temp:") }
                QGCLabel { text: _temperatureValue ? _temperatureValue : qsTr("--.--", "No data to display") }
                QGCLabel { text: "℃" }
                QGCLabel { text: qsTr("Humi:") }
                QGCLabel { text: _humidityValue ? _humidityValue : qsTr("--.--", "No data to display") }
                QGCLabel { text: "Rh%" }
                QGCLabel { text: qsTr("Press:") }
                QGCLabel { text: _pressureValue ? _pressureValue : qsTr("--.--", "No data to display") }
                QGCLabel { text: "hPa" }
                QGCLabel { text: qsTr("W/D:") }
                QGCLabel { text: _windDirValue ? _windDirValue : qsTr("--.--", "No data to display") }
                QGCLabel { text: "deg" }
                QGCLabel { text: qsTr("W/S:") }
                QGCLabel { text: _windSpdValue ? QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_windSpdValue).toFixed(1) : qsTr("--.--", "No data to display") }
                QGCLabel { text: QGroundControl.unitsConversion.appSettingsSpeedUnitsString  }
            }
        }
    }
}
