/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick              2.15
import QtLocation           5.3
import QtPositioning        5.3
import QtGraphicalEffects   1.0
import QtQuick.Layouts      1.2
import QtQuick.Shapes       1.15

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0
import QGroundControl.Controls      1.0
import QGroundControl.MultiVehicleManager 1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0
import QGroundControl.Palette       1.0

/// Marker for displaying a vehicle location on the map
MapQuickItem {
    anchorPoint.x:  vehicleItem.width  / 2
    anchorPoint.y:  vehicleItem.height / 2
    visible:        coordinate.isValid

    property var    map
    property var    _map:           map

    property real   _dataFontSize:  ScreenTools.isMobile ? ScreenTools.defaultFontPointSize * 0.8 : ScreenTools.defaultFontPointSize

    property string _flightMode:                        object ? object.flightMode.toString() : ""
    property real   _altitudeValue:                     object ? object.altitudeRelative.rawValue.toFixed(1) : 0
    property bool   _healthAndArmingChecksSupported:    object ? object.healthAndArmingCheckReport.supported : false

    property string _readyToFlyText:    qsTr("Ready To Fly")
    property string _notReadyToFlyText: qsTr("Not Ready")
    property string _armedText:         qsTr("Armed")
    property string _flyingText:        qsTr("Flying")
    property string _landingText:       qsTr("Landing")

    function mainStatusText() {
        if (object) {
            if (object.armed) {
                if (object.flying) {
                    return _flyingText
                } else if (object.landing) {
                    return _landingText
                } else {
                    return _armedText
                }
            } else {
                if (_healthAndArmingChecksSupported) {
                    if (object.healthAndArmingCheckReport.canArm) {
                        return _readyToFlyText
                    } else {
                        return _notReadyToFlyText
                    }
                } else if (object.readyToFlyAvailable) {
                    if (object.readyToFly) {
                        return _readyToFlyText
                    } else {
                        return _notReadyToFlyText
                    }
                } else {
                    // Best we can do is determine readiness based on AutoPilot component setup and health indicators from SYS_STATUS
                    if (object.allSensorsHealthy && object.autopilot.setupComplete) {
                        return _readyToFlyText
                    } else {
                        return _notReadyToFlyText
                    }
                }
            }
        } else {
            return qsTr("Unknown")
        }
    }

    sourceItem: Item {
        id:         vehicleItem

        Rectangle {
            id:         atmosphericValueBar
            height:     vehicleStatusColumn.height + ScreenTools.defaultFontPixelHeight * 0.4
            width:      vehicleStatusColumn.width + ScreenTools.defaultFontPixelHeight
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: ScreenTools.defaultFontPixelHeight * 2
            color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
            radius:     ScreenTools.defaultFontPixelHeight / 2

            Column{
                id:                 vehicleStatusColumn
                spacing:            ScreenTools.defaultFontPixelHeight / 5
                //width:              Math.max(vehicleStatusLabel.width, vehicleStatusGrid.width)
                anchors.margins:    ScreenTools.defaultFontPixelHeight
                anchors.centerIn:   parent

                QGCLabel {
                    id:             vehicleStatusLabel
                    text:           object ? qsTr("Vehicle")+" "+object.id : ""
                    font.family:    ScreenTools.demiboldFontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                RowLayout {
                    id:                         vehicleStatusGrid
                    anchors.margins:            ScreenTools.defaultFontPixelHeight
                    //columnSpacing:              ScreenTools.defaultFontPixelHeight
                    anchors.horizontalCenter:   parent.horizontalCenter
                    //columns: 2

                    Rectangle{
                        id: root
                        width:              ScreenTools.defaultFontPixelHeight * 3.5
                        height:             width
                        Layout.alignment:   Qt.AlignHCenter
                        Layout.rowSpan: 3
                        color:              "transparent"

                        property real   startAngle:         0
                        property real   spanAngle:          360
                        property real   minValue:           0
                        property real   maxValue:           100
                        property int    dialWidth:          ScreenTools.defaultFontPixelWidth * 0.6

                        property color  backgroundColor:    "transparent"
                        property color  dialColor:          Qt.rgba(qgcPal.text.r, qgcPal.text.g, qgcPal.text.b, 0.3)
                        property color  progressColor:      qgcPal.textHighlight

                        property int    penStyle:           Qt.RoundCap

                        Rectangle{
                            id: background
                            width:                      parent.width
                            height:                     width
                            anchors.horizontalCenter:   parent.horizontalCenter
                            anchors.verticalCenter:     parent.verticalCenter
                            radius:                     width * 0.5
                            color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.9)

                            QtObject {
                                id: internals

                                property real baseRadius: background.width * 0.45
                                property real radiusOffset: internals.isFullDial ? root.dialWidth * 0.4 : root.dialWidth * 0.4
                                property real actualSpanAngle: internals.isFullDial ? 360 : root.spanAngle
                                property color transparentColor: "transparent"
                                property color dialColor: internals.isNoDial ? internals.transparentColor : root.dialColor
                            }

                            QtObject {
                                id: battFeeder

                                property var _batteryGroup:          object && object.batteries.count ? object.batteries.get(0) : undefined
                                property var _battVoltageValue:      _batteryGroup ? _batteryGroup.voltage.value : 0
                                property var _battVoltageCheck:      isNaN(_battVoltageValue) ? 0 : _battVoltageValue
                                property var _battRemaining:         _batteryGroup ? _batteryGroup.percentRemaining.value : 0
                                property var _battRemainingCheck:    isNaN(_battRemaining) ? 0 : _battRemaining

                                property real   value:                  _battRemainingCheck
                            }

                            Shape {
                                id: shape
                                anchors.fill:               parent
                                anchors.verticalCenter:     background.verticalCenter
                                anchors.horizontalCenter:   background.horizontalCenter

                                property real battValue:    battFeeder.value

                                ShapePath {
                                    id: pathBackground
                                    strokeColor:    internals.transparentColor
                                    fillColor:      root.backgroundColor
                                    capStyle:       root.penStyle

                                    PathAngleArc {
                                        radiusX:    internals.baseRadius - root.dialWidth
                                        radiusY:    internals.baseRadius - root.dialWidth
                                        centerX:    background.width / 2
                                        centerY:    background.height / 2
                                        startAngle: 0
                                        sweepAngle: 360
                                    }
                                }

                                ShapePath {
                                    id: battPathDial
                                    strokeColor: root.dialColor
                                    fillColor: internals.transparentColor
                                    strokeWidth: root.dialWidth
                                    capStyle: root.penStyle

                                    PathAngleArc {
                                        radiusX: internals.baseRadius - internals.radiusOffset
                                        radiusY: internals.baseRadius - internals.radiusOffset
                                        centerX: background.width / 2
                                        centerY: background.height / 2
                                        startAngle: root.startAngle - 90
                                        sweepAngle: internals.actualSpanAngle
                                    }
                                }

                                ShapePath {
                                    id: battPathProgress
                                    strokeColor: qgcPal.brandingBlue // root.progressColor
                                    fillColor: internals.transparentColor
                                    strokeWidth: root.dialWidth
                                    capStyle: root.penStyle

                                    PathAngleArc {
                                        id:      battPathProgressArc
                                        radiusX: internals.baseRadius - internals.radiusOffset
                                        radiusY: internals.baseRadius - internals.radiusOffset
                                        centerX: background.width / 2
                                        centerY: background.height / 2
                                        startAngle: root.startAngle - 90
                                        sweepAngle: -(internals.actualSpanAngle / root.maxValue * shape.battValue)
                                    }
                                }
                            }

                            Column {
                                anchors.horizontalCenter:   background.horizontalCenter
                                anchors.verticalCenter:     background.verticalCenter
                                QGCLabel {
                                    text:                       "Batt"
                                    anchors.horizontalCenter:   parent.horizontalCenter
                                    horizontalAlignment:        Text.AlignHCenter
                                    font.pointSize:             _dataFontSize * 0.8
                                }
                                QGCLabel {
                                    text:                       battFeeder.value + " %"
                                    anchors.horizontalCenter:   parent.horizontalCenter
                                    horizontalAlignment:        Text.AlignHCenter
                                    font.bold:                  true
                                    font.pointSize:             _dataFontSize * 1.1
                                }
                            }
                        }
                    }

                    Column {
                        LabelledLabel {
                            label: qsTr("STS")
                            labelText: mainStatusText()
                        }

                        LabelledLabel {
                            label: qsTr("FLT")
                            labelText: object ? _flightMode : "Unknown"
                        }

                        LabelledLabel {
                            label: qsTr("ALT")
                            labelText: _altitudeValue ? QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_altitudeValue).toFixed(1) +" "+ QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString: "Unknown"
                        }
                    }
                } // GridLayout
            } // Column
        } // Rectangle
    }
}
