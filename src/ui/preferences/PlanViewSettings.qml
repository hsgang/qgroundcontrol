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
    property var _settingsManager:  QGroundControl.settingsManager
    property var _planViewSettings: QGroundControl.settingsManager.planViewSettings

    SettingsGroupLayout {
        heading:        qsTr("PlanView Settings")
        Layout.fillWidth: true

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Default Mission Altitude")
            fact:               _settingsManager.appSettings.defaultMissionItemAltitude
            visible:            fact.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("VTOL TransitionDistance")
            fact:               _planViewSettings.vtolTransitionDistance
            visible:            fact.visible
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Use MAV_CMD_CONDITION_GATE for pattern generation")
            fact:               _planViewSettings.useConditionGate
            visible:            fact.visible
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Missions Do Not Require Takeoff Item")
            fact:               _planViewSettings.takeoffItemNotRequired
            visible:            fact.visible
        }
        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Show ROI function on toolstrip")
            fact:               _planViewSettings.showROIToolstrip
            visible:            fact.visible
        }
    }
}
