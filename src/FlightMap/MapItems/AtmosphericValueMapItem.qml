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

    property string _flightMode:            object ? object.flightMode.toString() : ""

    property real   _temperatureValue:      object ? object.atmosphericSensor.temperature.rawValue.toFixed(1) : 0
    property real   _humidityValue:         object ? object.atmosphericSensor.humidity.rawValue.toFixed(1) : 0
    property real   _pressureValue:         object ? object.atmosphericSensor.pressure.rawValue.toFixed(1) : 0
    property real   _windDirValue:          object ? object.atmosphericSensor.windDir.rawValue.toFixed(1) : 0
    property real   _windSpdValue:          object ? object.atmosphericSensor.windSpd.rawValue.toFixed(1) : 0
    property real   _altitudeValue:         object ? object.altitudeRelative.rawValue.toFixed(1) : 0

    property bool   _healthAndArmingChecksSupported: object ? object.healthAndArmingCheckReport.supported : false

    property string _readyToFlyText:    qsTr("Ready To Fly")
    property string _notReadyToFlyText: qsTr("Not Ready")
    property string _armedText:         qsTr("Armed")
    property string _flyingText:        qsTr("Flying")
    property string _landingText:       qsTr("Landing")

    function mainStatusText() {
        if (object) {
            if (object.armed) {
                if (object.flying) {
                    return _flyingText
                } else if (object.landing) {
                    return _landingText
                } else {
                    return _armedText
                }
            } else {
                if (_healthAndArmingChecksSupported) {
                    if (object.healthAndArmingCheckReport.canArm) {
                        return _readyToFlyText
                    } else {
                        return _notReadyToFlyText
                    }
                } else if (object.readyToFlyAvailable) {
                    if (object.readyToFly) {
                        return _readyToFlyText
                    } else {
                        return _notReadyToFlyText
                    }
                } else {
                    // Best we can do is determine readiness based on AutoPilot component setup and health indicators from SYS_STATUS
                    if (object.allSensorsHealthy && object.autopilot.setupComplete) {
                        return _readyToFlyText
                    } else {
                        return _notReadyToFlyText
                    }
                }
            }
        } else {
            return "Unknown"
        }
    }

    sourceItem: Item {
        id:         vehicleItem

        property bool viewToggle: false

        Timer {
            interval:   3000;
            running:    true;
            repeat:     true;
            onTriggered: {
                vehicleItem.viewToggle = !vehicleItem.viewToggle
            }
        }

        Rectangle {
            id:         atmosphericValueBar
            height:     atmosphericValueColumn.height + ScreenTools.defaultFontPixelHeight * 0.2
            width:      atmosphericValueColumn.width + ScreenTools.defaultFontPixelHeight * 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: ScreenTools.defaultFontPixelHeight * 3
            color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
            radius:     _margins

            Column{
                id:                 atmosphericValueColumn
                spacing:            ScreenTools.defaultFontPixelHeight / 5
                width:              Math.max(atmosphericSensorViewLabel.width, atmosphericValueGrid.width)
                anchors.margins:    ScreenTools.defaultFontPixelHeight
                anchors.centerIn:   parent
                visible:            vehicleItem.viewToggle === true

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

            Column{
                id:                 vehicleStatusColumn
                spacing:            ScreenTools.defaultFontPixelHeight / 5
                width:              Math.max(vehicleStatusLabel.width, vehicleStatusGrid.width)
                anchors.margins:    ScreenTools.defaultFontPixelHeight
                anchors.centerIn:   parent
                visible:            vehicleItem.viewToggle === false

                QGCLabel {
                    id:             vehicleStatusLabel
                    text:           object ? "Vehicle "+object.id : ""
                    font.family:    ScreenTools.demiboldFontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                GridLayout {
                    id:                         vehicleStatusGrid
                    anchors.margins:            ScreenTools.defaultFontPixelHeight
                    columnSpacing:              ScreenTools.defaultFontPixelHeight
                    anchors.horizontalCenter:   parent.horizontalCenter
                    columns: 2

                    QGCLabel { text: qsTr("STS"); opacity: 0.7; Layout.alignment: Qt.AlignCenter}
                    QGCLabel {
                        text: mainStatusText()
                        width: ScreenTools.defaultFontPixelHeight * 11
                        Layout.alignment: Qt.AlignCenter
                    }

                    QGCLabel { text: qsTr("FLT"); opacity: 0.7; Layout.alignment: Qt.AlignCenter}
                    QGCLabel {
                        text: object ? _flightMode : "No Data"
                        width: ScreenTools.defaultFontPixelHeight * 11
                        Layout.alignment: Qt.AlignCenter
                    }

                    QGCLabel { text: qsTr("ALT"); opacity: 0.7; Layout.alignment: Qt.AlignCenter}
                    QGCLabel {
                        text: _altitudeValue ? QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_altitudeValue).toFixed(1) +" "+ QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString: "No data"
                        width: ScreenTools.defaultFontPixelHeight * 11
                        Layout.alignment: Qt.AlignCenter
                    }

                    QGCLabel { text: qsTr("VLT"); opacity: 0.7; Layout.alignment: Qt.AlignCenter}
                    Row {
                        id:             batteryIndicatorRow
                        spacing:        ScreenTools.defaultFontPixelHeight / 2
                        Layout.alignment: Qt.AlignCenter

                        Repeater {
                            model: object ? object.batteries : 0

                            Loader {
                                sourceComponent:    objectVoltage

                                property var battery: object
                            }
                        }
                    }

//                    QGCLabel {
//                        text: object ? _battery1volt : "???"
//                        Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 11
//                    }

                    QGCLabel { text: qsTr("SPD"); opacity: 0.7; Layout.alignment: Qt.AlignCenter}
                    QGCLabel {
                        text: object ? object.groundSpeed.rawValue.toFixed(1) : ""
                        width: ScreenTools.defaultFontPixelHeight * 11
                        Layout.alignment: Qt.AlignCenter
                    }

                    QGCLabel { text: qsTr("GPS"); opacity: 0.7; Layout.alignment: Qt.AlignCenter}
                    QGCLabel {
                        text: object ? object.gps.lock.enumStringValue + " (" + object.gps.count.valueString + ")" : ""
                        width: ScreenTools.defaultFontPixelHeight * 11
                        Layout.alignment: Qt.AlignCenter
                    }
                } // GridLayout
            } // Column
        } // Rectangle

        Item {
            id : triangleComponent
            anchors.top:    atmosphericValueBar.bottom
            anchors.left:   atmosphericValueBar.horizontalCenter
            width: ScreenTools.defaultFontPixelHeight
            height: ScreenTools.defaultFontPixelHeight
            clip : true

            // The index of corner for the triangle to be attached
            property int corner : 0;
            property alias color : rect.color

            Rectangle {
                x : triangleComponent.width * ((triangleComponent.corner + 1) % 4 < 2 ? 0 : 1) - width / 2
                y : triangleComponent.height * (triangleComponent.corner    % 4 < 2 ? 0 : 1) - height / 2
                id : rect
                color : Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
                antialiasing: true
                width : Math.min(triangleComponent.width,triangleComponent.height)
                height : width
                transformOrigin: Item.Center
                rotation : 45
                scale : 1.414
            }
        } // Item
    }

    Component {
        id: objectVoltage

        QGCLabel {
            text: object ? battery.voltage.valueString : ""
            Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 11
        }

    }
}
