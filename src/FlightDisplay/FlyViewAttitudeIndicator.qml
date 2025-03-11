/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Shapes

import QtLocation
import QtPositioning
import QtQuick.Window
import QtQml.Models

import QGroundControl
import QGroundControl.Controllers
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.Vehicle

Item{
    id:     control
    width:  attitudeIndicatorRow.implicitWidth
    height: attitudeIndicatorRow.implicitHeight
    //color: "transparent"

    // Property of Tools
    property real   _toolsMargin:               ScreenTools.defaultFontPixelWidth * 0.75
    property color  _baseBGColor:               qgcPal.window
    property real   _largeValueWidth:           ScreenTools.defaultFontPixelWidth * 8
    property real   _mediumValueWidth:          ScreenTools.defaultFontPixelWidth * 6
    property real   _smallValueWidth:           ScreenTools.defaultFontPixelWidth * 4

    property real   backgroundOpacity:          QGroundControl.settingsManager.flyViewSettings.flyviewWidgetOpacity.rawValue

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
    property string _vehicleVerticalSpeedText:  isNaN(_vehicleVerticalSpeed) ? "-.-" : QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_vehicleVerticalSpeed).toFixed(1)
    property string _speedUnitText:             QGroundControl.unitsConversion.appSettingsSpeedUnitsString
    property string _vehicleGroundSpeedText:    isNaN(_vehicleGroundSpeed) ? "-.-" : QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_vehicleGroundSpeed).toFixed(1)
    property string _distanceToHomeText:        isNaN(_distanceToHome) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsDistanceUnits(_distanceToHome).toFixed(1)
    property string _distanceUnitText:          QGroundControl.unitsConversion.appSettingsDistanceUnitsString
    property string _distanceDownText:          isNaN(_distanceDown) ? "   " : "RNG " + QGroundControl.unitsConversion.metersToAppSettingsDistanceUnits(_distanceDown).toFixed(2) + " " + QGroundControl.unitsConversion.appSettingsDistanceUnitsString

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

    RowLayout{
        id: attitudeIndicatorRow
        spacing:    _toolsMargin / 2

        //--Ground Speed Value Widget-----------------------------------------------------------------------------------       

        Rectangle {
            id:                 groundSpeedValue
            height:             ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 3.6 : ScreenTools.defaultFontPixelHeight * 3.2
            width:              ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 14 : ScreenTools.defaultFontPixelWidth * 16
            color:              Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, backgroundOpacity)
            radius:             _toolsMargin

            ColumnLayout {
                id :            spdGrid
                anchors.fill:   parent
                spacing :       0

                RowLayout{
                    spacing:                0
                    Layout.preferredHeight: parent.height * 0.6
                    Layout.fillHeight:      false

                    ColumnLayout {
                        spacing:                    0

                        QGCLabel {
                            Layout.alignment:       Qt.AlignBottom
                            Layout.fillWidth:       true
                            text:                   "SPD"
                            font.bold :             true
                            font.pointSize:         ScreenTools.defaultFontPointSize * 0.8
                            horizontalAlignment :   Text.AlignHCenter
                            opacity: 0.7
                        }

                        QGCLabel {
                            Layout.alignment:       Qt.AlignTop
                            Layout.fillWidth:       true
                            text:                   QGroundControl.unitsConversion.appSettingsSpeedUnitsString
                            font.bold :             true
                            horizontalAlignment :   Text.AlignHCenter
                            opacity: 0.7
                        }
                    }

                    QGCLabel {
                        text:                   zeroPad(_vehicleGroundSpeedText, 4)
                        font.bold :             true
                        color:                  qgcPal.textHighlight
                        font.pointSize :        ScreenTools.defaultFontPointSize * 2
                        Layout.fillWidth:       true
                        Layout.preferredWidth:  _largeValueWidth
                        horizontalAlignment:    Text.AlignHCenter
                    }
                }

                Row {
                    Layout.alignment:   Qt.AlignCenter
                    spacing:            _toolsMargin / 2

                    QGCLabel {
                        text:                   "Home"
                        opacity:                0.7
                    }
                    QGCLabel {
                        text:                   _distanceToHomeText
                        font.bold :             true
                    }
                    QGCLabel {
                        text:                   _distanceUnitText
                        opacity:                0.7
                    }
                }
            }
        }

        Rectangle {
            id :        gndSpdBarRect
            width:      ScreenTools.defaultFontPixelWidth * 3
            height:     ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 5.4 : ScreenTools.defaultFontPixelHeight * 7.2
            color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, backgroundOpacity)
            radius:     _toolsMargin

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
                    width:                  2
                    height:                 parent.height * 0.7
                    color:                  qgcPal.text
                    Layout.fillWidth:       false
                    Layout.fillHeight:      true
                    Layout.preferredHeight: parent.height * 0.76
                    Layout.alignment:       Qt.AlignRight
                    Layout.rightMargin:     _toolsMargin

                    property real maxValue:         20
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
                    Rectangle {
                        width:              ScreenTools.defaultFontPixelWidth
                        height:             1
                        color:              qgcPal.text
                        anchors.top:        parent.top
                        anchors.right:      parent.left
                    }
                    Rectangle {
                        width:              ScreenTools.defaultFontPixelWidth
                        height:             1
                        color:              qgcPal.text
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right:      parent.left
                    }
                    Rectangle {
                        width:              ScreenTools.defaultFontPixelWidth
                        height:             1
                        color:              qgcPal.text
                        anchors.bottom:     parent.bottom
                        anchors.right:      parent.left
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

        Item {
            width:      _toolsMargin * 2
            height:     parent.height
        }

        Rectangle {
            id: attitudeIndicatorBase
            height: ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 6 : ScreenTools.defaultFontPixelHeight * 8
            width:  height
            radius: height * 0.5
            color:  Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.9)

            CustomAttitudeHUD {
                size:                       parent.height
                vehicle:                    _activeVehicle
                anchors.horizontalCenter:   parent.horizontalCenter
            }
        }

        // RowLayout {
        //     //id: instrumentPanelBase
        //     width: instrumentPanel.implicitWidth
        //     height: instrumentPanel.implicitHeight
        //     //color:  "transparent"

        //     FlyViewInstrumentPanel {
        //         id:         instrumentPanel
        //         visible:    QGroundControl.corePlugin.options.flyView.showInstrumentPanel && _showSingleVehicleUI
        //     }
        // }

        Item {
            width:      _toolsMargin * 2
            height:     parent.height
        }

        Rectangle {
            id :        climbSpdBarRect
            width:      ScreenTools.defaultFontPixelWidth * 3
            height:     ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 5.4 : ScreenTools.defaultFontPixelHeight * 7.2
            color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, backgroundOpacity)
            radius:     _toolsMargin

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
                    width:                  2
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
                    Rectangle {
                        width:              ScreenTools.defaultFontPixelWidth
                        height:             1
                        color:              qgcPal.text
                        anchors.top:        parent.top
                        anchors.left:       parent.right
                    }
                    Rectangle {
                        width:              ScreenTools.defaultFontPixelWidth
                        height:             1
                        color:              qgcPal.text
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left:       parent.right
                    }
                    Rectangle {
                        width:              ScreenTools.defaultFontPixelWidth
                        height:             1
                        color:              qgcPal.text
                        anchors.bottom:     parent.bottom
                        anchors.left:       parent.right
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
            height:                     ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 3.6 : ScreenTools.defaultFontPixelHeight * 3.2
            width:                      ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 12 : ScreenTools.defaultFontPixelWidth * 16
            color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, backgroundOpacity)
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
                        id:                     altitudeValueLabel
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

                        QGCLabel {
                            Layout.alignment:       Qt.AlignBottom
                            Layout.fillWidth:       true
                            text:                   "ALT"
                            font.bold :             true
                            font.pointSize:         ScreenTools.defaultFontPointSize * 0.8
                            horizontalAlignment :   Text.AlignHCenter
                            opacity: 0.7
                        }

                        QGCLabel {
                            Layout.alignment:       Qt.AlignTop
                            Layout.fillWidth:       true
                            text:                   QGroundControl.unitsConversion.appSettingsDistanceUnitsString
                            font.bold :             true
                            font.pointSize:         ScreenTools.defaultFontPointSize
                            horizontalAlignment :   Text.AlignHCenter
                            opacity: 0.7
                        }
                    }
                }

                Row {
                    Layout.alignment:   Qt.AlignCenter
                    spacing:            _toolsMargin / 2

                    QGCLabel {
                        text:           "VS"
                        opacity:        0.7
                    }
                    QGCLabel {
                        text:           _vehicleVerticalSpeedText
                        font.bold :     true
                    }
                    QGCLabel {
                        text:           _speedUnitText
                        opacity:        0.7
                    }
                    QGCLabel {
                        text:           getVerticalSpeedState()
                        opacity:        0.7
                    }
                }
            }

            Rectangle {
                anchors.bottom:         parent.top
                anchors.left:           parent.left
                anchors.bottomMargin:   _toolsMargin * 0.5
                width:                  distanceDownRowLayout.width + _toolsMargin * 2
                height:                 distanceDownRowLayout.height
                color:                  (_distanceDown > 1 && _distanceDown <= 10) ? "red" : "transparent"
                radius:                 _toolsMargin / 2

                RowLayout {
                    id:                         distanceDownRowLayout
                    anchors.horizontalCenter:   parent.horizontalCenter
                    anchors.verticalCenter:     parent.verticalCenter
                    visible:                    _distanceDown

                    Rectangle{
                        height:             valueIcon.height
                        width:              valueIcon.width
                        color:              "transparent"

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
                            visible:                    true
                            source:                     "/InstrumentValueIcons/arrow-base-down.svg"
                        }
                    }

                    QGCLabel {
                        id:                     distanceDownLabel
                        text:                   _distanceDownText
                        font.bold :             true
                        font.pointSize :        ScreenTools.defaultFontPointSize
                        Layout.fillWidth:       true
                        horizontalAlignment:    Text.AlignHCenter
                        verticalAlignment:      Text.AlignVCenter
                    }
                }
            }

            QGCLabel {
                text:               _vehicleAltitudeAMSLText
                font.bold:          true
                font.pointSize:     ScreenTools.defaultFontPointSize
                anchors.top:        parent.bottom
                anchors.topMargin:  _toolsMargin * 0.5
                anchors.left:       parent.left
            }
        }
    }
}
