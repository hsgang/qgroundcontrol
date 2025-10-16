/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import QGroundControl
import QGroundControl.Controls





Rectangle {
    id:             control
    width:          ScreenTools.defaultFontPixelHeight * 10//Math.max(rowLayout.width + _margins, ScreenTools.defaultFontPixelHeight * 10)
    height:         parent.height
    color:          QGroundControl.globalPalette.widgetTransparentColor
    radius:         ScreenTools.defaultFontPixelHeight / 4
    border.color:   _mainStatusBGColor
    border.width:   2

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _armed:             _activeVehicle ? _activeVehicle.armed : false
    property real   _margins:           ScreenTools.defaultFontPixelHeight
    property real   _spacing:           ScreenTools.defaultFontPixelHeight / 2
    property bool   _allowForceArm:      false
    property bool   _healthAndArmingChecksSupported: _activeVehicle ? _activeVehicle.healthAndArmingCheckReport.supported : false
    property bool   _vehicleFlies:      _activeVehicle ? _activeVehicle.airShip || _activeVehicle.fixedWing || _activeVehicle.vtol || _activeVehicle.multiRotor : false
    property var    _vehicleInAir:      _activeVehicle ? _activeVehicle.flying || _activeVehicle.landing : false
    property bool   _vtolInFWDFlight:   _activeVehicle ? _activeVehicle.vtolInFwdFlight : false

    function dropMainStatusIndicator() {
        let overallStatusComponent = _activeVehicle ? overallStatusIndicatorPage : overallStatusOfflineIndicatorPage
        mainWindow.showIndicatorDrawer(overallStatusComponent, control)
    }

    QGCPalette { id: qgcPal }

    RowLayout {
        id:          rowLayout
        spacing:                    0
        anchors.fill:               parent
        anchors.leftMargin:         ScreenTools.defaultFontPixelHeight
        anchors.rightMargin:        ScreenTools.defaultFontPixelHeight
        //anchors.horizontalCenter:   parent.horizontalCenter
        anchors.verticalCenter:     parent.verticalCenter

        QGCLabel {
            id:                 mainStatusLabel
            Layout.fillHeight:  true
            Layout.fillWidth:   true
            //Layout.preferredWidth: contentWidth + control.spacing
            verticalAlignment:  Text.AlignVCenter
            horizontalAlignment:Text.AlignHCenter
            text:               mainStatusText()
            font.pointSize:     ScreenTools.largeFontPointSize
            font.bold:          true

            property string _commLostText:      qsTr("Comms Lost")
            property string _readyToFlyText:    control._vehicleFlies ? qsTr("Ready To Fly") : qsTr("Ready")
            property string _notReadyToFlyText: qsTr("Not Ready")
            property string _disconnectedText:  qsTr("Disconnected")
            property string _armedText:         qsTr("Armed")
            property string _flyingText:        qsTr("Flying")
            property string _landingText:       qsTr("Landing")

            function mainStatusText() {
                var statusText
                if (_activeVehicle) {
                    if (_communicationLost) {
                        _mainStatusBGColor = "red"
                        return mainStatusLabel._commLostText
                    }
                    if (_activeVehicle.armed) {
                        _mainStatusBGColor = qgcPal.colorGreen

                        if (_healthAndArmingChecksSupported) {
                            if (_activeVehicle.healthAndArmingCheckReport.canArm) {
                                if (_activeVehicle.healthAndArmingCheckReport.hasWarningsOrErrors) {
                                    _mainStatusBGColor = qgcPal.colorYellow
                                }
                            } else {
                                _mainStatusBGColor = qgcPal.colorRed
                            }
                        }

                        if (_activeVehicle.flying) {
                            return mainStatusLabel._flyingText
                        } else if (_activeVehicle.landing) {
                            return mainStatusLabel._landingText
                        } else {
                            return mainStatusLabel._armedText
                        }
                    } else {
                        if (_healthAndArmingChecksSupported) {
                            if (_activeVehicle.healthAndArmingCheckReport.canArm) {
                                if (_activeVehicle.healthAndArmingCheckReport.hasWarningsOrErrors) {
                                    _mainStatusBGColor = qgcPal.colorYellow
                                } else {
                                    _mainStatusBGColor = qgcPal.colorGreen
                                }
                                return mainStatusLabel._readyToFlyText
                            } else {
                                _mainStatusBGColor = qgcPal.colorRed
                                return mainStatusLabel._notReadyToFlyText
                            }
                        } else if (_activeVehicle.loadProgress) {
                                _mainStatusBGColor = qgcPal.colorYellow
                                return mainStatusLabel._parametersSynchronizingText
                        } else if (_activeVehicle.readyToFlyAvailable) {
                            if (_activeVehicle.readyToFly) {
                                _mainStatusBGColor = qgcPal.colorGreen
                                return mainStatusLabel._readyToFlyText
                            } else {
                                _mainStatusBGColor = qgcPal.colorYellow
                                return mainStatusLabel._notReadyToFlyText
                            }
                        } else {
                            // Best we can do is determine readiness based on AutoPilot component setup and health indicators from SYS_STATUS
                            if (_activeVehicle.allSensorsHealthy && _activeVehicle.autopilotPlugin.setupComplete) {
                                _mainStatusBGColor = qgcPal.colorGreen
                                return mainStatusLabel._readyToFlyText
                            } else {
                                _mainStatusBGColor = qgcPal.colorYellow
                                return mainStatusLabel._notReadyToFlyText
                            }
                        }
                    }
                } else {
                    _mainStatusBGColor = qgcPal.brandingBlue
                    return mainStatusLabel._disconnectedText
                }
            }

            QGCMouseArea {
                anchors.fill:   parent
                onClicked:      dropMainStatusIndicator()
            }
        }

        Item {
            visible:                vtolModeLabel.visible
            implicitWidth:  ScreenTools.defaultFontPixelWidth * ScreenTools.largeFontPointRatio * 1.5
            implicitHeight: 1
        }

        QGCLabel {
            id:                 vtolModeLabel
            Layout.fillHeight:  true
            verticalAlignment:  Text.AlignVCenter
            text:               _vtolInFWDFlight ? qsTr("FW(vtol)") : qsTr("MR(vtol)")
            font.pointSize:     _vehicleInAir ? ScreenTools.largeFontPointSize : ScreenTools.defaultFontPointSize
            visible:            _activeVehicle && _activeVehicle.vtol

            QGCMouseArea {
                anchors.fill: parent
                onClicked: {
                    if (_vehicleInAir) {
                        mainWindow.showIndicatorDrawer(vtolTransitionIndicatorPage)
                    }
                }
            }
        }

        Component {
            id: overallStatusOfflineIndicatorPage

            MainStatusIndicatorOfflinePage {}
        }

        Component {
            id: overallStatusIndicatorPage

            ToolIndicatorPage {
                showExpand:         true
                waitForParameters:  true
                contentComponent:   mainStatusContentComponent
                expandedComponent:  mainStatusExpandedComponent
            }
        }

        Component {
            id: mainStatusContentComponent

            ColumnLayout {
                id:         mainLayout
                spacing:    _spacing

                RowLayout {
                    spacing: ScreenTools.defaultFontPixelWidth

                    QGCDelayButton {
                        enabled:    _armed || !_healthAndArmingChecksSupported || _activeVehicle.healthAndArmingCheckReport.canArm
                        text:       _armed ? qsTr("Disarm") : (control._allowForceArm ? qsTr("Force Arm") : qsTr("Arm"))
                        showHelp:   true

                        onActivated: {
                            if (_armed) {
                                _activeVehicle.armed = false
                            } else {
                                if (_allowForceArm) {
                                    _allowForceArm = false
                                    _activeVehicle.forceArm()
                                } else {
                                    _activeVehicle.armed = true
                                }
                            }
                            mainWindow.closeIndicatorDrawer()
                        }
                    }

                    LabelledComboBox {
                        id:                 primaryLinkCombo
                        Layout.alignment:   Qt.AlignTop
                        label:              qsTr("Primary Link")
                        alternateText:      _primaryLinkName
                        visible:            _activeVehicle && _activeVehicle.vehicleLinkManager.linkNames.length > 1

                        property var    _rgLinkNames:       _activeVehicle ? _activeVehicle.vehicleLinkManager.linkNames : [ ]
                        property var    _rgLinkStatus:      _activeVehicle ? _activeVehicle.vehicleLinkManager.linkStatuses : [ ]
                        property string _primaryLinkName:   _activeVehicle ? _activeVehicle.vehicleLinkManager.primaryLinkName : ""

                        function updateComboModel() {
                            let linkModel = []
                            for (let i = 0; i < _rgLinkNames.length; i++) {
                                let linkStatus = _rgLinkStatus[i]
                                linkModel.push(_rgLinkNames[i] + (linkStatus === "" ? "" : " " + _rgLinkStatus[i]))
                            }
                            primaryLinkCombo.model = linkModel
                            primaryLinkCombo.currentIndex = -1
                        }

                        Component.onCompleted:  updateComboModel()
                        on_RgLinkNamesChanged:  updateComboModel()
                        on_RgLinkStatusChanged: updateComboModel()

                        onActivated:    (index) => { 
                            _activeVehicle.vehicleLinkManager.primaryLinkName = _rgLinkNames[index]; currentIndex = -1
                            mainWindow.closeIndicatorDrawer()
                        }
                    }
                }

                // SettingsGroupLayout {
                //     //Layout.fillWidth:   true
                //     heading:            qsTr("Vehicle Messages")
                //     visible:            !vehicleMessageList.noMessages

                //     VehicleMessageList {
                //         id: vehicleMessageList
                //     }
                // }

                SettingsGroupLayout {
                    //Layout.fillWidth:   true
                    heading:            qsTr("Sensor Status")
                    visible:            !_healthAndArmingChecksSupported

                    GridLayout {
                        rowSpacing:     _spacing
                        columnSpacing:  _spacing
                        rows:           _activeVehicle.sysStatusSensorInfo.sensorNames.length
                        flow:           GridLayout.TopToBottom

                        Repeater {
                                    model: _activeVehicle.sysStatusSensorInfo.sensorNames
                                    QGCLabel { text: modelData }
                        }
                        Repeater {
                            model: _activeVehicle.sysStatusSensorInfo.sensorStatus
                            QGCLabel { text: modelData }
                        }
                        Repeater {
                            model: _activeVehicle.sysStatusSensorInfo.sensorStatus
                            Rectangle {
                                function markColor() {
                                    if(modelData === qsTr("Error")){
                                        return "red"
                                    } else if (modelData === qsTr("Normal")) {
                                        return "green"
                                    } else if (modelData === qsTr("Disabled")) {
                                        return "gray"
                                    }
                                }

                                width: ScreenTools.defaultFontPixelWidth
                                height: width
                                radius: width /2
                                color: markColor()
                            }
                        }
                    }
                }

                SettingsGroupLayout {
                    //Layout.fillWidth:   true
                    heading:            qsTr("Overall Status")
                    visible:            _healthAndArmingChecksSupported && _activeVehicle.healthAndArmingCheckReport.problemsForCurrentMode.count > 0

                    // List health and arming checks
                    Repeater {
                        model:      _activeVehicle ? _activeVehicle.healthAndArmingCheckReport.problemsForCurrentMode : null
                        delegate:   listdelegate
                    }
                }

                FactPanelController {
                    id: controller
                }

                Component {
                    id: listdelegate

                    Column {
                        Row {
                            spacing: ScreenTools.defaultFontPixelHeight
                            
                            QGCLabel {
                                id:           message
                                text:         object.message
                                textFormat:   TextEdit.RichText
                                color:        object.severity == 'error' ? qgcPal.colorRed : object.severity == 'warning' ? qgcPal.colorYellow : qgcPal.text
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (object.description != "")
                                            object.expanded = !object.expanded
                                    }
                                }
                            }

                            QGCColoredImage {
                                id:                     arrowDownIndicator
                                anchors.verticalCenter: parent.verticalCenter
                                height:                 1.5 * ScreenTools.defaultFontPixelWidth
                                width:                  height
                                source:                 "/qmlimages/arrow-down.png"
                                color:                  qgcPal.text
                                visible:                object.description != ""
                                MouseArea {
                                    anchors.fill:       parent
                                    onClicked:          object.expanded = !object.expanded
                                }
                            }
                        }

                        QGCLabel {
                            id:                 description
                            text:               object.description
                            textFormat:         TextEdit.RichText
                            clip:               true
                            visible:            object.expanded

                            property var fact:  null

                            onLinkActivated: {
                                if (link.startsWith('param://')) {
                                    var paramName = link.substr(8);
                                    fact = controller.getParameterFact(-1, paramName, true)
                                    if (fact != null) {
                                        paramEditorDialogComponent.createObject(mainWindow).open()
                                    }
                                } else {
                                    Qt.openUrlExternally(link);
                                }
                            }

                            Component {
                                id: paramEditorDialogComponent

                                ParameterEditorDialog {
                                    title:          qsTr("Edit Parameter")
                                    fact:           description.fact
                                    destroyOnClose: true
                                }
                            }
                        }
                    }
                }
            }
        }
        
        Component {
            id: mainStatusExpandedComponent

            ColumnLayout {
                Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 60
                spacing:                margins / 2

                property real margins: ScreenTools.defaultFontPixelHeight

                Loader {
                    Layout.fillWidth:   true
                    source:             _activeVehicle.expandedToolbarIndicatorSource("MainStatus")
                }

                SettingsGroupLayout {
                    Layout.fillWidth:   true
                    heading:            qsTr("Force Arm")
                    headingDescription: qsTr("Force arming bypasses pre-arm checks. Use with caution.")
                    visible:            _activeVehicle && !_armed

                    QGCCheckBoxSlider {
                        Layout.fillWidth:   true
                        text:               qsTr("Allow Force Arm")
                        checked:            false
                        onClicked:          _allowForceArm = true
                    }
                }

                SettingsGroupLayout {
                    Layout.fillWidth:   true
                    visible:            QGroundControl.corePlugin.showAdvancedUI

                    GridLayout {
                        columns:            2
                        rowSpacing:         ScreenTools.defaultFontPixelHeight / 2
                        columnSpacing:      ScreenTools.defaultFontPixelWidth *2
                        Layout.fillWidth:   true

                        QGCLabel { Layout.fillWidth: true; text: qsTr("Vehicle Parameters") }
                        QGCButton {
                            text: qsTr("Configure")
                            onClicked: {                            
                                mainWindow.showVehicleConfigParametersPage()
                                mainWindow.closeIndicatorDrawer()
                            }
                        }

                        QGCLabel { Layout.fillWidth: true; text: qsTr("Vehicle Configuration") }
                        QGCButton {
                            text: qsTr("Configure")
                            onClicked: {                            
                                mainWindow.showVehicleConfig()
                                mainWindow.closeIndicatorDrawer()
                            }
                        }
                    }
                }
            }
        }

        Component {
            id: vtolTransitionIndicatorPage

            ToolIndicatorPage {
                contentComponent: Component {
                    QGCButton {
                        text: _vtolInFWDFlight ? qsTr("Transition to Multi-Rotor") : qsTr("Transition to Fixed Wing")

                        onClicked: {
                            if (_vtolInFWDFlight) {
                                mainWindow.vtolTransitionToMRFlightRequest()
                            } else {
                                mainWindow.vtolTransitionToFwdFlightRequest()
                            }
                            mainWindow.closeIndicatorDrawer()
                        }
                    }

                    QGCLabel { Layout.fillWidth: true; text: qsTr("Vehicle Configuration") }
                    QGCButton {
                        text: qsTr("Configure")
                        onClicked: {                            
                            mainWindow.showVehicleConfig()
                            mainWindow.closeIndicatorDrawer()
                        }
                    }
                }
            }
        }
    }
}

