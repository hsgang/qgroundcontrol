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

import QGroundControl
import QGroundControl.Controls
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.FactSystem

Rectangle {
    id:             control
    width:          marqueeRowLayout.width + _margins
    height:         parent.height
    color:          _mainStatusBGColor //"transparent" //Qt.rgba(_mainStatusBGColor.r, _mainStatusBGColor.g, _mainStatusBGColor.b, 0.7)
    //border.color:   _mainStatusBGColor //Qt.rgba(_mainStatusBGColor.r, _mainStatusBGColor.g, _mainStatusBGColor.b, 0.2)
    //border.width:   _margins / 8
    radius:         _margins / 4

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property var    _vehicleInAir:      _activeVehicle ? _activeVehicle.flying || _activeVehicle.landing : false
    property bool   _vtolInFWDFlight:   _activeVehicle ? _activeVehicle.vtolInFwdFlight : false
    property bool   _armed:             _activeVehicle ? _activeVehicle.armed : false
    property real   _margins:           ScreenTools.defaultFontPixelHeight
    property real   _spacing:           ScreenTools.defaultFontPixelHeight / 2
    property bool   _healthAndArmingChecksSupported: _activeVehicle ? _activeVehicle.healthAndArmingCheckReport.supported : false

    RowLayout {
        id:         marqueeRowLayout
        spacing:                    0
        anchors.horizontalCenter:   parent.horizontalCenter
        anchors.verticalCenter:     parent.verticalCenter

        QGCMarqueeLabel {
            id:             mainStatusLabel
            text:           mainStatusText()
            font.pointSize: ScreenTools.largeFontPointSize
            //implicitWidth:  maxWidth
            maxWidth:       ScreenTools.defaultFontPixelWidth * ScreenTools.largeFontPointRatio * 16

            property string _commLostText:      qsTr("Communication Lost")
            property string _readyToFlyText:    qsTr("Ready To Fly")
            property string _notReadyToFlyText: qsTr("Not Ready")
            property string _disconnectedText:  qsTr("Disconnected - Click to manually connect")
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
                                    _mainStatusBGColor = "orange"
                                }
                            } else {
                                _mainStatusBGColor = "red"
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
                                    _mainStatusBGColor = "orange"
                                } else {
                                    _mainStatusBGColor = "green"
                                }
                                return mainStatusLabel._readyToFlyText
                            } else {
                                _mainStatusBGColor = "red"
                                return mainStatusLabel._notReadyToFlyText
                            }
                        } else if (_activeVehicle.readyToFlyAvailable) {
                            if (_activeVehicle.readyToFly) {
                                _mainStatusBGColor = qgcPal.colorGreen
                                return mainStatusLabel._readyToFlyText
                            } else {
                                _mainStatusBGColor = "orange"
                                return mainStatusLabel._notReadyToFlyText
                            }
                        } else {
                            // Best we can do is determine readiness based on AutoPilot component setup and health indicators from SYS_STATUS
                            if (_activeVehicle.allSensorsHealthy && _activeVehicle.autopilot.setupComplete) {
                                _mainStatusBGColor = qgcPal.colorGreen
                                return mainStatusLabel._readyToFlyText
                            } else {
                                _mainStatusBGColor = "orange"
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
                height:                 marqueeRowLayout.height
                onClicked:              mainWindow.showIndicatorDrawer(overallStatusComponent)

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
                onClicked:      mainWindow.showIndicatorDrawer(vtolTransitionIndicatorPage)
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
                                        color:        object.severity == 'error' ? qgcPal.colorRed : object.severity == 'warning' ? qgcPal.colorOrange : qgcPal.text
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
                            drawer.close()
                        }
                    }
                }
            }
        }
    }
}

