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
    function _multiCtlModeText(m) {
        switch (m) {
        case 0: return qsTr("Dual control master")
        case 1: return qsTr("Dual control slave")
        case 2: return qsTr("Relay master")
        case 3: return qsTr("Relay slave")
        case 4: return qsTr("Relay")
        case 5: return qsTr("Single control")
        default: return "-"
        }
    }
    function _linkStatusText(s) {
        switch (s) {
        case 0: return qsTr("Not connected")
        case 1: return qsTr("Connected")
        case 2: return qsTr("Out of control")
        default: return "-"
        }
    }
    function _relayStatusText(s) {
        switch (s) {
        case 0: return qsTr("Master has authority")
        case 1: return qsTr("Slave has authority")
        case 2: return qsTr("Out of control")
        default: return "-"
        }
    }
    function _dualCtlText(s) {
        switch (s) {
        case 0: return qsTr("Disabled (master only)")
        case 1: return qsTr("Enabled (slave channels)")
        default: return "-"
        }
    }
    function _groundLedText(s) {
        switch (s) {
        case 0:  return qsTr("Normal")
        case 1:  return qsTr("Ground/air not communicating")
        case 2:  return qsTr("Binding in progress")
        case 3:  return qsTr("MCU firmware mismatch")
        case 4:  return qsTr("Link initialization failed")
        case 5:  return qsTr("Joystick needs calibration")
        case 6:  return qsTr("Video transmission starting")
        case 7:  return qsTr("Upgrading air unit firmware")
        case 8:  return qsTr("Power supply voltage abnormal")
        case 9:  return qsTr("Bluetooth not recognized")
        case 10: return qsTr("Temperature alarm level 1")
        case 11: return qsTr("Temperature alarm level 2")
        case 12: return qsTr("Temperature alarm level 3")
        case 13: return qsTr("Video firmware mismatch")
        case 14: return qsTr("Valid packet rate 100%")
        case 15: return qsTr("Valid packet rate 99–95%")
        case 16: return qsTr("Valid packet rate 75–50%")
        case 17: return qsTr("Valid packet rate 50–25%")
        case 18: return qsTr("Valid packet rate below 25%")
        default: return "-"
        }
    }
    function _skyLedText(s) {
        switch (s) {
        case 0:  return qsTr("Normal")
        case 1:  return qsTr("Voltage alarm (below 12V)")
        case 2:  return qsTr("Temperature alarm level 1")
        case 3:  return qsTr("Temperature alarm level 2")
        case 4:  return qsTr("Temperature alarm level 3")
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

    // Multi-device interconnection status (0x4E)
    LabelledLabel {
        Layout.fillWidth: true
        label:     qsTr("Interconnect Mode")
        labelText: _uniRC ? _multiCtlModeText(_uniRC.rcMultiCtlMode) : "-"
    }
    LabelledLabel {
        Layout.fillWidth: true
        visible:   _uniRC && _uniRC.rcMultiCtlMode >= 0 && _uniRC.rcMultiCtlMode !== 5
        label:     qsTr("Peer Link")
        labelText: _uniRC ? _linkStatusText(_uniRC.mainViceLinkStatus) : "-"
    }
    LabelledLabel {
        Layout.fillWidth: true
        visible:   _uniRC && (_uniRC.rcMultiCtlMode === 2 || _uniRC.rcMultiCtlMode === 3)
        label:     qsTr("Relay Authority")
        labelText: _uniRC ? _relayStatusText(_uniRC.rcRelayStatus) : "-"
    }
    LabelledLabel {
        Layout.fillWidth: true
        visible:   _uniRC && (_uniRC.rcMultiCtlMode === 0 || _uniRC.rcMultiCtlMode === 1)
        label:     qsTr("Dual Control")
        labelText: _uniRC ? _dualCtlText(_uniRC.dualCtlStatus) : "-"
    }

    // System status warning LEDs (0x4F); highlighted red when a warning is active
    RowLayout {
        Layout.fillWidth: true
        spacing: ScreenTools.defaultFontPixelWidth * 2
        QGCLabel {
            Layout.fillWidth:    true
            Layout.minimumWidth: implicitWidth
            text: qsTr("Ground Unit")
        }
        QGCLabel {
            text:  _uniRC ? _groundLedText(_uniRC.groundLedStatus) : "-"
            color: (_uniRC && _uniRC.groundLedStatus > 0) ? qgcPal.colorRed : qgcPal.text
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: ScreenTools.defaultFontPixelWidth * 2
        QGCLabel {
            Layout.fillWidth:    true
            Layout.minimumWidth: implicitWidth
            text: qsTr("Air Unit")
        }
        QGCLabel {
            text:  _uniRC ? _skyLedText(_uniRC.skyLedStatus) : "-"
            color: (_uniRC && _uniRC.skyLedStatus > 0) ? qgcPal.colorRed : qgcPal.text
        }
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
