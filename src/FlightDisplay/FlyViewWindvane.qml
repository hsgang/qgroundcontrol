import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.FlightMap

Rectangle {
    id: root
    height: columnLayout.height + _toolsMargin * 2
    width:  columnLayout.width + _toolsMargin * 2
    color:  Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.9)
    radius: ScreenTools.defaultFontPixelHeight / 2

    property var  vehicle:      null

    property real   size:         _defaultSize
    property real   _defaultSize: ScreenTools.defaultFontPixelHeight * 7
    property real   _sizeRatio:   ScreenTools.isTinyScreen ? (size / _defaultSize) * 0.5 : size / _defaultSize
    property int    _fontSize:    ScreenTools.defaultFontPointSize * _sizeRatio

    property real   _temperature:   vehicle ? vehicle.atmosphericSensor.temperature.rawValue : NaN
    property real   _humidity:      vehicle ? vehicle.atmosphericSensor.humidity.rawValue : NaN
    property real   _pressure:      vehicle ? vehicle.atmosphericSensor.pressure.rawValue : NaN
    property real   _windDir:       vehicle ? vehicle.atmosphericSensor.windDir.rawValue : NaN
    property real   _windSpd:       vehicle ? vehicle.atmosphericSensor.windSpd.rawValue : NaN
    property real   _pm1p0:         vehicle ? vehicle.atmosphericSensor.opc1.rawValue : NaN
    property real   _pm2p5:         vehicle ? vehicle.atmosphericSensor.opc2.rawValue : NaN
    property real   _pm10:          vehicle ? vehicle.atmosphericSensor.opc3.rawValue : NaN
    property real   _radiation:     vehicle ? vehicle.atmosphericSensor.radiation.rawValue : NaN
    property real   _hubTemp1:      vehicle ? vehicle.atmosphericSensor.hubTemp1.rawValue : NaN
    property real   _hubTemp2:      vehicle ? vehicle.atmosphericSensor.hubTemp2.rawValue : NaN
    property real   _hubHumi1:      vehicle ? vehicle.atmosphericSensor.hubHumi1.rawValue : NaN
    property real   _hubHumi2:      vehicle ? vehicle.atmosphericSensor.hubHumi2.rawValue : NaN
    property real   _hubPressure:   vehicle ? vehicle.atmosphericSensor.hubPressure.rawValue : NaN
    property real   _batt:          vehicle ? vehicle.atmosphericSensor.batt.rawValue : NaN
    property string _temperatureText: !isNaN(_temperature)  ? _temperature.toFixed(2) : "--.-"
    property string _humidityText:    !isNaN(_humidity)     ? _humidity.toFixed(2)    : "--.-"
    property string _pressureText:    !isNaN(_pressure)     ? _pressure.toFixed(2)    : "----.-"
    property string _windDirText:     !isNaN(_windDir)      ? _windDir.toFixed(0)     : "---"
    property string _windSpdText:     !isNaN(_windSpd)      ? _windSpd.toFixed(1)     : "--.-"
    property string _pm1p0Text:       !isNaN(_pm1p0)        ? _pm1p0.toFixed(0)       : "-.-"
    property string _pm2p5Text:       !isNaN(_pm2p5)        ? _pm2p5.toFixed(0)       : "-.-"
    property string _pm10Text:        !isNaN(_pm10)         ? _pm10.toFixed(0)        : "-.-"
    property string _radiationText:   !isNaN(_radiation)    ? _radiation.toFixed(0)   : "-.-"
    property string _hubTemp1Text:    !isNaN(_hubTemp1)     ? _hubTemp1.toFixed(2)    : "--.-"
    property string _hubTemp2Text:    !isNaN(_hubTemp2)     ? _hubTemp2.toFixed(2)    : "--.-"
    property string _hubHumi1Text:    !isNaN(_hubHumi1)     ? _hubHumi1.toFixed(2)    : "--.-"
    property string _hubHumi2Text:    !isNaN(_hubHumi2)     ? _hubHumi2.toFixed(2)    : "--.-"
    property string _hubPressureText: !isNaN(_hubPressure)  ? _hubPressure.toFixed(2) : "----.-"
    property string _battText:        !isNaN(_batt)         ? _batt.toFixed(0)        : "---"

    function isWindVaneOK(){
        return vehicle && !isNaN(_windDir)
    }

    ColumnLayout {
        id: columnLayout
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            id:         windvaneView
            height:     size
            width:      size
            color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.9)
            radius:     size / 2
            border.color: qgcPal.text



            CompassDial {
                id: compassDial
                anchors.fill:   parent
            }

            Image {
                id:                 windvaneExternal
                source:             isWindVaneOK() ? "/qmlimages/windVaneArrow.svg" : ""
                mipmap:             true
                fillMode:           Image.PreserveAspectFit
                anchors.fill:       parent
                sourceSize.height:  parent.height

                transform: Rotation {
                    origin.x:       windvaneExternal.width  / 2
                    origin.y:       windvaneExternal.height / 2
                    angle:          _windDir
                }
            }

            Rectangle {
                height: windvaneInnerColumn.height + _toolsMargin * 2
                width: windvaneInnerColumn.width + _toolsMargin * 2
                color: "transparent"
                radius: ScreenTools.defaultFontPixelHeight / 4
                border.color: Qt.rgba(qgcPal.text.r, qgcPal.text.g, qgcPal.text.b, 0.5)
                anchors.centerIn: parent

                ColumnLayout {
                    id: windvaneInnerColumn
                    anchors.centerIn: parent

                    QGCLabel {
                        Layout.alignment:       Qt.AlignHCenter
                        text:                   _windSpdText + "㎧"
                        horizontalAlignment:    Text.AlignHCenter
                        font.pointSize:         ScreenTools.defaultFontPointSize * 1.2
                    }
                    QGCLabel {
                        Layout.alignment:       Qt.AlignHCenter
                        text:                   _windDirText + "°"
                        horizontalAlignment:    Text.AlignHCenter
                        font.pointSize:         ScreenTools.defaultFontPointSize * 1.2
                    }
                }
            }
        }

        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            columns:    3
            rows:       10
            flow:       GridLayout.TopToBottom
            rowSpacing: 0

            QGCLabel {
                text:                   "풍속"
                horizontalAlignment:    Text.AlignHCenter
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   "풍향"
                horizontalAlignment:    Text.AlignHCenter
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   "기온[1]"
                horizontalAlignment:    Text.AlignHCenter
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   "기온[2]"
                horizontalAlignment:    Text.AlignHCenter
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   "기온[3]"
                horizontalAlignment:    Text.AlignHCenter
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   "습도[1]"
                horizontalAlignment:    Text.AlignHCenter
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   "습도[2]"
                horizontalAlignment:    Text.AlignHCenter
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   "습도[3]"
                horizontalAlignment:    Text.AlignHCenter
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   "기압[1]"
                horizontalAlignment:    Text.AlignHCenter
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   "기압[2]"
                horizontalAlignment:    Text.AlignHCenter
                Layout.fillWidth: true
            }

            QGCLabel {
                text:                   _windSpdText
                horizontalAlignment:    Text.AlignRight
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   _windDirText
                horizontalAlignment:    Text.AlignRight
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   _temperatureText
                horizontalAlignment:    Text.AlignRight
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   _hubTemp1Text
                horizontalAlignment:    Text.AlignRight
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   _hubTemp2Text
                horizontalAlignment:    Text.AlignRight
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   _humidityText
                horizontalAlignment:    Text.AlignRight
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   _hubHumi1Text
                horizontalAlignment:    Text.AlignRight
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   _hubHumi2Text
                horizontalAlignment:    Text.AlignRight
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   _pressureText
                horizontalAlignment:    Text.AlignRight
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   _hubPressureText
                horizontalAlignment:    Text.AlignRight
                Layout.fillWidth: true
            }

            QGCLabel {
                text:                   "㎧"
                horizontalAlignment:    Text.AlignLeft
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   "°"
                horizontalAlignment:    Text.AlignLeft
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   "℃"
                horizontalAlignment:    Text.AlignLeft
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   "℃"
                horizontalAlignment:    Text.AlignLeft
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   "℃"
                horizontalAlignment:    Text.AlignLeft
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   "Rh%"
                horizontalAlignment:    Text.AlignLeft
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   "Rh%"
                horizontalAlignment:    Text.AlignLeft
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   "Rh%"
                horizontalAlignment:    Text.AlignLeft
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   "hPa"
                horizontalAlignment:    Text.AlignLeft
                Layout.fillWidth: true
            }
            QGCLabel {
                text:                   "hPa"
                horizontalAlignment:    Text.AlignLeft
                Layout.fillWidth: true
            }

        }

        QGCLabel {
            Layout.alignment: Qt.AlignHCenter
            text:           "HUB_Batt " + _battText + " %"
        }

        // Rectangle {
        //     width:  externalsensorviewlayout.width * 1.1
        //     height: externalsensorviewlayout.height * 1.1
        //     color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.7)
        //     radius:     ScreenTools.defaultFontPixelHeight / 4

        //     ColumnLayout {
        //         id: externalsensorviewlayout
        //         anchors.horizontalCenter: parent.horizontalCenter
        //         anchors.verticalCenter: parent.verticalCenter
        //         spacing:                ScreenTools.defaultFontPixelWidth * 0.4
        //         QGCLabel {
        //             text:           "미세먼지 정보"
        //         }
        //         QGCLabel {
        //             text:           "PM1.0 : " + _pm1p0Text + "g/㎥"
        //         }
        //         QGCLabel {
        //             text:           "PM2.5 : " + _pm2p5Text + "g/㎥"
        //         }
        //         QGCLabel {
        //             text:           "PM10 : " + _pm10Text + "g/㎥"
        //         }
        //         QGCLabel {
        //             text:           "방사선량 정보"
        //         }
        //         QGCLabel {
        //             text:           "선량 : " + _radiationText
        //         }
        //     }
        // }
    }
}

