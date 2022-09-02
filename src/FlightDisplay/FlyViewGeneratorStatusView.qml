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
    property real _statusValue:         _activeVehicle ? _activeVehicle.generatorStatus.status.rawValue.toFixed(1) : NaN
    property real _batteryCurrentValue: _activeVehicle ? _activeVehicle.generatorStatus.batteryCurrent.rawValue.toFixed(1) : NaN
    property real _loadCurrentValue:    _activeVehicle ? _activeVehicle.generatorStatus.loadCurrent.rawValue.toFixed(1) : NaN
    property real _powerGeneratedValue: _activeVehicle ? _activeVehicle.generatorStatus.powerGenerated.rawValue.toFixed(1) : NaN
    property real _busVoltageValue:     _activeVehicle ? _activeVehicle.generatorStatus.busVoltage.rawValue.toFixed(1) : NaN
    property real _batCurrentSetpointValue: _activeVehicle ? _activeVehicle.generatorStatus.batCurrentSetpoint.rawValue.toFixed(1) : NaN
    property real _runtimeValue:        _activeVehicle ? _activeVehicle.generatorStatus.runtime.rawValue.toFixed(1) : NaN
    property real _generatorSpeedValue: _activeVehicle ? _activeVehicle.generatorStatus.generatorSpeed.rawValue.toFixed(1) : NaN
    property real _rectifierTempValue:  _activeVehicle ? _activeVehicle.generatorStatus.rectifierTemperature.rawValue.toFixed(1) : NaN
    property real _generatorTempValue:  _activeVehicle ? _activeVehicle.generatorStatus.generatorTemperature.rawValue.toFixed(1) : NaN

    property real _preferredWidth : ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 6 : ScreenTools.defaultFontPixelWidth * 9

    Column{
        id:                 generatorValueColumn
        spacing:            ScreenTools.defaultFontPixelWidth
        width:              Math.max(generatorStatusViewLabel.width, generatorStatusValueGrid.width)
        anchors.margins:    ScreenTools.defaultFontPixelHeight
        anchors.centerIn:   parent

        QGCLabel {
            id:     generatorStatusViewLabel
            text:   qsTr("Generator Status")
            font.family:    ScreenTools.demiboldFontFamily
            anchors.horizontalCenter: parent.horizontalCenter
        }

        GridLayout {
            id:                         generatorStatusValueGrid
            anchors.margins:            ScreenTools.defaultFontPixelHeight
            columnSpacing:              ScreenTools.defaultFontPixelWidth
            anchors.horizontalCenter:   parent.horizontalCenter
            columns: 2

            QGCLabel { text: qsTr("STATUS"); opacity: 0.7}
            QGCLabel { text: _statusValue ? _statusValue : "No data"}

            QGCLabel { text: qsTr("SOURCE"); opacity: 0.7}
            QGCLabel { text: _statusValue ? _activeVehicle.generatorStatus.status.enumStringValue : "No data"}

            QGCLabel { text: qsTr("VOLT"); opacity: 0.7}
            QGCLabel { text: _busVoltageValue ? _busVoltageValue +" V" : "No data"}

            QGCLabel { text: qsTr("CURR"); opacity: 0.7}
            QGCLabel { text: _batteryCurrentValue ? _batteryCurrentValue + " A" : "No data"}

            QGCLabel { text: qsTr("G.POW"); opacity: 0.7}
            QGCLabel { text: _powerGeneratedValue ? _powerGeneratedValue + " W" : "No data"}

            QGCLabel { text: qsTr("TEMP"); opacity: 0.7}
            QGCLabel { text: _rectifierTempValue ? _rectifierTempValue + " ℃" : "No data"}

            QGCLabel { text: qsTr("TIME"); opacity: 0.7}
            QGCLabel { text: _runtimeValue ? _runtimeValue + " s" : "No data"}
        }
    }
}

