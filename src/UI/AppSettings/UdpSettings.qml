/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Palette

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
                    //placeholderText:        qsTr("Example: 127.0.0.1")
                    text:                   "127.0.0.1"
                }
            }

            RowLayout {
                spacing: _colSpacing

                QGCLabel { text: qsTr("Port") }
                QGCTextField {
                    id:                     portField
                    text:                   subEditConfig.localPort.toString()
                    focus:                  true
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
                subEditConfig.addHost(hostField.text)
                hostField.text = ""
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
