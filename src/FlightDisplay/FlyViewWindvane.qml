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
    color:  "transparent" //Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.9)
    radius: ScreenTools.defaultFontPixelHeight / 2

    property var    _activeVehicle:          QGroundControl.multiVehicleManager.activeVehicle

    property real   size:         _defaultSize
    property real   _defaultSize: ScreenTools.defaultFontPixelHeight * 7
    property real   _sizeRatio:   ScreenTools.isTinyScreen ? (size / _defaultSize) * 0.5 : size / _defaultSize
    property int    _fontSize:    ScreenTools.defaultFontPointSize * _sizeRatio

    property real   _logCount:      _activeVehicle ? _activeVehicle.atmosphericSensor.logCount.rawValue : NaN
    property real   _temperature:   _activeVehicle ? _activeVehicle.atmosphericSensor.temperature.rawValue : NaN
    property real   _humidity:      _activeVehicle ? _activeVehicle.atmosphericSensor.humidity.rawValue : NaN
    property real   _pressure:      _activeVehicle ? _activeVehicle.atmosphericSensor.pressure.rawValue : NaN
    property real   _windDir:       _activeVehicle ? _activeVehicle.atmosphericSensor.windDir.rawValue : NaN
    property real   _windSpd:       _activeVehicle ? _activeVehicle.atmosphericSensor.windSpd.rawValue : NaN
    property real   _pm1p0:         _activeVehicle ? _activeVehicle.atmosphericSensor.opc1.rawValue : NaN
    property real   _pm2p5:         _activeVehicle ? _activeVehicle.atmosphericSensor.opc2.rawValue : NaN
    property real   _pm10:          _activeVehicle ? _activeVehicle.atmosphericSensor.opc3.rawValue : NaN
    property real   _radiation:     _activeVehicle ? _activeVehicle.atmosphericSensor.radiation.rawValue : NaN
    property real   _hubTemp1:      _activeVehicle ? _activeVehicle.atmosphericSensor.hubTemp1.rawValue : NaN
    property real   _hubTemp2:      _activeVehicle ? _activeVehicle.atmosphericSensor.hubTemp2.rawValue : NaN
    property real   _hubHumi1:      _activeVehicle ? _activeVehicle.atmosphericSensor.hubHumi1.rawValue : NaN
    property real   _hubHumi2:      _activeVehicle ? _activeVehicle.atmosphericSensor.hubHumi2.rawValue : NaN
    property real   _hubPressure:   _activeVehicle ? _activeVehicle.atmosphericSensor.hubPressure.rawValue : NaN
    property real   _batt:          _activeVehicle ? _activeVehicle.atmosphericSensor.batt.rawValue : NaN
    property real   _sdVolume:      _activeVehicle ? _activeVehicle.atmosphericSensor.sdVolume.rawValue : NaN
    property var    _timeHMS:       _activeVehicle ? _activeVehicle.atmosphericSensor.timeHMS.rawValue : "--:--:--"
    
    property string _logCountText:    !isNaN(_logCount)     ? _logCount.toFixed(0)     : "--"
    property string _temperatureText: !isNaN(_temperature)  ? _temperature.toFixed(2) + " ℃" : "--.- ℃"
    property string _humidityText:    !isNaN(_humidity)     ? _humidity.toFixed(2) + " Rh%" : "--.- Rh%"
    property string _pressureText:    !isNaN(_pressure)     ? _pressure.toFixed(2) + " hPa" : "----.- hPa"
    property string _windDirText:     !isNaN(_windDir)      ? _windDir.toFixed(0) + " °" : "--- °"
    property string _windSpdText:     !isNaN(_windSpd)      ? _windSpd.toFixed(1) + " ㎧" : "--.- ㎧"
    property string _pm1p0Text:       !isNaN(_pm1p0)        ? _pm1p0.toFixed(0)       : "-.-"
    property string _pm2p5Text:       !isNaN(_pm2p5)        ? _pm2p5.toFixed(0)       : "-.-"
    property string _pm10Text:        !isNaN(_pm10)         ? _pm10.toFixed(0)        : "-.-"
    property string _radiationText:   !isNaN(_radiation)    ? _radiation.toFixed(0)   : "-.-"
    property string _hubTemp1Text:    !isNaN(_hubTemp1)     ? _hubTemp1.toFixed(2) + " ℃" : "--.- ℃"
    property string _hubTemp2Text:    !isNaN(_hubTemp2)     ? _hubTemp2.toFixed(2) + " ℃" : "--.- ℃"
    property string _hubHumi1Text:    !isNaN(_hubHumi1)     ? _hubHumi1.toFixed(2) + " Rh%" : "--.- Rh%"
    property string _hubHumi2Text:    !isNaN(_hubHumi2)     ? _hubHumi2.toFixed(2) + " Rh%" : "--.- Rh%"
    property string _hubPressureText: !isNaN(_hubPressure)  ? _hubPressure.toFixed(2) + " hPa" : "----.- hPa"
    property string _battText:        !isNaN(_batt)         ? _batt.toFixed(0) + " %" : "--- %"
    property string _sdVolumeText:    _sdVolume > 0         ? _sdVolume.toFixed(2) + " GB" : "Error"
    property string _timeHMSText:     _timeHMS !== ""      ? _timeHMS : "--:--:--"

    function isWindVaneOK(){
        return _activeVehicle && !isNaN(_windDir)
    }

    RowLayout {
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
            Layout.alignment: Qt.AlignTop

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
                        text:                   _windSpdText
                        horizontalAlignment:    Text.AlignHCenter
                        font.pointSize:         ScreenTools.defaultFontPointSize * 1.2
                    }
                    QGCLabel {
                        Layout.alignment:       Qt.AlignHCenter
                        text:                   _windDirText
                        horizontalAlignment:    Text.AlignHCenter
                        font.pointSize:         ScreenTools.defaultFontPointSize * 1.2
                    }
                }
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignTop
            height:     valueGridLayout.height + _toolsMargin * 2
            width:      valueGridLayout.width + _toolsMargin * 2
            color:      qgcPal.windowTransparent
            radius:     _toolsMargin
            border.color: qgcPal.groupBorder

            ColumnLayout {
                id: valueGridLayout
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                //Layout.alignment: Qt.AlignHCenter
                //Layout.fillWidth: true
                // rows:       6
                // flow:       GridLayout.TopToBottom
                // rowSpacing: ScreenTools.defaultFontPixelHeight / 4
                // columnSpacing: ScreenTools.defaultFontPixelHeight / 2

                // LabelledLabel {
                //     label:      "풍속"
                //     labelText: _windSpdText
                // }
                // LabelledLabel {
                //     label:      "풍향"
                //     labelText: _windDirText
                // }
                LabelledLabel {
                    label:      "SHT_Temp"
                    labelText: _temperatureText
                }
                LabelledLabel {
                    label:      "HUB_Temp1"
                    labelText: _hubTemp1Text
                }
                LabelledLabel {
                    label:      "HUB_Temp2"
                    labelText: _hubTemp2Text
                }
                LabelledLabel {
                    label:      "SHT_Humi"
                    labelText: _humidityText
                }
                LabelledLabel {
                    label:      "HUB_Humi1"
                    labelText: _hubHumi1Text
                }
                LabelledLabel {
                    label:      "HUB_Humi2"
                    labelText: _hubHumi2Text
                }
                LabelledLabel {
                    label:      "Pressure"
                    labelText: _pressureText
                }
                LabelledLabel {
                    label:      "HUB_Pres"
                    labelText: _hubPressureText
                }
                Rectangle {
                    height: 1
                    Layout.fillWidth: true
                    color: qgcPal.groupBorder
                }
                LabelledLabel {
                    label:      "HUB_Batt"
                    labelText: _battText
                }
                LabelledLabel {
                    label:      "SD_Volume"
                    labelText: _sdVolumeText
                }
                LabelledLabel {
                    label:      "Time"
                    labelText: _timeHMSText
                }
                LabelledLabel {
                    label:      "LogCount"
                    labelText: _logCountText
                }
            }
        }
    }
}

