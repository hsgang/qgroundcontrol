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
    property var totalToolInsets:   _toolInsets // These are the insets for your custom overlay additions
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

    // Property of Vibration visible
    property var _vibeStatusVisible:        false

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

    // Get Weather on Complete
    Component.onCompleted: {
        getWeatherJSON()
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
        height:                 ScreenTools.defaultFontPixelHeight * 9
        width:                  height
        radius:                 height * 0.5
        color:                  "#80000000"

        CustomAttitudeHUD {
            size:               parent.height
            vehicle:            _activeVehicle
        }

        states:[
            State {
                name: "telemetrybarSide"
                when: telemetryPanel.bottomMode
                AnchorChanges {
                    target: attitudeIndicator
                    //anchors.top: undefined
                    //anchors.bottom: parent.bottom
                    anchors.left: telemetryPanel.right
                    //anchors.verticalCenter: undefined
                }
            },
            State {
                name: "parentCenter"
                when: telemetryPanel.bottomMode
                AnchorChanges {
                    target: attitudeIndicator
                    //anchors.top: undefined
                    anchors.bottom: parent.bottom
                    //anchors.left: telemetryPanel.right
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        ]
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
    Rectangle {
        id:                     weatherBackground
        anchors.right:          parent.right
        anchors.rightMargin:     _toolsMargin
        anchors.bottom:         parent.bottom
        anchors.bottomMargin:   _toolsMargin
        width:                  _rightPanelWidth
        height:                 weatherValue.height + _toolsMargin
        radius:                 ScreenTools.defaultFontPixelWidth / 2
        color:                  "#80000000" //qgcPal.window
        visible:                QGroundControl.settingsManager.appSettings.enableOpenWeatherAPI.rawValue

        MouseArea {
            anchors.fill: parent
            onClicked: getWeatherJSON()
        }

        ColumnLayout {
            id:         weatherValue
            spacing:    ScreenTools.defaultFontPixelWidth
            anchors.centerIn: parent

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


