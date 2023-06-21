import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts  1.2
import QtQuick.Dialogs  1.2

import QGroundControl                   1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.Controls          1.0
import QGroundControl.FactControls      1.0
import QGroundControl.Palette           1.0

Rectangle {
    id:     missionProgressRect
    height: ScreenTools.defaultFontPixelHeight * 4 // missionStats.height + _margins
    width: missionStats.width + _margins * 2
    color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
    radius: _margins
// form
    property real   _dataFontSize:              ScreenTools.defaultFontPointSize
    property real   _largeValueWidth:           ScreenTools.defaultFontPixelWidth * 8
    property real   _mediumValueWidth:          ScreenTools.defaultFontPixelWidth * 4
    property real   _smallValueWidth:           ScreenTools.defaultFontPixelWidth * 3
    property real   _labelToValueSpacing:       ScreenTools.defaultFontPixelWidth
    property real   _rowSpacing:                ScreenTools.isMobile ? 1 : 0

// Vehicle
    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle
    property real   _heading:               _activeVehicle   ? _activeVehicle.heading.rawValue : 0
    property bool   _available:             !isNaN(_activeVehicle.vibration.xAxis.rawValue)

    property real   _vehicleAltitude:           _activeVehicle ? _activeVehicle.altitudeRelative.rawValue : 0
    property real   _vehicleVerticalSpeed:      _activeVehicle ? _activeVehicle.climbRate.rawValue : 0
    property real   _vehicleGroundSpeed:        _activeVehicle ? _activeVehicle.groundSpeed.rawValue : 0
    property real   _latitude:                  _activeVehicle ? _activeVehicle.gps.lat.rawValue : NaN
    property real   _longitude:                 _activeVehicle ? _activeVehicle.gps.lon.rawValue : NaN
    property real   _flightDistance:            _activeVehicle ? _activeVehicle.flightDistance.rawValue : 20
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
    property string _missionProgressText:       isNaN(_missionProgress) ? "--.- %" : _missionProgress.toFixed(1) + " %"

    property bool   isVerticalMission:          (_missionDistance < (_missionPathDistance - _missionDistance)) ? true : false

    readonly property real _margins: ScreenTools.defaultFontPixelWidth

    function getMissionTime() {
        if (!_missionTime) {
            return "00:00:00"
        }
        var t = new Date(2021, 0, 0, 0, 0, Number(_missionTime))
        var days = Qt.formatDateTime(t, 'dd')
        var complete

        if (days == 31) {
            days = '0'
            complete = Qt.formatTime(t, 'hh:mm:ss')
        } else {
            complete = days + " days " + Qt.formatTime(t, 'hh:mm:ss')
        }
        return complete
    }

    function getMissionProgress() {
        var pct = _flightDistance / _missionDistance
        if (pct > 0.95){
            pct = 1
        }
        _missionProgress = pct * 100
        return pct
    }

    GridLayout {
        id: missionStats
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.left:           parent.left
        anchors.leftMargin:     _margins
        columns:                6
        rowSpacing:             _rowSpacing
        columnSpacing:          _labelToValueSpacing
        Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter

        Rectangle {
            id:             largeProgressBar
            Layout.fillWidth: true
            Layout.columnSpan:  6
            Layout.rowSpan: 1
            Layout.minimumHeight: ScreenTools.defaultFontPixelHeight
            color:          qgcPal.window
            border.color:   qgcPal.text
            border.width:   1
            radius:         _margins * 0.5
            visible:        !isVerticalMission

            Rectangle {
                anchors.top:    parent.top
                anchors.bottom: parent.bottom
                width:          getMissionProgress() * parent.width
                color:          qgcPal.textHighlight
                radius:         _margins * 0.5
            }

            QGCLabel {
                anchors.centerIn:   parent
                text:               _missionProgressText
                font.pointSize:     ScreenTools.smallFontPointSize
            }
        }

        QGCLabel { text: qsTr("Altitude:"); font.pointSize: _dataFontSize; }
        QGCLabel {
            text:                   _vehicleAltitudeText
            font.pointSize:         _dataFontSize
            Layout.minimumWidth:    _largeValueWidth
        }


        QGCLabel { text: qsTr("Latitude:"); font.pointSize: _dataFontSize; }
        QGCLabel {
            text:                   _latitudeText
            font.pointSize:         _dataFontSize
            Layout.minimumWidth:    _largeValueWidth
        }

        QGCLabel { text: qsTr("Longitude:"); font.pointSize: _dataFontSize; }
        QGCLabel {
            text:                   _longitudeText
            font.pointSize:         _dataFontSize
            Layout.minimumWidth:    _largeValueWidth
        }

        QGCLabel { text: qsTr("H.Distance:"); font.pointSize: _dataFontSize; }
        QGCLabel {
            text:                   _missionDistanceText
            font.pointSize:         _dataFontSize
            Layout.minimumWidth:    _largeValueWidth
        }

        QGCLabel { text: qsTr("Path Distance:"); font.pointSize: _dataFontSize; }
        QGCLabel {
            text:                   _missionPathDistanceText
            font.pointSize:         _dataFontSize
            Layout.minimumWidth:    _largeValueWidth
        }

        QGCLabel { text: qsTr("Total Time:"); font.pointSize: _dataFontSize; }
        QGCLabel {
            text:                   getMissionTime()
            font.pointSize:         _dataFontSize
            Layout.minimumWidth:    _largeValueWidth
        }

//        QGCLabel { text: qsTr("Mission Seq:"); font.pointSize: _dataFontSize; }
//        QGCLabel {
//            text:                   _missionItemIndex + " / " + _missionItemCount
//            font.pointSize:         _dataFontSize
//            Layout.minimumWidth:    _largeValueWidth
//        }
    }

}

