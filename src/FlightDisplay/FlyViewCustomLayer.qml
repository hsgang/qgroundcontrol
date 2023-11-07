/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.12
import QtQuick.Controls         2.4
import QtQuick.Dialogs          1.3
import QtQuick.Layouts          1.12
import QtGraphicalEffects       1.12

import QtLocation               5.3
import QtPositioning            5.3
import QtQuick.Window           2.2
import QtQml.Models             2.1

import QGroundControl               1.0
import QGroundControl.Controllers   1.0
import QGroundControl.Controls      1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.FlightMap     1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0

Item {
    id: _root

    property var    parentToolInsets               // These insets tell you what screen real estate is available for positioning the controls in your overlay
    property var    totalToolInsets:        _toolInsets // These are the insets for your custom overlay additions
    property var    mapControl
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30
    property real   _idealWidth:            (ScreenTools.isMobile ? ScreenTools.minTouchPixels : ScreenTools.defaultFontPixelWidth * 8) + _toolsMargin

    // Property of Tools
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property color  _baseBGColor:           qgcPal.window
    property color  _transparentColor:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)

    // Property of Active Vehicle
    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle
    property real   _heading:               _activeVehicle   ? _activeVehicle.heading.rawValue : 0
    property bool   _available:             !isNaN(_activeVehicle.vibration.xAxis.rawValue)
    property real   _xValue:                _activeVehicle.vibration.xAxis.rawValue
    property real   _yValue:                _activeVehicle.vibration.yAxis.rawValue
    property real   _zValue:                _activeVehicle.vibration.zAxis.rawValue

    property real   _barWidth:              ScreenTools.defaultFontPixelWidth * 3
    property real   _barHeight:             ScreenTools.defaultFontPixelHeight * 10

    readonly property real _barMinimum:     0.0
    readonly property real _barMaximum:     90.0
    readonly property real _barBadValue:    60.0

    property real   _vehicleAltitude:           _activeVehicle ? _activeVehicle.altitudeRelative.rawValue : 0
    property real   _vehicleVerticalSpeed:      _activeVehicle ? _activeVehicle.climbRate.rawValue : 0
    property real   _vehicleGroundSpeed:        _activeVehicle ? _activeVehicle.groundSpeed.rawValue : 0
    property real   _distanceToHome:            _activeVehicle ? _activeVehicle.distanceToHome.rawValue : 0
    property string _vehicleAltitudeText:       isNaN(_vehicleAltitude) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsVerticalDistanceUnits(_vehicleAltitude).toFixed(1)
    property string _vehicleVerticalSpeedText:  isNaN(_vehicleVerticalSpeed) ? "-.-" : QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_vehicleVerticalSpeed).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsSpeedUnitsString
    property string _vehicleGroundSpeedText:    isNaN(_vehicleGroundSpeed) ? "-.-" : QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_vehicleGroundSpeed).toFixed(1)
    property string _distanceToHomeText:        isNaN(_distanceToHome) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsVerticalDistanceUnits(_distanceToHome).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString


    // Property of Vibration visible
    property bool _vibeStatusVisible:        false

    // QGC Map Center Position
    property var _mapCoordinate:            QGroundControl.flightMapPosition

    // Property OpenWeather API Key
    property string   _openWeatherAPIkey:   QGroundControl.settingsManager ? QGroundControl.settingsManager.appSettings.openWeatherApiKey.value : null
    property string timeString   

    // since this file is a placeholder for the custom layer in a standard build, we will just pass through the parent insets
    QGCToolInsets {
        id:                     _totalToolInsets
        leftEdgeTopInset:       0
        leftEdgeCenterInset:    0
        id:                     _toolInsets
        leftEdgeTopInset:       parentToolInsets.leftEdgeTopInset
        leftEdgeCenterInset:    parentToolInsets.leftEdgeCenterInset
        leftEdgeBottomInset:    parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      parentToolInsets.rightEdgeTopInset
        rightEdgeCenterInset:   parentToolInsets.rightEdgeCenterInset
        rightEdgeBottomInset:   parentToolInsets.rightEdgeBottomInset
        topEdgeLeftInset:       parentToolInsets.topEdgeLeftInset
        topEdgeCenterInset:     parentToolInsets.topEdgeCenterInset
        topEdgeRightInset:      parentToolInsets.topEdgeRightInset
        bottomEdgeLeftInset:    parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  parentToolInsets.bottomEdgeCenterInset
        bottomEdgeRightInset:   parentToolInsets.bottomEdgeRightInset
    }

    TelemetryValuesBar {
        id:                 telemetryPanel
        x:                  recalcXPosition()
        anchors.margins:    _toolsMargin
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top:        parent.top

        function recalcXPosition() {
            // First try centered
            var halfRootWidth   = _root.width / 2
            var halfPanelWidth  = telemetryPanel.width / 2
            var leftX           = (halfRootWidth - halfPanelWidth) - _toolsMargin
            var rightX          = (halfRootWidth + halfPanelWidth) + _toolsMargin
            if (leftX >= parentToolInsets.leftEdgeBottomInset || rightX <= parentToolInsets.rightEdgeBottomInset ) {
                // It will fit in the horizontalCenter
                return halfRootWidth - halfPanelWidth
            } else {
                // Anchor to left edge
                return parentToolInsets.leftEdgeBottomInset + _toolsMargin
            }
        }
    }

    //-----------------------------------------------------------------------------------------------------
    //--custom VehicleWarnings Widget-----------------------------------------------------------------------------------

//    VehicleWarnings {
//        anchors.top: parent.top
//        anchors.topMargin: atmosphericSensorView.visible ? atmosphericSensorView.height + (_toolsMargin * 2) : _toolsMargin
//        anchors.horizontalCenter: parent.horizontalCenter
//        z:                  QGroundControl.zOrderTopMost
//    }

    //-----------------------------------------------------------------------------------------------------
    //--multiVehiclePanelSelector Widget-----------------------------------------------------------------------------------

    Row {
        id:                 multiVehiclePanelSelector
        anchors.margins:    _toolsMargin
        anchors.top:        parent.top
        anchors.right:      parent.right
        width:              _rightPanelWidth
        spacing:            ScreenTools.defaultFontPixelWidth
        visible:            QGroundControl.multiVehicleManager.vehicles.count > 1 && QGroundControl.corePlugin.options.flyView.showMultiVehicleList

        property bool showSingleVehiclePanel:  !visible || singleVehicleRadio.checked

        QGCMapPalette { id: mapPal; lightColors: true }

        QGCRadioButton {
            id:             singleVehicleRadio
            text:           qsTr("Single")
            checked:        true
            textColor:      mapPal.text
        }

        QGCRadioButton {
            text:           qsTr("Multi-Vehicle")
            textColor:      mapPal.text
        }
    }

    MultiVehicleList {
        anchors.margins:    _toolsMargin
        anchors.top:        multiVehiclePanelSelector.bottom
        anchors.right:      parent.right
        width:              _rightPanelWidth
        height:             parent.height - y - _toolsMargin
        visible:            !multiVehiclePanelSelector.showSingleVehiclePanel
    }

    //-----------------------------------------------------------------------------------------------------
    //--custom ModeChangedIndicator Widget-----------------------------------------------------------------------------------

    ModeChangedIndicator {
        anchors.centerIn:   parent
        z:                  QGroundControl.zOrderTopMost
    }

    //-----------------------------------------------------------------------------------------------------
    //--custom indicator Widget-----------------------------------------------------------------------------------

    FlyViewAltitudeIndicator{
        id:                         altitudeIndicator
        anchors.margins:            _toolsMargin
        height:                     attitudeIndicator.height * 0.9
        anchors.left:               attitudeIndicator.right
        anchors.leftMargin:         ScreenTools.defaultFontPixelWidth * 19 + _toolsMargin * 6
        anchors.verticalCenter:     attitudeIndicator.verticalCenter
        visible:                    QGroundControl.settingsManager.flyViewSettings.missionMaxAltitudeIndicator.rawValue
    }

    FlyViewAttitudeIndicator{
        id:                         attitudeIndicator
        anchors.margins:            _toolsMargin * 2
        anchors.bottom:             parent.bottom
        anchors.horizontalCenter:   parent.horizontalCenter
    }

    FlyViewAtmosphericSensorView{
        id:                         atmosphericSensorView
        anchors.top:                parent.top
        anchors.topMargin:          _toolsMargin
        anchors.left:               parent.left
        anchors.leftMargin:         (ScreenTools.isMobile ? ScreenTools.minTouchPixels : ScreenTools.defaultFontPixelWidth * 8) + _toolsMargin * 2
        visible:                    QGroundControl.settingsManager.flyViewSettings.showAtmosphericValueBar.rawValue && mapControl.pipState.state === mapControl.pipState.pipState
    }

//    FlyViewGeneratorStatusView{
//        id:                         generatorStatusView
//        anchors.margins:            _toolsMargin
//        anchors.top:                parent.top
//        anchors.topMargin:          mapControl.pipState.state !== mapControl.pipState.pipState ? (atmosphericSensorView.visible ? _toolsMargin : _idealWidth) : _toolsMargin
//        anchors.left:               atmosphericSensorView.visible ? atmosphericSensorView.right : parent.left
//        anchors.leftMargin:         atmosphericSensorView.visible ? _toolsMargin : _idealWidth * 3
//        visible:                    QGroundControl.settingsManager.flyViewSettings.showGeneratorStatus.rawValue
//    }

    PhotoVideoControl {
        id:                         photoVideoControl
        anchors.margins:            _toolsMargin
        anchors.right:              parent.right
        anchors.verticalCenter:     parent.verticalCenter

        property bool _verticalCenter: !QGroundControl.settingsManager.flyViewSettings.alternateInstrumentPanel.rawValue
    }

    SIYICameraControl {
        id:                         siyiCameraControl
        anchors.margins:            _toolsMargin
        anchors.right:              photoVideoControl.visible ? photoVideoControl.left : parent.right
        anchors.verticalCenter:     parent.verticalCenter
    }

    GimbalControl{
        id:                     gimbalControl
        anchors.margins:        _toolsMargin
        anchors.right:          photoVideoControl.visible ? photoVideoControl.left : parent.right
        anchors.verticalCenter: parent.verticalCenter
        width:                  _rightPanelWidth*0.9
        height:                 width
    }

    WinchControlPanel {
        id:                     winchControlPanel
        anchors.margins:        _toolsMargin
        anchors.right:          photoVideoControl.visible ? photoVideoControl.left : parent.right
        anchors.verticalCenter: parent.verticalCenter
        width:                  ScreenTools.defaultFontPixelWidth * 10
        height:                 ScreenTools.defaultFontPixelWidth * 40
        visible:                false
    }

    // need to manage full screen here
    FlyViewVideoToolStrip {
        id:                         videoToolStrip
        anchors.top:                multiVehiclePanelSelector.visible ? multiVehiclePanelSelector.bottom : parent.top
        anchors.topMargin:          _toolsMargin
        anchors.right:              multiVehiclePanelSelector.showSingleVehiclePanel ? quickViewPopupButton.left : multiVehiclePanelSelector.left
        anchors.rightMargin:        _toolsMargin
        z:                          QGroundControl.zOrderWidgets
        maxWidth:                   parent.width * 0.7
        maxHeight:                  parent.height * 0.7
        visible:                    multiVehiclePanelSelector.showSingleVehiclePanel
    }

    FlyViewWeatherWidget{
        id:                         weatherWidget
        anchors.margins:            _toolsMargin
        anchors.verticalCenter:     parent.verticalCenter
        anchors.right:              parent.right
        anchors.topMargin:          _toolsMargin
        visible:                    false
    }

    Rectangle {
        id:                         messageToastManagerRect
        anchors.margins:            _toolsMargin
        anchors.bottom:             attitudeIndicator.top
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
                onNewFormattedMessage :{
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
        anchors.bottom:         attitudeIndicator.top
        anchors.right:          siyiCameraControl.visible ? siyiCameraControl.left : (photoVideoControl.visible ? photoVideoControl.left : parent.right)
            //photoVideoControl.visible ? photoVideoControl.left : (siyiCameraControl.visible ? siyiCameraControl.left : parent.right)
        width:                  ScreenTools.isMobile ? mainWindow.width * 0.7 : mainWindow.width * 0.4
        visible:                false
    }

    FlyViewMissionProgress{
        id: flyviewMissionProgress
        y:                      (parent.height - parentToolInsets.bottomEdgeLeftInset - height) * 0.7
        anchors.left:           parent.left
        anchors.leftMargin:     (ScreenTools.isMobile ? ScreenTools.minTouchPixels : ScreenTools.defaultFontPixelWidth * 8) + _margins * 2
        visible: false

        Connections{
            target: _activeVehicle
            onFlightModeChanged: {
                //console.log(flightMode)
                if (flightMode === "Auto" || flightMode === "Mission" || flightMode ==="미션"){
                    flyviewMissionProgress.visible = true
                }
            }
        }
    }

    Rectangle {
        id:                         flyviewStatusRect
        anchors.horizontalCenter:   parent.horizontalCenter
        anchors.bottom:             attitudeIndicator.top
        anchors.bottomMargin:       _toolsMargin
        color:                      "transparent"
        width:                      flyviewStatusRow.width
        height:                     flyviewStatusRow.height

        RowLayout{
            id: flyviewStatusRow

            FlyViewVibrationStatus{
                id:                         flyviewVibrationStatus
                visible:                    false
            }

            FlyViewEKFStatus{
                id:                         flyviewEKFStatus
                visible:                    false
            }
        }
    }



    Component {
        id: quickViewControlDialogComponent

        QGCPopupDialog {
            title:      qsTr("FlyView Widget Settings")
            buttons:    StandardButton.Close

            RowLayout{
                spacing: _margins * 5

                GridLayout{
                    id:     quickViewControlStripGrid
                    flow:   GridLayout.LeftToRight //TopToBottom
                    columns: 2
                    rowSpacing: _margins * 2

                    QGCLabel{ text: qsTr("Payload Widget"); Layout.columnSpan : 2; Layout.alignment: Qt.AlignHCenter }

                    QGCLabel{ text: qsTr("PhotoVideo Control") }
                    QGCSwitch {
                        checked:            photoVideoControl.visible
                        onClicked:          photoVideoControl.visible = !photoVideoControl.visible
                    }

                    QGCLabel{ text: qsTr("Mount Control") }
                    QGCSwitch {
                        checked:            QGroundControl.settingsManager.flyViewSettings.showGimbalControlPannel.rawValue === true ? 1 : 0
                        onClicked:          QGroundControl.settingsManager.flyViewSettings.showGimbalControlPannel.rawValue = checked ? 1 : 0
                    }

                    QGCLabel{ text: qsTr("Winch Control") }
                    QGCSwitch {
                        checked:            winchControlPanel.visible
                        onClicked:          winchControlPanel.visible = !winchControlPanel.visible
                    }

                    QGCLabel{ text: qsTr("Chart Widget") }
                    QGCSwitch {
                        checked:            flyViewChartWidget.visible
                        onClicked:          flyViewChartWidget.visible = !flyViewChartWidget.visible
                    }

                    QGCLabel{ text: qsTr("Atmospheric Data") }
                    QGCSwitch {
                        checked:            QGroundControl.settingsManager.flyViewSettings.showAtmosphericValueBar.rawValue === true ? 1 : 0
                        onClicked:          QGroundControl.settingsManager.flyViewSettings.showAtmosphericValueBar.rawValue = checked ? 1 : 0
                    }
                }

                GridLayout{
                    id:     quickViewControlStripGrid2
                    flow:   GridLayout.LeftToRight //TopToBottom
                    columns: 2
                    rowSpacing: _margins * 2

                    QGCLabel{ text: qsTr("Status Widget"); Layout.columnSpan : 2; Layout.alignment: Qt.AlignHCenter }

                    QGCLabel{ text: qsTr("Mission Progress Bar") }
                    QGCSwitch {
                        checked:            flyviewMissionProgress.visible
                        onClicked:          flyviewMissionProgress.visible = !flyviewMissionProgress.visible
                    }

                    QGCLabel{ text: qsTr("Telemetry Panel") }
                    QGCSwitch {
                        checked:            telemetryPanel.visible
                        onClicked:          telemetryPanel.visible = !telemetryPanel.visible
                    }

                    QGCLabel{ text: qsTr("Weather Widget") }
                    QGCSwitch {
                        checked:            weatherWidget.visible
                        onClicked:          {
                            weatherWidget.visible = !weatherWidget.visible
                            //weatherWidget.getWeatherJSON()
                        }
                    }

                    QGCLabel{ text: qsTr("Vibration Status") }
                    QGCSwitch {
                        checked:            flyviewVibrationStatus.visible //QGroundControl.settingsManager.flyViewSettings.showGeneratorStatus.rawValue === true ? 1 : 0
                        onClicked:          flyviewVibrationStatus.visible = !flyviewVibrationStatus.visible //QGroundControl.settingsManager.flyViewSettings.showGeneratorStatus.rawValue = checked ? 1 : 0
                    }

                    QGCLabel{ text: qsTr("EKF Status") }
                    QGCSwitch {
                        checked:            flyviewEKFStatus.visible //QGroundControl.settingsManager.flyViewSettings.showGeneratorStatus.rawValue === true ? 1 : 0
                        onClicked:          flyviewEKFStatus.visible = !flyviewEKFStatus.visible //QGroundControl.settingsManager.flyViewSettings.showGeneratorStatus.rawValue = checked ? 1 : 0
                    }
                }
            }
        }
    }

    Rectangle {
        id:                 quickViewPopupButton
        anchors.margins:    _toolsMargin + ScreenTools.defaultFontPixelWidth * 0.25
        anchors.top:        multiVehiclePanelSelector.visible ? multiVehiclePanelSelector.bottom : parent.top
        anchors.right:      multiVehiclePanelSelector.showSingleVehiclePanel ?  (photoVideoControl.visible ? photoVideoControl.left : parent.right) : multiVehiclePanelSelector.left
        anchors.rightMargin: _toolsMargin
        color:              qgcPal.window
        width:              _idealWidth - anchorsMargins
        height:             width
        radius:             ScreenTools.defaultFontPixelHeight / 2
        visible:            true

        property real _idealWidth:      (ScreenTools.isMobile ? ScreenTools.minTouchPixels : ScreenTools.defaultFontPixelWidth * 8)
        property real anchorsMargins:   ScreenTools.defaultFontPixelWidth * 0.8
        property real contentMargins:   innerText.height * 0.1

        DeadMouseArea {
            anchors.fill: parent
        }

        Item{
            id:                 contentLayoutItem
            anchors.fill:       parent
            anchors.margins:    quickViewPopupButton.contentMargins

            Column {
                anchors.centerIn:   parent
                spacing:            quickViewPopupButton.contentMargins * 2

                QGCColoredImage {
                    id:                         innerImage
                    height:                     contentLayoutItem.height * 0.6
                    width:                      contentLayoutItem.width  * 0.6
                    smooth:                     true
                    mipmap:                     true
                    color:                      qgcPal.text
                    fillMode:                   Image.PreserveAspectFit
                    antialiasing:               true
                    sourceSize.height:          height
                    sourceSize.width:           width
                    anchors.horizontalCenter:   parent.horizontalCenter
                    source:                     "/qmlimages/LogDownloadIcon"
                }

                QGCLabel {
                    id:                         innerText
                    text:                       qsTr("Widget")
                    color:                      qgcPal.text
                    anchors.horizontalCenter:   parent.horizontalCenter
                    font.family:                ScreenTools.normalFontFamily
                    font.pointSize:             ScreenTools.smallFontPointSize
                }
            }
        }

        MouseArea {
            anchors.fill: quickViewPopupButton
            onClicked: {
                quickViewControlDialogComponent.createObject(mainWindow).open()
            }
        }
    }
}



