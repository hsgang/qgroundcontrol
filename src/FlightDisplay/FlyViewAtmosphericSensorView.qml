import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts  1.2
import QtQuick.Dialogs  1.2

import QGroundControl                   1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.MultiVehicleManager 1.0
import QGroundControl.Controls          1.0
import QGroundControl.FactControls      1.0
import QGroundControl.Palette           1.0

Rectangle {
    id:         atmosphericValueBar
    height:     atmosphericValueColumn.height + ScreenTools.defaultFontPixelHeight * 0.5
    width:      atmosphericValueColumn.width + ScreenTools.defaultFontPixelWidth * 3
    color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
    radius:     _margins
    border.color: qgcPal.text

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property real _temperatureValue:    _activeVehicle ? _activeVehicle.atmosphericSensor.temperature.rawValue.toFixed(1) : NaN
    property real _humidityValue:       _activeVehicle ? _activeVehicle.atmosphericSensor.humidity.rawValue.toFixed(1) : NaN
    property real _pressureValue:       _activeVehicle ? _activeVehicle.atmosphericSensor.pressure.rawValue.toFixed(1) : NaN
    property real _windDirValue:        _activeVehicle ? _activeVehicle.atmosphericSensor.windDir.rawValue.toFixed(1) : NaN
    property real _windSpdValue:        _activeVehicle ? _activeVehicle.atmosphericSensor.windSpd.rawValue.toFixed(1) : NaN
    property real _altitudeValue:       _activeVehicle ? _activeVehicle.altitudeRelative.rawValue.toFixed(1) : NaN

    property real _preferredWidth : ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 6 : ScreenTools.defaultFontPixelWidth * 9

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


