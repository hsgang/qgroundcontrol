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
    id:         generatorView
    height:     generatorValueColumn.height + ScreenTools.defaultFontPixelHeight * 0.5
    width:      generatorValueColumn.width + ScreenTools.defaultFontPixelWidth * 3
    color:      "#80000000"
    radius:     _margins
    border.color: qgcPal.text

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property real _acInputVolatage1Value:   _activeVehicle ? _activeVehicle.externalPowerStatus.ACInputVolatage1.rawValue.toFixed(1) : NaN
    property real _acInputVolatage2Value:   _activeVehicle ? _activeVehicle.externalPowerStatus.ACInputVolatage2.rawValue.toFixed(1) : NaN
    property real _acInputVolatage3Value:   _activeVehicle ? _activeVehicle.externalPowerStatus.ACInputVolatage3.rawValue.toFixed(1) : NaN
    property real _dcOutputVolatage1Value:  _activeVehicle ? _activeVehicle.externalPowerStatus.DCOutputVolatage1.rawValue.toFixed(1) : NaN
    property real _dcOutputVolatage2Value:  _activeVehicle ? _activeVehicle.externalPowerStatus.DCOutputVolatage2.rawValue.toFixed(1) : NaN
    property real _dcOutputVolatage3Value:  _activeVehicle ? _activeVehicle.externalPowerStatus.DCOutputVolatage3.rawValue.toFixed(1) : NaN
    property real _dcOutputCurrent1Value:   _activeVehicle ? _activeVehicle.externalPowerStatus.DCOutputCurrent1.rawValue.toFixed(1) : NaN
    property real _dcOutputCurrent2Value:   _activeVehicle ? _activeVehicle.externalPowerStatus.DCOutputCurrent2.rawValue.toFixed(1) : NaN
    property real _dcOutputCurrent3Value:   _activeVehicle ? _activeVehicle.externalPowerStatus.DCOutputCurrent3.rawValue.toFixed(1) : NaN
    property real _temperatureValue:        _activeVehicle ? _activeVehicle.externalPowerStatus.Temperature.rawValue.toFixed(1) : NaN
    property real _batteryVoltageValue:     _activeVehicle ? _activeVehicle.externalPowerStatus.BatteryVoltage.rawValue.toFixed(1) : NaN
    property real _batteryChangeValue:      _activeVehicle ? _activeVehicle.externalPowerStatus.BatteryChange.rawValue.toFixed(0) : NaN

    property real _preferredWidth : ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 6 : ScreenTools.defaultFontPixelWidth * 9

    Column{
        id:                 generatorValueColumn
        spacing:            ScreenTools.defaultFontPixelWidth
        width:              Math.max(generatorStatusViewLabel.width, generatorStatusValueGrid.width)
        anchors.margins:    ScreenTools.defaultFontPixelHeight
        anchors.centerIn:   parent

        QGCLabel {
            id:     generatorStatusViewLabel
            text:   qsTr("ExtPower Status")
            font.family:    ScreenTools.demiboldFontFamily
            anchors.horizontalCenter: parent.horizontalCenter
        }

        GridLayout {
            id:                         generatorStatusValueGrid
            anchors.margins:            ScreenTools.defaultFontPixelHeight
            columnSpacing:              ScreenTools.defaultFontPixelWidth
            anchors.horizontalCenter:   parent.horizontalCenter
            columns: 2

            QGCLabel { text: qsTr("AC1_V"); opacity: 0.7}
            QGCLabel { text: _acInputVolatage1Value ? _acInputVolatage1Value + " V" : "No data"}

            QGCLabel { text: qsTr("AC2_V"); opacity: 0.7}
            QGCLabel { text: _acInputVolatage2Value ? _acInputVolatage2Value + " V": "No data"}

            QGCLabel { text: qsTr("AC3_V"); opacity: 0.7}
            QGCLabel { text: _acInputVolatage3Value ? _acInputVolatage3Value + " V": "No data"}

            QGCLabel { text: qsTr("DC1_V"); opacity: 0.7}
            QGCLabel { text: _dcOutputVolatage1Value ? _dcOutputVolatage1Value + " V" : "No data"}

            QGCLabel { text: qsTr("DC2_V"); opacity: 0.7}
            QGCLabel { text: _dcOutputVolatage2Value ? _dcOutputVolatage2Value + " V" : "No data"}

            QGCLabel { text: qsTr("DC3_V"); opacity: 0.7}
            QGCLabel { text: _dcOutputVolatage3Value ? _dcOutputVolatage3Value + " V" : "No data"}

            QGCLabel { text: qsTr("DC1_C"); opacity: 0.7}
            QGCLabel { text: _dcOutputCurrent1Value ? _dcOutputCurrent1Value + " A" : "No data"}

            QGCLabel { text: qsTr("DC2_C"); opacity: 0.7}
            QGCLabel { text: _dcOutputCurrent2Value ? _dcOutputCurrent2Value + " A" : "No data"}

            QGCLabel { text: qsTr("DC3_C"); opacity: 0.7}
            QGCLabel { text: _dcOutputCurrent3Value ? _dcOutputCurrent3Value + " A" : "No data"}

            QGCLabel { text: qsTr("TEMP"); opacity: 0.7}
            QGCLabel { text: _temperatureValue ? _temperatureValue + " ℃" : "No data"}

            QGCLabel { text: qsTr("BATT"); opacity: 0.7}
            QGCLabel { text: _batteryVoltageValue ? _batteryVoltageValue + " V" : "No data"}

            QGCLabel { text: qsTr("STATUS"); opacity: 0.7}
            QGCLabel { text: _batteryChangeValue ? _batteryChangeValue : "No data"}
        }
    }
}

