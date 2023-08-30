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
import QtGraphicalEffects       1.12
import QtQuick.Shapes           1.15

import QtLocation               5.3
import QtPositioning            5.3
import QtQuick.Window           2.2
import QtQml.Models             2.1

import QGroundControl               1.0
import QGroundControl.Controllers   1.0
import QGroundControl.Controls      1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.FlightMap     1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0

Rectangle {
    id: attitudeIndicatorRoot

    width: ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 6 : ScreenTools.defaultFontPixelHeight * 8
    height: width

    color: "transparent"
//    border.width: 1
//    border.color: "white"

    // Property of Tools
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property color  _baseBGColor:           qgcPal.window
    property real   _largeValueWidth:           ScreenTools.defaultFontPixelWidth * 8
    property real   _mediumValueWidth:          ScreenTools.defaultFontPixelWidth * 6
    property real   _smallValueWidth:           ScreenTools.defaultFontPixelWidth * 4

    // Property of Active Vehicle
    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle
    property real   _heading:               _activeVehicle   ? _activeVehicle.heading.rawValue : 0
    property bool   _available:             !isNaN(_activeVehicle.vibration.xAxis.rawValue)

    property real   _vehicleAltitude:           _activeVehicle ? _activeVehicle.altitudeRelative.rawValue : 0
    property real   _vehicleVerticalSpeed:      _activeVehicle ? _activeVehicle.climbRate.rawValue : 0
    property real   _vehicleGroundSpeed:        _activeVehicle ? _activeVehicle.groundSpeed.rawValue : 0
    property real   _distanceToHome:            _activeVehicle ? _activeVehicle.distanceToHome.rawValue : 0
    property string _vehicleAltitudeText:       isNaN(_vehicleAltitude) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsVerticalDistanceUnits(_vehicleAltitude).toFixed(1)
    property string _vehicleVerticalSpeedText:  isNaN(_vehicleVerticalSpeed) ? "-.-" : QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_vehicleVerticalSpeed).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsSpeedUnitsString
    property string _vehicleGroundSpeedText:    isNaN(_vehicleGroundSpeed) ? "-.-" : QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_vehicleGroundSpeed).toFixed(1)
    property string _distanceToHomeText:        isNaN(_distanceToHome) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsVerticalDistanceUnits(_distanceToHome).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString

    //--Attitude Widget-----------------------------------------------------------------------------------

    Rectangle {
        id:                     attitudeIndicator
        anchors.bottom:         parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        height:                 parent.height
        width:                  height
        radius:                 height * 0.5
        color:                  Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)

        CustomAttitudeHUD {
            size:                       parent.height
            vehicle:                    _activeVehicle
            anchors.horizontalCenter:   parent.horizontalCenter
        }
    }

    //--Altitude Value Widget-----------------------------------------------------------------------------------

    Rectangle {
        id:                         altitudeValue
        anchors.margins:            _toolsMargin * 6
        anchors.left:               parent.right
        anchors.verticalCenter:     parent.verticalCenter
        height:                     ScreenTools.isMobile ? parent.height * 0.55 : parent.height * 0.45
        width:                      ScreenTools.defaultFontPixelWidth * 20 //altitudeGrid.width
        color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
        radius:                     _toolsMargin

        ColumnLayout {
            id: altitudeGrid
            anchors.fill: parent
            spacing: ScreenTools.defaultFontPixelHeight * 0.5

            RowLayout{
                spacing : ScreenTools.defaultFontPixelWidth
                Layout.preferredHeight: 0.6 * parent.height
                Layout.fillHeight: false

                QGCLabel {
                    text:   _vehicleAltitudeText
                    font.bold : true
                    color: qgcPal.textHighlight
                    font.pointSize : ScreenTools.defaultFontPointSize * 2.5
                    Layout.fillWidth: true
                    Layout.minimumWidth: _largeValueWidth * 1.5
                    Layout.preferredWidth: _largeValueWidth * 1.7
                    horizontalAlignment : Text.AlignHCenter
                }

                ColumnLayout {
                    spacing: ScreenTools.defaultFontPixelHeight * 0.5
                    Layout.preferredWidth: 0.25 * parent.width

                    QGCLabel {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        text: "ALT"
                        font.bold : true
                        horizontalAlignment : Text.AlignHCenter
                    }

                    QGCLabel {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        text: QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString
                        font.bold : true
                        horizontalAlignment : Text.AlignHCenter
                    }
                }
            }

            QGCLabel {
                text:   "VS " + _vehicleVerticalSpeedText
                font.bold : true
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    //--Ground Speed Value Widget-----------------------------------------------------------------------------------

    Rectangle {
        id:                         groundSpeedValue
        anchors.margins:            _toolsMargin * 6
        anchors.right:              parent.left
        anchors.verticalCenter:     parent.verticalCenter
        height:                     ScreenTools.isMobile ? parent.height * 0.55 : parent.height * 0.45
        width:                      ScreenTools.defaultFontPixelWidth * 20
        color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
        radius:                     _toolsMargin

        ColumnLayout {
            id : spdGrid
            anchors.fill: parent
            spacing : ScreenTools.defaultFontPixelHeight * 0.5

            RowLayout{
                spacing: ScreenTools.defaultFontPixelWidth
                Layout.preferredHeight: 0.6 * parent.height
                Layout.fillHeight: false

                ColumnLayout {
                    spacing: ScreenTools.defaultFontPixelHeight * 0.5
                    Layout.preferredWidth: 0.25 * parent.width

                    QGCLabel {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        text: "SPD"
                        font.bold : true
                        horizontalAlignment : Text.AlignHCenter
                    }

                    QGCLabel {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        text: QGroundControl.unitsConversion.appSettingsSpeedUnitsString
                        font.bold : true
                        horizontalAlignment : Text.AlignHCenter
                    }
                }

                QGCLabel {
                    text:   _vehicleGroundSpeedText
                    font.bold : true
                    color: qgcPal.textHighlight
                    font.pointSize : ScreenTools.defaultFontPointSize * 2.5
                    Layout.fillWidth: true
                    Layout.minimumWidth: _largeValueWidth * 1.5
                    Layout.preferredWidth: _largeValueWidth * 1.7
                    horizontalAlignment : Text.AlignHCenter
                }
            }

            QGCLabel {
                text:   "Home " + _distanceToHomeText
                font.bold : true
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    Rectangle {
        id : gndSpdBarRect
        width: ScreenTools.defaultFontPixelWidth * 3
        height: parent.height * 0.9
        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
        radius: _toolsMargin

        anchors.right: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: _toolsMargin

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            QGCLabel{
                text: gndSpdBar.maxValueString
                Layout.fillWidth: true
                Layout.preferredHeight: parent.height * 0.15
                horizontalAlignment : Text.AlignHCenter
            }
            Rectangle {
                id: gndSpdBar
                width: ScreenTools.defaultFontPixelWidth * 0.2
                height: parent.height * 0.7
                color: qgcPal.text
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: _toolsMargin

                property real maxValue: 15
                property real minValue: 0
                property real value: (_vehicleGroundSpeed > maxValue) ? maxValue : _vehicleGroundSpeed
                property string maxValueString: maxValue.toString()
                property string minValueString: minValue.toString()

                Image {
                    id:                 gndSpdlevelerArrow
                    source:             "/qmlimages/LevelerArrow.svg"
                    mipmap:             true
                    fillMode:           Image.PreserveAspectFit
                    anchors.right:      parent.left
                    sourceSize.height:  ScreenTools.defaultFontPixelWidth * 2
                    y: {(_vehicleGroundSpeed <= gndSpdBar.maxValue && _vehicleGroundSpeed > 0) ?
                                    gndSpdBar.height - (gndSpdBar.height * (_vehicleGroundSpeed / gndSpdBar.maxValue)) - (height/2) :
                                     gndSpdBar.height - (height/2)}

                    transform: Rotation {
                        origin.x:       gndSpdlevelerArrow.width  / 2
                        origin.y:       gndSpdlevelerArrow.height / 2
                        angle:         180
                    }
                }
            }
            QGCLabel{
                text: gndSpdBar.minValueString
                Layout.fillWidth: true
                Layout.preferredHeight: parent.height * 0.15
                horizontalAlignment : Text.AlignHCenter
            }
        }
    }

    Rectangle {
        id : climbSpdBarRect
        width: ScreenTools.defaultFontPixelWidth * 3
        height: parent.height * 0.9
        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
        radius: _toolsMargin

        anchors.left: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: _toolsMargin

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            QGCLabel{
                text: climbSpdBar.maxValueString
                Layout.fillWidth: true
                Layout.preferredHeight: parent.height * 0.15
                horizontalAlignment : Text.AlignHCenter
            }
            Rectangle {
                id: climbSpdBar
                width: ScreenTools.defaultFontPixelWidth * 0.2
                height: parent.height * 0.7
                color: qgcPal.text
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: _toolsMargin

                property real maxValue: 10
                property real minValue: -10
                property real value: (Math.abs(_vehicleVerticalSpeed) > maxValue) ? maxValue : _vehicleVerticalSpeed
                property string maxValueString: maxValue.toString()
                property string minValueString: minValue.toString()

                Image {
                    id:                 climbSpdlevelerArrow
                    source:             "/qmlimages/LevelerArrow.svg"
                    mipmap:             true
                    fillMode:           Image.PreserveAspectFit
                    anchors.left:       parent.right
                    sourceSize.height:  ScreenTools.defaultFontPixelWidth * 2
                    y: {(Math.abs(_vehicleVerticalSpeed) <= climbSpdBar.maxValue) ?
                                    (climbSpdBar.height/2) - ((climbSpdBar.height/2) * (_vehicleVerticalSpeed / climbSpdBar.maxValue)) - (height/2) :
                                    (climbSpdBar.height/2)}
                }
            }
            QGCLabel{
                text: climbSpdBar.minValueString
                Layout.fillWidth: true
                Layout.preferredHeight: parent.height * 0.15
                horizontalAlignment : Text.AlignHCenter
            }
        }
    }

}


