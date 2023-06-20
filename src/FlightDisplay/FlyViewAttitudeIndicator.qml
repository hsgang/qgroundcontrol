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
import QGroundControl.Airspace      1.0
import QGroundControl.Airmap        1.0
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

    width: attitudeIndicator.width + altitudeValue.width + groundSpeedValue.width + _toolsMargin * 6
    height: attitudeIndicator.height

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

    //-----------------------------------------------------------------------------------------------------
    //--Attitude Widget-----------------------------------------------------------------------------------

    Rectangle {
        id:                     attitudeIndicator
        anchors.bottom:         parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        height:                 ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 6 : ScreenTools.defaultFontPixelHeight * 8
        width:                  height
        radius:                 height * 0.5
        color:                  Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)

        Rectangle {
            id:                         altitudeValue
            anchors.margins:            _toolsMargin * 6
            anchors.left:               parent.right
            anchors.verticalCenter:     parent.verticalCenter
            height:                     ScreenTools.isMobile ? parent.height * 0.55 : parent.height * 0.45
            width:                      altitudeGrid.width
            color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
            radius:                     _toolsMargin

            GridLayout {
                id: altitudeGrid
                anchors.top:            parent.top
                anchors.bottom:         parent.bottom
                anchors.left:           parent.left
                anchors.leftMargin:     _margins
                Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter

                columns: 4
                rows: 3

                rowSpacing: 1

                QGCLabel {
                    id: altText
                    text: "ALT"
                    font.bold : true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 1
                    Layout.rowSpan : 1
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 1
                    Layout.column : 3
                    Layout.row : 0
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.minimumWidth:    _mediumValueWidth

//                    layer.enabled: true
//                    layer.effect: Glow {
//                        samples: 5
//                        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
//                        transparentBorder: true
//                    }
                }

                QGCLabel {
                    id: distunitText
                    text:  QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString
                    font.bold : true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 1
                    Layout.rowSpan : 1
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 1
                    Layout.column : 3
                    Layout.row : 1
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.minimumWidth:    _mediumValueWidth

//                    layer.enabled: true
//                    layer.effect: Glow {
//                        samples: 5
//                        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
//                        transparentBorder: true
//                    }
                }


                QGCLabel {
                    id:     altitudeValueText
                    text:   _vehicleAltitudeText
                    font.bold : true
                    font.pointSize : ScreenTools.defaultFontPointSize * 2.5
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: qgcPal.textHighlight

                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 3
                    Layout.rowSpan : 2
                    Layout.preferredWidth: 3
                    Layout.preferredHeight: 2
                    Layout.column : 0
                    Layout.row : 0
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.minimumWidth:    _largeValueWidth * 1.5

//                    layer.enabled: true
//                    layer.effect: Glow {
//                        samples: 5
//                        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
//                        transparentBorder: true
//                    }
                }

                QGCLabel {
                    id: vsText
                    text:   "VS " + _vehicleVerticalSpeedText
                    font.bold : true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 4
                    Layout.rowSpan : 1
                    Layout.preferredWidth: 4
                    Layout.preferredHeight: 1
                    Layout.column : 0
                    Layout.row : 2
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.minimumWidth:    _largeValueWidth + _mediumValueWidth

//                    layer.enabled: true
//                    layer.effect: Glow {
//                        samples: 5
//                        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
//                        transparentBorder: true
//                    }
                }



            }
        }

        Rectangle {
            id:                         groundSpeedValue
            anchors.margins:            _toolsMargin * 6
            anchors.right:              parent.left
            anchors.verticalCenter:     parent.verticalCenter
            height:                     ScreenTools.isMobile ? parent.height * 0.55 : parent.height * 0.45
            width:                      spdGrid.width
            color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
            radius:                     _toolsMargin

            GridLayout {
                id: spdGrid

                anchors.top:            parent.top
                anchors.bottom:         parent.bottom
                anchors.right:          parent.right
                anchors.rightMargin:    _margins
                Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter

                columns: 4
                rows: 3

                rowSpacing: 1

                QGCLabel {
                    id: spdText
                    text: "SPD"
                    font.bold : true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 1
                    Layout.rowSpan : 1
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 1
                    Layout.column : 0
                    Layout.row : 0
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.minimumWidth:    _mediumValueWidth

//                    layer.enabled: true
//                    layer.effect: Glow {
//                        samples: 5
//                        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
//                        transparentBorder: true
//                    }
                }

                QGCLabel {
                    id: spdunitText
                    text: QGroundControl.unitsConversion.appSettingsSpeedUnitsString
                    font.bold : true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 1
                    Layout.rowSpan : 1
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 1
                    Layout.column : 0
                    Layout.row : 1
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.minimumWidth:    _mediumValueWidth

//                    layer.enabled: true
//                    layer.effect: Glow {
//                        samples: 5
//                        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
//                        transparentBorder: true
//                    }
                }

                QGCLabel {
                    id: gndspdText
                    text: _vehicleGroundSpeedText
                    font.bold : true
                    font.pointSize : ScreenTools.defaultFontPointSize * 2.5
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: qgcPal.textHighlight

                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 3
                    Layout.rowSpan : 2
                    Layout.preferredWidth: 3
                    Layout.preferredHeight: 2
                    Layout.column : 1
                    Layout.row : 0
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.minimumWidth:    _largeValueWidth * 1.5

//                    layer.enabled: true
//                    layer.effect: Glow {
//                        samples: 5
//                        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
//                        transparentBorder: true
//                    }
                }

                QGCLabel {
                    id: dtohText
                    text: "Home " + _distanceToHomeText
                    font.bold : true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 4
                    Layout.rowSpan : 1
                    Layout.preferredWidth: 4
                    Layout.preferredHeight: 1
                    Layout.column : 0
                    Layout.row : 2
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.minimumWidth:    _largeValueWidth + _mediumValueWidth

//                    layer.enabled: true
//                    layer.effect: Glow {
//                        samples: 5
//                        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
//                        transparentBorder: true
//                    }
                }

            }
        }

        CustomAttitudeHUD {
            size:                       parent.height
            vehicle:                    _activeVehicle
            anchors.horizontalCenter:   parent.horizontalCenter
        }

        Rectangle{
            id: gndSpdBarRect
            width: ScreenTools.defaultFontPixelWidth * 0.2
            height: parent.height * 0.8
            color: qgcPal.text
            anchors.right: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: _toolsMargin * 2

            property real maxValue: 15
            property real minValue: 0
            property real value: (_vehicleGroundSpeed > maxValue) ? maxValue : _vehicleGroundSpeed
            property string maxValueString: maxValue.toString()
            property string minValueString: minValue.toString()

            Rectangle{
                height: 2
                color: qgcPal.text
                width: ScreenTools.defaultFontPixelWidth * 1.2
                anchors.top: parent.top
                anchors.right: parent.right

                QGCLabel{
                    text: gndSpdBarRect.maxValueString
                    anchors.right: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: _toolsMargin
                }
            }

            Rectangle{
                height: 2
                color: qgcPal.text
                width: ScreenTools.defaultFontPixelWidth * 1.2
                anchors.bottom: parent.bottom
                anchors.right: parent.right

                QGCLabel{
                    text: gndSpdBarRect.minValueString
                    anchors.right: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: _toolsMargin
                }
            }

            Image {
                id:                 gndSpdlevelerArrow
                source:             "/qmlimages/LevelerArrow.svg"
                mipmap:             true
                fillMode:           Image.PreserveAspectFit
                anchors.right:      parent.left
                sourceSize.height:  ScreenTools.defaultFontPixelWidth * 2
                y: {(_vehicleGroundSpeed <= gndSpdBarRect.maxValue && _vehicleGroundSpeed > 0) ?
                                gndSpdBarRect.height - (gndSpdBarRect.height * (_vehicleGroundSpeed / gndSpdBarRect.maxValue)) - (height/2) :
                                 gndSpdBarRect.height - (height/2)}

                transform: Rotation {
//                    property var _angle:isNoseUpLocked() ? _courseOverGround-_heading : _courseOverGround
                    origin.x:       gndSpdlevelerArrow.width  / 2
                    origin.y:       gndSpdlevelerArrow.height / 2
                    angle:         180
                }
            }
        }

        Rectangle{
            id: climbSpdBarRect
            width: ScreenTools.defaultFontPixelWidth * 0.2
            height: parent.height * 0.8
            color: qgcPal.text
            anchors.left: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: _toolsMargin * 2

            property real maxValue: 10
            property real minValue: -10
            property real value: (Math.abs(_vehicleVerticalSpeed) > maxValue) ? maxValue : _vehicleVerticalSpeed
            property string maxValueString: maxValue.toString()
            property string minValueString: minValue.toString()

            Rectangle{
                height: 2
                color: qgcPal.text
                width: ScreenTools.defaultFontPixelWidth * 1.2
                anchors.top: parent.top
                anchors.left: parent.left

                QGCLabel{
                    text: climbSpdBarRect.maxValueString
                    anchors.left: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: _toolsMargin
                }
            }

            Rectangle{
                height: 2
                color: qgcPal.text
                width: ScreenTools.defaultFontPixelWidth * 1.2
                anchors.bottom: parent.bottom
                anchors.left: parent.left

                QGCLabel{
                    text: climbSpdBarRect.minValueString
                    anchors.left: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: _toolsMargin
                }
            }

            Image {
                id:                 climbSpdlevelerArrow
                source:             "/qmlimages/LevelerArrow.svg"
                mipmap:             true
                fillMode:           Image.PreserveAspectFit
                anchors.left:       parent.right
                sourceSize.height:  ScreenTools.defaultFontPixelWidth * 2
                y: {(Math.abs(_vehicleVerticalSpeed) <= climbSpdBarRect.maxValue) ?
                                (climbSpdBarRect.height/2) - ((climbSpdBarRect.height/2) * (_vehicleVerticalSpeed / climbSpdBarRect.maxValue)) - (height/2) :
                                (climbSpdBarRect.height/2)}
            }
        }
    }
}


