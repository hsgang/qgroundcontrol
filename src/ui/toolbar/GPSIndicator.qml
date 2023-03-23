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

    Component {
        id: gpsInfo

        RowLayout {
            spacing: _margins

            property bool showExpand: true

            property real _margins: ScreenTools.defaultFontPixelHeight
            property real _editFieldWidth

            Column {
                Layout.alignment:   Qt.AlignTop
                spacing:            ScreenTools.defaultFontPixelHeight * 0.5

                QGCLabel {
                    id:             gpsLabel
                    text:           (_activeVehicle && _activeVehicle.gps.count.value >= 0) ? qsTr("GNSS Status") : qsTr("GNSS Data Unavailable")
                    font.family:    ScreenTools.demiboldFontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                GridLayout {
                    id:                 gpsGrid
                    visible:            (_activeVehicle && _activeVehicle.gps.count.value >= 0)
                    anchors.margins:    ScreenTools.defaultFontPixelHeight
                    columnSpacing:      ScreenTools.defaultFontPixelWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 2

                    QGCLabel { text: qsTr("GNSS Count:") }
                    QGCLabel { text: _activeVehicle ? _activeVehicle.gps.count.valueString : qsTr("N/A", "No data to display") }
                    QGCLabel { text: qsTr("GNSS Lock:") }
                    QGCLabel { text: _activeVehicle ? _activeVehicle.gps.lock.enumStringValue : qsTr("N/A", "No data to display") }
                    QGCLabel { text: qsTr("HDOP:") }
                    QGCLabel { text: _activeVehicle ? _activeVehicle.gps.hdop.valueString : qsTr("--.--", "No data to display") }
                    QGCLabel { text: qsTr("VDOP:") }
                    QGCLabel { text: _activeVehicle ? _activeVehicle.gps.vdop.valueString : qsTr("--.--", "No data to display") }
                    QGCLabel { text: qsTr("Course Over Ground:") }
                    QGCLabel { text: _activeVehicle ? _activeVehicle.gps.courseOverGround.valueString : qsTr("--.--", "No data to display") }
                }

                QGCLabel {
                    id:             gps2Label
                    visible:        isGNSS2
                    text:           (_activeVehicle && _activeVehicle.gps2.count.value >= 0) ? qsTr("GNSS2 Status") : qsTr("GNSS2 Data Unavailable")
                    font.family:    ScreenTools.demiboldFontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                GridLayout {
                    id:                 gps2Grid
                    visible:            isGNSS2
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

            Rectangle {
                Layout.fillHeight:  true
                width:              1
                color:              QGroundControl.globalPalette.text
                visible:            expanded
            }

            GridLayout {
                id:                 rtkGrid
                Layout.alignment:   Qt.AlignTop
                columns:            3
                visible:            expanded

                property var  rtkSettings:      QGroundControl.settingsManager.rtkSettings
                property bool useFixedPosition: rtkSettings.useFixedBasePosition.rawValue
                property real firstColWidth:    ScreenTools.defaultFontPixelWidth * 5

                QGCLabel {
                    text: qsTr("RTK GPS Settings")
                    Layout.columnSpan:  3
                } 

                QGCRadioButton {
                    text:               qsTr("Perform Survey-In")
                    visible:            rtkGrid.rtkSettings.useFixedBasePosition.visible
                    checked:            rtkGrid.rtkSettings.useFixedBasePosition.value === false
                    Layout.columnSpan:  3
                    onClicked:          rtkGrid.rtkSettings.useFixedBasePosition.value = false
                }

                Item { width: rtkGrid.firstColWidth; height: 1 }
                QGCLabel {
                    text:       rtkGrid.rtkSettings.surveyInAccuracyLimit.shortDescription
                    visible:    rtkGrid.rtkSettings.surveyInAccuracyLimit.visible
                    enabled:    !rtkGrid.useFixedPosition
                }
                FactTextField {
                    Layout.preferredWidth:  editFieldWidth
                    fact:                   rtkGrid.rtkSettings.surveyInAccuracyLimit
                    visible:                rtkGrid.rtkSettings.surveyInAccuracyLimit.visible
                    enabled:                !rtkGrid.useFixedPosition
                }

                Item { width: rtkGrid.firstColWidth; height: 1 }
                QGCLabel {
                    text:       rtkGrid.rtkSettings.surveyInMinObservationDuration.shortDescription
                    visible:    rtkGrid.rtkSettings.surveyInMinObservationDuration.visible
                    enabled:    !rtkGrid.useFixedPosition
                }
                FactTextField {
                    Layout.fillWidth:   true
                    fact:               rtkGrid.rtkSettings.surveyInMinObservationDuration
                    visible:            rtkGrid.rtkSettings.surveyInMinObservationDuration.visible
                    enabled:            !rtkGrid.useFixedPosition
                }

                QGCRadioButton {
                    text:               qsTr("Use Specified Base Position")
                    visible:            rtkGrid.rtkSettings.useFixedBasePosition.visible
                    checked:            rtkGrid.rtkSettings.useFixedBasePosition.value === true
                    onClicked:          rtkGrid.rtkSettings.useFixedBasePosition.value = true
                    Layout.columnSpan:  3
                }

                Item { width: rtkGrid.firstColWidth; height: 1 }
                QGCLabel {
                    text:               rtkGrid.rtkSettings.fixedBasePositionLatitude.shortDescription
                    visible:            rtkGrid.rtkSettings.fixedBasePositionLatitude.visible
                    enabled:            rtkGrid.useFixedPosition
                }
                FactTextField {
                    Layout.fillWidth:   true
                    fact:               rtkGrid.rtkSettings.fixedBasePositionLatitude
                    visible:            rtkGrid.rtkSettings.fixedBasePositionLatitude.visible
                    enabled:            rtkGrid.useFixedPosition
                }

                Item { width: rtkGrid.firstColWidth; height: 1 }
                QGCLabel {
                    text:               rtkGrid.rtkSettings.fixedBasePositionLongitude.shortDescription
                    visible:            rtkGrid.rtkSettings.fixedBasePositionLongitude.visible
                    enabled:            rtkGrid.useFixedPosition
                }
                FactTextField {
                    Layout.fillWidth:   true
                    fact:               rtkGrid.rtkSettings.fixedBasePositionLongitude
                    visible:            rtkGrid.rtkSettings.fixedBasePositionLongitude.visible
                    enabled:            rtkGrid.useFixedPosition
                }

                Item { width: rtkGrid.firstColWidth; height: 1 }
                QGCLabel {
                    text:               rtkGrid.rtkSettings.fixedBasePositionAltitude.shortDescription
                    visible:            rtkGrid.rtkSettings.fixedBasePositionAltitude.visible
                    enabled:            rtkGrid.useFixedPosition
                }
                FactTextField {
                    Layout.fillWidth:   true
                    fact:               rtkGrid.rtkSettings.fixedBasePositionAltitude
                    visible:            rtkGrid.rtkSettings.fixedBasePositionAltitude.visible
                    enabled:            rtkGrid.useFixedPosition
                }

                Item { width: rtkGrid.firstColWidth; height: 1 }
                QGCLabel {
                    text:               rtkGrid.rtkSettings.fixedBasePositionAccuracy.shortDescription
                    visible:            rtkGrid.rtkSettings.fixedBasePositionAccuracy.visible
                    enabled:            rtkGrid.useFixedPosition
                }
                FactTextField {
                    Layout.fillWidth:   true
                    fact:               rtkGrid.rtkSettings.fixedBasePositionAccuracy
                    visible:            rtkGrid.rtkSettings.fixedBasePositionAccuracy.visible
                    enabled:            rtkGrid.useFixedPosition
                }

                Item { width: rtkGrid.firstColWidth; height: 1 }
                QGCButton {
                    text:               qsTr("Save Current Base Position")
                    enabled:            QGroundControl.gpsRtk && QGroundControl.gpsRtk.valid.value
                    Layout.columnSpan:  2
                    Layout.alignment:   Qt.AlignHCenter
                    onClicked: {
                        rtkGrid.rtkSettings.fixedBasePositionLatitude.rawValue =    QGroundControl.gpsRtk.currentLatitude.rawValue
                        rtkGrid.rtkSettings.fixedBasePositionLongitude.rawValue =   QGroundControl.gpsRtk.currentLongitude.rawValue
                        rtkGrid.rtkSettings.fixedBasePositionAltitude.rawValue =    QGroundControl.gpsRtk.currentAltitude.rawValue
                        rtkGrid.rtkSettings.fixedBasePositionAccuracy.rawValue =    QGroundControl.gpsRtk.currentAccuracy.rawValue
                    }
                }
            }
        }
    }

    Row {
        id:             gnssValuesRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom

        spacing: ScreenTools.defaultFontPixelWidth / 2

        Rectangle{
            width:              1
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            color:              qgcPal.text
            opacity:            0.5
        }

        QGCColoredImage {
            id:                 gpsIcon
            width:              height
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            source:             getGpsImage()
            fillMode:           Image.PreserveAspectFit
            sourceSize.height:  height
            opacity:            (_activeVehicle && _activeVehicle.gps.count.value >= 0) ? 1 : 0.5
            color:              (_activeVehicle && _activeVehicle.gps.lock.value >= 3) ? qgcPal.buttonText : qgcPal.colorOrange
        }

        Column {
            id:                     gpsValuesColumn
            anchors.verticalCenter: parent.verticalCenter

            QGCLabel {
                anchors.horizontalCenter:   hdopValue.horizontalCenter
                color:                      qgcPal.buttonText
                text:                       _activeVehicle ? _activeVehicle.gps.count.valueString : ""
            }

            QGCLabel {
                id:         hdopValue
                color:      qgcPal.buttonText
                text:       _activeVehicle ? _activeVehicle.gps.hdop.value.toFixed(1) : ""
            }
        }

        Rectangle{
            visible:            isGNSS2
            width:              1
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            color:              qgcPal.text
            opacity:            0.5
        }

        QGCColoredImage {
            visible:            isGNSS2
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
            visible:                isGNSS2
            anchors.verticalCenter: parent.verticalCenter

            QGCLabel {
                anchors.horizontalCenter:   gps2hdopValue.horizontalCenter
                color:                      qgcPal.buttonText
                text:                       _activeVehicle ? _activeVehicle.gps2.count.valueString : ""
            }

            QGCLabel {
                id:         gps2hdopValue
                color:      qgcPal.buttonText
                text:       _activeVehicle ? _activeVehicle.gps2.hdop.value.toFixed(1) : "100.0"
            }
        }
    }

//    Row {
//        visible:        true//isGNSS2
//        anchors.top:    parent.top
//        anchors.bottom: parent.bottom

//        spacing: ScreenTools.defaultFontPixelWidth/2


//    }

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
