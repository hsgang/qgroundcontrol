import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

SettingsGroupLayout {
    Layout.fillWidth: true
    heading:          qsTr("UniRC 7 Transport")

    property var  _siyiSettings: QGroundControl.settingsManager.siyiSettings
    property bool _isSerial:     _siyiSettings.siyiUniRCTransportMode.rawValue === 1

    LabelledFactComboBox {
        label: qsTr("Transport")
        fact:  _siyiSettings.siyiUniRCTransportMode
    }

    LabelledComboBox {
        id:      portCombo
        visible: _isSerial
        label:   qsTr("Serial Port")

        model: ListModel {}

        onActivated: (index) => {
            if (index !== -1) {
                _siyiSettings.siyiUniRCSerialPort.value = comboBox.textAt(index)
            }
        }

        Component.onCompleted: {
            var ports = []
            if (QGroundControl.linkManager.serialPorts.length === 0) {
                ports.push(qsTr("<none available>"))
            } else {
                for (var i in QGroundControl.linkManager.serialPorts) {
                    ports.push(QGroundControl.linkManager.serialPorts[i])
                }
            }
            portCombo.model = ports
            var index = portCombo.comboBox.find(_siyiSettings.siyiUniRCSerialPort.valueString)
            portCombo.currentIndex = index === -1 ? 0 : index
        }
    }

    LabelledComboBox {
        id:      baudCombo
        visible: _isSerial
        label:   qsTr("Baud Rate")

        readonly property string _customLabel: qsTr("Custom")
        readonly property bool   isCustomBaud: currentText === _customLabel

        onActivated: (index) => {
            if (index !== -1 && !isCustomBaud) {
                _siyiSettings.siyiUniRCSerialBaud.value = parseInt(comboBox.textAt(index))
            }
        }

        Component.onCompleted: {
            var rates = QGroundControl.linkManager.serialBaudRates.slice()
            rates.push(_customLabel)
            baudCombo.model = rates

            var baud = _siyiSettings.siyiUniRCSerialBaud.valueString
            var index = baudCombo.comboBox.find(baud)
            if (index === -1) {
                baudCombo.currentIndex = baudCombo.comboBox.count - 1
                customBaudField.text = baud
            } else {
                baudCombo.currentIndex = index
            }
        }
    }

    RowLayout {
        visible: _isSerial && baudCombo.isCustomBaud
        spacing: ScreenTools.defaultFontPixelWidth

        QGCLabel {
            text:             qsTr("Custom Baud Rate")
            Layout.fillWidth: true
        }
        QGCTextField {
            id:                customBaudField
            numericValuesOnly: true
            validator:         IntValidator { bottom: 1 }
            onEditingFinished: {
                if (!baudCombo.isCustomBaud) return
                var baud = parseInt(text)
                if (baud > 0) {
                    _siyiSettings.siyiUniRCSerialBaud.value = baud
                }
            }
        }
    }

    QGCLabel {
        Layout.fillWidth: true
        visible:          _isSerial
        wrapMode:         Text.WordWrap
        font.pointSize:   ScreenTools.smallFontPointSize
        text:             qsTr("Serial (UART) transport is supported on Android only. Changing transport requires an application restart.")
    }
}
