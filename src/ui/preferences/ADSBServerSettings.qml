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

SettingsPage {
    property var    _settingsManager:           QGroundControl.settingsManager
    property var     _adsbSettings:             _settingsManager.adsbVehicleManagerSettings
    property Fact   _adsbServerConnectEnabled:  _adsbSettings.adsbServerConnectEnabled

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("ADSB Server")
        visible:            QGroundControl.settingsManager.adsbVehicleManagerSettings.visible

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               fact.shortDescription
            fact:               _adsbServerConnectEnabled
            visible:            fact.visible
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Settings")
        visible:             _adsbSettings.adsbServerHostAddress.visible || _adsbSettings.adsbServerPort.visible
        enabled:             _adsbServerConnectEnabled.rawValue

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              fact.shortDescription
            fact:               _adsbSettings.adsbServerHostAddress
            visible:            fact.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              fact.shortDescription
            fact:               _adsbSettings.adsbServerPort
            visible:            fact.visible
        }
    }
}
