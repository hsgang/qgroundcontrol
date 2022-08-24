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
import QGroundControl.Palette       1.0

/// Marker for displaying a vehicle location on the map
MapQuickItem {
    anchorPoint.x:  vehicleItem.width  / 2
    anchorPoint.y:  vehicleItem.height / 2
    visible:        coordinate.isValid

    property var    map
    property var    _activeVehicle:       QGroundControl.multiVehicleManager.activeVehicle
    property var    _map:                 map

    property real   _temperatureValue:    _activeVehicle ? _activeVehicle.atmosphericSensor.temperature.rawValue.toFixed(1) : 0
    property real   _humidityValue:       _activeVehicle ? _activeVehicle.atmosphericSensor.humidity.rawValue.toFixed(1) : 0
    property real   _pressureValue:       _activeVehicle ? _activeVehicle.atmosphericSensor.pressure.rawValue.toFixed(1) : 0
    property real   _windDirValue:        _activeVehicle ? _activeVehicle.atmosphericSensor.windDir.rawValue.toFixed(1) : 0
    property real   _windSpdValue:        _activeVehicle ? _activeVehicle.atmosphericSensor.windSpd.rawValue.toFixed(1) : 0
    property real   _altitudeValue:       _activeVehicle ? _activeVehicle.altitudeRelative.rawValue.toFixed(1) : 0

    sourceItem: Item {
        id:         vehicleItem

        Rectangle {
            id:         atmosphericValueBar
            height:     atmosphericValueColumn.height + ScreenTools.defaultFontPixelHeight * 0.2
            width:      atmosphericValueColumn.width + ScreenTools.defaultFontPixelWidth * 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: ScreenTools.defaultFontPixelHeight * 3
            color:      "#80000000"
            radius:     _margins
            border.width: 1
            border.color: qgcPal.text

            Column{
                id:                 atmosphericValueColumn
                spacing:            ScreenTools.defaultFontPixelWidth
                width:              Math.max(atmosphericSensorViewLabel.width, atmosphericValueGrid.width)
                anchors.margins:    ScreenTools.defaultFontPixelHeight
                anchors.centerIn:   parent

                QGCLabel {
                    id:     atmosphericSensorViewLabel
                    text:   qsTr("Ext. Sensors")
                    font.family:    ScreenTools.demiboldFontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                GridLayout {
                    id:                         atmosphericValueGrid
                    anchors.margins:            ScreenTools.defaultFontPixelHeight
                    columnSpacing:              ScreenTools.defaultFontPixelWidth
                    anchors.horizontalCenter:   parent.horizontalCenter
                    //anchors.verticalCenter:     atmosphericValueColumn.verticalCenter
                    columns: 2

                    QGCLabel { text: qsTr("ALT"); opacity: 0.7}
                    QGCLabel { text: _altitudeValue ? QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_altitudeValue).toFixed(1) +" "+ QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString: "No data"}

                    QGCLabel { text: qsTr("TMP"); opacity: 0.7}
                    QGCLabel { text: _temperatureValue ? _temperatureValue +" ℃" : "No data"}

                    QGCLabel { text: qsTr("HMD"); opacity: 0.7}
                    QGCLabel { text: _humidityValue ? _humidityValue + " Rh%" : "No data"}

                    QGCLabel { text: qsTr("PRS"); opacity: 0.7}
                    QGCLabel { text: _pressureValue ? _pressureValue + " hPa" : "No data"}

                    QGCLabel { text: qsTr("W/D"); opacity: 0.7}
                    QGCLabel { text: _windDirValue ? _windDirValue + " deg" : "No data"}

                    QGCLabel { text: qsTr("W/S"); opacity: 0.7}
                    QGCLabel { text: _windSpdValue ? QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_windSpdValue).toFixed(1) + " "+QGroundControl.unitsConversion.appSettingsSpeedUnitsString : "No data"}
                }
            }
        }
    }
}
