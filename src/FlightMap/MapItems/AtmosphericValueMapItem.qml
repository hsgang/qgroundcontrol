/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtLocation
import QtPositioning
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Vehicle
import QGroundControl.Controls
import QGroundControl.MultiVehicleManager
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Palette

/// Marker for displaying a vehicle location on the map
MapQuickItem {
    anchorPoint.x:  vehicleItem.width  / 2
    anchorPoint.y:  vehicleItem.height / 2
    visible:        coordinate.isValid

    property var    map
    property var    _map:                   map

    property real   _temperatureValue:      object ? object.atmosphericSensor.temperature.rawValue.toFixed(1) : 0
    property real   _humidityValue:         object ? object.atmosphericSensor.humidity.rawValue.toFixed(1) : 0
    property real   _pressureValue:         object ? object.atmosphericSensor.pressure.rawValue.toFixed(1) : 0
    property real   _windDirValue:          object ? object.atmosphericSensor.windDir.rawValue.toFixed(1) : 0
    property real   _windSpdValue:          object ? object.atmosphericSensor.windSpd.rawValue.toFixed(1) : 0
    property real   _altitudeValue:         object ? object.altitudeRelative.rawValue.toFixed(1) : 0

    sourceItem: Item {
        id:         vehicleItem

        Rectangle {
            id:         atmosphericValueBar
            height:     atmosphericValueColumn.height + ScreenTools.defaultFontPixelHeight * 0.2
            width:      atmosphericValueColumn.width + ScreenTools.defaultFontPixelHeight * 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: ScreenTools.defaultFontPixelHeight * 2
            color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
            radius:     ScreenTools.defaultFontPixelHeight / 2

            Column{
                id:                 atmosphericValueColumn
                spacing:            ScreenTools.defaultFontPixelHeight / 5
                width:              Math.max(atmosphericSensorViewLabel.width, atmosphericValueGrid.width)
                anchors.margins:    ScreenTools.defaultFontPixelHeight
                anchors.centerIn:   parent

                QGCLabel {
                    id:             atmosphericSensorViewLabel
                    text:           qsTr("Ext. Sensors")
                    font.family:    ScreenTools.demiboldFontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                GridLayout {
                    id:                         atmosphericValueGrid
                    anchors.margins:            ScreenTools.defaultFontPixelHeight
                    columnSpacing:              ScreenTools.defaultFontPixelHeight
                    anchors.horizontalCenter:   parent.horizontalCenter
                    columns: 2

                    QGCLabel { text: qsTr("ALT"); opacity: 0.7; Layout.alignment: Qt.AlignCenter}
                    QGCLabel {
                        text: _altitudeValue ? QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_altitudeValue).toFixed(1) +" "+ QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString: "No data"
                        width: ScreenTools.defaultFontPixelHeight * 11
                        Layout.alignment: Qt.AlignCenter
                    }

                    QGCLabel { text: qsTr("TMP"); opacity: 0.7; Layout.alignment: Qt.AlignCenter}
                    QGCLabel {
                        text: _temperatureValue ? _temperatureValue +" ℃" : "No data"
                        width: ScreenTools.defaultFontPixelHeight * 11
                        Layout.alignment: Qt.AlignCenter
                    }

                    QGCLabel { text: qsTr("HMD"); opacity: 0.7; Layout.alignment: Qt.AlignCenter}
                    QGCLabel {
                        text: _humidityValue ? _humidityValue + " Rh%" : "No data"
                        width: ScreenTools.defaultFontPixelHeight * 11
                        Layout.alignment: Qt.AlignCenter
                    }

                    QGCLabel { text: qsTr("PRS"); opacity: 0.7; Layout.alignment: Qt.AlignCenter}
                    QGCLabel {
                        text: _pressureValue ? _pressureValue + " hPa" : "No data"
                        width: ScreenTools.defaultFontPixelHeight * 11
                        Layout.alignment: Qt.AlignCenter
                    }

                    QGCLabel { text: qsTr("W/D"); opacity: 0.7; Layout.alignment: Qt.AlignCenter}
                    QGCLabel {
                        text: _windDirValue ? _windDirValue + " deg" : "No data"
                        width: ScreenTools.defaultFontPixelHeight * 11
                        Layout.alignment: Qt.AlignCenter
                    }

                    QGCLabel { text: qsTr("W/S"); opacity: 0.7; Layout.alignment: Qt.AlignCenter}
                    QGCLabel {
                        text: _windSpdValue ? QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_windSpdValue).toFixed(1) + " "+QGroundControl.unitsConversion.appSettingsSpeedUnitsString : "No data"
                        width: ScreenTools.defaultFontPixelHeight * 11
                        Layout.alignment: Qt.AlignCenter
                    }
                }
            } // Column
        } // Rectangle
    }
}
