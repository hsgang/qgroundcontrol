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

    property var parentToolInsets               // These insets tell you what screen real estate is available for positioning the controls in your overlay
    property var totalToolInsets:           _toolInsets // These are the insets for your custom overlay additions
    property var mapControl
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30

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
    property bool _showWeatherStatus :       false

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

        // States for custom layout support
        states: [
            State {
                name: "bottom"
                when: telemetryPanel.bottomMode

                AnchorChanges {
                    target: telemetryPanel
                    anchors.top: undefined
                    anchors.bottom: parent.bottom
                    anchors.right: undefined
                    anchors.verticalCenter: undefined
                }

                PropertyChanges {
                    target: telemetryPanel
                    x: recalcXPosition()
                }
            },

            State {
                name: "right-video"
                when: !telemetryPanel.bottomMode && attitudeIndicator.visible

                AnchorChanges {
                    target: telemetryPanel
                    anchors.top: undefined
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.verticalCenter: undefined
                }
            },

            State {
                name: "right-novideo"
                when: !telemetryPanel.bottomMode && !attitudeIndicator.visible

                AnchorChanges {
                    target: telemetryPanel
                    anchors.top: undefined
                    anchors.bottom: undefined
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        ]

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

    VehicleWarnings {
        anchors.top: parent.top
        anchors.topMargin: atmosphericSensorView.visible ? atmosphericSensorView.height + (_toolsMargin * 2) : _toolsMargin
        anchors.horizontalCenter: parent.horizontalCenter
        z:                  QGroundControl.zOrderTopMost
    }

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
        anchors.verticalCenter:     parent.verticalCenter
        anchors.right:              parent.right
        anchors.rightMargin:        _rightPanelWidth * 1.1
        visible:                    QGroundControl.settingsManager.flyViewSettings.missionMaxAltitudeIndicator.rawValue
    }

    FlyViewAtmosphericSensorView{
        id:                         atmosphericSensorView
        anchors.margins:            _toolsMargin
        anchors.top:                parent.top
        anchors.horizontalCenter:   parent.horizontalCenter
        visible:                    QGroundControl.settingsManager.flyViewSettings.showAtmosphericValueBar.rawValue && mapControl.pipState.state === mapControl.pipState.pipState
    }

    //-----------------------------------------------------------------------------------------------------
    //--Attitude Widget-----------------------------------------------------------------------------------

    Rectangle {
        id:                     attitudeIndicator
        anchors.bottomMargin:   _toolsMargin
        anchors.leftMargin:    _toolsMargin * 1.5
        anchors.bottom:         parent.bottom
        //anchors.left:          telemetryPanel.right
        height:                 ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 7 : ScreenTools.defaultFontPixelHeight * 9
        width:                  height
        radius:                 height * 0.5
        color:                  "#80000000"

        Rectangle {
            id:                         altitudeValue
            anchors.margins:            _toolsMargin * 2
            anchors.left:               parent.right
            anchors.verticalCenter:     parent.verticalCenter
            height:                     ScreenTools.isMobile ? parent.height * 0.55 : parent.height * 0.45
            width:                      ScreenTools.isMobile ? parent.width : parent.width * 0.8
            color:                      "transparent" //"#80000000"
            border.color: "white"
            border.width: 2
            radius:                     _toolsMargin

            GridLayout {
                anchors.fill: parent

                columns: 4
                rows: 3

                rowSpacing: 1

                Rectangle{
                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 1
                    Layout.rowSpan : 1
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 1
                    Layout.column : 3
                    Layout.row : 0
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: "transparent"
                    QGCLabel {
                        id: altText
                        text: "ALT"
                        anchors.right: parent.right
                        anchors.rightMargin: _toolsMargin
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Glow {
                        anchors.fill: altText
                        radius: 2
                        samples: 3
                        color: "black"
                        source: altText
                    }
                }
                Rectangle{
                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 1
                    Layout.rowSpan : 1
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 1
                    Layout.column : 3
                    Layout.row : 1
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: "transparent"
                    QGCLabel {
                        id: distunitText
                        text:  QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString
                        anchors.right: parent.right
                        anchors.rightMargin: _toolsMargin
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Glow {
                        anchors.fill: distunitText
                        radius: 2
                        samples: 3
                        color: "black"
                        source: distunitText
                    }
                }

                Rectangle{
                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 3
                    Layout.rowSpan : 2
                    Layout.preferredWidth: 3
                    Layout.preferredHeight: 2
                    Layout.column : 0
                    Layout.row : 0
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: "transparent"
                    QGCLabel {
                        id:     altitudeValueText
                        text:   _vehicleAltitudeText
                        font.bold : true
                        font.pointSize : ScreenTools.defaultFontPointSize * 2.5
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Glow {
                        anchors.fill: altitudeValueText
                        radius: 3
                        samples: 5
                        color: "black"
                        source: altitudeValueText
                    }
                }

                Rectangle{
                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 4
                    Layout.rowSpan : 1
                    Layout.preferredWidth: 4
                    Layout.preferredHeight: 1
                    Layout.column : 0
                    Layout.row : 2
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: "transparent"
                    QGCLabel {
                        id: vsText
                        text:   "VS " + _vehicleVerticalSpeedText
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Glow {
                        anchors.fill: vsText
                        radius: 2
                        samples: 3
                        color: "black"
                        source: vsText
                    }
                }
            }
        }

        Rectangle {
            id:                         groundSpeedValue
            anchors.margins:            _toolsMargin * 2
            anchors.right:              parent.left
            anchors.verticalCenter:     parent.verticalCenter
            height:                     ScreenTools.isMobile ? parent.height * 0.55 : parent.height * 0.45
            width:                      ScreenTools.isMobile ? parent.width : parent.width * 0.8
            color:                      "transparent" //"#80000000"
            border.color: "white"
            border.width: 2
            radius:                     _toolsMargin

            GridLayout {
                id: leftIndicator
                anchors.fill: parent

                columns: 4
                rows: 3

                rowSpacing: 1

                Rectangle{
                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 1
                    Layout.rowSpan : 1
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 1
                    Layout.column : 0
                    Layout.row : 0
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: "transparent"
                    QGCLabel {
                        id: spdText
                        text: "SPD"
                        anchors.left: parent.left
                        anchors.leftMargin: _toolsMargin
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Glow {
                        anchors.fill: spdText
                        radius: 2
                        samples: 3
                        color: "black"
                        source: spdText
                    }
                }

                Rectangle{
                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 1
                    Layout.rowSpan : 1
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 1
                    Layout.column : 0
                    Layout.row : 1
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: "transparent"
                    QGCLabel {
                        id: spdunitText
                        text:  QGroundControl.unitsConversion.appSettingsSpeedUnitsString
                        anchors.left: parent.left
                        anchors.leftMargin: _toolsMargin
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Glow {
                        anchors.fill: spdunitText
                        radius: 2
                        samples: 3
                        color: "black"
                        source: spdunitText
                    }
                }

                Rectangle{
                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 3
                    Layout.rowSpan : 2
                    Layout.preferredWidth: 3
                    Layout.preferredHeight: 2
                    Layout.column : 1
                    Layout.row : 0
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: "transparent"
                    QGCLabel {
                        id: gndspdText
                        text:   _vehicleGroundSpeedText
                        font.bold : true
                        font.pointSize : ScreenTools.defaultFontPointSize * 2.5
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Glow {
                        anchors.fill: gndspdText
                        radius: 3
                        samples: 5
                        color: "black"
                        source: gndspdText
                    }
                }

                Rectangle{
                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 4
                    Layout.rowSpan : 1
                    Layout.preferredWidth: 4
                    Layout.preferredHeight: 1
                    Layout.column : 0
                    Layout.row : 2
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: "transparent"
                    QGCLabel {
                        id: dtohText
                        text:   "DtoH " + _distanceToHomeText
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Glow {
                        anchors.fill: dtohText
                        radius: 2
                        samples: 3
                        color: "black"
                        source: dtohText
                    }
                }
            }
        }

        state:                  telemetryPanel.bottomMode ? "side" : "center"

        CustomAttitudeHUD {
            size:               parent.height
            vehicle:            _activeVehicle
        }

        states: [
            State {
                name: "side"
                AnchorChanges {
                    target: attitudeIndicator
                    anchors.left: telemetryPanel.right
                }
            },
            State {
                name: "center"
                AnchorChanges {
                    target: attitudeIndicator
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        ]
    }

    PhotoVideoControl {
        id:                     photoVideoControl
        anchors.margins:        _toolsMargin
        anchors.right:          parent.right
        width:                  ScreenTools.isMobile ? _rightPanelWidth * 0.66 : _rightPanelWidth
        state:                  _verticalCenter ? "verticalCenter" : "topAnchor"
        states: [
            State {
                name: "verticalCenter"
                AnchorChanges {
                    target:                 photoVideoControl
                    anchors.top:            undefined
                    anchors.verticalCenter: _root.verticalCenter
                }
            },
            State {
                name: "topAnchor"
                AnchorChanges {
                    target:                 photoVideoControl
                    anchors.verticalCenter: undefined
                    anchors.top:            instrumentPanel.bottom
                }
            }
        ]

        property bool _verticalCenter: !QGroundControl.settingsManager.flyViewSettings.alternateInstrumentPanel.rawValue
    }

    //-----------------------------------------------------------------------------------------------------
    //--Vibration Widget-----------------------------------------------------------------------------------
    Rectangle {
        id:                     vibrationBackground
        anchors.bottom:         parent.bottom
        anchors.bottomMargin:   ScreenTools.smallFontPointSize * 2
        anchors.right:          parent.right
        width:                  _rightPanelWidth
        height:                 _rightPanelWidth * 0.1
        radius:                 height / 2
        color:                  Qt.rgba(0,0,0,1)
        visible:  false

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
        anchors.bottom:         parent.bottom
        anchors.bottomMargin:   _toolsMargin
        width:                  _rightPanelWidth
        height:                 _rightPanelWidth
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

    //-----------------------------------------------------------------------------------------------------
    //--Weather Widget------------------------------------------------------==-----------------------------
    // Weather Function
    function getWeatherJSON() {
        if(!_openWeatherAPIkey) {
            weatherBackground.visible = false
            return
        }

        var requestUrl = "http://api.openweathermap.org/data/2.5/weather?lat=" + QGroundControl.flightMapPosition.latitude + "&lon="
                         + QGroundControl.flightMapPosition.longitude + "&appid=" + _openWeatherAPIkey + "&lang=kr&units=metric"

        var openWeatherRequest = new XMLHttpRequest()
        openWeatherRequest.open('GET', requestUrl, true);
        openWeatherRequest.onreadystatechange = function() {
            if (openWeatherRequest.readyState === XMLHttpRequest.DONE) {
                //console.log(openWeatherRequest.status)
                if (openWeatherRequest.status && openWeatherRequest.status === 200) {
                    var openWeatherText = JSON.parse(openWeatherRequest.responseText)

                    // Debug
                    //console.log(openWeatherRequest.responseText)

                    // Weather Tab
                    cityText.text       = openWeatherText.name
                    weatherText.text    = openWeatherText.weather[0].main
                    tempText.text       = openWeatherText.main.temp
                    humiText.text       = openWeatherText.main.humidity
                    windDegreeText.text = getDirection(openWeatherText.wind.deg)
                    windSpeedText.text  = openWeatherText.wind.speed
                    visibilityText.text = openWeatherText.visibility

                } else {
                    if(!openWeatherRequest.status) {
                        // Not Internet
                        mainWindow.showMessageDialog(qsTr("Internet Not Connect."), qsTr("Check Your Internet Connection."))
                    }
                    else if(openWeatherRequest.status === 401) {
                        // Key error
                        mainWindow.showMessageDialog(qsTr("OpenWeather Key Error"), qsTr("OpenWeather Key Error. Check Your API Key."))
                        console.log(requestUrl)
                    }
                    else if(openWeatherRequest.status === 429) {
                        // Key use excess
                        mainWindow.showMessageDialog(qsTr("OpenWeather API Use Excess."), qsTr("OpenWeather API Use Excess. Make your request a little bit slower."))
                    }
                }
            }
        }
        openWeatherRequest.send()
    }

    // Degree Convert
    function getDirection(angle) {
        var directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
        var index = Math.round(((angle %= 360) < 0 ? angle + 360 : angle) / 45) % 8;
        return directions[index];
    }

//    // Get Weather on Complete
//    Component.onCompleted: {
//        getWeatherJSON()
//    }
    Rectangle {
        anchors.margins:    _toolsMargin
        anchors.right:      parent.right
        anchors.top:        parent.top
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
                anchors.fill: parent
                onClicked: {
                    getWeatherJSON()
                    _showWeatherStatus = !_showWeatherStatus
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
        id:                     weatherBackground
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top:            parent.top
        anchors.topMargin:      _toolsMargin
        width:                  _rightPanelWidth
        height:                 weatherTitle.height + weatherValue.height + (_toolsMargin * 3)
        radius:                 ScreenTools.defaultFontPixelWidth / 2
        color:                  "#80000000" //qgcPal.window
        visible:                _showWeatherStatus

        MouseArea {
            anchors.fill: parent
            onClicked: getWeatherJSON()
        }

        QGCLabel {
            id:     weatherTitle
            text:   qsTr("Weather Status")
            font.pointSize: ScreenTools.defaultFontPixelWidth * 1.2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins: _toolsMargin * 2
        }

        Rectangle {
            id:     weatherSpliter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: weatherTitle.bottom
            anchors.topMargin: _toolsMargin
            width: parent.width * 0.9
            height: 1
            color: "#ffffff"
        }

        ColumnLayout {
            id:         weatherValue
            spacing:    ScreenTools.defaultFontPixelWidth
            anchors.top: weatherSpliter.bottom
            anchors.topMargin: _toolsMargin
            anchors.horizontalCenter: parent.horizontalCenter

            // City
            Row {
                QGCLabel { Layout.alignment:   Qt.AlignHCenter;     text: qsTr("Location : ");}
                QGCLabel { id: cityText;                            Layout.alignment:   Qt.AlignHCenter;}
            }
            // Weather
            Row {
                QGCLabel { Layout.alignment:   Qt.AlignHCenter;     text: qsTr("Weather : ")}
                QGCLabel { id:                 weatherText;         Layout.alignment:   Qt.AlignHCenter}
            }
            // Temperature
            Row {
                QGCLabel { Layout.alignment:   Qt.AlignHCenter;                    text:               qsTr("Temperature : ")                }
                QGCLabel { id:                 tempText;                     Layout.alignment:   Qt.AlignHCenter                }
            }
            // Humidity
            Row {
                QGCLabel { Layout.alignment:   Qt.AlignHCenter;                     text:               qsTr("Humidity : ")                }
                QGCLabel { id:                 humiText;                    Layout.alignment:   Qt.AlignHCenter                }
            }
            // Wind Degree
            Row {
                QGCLabel { Layout.alignment:   Qt.AlignHCenter;                     text:               qsTr("Wind Direction : ")                }
                QGCLabel { id:                 windDegreeText; Layout.alignment:   Qt.AlignHCenter                }
            }
            // Wind Speed
            Row {
                QGCLabel { Layout.alignment:   Qt.AlignHCenter;                     text:               qsTr("Wind Speed : ")                }
                QGCLabel { id:                 windSpeedText;                     Layout.alignment:   Qt.AlignHCenter                }
            }
            // Visibility
            Row {
                QGCLabel { Layout.alignment:   Qt.AlignHCenter;                    text:               qsTr("Visibility : ")                }
                QGCLabel { id:                 visibilityText;                     Layout.alignment:   Qt.AlignHCenter                }
            }

            // Widget Footer
            QGCLabel {
                font.pointSize:     ScreenTools.smallFontPointSize
                Layout.alignment:   Qt.AlignHCenter
                text:               qsTr("[from OpenWeatherMap]")
            }

//            QGCLabel {
//                font.pointSize:     ScreenTools.smallFontPointSize
//                Layout.alignment:   Qt.AlignHCenter
//                text:               qsTr("(Click to Refresh)")
//            }
        }//ColumnLayout
    }
}


