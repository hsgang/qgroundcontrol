/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.3
import QtQuick.Controls         1.2
import QtQuick.Controls.Styles  1.4
import QtQuick.Layouts          1.2

import QGroundControl                       1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.FactControls          1.0
import QGroundControl.Controls              1.0
import QGroundControl.Palette               1.0
import QGroundControl.ScreenTools           1.0

SettingsPage {
    property var    _settingsManager:           QGroundControl.settingsManager
    property var    ntripSettings:    QGroundControl.settingsManager.ntripSettings
    property real   _urlFieldWidth:             ScreenTools.defaultFontPixelWidth * 25

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("NTRIP / RTCM")
        visible:            QGroundControl.settingsManager.ntripSettings.visible

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               ntripSettings.ntripServerConnectEnabled.shortDescription
            fact:               ntripSettings.ntripServerConnectEnabled
            visible:            fact.visible
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Settings")

        LabelledFactTextField {
            Layout.fillWidth:   true
            textFieldPreferredWidth:    _urlFieldWidth
            label:              ntripSettings.ntripServerHostAddress.shortDescription
            fact:               ntripSettings.ntripServerHostAddress
            visible:            ntripSettings.ntripServerHostAddress.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              ntripSettings.ntripServerPort.shortDescription
            fact:               ntripSettings.ntripServerPort
            visible:            ntripSettings.ntripServerPort.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            textFieldPreferredWidth:    _urlFieldWidth
            label:              ntripSettings.ntripUsername.shortDescription
            fact:               ntripSettings.ntripUsername
            visible:            ntripSettings.ntripUsername.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              ntripSettings.ntripPassword.shortDescription
            fact:               ntripSettings.ntripPassword
            visible:            ntripSettings.ntripPassword.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              ntripSettings.ntripMountpoint.shortDescription
            fact:               ntripSettings.ntripMountpoint
            visible:            ntripSettings.ntripMountpoint.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              ntripSettings.ntripWhitelist.shortDescription
            fact:               ntripSettings.ntripWhitelist
            visible:            ntripSettings.ntripWhitelist.visible
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Status")

        LabelledLabel {
            label: "Connection"
            labelText: QGroundControl.ntrip.connected === true ? "Connected" : "Disconnected"
        }

        LabelledLabel {
            label: "BandWidth"
            labelText: QGroundControl.ntrip.bandWidth.toFixed(2) + " kB/s"
        }

        LabelledButton {
            label:      qsTr("Reconnect NTRIP")
            buttonText: qsTr("Reconnect")
            onClicked:  {
                QGroundControl.ntrip.reconnectNTRIP()
            }
        }

        LabelledButton {
            label:      qsTr("Stop NTRIP")
            buttonText: qsTr("Stop")
            onClicked:  QGroundControl.ntrip.stopNTRIP()
        }
    }
}
