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

//-------------------------------------------------------------------------
//-- PrecisionLandingIndicator
Item {
    id:             _root
    width:          (pLndIcon.x + pLndIcon.width) * 1.1
    //width:          (pLndValuesColumn.x + pLndValuesColumn.width) * 1.1
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator: true

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    Component {
        id: pLndInfo

        Rectangle {
            width:  pLndCol.width   + ScreenTools.defaultFontPixelWidth  * 3
            height: pLndCol.height  + ScreenTools.defaultFontPixelHeight * 2
            radius: ScreenTools.defaultFontPixelHeight * 0.5
            color:  qgcPal.window
            border.color:   qgcPal.text

            Column {
                id:                 pLndCol
                spacing:            ScreenTools.defaultFontPixelHeight * 0.5
                width:              Math.max(pLndGrid.width, pLndLabel.width)
                anchors.margins:    ScreenTools.defaultFontPixelHeight
                anchors.centerIn:   parent

                QGCLabel {
                    id:             pLndLabel
                    text:           (_activeVehicle && _activeVehicle.landingTarget) ? qsTr("Landing Target") : qsTr("Precision Landing Unavailable")
                    font.family:    ScreenTools.demiboldFontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                GridLayout {
                    id:                 pLndGrid
                    visible:            (_activeVehicle && _activeVehicle.gps.count.value >= 0)
                    anchors.margins:    ScreenTools.defaultFontPixelHeight
                    columnSpacing:      ScreenTools.defaultFontPixelWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 2

                    QGCLabel { text: qsTr("Angle X:") }
                    QGCLabel { text: _activeVehicle ? _activeVehicle.landingTarget.angleX.valueString : qsTr("N/A", "No data to display") }
                    QGCLabel { text: qsTr("Angle Y:") }
                    QGCLabel { text: _activeVehicle ? _activeVehicle.landingTarget.angleY.valueString : qsTr("N/A", "No data to display") }
                }
            }
        }
    }

    QGCColoredImage {
        id:                 pLndIcon
        width:              height
        anchors.top:        parent.top
        anchors.bottom:     parent.bottom
        source:             "/qmlimages/PrecisionLanding.svg"
        fillMode:           Image.PreserveAspectFit
        sourceSize.height:  height
        //opacity:            (_activeVehicle && _activeVehicle.gps.count.value >= 0) ? 1 : 0.5
        //color:              (_activeVehicle && _activeVehicle.gps.lock.value >= 3) ? qgcPal.colorGreen : qgcPal.buttonText
        color:              (_activeVehicle && _activeVehicle.landingTarget) ? qgcPal.colorGreen : qgcPal.buttonText
    }

//    Column {
//        id:                     gpsValuesColumn
//        anchors.verticalCenter: parent.verticalCenter
//        anchors.leftMargin:     ScreenTools.defaultFontPixelWidth / 2
//        anchors.left:           gpsIcon.right

//        QGCLabel {
//            anchors.horizontalCenter:   hdopValue.horizontalCenter
//            visible:                    _activeVehicle && !isNaN(_activeVehicle.gps.hdop.value)
//            color:                      qgcPal.buttonText
//            text:                       _activeVehicle ? _activeVehicle.gps.count.valueString : ""
//        }

//        QGCLabel {
//            id:         hdopValue
//            visible:    _activeVehicle && !isNaN(_activeVehicle.gps.hdop.value)
//            color:      qgcPal.buttonText
//            text:       _activeVehicle ? _activeVehicle.gps.hdop.value.toFixed(1) : ""
//        }
//    }

    MouseArea {
        anchors.fill:   parent
        onClicked: {
            mainWindow.showIndicatorPopup(_root, pLndInfo)
        }
    }
}
