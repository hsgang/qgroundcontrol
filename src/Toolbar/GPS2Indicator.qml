import QtQuick          2.11
import QtQuick.Layouts  1.11

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0

//-------------------------------------------------------------------------
//-- GPS Indicator
Item {
    id:             _root
    width:          (gps2ValuesColumn.x + gps2ValuesColumn.width) * 1.1
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator: _activeVehicle.gps2.lock.value

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    function getGpsImage() {
        if (_activeVehicle.gps2.lock.value) {
            switch (_activeVehicle.gps2.lock.value) {
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

    Component {
        id: gps2Info

        Rectangle {
            width:  gps2Col.width   + ScreenTools.defaultFontPixelWidth  * 3
            height: gps2Col.height  + ScreenTools.defaultFontPixelHeight * 2
            radius: ScreenTools.defaultFontPixelHeight * 0.5
            color:  qgcPal.window
            border.color:   qgcPal.text

            Column {
                id:                 gps2Col
                spacing:            ScreenTools.defaultFontPixelHeight * 0.5
                width:              Math.max(gps2Grid.width, gps2Label.width)
                anchors.margins:    ScreenTools.defaultFontPixelHeight
                anchors.centerIn:   parent

                QGCLabel {
                    id:             gps2Label
                    text:           (_activeVehicle && _activeVehicle.gps2.count.value >= 0) ? qsTr("GNSS2 Status") : qsTr("GNSS Data Unavailable")
                    font.family:    ScreenTools.demiboldFontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                GridLayout {
                    id:                 gps2Grid
                    visible:            (_activeVehicle && _activeVehicle.gps2.count.value >= 0)
                    anchors.margins:    ScreenTools.defaultFontPixelHeight
                    columnSpacing:      ScreenTools.defaultFontPixelWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 2

                    QGCLabel { text: qsTr("GNSS Count:") }
                    QGCLabel { text: _activeVehicle ? _activeVehicle.gps2.count.valueString : qsTr("N/A", "No data to display") }
                    QGCLabel { text: qsTr("GNSS Lock:") }
                    QGCLabel { text: _activeVehicle ? _activeVehicle.gps2.lock.enumStringValue : qsTr("N/A", "No data to display") }
                    QGCLabel { text: qsTr("HDOP:") }
                    QGCLabel { text: _activeVehicle ? _activeVehicle.gps2.hdop.valueString : qsTr("--.--", "No data to display") }
                    QGCLabel { text: qsTr("VDOP:") }
                    QGCLabel { text: _activeVehicle ? _activeVehicle.gps2.vdop.valueString : qsTr("--.--", "No data to display") }
                    QGCLabel { text: qsTr("Course Over Ground:") }
                    QGCLabel { text: _activeVehicle ? _activeVehicle.gps2.courseOverGround.valueString : qsTr("--.--", "No data to display") }
                }
            }
        }
    }

    Row {
        anchors.top:    parent.top
        anchors.bottom: parent.bottom

        spacing: ScreenTools.defaultFontPixelWidth/2

        Rectangle{
            width:              1
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            color:              qgcPal.text
            opacity:            0.5
        }

        QGCColoredImage {
            id:                 gps2Icon
            width:              height
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            source:             getGpsImage()
            fillMode:           Image.PreserveAspectFit
            sourceSize.height:  height
            opacity:            (_activeVehicle && _activeVehicle.gps2.count.value >= 0) ? 1 : 0.5
            color:              (_activeVehicle && _activeVehicle.gps2.lock.value >= 3) ? qgcPal.buttonText : qgcPal.colorOrange
        }

        Column {
            id:                     gps2ValuesColumn
            anchors.verticalCenter: parent.verticalCenter

            QGCLabel {
                anchors.horizontalCenter:   hdop2Value.horizontalCenter
                color:                      qgcPal.buttonText
                text:                       _activeVehicle ? _activeVehicle.gps2.count.valueString : ""
            }

            QGCLabel {
                id:         hdop2Value
                color:      qgcPal.buttonText
                text:       _activeVehicle ? _activeVehicle.gps2.hdop.value.toFixed(1) : ""                
            }
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked: {
            mainWindow.showIndicatorPopup(_root, gps2Info)
        }
    }
}
