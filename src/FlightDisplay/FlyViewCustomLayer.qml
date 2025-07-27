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
import QtMultimedia

import QtLocation
import QtPositioning
import QtQuick.Window
import QtQml.Models

import QGroundControl

import QGroundControl.Controls

import QGroundControl.FlightDisplay
import QGroundControl.FlightMap

import QGroundControl.ScreenTools


Item {
    id: _root

    property var    parentToolInsets               // These insets tell you what screen real estate is available for positioning the controls in your overlay
    property var    totalToolInsets:        _toolInsets // These are the insets for your custom overlay additions
    property var    mapControl
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30
    property real   _idealWidth:            (ScreenTools.isMobile ? ScreenTools.minTouchPixels : ScreenTools.defaultFontPixelWidth * 8) + _toolsMargin

    // Property of Tools
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property color  _baseBGColor:           qgcPal.window
    property color  _transparentColor:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)

    // Property of Active Vehicle
    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle
    property real   _heading:               _activeVehicle   ? _activeVehicle.heading.rawValue : 0
    property bool   _available:             !isNaN(_activeVehicle.vibration.xAxis.rawValue)
    property real   _xValue:                _activeVehicle.vibration.xAxis.rawValue
    property real   _yValue:                _activeVehicle.vibration.yAxis.rawValue
    property real   _zValue:                _activeVehicle.vibration.zAxis.rawValue

    property real   _barWidth:              ScreenTools.defaultFontPixelWidth * 3
    property real   _barHeight:             ScreenTools.defaultFontPixelHeight * 10

    readonly property real _barMinimum:     0.0
    readonly property real _barMaximum:     90.0
    readonly property real _barBadValue:    60.0

    property real   _vehicleAltitude:           _activeVehicle ? _activeVehicle.altitudeRelative.rawValue : 0
    property real   _vehicleVerticalSpeed:      _activeVehicle ? _activeVehicle.climbRate.rawValue : 0
    property real   _vehicleGroundSpeed:        _activeVehicle ? _activeVehicle.groundSpeed.rawValue : 0
    property real   _distanceToHome:            _activeVehicle ? _activeVehicle.distanceToHome.rawValue : 0
    property string _vehicleAltitudeText:       isNaN(_vehicleAltitude) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsVerticalDistanceUnits(_vehicleAltitude).toFixed(1)
    property string _vehicleVerticalSpeedText:  isNaN(_vehicleVerticalSpeed) ? "-.-" : QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_vehicleVerticalSpeed).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsSpeedUnitsString
    property string _vehicleGroundSpeedText:    isNaN(_vehicleGroundSpeed) ? "-.-" : QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_vehicleGroundSpeed).toFixed(1)
    property string _distanceToHomeText:        isNaN(_distanceToHome) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsVerticalDistanceUnits(_distanceToHome).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString

    // Property of Vibration visible
    property bool _vibeStatusVisible:        false

    // QGC Map Center Position
    property var _mapCoordinate:            QGroundControl.flightMapPosition

    // // Property OpenWeather API Key
    // property string   _openWeatherAPIkey:   QGroundControl.settingsManager ? QGroundControl.settingsManager.appSettings.openWeatherApiKey.value : null
    // property string timeString

    // since this file is a placeholder for the custom layer in a standard build, we will just pass through the parent insets
    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeTopInset:       parentToolInsets.leftEdgeTopInset
        leftEdgeCenterInset:    parentToolInsets.leftEdgeCenterInset
        leftEdgeBottomInset:    parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      parentToolInsets.rightEdgeTopInset
        rightEdgeCenterInset:   parentToolInsets.rightEdgeCenterInset
        rightEdgeBottomInset:   parentToolInsets.rightEdgeBottomInset
        topEdgeLeftInset:       parentToolInsets.topEdgeLeftInset
        topEdgeCenterInset:     parentToolInsets.topEdgeCenterInset
        topEdgeRightInset:      parentToolInsets.topEdgeRightInset
        bottomEdgeLeftInset:    parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  parentToolInsets.bottomEdgeCenterInset
        bottomEdgeRightInset:   parentToolInsets.bottomEdgeRightInset
    }

    Row {
        id:                         rightPanelRow
        anchors.right:              parent.right
        anchors.margins:            _toolsMargin
        anchors.verticalCenter:     parent.verticalCenter
        spacing:                    _toolsMargin

        // VehicleStepMoveControl{
        //     id:                     vehicleStepMoveControl
        //     anchors.verticalCenter: parent.verticalCenter
        //     visible:                QGroundControl.settingsManager.flyViewSettings.showVehicleStepMoveControl.rawValue
        // }

        // GimbalControl{
        //     id:                     gimbalControl
        //     anchors.verticalCenter: parent.verticalCenter
        //     visible:                QGroundControl.settingsManager.flyViewSettings.showGimbalControlPannel.rawValue
        // }

        // WinchControlPanel {
        //     id:                     winchControlPanel
        //     anchors.verticalCenter: parent.verticalCenter
        //     visible:                QGroundControl.settingsManager.flyViewSettings.showWinchControl.rawValue
        // }

        // Column {
        //     anchors.verticalCenter: parent.verticalCenter
        //     spacing:                _toolsMargin

        //     PhotoVideoControl {
        //        id:                         photoVideoControl
        //        anchors.horizontalCenter:   parent.horizontalCenter
        //        visible:                    QGroundControl.settingsManager.flyViewSettings.showPhotoVideoControl.rawValue

        //        property real rightEdgeCenterInset: visible ? width + _margins * 2 : 0
        //     }
        //     SIYICameraControl {
        //         id:                         siyiCameraControl
        //         anchors.horizontalCenter:   parent.horizontalCenter
        //     }
        // }
    }
}



