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
        subEditConfig.signalingServer = signalingServerField.text
        subEditConfig.stunServer = stunServerField.text
        subEditConfig.turnServer = turnServerField.text
        subEditConfig.turnUsername = turnUsernameField.text
        subEditConfig.turnPassword = turnPasswordField.text
    }

    ColumnLayout {
        spacing: 0
        Layout.fillWidth: true

        RowLayout {
            spacing: _colSpacing
            QGCLabel { text: qsTr("roomId") }
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
            QGCLabel { text: qsTr("peerId") }
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
            QGCLabel { text: qsTr("targetPeerId") }
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

        RowLayout {
            spacing: _colSpacing

            QGCLabel { text: qsTr("signalingServer") }
            QGCTextField {
                id:                     signalingServerField
                Layout.preferredWidth:  _secondColumnWidth * 0.7
                Layout.fillWidth:       true
                text:                   subEditConfig.signalingServer

                onEditingFinished: {
                    saveSettings()
                }
            }
        }

        RowLayout {
            spacing: _colSpacing

            QGCLabel { text: qsTr("stunServer") }
            QGCTextField {
                id:                     stunServerField
                Layout.preferredWidth:  _secondColumnWidth * 0.7
                Layout.fillWidth:       true
                text:                   subEditConfig.stunServer

                onEditingFinished: {
                    saveSettings()
                }
            }
        }

        RowLayout {
            spacing: _colSpacing

            QGCLabel { text: qsTr("turnServer") }
            QGCTextField {
                id:                     turnServerField
                Layout.preferredWidth:  _secondColumnWidth * 0.7
                Layout.fillWidth:       true
                text:                   subEditConfig.turnServer

                onEditingFinished: {
                    saveSettings()
                }
            }
        }

        RowLayout {
            spacing: _colSpacing

            QGCLabel { text: qsTr("turnUsername") }
            QGCTextField {
                id:                     turnUsernameField
                Layout.preferredWidth:  _secondColumnWidth * 0.7
                Layout.fillWidth:       true
                text:                   subEditConfig.turnUsername

                onEditingFinished: {
                    saveSettings()
                }
            }
        }

        RowLayout {
            spacing: _colSpacing

            QGCLabel { text: qsTr("turnPassword") }
            QGCTextField {
                id:                     turnPasswordField
                Layout.preferredWidth:  _secondColumnWidth * 0.7
                Layout.fillWidth:       true
                text:                   subEditConfig.turnPassword

                onEditingFinished: {
                    saveSettings()
                }
            }
        }
    }
}
