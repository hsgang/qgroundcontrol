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

Row{
    id: attitudeIndicatorRow
    spacing: _toolsMargin * 2

    // Property of Tools
    property real   _toolsMargin:               ScreenTools.defaultFontPixelWidth * 0.75
    property color  _baseBGColor:               qgcPal.window
    property real   _largeValueWidth:           ScreenTools.defaultFontPixelWidth * 8
    property real   _mediumValueWidth:          ScreenTools.defaultFontPixelWidth * 6
    property real   _smallValueWidth:           ScreenTools.defaultFontPixelWidth * 4

    // Property of Active Vehicle
    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle // ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle
    property real   _heading:                   _activeVehicle   ? _activeVehicle.heading.rawValue : 0

    property real   _vehicleAltitude:           _activeVehicle ? _activeVehicle.altitudeRelative.rawValue : 0
    property real   _vehicleAltitudeAMSL:       _activeVehicle ? _activeVehicle.altitudeAMSL.rawValue : 0
    property real   _vehicleVerticalSpeed:      _activeVehicle ? _activeVehicle.climbRate.rawValue : 0
    property real   _vehicleGroundSpeed:        _activeVehicle ? _activeVehicle.groundSpeed.rawValue : 0
    property real   _distanceToHome:            _activeVehicle ? _activeVehicle.distanceToHome.rawValue : 0
    property real   _distanceDown:              _activeVehicle ? _activeVehicle.distanceSensors.rotationPitch270.rawValue : 0
    property string _vehicleAltitudeText:       isNaN(_vehicleAltitude) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsDistanceUnits(_vehicleAltitude).toFixed(1)
    property string _vehicleAltitudeAMSLText:   isNaN(_vehicleAltitudeAMSL) ? "-.-" : "ASL " + QGroundControl.unitsConversion.metersToAppSettingsDistanceUnits(_vehicleAltitudeAMSL).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsDistanceUnitsString
    property string _vehicleVerticalSpeedText:  isNaN(_vehicleVerticalSpeed) ? "-.-" : QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_vehicleVerticalSpeed).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsSpeedUnitsString
    property string _vehicleGroundSpeedText:    isNaN(_vehicleGroundSpeed) ? "-.-" : QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_vehicleGroundSpeed).toFixed(1)
    property string _distanceToHomeText:        isNaN(_distanceToHome) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsDistanceUnits(_distanceToHome).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsDistanceUnitsString
    property string _distanceDownText:          isNaN(_distanceDown) ? "   " : QGroundControl.unitsConversion.metersToAppSettingsDistanceUnits(_distanceDown).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsDistanceUnitsString

    function getVerticalSpeedState() {
        if(_activeVehicle){
            if(_vehicleVerticalSpeed > 0.1){
                return "▲"
            } else if (_vehicleVerticalSpeed < -0.1) {
                return "▼"
            } else {
                return "-"
            }
        } else {
            return "-"
        }
    }

    function zeroPad(input, length) {
        var sign = (input[0] === '-') ? '-' : "";
        input = input.replace(/^-/, "");
        while (input.length < length) {
            input = "0" + input;
        }
        return sign + input;
    }

    //--Ground Speed Value Widget-----------------------------------------------------------------------------------

    Rectangle {
        id:                         groundSpeedValue
        anchors.margins:            _toolsMargin * 6
        //anchors.right:              parent.left
        anchors.verticalCenter:     parent.verticalCenter
        height:                     ScreenTools.isMobile ? parent.height * 0.6 : parent.height * 0.4
        width:                      ScreenTools.defaultFontPixelWidth * 16
        color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.7)
        radius:                     _toolsMargin

        ColumnLayout {
            id :            spdGrid
            anchors.fill:   parent
            spacing :       0

            RowLayout{
                spacing:                0
                Layout.preferredHeight: parent.height * 0.6
                Layout.fillHeight:      false

                ColumnLayout {
                    spacing:                0
                    //Layout.preferredWidth:  0.25 * parent.width

                    QGCLabel {
                        Layout.alignment:       Qt.AlignBottom
                        Layout.fillWidth:       true
                        text:                   "SPD"
                        font.bold :             true
                        font.pointSize:         ScreenTools.defaultFontPointSize * 0.8
                        horizontalAlignment :   Text.AlignHCenter
                    }

                    QGCLabel {
                        Layout.alignment:       Qt.AlignTop
                        Layout.fillWidth:       true
                        text:                   QGroundControl.unitsConversion.appSettingsSpeedUnitsString
                        font.bold :             true
                        horizontalAlignment :   Text.AlignHCenter
                    }
                }

                QGCLabel {
                    //text:                   _vehicleGroundSpeedText
                    text:                   zeroPad(_vehicleGroundSpeedText, 4)
                    font.bold :             true
                    color:                  qgcPal.textHighlight
                    font.pointSize :        ScreenTools.defaultFontPointSize * 2
                    Layout.fillWidth:       true
                    Layout.preferredWidth:  _largeValueWidth
                    horizontalAlignment:    Text.AlignHCenter
                }
            }

            QGCLabel {
                text:                   "Home " + _distanceToHomeText
                font.bold :             true
                Layout.fillWidth:       true
                horizontalAlignment:    Text.AlignHCenter
            }
        }
    }

    Rectangle {
        id :        gndSpdBarRect
        width:      ScreenTools.defaultFontPixelWidth * 3
        height:     parent.height * 0.9
        color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.7)
        radius:     _toolsMargin

//        anchors.right:          parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins:        _toolsMargin

        ColumnLayout {
            anchors.fill:       parent
            spacing:            0

            QGCLabel{
                text:                   gndSpdBar.maxValueString
                font.pointSize:         ScreenTools.defaultFontPointSize * 0.7
                Layout.fillWidth:       true
                Layout.preferredHeight: parent.height * 0.12
                horizontalAlignment:    Text.AlignHCenter
                verticalAlignment:      Text.AlignVCenter
            }
            Rectangle {
                id:                     gndSpdBar
                width:                  ScreenTools.defaultFontPixelWidth * 0.2
                height:                 parent.height * 0.7
                color:                  qgcPal.text
                Layout.fillWidth:       false
                Layout.fillHeight:      true
                Layout.preferredHeight: parent.height * 0.76
                Layout.alignment:       Qt.AlignRight
                Layout.rightMargin:     _toolsMargin

                property real maxValue:         12
                property real minValue:         0
                property real value:            (_vehicleGroundSpeed > maxValue) ? maxValue : _vehicleGroundSpeed
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
                        angle:          180
                    }
                }
            }
            QGCLabel{
                text:                   gndSpdBar.minValueString
                font.pointSize:         ScreenTools.defaultFontPointSize * 0.7
                Layout.fillWidth:       true
                Layout.preferredHeight: parent.height * 0.12
                horizontalAlignment:    Text.AlignHCenter
                verticalAlignment:      Text.AlignVCenter
            }
        }
    }

    Rectangle {
        id: attitudeIndicatorBase
        width: ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 6 : ScreenTools.defaultFontPixelHeight * 8
        height: width
        radius:                     height * 0.5
        color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.7)

        CustomAttitudeHUD {
            size:                       parent.height
            vehicle:                    _activeVehicle
            anchors.horizontalCenter:   parent.horizontalCenter
        }
    }

    Rectangle {
        id :        climbSpdBarRect
        width:      ScreenTools.defaultFontPixelWidth * 3
        height:     parent.height * 0.9
        color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.7)
        radius:     _toolsMargin

//        anchors.left:           parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins:        _toolsMargin

        ColumnLayout {
            anchors.fill:   parent
            spacing:        0

            QGCLabel{
                text:                   climbSpdBar.maxValueString
                font.pointSize:         ScreenTools.defaultFontPointSize * 0.7
                Layout.fillWidth:       true
                Layout.preferredHeight: parent.height * 0.12
                horizontalAlignment:    Text.AlignHCenter
                verticalAlignment:      Text.AlignVCenter
            }
            Rectangle {
                id:                     climbSpdBar
                width:                  ScreenTools.defaultFontPixelWidth * 0.2
                height:                 parent.height * 0.7
                color:                  qgcPal.text
                Layout.fillWidth:       false
                Layout.fillHeight:      true
                Layout.preferredHeight: parent.height * 0.76
                Layout.alignment:       Qt.AlignLeft
                Layout.leftMargin:      _toolsMargin

                property real maxValue: 5
                property real minValue: -5
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
                text:                   climbSpdBar.minValueString
                font.pointSize:         ScreenTools.defaultFontPointSize * 0.7
                Layout.fillWidth:       true
                Layout.preferredHeight: parent.height * 0.12
                horizontalAlignment:    Text.AlignHCenter
                verticalAlignment:      Text.AlignVCenter
            }
        }
    }

    Rectangle {
        id:                         altitudeValue
        anchors.margins:            _toolsMargin * 6
        //anchors.left:               parent.right
        anchors.verticalCenter:     parent.verticalCenter
        height:                     ScreenTools.isMobile ? parent.height * 0.6 : parent.height * 0.4
        width:                      ScreenTools.defaultFontPixelWidth * 16
        color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.7)
        radius:                     _toolsMargin

        ColumnLayout {
            id:             altitudeGrid
            anchors.fill:   parent
            spacing:        0

            RowLayout{
                spacing :               0
                Layout.preferredHeight: parent.height * 0.6
                Layout.fillHeight:      false

                QGCLabel {
                    //text:                   _vehicleAltitudeText
                    text:                   zeroPad(_vehicleAltitudeText, 5)
                    font.bold:              true
                    color:                  qgcPal.textHighlight
                    font.pointSize:         ScreenTools.defaultFontPointSize * 2
                    Layout.fillWidth:       true
                    Layout.preferredWidth:  _largeValueWidth
                    horizontalAlignment:    Text.AlignHCenter
                }

                ColumnLayout {
                    spacing: 0
                    //Layout.preferredWidth:  0.25 * parent.width

                    QGCLabel {
                        Layout.alignment:       Qt.AlignBottom
                        Layout.fillWidth:       true
                        text:                   "ALT"
                        font.bold :             true
                        font.pointSize:         ScreenTools.defaultFontPointSize * 0.8
                        horizontalAlignment :   Text.AlignHCenter
                    }

                    QGCLabel {
                        Layout.alignment:       Qt.AlignTop
                        Layout.fillWidth:       true
                        text:                   QGroundControl.unitsConversion.appSettingsDistanceUnitsString
                        font.bold :             true
                        font.pointSize:         ScreenTools.defaultFontPointSize
                        horizontalAlignment :   Text.AlignHCenter
                    }
                }
            }

            QGCLabel {
                text:                   "VS " + _vehicleVerticalSpeedText + " " + getVerticalSpeedState()
                font.bold :             true
                Layout.fillWidth:       true
                horizontalAlignment:    Text.AlignHCenter
                verticalAlignment:      Text.AlignVCenter
            }
        }

        RowLayout {
            id:                 distanceDownRowLayout
            anchors.bottom:     parent.top
            anchors.left:       parent.left
            anchors.bottomMargin:    _toolsMargin * 0.5
            visible:            _distanceDown

            Rectangle{
                height:     valueIcon.height
                width:      valueIcon.width
                color:      "transparent"

                QGCColoredImage {
                    id:                         valueIcon
                    Layout.alignment:           Qt.AlignHCenter || Qt.AlignVCenter
                    height:                     distanceDownLabel.height * 0.6
                    width:                      height
                    sourceSize.height:          height
                    fillMode:                   Image.PreserveAspectFit
                    mipmap:                     true
                    smooth:                     true
                    color:                      qgcPal.text
                    visible:                    true //_iconVisible
                    source:                     "/InstrumentValueIcons/arrow-base-down.svg"
                }
            }

            QGCLabel {
                id:                     distanceDownLabel
                text:                   _distanceDownText
                font.bold :             true
                font.pointSize :        ScreenTools.defaultFontPointSize * 1.2
                Layout.fillWidth:       true
                horizontalAlignment:    Text.AlignHCenter
                verticalAlignment:      Text.AlignVCenter
            }
        }

        QGCLabel {
            text:               _vehicleAltitudeAMSLText
            font.bold:          true
            font.pointSize:     ScreenTools.defaultFontPointSize * 0.8
            anchors.top:        parent.bottom
            anchors.topMargin:  _toolsMargin * 0.5
            anchors.left:       parent.left
        }
    }
}

