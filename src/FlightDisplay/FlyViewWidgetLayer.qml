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

import QtLocation
import QtPositioning
import QtQuick.Window
import QtQml.Models

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Controllers
import QGroundControl.FactSystem
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.Vehicle

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
    property alias  _gripperMenu:           gripperOptions
    property real   _layoutMargin:          ScreenTools.defaultFontPixelWidth * 0.75
    property bool   _layoutSpacing:         ScreenTools.defaultFontPixelWidth
    property bool   _showSingleVehicleUI:   true

    property bool utmspActTrigger

    QGCToolInsets {
        id:                     _totalToolInsets
        leftEdgeTopInset:       toolStrip.leftEdgeTopInset
        leftEdgeCenterInset:    toolStrip.leftEdgeCenterInset
        leftEdgeBottomInset:    virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.leftEdgeBottomInset : parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      topRightColumnLayout.rightEdgeTopInset
        rightEdgeCenterInset:   topRightColumnLayout.rightEdgeCenterInset
        rightEdgeBottomInset:   bottomRightRowLayout.rightEdgeBottomInset
        topEdgeLeftInset:       toolStrip.topEdgeLeftInset
        topEdgeCenterInset:     parentToolInsets.topEdgeCenterInset
        topEdgeRightInset:      topRightColumnLayout.topEdgeRightInset
        bottomEdgeLeftInset:    virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeLeftInset : parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  bottomCenterRowLayout.bottomEdgeCenterInset
        bottomEdgeRightInset:   virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeRightInset : bottomRightRowLayout.bottomEdgeRightInset
    }

    FlyViewTopRightColumnLayout {
        id:                 topRightColumnLayout
        anchors.margins:    _layoutMargin
        anchors.top:        parent.top
        anchors.bottom:     bottomRightRowLayout.top
        anchors.right:      parent.right
        spacing:            _layoutSpacing

        property real topEdgeRightInset:    childrenRect.height + _layoutMargin
        property real rightEdgeTopInset:    width + _layoutMargin
        property real rightEdgeCenterInset: rightEdgeTopInset
    }

    FlyViewBottomRightRowLayout {
        id:                 bottomRightRowLayout
        anchors.margins:    _layoutMargin
        anchors.bottom:     parent.bottom
        anchors.right:      parent.right
        spacing:            _layoutSpacing

        property real bottomEdgeRightInset:     height + _layoutMargin
        //property real bottomEdgeCenterInset:    bottomEdgeRightInset
        property real rightEdgeBottomInset:     width + _layoutMargin
    }

    FlyViewBottomCenterRowLayout {
        id:                 bottomCenterRowLayout
        anchors.bottomMargin:       _layoutMargin * 3
        anchors.bottom:             parent.bottom
        anchors.horizontalCenter:   parent.horizontalCenter
        spacing:                    _layoutSpacing

        property real bottomEdgeCenterInset:    height + (_layoutMargin * 2)
    }

    TelemetryValuesBar {
        id:                 telemetryPanel
        x:                  recalcXPosition()
        anchors.margins:    _toolsMargin
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top:        guidedActionConfirm.visible ? guidedActionConfirm.bottom : parent.top
        visible:            QGroundControl.settingsManager.flyViewSettings.showTelemetryPanel.rawValue

        property real topEdgeCenterInset: visible ? y + height : 0

        function recalcXPosition() {
            // First try centered
            var halfRootWidth   = _root.width / 2
            var halfPanelWidth  = telemetryPanel.width / 2
            var leftX           = (halfRootWidth - halfPanelWidth) - _toolsMargin
            var rightX          = (halfRootWidth + halfPanelWidth) + _toolsMargin
            if (leftX >= parentToolInsets.leftEdgeTopInset || rightX <= parentToolInsets.rightEdgeTopInset ) {
                // It will fit in the horizontalCenter
                return halfRootWidth - halfPanelWidth
            } else {
                // Anchor to left edge
                return parentToolInsets.leftEdgeTopInset + _toolsMargin
            }
        }
    }

    FlyViewMissionCompleteDialog {
        missionController:      _missionController
        geoFenceController:     _geoFenceController
        rallyPointController:   _rallyPointController
    }

    GuidedActionConfirm {
        id:                         guidedActionConfirm
        anchors.margins:            _toolsMargin
        anchors.top:                parent.top
        anchors.horizontalCenter:   parent.horizontalCenter
        z:                          QGroundControl.zOrderTopMost
        guidedController:           _guidedController
        guidedValueSlider:          _guidedValueSlider
        utmspSliderTrigger:         utmspActTrigger
    }

    //-- Virtual Joystick
    Loader {
        id:                         virtualJoystickMultiTouch
        z:                          QGroundControl.zOrderTopMost + 1
        width:                      parent.width  - (_pipView.width / 2)
        height:                     Math.min(parent.height * 0.25, ScreenTools.defaultFontPixelWidth * 16)
        visible:                    _virtualJoystickEnabled && !QGroundControl.videoManager.fullScreen && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)
        anchors.bottom:             parent.bottom
        anchors.bottomMargin:       parentToolInsets.leftEdgeBottomInset + ScreenTools.defaultFontPixelHeight * 2
        anchors.horizontalCenter:   parent.horizontalCenter
        source:                     "qrc:/qml/VirtualJoystick.qml"
        active:                     _virtualJoystickEnabled && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)

        property bool autoCenterThrottle: QGroundControl.settingsManager.appSettings.virtualJoystickAutoCenterThrottle.rawValue

        property bool _virtualJoystickEnabled: QGroundControl.settingsManager.appSettings.virtualJoystick.rawValue

        property real bottomEdgeLeftInset: parent.height-y
        property real bottomEdgeRightInset: parent.height-y

        // Width is difficult to access directly hence this hack which may not work in all circumstances
        property real leftEdgeBottomInset: visible ? bottomEdgeLeftInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0
        property real rightEdgeBottomInset: visible ? bottomEdgeRightInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0
    }

    FlyViewToolStrip {
        id:                     toolStrip
        anchors.leftMargin:     _toolsMargin + parentToolInsets.leftEdgeCenterInset
        anchors.topMargin:      _toolsMargin + parentToolInsets.topEdgeLeftInset
        anchors.left:           parent.left
        anchors.top:            parent.top
        z:                      QGroundControl.zOrderWidgets
        maxHeight:              parent.height - y - parentToolInsets.bottomEdgeLeftInset - _toolsMargin
        visible:                !QGroundControl.videoManager.fullScreen

        onDisplayPreFlightChecklist: preFlightChecklistPopup.createObject(mainWindow).open()


        property real topEdgeLeftInset:     visible ? y + height : 0
        property real leftEdgeTopInset:     visible ? x + width : 0
        property real leftEdgeCenterInset:  leftEdgeTopInset
    }

    GripperMenu {
        id: gripperOptions
    }
    
//    VehicleWarnings {
//        anchors.centerIn:   parent
//        z:                  QGroundControl.zOrderTopMost
//    }

    MapScale {
        id:                 mapScale
        anchors.margins:    _toolsMargin
        anchors.right:      parent.right
        anchors.bottom:     parent.bottom
        mapControl:         _mapControl
        buttonsOnLeft:      true
        visible:            !ScreenTools.isTinyScreen && QGroundControl.corePlugin.options.flyView.showMapScale && !isViewer3DOpen && mapControl.pipState.state === mapControl.pipState.fullState

        property real topEdgeCenterInset: visible ? y + height : 0
    }

    Component {
        id: preFlightChecklistPopup
        FlyViewPreFlightChecklistPopup {
        }
    }

    // GuidedActionPressHoldConfirm{
    //     Layout.fillWidth:   true
    //     z:                  QGroundControl.zOrderTopMost
    //     anchors.verticalCenter: parent.verticalCenter
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     guidedController:   _guidedController
    //     guidedValueSlider:  _guidedValueSlider
    //     utmspSliderTrigger:          utmspActTrigger
    // }

//    PowerEstimatedIndicator{
//        id:                         powerEstimatedIndicator

//    }

    Rectangle {
        id:                         flyviewStatusRect
        anchors.horizontalCenter:   parent.horizontalCenter
        anchors.bottom:             bottomCenterRowLayout.top
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

    // FlyViewAltitudeIndicator{
    //     id:                         altitudeIndicator
    //     anchors.margins:            _toolsMargin
    //     height:                     flyviewMissionProgress.height * 0.9
    //     anchors.left:               flyviewMissionProgress.right
    //     anchors.leftMargin:         _toolsMargin
    //     anchors.verticalCenter:     flyviewMissionProgress.verticalCenter
    //     visible:                    flyviewMissionProgress.visible && QGroundControl.settingsManager.flyViewSettings.missionMaxAltitudeIndicator.rawValue
    // }

    // FlyViewAttitudeIndicator{
    //     id:                         attitudeIndicator
    //     anchors.margins:            _toolsMargin * 2.5
    //     anchors.bottom:             parent.bottom
    //     anchors.horizontalCenter:   parent.horizontalCenter
    //     visible:                    !flyviewMissionProgress.visible

    //     property real bottomEdgeCenterInset: visible ? height + (_toolsMargin * 2.5) : 0
    // }

    // FlyViewMissionProgress{
    //     id:                         flyviewMissionProgress
    //     anchors.margins:            _toolsMargin * 2
    //     anchors.bottom:             parent.bottom
    //     anchors.horizontalCenter:   parent.horizontalCenter
    //     _planMasterController: planController
    //     visible:  QGroundControl.settingsManager.flyViewSettings.showMissionProgress.rawValue

    //     Connections{
    //         target: _activeVehicle
    //         onFlightModeChanged: (flightMode)=> {
    //             //console.log(flightMode)
    //             if(flightMode === _activeVehicle.missionFlightMode){
    //                 flyviewMissionProgress.visible = true
    //             } else {
    //                 flyviewMissionProgress.visible = false
    //             }
    //         }
    //     }
    // }

    FlyViewAtmosphericSensorView{
        id:                         atmosphericSensorView
        anchors.top:                parent.top
        anchors.topMargin:          _toolsMargin
        anchors.left:               toolStrip.right
        anchors.leftMargin:         _toolsMargin
        visible:                    QGroundControl.settingsManager.flyViewSettings.showAtmosphericValueBar.rawValue && mapControl.pipState.state === mapControl.pipState.pipState
    }

    FlyViewWindvane {
        id:                         windvane
        vehicle:                    _activeVehicle
        anchors.top:                parent.top
        anchors.topMargin:          _toolsMargin
        anchors.left:               toolStrip.right
        anchors.leftMargin:         _toolsMargin
        //anchors.leftMargin:         (ScreenTools.isMobile ? ScreenTools.minTouchPixels : ScreenTools.defaultFontPixelWidth * 8) + _toolsMargin * 2
        visible:                    QGroundControl.settingsManager.flyViewSettings.showWindvane.rawValue
    }

    ModeChangedIndicator {
        anchors.centerIn:   parent
        z:                  QGroundControl.zOrderTopMost
    }

    Rectangle {
        id:                         messageToastManagerRect
        anchors.margins:            _toolsMargin
        anchors.bottom:             bottomCenterRowLayout.top
        anchors.horizontalCenter:   parent.horizontalCenter
        width:                      messageToastManager.width //mainWindow.width  * 0.4
        height:                     messageToastManager.height < mainWindow.height * 0.14 ? messageToastManager.height : mainWindow.height * 0.14
        color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.4) //"transparent" //qgcPal.window
        radius:                     _toolsMargin
        visible:                    messageFlick.contentHeight

        QGCFlickable {
            id:                 messageFlick
            anchors.fill:       parent
            anchors.horizontalCenter: parent.horizontalCenter
            contentHeight:      messageToastManager.height
            contentWidth:       messageToastManager.width
            pixelAligned:       true

            ScrollBar.vertical : ScrollBar{
                active: false
            }

            contentY : contentHeight > height ? contentHeight - height + _toolsMargin * 3 : 0

            MessageToastManager{
                id: messageToastManager
            }

            Connections {
                target: _activeVehicle
                onNewFormattedMessage : function(formattedMessage) {
                    messageToastManager.show(formattedMessage)
                }
            }
        }

        MouseArea{
            anchors.fill: parent
            propagateComposedEvents: true
        }
    }

    FlyViewAtmosphericChart{
        id: flyViewChartWidget
        anchors.margins:        _toolsMargin
        anchors.top:            telemetryPanel.bottom
        anchors.bottom:         bottomCenterRowLayout.top
        anchors.right:          topRightColumnLayout.left
        width:                  ScreenTools.isMobile ? mainWindow.width * 0.7 : mainWindow.width * 0.4
        visible:                QGroundControl.settingsManager.flyViewSettings.showChartWidget.rawValue
    }

    FlyViewEscStatus {
        id: flyViewEscStatus
        anchors.margins:        _toolsMargin
        anchors.top:            parent.top
        anchors.bottomMargin:   _toolsMargin
        anchors.right:          topRightColumnLayout.left
        visible:                QGroundControl.settingsManager.flyViewSettings.showEscStatus.rawValue
    }
}
