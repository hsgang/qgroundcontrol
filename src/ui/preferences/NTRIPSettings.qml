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
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.ScreenTools 

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
            text:               qsTr("Connect to NTRIP server (Required Reboot)")
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
            label:              qsTr("Host Address")
            fact:               ntripSettings.ntripServerHostAddress
            visible:            ntripSettings.ntripServerHostAddress.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Server Port")
            fact:               ntripSettings.ntripServerPort
            visible:            ntripSettings.ntripServerPort.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            textFieldPreferredWidth:    _urlFieldWidth
            label:              qsTr("User Name")
            fact:               ntripSettings.ntripUsername
            visible:            ntripSettings.ntripUsername.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Password")
            fact:               ntripSettings.ntripPassword
            visible:            ntripSettings.ntripPassword.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Mount Point")
            fact:               ntripSettings.ntripMountpoint
            visible:            ntripSettings.ntripMountpoint.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("White List")
            fact:               ntripSettings.ntripWhitelist
            visible:            ntripSettings.ntripWhitelist.visible
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Status")

        LabelledLabel {
            label:          qsTr("Connection")
            labelText: QGroundControl.ntrip.connected === true ? qsTr("Connected") : qsTr("Disconnected")
        }

        LabelledLabel {
            label:          qsTr("BandWidth")
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

        LabelledLabel {
            label: "Connection"
            labelText: QGroundControl.ntrip.connected === true ? "Connected" : "Disconnected"
        }

        LabelledLabel {
            label: "BandWidth"
            labelText: QGroundControl.ntrip.bandWidth.toFixed(2) + " kB/s"
        }
    }
}
