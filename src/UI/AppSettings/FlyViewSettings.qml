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
    property var    _modelProfileSettings:              _settingsManager.modelProfileSettings
    property var    _mavlinkActionsSettings:            _settingsManager.mavlinkActionsSettings
    property Fact   _virtualJoystick:                   _settingsManager.appSettings.virtualJoystick
    property Fact   _virtualJoystickAutoCenterThrottle: _settingsManager.appSettings.virtualJoystickAutoCenterThrottle
    property Fact   _virtualJoystickLeftHandedMode:     _settingsManager.appSettings.virtualJoystickLeftHandedMode
    property Fact   _enableMultiVehiclePanel:           _settingsManager.appSettings.enableMultiVehiclePanel
    property Fact   _showAdditionalIndicatorsCompass:   _flyViewSettings.showAdditionalIndicatorsCompass
    property Fact   _lockNoseUpCompass:                 _flyViewSettings.lockNoseUpCompass
    property Fact   _guidedMinimumAltitude:             _flyViewSettings.guidedMinimumAltitude
    property Fact   _guidedMaximumAltitude:             _flyViewSettings.guidedMaximumAltitude
    property Fact   _maxGoToLocationDistance:           _flyViewSettings.maxGoToLocationDistance
    property Fact   _forwardFlightGoToLocationLoiterRad:    _flyViewSettings.forwardFlightGoToLocationLoiterRad
    property Fact   _goToLocationRequiresConfirmInGuided:   _flyViewSettings.goToLocationRequiresConfirmInGuided
    property var    _viewer3DSettings:                  _settingsManager.viewer3DSettings
    property Fact   _viewer3DEnabled:                   _viewer3DSettings.enabled
    property Fact   _viewer3DOsmFilePath:               _viewer3DSettings.osmFilePath
    property Fact   _viewer3DBuildingLevelHeight:       _viewer3DSettings.buildingLevelHeight
    property Fact   _viewer3DAltitudeBias:              _viewer3DSettings.altitudeBias

    QGCFileDialogController { id: fileController }

    function mavlinkActionList() {
        var fileModel = fileController.getFiles(_settingsManager.appSettings.mavlinkActionsSavePath, "*.json")
        fileModel.unshift(qsTr("<None>"))
        return fileModel
    }

    function modelProfileList() {
        var fileModel = fileController.getFiles(_settingsManager.appSettings.modelProfilesSavePath, "*.json")
        fileModel.unshift(qsTr("<None>"))
        return fileModel
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("FlyView General")

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
            text:               qsTr("Enable Multi-Vehicle Panel")
            fact:               _enableMultiVehiclePanel
            visible:            _enableMultiVehiclePanel.visible
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Keep Map Centered On Vehicle")
            fact:               _keepMapCenteredOnVehicle
            visible:            _keepMapCenteredOnVehicle.visible
            property Fact _keepMapCenteredOnVehicle: _flyViewSettings.keepMapCenteredOnVehicle
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Show Grid on Map")
            fact:               _showGridOnMap
            visible:            _showGridOnMap.visible
            property Fact _showGridOnMap: _flyViewSettings.showGridOnMap
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

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Background Opacity")
            fact:               QGroundControl.settingsManager.flyViewSettings.flyviewWidgetOpacity
            indexModel:         false
            comboBoxPreferredWidth: ScreenTools.defaultFontPixelWidth * 16
        }
    }

    SettingsGroupLayout {

        Layout.fillWidth:   true
        heading:            qsTr("Model Profiles")

        LabelledComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Model Profile")
            model:              modelProfileList()
            onActivated:        (index) => index === 0 ? _modelProfileSettings.modelProfileFile.rawValue = "" : _modelProfileSettings.modelProfileFile.rawValue = comboBox.currentText

            Component.onCompleted: {
                var index = comboBox.find(_modelProfileSettings.modelProfileFile.valueString)
                comboBox.currentIndex = index === -1 ? 0 : index
            }
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Instrument Panel")
        visible:            _showAdditionalIndicatorsCompass.visible || _lockNoseUpCompass.visible

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
        visible:            _guidedMinimumAltitude.visible || _guidedMaximumAltitude.visible ||
                            _maxGoToLocationDistance.visible || _forwardFlightGoToLocationLoiterRad.visible ||
                            _goToLocationRequiresConfirmInGuided.visible

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

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Loiter Radius in Forward Flight Guided Mode")
            fact:               _forwardFlightGoToLocationLoiterRad
            visible:            fact.visible
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Require Confirmation for Go To Location in Guided Mode")
            fact:               _goToLocationRequiresConfirmInGuided
            visible:            fact.visible
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Virtual Joystick")
        visible:            _virtualJoystick.visible || _virtualJoystickAutoCenterThrottle.visible || _virtualJoystickLeftHandedMode.visible

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

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Left-Handed Mode (swap sticks)")
            visible:            _virtualJoystickLeftHandedMode.visible
            enabled:            _virtualJoystick.rawValue
            fact:               _virtualJoystickLeftHandedMode
        }
    }

    SettingsGroupLayout {
        id:         customActions
        Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 40
        Layout.fillWidth:       true
        heading:                qsTr("MAVLink Actions")
        headingDescription:     qsTr("Action JSON files should be created in the '%1' folder.").arg(QGroundControl.settingsManager.appSettings.mavlinkActionsSavePath)


        // onVisibleChanged: {
        //     if (jsonFile.rawValue === "" && ScreenTools.isMobile) {
        //         jsonFile.rawValue = _defaultFile
        //     }
        // }

        // property Fact   jsonFile:     QGroundControl.settingsManager.flyViewSettings.customActionDefinitions
        // property string _defaultDir:  QGroundControl.settingsManager.appSettings.customActionsSavePath
        // property string _defaultFile: _defaultDir + "/CustomActions.json"

        // FactCheckBoxSlider {
        //     Layout.fillWidth:   true
        //     text:               qsTr("Enable Custom Actions")
        //     fact:               QGroundControl.settingsManager.flyViewSettings.enableCustomActions
        //     visible:            fact.visible
        // }

        // RowLayout {
        //     Layout.fillWidth: true
        //     spacing:  ScreenTools.defaultFontPixelWidth * 2
        //     visible:  QGroundControl.settingsManager.flyViewSettings.enableCustomActions.rawValue

        //     ColumnLayout {
        //         Layout.fillWidth:   true
        //         spacing:            0

        //         QGCLabel { text: qsTr("Custom Action Definitions") }
        //         QGCLabel {
        //             Layout.fillWidth:   true
        //             font.pointSize:     ScreenTools.smallFontPointSize
        //             text:               customActions.jsonFile.rawValue === "" ? qsTr("<not set>") : customActions.jsonFile.rawValue
        //             elide:              Text.ElideMiddle
        //         }
        //     }

        //     QGCButton {
        //         visible:    !ScreenTools.isMobile
        //         text:       qsTr("Browse")
        //         onClicked:  customActionPathBrowseDialog.openForLoad()
        //         QGCFileDialog {
        //             id:             customActionPathBrowseDialog
        //             title:          qsTr("Choose the Custom Action Definitions file")
        //             folder:         customActions.jsonFile.rawValue.replace("file:///", "")
        //             selectFolder:   false
        //             onAcceptedForLoad: (file) => customActions.jsonFile.rawValue = "file:///" + file
        //             nameFilters: ["JSON files (*.json)"]
        //         }
        //     }

        //     // The file loader on Android doesn't work, so we hard code the path to the
        //     // JSON file. However, we need a button to force a refresh if the JSON file
        //     // is changed.
        //     QGCButton {
        //         visible:    ScreenTools.isMobile
        //         text:       qsTr("Reload")
        //         onClicked:  {
        //             customActions.jsonFile.valueChanged(customActions.jsonFile.rawValue)
        //         }
        //     }
        // }

        LabelledComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Fly View Actions")
            model:              mavlinkActionList()
            onActivated:        (index) => index == 0 ? _mavlinkActionsSettings.flyViewActionsFile.rawValue = "" : _mavlinkActionsSettings.flyViewActionsFile.rawValue = comboBox.currentText
            enabled:            model.length > 1

            Component.onCompleted: {
                var index = comboBox.find(_mavlinkActionsSettings.flyViewActionsFile.valueString)
                comboBox.currentIndex = index == -1 ? 0 : index
            }
        }

        LabelledComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Joystick Actions")
            model:              mavlinkActionList()
            onActivated:        (index) => index == 0 ? _mavlinkActionsSettings.joystickActionsFile.rawValue = "" : _mavlinkActionsSettings.joystickActionsFile.rawValue = comboBox.currentText
            enabled:            model.length > 1

            Component.onCompleted: {
                var index = comboBox.find(_mavlinkActionsSettings.joystickActionsFile.valueString)
                comboBox.currentIndex = index == -1 ? 0 : index
            }
        }
    }

    // SettingsGroupLayout {
    //     Layout.fillWidth:   true
    //     heading:            qsTr("3D View")
    //     visible:            !ScreenTools.isMobile

    //     FactCheckBoxSlider {
    //         Layout.fillWidth:   true
    //         text:               qsTr("Enabled")
    //         fact:               _viewer3DEnabled
    //     }
    //     ColumnLayout{
    //         Layout.fillWidth:   true
    //         spacing: ScreenTools.defaultFontPixelWidth
    //         enabled:            _viewer3DEnabled.rawValue

    //         RowLayout{
    //             Layout.fillWidth:   true
    //             spacing: ScreenTools.defaultFontPixelWidth

    //             QGCLabel {
    //                 wrapMode:           Text.WordWrap
    //                 visible:            true
    //                 text: qsTr("3D Map File:")
    //             }

    //             QGCTextField {
    //                 id:                 osmFileTextField
    //                 height:             ScreenTools.defaultFontPixelWidth * 4.5
    //                 unitsLabel:         ""
    //                 showUnits:          false
    //                 visible:            true
    //                 Layout.fillWidth:   true
    //                 readOnly: true
    //                 text: _viewer3DOsmFilePath.rawValue
    //             }
    //         }
    //         RowLayout{
    //             Layout.alignment: Qt.AlignRight
    //             spacing: ScreenTools.defaultFontPixelWidth

    //             QGCButton {
    //                 text:       qsTr("Clear")

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("3D View")
        visible:            _viewer3DSettings.visible

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Enabled")
            fact:               _viewer3DEnabled
            visible:            _viewer3DEnabled.visible
        }

        ColumnLayout{
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth
            enabled:            _viewer3DEnabled.rawValue
            visible:            _viewer3DOsmFilePath.rawValue

            RowLayout{
                Layout.fillWidth:   true
                spacing:            ScreenTools.defaultFontPixelWidth

                QGCLabel {
                    wrapMode:   Text.WordWrap
                    visible:    true
                    text:       qsTr("3D Map File:")
                }

                QGCTextField {
                    id:                 osmFileTextField
                    height:             ScreenTools.defaultFontPixelWidth * 4.5
                    unitsLabel:         ""
                    showUnits:          false
                    visible:            true
                    Layout.fillWidth:   true
                    readOnly:           true
                    text:               _viewer3DOsmFilePath.rawValue
                }
            }

            RowLayout{
                Layout.alignment:   Qt.AlignRight
                spacing:            ScreenTools.defaultFontPixelWidth

                QGCButton {
                    text: qsTr("Clear")

                    onClicked: {
                        osmFileTextField.text = "Please select an OSM file"
                        _viewer3DOsmFilePath.value = osmFileTextField.text
                    }
                }

                QGCButton {
                    text: qsTr("Select File")

                    onClicked: {
                        var filename = _viewer3DOsmFilePath.rawValue;
                        const found = filename.match(/(.*)[\/\\]/);
                        if(found){
                            filename = found[1]||''; // extracting the directory from the file path
                            fileDialog.folder = (filename[0] === "/")?(filename.slice(1)):(filename);
                        }
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
            visible:            _viewer3DBuildingLevelHeight.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Vehicles Altitude Bias")
            fact:               _viewer3DAltitudeBias
            enabled:            _viewer3DEnabled.rawValue
            visible:            _viewer3DAltitudeBias.visible
        }
    }
}
