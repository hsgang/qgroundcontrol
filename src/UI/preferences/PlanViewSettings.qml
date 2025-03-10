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
            text:               qsTr("Missions do not require takeoff item")
            fact:               _planViewSettings.takeoffItemNotRequired
            visible:            fact.visible
        }
        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Show ROI function on toolstrip")
            fact:               _planViewSettings.showROIToolstrip
            visible:            fact.visible
        }
        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Download mission when connecting vehicle")
            fact:               _planViewSettings.missionDownload
            visible:            fact.visible
            description:        "기체 연결시에 임무경로를 자동 다운로드하여 동기화합니다"
        }
        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Allow configuring multiple landing sequences")
            fact:               _planViewSettings.allowMultipleLandingPatterns
            visible:            fact.visible
        }
    }
}
