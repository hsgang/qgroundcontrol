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
    property var    _ntripManager:      QGroundControl.ntripManager
    property var    _settingsManager:   QGroundControl.settingsManager
    property var    _ntripSettings:     QGroundControl.settingsManager.ntripSettings
    property real   _urlFieldWidth:     ScreenTools.defaultFontPixelWidth * 25

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("NTRIP / RTCM")
        visible:            QGroundControl.settingsManager.ntripSettings.visible

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Enable NTRIP")
            fact:               _ntripSettings.ntripEnabled
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
            fact:               _ntripSettings.ntripServerHostAddress
            visible:            _ntripSettings.ntripServerHostAddress.visible
            enabled:            !_ntripSettings.ntripEnabled.rawValue
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            textFieldPreferredWidth:    _urlFieldWidth
            label:              qsTr("Server Port")
            fact:               _ntripSettings.ntripServerPort
            visible:            _ntripSettings.ntripServerPort.visible
            enabled:            !_ntripSettings.ntripEnabled.rawValue
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            textFieldPreferredWidth:    _urlFieldWidth
            label:              qsTr("User Name")
            fact:               _ntripSettings.ntripUsername
            visible:            _ntripSettings.ntripUsername.visible
            enabled:            !_ntripSettings.ntripEnabled.rawValue
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            textFieldPreferredWidth:    _urlFieldWidth
            label:              qsTr("Password")
            fact:               _ntripSettings.ntripPassword
            visible:            _ntripSettings.ntripPassword.visible
            enabled:            !_ntripSettings.ntripEnabled.rawValue
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            textFieldPreferredWidth:    _urlFieldWidth
            label:              qsTr("Mount Point")
            fact:               _ntripSettings.ntripMountpoint
            visible:            _ntripSettings.ntripMountpoint.visible
            enabled:            !_ntripSettings.ntripEnabled.rawValue
        }

        // LabelledFactTextField {
        //     Layout.fillWidth:   true
        //     textFieldPreferredWidth:    _urlFieldWidth
        //     label:              qsTr("White List")
        //     fact:               _ntripSettings.ntripWhitelist
        //     visible:            _ntripSettings.ntripWhitelist.visible
        //     enabled:            !_ntripSettings.ntripEnabled.rawValue
        // }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Status")

        LabelledLabel {
            label:          qsTr("Connection State")
            labelText: _ntripManager.connectionState
        }
        LabelledLabel {
            label:          qsTr("Connect Error")
            labelText:  _ntripManager.lastError
            visible:    _ntripManager.lastError !== ""
        }
        LabelledLabel {
            label:          qsTr("Connect Rate")
            labelText: (_ntripManager.dataRate / 1024).toFixed(2) + " KB/s"
        }

        LabelledLabel {
            label:          qsTr("Connection")
            labelText: _ntripManager.connected === true ? qsTr("Connected") : qsTr("Disconnected")
        }

        LabelledLabel {
            label:          qsTr("BandWidth")
            labelText: _ntripManager.bandWidth.toFixed(2) + " KB/s"
        }

        // RowLayout {
        //     Rectangle{
        //         width: ScreenTools.defaultFontPixelHeight * 2
        //         height: width
        //         color: red
        //     }
        //     Rectangle{
        //         width: ScreenTools.defaultFontPixelHeight * 2
        //         height: width
        //         color: red
        //     }
        //     Rectangle{
        //         width: ScreenTools.defaultFontPixelHeight * 2
        //         height: width
        //         color: red
        //     }
        //     Rectangle{
        //         width: ScreenTools.defaultFontPixelHeight * 2
        //         height: width
        //         color: red
        //     }
        //     Rectangle{
        //         width: ScreenTools.defaultFontPixelHeight * 2
        //         height: width
        //         color: red
        //     }
        // }

        // LabelledButton {
        //     label:      qsTr("Reconnect NTRIP")
        //     buttonText: qsTr("Reconnect")
        //     onClicked:  {
        //         _ntripManager.reconnect()
        //     }
        // }

        // LabelledButton {
        //     label:      qsTr("Stop NTRIP")
        //     buttonText: qsTr("Stop")
        //     onClicked:  _ntripManager.stop()
        // }
    }
}
