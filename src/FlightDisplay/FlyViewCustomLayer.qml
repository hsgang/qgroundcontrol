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
import QGroundControl.Airspace      1.0
import QGroundControl.Airmap        1.0
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

    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeTopInset:       0
        leftEdgeCenterInset:    0
        leftEdgeBottomInset:    0
        rightEdgeTopInset:      0
        rightEdgeCenterInset:   0
        rightEdgeBottomInset:   0
        topEdgeLeftInset:       0
        topEdgeCenterInset:     0
        topEdgeRightInset:      0
        bottomEdgeLeftInset:    0
        bottomEdgeCenterInset:  0
        bottomEdgeRightInset:   0
    }

    TelemetryValuesBar {
        id:                 telemetryPanel
        x:                  recalcXPosition()
        anchors.margins:    _toolsMargin
        anchors.right:      parent.right
        anchors.bottom:     parent.bottom
        anchors.bottomMargin: _toolsMargin //ScreenTools.defaultFontPixelHeight * 3

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
        //anchors.verticalCenter:     parent.verticalCenter
        anchors.left:               attitudeIndicator.right
        anchors.leftMargin:         _toolsMargin * 4
        anchors.verticalCenter:     attitudeIndicator.verticalCenter
        visible:                    QGroundControl.settingsManager.flyViewSettings.missionMaxAltitudeIndicator.rawValue
    }

    FlyViewAttitudeIndicator{
        id:                         attitudeIndicator
        anchors.margins:            _toolsMargin * 2
        //anchors.top:                parent.top
        anchors.bottom:             parent.bottom
        anchors.horizontalCenter:   parent.horizontalCenter
        //anchors.right:              parent.right
        //anchors.left:               parent.left
    }

    FlyViewAtmosphericSensorView{
        id:                         atmosphericSensorView
        anchors.margins:            _toolsMargin
        anchors.top:                parent.top
        anchors.topMargin:          _toolsMargin//ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 8 : ScreenTools.defaultFontPixelHeight * 11
        anchors.left:               parent.left
        anchors.leftMargin:         _idealWidth * 1.4
        visible:                    QGroundControl.settingsManager.flyViewSettings.showAtmosphericValueBar.rawValue && mapControl.pipState.state === mapControl.pipState.pipState
    }

    FlyViewGeneratorStatusView{
        id:                         generatorStatusView
        anchors.margins:            _toolsMargin
        anchors.top:                parent.top
        anchors.topMargin:          mapControl.pipState.state !== mapControl.pipState.pipState ? (atmosphericSensorView.visible ? _toolsMargin : _idealWidth) : _toolsMargin
        anchors.left:               atmosphericSensorView.visible ? atmosphericSensorView.right : parent.left
        anchors.leftMargin:         atmosphericSensorView.visible ? _toolsMargin : _idealWidth * 1.4
        visible:                    QGroundControl.settingsManager.flyViewSettings.showGeneratorStatus.rawValue
    }

    PhotoVideoControl {
        id:                         photoVideoControl
        anchors.margins:            _toolsMargin
        anchors.top:                parent.top
        anchors.right:              parent.right

        property bool _verticalCenter: !QGroundControl.settingsManager.flyViewSettings.alternateInstrumentPanel.rawValue
    }

    GimbalControl{
        id:                     gimbalControl
        anchors.margins:        _toolsMargin
        anchors.right:          parent.right
        anchors.verticalCenter: parent.verticalCenter
        width:                  _rightPanelWidth*0.9
        height:                 width
    }

    //-----------------------------------------------------------------------------------------------------
    //--Vibration Widget-----------------------------------------------------------------------------------
    Rectangle {
        id:                     vibrationBackground
        anchors.right:          weatherPopupButton.left
        anchors.bottom:         parent.bottom
        anchors.margins:        _toolsMargin
        color:                  "#80000000"
        height:                 ScreenTools.defaultFontPixelHeight * 2.5
        width:                  height
        radius:                 ScreenTools.defaultFontPixelHeight / 3
        visible:                false

        MouseArea {
            anchors.fill: parent
            onClicked:    _vibeStatusVisible = !_vibeStatusVisible
        }

        QGCLabel {
            anchors.centerIn:   parent
            font.pointSize:     ScreenTools.largeFontPointSize
            Layout.alignment:   Qt.AlignHCenter
            color:              "white"
            text:               qsTr("Vibe")
        }
    }

    //-----------------------------------------------------------------------------------------------------
    //--Vibration Status-----------------------------------------------------------------------------------
    Rectangle {
        id:                     vibrationStatus
        anchors.left:           parent.left
        anchors.leftMargin:     _toolsMargin
        anchors.verticalCenter: parent.verticalCenter
        width:                  _rightPanelWidth
        height:                 width
        radius:                 2
        color:                  qgcPal.window
        visible:                _vibeStatusVisible

        RowLayout {
            id:               barRow
            spacing:          ScreenTools.defaultFontPixelWidth * 2
            anchors.centerIn: parent

            ColumnLayout {
                Rectangle {
                    id:                 xBar
                    height:             _barHeight
                    width:              _barWidth
                    Layout.alignment:   Qt.AlignHCenter
                    border.width:       1
                    border.color:       qgcPal.text

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         parent.height * (Math.min(_barMaximum, _xValue) / (_barMaximum - _barMinimum))
                        color:          qgcPal.text
                    }
                }

                QGCLabel {
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("X")
                }
            }

            ColumnLayout {
                Rectangle {
                    height:             _barHeight
                    width:              _barWidth
                    Layout.alignment:   Qt.AlignHCenter
                    border.width:       1
                    border.color:       qgcPal.text

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         parent.height * (Math.min(_barMaximum, _yValue) / (_barMaximum - _barMinimum))
                        color:          qgcPal.text
                    }
                }

                QGCLabel {
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("Y")
                }
            }

            ColumnLayout {
                Rectangle {
                    height:             _barHeight
                    width:              _barWidth
                    Layout.alignment:   Qt.AlignHCenter
                    border.width:       1
                    border.color:       qgcPal.text

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         parent.height * (Math.min(_barMaximum, _zValue) / (_barMaximum - _barMinimum))
                        color:          qgcPal.text
                    }
                }

                QGCLabel {
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("Z")
                }
            }
        }

        // Max vibe indication line at 60
        Rectangle {
            anchors.topMargin:      xBar.height * (1.0 - ((_barBadValue - _barMinimum) / (_barMaximum - _barMinimum)))
            anchors.top:            barRow.top
            anchors.left:           barRow.left
            anchors.right:          barRow.right
            width:                  barRow.width
            height:                 1
            color:                  "red"
        }
    }

    FlyViewWeatherWidget{
        id:                         weatherWidget
        anchors.margins:            _toolsMargin
        anchors.horizontalCenter:   parent.horizontalCenter
        anchors.top:                parent.top
        anchors.topMargin:          _toolsMargin
        visible:                    false
    }

    Rectangle {
        id:                 weatherPopupButton
        anchors.margins:    _toolsMargin
        anchors.right:      parent.right
        anchors.bottom:     telemetryPanel.top
        color:              "#80000000" //qgcPal.window
        height:             ScreenTools.defaultFontPixelHeight * 2.5
        width:              ScreenTools.defaultFontPixelHeight * 2.5
        radius:             ScreenTools.defaultFontPixelHeight / 3
        visible: QGroundControl.settingsManager.appSettings.enableOpenWeatherAPI.rawValue

        Image {
            id: showWeatherStatusIcon
            source: "/qmlimages/cloudy_wind.svg"
            mipmap: true
            fillMode: Image.PreserveAspectFit
            sourceSize: Qt.size(parent.width, parent.height)
            MouseArea {
                anchors.fill: showWeatherStatusIcon
                onClicked: {
                    weatherWidget.getWeatherJSON()
                    weatherWidget.visible = !weatherWidget.visible
                }
            }
        }
        ColorOverlay {
               anchors.fill: showWeatherStatusIcon
               source: showWeatherStatusIcon
               color: "#ffffff"
        }
    }

    Rectangle {
        id: messageToastManagerRect
        anchors.margins: _toolsMargin
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width:           mainWindow.width  * 0.5
        //height:         mainWindow.height * 0.15
        height:         messageToastManager.height < mainWindow.height * 0.15 ? messageToastManager.height : mainWindow.height * 0.15
        color:          "transparent" //qgcPal.window
        visible:        messageFlick.contentHeight

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

    Rectangle {
        id:                 chartPopupButton
        anchors.margins:    _toolsMargin
        anchors.right:      parent.right
        anchors.bottom:     weatherPopupButton.visible ? weatherPopupButton.top : telemetryPanel.top
        color:              "#80000000" //qgcPal.window
        height:             ScreenTools.defaultFontPixelHeight * 2.5
        width:              ScreenTools.defaultFontPixelHeight * 2.5
        radius:             ScreenTools.defaultFontPixelHeight / 3
        visible:            true
        //visible: QGroundControl.settingsManager.appSettings.enableOpenWeatherAPI.rawValue

        Image {
            id: showChartIcon
            anchors.centerIn: parent
            source: "/qmlimages/MAVLinkInspector"
            mipmap: true
            fillMode: Image.PreserveAspectFit
            sourceSize: Qt.size(parent.width * 0.8, parent.height * 0.8)
            MouseArea {
                anchors.fill: showChartIcon
                onClicked: {
                    flyViewChartWidget.visible = !flyViewChartWidget.visible
                }
            }
        }
        ColorOverlay {
               anchors.fill: showChartIcon
               source: showChartIcon
               color: "#ffffff"
        }
    }

    FlyViewAtmosphericChart{
        id: flyViewChartWidget
        anchors.margins:        _toolsMargin
        anchors.top:            photoVideoControl.bottom
        anchors.bottom:         attitudeIndicator.top
        anchors.right:          chartPopupButton.left
        //anchors.verticalCenter: parent.verticalCenter
        width: mainWindow.width * 0.4
        //height: mainWindow.height * 0.5
    }

}


