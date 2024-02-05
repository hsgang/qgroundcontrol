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
import QGroundControl.ScreenTools           1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.Palette               1.0

SettingsPage {
    property var    _settingsManager:                   QGroundControl.settingsManager
    property Fact   _virtualJoystick:                   _settingsManager.appSettings.virtualJoystick
    property Fact   _virtualJoystickAutoCenterThrottle: _settingsManager.appSettings.virtualJoystickAutoCenterThrottle
    property Fact   _alternateInstrumentPanel:          _settingsManager.flyViewSettings.alternateInstrumentPanel
    property Fact   _showAdditionalIndicatorsCompass:   _settingsManager.flyViewSettings.showAdditionalIndicatorsCompass
    property Fact   _lockNoseUpCompass:                 _settingsManager.flyViewSettings.lockNoseUpCompass
    property Fact   _guidedMinimumAltitude:             _settingsManager.flyViewSettings.guidedMinimumAltitude
    property Fact   _guidedMaximumAltitude:             _settingsManager.flyViewSettings.guidedMaximumAltitude
    property Fact   _maxGoToLocationDistance:           _settingsManager.flyViewSettings.maxGoToLocationDistance

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("General")

        FactCheckBoxSlider {
            id:                 useCheckList
            Layout.fillWidth:   true
            text:               qsTr("Use Preflight Checklist")
            fact:               _useChecklist
            visible:            _useChecklist.visible && QGroundControl.corePlugin.options.preFlightChecklistUrl.toString().length
            property Fact _useChecklist:      _settingsManager.appSettings.useChecklist
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Enforce Preflight Checklist")
            fact:               _enforceChecklist
            enabled:            _settingsManager.appSettings.useChecklist.value
            visible:            useCheckList.fact.rawValue && _enforceChecklist.visible
            property Fact _enforceChecklist: _settingsManager.appSettings.enforceChecklist
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Keep Map Centered On Vehicle")
            fact:               _keepMapCenteredOnVehicle
            visible:            _keepMapCenteredOnVehicle.visible
            property Fact _keepMapCenteredOnVehicle: _settingsManager.flyViewSettings.keepMapCenteredOnVehicle
        }

        // FactCheckBoxSlider {
        //     Layout.fillWidth:   true
        //     text:               qsTr("Show Telemetry Log Replay Status Bar")
        //     fact:               _showLogReplayStatusBar
        //     visible:            _showLogReplayStatusBar.visible
        //     property Fact _showLogReplayStatusBar: _settingsManager.flyViewSettings.showLogReplayStatusBar
        // }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Show simple camera controls (DIGICAM_CONTROL)")
            visible:            _showDumbCameraControl.visible
            fact:               _showDumbCameraControl

            property Fact _showDumbCameraControl: _settingsManager.flyViewSettings.showSimpleCameraControl
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Update return to home position based on device location.")
            description:        "Update return to home position based on device location."
            fact:               _updateHomePosition
            visible:            _updateHomePosition.visible
            property Fact _updateHomePosition: _settingsManager.flyViewSettings.updateHomePosition
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Instrument Panel")
        visible:            _alternateInstrumentPanel.visible || _showAdditionalIndicatorsCompass.visible || _lockNoseUpCompass.visible

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Show additional heading indicators on Compass")
            description:        "홈 위치, 다음경로 위치, 풍향 정보 등을 표시"
            visible:            _showAdditionalIndicatorsCompass.visible
            fact:               _showAdditionalIndicatorsCompass
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Lock Compass Nose-Up")
            visible:            _lockNoseUpCompass.visible
            fact:               _lockNoseUpCompass
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Show attitude HUD indicators on Compass")
            description:        "롤 피치 정보를 표시"
            fact:               QGroundControl.settingsManager.flyViewSettings.showAttitudeHUD
            visible:            fact.visible
        }
        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Show Mission Max Altitude Indicator")
            description:        "자동경로상 최대 고도 정보를 표시"
            fact:               QGroundControl.settingsManager.flyViewSettings.missionMaxAltitudeIndicator
            visible:            fact.visible
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Guided Commands")
        visible:            _guidedMinimumAltitude.visible || _guidedMaximumAltitude.visible || _maxGoToLocationDistance.visible

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Minimum Altitude")
            fact:               _guidedMinimumAltitude
            visible:            fact.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Maximum Altitude")
            fact:               _guidedMaximumAltitude
            visible:            fact.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Go To Location Max Distance")
            fact:               _maxGoToLocationDistance
            visible:            fact.visible
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Virtual Joystick")
        visible:            _virtualJoystick.visible || _virtualJoystickAutoCenterThrottle.visible

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Enabled")
            visible:            _virtualJoystick.visible
            fact:               _virtualJoystick
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Auto-Center Throttle")
            visible:            _virtualJoystick.rawValue && _virtualJoystickAutoCenterThrottle.visible
            enabled:            _virtualJoystick.rawValue
            fact:               _virtualJoystickAutoCenterThrottle
        }
    }

    SettingsGroupLayout {
        id:         customActions
        Layout.fillWidth:   true
        heading:            qsTr("Custom Actions")

        onVisibleChanged: {
            if (jsonFile.rawValue === "" && ScreenTools.isMobile) {
                jsonFile.rawValue = _defaultFile
            }
        }

        property Fact   jsonFile:     QGroundControl.settingsManager.flyViewSettings.customActionDefinitions
        property string _defaultDir:  QGroundControl.settingsManager.appSettings.customActionsSavePath
        property string _defaultFile: _defaultDir + "/CustomActions.json"

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Enable Custom Actions")
            fact:               QGroundControl.settingsManager.flyViewSettings.enableCustomActions
            visible:            fact.visible
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: ScreenTools.defaultFontPixelWidth * 2
            visible:  QGroundControl.settingsManager.flyViewSettings.enableCustomActions.rawValue

            ColumnLayout {
                Layout.fillWidth:   true
                spacing:            0

                QGCLabel { text: qsTr("Custom Action Definitions") }
                QGCLabel {
                    Layout.fillWidth:   true
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               customActions.jsonFile.rawValue === "" ? qsTr("<not set>") : customActions.jsonFile.rawValue
                    elide:              Text.ElideMiddle
                }
            }

            QGCButton {
                visible:    !ScreenTools.isMobile
                text:       qsTr("Browse")
                onClicked:  customActionPathBrowseDialog.openForLoad()
                QGCFileDialog {
                    id:             customActionPathBrowseDialog
                    title:          qsTr("Choose the Custom Action Definitions file")
                    folder:         customActions.jsonFile.rawValue.replace("file:///", "")
                    selectFolder:   false
                    onAcceptedForLoad: (file) => customActions.jsonFile.rawValue = "file:///" + file
                    nameFilters: ["JSON files (*.json)"]
                }
            }

            // The file loader on Android doesn't work, so we hard code the path to the
            // JSON file. However, we need a button to force a refresh if the JSON file
            // is changed.
            QGCButton {
                visible:    ScreenTools.isMobile
                text:       qsTr("Reload")
                onClicked:  {
                    customActions.jsonFile.valueChanged(customActions.jsonFile.rawValue)
                }
            }
        }
    }
}
