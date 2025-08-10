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
import QGroundControl.Controls
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap

Item{
    id:     control
    width:  attitudeIndicatorRow.width
    height: attitudeIndicatorRow.height
    //color: "transparent"

    property real   extraWidth: 0 ///< Extra width to add to the background rectangle

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
    property real   _alitutdeDecimal:           (_vehicleAltitude >= 100) ? 0 : 1
    property real   _vehicleAltitudeAMSL:       _activeVehicle ? _activeVehicle.altitudeAMSL.rawValue : 0
    property real   _vehicleVerticalSpeed:      _activeVehicle ? _activeVehicle.climbRate.rawValue : 0
    property real   _vehicleGroundSpeed:        _activeVehicle ? _activeVehicle.groundSpeed.rawValue : 0
    property real   _distanceToHome:            _activeVehicle ? _activeVehicle.distanceToHome.rawValue : 0
    property real   _distanceDecimal:           (_distanceToHome >= 100) ? 0 : 1
    property real   _distanceDown:              _activeVehicle ? _activeVehicle.distanceSensors.rotationPitch270.rawValue : 0
    property string _vehicleAltitudeText:       isNaN(_vehicleAltitude) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsDistanceUnits(_vehicleAltitude).toFixed(_alitutdeDecimal)
    property string _vehicleAltitudeAMSLText:   isNaN(_vehicleAltitudeAMSL) ? "-.-" : "ASL " + QGroundControl.unitsConversion.metersToAppSettingsDistanceUnits(_vehicleAltitudeAMSL).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsDistanceUnitsString
    property string _vehicleVerticalSpeedText:  isNaN(_vehicleVerticalSpeed) ? "-.-" : QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_vehicleVerticalSpeed).toFixed(1)
    property string _speedUnitText:             QGroundControl.unitsConversion.appSettingsSpeedUnitsString
    property string _vehicleGroundSpeedText:    isNaN(_vehicleGroundSpeed) ? "-.-" : QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_vehicleGroundSpeed).toFixed(1)
    property string _distanceToHomeText:        isNaN(_distanceToHome) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsDistanceUnits(_distanceToHome).toFixed(_distanceDecimal)
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

    Rectangle {
        id:         backgroundRect
        width:      control.width + extraWidth
        height:     control.height
        color:      qgcPal.window
        radius:     ScreenTools.defaultFontPixelWidth / 2
        opacity:    0.75
    }

    RowLayout{
        id: attitudeIndicatorRow
        spacing:    ScreenTools.defaultFontPixelWidth

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0

            QGCLabel {
                text:                   "GS"
                Layout.alignment:       Qt.AlignHCenter
            }
            QGCLabel {
                text:                   _vehicleGroundSpeedText
                Layout.minimumWidth:    _mediumValueWidth
                Layout.fillWidth:       true
                font.pointSize :        ScreenTools.defaultFontPointSize * 1.5
                font.bold :             true
                color:                  qgcPal.textHighlight
                horizontalAlignment:    Text.AlignHCenter
            }
            QGCLabel {
                text:                   _speedUnitText
                Layout.alignment:       Qt.AlignHCenter
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0

            QGCLabel {
                Layout.alignment:       Qt.AlignHCenter
                text:                   "VS"
            }
            QGCLabel {
                Layout.minimumWidth:    _mediumValueWidth
                Layout.fillWidth:       true
                text:                   _vehicleVerticalSpeedText
                font.pointSize :        ScreenTools.defaultFontPointSize * 1.5
                font.bold :             true
                color:                  qgcPal.textHighlight
                horizontalAlignment:    Text.AlignHCenter
            }
            QGCLabel {
                Layout.alignment: Qt.AlignHCenter
                text:   _speedUnitText
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0

            QGCLabel {
                Layout.alignment:       Qt.AlignHCenter
                text:                   "ALT"
            }
            QGCLabel {
                Layout.minimumWidth:    _mediumValueWidth
                Layout.fillWidth:       true
                text:                   _vehicleAltitudeText
                font.pointSize :        ScreenTools.defaultFontPointSize * 1.5
                font.bold :             true
                color:                  qgcPal.textHighlight
                horizontalAlignment:    Text.AlignHCenter
            }
            QGCLabel {
                Layout.alignment: Qt.AlignHCenter
                text:   _distanceUnitText
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0

            QGCLabel {
                Layout.alignment:       Qt.AlignHCenter
                text:                   "DIST"
            }
            QGCLabel {
                Layout.minimumWidth:    _mediumValueWidth
                Layout.fillWidth:       true
                text:                   _distanceToHomeText
                font.pointSize :        ScreenTools.defaultFontPointSize * 1.5
                font.bold :             true
                color:                  qgcPal.textHighlight
                horizontalAlignment:    Text.AlignHCenter
            }
            QGCLabel {
                Layout.alignment: Qt.AlignHCenter
                text:   _distanceUnitText
            }
        }
    }
}
