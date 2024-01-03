import QtQml.Models                 2.12
import QtQuick                      2.12
import QtQuick.Controls             2.15
import QtQuick.Layouts              1.11
import QtQuick.Dialogs              1.2
import QtPositioning                5.3

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.FactControls  1.0

Item {
    id:     rootItem
    width:  toolStripPanelVideo.width
    height: toolStripPanelVideo.height

    property alias maxHeight:               toolStripPanelVideo.maxHeight
    property alias maxWidth:                modesToolStrip.maxWidth
    property real  _margins:                ScreenTools.defaultFontPixelHeight / 2
    property bool  _modesPanelVisible:      modesToolStripAction.checked
    property bool  _actionsPanelVisible:    actionsToolStripAction.checked
    property bool  _selectPanelVisible:     selectToolStripAction.checked
    property bool  _actionsMapPanelVisible: mapToolsToolStripAction.checked && mapToolsToolStripAction.enabled
    property var   _activeVehicle:          QGroundControl.multiVehicleManager.activeVehicle
    property var   _gimbalController:       _activeVehicle ? _activeVehicle.gimbalController : undefined

    Connections {
            // Setting target to null makes this connection efectively disabled, dealing with qml warnings
            target: _gimbalController ? _gimbalController : null
            onShowAcquireGimbalControlPopup: {
                showAcquireGimbalControlPopup()
            }
    }

    function showAcquireGimbalControlPopup() {
        // TODO: we should mention who is currently in control
        mainWindow.showMessageDialog(
            title,
            qsTr("Do you want to take over gimbal control?"),
            StandardButton.Yes | StandardButton.Cancel,
            function() {
               _activeVehicle.gimbalController.acquireGimbalControl()
            }
        )
    }

    ToolStrip{
        id:                 toolStripPanelVideo
        model:              toolStripActionList.model
        maxHeight:          width * 5
        
        property bool panelHidden: true

        function togglePanelVisibility() {
            if (panelHidden) {
                panelHidden = false
            } else { 
                panelHidden = true
            }
        }

        ToolStripActionList {
            id: toolStripActionList
            model: [
                ToolStripAction {
                    text:               toolStripPanelVideo.panelHidden ? qsTr("MOUNT ▼") : qsTr("MOUNT ▲")
                    iconSource:         "/HA_Icons/PAYLOAD.png"
                    onTriggered:        toolStripPanelVideo.togglePanelVisibility()
                },
                ToolStripAction {
                    id:                 modesToolStripAction
                    text:               qsTr("Modes")
                    iconSource:         "/HA_Icons/MODES.png"
                    checkable:          true
                    visible:            !toolStripPanelVideo.panelHidden
                    
                    onVisibleChanged: {
                        checked = false
                    }
                },
                ToolStripAction {
                    id:                actionsToolStripAction
                    text:              qsTr("Actions")
                    iconSource:        "/HA_Icons/ACTIONS.png"
                    checkable:         true
                    visible:           !toolStripPanelVideo.panelHidden

                    onVisibleChanged: {
                        checked = false
                    }
                },
                // Change here based on control status?
                ToolStripAction {
                    text:              hasControl ? qsTr("Release C.") : qsTr("Acquuire C.")
                    iconSource:        "/HA_Icons/PAYLOAD.png"
                    checkable:         false
                    visible:           !toolStripPanelVideo.panelHidden && _activeVehicle && _gimbalController.activeGimbal
                    onTriggered:       _activeVehicle ?
                                            hasControl ? _gimbalController.releaseGimbalControl() : _gimbalController.acquireGimbalControl()
                                                : undefined

                    property var hasControl: _gimbalController && _gimbalController.activeGimbal && _gimbalController.activeGimbal.gimbalHaveControl
                },
                ToolStripAction {
                    id:                 selectToolStripAction
                    text:               qsTr("Gimbal ") + (_gimbalController && _gimbalController.activeGimbal ? _gimbalController.activeGimbal.deviceId : "")
                    iconSource:         "/HA_Icons/SELECT.png"
                    checkable:          true
                    visible:            !toolStripPanelVideo.panelHidden && _gimbalController ? _gimbalController.gimbals.count : false
                    
                    onVisibleChanged: {
                        checked = false
                    }
                }
            ]
        }
    }

    ToolStripHorizontal {
        id:        modesToolStrip
        model:     modesToolStripActionList.model
        forceImageScale11: true
        maxWidth:  height * 3
        visible:   rootItem._modesPanelVisible
        fontSize:  ScreenTools.isMobile ? ScreenTools.smallFontPointSize * 0.7 : ScreenTools.smallFontPointSize

        anchors.top:                toolStripPanelVideo.top
        anchors.right:              toolStripPanelVideo.left
        anchors.topMargin:          height
        anchors.rightMargin:        _margins

        ToolStripActionList {
            id: modesToolStripActionList
            model: [
                ToolStripAction {
                    text:               qsTr("RC target")
                    iconSource:         "/HA_Icons/PAYLOAD.png"
                    onTriggered:        _activeVehicle ? _activeVehicle.gimbalController.setGimbalRcTargeting() : undefined
                },
                ToolStripAction {
                    text:               qsTr("Yaw Lock")
                    iconSource:         "/HA_Icons/YAW_LOCK.png"
                    onTriggered:        _activeVehicle ? _activeVehicle.gimbalController.toggleGimbalYawLock(true, true) : undefined
                },
                ToolStripAction {
                    text:               qsTr("Yaw Follow")
                    iconSource:         "/HA_Icons/YAW_UNLOCK.png"
                    onTriggered:        _activeVehicle ? _activeVehicle.gimbalController.toggleGimbalYawLock(true, false) : undefined
                }
            ]
        }
    }

    ToolStripHorizontal{
        id:        actionsToolStrip
        model:     actionsToolStripActionList.model
        forceImageScale11: true
        maxWidth:  height * 5
        visible:   rootItem._actionsPanelVisible
        fontSize:  ScreenTools.isMobile ? ScreenTools.smallFontPointSize * 0.7 : ScreenTools.smallFontPointSize

        anchors.top:                toolStripPanelVideo.top
        anchors.right:              toolStripPanelVideo.left
        anchors.topMargin:          (height * 2) + (_margins / 2)
        anchors.rightMargin:        _margins

        ToolStripActionList {
            id: actionsToolStripActionList
            model: [
                ToolStripAction {
                    text:               qsTr("Retract")
                    iconSource:         "/HA_Icons/RETRACT_ON.png"
                    onTriggered:        _activeVehicle ? _activeVehicle.gimbalController.toggleGimbalRetracted(true, true) : undefined
                },
                ToolStripAction {
                    text:               qsTr("Neutral")
                    iconSource:         "/HA_Icons/NEUTRAL.png"
                    onTriggered:        _activeVehicle ? _activeVehicle.gimbalController.toggleGimbalNeutral(true, true) : undefined
                },
                ToolStripAction {
                    text:               qsTr("Tilt 90")
                    iconSource:         "/HA_Icons/CAMERA_90.png"
                    onTriggered: {
                        if (_activeVehicle) {
                            _activeVehicle.gimbalController.toggleGimbalYawLock(true, false)
                            _activeVehicle.gimbalController.sendGimbalManagerPitchYaw(-90, 0)
                        }
                    }
                },
                ToolStripAction {
                    text:               qsTr("Point Home")
                    iconSource:         "/HA_Icons/HOME.png"
                    onTriggered:        _activeVehicle ? _activeVehicle.gimbalController.setGimbalHomeTargeting() : undefined
                },
                ToolStripAction {
                    id:                 mapToolsToolStripAction
                    text:               qsTr("ROI tools")
                    iconSource:         "/HA_Icons/MAP_CLICK.png"
                    checkable:          true
                    visible:            !toolStripPanelVideo.panelHidden
                    enabled:            flightView._mainWindowIsMap

                    onVisibleChanged: {
                        if (!visible)
                            checked = false
                    }
                }
            ]  
        }
    }

    Rectangle {
        id:      gimbalMapActions
        width:   ScreenTools.defaultFontPixelWidth * 20
        height:   ScreenTools.defaultFontPixelHeight * 10
        color:   Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
        radius:  ScreenTools.defaultFontPixelWidth / 2
        visible: rootItem._actionsMapPanelVisible && rootItem._actionsPanelVisible

        anchors.right:          actionsToolStrip.right
        anchors.rightMargin:    _margins
        anchors.top:            actionsToolStrip.bottom
        anchors.topMargin:      _margins

        property var roiActive: _activeVehicle && _activeVehicle.isROIEnabled ? true : false

        onVisibleChanged: {
            getFromMapButton.checked = false
        }

        DeadMouseArea {
            anchors.fill: parent
        }

        QGCLabel {
            id: gimbalMapActionsLabel
            text: qsTr("ROI Tools")
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top:              parent.top
            anchors.margins:          _margins
            font.pointSize:           ScreenTools.smallFontPointSize
        }

        // Left grid, coordinates
        GridLayout {
            id:             gimbalMapActionsGridLeft
            anchors.top:    gimbalMapActionsLabel.bottom
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.bottom: parent.bottom
            anchors.margins:_margins

            columnSpacing:  _margins
            rowSpacing:     _margins
            columns:        2

            QGCLabel {
                text: qsTr("LAT")
                font.pointSize: ScreenTools.smallFontPointSize
                //Layout.preferredWidth: ScreenTools.smallFontPointSize * 3
                Layout.alignment:   Qt.AlignHCenter
            }
            FactTextField {
                fact:               _activeVehicle ? _activeVehicle.gimbalTargetSetLatitude : null
                font.pointSize:     ScreenTools.smallFontPointSize
                implicitHeight:     ScreenTools.defaultFontPixelHeight
                Layout.fillWidth:   true
            }

            QGCLabel {
                text: qsTr("LON")
                font.pointSize: ScreenTools.smallFontPointSize
                Layout.alignment:   Qt.AlignHCenter
            }
            FactTextField {
                fact:               _activeVehicle ? _activeVehicle.gimbalTargetSetLongitude : null
                font.pointSize:     ScreenTools.smallFontPointSize
                implicitHeight:     ScreenTools.defaultFontPixelHeight
                Layout.fillWidth:   true
            }

            QGCLabel {
                text: qsTr("ALT")
                font.pointSize: ScreenTools.smallFontPointSize
                Layout.alignment:   Qt.AlignHCenter
            }
            FactTextField {
                fact:               _activeVehicle ? _activeVehicle.gimbalTargetSetAltitude : null
                font.pointSize:     ScreenTools.smallFontPointSize
                implicitHeight:     ScreenTools.defaultFontPixelHeight
                Layout.fillWidth:   true
            }
            QGCButton {
                id:                 getFromMapButton
                text:              qsTr("Set from map")
                checkable:         true
                Layout.columnSpan: 2
                Layout.alignment:   Qt.AlignHCenter | Qt.AlignTop
                //Layout.fillWidth:  true
                pointSize:         ScreenTools.smallFontPointSize
                implicitHeight:    ScreenTools.implicitButtonHeight * 0.6
                implicitWidth:     ScreenTools.implicitButtonWidth * 2
                backRadius:        ScreenTools.defaultFontPixelWidth / 2

                onCheckedChanged: {
                    if (_activeVehicle) {
                        _activeVehicle.GimbalClickOnMapActive = checked
                    }
                }
            }
            QGCLabel {
                text:                   qsTr("ROI")
                Layout.rowSpan:     2
                font.pointSize:         ScreenTools.smallFontPointSize
                //visible:                gimbalMapActions.roiActive
                Layout.fillWidth:       true
                Layout.alignment:       Qt.AlignHCenter | Qt.AlignVCenter
            }

            QGCButton {
                text:               qsTr("ROI Activation")
                Layout.alignment:   Qt.AlignHCenter | Qt.AlignTop
                checkable:          false
                backRadius:         ScreenTools.defaultFontPixelWidth / 2
                pointSize:          ScreenTools.smallFontPointSize
                implicitHeight:     ScreenTools.implicitButtonHeight * 0.6
                implicitWidth:     ScreenTools.implicitButtonWidth * 2

                onClicked: {
                    var coordinate = QtPositioning.coordinate(_activeVehicle.gimbalTargetSetLatitude.rawValue, _activeVehicle.gimbalTargetSetLongitude.rawValue, _activeVehicle.gimbalTargetSetAltitude.rawValue)
                    _activeVehicle.guidedModeROI(coordinate)
                }
            }

            QGCButton {
                text:             qsTr("Cancel")
                //visible:          gimbalMapActions.roiActive
                Layout.alignment:   Qt.AlignHCenter | Qt.AlignTop
                pointSize:        ScreenTools.smallFontPointSize
                implicitHeight:   ScreenTools.implicitButtonHeight * 0.6
                implicitWidth:     ScreenTools.implicitButtonWidth * 2
                backRadius:       ScreenTools.defaultFontPixelWidth / 2
                enabled:           gimbalMapActions.roiActive

                onPressed: {
                    if (_activeVehicle) {
                        _activeVehicle.stopGuidedModeROI()
                    }
                }
            }
        }
    }

    Rectangle {
        id:        gimbalSelectorPanel
        width:     toolStripPanelVideo.width
        height:    panelHeight
        visible:   rootItem._selectPanelVisible
        color:     qgcPal.windowShade
        radius:    ScreenTools.defaultFontPixelWidth / 2

        anchors.bottom:             toolStripPanelVideo.bottom
        anchors.right:              toolStripPanelVideo.left
        anchors.rightMargin:        _margins

        property real buttonWidth:    width - _margins * 2
        property real panelHeight:    gimbalSelectorContentGrid.childrenRect.height + _margins * 2
        property real gridRowSpacing: _margins
        property real buttonFontSize: ScreenTools.smallFontPointSize * 0.9

        GridLayout {
            id:               gimbalSelectorContentGrid
            width:            parent.width
            rowSpacing:       gimbalSelectorPanel.gridRowSpacing
            columns:          1

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top:              parent.top
            anchors.topMargin:        _margins

            Repeater {
                model: _gimbalController && _gimbalController.gimbals ? _gimbalController.gimbals : undefined
                delegate: FakeToolStripHoverButton {
                    Layout.preferredWidth:  gimbalSelectorPanel.buttonWidth
                    Layout.preferredHeight: Layout.preferredWidth
                    Layout.alignment:       Qt.AlignHCenter | Qt.AlignVCenter
                    text:                   qsTr("Gimbal ") + object.deviceId
                    fontPointSize:          gimbalSelectorPanel.buttonFontSize
                    onClicked: {
                        _gimbalController.activeGimbal = object
                    }
                }
            }
        }
    }
}
