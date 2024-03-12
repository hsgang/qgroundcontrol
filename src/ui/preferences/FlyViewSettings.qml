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
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.MultiVehicleManager
import QGroundControl.Palette
import QGroundControl.Controllers

SettingsPage {
    property var    _settingsManager:                   QGroundControl.settingsManager
    property var    _flyViewSettings:                   _settingsManager.flyViewSettings
    property var    _customMavlinkActionsSettings:      _settingsManager.customMavlinkActionsSettings
    property Fact   _virtualJoystick:                   _settingsManager.appSettings.virtualJoystick
    property Fact   _virtualJoystickAutoCenterThrottle: _settingsManager.appSettings.virtualJoystickAutoCenterThrottle
    property Fact   _showAdditionalIndicatorsCompass:   _flyViewSettings.showAdditionalIndicatorsCompass
    property Fact   _lockNoseUpCompass:                 _flyViewSettings.lockNoseUpCompass
    property Fact   _guidedMinimumAltitude:             _flyViewSettings.guidedMinimumAltitude
    property Fact   _guidedMaximumAltitude:             _flyViewSettings.guidedMaximumAltitude
    property Fact   _maxGoToLocationDistance:           _flyViewSettings.maxGoToLocationDistance
    property Fact   _viewer3DEnabled:                   _settingsManager.viewer3DSettings.enabled
    property Fact   _viewer3DOsmFilePath:               _settingsManager.viewer3DSettings.osmFilePath
    property Fact   _viewer3DBuildingLevelHeight:       _settingsManager.viewer3DSettings.buildingLevelHeight
    property Fact   _viewer3DAltitudeBias:              _settingsManager.viewer3DSettings.altitudeBias

    QGCFileDialogController { id: fileController }

    function customActionList() {
        var fileModel = fileController.getFiles(_settingsManager.appSettings.customActionsSavePath, "*.json")
        fileModel.unshift(qsTr("<None>"))
        return fileModel
    }

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
            property Fact _keepMapCenteredOnVehicle: _flyViewSettings.keepMapCenteredOnVehicle
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

            property Fact _showDumbCameraControl: _flyViewSettings.showSimpleCameraControl
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Update return to home position based on device location.")
            description:        "Update return to home position based on device location."
            fact:               _updateHomePosition
            visible:            _updateHomePosition.visible
            property Fact _updateHomePosition: _flyViewSettings.updateHomePosition
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
        Layout.fillWidth:       true
        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 35
        heading:                qsTr("Custom MAVLink Actions")
        headingDescription:     qsTr("Custom action JSON files should be created in the '%1' folder.").arg(QGroundControl.settingsManager.appSettings.customActionsSavePath)

        LabelledComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Fly View Custom Actions")
            model:              customActionList()
            onActivated:        (index) => index == 0 ? _customMavlinkActionsSettings.flyViewActionsFile.rawValue = "" : _customMavlinkActionsSettings.flyViewActionsFile.rawValue = comboBox.currentText

            Component.onCompleted: {
                var index = comboBox.find(_customMavlinkActionsSettings.flyViewActionsFile.valueString)
                comboBox.currentIndex = index == -1 ? 0 : index
            }
        }

        LabelledComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Joystick Custom Actions")
            model:              customActionList()
            onActivated:        (index) => index == 0 ? _customMavlinkActionsSettings.joystickActionsFile.rawValue = "" : _customMavlinkActionsSettings.joystickActionsFile.rawValue = comboBox.currentText

            Component.onCompleted: {
                var index = comboBox.find(_customMavlinkActionsSettings.joystickActionsFile.valueString)
                comboBox.currentIndex = index == -1 ? 0 : index
            }
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
            visible:            _virtualJoystickAutoCenterThrottle.visible
            enabled:            _virtualJoystick.rawValue
            fact:               _virtualJoystickAutoCenterThrottle
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Instrument Panel")
        visible:            _showAdditionalIndicatorsCompass.visible || _lockNoseUpCompass.visible

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Show additional heading indicators on Compass")
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
            fact:               QGroundControl.settingsManager.flyViewSettings.showAttitudeHUD
            visible:            fact.visible
        }
        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Show Mission Max Altitude Indicator")
            fact:               QGroundControl.settingsManager.flyViewSettings.missionMaxAltitudeIndicator
            visible:            fact.visible
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

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("3D View")

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Enabled")
            fact:               _viewer3DEnabled
        }
        ColumnLayout{
            Layout.fillWidth:   true
            spacing: ScreenTools.defaultFontPixelWidth
            enabled:            _viewer3DEnabled.rawValue

            RowLayout{
                Layout.fillWidth:   true
                spacing: ScreenTools.defaultFontPixelWidth

                QGCLabel {
                    wrapMode:           Text.WordWrap
                    visible:            true
                    text: qsTr("3D Map File:")
                }

                QGCTextField {
                    id:                 osmFileTextField
                    height:             ScreenTools.defaultFontPixelWidth * 4.5
                    unitsLabel:         ""
                    showUnits:          false
                    visible:            true
                    Layout.fillWidth:   true
                    readOnly: true
                    text: _viewer3DOsmFilePath.rawValue
                }
            }
            RowLayout{
                Layout.alignment: Qt.AlignRight
                spacing: ScreenTools.defaultFontPixelWidth

                QGCButton {
                    text:       qsTr("Clear")

                    onClicked: {
                        osmFileTextField.text = "Please select an OSM file"
                        _viewer3DOsmFilePath.value = osmFileTextField.text
                    }
                }

                QGCButton {
                    text:       qsTr("Select File")

                    onClicked: {
                        fileDialog.openForLoad()
                    }

                    QGCFileDialog {
                        id:             fileDialog
                        nameFilters:    [qsTr("OpenStreetMap files (*.osm)")]
                        title:          qsTr("Select map file")
                        onAcceptedForLoad: (file) => {
                                               osmFileTextField.text = file
                                               _viewer3DOsmFilePath.value = osmFileTextField.text
                                           }
                    }
                }
            }
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Average Building Level Height")
            fact:               _viewer3DBuildingLevelHeight
            enabled:            _viewer3DEnabled.rawValue
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Vehicles Altitude Bias")
            fact:               _viewer3DAltitudeBias
            enabled:            _viewer3DEnabled.rawValue
        }
    }
}
