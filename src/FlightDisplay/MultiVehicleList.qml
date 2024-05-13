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
import QtQuick.Layouts
import QtQuick.Shapes

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.Vehicle
import QGroundControl.FlightMap

Item {
    property real   _margin:            ScreenTools.defaultFontPixelWidth / 2
    property real   _widgetHeight:      ScreenTools.defaultFontPixelHeight * 3
    property color  _textColor:         qgcPal.text
    property real   _rectOpacity:       0.8
    property var    _guidedController:  globals.guidedControllerFlyView
    property real   _dataFontSize:  ScreenTools.isMobile ? ScreenTools.defaultFontPointSize * 0.8 : ScreenTools.defaultFontPointSize

    property string _readyToFlyText:    qsTr("Ready To Fly")
    property string _notReadyToFlyText: qsTr("Not Ready")
    property string _armedText:         qsTr("Armed")
    property string _flyingText:        qsTr("Flying")
    property string _landingText:       qsTr("Landing")

    QGCPalette { id: qgcPal }

    Rectangle {
        id:             mvCommands
        anchors.left:   parent.left
        anchors.right:  parent.right
        height:         mvCommandsColumn.height + (_margin *2)
        color:          Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, _rectOpacity)
        radius:         _margin

        DeadMouseArea {
            anchors.fill: parent
        }

        Column {
            id:                 mvCommandsColumn
            anchors.margins:    _margin
            anchors.top:        parent.top
            anchors.left:       parent.left
            anchors.right:      parent.right
            spacing:            _margin

            QGCLabel {
                anchors.left:   parent.left
                anchors.right:  parent.right
                text:           qsTr("The following commands will be applied to all vehicles")
                color:          _textColor
                wrapMode:       Text.WordWrap
                font.pointSize: ScreenTools.smallFontPointSize
            }

            Row {
                spacing:            _margin

                QGCButton {
                    text:       qsTr("Start Mission")
                    onClicked:  _guidedController.confirmAction(_guidedController.actionMVStartMission)
                }

                QGCButton {
                    text:       qsTr("Pause")
                    onClicked:  _guidedController.confirmAction(_guidedController.actionMVPause)
                }                
            }
        }
    }

    QGCListView {
        id:                 missionItemEditorListView
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.topMargin:  _margin
        anchors.top:        mvCommands.bottom
        anchors.bottom:     parent.bottom
        spacing:            ScreenTools.defaultFontPixelHeight / 2
        orientation:        ListView.Vertical
        model:              QGroundControl.multiVehicleManager.vehicles
        cacheBuffer:        _cacheBuffer < 0 ? 0 : _cacheBuffer
        clip:               true

        property real _cacheBuffer:     height * 2

        delegate: Rectangle {
            width:      missionItemEditorListView.width
            height:     innerColumn.y + innerColumn.height + _margin
            color:      qgcPal.window
            opacity:    _rectOpacity
            radius:     _margin
            border.color: _vehicle.id === QGroundControl.multiVehicleManager.activeVehicle.id ? qgcPal.missionItemEditor : "transparent"
            border.width: 2           

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if(_vehicle.id !== QGroundControl.multiVehicleManager.activeVehicle.id){
                        var vehicleId = vehicleIdLabel.text //textAt(index).split(" ")[1]
                        var vehicle = QGroundControl.multiVehicleManager.getVehicleById(vehicleId)
                        QGroundControl.multiVehicleManager.activeVehicle = vehicle
                        busyIndicator.visible = true
                    }
                }
            }

            property var    _vehicle:   object           

            ColumnLayout {
                id:                 innerColumn
                anchors.margins:    _margin
                anchors.top:        parent.top
                anchors.left:       parent.left
                anchors.right:      parent.right
                spacing:            _margin

                property bool   _healthAndArmingChecksSupported:    _vehicle ? _vehicle.healthAndArmingCheckReport.supported : false

                function mainStatusText() {
                    if (_vehicle) {
                        if (_vehicle.armed) {
                            if (_vehicle.flying) {
                                return _flyingText
                            } else if (_vehicle.landing) {
                                return _landingText
                            } else {
                                return _armedText
                            }
                        } else {
                            if (_healthAndArmingChecksSupported) {
                                if (_vehicle.healthAndArmingCheckReport.canArm) {
                                    return _readyToFlyText
                                } else {
                                    return _notReadyToFlyText
                                }
                            } else if (_vehicle.readyToFlyAvailable) {
                                if (_vehicle.readyToFly) {
                                    return _readyToFlyText
                                } else {
                                    return _notReadyToFlyText
                                }
                            } else {
                                // Best we can do is determine readiness based on AutoPilot component setup and health indicators from SYS_STATUS
                                if (_vehicle.allSensorsHealthy && _vehicle.autopilot.setupComplete) {
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

                RowLayout {
                    Layout.fillWidth:       true

                    Rectangle {
                        Layout.alignment: Qt.AlignTop
                        height:     ScreenTools.defaultFontPixelHeight * 1.5
                        width:      height
                        radius:     _margin
                        color:      "transparent"
                        border.color:   qgcPal.text

                        QGCLabel {
                            id: vehicleIdLabel
                            //Layout.alignment:   Qt.AlignTop
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter:   parent.verticalCenter
                            text:               _vehicle ? _vehicle.id : ""
                            color:              _textColor
                        }

                        // MouseArea {
                        //     anchors.fill: parent
                        //     onClicked: {
                        //         var vehicleId = vehicleIdLabel.text //textAt(index).split(" ")[1]
                        //         var vehicle = QGroundControl.multiVehicleManager.getVehicleById(vehicleId)
                        //         QGroundControl.multiVehicleManager.activeVehicle = vehicle
                        //     }
                        // }
                    }

                    Rectangle{
                        id: root
                        width:              _widgetHeight
                        height:             width
                        Layout.alignment:   Qt.AlignHCenter
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

                                property var _batteryGroup:          _vehicle && _vehicle.batteries.count ? _vehicle.batteries.get(0) : undefined
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
                                    font.pointSize:             _dataFontSize * 0.7
                                }
                                QGCLabel {
                                    text:                       battFeeder.value + " %"
                                    anchors.horizontalCenter:   parent.horizontalCenter
                                    horizontalAlignment:        Text.AlignHCenter
                                    font.bold:                  true
                                    font.pointSize:             _dataFontSize * 0.9
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.alignment:   Qt.AlignCenter
                        spacing:            _margin

                        QGCLabel {
                            Layout.alignment:           Qt.AlignHCenter
                            text:                       innerColumn.mainStatusText()//_vehicle && _vehicle.armed ? qsTr("Armed") : qsTr("Disarmed")
                            color:                      _textColor
                        }

                        FlightModeMenu {
                            Layout.alignment:           Qt.AlignHCenter
                            font.pointSize:             ScreenTools.largeFontPointSize
                            color:                      _textColor
                            currentVehicle:             _vehicle
                        }

                        RowLayout {
                            Layout.alignment:           Qt.AlignHCenter

                            Row {
                                spacing: ScreenTools.defaultFontPixelWidth / 2

                                QGCColoredImage{
                                    anchors.top:        parent.top
                                    anchors.bottom:     parent.bottom
                                    width:              height
                                    source:             "/InstrumentValueIcons/arrow-thick-up.svg"
                                    fillMode:           Image.PreserveAspectFit
                                    sourceSize.height:  height * 0.8
                                    color:              qgcPal.text
                                }

                                QGCLabel {
                                    property real   _altitudeValue:         _vehicle ? _vehicle.altitudeRelative.rawValue.toFixed(1) : 0

                                    Layout.alignment:   Qt.AlignHCenter
                                    text:               _altitudeValue
                                                        ? QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_altitudeValue).toFixed(1) +" "+ QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString
                                                        : "-- " + QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString
                                    font.pointSize:     ScreenTools.smallFontPointSize
                                }
                            }

                            Row {
                                spacing: ScreenTools.defaultFontPixelWidth

                                QGCColoredImage{
                                    anchors.top:        parent.top
                                    anchors.bottom:     parent.bottom
                                    width:              height
                                    source:             "/qmlimages/Gps.svg"
                                    fillMode:           Image.PreserveAspectFit
                                    sourceSize.height:  height * 0.8
                                    color:              qgcPal.text
                                }

                                QGCLabel {
                                    Layout.alignment:   Qt.AlignHCenter
                                    text:               _vehicle ? _vehicle.gps.lock.enumStringValue + " (" + _vehicle.gps.count.valueString + ")" : ""
                                    font.pointSize:     ScreenTools.smallFontPointSize
                                }
                            }
                        }
                    }

                    // QGCCompassWidget {
                    //     size:       _widgetHeight
                    //     usedByMultipleVehicleList: true
                    //     vehicle:    _vehicle
                    // }

                    // QGCAttitudeWidget {
                    //     size:       _widgetHeight
                    //     vehicle:    _vehicle
                    // }
                } // RowLayout

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(qgcPal.text.r, qgcPal.text.g, qgcPal.text.b, 0.7)
                }

                SliderSwitch {
                    id: slider
                    visible:            _vehicle && !_vehicle.armed
                    confirmText:        qsTr("Arm")
                    Layout.alignment:   Qt.AlignVCenter | Qt.AlignHCenter

                    onAccept: {
                        _vehicle.armed = true
                    }
                }

                Row {
                    // Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    spacing: ScreenTools.defaultFontPixelWidth

                    // QGCButton {
                    //     text:       qsTr("Arm")
                    //     visible:    _vehicle && !_vehicle.armed
                    //     onClicked:  _vehicle.armed = true
                    // }

                    QGCButton {
                        text:       qsTr("Disarm")
                        visible:    _vehicle && _vehicle.armed && !_vehicle.flying
                        onClicked:  _vehicle.armed = false
                    }

                    QGCButton {
                        text:       qsTr("Start Mission")
                        visible:    _vehicle && _vehicle.armed && _vehicle.flightMode !== _vehicle.missionFlightMode
                        onClicked:  _vehicle.startMission()
                    }

                    // QGCButton {
                    //     text:       qsTr("Pause")
                    //     visible:    _vehicle && _vehicle.armed && _vehicle.pauseVehicleSupported
                    //     onClicked:  _vehicle.pauseVehicle()
                    // }

                    QGCButton {
                        text:       qsTr("RTL")
                        visible:    _vehicle && _vehicle.armed && _vehicle.flying && _vehicle.flightMode !== _vehicle.rtlFlightMode
                        onClicked:  _vehicle.flightMode = _vehicle.rtlFlightMode
                    }

                    QGCButton {
                        text:       qsTr("Take control")
                        visible:    _vehicle && _vehicle.armed && _vehicle.flying && _vehicle.flightMode !== _vehicle.takeControlFlightMode
                        onClicked:  _vehicle.flightMode = _vehicle.takeControlFlightMode
                    }
                } // Row
            } // ColumnLayout            

            BusyIndicator {
                id:         busyIndicator
                height:     ScreenTools.defaultFontPixelHeight * 3
                width:      height
                visible:    false
                anchors.horizontalCenter:   parent.horizontalCenter
                anchors.verticalCenter:     parent.verticalCenter

                running:    true

                palette.dark: "white"

                property string vehicleId: QGroundControl.multiVehicleManager.activeVehicle.id
                onVehicleIdChanged: {
                    if(_vehicle.id === QGroundControl.multiVehicleManager.activeVehicle.id) {
                        visible = false
                    }
                }
            }
        } // delegate - Rectangle
    } // QGCListView
} // Item
