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
            height:     atmosphericValueGrid.height + ScreenTools.defaultFontPixelHeight * 0.2
            width:      atmosphericValueGrid.width + ScreenTools.defaultFontPixelWidth * 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: ScreenTools.defaultFontPixelHeight * 3
            color:      "#80000000"
            radius:     _margins

            GridLayout {
                id:                         atmosphericValueGrid
                anchors.margins:            ScreenTools.defaultFontPixelHeight
                rowSpacing:                 ScreenTools.defaultFontPixelWidth
                anchors.horizontalCenter:   atmosphericValueBar.horizontalCenter
                anchors.verticalCenter:     atmosphericValueBar.verticalCenter
                columns: 3

                QGCLabel { text: qsTr("ALT:") }
                QGCLabel { text: _altitudeValue ? QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_altitudeValue).toFixed(1) : qsTr("--.-", "No data to display")
                           Layout.alignment: Qt.AlignRight
                           Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 6}
                QGCLabel { text: QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString }
                QGCLabel { text: qsTr("TMP:") }
                QGCLabel { text: _temperatureValue ? _temperatureValue : qsTr("--.-", "No data to display")
                           Layout.alignment: Qt.AlignRight
                           Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 6}
                QGCLabel { text: "℃" }
                QGCLabel { text: qsTr("HMD:") }
                QGCLabel { text: _humidityValue ? _humidityValue : qsTr("--.-", "No data to display")
                           Layout.alignment: Qt.AlignRight
                           Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 6}
                QGCLabel { text: "Rh%" }
                QGCLabel { text: qsTr("PRS:") }
                QGCLabel { text: _pressureValue ? _pressureValue : qsTr("--.-", "No data to display")
                           Layout.alignment: Qt.AlignRight
                           Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 6}
                QGCLabel { text: "hPa" }
                QGCLabel { text: qsTr("W/D:") }
                QGCLabel { text: _windDirValue ? _windDirValue : qsTr("--.-", "No data to display")
                           Layout.alignment: Qt.AlignRight
                           Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 6}
                QGCLabel { text: "deg" }
                QGCLabel { text: qsTr("W/S:") }
                QGCLabel { text: _windSpdValue ? QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_windSpdValue).toFixed(1) : qsTr("--.-", "No data to display")
                           Layout.alignment: Qt.AlignRight
                           Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 6}
                QGCLabel { text: QGroundControl.unitsConversion.appSettingsSpeedUnitsString }
            }
        }
    }
}
