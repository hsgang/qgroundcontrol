import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

ColumnLayout {
    spacing: _rowSpacing
    width:  _columnLayoutWidth

    function saveSettings() {
        // No need
    }

    QGCLabel {
        Layout.preferredWidth: _secondColumnWidth
        Layout.fillWidth:       true
        font.pointSize:         ScreenTools.smallFontPointSize
        wrapMode:               Text.WordWrap
        text:                   qsTr("Note: For best perfomance, please disable AutoConnect to UDP devices on the General page.")
    }

    RowLayout {
        Layout.fillWidth: true

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            RowLayout {
                spacing: _colSpacing
                QGCLabel { text: qsTr("Server") }
                QGCTextField {
                    id:                     hostField
                    Layout.preferredWidth:  _secondColumnWidth * 0.7
                    Layout.fillWidth:       true
                    placeholderText:        "192.168.144.12"
                    text:                   "192.168.144.12"
                }
            }

            RowLayout {
                spacing: _colSpacing

                QGCLabel { text: qsTr("Port") }
                QGCTextField {
                    id:                     portField
                    text:                   "19856" //subEditConfig.localPort.toString()
                    placeholderText:        "19856"
                    Layout.preferredWidth:  _secondColumnWidth * 0.7
                    Layout.fillWidth:       true
                    inputMethodHints:       Qt.ImhFormattedNumbersOnly
                    onTextChanged:          subEditConfig.localPort = parseInt(portField.text)
                }
            }
        }

        QGCButton {
            text:       qsTr("Add Server")
            enabled:    hostField.text !== ""
            onClicked: {
                // Combine host and port before adding
                var hostWithPort = hostField.text
                if (hostWithPort.indexOf(":") === -1) {
                    hostWithPort = hostWithPort + ":" + portField.text
                }
                subEditConfig.addHost(hostWithPort)
                //hostField.text = ""
                subEditConfig.hostListChanged()
            }
        }
    }

    QGCLabel { text: qsTr("Server List") }

    Repeater {
        model: subEditConfig.hostList

        delegate: RowLayout {
            spacing: _colSpacing

            QGCLabel {
                Layout.preferredWidth:  _secondColumnWidth
                text:                   modelData
            }

            QGCButton {
                text:       qsTr("Remove")
                onClicked:  subEditConfig.removeHost(modelData)
            }
        }
    }
}
