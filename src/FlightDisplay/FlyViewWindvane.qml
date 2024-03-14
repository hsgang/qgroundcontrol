import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts  1.2
import QtQuick.Dialogs  1.2

import QGroundControl                   1.0
import QGroundControl.Vehicle           1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.Controls          1.0
import QGroundControl.FactControls      1.0
import QGroundControl.Palette           1.0
import QGroundControl.FlightMap         1.0

Rectangle {
    id:         windvaneView

    property var  vehicle:      null

    property real size:         _defaultSize
    property real _defaultSize: ScreenTools.defaultFontPixelHeight * (10)
    property real _sizeRatio:   ScreenTools.isTinyScreen ? (size / _defaultSize) * 0.5 : size / _defaultSize
    property int  _fontSize:    ScreenTools.defaultFontPointSize * _sizeRatio

    property real   _windDir:       vehicle ? vehicle.wind.direction.rawValue : NaN
    property real   _windSpd:       vehicle ? vehicle.wind.speed.rawValue : NaN
    property real   _temperature:   vehicle ? vehicle.atmosphericSensor.temperature.rawValue : NaN
    property real   _humidity:      vehicle ? vehicle.atmosphericSensor.humidity.rawValue : NaN
    property real   _pressure:      vehicle ? vehicle.atmosphericSensor.pressure.rawValue : NaN
    property real   _atmosWindDir:  vehicle ? vehicle.atmosphericSensor.windDir.rawValue : NaN
    property real   _atmosWindSpd:  vehicle ? vehicle.atmosphericSensor.windSpd.rawValue : NaN
    property string _temperatureText: !isNaN(_temperature)  ? _temperature.toFixed(1)   + " ℃"      : "--.- ℃"
    property string _humidityText:    !isNaN(_humidity)     ? _humidity.toFixed(1)      + " Rh%"    : "--.- Rh%"
    property string _pressureText:    !isNaN(_pressure)     ? _pressure.toFixed(1)      + " hPa"    : "----.- hPa"
    property string _windDirText:     !isNaN(_windDir)      ? _windDir.toFixed(0)       + " °"      : "-- °"
    property string _windSpdText:     !isNaN(_windSpd)      ? _windSpd.toFixed(1)       + " (Est.)" : "-.- (Est.)"
    property string _atmosWindDirText:!isNaN(_atmosWindDir) ? _atmosWindDir.toFixed(0)  + " °"      : "-- °"
    property string _atmosWindSpdText:!isNaN(_atmosWindSpd) ? _atmosWindSpd.toFixed(1)              : "-.-"

    height:     size
    width:      size
    color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.9)
    radius:     size / 2
    border.color: qgcPal.text

    function isWindVaneOK(){
        return vehicle && !isNaN(_windDir)
    }

    function isExternalWindVaneOK(){
        return vehicle && !isNaN(_atmosWindDir)
    }

    CompassDial {
        id: compassDial
        anchors.fill:   parent
    }

    Image {
        id:                 windvane
        source:             isWindVaneOK() ? "/qmlimages/windVaneArrow.svg" : ""
        mipmap:             true
        fillMode:           Image.PreserveAspectFit
        anchors.fill:       parent
        sourceSize.height:  parent.height

        transform: Rotation {
            origin.x:       windvane.width  / 2
            origin.y:       windvane.height / 2
            angle:          _windDir
        }
    }

    Rectangle {
        width:                      windVaneText.width + (size * 0.05)
        height:                     size * 0.12
        border.color:               qgcPal.colorGreen
        color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.9)
        radius:                     height * 0.2
        visible:                    isWindVaneOK()
        anchors.centerIn:           parent

        QGCLabel {
            id:                 windVaneText
            text:               _windSpdText
            font.pointSize:     _fontSize < 8 ? 8 : _fontSize;
            font.family:        ScreenTools.demiboldFontFamily
            color:              qgcPal.text
            anchors.centerIn:   parent
        }

        transform: Translate {
            x: size/2.4 * Math.sin((_windDir)*(3.14/180))
            y: - size/2.4 * Math.cos((_windDir)*(3.14/180)) + windVaneText.height * 1.1
        }
    }

    Image {
        id:                 windvaneExternal
        source:             isExternalWindVaneOK() ? "/qmlimages/windVaneArrow.svg" : ""
        mipmap:             true
        fillMode:           Image.PreserveAspectFit
        anchors.fill:       parent
        sourceSize.height:  parent.height

        transform: Rotation {
            origin.x:       windvaneExternal.width  / 2
            origin.y:       windvaneExternal.height / 2
            angle:          _atmosWindDir
        }
    }

    Rectangle {
        width:                      windVaneExternalText.width + (size * 0.05)
        height:                     size * 0.12
        border.color:               qgcPal.colorGreen
        color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.9)
        radius:                     height * 0.2
        visible:                    isExternalWindVaneOK()
        anchors.centerIn:           parent

        QGCLabel {
            id:                 windVaneExternalText
            text:               _atmosWindSpdText
            font.pointSize:     _fontSize < 8 ? 8 : _fontSize;
            font.family:        ScreenTools.demiboldFontFamily
            color:              qgcPal.text
            anchors.centerIn:   parent
        }

        transform: Translate {
            x: size/2.4 * Math.sin((_atmosWindDir)*(3.14/180))
            y: - size/2.4 * Math.cos((_atmosWindDir)*(3.14/180)) + windVaneExternalText.height * 1.1
        }
    }

    GridLayout {
        columns:    2
        rows:       5
        flow:       GridLayout.TopToBottom
        anchors.horizontalCenter:   parent.horizontalCenter
        anchors.verticalCenter:     parent.verticalCenter

        QGCLabel {
            text:                   "TMP"
            horizontalAlignment:    Text.AlignHCenter
            font.pointSize:         ScreenTools.defaultFontPointSize * 0.8
        }
        QGCLabel {
            text:                   "HMD"
            horizontalAlignment:    Text.AlignHCenter
            font.pointSize:         ScreenTools.defaultFontPointSize * 0.8
        }
        QGCLabel {
            text:                   "PRS"
            horizontalAlignment:    Text.AlignHCenter
            font.pointSize:         ScreenTools.defaultFontPointSize * 0.8
        }
        QGCLabel {
            text:                   "FCWD"
            horizontalAlignment:    Text.AlignHCenter
            font.pointSize:         ScreenTools.defaultFontPointSize * 0.8
        }
        QGCLabel {
            text:                   "EXWD"
            horizontalAlignment:    Text.AlignHCenter
            font.pointSize:         ScreenTools.defaultFontPointSize * 0.8
        }

        QGCLabel {
            text:                   vehicle ? _temperatureText : "unknown"
            horizontalAlignment:    Text.AlignHCenter
        }
        QGCLabel {
            text:                   vehicle ? _humidityText : "unknown"
            horizontalAlignment:    Text.AlignHCenter
        }
        QGCLabel {
            text:                   vehicle ? _pressureText : "unknown"
            horizontalAlignment:    Text.AlignHCenter
        }
        QGCLabel {
            text:                   vehicle ? _windDirText  : "unknown"
            horizontalAlignment:    Text.AlignHCenter
        }
        QGCLabel {
            text:                   vehicle ? _atmosWindDirText : "unknown"
            horizontalAlignment:    Text.AlignHCenter
        }
    }
}

