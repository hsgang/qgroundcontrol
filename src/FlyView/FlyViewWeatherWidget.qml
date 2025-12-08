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
import QtQuick.Layouts

import QtQuick.Window
import QtQml.Models

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.Palette
import QGroundControl.ScreenTools

Rectangle {
    id:                     weatherBackground
    width:                  ScreenTools.defaultFontPixelWidth * 30
    height:                 weatherTitle.height + weatherValue.height + (_toolsMargin * 3)
    radius:                 ScreenTools.defaultFontPixelWidth / 2
    color:                  Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
    border.color:           qgcPal.text
    border.width:           1

    // Property of Tools
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property color  _baseBGColor:           qgcPal.window

    // Property OpenWeather API Key
    property string _openWeatherAPIkey:     QGroundControl.settingsManager ? QGroundControl.settingsManager.appSettings.openWeatherApiKey.value : null
    property string timeString
    property bool   _showWeatherStatus:     false

    //-----------------------------------------------------------------------------------------------------
    //--Weather Widget------------------------------------------------------==-----------------------------
    // Weather Function
    function getWeatherJSON() {
        if(!_openWeatherAPIkey) {
            //weatherBackground.visible = false
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

    MouseArea {
        anchors.fill: parent
        onClicked: getWeatherJSON()
    }

    QGCLabel {
        id:     weatherTitle
        text:   qsTr("Weather Status")
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

//        // Widget Footer
//        QGCLabel {
//            font.pointSize:     ScreenTools.smallFontPointSize
//            Layout.alignment:   Qt.AlignHCenter
//            text:               qsTr("[from OpenWeatherMap]")
//        }
    }
}


