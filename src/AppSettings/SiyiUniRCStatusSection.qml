import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

SettingsGroupLayout {
    Layout.fillWidth: true
    heading:          qsTr("UniRC 7 Status")

    property var _siyi:  QGroundControl.siyi
    property var _uniRC: _siyi ? _siyi.uniRC : null

    function _joystickModeText(t) {
        switch (t) {
        case 0: return qsTr("Japanese (Mode 1)")
        case 1: return qsTr("American (Mode 2)")
        case 2: return qsTr("Chinese (Mode 3)")
        case 3: return qsTr("Custom")
        default: return "-"
        }
    }
    function _pairingText(s) {
        switch (s) {
        case 0: return qsTr("Idle")
        case 1:
        case 2: return qsTr("Binding…")
        case 3: return qsTr("Bound")
        default: return "-"
        }
    }
    function _baudText(b) {
        switch (b) {
        case 1: return "9600"
        case 3: return "57600"
        case 5: return "115200"
        default: return "-"
        }
    }

    QGCPalette { id: qgcPal }

    RowLayout {
        Layout.fillWidth: true
        spacing: ScreenTools.defaultFontPixelWidth

        Rectangle {
            width:  ScreenTools.defaultFontPixelHeight * 0.75
            height: width
            radius: width / 2
            color:  (_uniRC && _uniRC.isConnected) ? qgcPal.colorGreen : qgcPal.colorGrey
            Layout.alignment: Qt.AlignVCenter
        }
        QGCLabel {
            Layout.fillWidth: true
            text: (_uniRC && _uniRC.isConnected) ? qsTr("Connected") : qsTr("Disconnected")
        }
        QGCButton {
            text: qsTr("Refresh")
            enabled: _uniRC && _uniRC.isConnected
            onClicked: {
                _uniRC.requestHardwareId()
                _uniRC.requestSystemSettings()
                _uniRC.requestFirmwareVersion()
            }
        }
    }

    LabelledLabel {
        Layout.fillWidth: true
        label:     qsTr("Hardware ID")
        labelText: _uniRC && _uniRC.hardwareId.length > 0 ? _uniRC.hardwareId : "-"
    }
    LabelledLabel {
        Layout.fillWidth: true
        label:     qsTr("Firmware")
        labelText: _uniRC ? _uniRC.version : "-"
    }
    LabelledLabel {
        Layout.fillWidth: true
        label:     qsTr("Battery")
        labelText: (_uniRC && _uniRC.batteryVoltage > 0) ? _uniRC.batteryVoltage.toFixed(1) + " V" : "-"
    }
    LabelledLabel {
        Layout.fillWidth: true
        label:     qsTr("Pairing")
        labelText: _uniRC ? _pairingText(_uniRC.pairingState) : "-"
    }
    LabelledLabel {
        Layout.fillWidth: true
        label:     qsTr("Joystick Mode")
        labelText: _uniRC ? _joystickModeText(_uniRC.joystickType) : "-"
    }
    LabelledLabel {
        Layout.fillWidth: true
        label:     qsTr("UART1 Baud")
        labelText: _uniRC ? _baudText(_uniRC.com1BaudType) : "-"
    }
    LabelledLabel {
        Layout.fillWidth: true
        label:     qsTr("UART2 Baud")
        labelText: _uniRC ? _baudText(_uniRC.com2BaudType) : "-"
    }
    LabelledLabel {
        Layout.fillWidth: true
        label:     qsTr("Signal")
        labelText: (_uniRC && _uniRC.signalQuality >= 0) ? _uniRC.signalQuality + " %" : "-"
    }
    LabelledLabel {
        Layout.fillWidth: true
        label:     qsTr("RSSI")
        labelText: (_uniRC && _uniRC.rssi !== -1) ? _uniRC.rssi + " dBm" : "-"
    }
    LabelledLabel {
        Layout.fillWidth: true
        label:     qsTr("Frequency")
        labelText: (_uniRC && _uniRC.freq > 0) ? _uniRC.freq + " MHz" : "-"
    }
    LabelledLabel {
        Layout.fillWidth: true
        label:     qsTr("Channel")
        labelText: (_uniRC && _uniRC.channel > 0) ? _uniRC.channel : "-"
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: ScreenTools.defaultFontPixelWidth
        QGCButton {
            text: qsTr("Start Pairing")
            enabled: _uniRC && _uniRC.isConnected && _uniRC.pairingState !== 1 && _uniRC.pairingState !== 2
            onClicked: _uniRC.startPairing()
        }
        QGCButton {
            text: qsTr("Stop Pairing")
            enabled: _uniRC && _uniRC.isConnected
            onClicked: _uniRC.stopPairing()
        }
    }
}
