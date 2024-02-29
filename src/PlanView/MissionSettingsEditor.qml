import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Vehicle
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.Palette
import QGroundControl.SettingsManager
import QGroundControl.Controllers

// Editor for Mission Settings
Rectangle {
    id:                 valuesRect
    width:              availableWidth
    height:             valuesColumn.height + (_margin * 2)
    color:              qgcPal.window
    visible:            missionItem.isCurrentItem
    radius:             _radius

    property var    _masterControler:               masterController
    property var    _missionController:             _masterControler.missionController
    property var    _controllerVehicle:             _masterControler.controllerVehicle
    property bool   _vehicleHasHomePosition:        _controllerVehicle.homePosition.isValid
    property bool   _showCruiseSpeed:               !_controllerVehicle.multiRotor
    property bool   _showHoverSpeed:                _controllerVehicle.multiRotor || _controllerVehicle.vtol
    property bool   _multipleFirmware:              !QGroundControl.singleFirmwareSupport
    property bool   _multipleVehicleTypes:          !QGroundControl.singleVehicleSupport
    property real   _fieldWidth:                    ScreenTools.defaultFontPixelWidth * 16
    property bool   _mobile:                        ScreenTools.isMobile
    property var    _savePath:                      QGroundControl.settingsManager.appSettings.missionSavePath
    property var    _fileExtension:                 QGroundControl.settingsManager.appSettings.missionFileExtension
    property var    _appSettings:                   QGroundControl.settingsManager.appSettings
    property bool   _waypointsOnlyMode:             QGroundControl.corePlugin.options.missionWaypointsOnly
    property bool   _showCameraSection:             (_waypointsOnlyMode || QGroundControl.corePlugin.showAdvancedUI) && !_controllerVehicle.apmFirmware
    property bool   _simpleMissionStart:            QGroundControl.corePlugin.options.showSimpleMissionStart
    property bool   _showFlightSpeed:               !_controllerVehicle.vtol && !_simpleMissionStart && !_controllerVehicle.apmFirmware
    property bool   _allowFWVehicleTypeSelection:   _noMissionItemsAdded && !globals.activeVehicle

    readonly property string _firmwareLabel:    qsTr("Firmware")
    readonly property string _vehicleLabel:     qsTr("Vehicle")
    readonly property real  _margin:            ScreenTools.defaultFontPixelWidth / 2

    QGCPalette { id: qgcPal }
    QGCFileDialogController { id: fileController }
    Component {
        id: altModeDialogComponent
        AltModeDialog { }
    }

    Connections {
        target: _controllerVehicle
        function onSupportsTerrainFrameChanged() {
            if (!_controllerVehicle.supportsTerrainFrame && _missionController.globalAltitudeMode === QGroundControl.AltitudeModeTerrainFrame) {
                _missionController.globalAltitudeMode = QGroundControl.AltitudeModeCalcAboveTerrain
            }
        }
    }

    ColumnLayout {
        id:                 valuesColumn
        anchors.margins:    _margin
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.top:        parent.top
        spacing:            _margin

        SettingsGroupLayout {
            RowLayout{
                Layout.fillWidth: true

                QGCLabel {
                    text:           qsTr("All Altitudes")
                    //font.pointSize: ScreenTools.smallFontPointSize
                }
                MouseArea {
                    Layout.preferredWidth:  childrenRect.width
                    Layout.preferredHeight: childrenRect.height
                    enabled:                _noMissionItemsAdded
                    Layout.alignment:       Qt.AlignRight

                    onClicked: {
                        var removeModes = []
                        var updateFunction = function(altMode){ _missionController.globalAltitudeMode = altMode }
                        if (!_controllerVehicle.supportsTerrainFrame) {
                            removeModes.push(QGroundControl.AltitudeModeTerrainFrame)
                        }
                        altModeDialogComponent.createObject(mainWindow, { rgRemoveModes: removeModes, updateAltModeFn: updateFunction }).open()
                    }

                    RowLayout {
                        spacing: ScreenTools.defaultFontPixelWidth
                        enabled: _noMissionItemsAdded

                        QGCLabel {
                            id:     altModeLabel
                            text:   QGroundControl.altitudeModeShortDescription(_missionController.globalAltitudeMode)
                        }
                        QGCColoredImage {
                            height:     ScreenTools.defaultFontPixelHeight / 2
                            width:      height
                            source:     "/res/DropArrow.svg"
                            color:      altModeLabel.color
                        }
                    }
                }
            }

            LabelledFactTextField {
                label:      qsTr("Initial Waypoint Alt")
                fact:       QGroundControl.settingsManager.appSettings.defaultMissionItemAltitude
                textFieldPreferredWidth: ScreenTools.defaultFontPixelWidth * 10
            }

            GridLayout {
                Layout.fillWidth:   true
                columnSpacing:      ScreenTools.defaultFontPixelWidth
                rowSpacing:         columnSpacing
                columns:            2
                visible:            _showFlightSpeed

                QGCCheckBox {
                    id:         flightSpeedCheckBox
                    text:       qsTr("Flight speed")
                    visible:    _showFlightSpeed
                    checked:    missionItem.speedSection.specifyFlightSpeed
                    onClicked:   missionItem.speedSection.specifyFlightSpeed = checked
                }
                FactTextField {
                    Layout.fillWidth:   true
                    fact:               missionItem.speedSection.flightSpeed
                    visible:            _showFlightSpeed
                    enabled:            flightSpeedCheckBox.checked
                }
            }
        }

        SettingsGroupLayout {
            heading:    qsTr("Camera")
            visible:    _showCameraSection

            Column {
                Layout.fillWidth:   true
                spacing:            _margin
                visible:            !_simpleMissionStart

                CameraSection {
                    id:         cameraSection
                    checked:    !_waypointsOnlyMode && missionItem.cameraSection.settingsSpecified
                    visible:    _showCameraSection
                }

                QGCLabel {
                    anchors.left:           parent.left
                    anchors.right:          parent.right
                    text:                   qsTr("Above camera commands will take affect immediately upon mission start.")
                    wrapMode:               Text.WordWrap
                    horizontalAlignment:    Text.AlignHCenter
                    font.pointSize:         ScreenTools.smallFontPointSize
                    visible:                _showCameraSection && cameraSection.checked
                }
            }
        }

        SettingsGroupLayout {
            Layout.fillWidth: true

            SectionHeader {
                id:             vehicleInfoSectionHeader
                Layout.fillWidth: true
                text:           qsTr("Vehicle Info")
                visible:        !_waypointsOnlyMode
                checked:        false
            }

            LabelledFactComboBox {
                label:      _firmwareLabel
                fact:       QGroundControl.settingsManager.appSettings.offlineEditingFirmwareClass
                indexModel: false
                visible:    _multipleFirmware && _allowFWVehicleTypeSelection && vehicleInfoSectionHeader.visible && vehicleInfoSectionHeader.checked
                comboBoxPreferredWidth: ScreenTools.defaultFontPixelWidth * 15
            }

            LabelledLabel{
                label:      _firmwareLabel
                labelText:  _controllerVehicle.firmwareTypeString
                visible:    _multipleFirmware && !_allowFWVehicleTypeSelection && vehicleInfoSectionHeader.visible && vehicleInfoSectionHeader.checked
            }

            LabelledFactComboBox {
                label:      _vehicleLabel
                fact:       QGroundControl.settingsManager.appSettings.offlineEditingVehicleClass
                indexModel: false
                visible:    _multipleVehicleTypes && _allowFWVehicleTypeSelection && vehicleInfoSectionHeader.visible && vehicleInfoSectionHeader.checked
                comboBoxPreferredWidth: ScreenTools.defaultFontPixelWidth * 15
            }

            LabelledLabel{
                label:      _vehicleLabel
                labelText:  _controllerVehicle.vehicleTypeString
                visible:    _multipleVehicleTypes && !_allowFWVehicleTypeSelection && vehicleInfoSectionHeader.visible && vehicleInfoSectionHeader.checked
            }

            LabelledFactTextField {
                Layout.fillWidth:   true
                label:              qsTr("Cruise speed")
                description:        qsTr("The following speed values are used to calculate total mission time. They do not affect the flight speed for the mission.")
                fact:               QGroundControl.settingsManager.appSettings.offlineEditingCruiseSpeed
                visible:            _showCruiseSpeed && vehicleInfoSectionHeader.visible && vehicleInfoSectionHeader.checked
                textFieldPreferredWidth: ScreenTools.defaultFontPixelWidth * 10
            }

            LabelledFactTextField {
                Layout.fillWidth:   true
                label:              qsTr("Hover speed")
                description:        qsTr("The following speed values are used to calculate total mission time. They do not affect the flight speed for the mission.")
                fact:               QGroundControl.settingsManager.appSettings.offlineEditingHoverSpeed
                visible:            _showHoverSpeed && vehicleInfoSectionHeader.visible && vehicleInfoSectionHeader.checked
                textFieldPreferredWidth: ScreenTools.defaultFontPixelWidth * 10
            }

            SectionHeader {
                id:             plannedHomePositionSection
                Layout.fillWidth: true
                text:           qsTr("Launch Position")
                visible:        !_vehicleHasHomePosition
                checked:        false
            }

            LabelledFactTextField{
                Layout.fillWidth: true
                textFieldPreferredWidth: ScreenTools.defaultFontPixelWidth * 10
                label:  qsTr("Altitude")
                fact:   missionItem.plannedHomePositionAltitude
                description: qsTr("Actual position set by vehicle at flight time.")
                visible:        plannedHomePositionSection.checked && !_vehicleHasHomePosition
            }

            QGCButton {
                text:                       qsTr("Set To Map Center")
                onClicked:                  missionItem.coordinate = map.center
                Layout.alignment:           Qt.AlignHCenter
            }
        }
    }
}
