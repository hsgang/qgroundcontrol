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

ColumnLayout {
    spacing: _rowSpacing
    width:  _columnLayoutWidth

    function saveSettings() {
        subEditConfig.roomId = roomIdField.text
        subEditConfig.peerId = peerIdField.text
        subEditConfig.targetPeerId = targetPeerIdField.text
    }

    ColumnLayout {
        spacing: 0
        Layout.fillWidth: true

        RowLayout {
            spacing: _colSpacing
            QGCLabel { text: qsTr("ID") }
            QGCTextField {
                id:                     roomIdField
                Layout.preferredWidth:  _secondColumnWidth * 0.7
                Layout.fillWidth:       true
                text:                   subEditConfig.roomId

                onEditingFinished: {
                    peerIdField.text = "app_" + text
                    targetPeerIdField.text = "vehicle_" + text
                    saveSettings()
                }
            }
        }

        RowLayout {
            spacing: _colSpacing
            QGCLabel { text: qsTr("APP ID (자동설정)") }
            QGCTextField {
                id:                     peerIdField
                Layout.preferredWidth:  _secondColumnWidth * 0.7
                Layout.fillWidth:       true
                text:                   subEditConfig.peerId

                onEditingFinished: {
                    saveSettings()
                }
            }
        }

        RowLayout {
            spacing: _colSpacing
            QGCLabel { text: qsTr("TARGET ID (자동설정)") }
            QGCTextField {
                id:                     targetPeerIdField
                Layout.preferredWidth:  _secondColumnWidth * 0.7
                Layout.fillWidth:       true
                text:                   subEditConfig.targetPeerId

                onEditingFinished: {
                    saveSettings()
                }
            }
        }
    }
}
