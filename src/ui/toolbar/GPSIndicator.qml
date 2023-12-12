/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.11
import QtQuick.Layouts  1.11

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.FactControls          1.0

//-------------------------------------------------------------------------
//-- GPS Indicator
Item {
    id:             _root
    width:          gnssValuesRow.width//(gnssValuesRow.x + gnssValuesRow.width)// * 1.1
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator: true

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    property bool isGNSS2: _activeVehicle.gps2.lock.value

    function getGpsImage() {
        if (_activeVehicle.gps.lock.value) {
            switch (_activeVehicle.gps.lock.value) {
            case 0:
                return "/qmlimages/GPS_None.svg"
            case 1:
                return "/qmlimages/GPS_NoFix.svg"
            case 2:
                return "/qmlimages/GPS_2DFix.svg"
            case 3:
                return "/qmlimages/GPS_3DFix.svg"
            case 4:
                return "/qmlimages/GPS_DGPS.svg"
            case 5:
                return "/qmlimages/GPS_Float.svg"
            case 6:
                return "/qmlimages/GPS_RTK.svg"
            default:
                return "/qmlimages/Gps.svg"
            }
        }
        else{
            return "/qmlimages/GPS_None.svg"
        }
    }

    function getGpsLock() {
        if (_activeVehicle.gps.lock.value) {
            switch (_activeVehicle.gps.lock.value) {
            case 0:
                return "None"
            case 1:
                return "NoFix"
            case 2:
                return "2D"
            case 3:
                return "3D"
            case 4:
                return "DGPS"
            case 5:
                return "Float"
            case 6:
                return "RTK"
            default:
                return "GPS"
            }
        }
        else{
            return "None"
        }
    }

    function getGps2Lock() {
        if (_activeVehicle.gps2.lock.value) {
            switch (_activeVehicle.gps2.lock.value) {
            case 0:
                return "None"
            case 1:
                return "NoFix"
            case 2:
                return "2D"
            case 3:
                return "3D"
            case 4:
                return "DGPS"
            case 5:
                return "Float"
            case 6:
                return "RTK"
            default:
                return "GPS"
            }
        }
        else{
            return "None"
        }
    }

    Row {
        id:             gnssValuesRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom

        spacing: ScreenTools.defaultFontPixelHeight / 5

        QGCColoredImage {
            id:                 gpsIcon
            width:              height
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            source:             "/qmlimages/Gps.svg" //getGpsImage()
            fillMode:           Image.PreserveAspectFit
            sourceSize.height:  height * 0.9
            opacity:            (_activeVehicle && _activeVehicle.gps.count.value >= 0) ? 1 : 0.5
            color:              (_activeVehicle && _activeVehicle.gps.lock.value >= 3) ? qgcPal.buttonText : qgcPal.colorOrange

            Rectangle {
                visible:        QGroundControl.ntrip.connected
                width:          ScreenTools.defaultFontPixelHeight * 0.9
                height:         width
                color:          Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5)
                border.color:   (QGroundControl.ntrip.bandWidth > 0) ? qgcPal.colorGreen : qgcPal.text
                border.width:   2
                radius:         ScreenTools.defaultFontPixelHeight / 5
                anchors.left:   parent.left
                anchors.bottom: parent.bottom

                QGCLabel {
                    text:                       "N"
                    font.bold:                  true
                    color:                      (QGroundControl.ntrip.bandWidth > 0) ? qgcPal.colorGreen : qgcPal.text
                    anchors.horizontalCenter:   parent.horizontalCenter
                    anchors.verticalCenter:     parent.verticalCenter
                }
            }
        }

        Column {
            id:                     gpsValuesColumn
            anchors.verticalCenter: parent.verticalCenter

            QGCLabel {
                anchors.left:   parent.left
                color:          qgcPal.buttonText
                font.pointSize: ScreenTools.smallFontPointSize
                text:           _activeVehicle ? getGpsLock() : ""
            }

            QGCLabel {
                id:             hdopValue
                anchors.left:   parent.left
                color:          qgcPal.buttonText
                text:           _activeVehicle ? _activeVehicle.gps.count.valueString : ""
            }
        }

        Column {
            id:                     gps2ValuesColumn
            visible:                isGNSS2
            anchors.verticalCenter: parent.verticalCenter

            QGCLabel {
                anchors.left:   parent.left
                color:          qgcPal.buttonText
                font.pointSize: ScreenTools.smallFontPointSize
                text:           _activeVehicle ? getGps2Lock() : ""
            }

            QGCLabel {
                id:             gps2hdopValue
                anchors.left:   parent.left
                color:          qgcPal.buttonText
                text:           _activeVehicle ? _activeVehicle.gps2.count.valueString : ""
            }
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorDrawer(gpsIndicatorPage)
    }

    Component {
        id: gpsIndicatorPage

        GPSIndicatorPage {

        }
    }
}
