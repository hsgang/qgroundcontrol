import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.MultiVehicleManager
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.Palette

Rectangle {
    id:         atmosphericValueBar
    height:     atmosphericValueColumn.height + ScreenTools.defaultFontPixelHeight * 0.5
    width:      atmosphericValueColumn.width + ScreenTools.defaultFontPixelWidth * 2
    color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5)
    radius:     _margins
    //border.color: qgcPal.text

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property real _temperatureValue:    _activeVehicle ? _activeVehicle.atmosphericSensor.temperature.rawValue.toFixed(1) : NaN
    property real _humidityValue:       _activeVehicle ? _activeVehicle.atmosphericSensor.humidity.rawValue.toFixed(1) : NaN
    property real _pressureValue:       _activeVehicle ? _activeVehicle.atmosphericSensor.pressure.rawValue.toFixed(1) : NaN
    property real _windDirValue:        _activeVehicle ? _activeVehicle.atmosphericSensor.windDir.rawValue.toFixed(1) : NaN
    property real _windSpdValue:        _activeVehicle ? _activeVehicle.atmosphericSensor.windSpd.rawValue.toFixed(1) : NaN
    property real _altitudeValue:       _activeVehicle ? _activeVehicle.altitudeRelative.rawValue.toFixed(1) : NaN

    property real _preferredWidth : ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 6 : ScreenTools.defaultFontPixelWidth * 9
    property real _fontSize :       ScreenTools.isMobile ? ScreenTools.defaultFontPointSize * 0.8 : ScreenTools.defaultFontPointSize

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
            font.pointSize: _fontSize
            anchors.horizontalCenter: parent.horizontalCenter
        }

        GridLayout {
            id:                         atmosphericValueGrid
            anchors.margins:            ScreenTools.defaultFontPixelHeight
            columnSpacing:              ScreenTools.defaultFontPixelWidth / 2
            anchors.horizontalCenter:   parent.horizontalCenter
            columns: 2

            QGCLabel { text: qsTr("ALT"); opacity: 0.7; font.pointSize: _fontSize; }
            QGCLabel {
                text: _altitudeValue ? QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_altitudeValue).toFixed(1) +" "+ QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString: "No data"
                font.pointSize: _fontSize
                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 8
                horizontalAlignment:    Text.AlignRight
            }

            QGCLabel { text: qsTr("TMP"); opacity: 0.7; font.pointSize: _fontSize; }
            QGCLabel {
                text: _temperatureValue ? _temperatureValue +" ℃" : "No data"
                font.pointSize: _fontSize
                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 8
                horizontalAlignment:    Text.AlignRight
            }

            QGCLabel { text: qsTr("HMD"); opacity: 0.7; font.pointSize: _fontSize; }
            QGCLabel {
                text: _humidityValue ? _humidityValue + " Rh%" : "No data"
                font.pointSize: _fontSize
                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 8
                horizontalAlignment:    Text.AlignRight
            }

            QGCLabel { text: qsTr("PRS"); opacity: 0.7; font.pointSize: _fontSize; }
            QGCLabel {
                text: _pressureValue ? _pressureValue + " hPa" : "No data"
                font.pointSize: _fontSize
                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 8
                horizontalAlignment:    Text.AlignRight
            }

            QGCLabel { text: qsTr("W/D"); opacity: 0.7; font.pointSize: _fontSize; }
            QGCLabel {
                text: _windDirValue ? _windDirValue + " deg" : "No data"
                font.pointSize: _fontSize
                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 8
                horizontalAlignment:    Text.AlignRight
            }

            QGCLabel { text: qsTr("W/S"); opacity: 0.7; font.pointSize: _fontSize; }
            QGCLabel {
                text: _windSpdValue ? QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_windSpdValue).toFixed(1) + " "+QGroundControl.unitsConversion.appSettingsSpeedUnitsString : "No data"
                font.pointSize: _fontSize
                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 8
                horizontalAlignment:    Text.AlignRight
            }
        }
    }
}


