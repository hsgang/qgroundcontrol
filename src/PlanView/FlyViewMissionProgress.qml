import QtQuick          2.15
import QtQuick.Controls 1.2
import QtQuick.Layouts  1.2
import QtQuick.Dialogs  1.2
import QtGraphicalEffects 1.0
import QtQuick.Shapes   1.15

import QGroundControl                   1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.Controls          1.0
import QGroundControl.FactSystem        1.0
import QGroundControl.FactControls      1.0
import QGroundControl.Palette           1.0

Rectangle {
    id:     missionProgressRect
    height: childrenRect.height//ScreenTools.defaultFontPixelHeight * 3.2 // missionStats.height + _margins
    width:  childrenRect.width//missionStatsGrid.width + _margins * 2
    color: "transparent"
    radius: _margins

//    property bool parameterAvailable:   _activeVehicle && QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable
//    property Fact wpnavSpeed:           parameterAvailable ? controller.getParameterFact(-1, "WPNAV_SPEED") : null
//    property string wpnavSpeedString:   parameterAvailable ? wpnavSpeed.valueString + " " + wpnavSpeed.units : "unknown"

//    FactPanelController { id: controller; }

// form
    property real   _dataFontSize:              ScreenTools.defaultFontPointSize * 0.8
    property real   _largeValueWidth:           ScreenTools.defaultFontPixelWidth * 8
    property real   _mediumValueWidth:          ScreenTools.defaultFontPixelWidth * 4
    property real   _smallValueWidth:           ScreenTools.defaultFontPixelWidth * 3
    property real   _labelToValueSpacing:       0 //ScreenTools.defaultFontPixelWidth * 0.5
    property real   _rowSpacing:                ScreenTools.isMobile ? 1 : 0

// Vehicle
    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property real   _heading:               _activeVehicle   ? _activeVehicle.heading.rawValue : 0

    property real   _vehicleAltitude:           _activeVehicle ? _activeVehicle.altitudeRelative.rawValue : 0
    property real   _vehicleVerticalSpeed:      _activeVehicle ? _activeVehicle.climbRate.rawValue : 0
    property real   _vehicleGroundSpeed:        _activeVehicle ? _activeVehicle.groundSpeed.rawValue : 0
    property real   _latitude:                  _activeVehicle ? _activeVehicle.gps.lat.rawValue : NaN
    property real   _longitude:                 _activeVehicle ? _activeVehicle.gps.lon.rawValue : NaN
    property real   _flightDistance:            _activeVehicle ? _activeVehicle.flightDistance.rawValue : 20
    property real   _cameraTriggerCount:        _activeVehicle ? _activeVehicle.cameraTriggerPoints.count : 0
    property string _vehicleAltitudeText:       isNaN(_vehicleAltitude) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsVerticalDistanceUnits(_vehicleAltitude).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString
    property string _vehicleVerticalSpeedText:  isNaN(_vehicleVerticalSpeed) ? "-.-" : QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_vehicleVerticalSpeed).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsSpeedUnitsString
    property string _vehicleGroundSpeedText:    isNaN(_vehicleGroundSpeed) ? "-.-" : QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_vehicleGroundSpeed).toFixed(1)
    property string _latitudeText:              isNaN(_latitude) ? "-.-" : _latitude.toFixed(7)
    property string _longitudeText:             isNaN(_longitude) ? "-.-" : _longitude.toFixed(7)
    property string _flightDistanceText:        isNaN(_flightDistance) ? "-.-" : _flightDistance.toFixed(1)
    property real   _missionItemIndex:          _activeVehicle ? _activeVehicle.missionItemIndex.rawValue : 0

// Mission
    property var    _planMasterController:      globals.planMasterControllerPlanView
    property var    _currentMissionItem:        globals.currentPlanMissionItem          ///< Mission item to display status for

    property var    missionItems:               _controllerValid ? _planMasterController.missionController.visualItems : undefined
    property real   missionDistance:            _controllerValid ? _planMasterController.missionController.missionDistance : NaN
    property real   missionPathDistance:        _controllerValid ? _planMasterController.missionController.missionPathDistance : NaN
    property real   missionTime:                _controllerValid ? _planMasterController.missionController.missionTime : 0
    property real   missionItemCount:           _controllerValid ? _planMasterController.missionController.missionItemCount : NaN

    property bool   _controllerValid:           _planMasterController !== undefined && _planMasterController !== null
    property bool   _controllerOffline:         _controllerValid ? _planMasterController.offline : true
    property var    _controllerDirty:           _controllerValid ? _planMasterController.dirty : false

    property bool   _missionValid:              missionItems !== undefined

    property real   _missionDistance:           _missionValid ? missionDistance : NaN
    property real   _missionPathDistance:       _missionValid ? missionPathDistance : NaN
    property real   _missionTime:               _missionValid ? missionTime : 0
    property real   _missionItemCount:          _missionValid ? missionItemCount : NaN

    property string _missionDistanceText:       isNaN(_missionDistance) ?       "-.-" : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionDistance).toFixed(0) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
    property string _missionPathDistanceText:   isNaN(_missionPathDistance) ?   "-.-" : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionPathDistance).toFixed(0) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString

    property real   _missionProgress:           0
    property string _missionProgressText:       isNaN(_missionProgress) ? "Waiting" : _missionProgress.toFixed(1) + " %"

    property bool   isVerticalMission:          (_missionDistance < (_missionPathDistance - _missionDistance)) ? true : false

    readonly property real _margins: ScreenTools.defaultFontPixelWidth

    function getMissionTime() {
        if (!_missionTime) {
            return "00:00:00"
        }
        var t = new Date(2021, 0, 0, 0, 0, Number(_missionTime))
        var days = Qt.formatDateTime(t, 'dd')
        var complete

        if (days === '31') {
            days = '0'
            complete = Qt.formatTime(t, 'hh:mm:ss')
        } else {
            complete = days + " days " + Qt.formatTime(t, 'hh:mm:ss')
        }
        return complete
    }

    function getMissionProgress() {
        var pctValue = 0
        var pct = _flightDistance / _missionDistance
        var itempct = _missionItemIndex / (_missionItemCount - 1)
        if (pct > 0.9){
            pct = 1
        }
        if (_missionItemIndex > 0) {
            pctValue = (pct + itempct) / 2;
        }
        _missionProgress = pctValue * 100
        return pctValue
    }

    Rectangle{
        id: root

        width: backgroundGrid.width
        height: width + statsGridRect.height + (_margins * 3)
        color:  Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
        radius: width * 0.5

        property real startAngle: 0
        property real spanAngle: 360
        property real minValue: 0
        property real maxValue: 100
        property int  dialWidth: 15

        property color backgroundColor: "transparent"
        property color dialColor: Qt.rgba(qgcPal.text.r, qgcPal.text.g, qgcPal.text.b, 0.6)//"#FF505050"
        property color progressColor: qgcPal.textHighlight //qgcPal.buttonHighlight // "#FFA51BAB"

        property int penStyle: Qt.RoundCap

        signal pressSignal
        signal releaseSignal
        signal confirmSignal

        ColumnLayout {
            id:     backgroundGrid
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: _margins * 2

            Rectangle{
                id: background
                width: ScreenTools.defaultFontPixelWidth * 10
                height : width
                Layout.alignment: Qt.AlignHCenter
                //anchors.horizontalCenter: parent.horizontalCenter
                //anchors.verticalCenter: parent.verticalCenter
                radius: width * 0.5
                color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)

                QtObject {
                    id: internals

                    property real baseRadius: Math.min(background.width * 0.6, background.height * 0.6)
                    property real radiusOffset: internals.isFullDial ? root.dialWidth * 0.3 : root.dialWidth * 0.3
                    property real actualSpanAngle: internals.isFullDial ? 360 : root.spanAngle
                    property color transparentColor: "transparent"
                    property color dialColor: internals.isNoDial ? internals.transparentColor : root.dialColor
                }

                QtObject {
                    id: feeder

                    property real value: getMissionProgress() * 100
                }

                Shape {
                    id: shape
                    anchors.fill: parent
                    anchors.verticalCenter: background.verticalCenter
                    anchors.horizontalCenter: background.horizontalCenter

                    property real value: feeder.value

                    ShapePath {
                        id: pathBackground
                        strokeColor: internals.transparentColor
                        fillColor: root.backgroundColor
                        capStyle: root.penStyle

                        PathAngleArc {
                            radiusX: internals.baseRadius - root.dialWidth
                            radiusY: internals.baseRadius - root.dialWidth
                            centerX: background.width / 2
                            centerY: background.height / 2
                            startAngle: 0
                            sweepAngle: 360
                        }
                    }

                    ShapePath {
                        id: pathDial
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
                        id: pathProgress
                        strokeColor: root.progressColor
                        fillColor: internals.transparentColor
                        strokeWidth: root.dialWidth
                        capStyle: root.penStyle

                        PathAngleArc {
                            id:      pathProgressArc
                            radiusX: internals.baseRadius - internals.radiusOffset
                            radiusY: internals.baseRadius - internals.radiusOffset
                            centerX: background.width / 2
                            centerY: background.height / 2
                            startAngle: root.startAngle - 90
                            sweepAngle: (internals.actualSpanAngle / root.maxValue * (shape.value * 1.05))
                        }
                    }
                }

                QGCLabel {
                    text:                       _missionProgressText
                    anchors.horizontalCenter:   background.horizontalCenter
                    anchors.verticalCenter:     background.verticalCenter
                    horizontalAlignment:        Text.AlignVCenter
                    wrapMode:                   Text.WordWrap
                    font.bold:                  true
                    font.pointSize:             ScreenTools.defaultFontPointSize * 1.2
                }
            }

            Rectangle {
                id:     statsGridRect
                height: statsGrid.height + _margins * 3
                width:  statsGrid.width + _margins * 2
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                //color:  Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
                //border.color: "white"
                color:          "transparent"
                radius: _margins

                GridLayout {
                    id: statsGrid
                    anchors.top:            parent.top
                    anchors.topMargin:      _margins
                    anchors.left:           parent.left
                    anchors.leftMargin:     _margins
                    columns:                2
                    rowSpacing:             _rowSpacing
                    columnSpacing:          _labelToValueSpacing
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter

                    QGCLabel { text: qsTr("Altitude: "); font.pointSize: _dataFontSize; opacity: 0.7;}
                    QGCLabel {
                        text:                   _vehicleAltitudeText
                        font.pointSize:         _dataFontSize
                        Layout.minimumWidth:    _largeValueWidth
                        horizontalAlignment:    Text.AlignRight
                    }

                    QGCLabel { text: qsTr("Latitude: "); font.pointSize: _dataFontSize; opacity: 0.7; }
                    QGCLabel {
                        text:                   _latitudeText
                        font.pointSize:         _dataFontSize
                        Layout.minimumWidth:    _largeValueWidth
                        horizontalAlignment:    Text.AlignRight
                    }

                    QGCLabel { text: qsTr("Longitude: "); font.pointSize: _dataFontSize; opacity: 0.7; }
                    QGCLabel {
                        text:                   _longitudeText
                        font.pointSize:         _dataFontSize
                        Layout.minimumWidth:    _largeValueWidth
                        horizontalAlignment:    Text.AlignRight
                    }

//                    QGCLabel { text: qsTr("H.Distance: "); font.pointSize: _dataFontSize; opacity: 0.7; }
//                    QGCLabel {
//                        text:                   _missionDistanceText
//                        font.pointSize:         _dataFontSize
//                        Layout.minimumWidth:    _largeValueWidth
//                        horizontalAlignment:    Text.AlignRight
//                    }

                    QGCLabel { text: qsTr("Path Distance: "); font.pointSize: _dataFontSize; opacity: 0.7; }
                    QGCLabel {
                        text:                   _missionPathDistanceText
                        font.pointSize:         _dataFontSize
                        Layout.minimumWidth:    _largeValueWidth
                        horizontalAlignment:    Text.AlignRight
                    }

                    QGCLabel { text: qsTr("Total Time: "); font.pointSize: _dataFontSize; opacity: 0.7; }
                    QGCLabel {
                        text:                   getMissionTime()
                        font.pointSize:         _dataFontSize
                        Layout.minimumWidth:    _largeValueWidth
                        horizontalAlignment:    Text.AlignRight
                    }

                    QGCLabel { text: qsTr("Mission Seq: "); font.pointSize: _dataFontSize; opacity: 0.7; }
                    QGCLabel {
                        text:                   _missionItemIndex + " / " + (_missionItemCount -1)
                        font.pointSize:         _dataFontSize
                        Layout.minimumWidth:    _largeValueWidth
                        horizontalAlignment:    Text.AlignRight
                    }

                    QGCLabel { text: qsTr("Captures: "); font.pointSize: _dataFontSize; opacity: 0.7; }
                    QGCLabel {
                        text:                   _cameraTriggerCount
                        font.pointSize:         _dataFontSize
                        Layout.minimumWidth:    _largeValueWidth
                        horizontalAlignment:    Text.AlignRight
                    }

//                    QGCLabel { text: qsTr("text:"); font.pointSize: _dataFontSize; }
//                    QGCLabel {
//                        text:                   wpnavSpeedString
//                        font.pointSize:         _dataFontSize
//                        Layout.minimumWidth:    _largeValueWidth
//                    }
                }
            }
        }

    }
}
