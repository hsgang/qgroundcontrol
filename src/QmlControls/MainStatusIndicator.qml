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
    color:          "transparent"//_mainStatusBGColor
    radius:         ScreenTools.defaultFontPixelHeight / 4
    border.color:   _mainStatusBGColor
    border.width:   2
    // gradient: Gradient {
    //     orientation: Gradient.Horizontal
    //     GradientStop { position: 0;     color: _mainStatusBGColor }
    //     //GradientStop { position: 0.7;   color: _mainStatusBGColor }
    //     GradientStop { position: 1;     color: _root.color }
    // }
    // radius:         _margins / 4

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property var    _vehicleInAir:      _activeVehicle ? _activeVehicle.flying || _activeVehicle.landing : false
    property bool   _vtolInFWDFlight:   _activeVehicle ? _activeVehicle.vtolInFwdFlight : false
    property bool   _armed:             _activeVehicle ? _activeVehicle.armed : false
    property real   _margins:           ScreenTools.defaultFontPixelHeight
    property real   _spacing:           ScreenTools.defaultFontPixelHeight / 2
    property bool   _healthAndArmingChecksSupported: _activeVehicle ? _activeVehicle.healthAndArmingCheckReport.supported : false

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

            property string _commLostText:      qsTr("Communication Lost")
            property string _readyToFlyText:    qsTr("Ready To Fly")
            property string _notReadyToFlyText: qsTr("Not Ready")
            property string _disconnectedText:  qsTr("Disconnected")
            property string _armedText:         qsTr("Armed")
            property string _flyingText:        qsTr("Flying")
            property string _landingText:       qsTr("Landing")
            property string _parametersSynchronizingText:    qsTr("Parameters Synchronizing")

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
                anchors.left:           parent.left
                anchors.right:          parent.right
                anchors.verticalCenter: parent.verticalCenter
                height:                 rowLayout.height
                onClicked:              mainWindow.showIndicatorDrawer(overallStatusComponent, control)

                property Component overallStatusComponent: _activeVehicle ? overallStatusIndicatorPage : overallStatusOfflineIndicatorPage
            }
        }

        Item {
            visible:                vtolModeLabel.visible
            implicitWidth:  ScreenTools.defaultFontPixelWidth * ScreenTools.largeFontPointRatio * 1.5
            implicitHeight: 1
        }

        QGCLabel {
            id:                     vtolModeLabel
            Layout.alignment:       Qt.AlignVCenter
            text:                   _vtolInFWDFlight ? qsTr("FW(vtol)") : qsTr("MR(vtol)")
            font.pointSize:         enabled ? ScreenTools.largeFontPointSize : ScreenTools.defaultFontPointSize
            Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * ScreenTools.largeFontPointRatio * text.length
            visible:                _activeVehicle && _activeVehicle.vtol
            enabled:                _activeVehicle && _activeVehicle.vtol && _vehicleInAir

            QGCMouseArea {
                anchors.fill:   parent
                onClicked:      mainWindow.showIndicatorDrawer(vtolTransitionIndicatorPage, control)
            }
        }

        Component {
            id: overallStatusOfflineIndicatorPage

            MainStatusIndicatorOfflinePage {

            }
        }

        Component {
            id: overallStatusIndicatorPage

            ToolIndicatorPage {
                showExpand: _activeVehicle.mainStatusIndicatorExpandedItem ? true : false

                contentComponent: Component {
                    Column {
                        id:         mainLayout
                        spacing:    _spacing

                        QGCButton {
                            // FIXME: forceArm is not possible anymore if _healthAndArmingChecksSupported == true
                            enabled:            _armed || !_healthAndArmingChecksSupported || _activeVehicle.healthAndArmingCheckReport.canArm
                            text:               _armed ?  qsTr("Disarm") : (forceArm ? qsTr("Force Arm") : qsTr("Arm"))
                            Layout.alignment:   Qt.AlignLeft

                            property bool forceArm: false

                            onPressAndHold: forceArm = true

                            onClicked: {
                                if (_armed) {
                                    mainWindow.disarmVehicleRequest()
                                } else {
                                    if (forceArm) {
                                        mainWindow.forceArmVehicleRequest()
                                    } else {
                                        mainWindow.armVehicleRequest()
                                    }
                                }
                                forceArm = false
                                mainWindow.closeIndicatorDrawer()
                            }
                        }

                        QGCLabel {
                            anchors.horizontalCenter:   parent.horizontalCenter
                            text:                       qsTr("Sensor Status")
                            visible:                    !_healthAndArmingChecksSupported
                        }

                        GridLayout {
                            rowSpacing:     _spacing
                            columnSpacing:  _spacing
                            rows:           _activeVehicle.sysStatusSensorInfo.sensorNames.length
                            flow:           GridLayout.TopToBottom
                            visible:        !_healthAndArmingChecksSupported

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

                        QGCLabel {
                            text:       qsTr("Overall Status")
                            visible:    _healthAndArmingChecksSupported && _activeVehicle.healthAndArmingCheckReport.problemsForCurrentMode.count > 0
                        }
                        // List health and arming checks
                        Repeater {
                            visible:    _healthAndArmingChecksSupported
                            model:      _activeVehicle ? _activeVehicle.healthAndArmingCheckReport.problemsForCurrentMode : null
                            delegate:   listdelegate
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
            }
        }

        // Component {
        //     id: vtolTransitionIndicatorPage

        //     ToolIndicatorPage {
        //         contentComponent: Component {
        //             QGCButton {
        //                 text: qsTr("Configure")
        //                 onClicked: {
        //                     mainWindow.showVehicleConfigParametersPage()
        //                     mainWindow.closeIndicatorDrawer()
        //                 }
        //             }

        //             QGCLabel { Layout.fillWidth: true; text: qsTr("Vehicle Configuration") }
        //             QGCButton {
        //                 text: qsTr("Configure")
        //                 onClicked: {
        //                     mainWindow.showVehicleConfig()
        //                     mainWindow.closeIndicatorDrawer()
        //                 }
        //             }
        //         }
        //     }
        // }
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
            }
        }
    }
}

