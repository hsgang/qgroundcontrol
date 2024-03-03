import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Vehicle
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.Palette
import QGroundControl.FlightMap

Rectangle {
    id:         windvaneView

    property var  vehicle:      null

    property real size:         _defaultSize
    property real _defaultSize: ScreenTools.defaultFontPixelHeight * (10)
    property real _sizeRatio:   ScreenTools.isTinyScreen ? (size / _defaultSize) * 0.5 : size / _defaultSize
    property int  _fontSize:    ScreenTools.defaultFontPointSize * _sizeRatio

    property real   _windDir:       vehicle ? vehicle.wind.direction.rawValue : 0
    property real   _windSpd:       vehicle ? vehicle.wind.speed.rawValue : 0
    property string _windSpdText:   vehicle ? + _windSpd.toFixed(1) + " (Est.)" : "0.0"
    property real   _temperature:   vehicle ? vehicle.atmosphericSensor.temperature.rawValue.toFixed(1) : 0
    property real   _humidity:      vehicle ? vehicle.atmosphericSensor.humidity.rawValue.toFixed(1) : 0
    property real   _pressure:      vehicle ? vehicle.atmosphericSensor.pressure.rawValue.toFixed(1) : 0
    property real   _atmosWindDir:  vehicle ? vehicle.atmosphericSensor.windDir.rawValue.toFixed(1) : 0
    property real   _atmosWindSpd:  vehicle ? vehicle.atmosphericSensor.windSpd.rawValue.toFixed(1) : 0
    property string _atmosWindSpdText: vehicle ? _atmosWindSpd.toFixed(1) : "0.0"

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

    Column{
        anchors.horizontalCenter:   parent.horizontalCenter
        anchors.verticalCenter:     parent.verticalCenter

        QGCLabel {
            anchors.horizontalCenter:   parent.horizontalCenter
            text:                       vehicle ? "TMP: "+ _temperature.toFixed(1) + " ℃" : "TMP: -- ℃"
            horizontalAlignment:        Text.AlignHCenter
        }
        QGCLabel {
            anchors.horizontalCenter:   parent.horizontalCenter
            text:                       vehicle ? "HMD: "+ _humidity.toFixed(1) + " Rh%" : "HMD: -- Rh%"
            horizontalAlignment:        Text.AlignHCenter
        }
        QGCLabel {
            anchors.horizontalCenter:   parent.horizontalCenter
            text:                       vehicle ? "PRS: "+ _pressure.toFixed(1) + " hPa" : "PRS: -- hPa"
            horizontalAlignment:        Text.AlignHCenter
        }
        QGCLabel {
            anchors.horizontalCenter:   parent.horizontalCenter
            text:                       vehicle ? "FCWD: "+ _pressure.toFixed(1) + " °" : "FCWD: -- °"
            horizontalAlignment:        Text.AlignHCenter
        }
        QGCLabel {
            anchors.horizontalCenter:   parent.horizontalCenter
            text:                       vehicle ? "EXWD: "+ _pressure.toFixed(1) + " °" : "FCWD: -- °"
            horizontalAlignment:        Text.AlignHCenter
        }
    }
}

