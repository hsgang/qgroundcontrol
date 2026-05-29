import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

SettingsGroupLayout {
    Layout.fillWidth: true
    heading:          qsTr("UniRC 7 RC Channels (live)")

    property var _siyi:     QGroundControl.siyi
    property var _uniRC:    _siyi ? _siyi.uniRC : null
    property var _channels: _uniRC ? _uniRC.rcChannels : []

    readonly property var _freqLabels: [
        qsTr("Off"),
        "2 Hz",
        "4 Hz",
        "5 Hz",
        "10 Hz",
        "20 Hz",
        "50 Hz",
        "100 Hz"
    ]

    QGCPalette { id: qgcPal }

    QGCLabel {
        Layout.fillWidth: true
        text: qsTr("⚠ Enabling RC output may interfere with telemetry sharing the same port.")
        color: qgcPal.colorOrange
        wrapMode: Text.WordWrap
        font.pointSize: ScreenTools.smallFontPointSize
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: ScreenTools.defaultFontPixelWidth

        QGCLabel {
            text: qsTr("Output Frequency")
            Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 20
        }
        QGCComboBox {
            id: freqCombo
            Layout.fillWidth: true
            model: _freqLabels
            currentIndex: _uniRC ? _uniRC.rcOutputFreq : 0
            enabled: _uniRC && _uniRC.isConnected
            onActivated: _uniRC.setRcOutputFreq(currentIndex)
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: ScreenTools.defaultFontPixelHeight / 4
        visible: _uniRC && _uniRC.rcOutputFreq > 0

        Repeater {
            model: 16

            delegate: RowLayout {
                required property int index
                property int chValue: index < _channels.length ? _channels[index] : 1500
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelWidth

                QGCLabel {
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 6
                    text: "CH " + (index + 1)
                }
                ProgressBar {
                    Layout.fillWidth: true
                    from: 1050
                    to:   1950
                    value: Math.max(1050, Math.min(1950, chValue))
                }
                QGCLabel {
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 6
                    text: chValue
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
