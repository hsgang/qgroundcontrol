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
import QGroundControl.AutoPilotPlugin
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.MultiVehicleManager
import QGroundControl.Controllers
import QGroundControl.FlightDisplay

Rectangle {
    id:     setupView
    color:  qgcPal.window
    z:      QGroundControl.zOrderTopMost

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    ButtonGroup { id: setupButtonGroup }

    ParameterEditorController {
        id: parameterEditorController
    }

    readonly property real      _defaultTextHeight:  ScreenTools.defaultFontPixelHeight
    readonly property real      _defaultTextWidth:   ScreenTools.defaultFontPixelWidth
    readonly property real      _horizontalMargin:   _defaultTextWidth / 2
    readonly property real      _verticalMargin:     _defaultTextHeight / 2
    readonly property real      _buttonHeight:       ScreenTools.isTinyScreen ? ScreenTools.defaultFontPixelHeight * 3 : ScreenTools.defaultFontPixelHeight * 2
    readonly property real      _buttonWidth:       _defaultTextWidth * 18
    readonly property string    _armedVehicleText:  qsTr("This operation cannot be performed while the vehicle is armed.")

    property bool   _vehicleArmed:                  QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle.armed : false
    property string _messagePanelText:              qsTr("missing message panel text")
    property bool   _fullParameterVehicleAvailable: QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable && !QGroundControl.multiVehicleManager.activeVehicle.parameterManager.missingParameters
    property var    _corePlugin:                    QGroundControl.corePlugin

    function showSummaryPanel() {
        if (mainWindow.allowViewSwitch()) {
            _showSummaryPanel()
        }
    }

    function _showSummaryPanel() {
        if (_fullParameterVehicleAvailable) {
            if (QGroundControl.multiVehicleManager.activeVehicle.autopilotPlugin.vehicleComponents.length === 0) {
                panelLoader.setSourceComponent(noComponentsVehicleSummaryComponent)
            } else {
                panelLoader.setSource("qrc:/qml/QGroundControl/VehicleSetup/VehicleSummary.qml")
            }
        } else if (QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable) {
            panelLoader.setSourceComponent(missingParametersVehicleSummaryComponent)
        } else {
            panelLoader.setSourceComponent(disconnectedVehicleSummaryComponent)
        }
        summaryButton.checked = true
    }

    function showPanel(button, qmlSource) {
        if (mainWindow.allowViewSwitch()) {
            button.checked = true
            panelLoader.setSource(qmlSource)
        }
    }

    function showVehicleComponentPanel(vehicleComponent)
    {
        if (mainWindow.allowViewSwitch()) {
            var autopilotPlugin = QGroundControl.multiVehicleManager.activeVehicle.autopilotPlugin
            var prereq = autopilotPlugin.prerequisiteSetup(vehicleComponent)
            if (prereq !== "") {
                _messagePanelText = qsTr("%1 setup must be completed prior to %2 setup.").arg(prereq).arg(vehicleComponent.name)
                panelLoader.setSourceComponent(messagePanelComponent)
            } else {
                panelLoader.setSource(vehicleComponent.setupSource, vehicleComponent)
                for(var i = 0; i < componentRepeater.count; i++) {
                    var obj = componentRepeater.itemAt(i);
                    if (obj.text === vehicleComponent.name) {
                        obj.checked = true
                        break;
                    }
                }
            }
        }
    }

    function showParametersPanel() {
        if (mainWindow.allowViewSwitch()) {
            parametersButton.checked = true
            panelLoader.setSource("qrc:/qml/QGroundControl/VehicleSetup/SetupParameterEditor.qml")
        }
    }

    Component.onCompleted: _showSummaryPanel()

    Connections {
        target: QGroundControl.corePlugin
        function onShowAdvancedUIChanged(showAdvancedUI) {
            if (!showAdvancedUI) {
                _showSummaryPanel()
            }
        }
    }

    Connections {
        target: QGroundControl.multiVehicleManager
        function onParameterReadyVehicleAvailableChanged(parametersReady) {
            if (parametersReady || summaryButton.checked || !firmwareButton.checked) {
                // Show/Reload the Summary panel when:
                //      A new vehicle shows up
                //      The summary panel is already showing and the active vehicle goes away
                //      The active vehicle goes away and we are not on the Firmware panel.
                summaryButton.checked = true
                _showSummaryPanel()
            }
        }
    }

    Component {
        id: noComponentsVehicleSummaryComponent
        Rectangle {
            color: qgcPal.windowShade
            QGCLabel {
                anchors.margins:        _defaultTextWidth * 2
                anchors.fill:           parent
                verticalAlignment:      Text.AlignVCenter
                horizontalAlignment:    Text.AlignHCenter
                wrapMode:               Text.WordWrap
                font.pointSize:         ScreenTools.mediumFontPointSize
                text:                   qsTr("%1 does not currently support setup of your vehicle type. ").arg(QGroundControl.appName) +
                                        qsTr("If your vehicle is already configured you can still Fly.")
                onLinkActivated: Qt.openUrlExternally(link)
            }
        }
    }

    Component {
        id: disconnectedVehicleSummaryComponent
        Rectangle {
            color: qgcPal.windowShade
            ColumnLayout {
                anchors.margins:        _defaultTextWidth * 2
                anchors.fill:           parent
                QGCLabel {
                    Layout.fillWidth: true
                    verticalAlignment:      Text.AlignVCenter
                    horizontalAlignment:    Text.AlignHCenter
                    wrapMode:               Text.WordWrap
                    font.pointSize:         ScreenTools.largeFontPointSize
                    text:                   qsTr("Vehicle settings and info will display after connecting your vehicle.")

                    onLinkActivated: (link) => Qt.openUrlExternally(link)
                }
                Rectangle {
                    color:              qgcPal.windowShade
                    height:             ScreenTools.defaultFontPixelHeight * 5
                    Layout.fillWidth:   true
                    visible:            QGroundControl.multiVehicleManager.activeVehicle
                    Column {
                        anchors.fill:       parent
                        spacing:            ScreenTools.defaultFontPixelHeight / 2
                        QGCButton {
                            anchors.horizontalCenter:   parent.horizontalCenter
                            text:                       qsTr("Refresh parameter")
                            onClicked: {
                                parameterEditorController.refresh()
                            }
                        }
                        ProgressBar {
                            anchors.horizontalCenter:   parent.horizontalCenter
                            width:  parent.width * 0.7
                            value:  QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle.loadProgress : 0
                        }
                        QGCLabel {
                            anchors.horizontalCenter:   parent.horizontalCenter
                            text:   QGroundControl.multiVehicleManager.activeVehicle ? (QGroundControl.multiVehicleManager.activeVehicle.loadProgress * 100).toFixed(1) + " %" : ""
                        }
                    }
                }
            }
        }
    }

    Component {
        id: missingParametersVehicleSummaryComponent

        Rectangle {
            color: qgcPal.windowShade

            QGCLabel {
                anchors.margins:        _defaultTextWidth * 2
                anchors.fill:           parent
                verticalAlignment:      Text.AlignVCenter
                horizontalAlignment:    Text.AlignHCenter
                wrapMode:               Text.WordWrap
                font.pointSize:         ScreenTools.mediumFontPointSize
                text:                   qsTr("You are currently connected to a vehicle but it did not return the full parameter list. ") +
                                        qsTr("As a result, the full set of vehicle setup options are not available.")

                onLinkActivated: (link) => Qt.openUrlExternally(link)
            }
        }
    }

    Component {
        id: messagePanelComponent

        Item {
            QGCLabel {
                anchors.margins:        _defaultTextWidth * 2
                anchors.fill:           parent
                verticalAlignment:      Text.AlignVCenter
                horizontalAlignment:    Text.AlignHCenter
                wrapMode:               Text.WordWrap
                font.pointSize:         ScreenTools.mediumFontPointSize
                text:                   _messagePanelText
            }
        }
    }

    FlyViewToolBar {
        id:         toolbar
        visible:    !QGroundControl.videoManager.fullScreen
    }

    Item {
        id: setupviewHolder
        anchors.top:    toolbar.bottom
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right

        QGCFlickable {
            id:                 buttonScroll
            width:              buttonColumn.width
            anchors.topMargin:  _defaultTextHeight / 2
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            anchors.leftMargin: _horizontalMargin
            anchors.left:       parent.left
            contentHeight:      buttonColumn.height
            flickableDirection: Flickable.VerticalFlick
            clip:               true

            ColumnLayout {
                id:         buttonColumn
                spacing:    _defaultTextHeight / 2

                ConfigButton {
                    id:                 summaryButton
                    icon.source:        "/qmlimages/VehicleSummaryIcon.png"
                    checked:            true
                    text:               qsTr("Summary")
                    Layout.fillWidth:   true

                    onClicked: showSummaryPanel()
                }

                ConfigButton {
                    visible:            QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle.flowImageIndex > 0 : false
                    text:               qsTr("Optical Flow")
                    Layout.fillWidth:   true
                    onClicked:          showPanel(this, "OpticalFlowSensor.qml")
                }

                ConfigButton {
                    id:                 joystickButton
                    icon.source:      "/qmlimages/Joystick.png"
                    setupComplete:      _activeJoystick ? _activeJoystick.calibrated || _buttonsOnly : false
                    visible:            _fullParameterVehicleAvailable && joystickManager.joysticks.length !== 0
                    text:               _forcedToButtonsOnly ? qsTr("Buttons") : qsTr("Joystick")
                    Layout.fillWidth:   true
                    onClicked:          showPanel(this, "JoystickConfig.qml")

                    property var    _activeJoystick:        joystickManager.activeJoystick
                    property bool   _buttonsOnly:           _activeJoystick ? _activeJoystick.axisCount == 0 : false
                    property bool   _forcedToButtonsOnly:   !QGroundControl.corePlugin.options.allowJoystickSelection && _buttonsOnly
                }

                Repeater {
                    id:     componentRepeater
                    model:  _fullParameterVehicleAvailable ? QGroundControl.multiVehicleManager.activeVehicle.autopilotPlugin.vehicleComponents : 0

                    ConfigButton {
                        icon.source:      modelData.iconResource
                        setupComplete:      modelData.setupComplete
                        text:               modelData.name
                        visible:            modelData.setupSource.toString() !== ""
                        Layout.fillWidth:   true
                        onClicked:          showVehicleComponentPanel(componentUrl)

                        property var componentUrl: modelData
                    }
                }

                ConfigButton {
                    id:                 parametersButton
                    visible:            QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable &&
                                        !QGroundControl.multiVehicleManager.activeVehicle.usingHighLatencyLink &&
                                        _corePlugin.showAdvancedUI
                    text:               qsTr("Parameters")
                    Layout.fillWidth:   true
                    icon.source:        "/qmlimages/subMenuButtonImage.png"
                    onClicked:          showPanel(this, "SetupParameterEditor.qml")
                }

                ConfigButton {
                    id:                 firmwareButton
                    icon.source:      "/qmlimages/FirmwareUpgradeIcon.png"
                    visible:            !ScreenTools.isMobile && _corePlugin.options.showFirmwareUpgrade
                    text:               qsTr("Firmware")
                    Layout.fillWidth:   true

                    onClicked: showPanel(this, "FirmwareUpgrade.qml")
                }
            }
        }

        Rectangle {
            id:  topDividerBar
            anchors.top:            parent.top
            anchors.right:          parent.right
            anchors.left:           parent.left
            height:                 1
            color:                  Qt.darker(QGroundControl.globalPalette.text, 4)
        }

        Rectangle {
            id:                     divider
            anchors.topMargin:      _verticalMargin
            anchors.bottomMargin:   _verticalMargin
            anchors.leftMargin:     _horizontalMargin
            anchors.left:           buttonScroll.right
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            width:                  1
            color:                  qgcPal.windowShade
        }

        Loader {
            id:                     panelLoader
            anchors.topMargin:      _verticalMargin
            anchors.bottomMargin:   _verticalMargin
            anchors.leftMargin:     _horizontalMargin
            anchors.rightMargin:    _horizontalMargin
            anchors.left:           divider.right
            anchors.right:          parent.right
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom

            function setSource(source, vehicleComponent) {
                panelLoader.source = ""
                panelLoader.vehicleComponent = vehicleComponent
                panelLoader.source = source
            }

            function setSourceComponent(sourceComponent, vehicleComponent) {
                panelLoader.sourceComponent = undefined
                panelLoader.vehicleComponent = vehicleComponent
                panelLoader.sourceComponent = sourceComponent
            }

            property var vehicleComponent
        }
    }
}
