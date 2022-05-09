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

    width: attitudeIndicator.width + altitudeValue.width + groundSpeedValue.width + _toolsMargin * 6 + (gndSpdBarBase.width * 0.5)
    height: attitudeIndicator.height

    color: "transparent"
//    border.width: 1
//    border.color: "white"

    // Property of Tools
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property color  _baseBGColor:           qgcPal.window

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
        //anchors.bottomMargin:   _toolsMargin
        anchors.bottom:         parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        height:                 ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 7 : ScreenTools.defaultFontPixelHeight * 9
        width:                  height
        radius:                 height * 0.5
        color:                  "#80000000"

        Rectangle {
            id:                         altitudeValue
            anchors.margins:            _toolsMargin * 2
            anchors.left:               parent.right
            anchors.verticalCenter:     parent.verticalCenter
            height:                     ScreenTools.isMobile ? parent.height * 0.55 : parent.height * 0.45
            width:                      ScreenTools.isMobile ? parent.width : parent.width * 0.8
            color:                      "transparent" //"#80000000"
//            border.color:               Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
//            border.width:               1
            radius:                     _toolsMargin

            GridLayout {
                anchors.fill: parent

                columns: 4
                rows: 3

                rowSpacing: 1

                Rectangle{
                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 1
                    Layout.rowSpan : 1
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 1
                    Layout.column : 3
                    Layout.row : 0
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: "transparent"
                    QGCLabel {
                        id: altText
                        text: "ALT"
                        font.bold : true
                        anchors.right: parent.right
                        anchors.rightMargin: _toolsMargin
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Glow {
                        anchors.fill: altText
                        radius: 2
                        samples: 5
                        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
                        source: altText
                    }
                }
                Rectangle{
                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 1
                    Layout.rowSpan : 1
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 1
                    Layout.column : 3
                    Layout.row : 1
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: "transparent"
                    QGCLabel {
                        id: distunitText
                        text:  QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString
                        font.bold : true
                        anchors.right: parent.right
                        anchors.rightMargin: _toolsMargin
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Glow {
                        anchors.fill: distunitText
                        radius: 2
                        samples: 5
                        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
                        source: distunitText
                    }
                }

                Rectangle{
                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 3
                    Layout.rowSpan : 2
                    Layout.preferredWidth: 3
                    Layout.preferredHeight: 2
                    Layout.column : 0
                    Layout.row : 0
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: "transparent"
                    QGCLabel {
                        id:     altitudeValueText
                        text:   _vehicleAltitudeText
                        font.bold : true
                        font.pointSize : ScreenTools.defaultFontPointSize * 2.5
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Glow {
                        anchors.fill: altitudeValueText
                        radius: 2
                        samples: 5
                        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
                        source: altitudeValueText
                    }
                }

                Rectangle{
                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 4
                    Layout.rowSpan : 1
                    Layout.preferredWidth: 4
                    Layout.preferredHeight: 1
                    Layout.column : 0
                    Layout.row : 2
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: "transparent"
                    QGCLabel {
                        id: vsText
                        text:   "VS " + _vehicleVerticalSpeedText
                        font.bold : true
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Glow {
                        anchors.fill: vsText
                        radius: 2
                        samples: 5
                        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
                        source: vsText
                    }
                }
            }
        }

        Rectangle {
            id:                         groundSpeedValue
            anchors.margins:            _toolsMargin * 2
            anchors.right:              parent.left
            anchors.verticalCenter:     parent.verticalCenter
            height:                     ScreenTools.isMobile ? parent.height * 0.55 : parent.height * 0.45
            width:                      ScreenTools.isMobile ? parent.width : parent.width * 0.8
            color:                      "transparent" //"#80000000"
//            border.color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
//            border.width: 1
            radius:                     _toolsMargin

            GridLayout {
                id: leftIndicator
                anchors.fill: parent

                columns: 4
                rows: 3

                rowSpacing: 1

                Rectangle{
                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 1
                    Layout.rowSpan : 1
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 1
                    Layout.column : 0
                    Layout.row : 0
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: "transparent"
                    QGCLabel {
                        id: spdText
                        text: "SPD"
                        font.bold : true
                        anchors.left: parent.left
                        anchors.leftMargin: _toolsMargin
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Glow {
                        anchors.fill: spdText
                        radius: 2
                        samples: 5
                        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
                        source: spdText
                    }
                }

                Rectangle{
                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 1
                    Layout.rowSpan : 1
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 1
                    Layout.column : 0
                    Layout.row : 1
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: "transparent"
                    QGCLabel {
                        id: spdunitText
                        text:  QGroundControl.unitsConversion.appSettingsSpeedUnitsString
                        font.bold : true
                        anchors.left: parent.left
                        anchors.leftMargin: _toolsMargin
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Glow {
                        anchors.fill: spdunitText
                        radius: 2
                        samples: 5
                        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
                        source: spdunitText
                    }
                }

                Rectangle{
                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 3
                    Layout.rowSpan : 2
                    Layout.preferredWidth: 3
                    Layout.preferredHeight: 2
                    Layout.column : 1
                    Layout.row : 0
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: "transparent"
                    QGCLabel {
                        id: gndspdText
                        text:   _vehicleGroundSpeedText
                        font.bold : true
                        font.pointSize : ScreenTools.defaultFontPointSize * 2.5
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Glow {
                        anchors.fill: gndspdText
                        radius: 2
                        samples: 5
                        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
                        source: gndspdText
                    }
                }

                Rectangle{
                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan : 4
                    Layout.rowSpan : 1
                    Layout.preferredWidth: 4
                    Layout.preferredHeight: 1
                    Layout.column : 0
                    Layout.row : 2
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: "transparent"
                    QGCLabel {
                        id: dtohText
                        text:   "Home " + _distanceToHomeText
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Glow {
                        anchors.fill: dtohText
                        radius: 2
                        samples: 5
                        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
                        source: dtohText
                    }
                }
            }
        }

        CustomAttitudeHUD {
            size:                       parent.height
            vehicle:                    _activeVehicle
            anchors.horizontalCenter:   parent.horizontalCenter
        }

        Rectangle{
            id: gndSpdBarBase
            anchors.right: groundSpeedValue.left
            anchors.rightMargin: -(width*0.65)
            anchors.verticalCenter: parent.verticalCenter
            width: attitudeIndicator.width
            height: width
            color: "transparent"


            property int _startAngle : 100
            property int _sweepAngle : 160

            property real minValue: 0
            property real maxValue: 20

            property real value: _vehicleGroundSpeed

            Shape {
                id: shape
                anchors.fill: parent

                property int  dialWidth: ScreenTools.defaultFontPixelWidth * 1.6
                property int  strokeWidth: ScreenTools.defaultFontPixelWidth * 1.3
                property int  baseRadius: attitudeIndicator.height * 0.45
                property real radiusOffset: dialWidth / 2
                property int  penStyle: Qt.RoundCap

                layer.enabled: true
                layer.samples: 4

                ShapePath {
                    id: pathDial
                    strokeColor: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5) //root.dialColor
                    fillColor: "transparent"
                    strokeWidth: shape.dialWidth
                    capStyle: shape.penStyle

                    PathAngleArc {
                        radiusX: shape.baseRadius - shape.radiusOffset
                        radiusY: shape.baseRadius - shape.radiusOffset
                        centerX: gndSpdBarBase.width / 2
                        centerY: gndSpdBarBase.height / 2
                        startAngle: gndSpdBarBase._startAngle
                        sweepAngle: gndSpdBarBase._sweepAngle
                    }
                }

                ShapePath {
                    id: pathProgress
                    strokeColor: qgcPal.colorGreen
                    fillColor:  "transparent"
                    strokeWidth: shape.dialWidth - 5
                    capStyle: shape.penStyle

                    PathAngleArc {
                        id:      pathProgressArc
                        radiusX: shape.baseRadius - shape.radiusOffset
                        radiusY: shape.baseRadius - shape.radiusOffset
                        centerX: gndSpdBarBase.width / 2
                        centerY: gndSpdBarBase.height / 2
                        startAngle: gndSpdBarBase._startAngle
                        sweepAngle: (gndSpdBarBase._sweepAngle / gndSpdBarBase.maxValue * gndSpdBarBase.value)
                    }
                }
            }

            Rectangle{
                id: groundSpeedNeedleBase
                width: parent.width * 0.75
                height: parent.height * 0.75
                color: "transparent"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                Rectangle{
                    width: ScreenTools.defaultFontPixelWidth * 2.5
                    height: 2
                    anchors.left: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    color: qgcPal.text
                    antialiasing: true
                    smooth: true
                }

                transform: Rotation{
                    origin.x: groundSpeedNeedleBase.width / 2
                    origin.y: groundSpeedNeedleBase.height / 2
                    angle: gndSpdBarBase._startAngle + (gndSpdBarBase._sweepAngle / gndSpdBarBase.maxValue * gndSpdBarBase.value)
                }
            }
        }

        Rectangle{
            id: altBarBase
            anchors.left: altitudeValue.right
            anchors.leftMargin: -(width*0.65)
            anchors.verticalCenter: parent.verticalCenter
            width: attitudeIndicator.width
            height: width
            color: "transparent"

            property int _startAngle : 280
            property int _sweepAngle : 160

            property real minValue: 0
            property real maxValue: 7

            property real value: _vehicleVerticalSpeed

            Shape {
                id: shape1
                anchors.fill: parent

                property int  dialWidth: ScreenTools.defaultFontPixelWidth * 2
                property int  baseRadius: attitudeIndicator.height * 0.5
                property real radiusOffset: dialWidth / 2
                property int  penStyle: Qt.RoundCap

                layer.enabled: true
                layer.samples: 4

                ShapePath {
                    id: pathDial1
                    strokeColor: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5) //root.dialColor
                    fillColor: "transparent" //internals.transparentColor
                    strokeWidth: shape.dialWidth //root.dialWidth
                    capStyle: shape.penStyle

                    PathAngleArc {
                        radiusX: shape.baseRadius - shape.radiusOffset
                        radiusY: shape.baseRadius - shape.radiusOffset
                        centerX: altBarBase.width / 2
                        centerY: altBarBase.height / 2
                        startAngle: altBarBase._startAngle
                        sweepAngle: altBarBase._sweepAngle
                    }
                }

                ShapePath {
                    id: pathProgress1
                    strokeColor: (_vehicleVerticalSpeed >= 0) ? qgcPal.colorGreen : qgcPal.alertBackground //root.progressColor
                    fillColor:  "transparent" //internals.transparentColor
                    strokeWidth: shape.dialWidth - 5
                    capStyle: shape.penStyle

                    PathAngleArc {
                        id:      pathProgressArc1
                        radiusX: shape.baseRadius - shape.radiusOffset
                        radiusY: shape.baseRadius - shape.radiusOffset
                        centerX: altBarBase.width / 2
                        centerY: altBarBase.height / 2
                        startAngle: altBarBase._startAngle + 80
                        sweepAngle: -((altBarBase._sweepAngle / 2) / altBarBase.maxValue * altBarBase.value)
                    }
                }
            }

            Rectangle{
                id: altNeedleBase
                width: parent.width * 0.75
                height: parent.height * 0.75
                color: "transparent"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                Rectangle{
                    width: ScreenTools.defaultFontPixelWidth * 2.5
                    height: 2
                    anchors.left: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    color: qgcPal.text

                    antialiasing: true
                    smooth: true
                }

                transform: Rotation{
                    origin.x: groundSpeedNeedleBase.width / 2
                    origin.y: groundSpeedNeedleBase.height / 2
                    angle: -((altBarBase._sweepAngle / 2) / altBarBase.maxValue * altBarBase.value)
                }
            }
        }
    }
}


