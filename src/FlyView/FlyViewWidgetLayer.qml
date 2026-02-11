import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QtLocation
import QtPositioning
import QtQuick.Window
import QtQml.Models

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView
import QGroundControl.FlightMap

// This is the ui overlay layer for the widgets/tools for Fly View
Item {
    id: _root

    property var    parentToolInsets
    property var    totalToolInsets:        _totalToolInsets
    property var    mapControl
    property bool   isViewer3DOpen:         false

    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property var    _planMasterController:  globals.planMasterControllerFlyView
    property var    _missionController:     _planMasterController.missionController
    property var    _geoFenceController:    _planMasterController.geoFenceController
    property var    _rallyPointController:  _planMasterController.rallyPointController
    property var    _guidedController:      globals.guidedControllerFlyView
    property real   _margins:               ScreenTools.defaultFontPixelWidth / 2
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property rect   _centerViewport:        Qt.rect(0, 0, width, height)
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30
    property real   _layoutMargin:          ScreenTools.defaultFontPixelWidth * 0.75
    property bool   _layoutSpacing:         ScreenTools.defaultFontPixelWidth
    property bool   _showSingleVehicleUI:   true

    property var _siyi: QGroundControl.siyi
    property SiYiCamera camera: _siyi.camera

    QGCToolInsets {
        id:                     _totalToolInsets
        leftEdgeTopInset:       toolStrip.leftEdgeTopInset
        leftEdgeCenterInset:    toolStrip.leftEdgeCenterInset
        leftEdgeBottomInset:    virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.leftEdgeBottomInset : parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      topRightPanel.rightEdgeTopInset
        rightEdgeCenterInset:   topRightPanel.rightEdgeCenterInset
        rightEdgeBottomInset:   bottomRightRowLayout.rightEdgeBottomInset
        topEdgeLeftInset:       toolStrip.topEdgeLeftInset
        topEdgeCenterInset:     flyviewMissionProgress.topEdgeCenterInset
        topEdgeRightInset:      topRightPanel.topEdgeRightInset
        bottomEdgeLeftInset:    virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeLeftInset : parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  parentToolInsets.bottomEdgeCenterInset
        bottomEdgeRightInset:   virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeRightInset : bottomRightRowLayout.bottomEdgeRightInset
    }

    FlyViewTopRightPanel {
        id:                     topRightPanel
        anchors.top:            parent.top
        anchors.bottom:         bottomRightRowLayout.top
        anchors.right:          parent.right
        maximumHeight:          parent.height - (bottomRightRowLayout.height + _margins * 4)

        property real topEdgeRightInset:    height + _layoutMargin
        property real rightEdgeTopInset:    width + _layoutMargin
        property real rightEdgeCenterInset: rightEdgeTopInset
    }

    FlyViewTopRightColumnLayout {
        id:                 topRightColumnLayout
        anchors.top:        parent.top
        anchors.right:      parent.right
        spacing:            _layoutSpacing
        visible:            !topRightPanel.visible

        property real topEdgeRightInset:    childrenRect.height + _layoutMargin
        property real rightEdgeTopInset:    width + _layoutMargin
        property real rightEdgeCenterInset: rightEdgeTopInset
    }

    FlyViewRightPanel {
        id:                 rightPanel
        anchors.top:        topRightColumnLayout.bottom
        anchors.bottom:     bottomRightRowLayout.top
        anchors.right:      parent.right
    }

    FlyViewBottomRightRowLayout {
        id:                 bottomRightRowLayout
        anchors.bottom:     parent.bottom
        anchors.right:      parent.right
        spacing:            _layoutSpacing

        property real bottomEdgeRightInset:     height + _layoutMargin * 3
        //property real bottomEdgeCenterInset:    bottomEdgeRightInset
        property real rightEdgeBottomInset:     width + _layoutMargin
    }

    // FlyViewBottomCenterRowLayout {
    //     id:                 bottomCenterRowLayout
    //     anchors.bottomMargin:       _layoutMargin * 3
    //     anchors.bottom:             parent.bottom
    //     anchors.horizontalCenter:   parent.horizontalCenter
    //     spacing:                    _layoutSpacing

    //     property real bottomEdgeCenterInset:    height + (_layoutMargin * 2)
    // }

    // TelemetryValuesBar {
    //     id:                 telemetryPanel
    //     x:                  recalcXPosition()
    //     anchors.margins:    _toolsMargin
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     anchors.top:        parent.top //guidedActionConfirm.visible ? guidedActionConfirm.bottom : parent.top
    //     visible:            QGroundControl.settingsManager.flyViewSettings.showTelemetryPanel.rawValue

    //     property real topEdgeCenterInset: visible ? y + height : 0

    //     function recalcXPosition() {
    //         // First try centered
    //         var halfRootWidth   = _root.width / 2
    //         var halfPanelWidth  = telemetryPanel.width / 2
    //         var leftX           = (halfRootWidth - halfPanelWidth) - _toolsMargin
    //         var rightX          = (halfRootWidth + halfPanelWidth) + _toolsMargin
    //         if (leftX >= parentToolInsets.leftEdgeTopInset || rightX <= parentToolInsets.rightEdgeTopInset ) {
    //             // It will fit in the horizontalCenter
    //             return halfRootWidth - halfPanelWidth
    //         } else {
    //             // Anchor to left edge
    //             return parentToolInsets.leftEdgeTopInset + _toolsMargin
    //         }
    //     }
    // }

    FlyViewMissionCompleteDialog {
        missionController:      _missionController
        geoFenceController:     _geoFenceController
        rallyPointController:   _rallyPointController
    }

    RequestConfirmPopup {
        id:                         requestConfirmPopup
        anchors.margins:            _toolsMargin * 2
        anchors.top:                parent.top //telemetryPanel.visible ? telemetryPanel.bottom : parent.top
        anchors.horizontalCenter:   parent.horizontalCenter
        z:                          QGroundControl.zOrderTopMost
    }

    //-- Virtual Joystick
    Loader {
        id:                         virtualJoystickMultiTouch
        z:                          QGroundControl.zOrderTopMost + 1
        anchors.right:              parent.right
        anchors.rightMargin:        anchors.leftMargin
        height:                     Math.min(parent.height * 0.25, ScreenTools.defaultFontPixelWidth * 16)
        visible:                    _virtualJoystickEnabled && !QGroundControl.videoManager.fullScreen && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)
        anchors.bottom:             parent.bottom
        anchors.bottomMargin:       bottomLoaderMargin
        anchors.left:               parent.left
        anchors.leftMargin:         ( y > toolStrip.y + toolStrip.height ? toolStrip.width / 2 : toolStrip.width * 1.05 + toolStrip.x)
        source:                     "qrc:/qml/QGroundControl/FlyView/VirtualJoystick.qml"
        active:                     _virtualJoystickEnabled && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)

        property real bottomEdgeLeftInset:     parent.height-y
        property bool autoCenterThrottle:      QGroundControl.settingsManager.appSettings.virtualJoystickAutoCenterThrottle.rawValue
        property bool leftHandedMode:          QGroundControl.settingsManager.appSettings.virtualJoystickLeftHandedMode.rawValue
        property bool _virtualJoystickEnabled: QGroundControl.settingsManager.appSettings.virtualJoystick.rawValue
        property real bottomEdgeRightInset:    parent.height-y
        property var  _pipViewMargin:          _pipView.visible ? parentToolInsets.bottomEdgeLeftInset + ScreenTools.defaultFontPixelHeight * 2 :
                                               bottomRightRowLayout.height + ScreenTools.defaultFontPixelHeight * 1.5

        property var  bottomLoaderMargin:      _pipViewMargin >= parent.height / 2 ? parent.height / 2 : _pipViewMargin

        // Width is difficult to access directly hence this hack which may not work in all circumstances
        property real leftEdgeBottomInset:  visible ? bottomEdgeLeftInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0
        property real rightEdgeBottomInset: visible ? bottomEdgeRightInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0
        property real rootWidth:            _root.width
        property var  itemX:                virtualJoystickMultiTouch.x   // real X on screen

        onRootWidthChanged: virtualJoystickMultiTouch.status == Loader.Ready && visible ? virtualJoystickMultiTouch.item.uiTotalWidth = rootWidth : undefined
        onItemXChanged:     virtualJoystickMultiTouch.status == Loader.Ready && visible ? virtualJoystickMultiTouch.item.uiRealX = itemX : undefined

        //Loader status logic
        onLoaded: {
            if (virtualJoystickMultiTouch.visible) {
                virtualJoystickMultiTouch.item.calibration = true
                virtualJoystickMultiTouch.item.uiTotalWidth = rootWidth
                virtualJoystickMultiTouch.item.uiRealX = itemX
            } else {
                virtualJoystickMultiTouch.item.calibration = false
            }
        }
    }

    FlyViewToolStrip {
        id:                     toolStrip
        anchors.left:           parent.left
        anchors.top:            parent.top
        z:                      QGroundControl.zOrderWidgets
        maxHeight:              parent.height - y - parentToolInsets.bottomEdgeLeftInset - _toolsMargin
        visible:                !QGroundControl.videoManager.fullScreen

        onDisplayPreFlightChecklist: {
            if (!preFlightChecklistLoader.active) {
                preFlightChecklistLoader.active = true
            }
            preFlightChecklistLoader.item.open()
        }

        property real topEdgeLeftInset:     visible ? y + height : 0
        property real leftEdgeTopInset:     visible ? x + width : 0
        property real leftEdgeCenterInset:  leftEdgeTopInset
    }

    VehicleWarnings {
        anchors.centerIn:   parent
        z:                  QGroundControl.zOrderTopMost
    }

    MapScale {
        id:                 mapScale
        anchors.bottomMargin: _toolsMargin //_pipView.visible ? _totalToolInsets.bottomEdgeLeftInset + _toolsMargin : _toolsMargin
        anchors.bottom:     parent.bottom
        anchors.leftMargin: _totalToolInsets.leftEdgeBottomInset + _toolsMargin
        anchors.left:       parent.left
        mapControl:         _mapControl
        autoHide:           true
        visible:            !ScreenTools.isTinyScreen && QGroundControl.corePlugin.options.flyView.showMapScale && !isViewer3DOpen && mapControl.pipState.state === mapControl.pipState.fullState

        property real topEdgeCenterInset: visible ? y + height : 0
    }

    Loader {
        id: preFlightChecklistLoader
        sourceComponent: preFlightChecklistPopup
        active: false
    }

    Component {
        id: preFlightChecklistPopup
        FlyViewPreFlightChecklistPopup {
        }
    }

    GuidedActionConfirm {
        id:                         guidedActionConfirm
        height:                     ScreenTools.defaultFontPixelHeight * 2
        anchors.top:                parent.top
        anchors.horizontalCenter:   parent.horizontalCenter
        guidedController:           _guidedController
        guidedValueSlider:          guidedValueSlider
        messageDisplay:             undefined
    }

    // GuidedActionPressHoldConfirm{
    //     Layout.fillWidth:   true
    //     z:                  QGroundControl.zOrderTopMost
    //     anchors.verticalCenter: parent.verticalCenter
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     guidedController:   _guidedController
    //     guidedValueSlider:  _guidedValueSlider
    // }

    Rectangle {
        id:                         flyviewStatusRect
        anchors.horizontalCenter:   parent.horizontalCenter
        anchors.bottom:             bottomRightRowLayout.top
        anchors.bottomMargin:       _toolsMargin
        color:                      "transparent"
        width:                      flyviewStatusRow.width
        height:                     flyviewStatusRow.height

        RowLayout{
            id: flyviewStatusRow

            FlyViewVibrationStatus{
                id:         flyviewVibrationStatus
                visible:    QGroundControl.settingsManager.flyViewSettings.showVibrationStatus.rawValue
            }

            FlyViewEKFStatus{
                id:         flyviewEKFStatus
                visible:    QGroundControl.settingsManager.flyViewSettings.showEKFStatus.rawValue
            }
        }
    }

    // FlyViewAtmosphericSensorView{
    //     id:                         atmosphericSensorView
    //     anchors.top:                parent.top
    //     anchors.topMargin:          _toolsMargin
    //     anchors.left:               toolStrip.right
    //     anchors.leftMargin:         _toolsMargin
    //     visible:                    QGroundControl.settingsManager.flyViewSettings.showAtmosphericValueBar.rawValue && mapControl.pipState.state === mapControl.pipState.pipState
    // }

    // FlyViewWindvane {
    //     id:                         windvane
    //     vehicle:                    _activeVehicle
    //     anchors.top:                parent.top
    //     anchors.topMargin:          _toolsMargin
    //     anchors.left:               toolStrip.right
    //     anchors.leftMargin:         _toolsMargin
    //     //anchors.leftMargin:         (ScreenTools.isMobile ? ScreenTools.minTouchPixels : ScreenTools.defaultFontPixelWidth * 8) + _toolsMargin * 2
    //     visible:                    QGroundControl.settingsManager.flyViewSettings.showWindvane.rawValue
    // }

    ModeChangedIndicator {
        anchors.centerIn:   parent
        z:                  QGroundControl.zOrderTopMost
    }

    Rectangle {
        id:                 messageToastManagerRect
        anchors.margins:    _toolsMargin * 3
        anchors.top:        parent.top
        anchors.left:       toolStrip.right
        width:              ScreenTools.isMobile ? parent.width / 2 : parent.width / 4
        height:             parent.height / 2
        color:              "transparent"

        MessageToastManager {
            id:                 messageToastManager

            Connections {
                target: _activeVehicle
                function onNewFormattedMessage(formattedMessage) {
                    messageToastManager.show(formattedMessage, 5000)
                }
            }
        }
    }

    FlyViewAtmosphericChart{
        id: flyViewChartWidget
        anchors.margins:        _toolsMargin
        anchors.top:            parent.top //telemetryPanel.visible ? telemetryPanel.bottom : parent.top
        anchors.bottom:         bottomRightRowLayout.top
        anchors.right:          rightPanel.left
        width:                  ScreenTools.isMobile ? mainWindow.width * 0.7 : mainWindow.width * 0.4
        visible:                QGroundControl.settingsManager.flyViewSettings.showChartWidget.rawValue
    }

    // FlyViewEscStatus {
    //     id: flyViewEscStatus
    //     anchors.margins:        _toolsMargin
    //     anchors.top:            parent.top
    //     anchors.topMargin:      _toolsMargin
    //     anchors.right:          rightPanel.left
    //     visible:                QGroundControl.settingsManager.flyViewSettings.showEscStatus.rawValue
    // }

    FlyViewMissionProgress{
        id:                     flyviewMissionProgress
        anchors.margins:        _toolsMargin
        anchors.top:            parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        _planMasterController: planController
        visible:  QGroundControl.settingsManager.flyViewSettings.showMissionProgress.rawValue

        property real topEdgeCenterInset: visible ? height+_toolsMargin : 0
    }

    Rectangle {
        id: siyiResultRectangle
        anchors.top: parent.top //telemetryPanel.visible ? telemetryPanel.bottom : parent.top
        width: resultLabel.width + resultLabel.width*0.4
        height: resultLabel.height + resultLabel.height*0.4
        anchors.margins: _toolsMargin
        anchors.horizontalCenter: parent.horizontalCenter //telemetryPanel.visible ? telemetryPanel.horizontalCenter : parent.horizontalCenter
        color:  Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5)
        visible: false
        radius: _toolsMargin / 2
        QGCLabel {
            id: resultLabel
            anchors.centerIn: parent
            color: qgcPal.text

            Timer {
                id: resultTimer
                interval: 5000
                running: false
                repeat: false
                onTriggered: siyiResultRectangle.visible = false
            }

            Connections {
                target: camera
                function onOperationResultChanged(result) {
                    if (result === 0) {
                        resultLabel.text = qsTr("Take Photo Success")
                    } else if (result === 1) {
                        resultLabel.text = qsTr("Take Photo Failed")
                    } else if (result === 4) {
                        resultLabel.text = qsTr("Video Record Failed")
                    } else if (result === -1) {
                        resultLabel.text = qsTr("Not supportted") //4K视频不支持变倍
                    } else if (result === camera.TipOptionLaserNotInRange) {
                        resultLabel.text = qsTr("Not in the range of laser")
                    } else if (result === camera.TipOptionSettingOK) {
                        resultLabel.text = qsTr("Setting OK")
                    } else if (result === camera.TipOptionSettingFailed) {
                        resultLabel.text = qsTr("Setting Failed")
                    } else if (result === camera.TipOptionIsNotAiTrackingMode) {
                        resultLabel.text = qsTr("Not in AI tracking mode") // 不支持AI跟踪模式
                    } else if (result === camera.TipOptionStreamNotSupportedAiTracking) {
                        resultLabel.text = qsTr("AI tracking not supportted") //AI跟踪不支持
                    }

                    resultTimer.restart()
                    zoomMultipleRectangle.visible = false
                    siyiResultRectangle.visible = true
                }
            }
        }
    }
}
