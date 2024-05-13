import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.Palette

Rectangle {
    id:         altitudeIndicator
    //height:     parent.height * 0.32
    width:      ScreenTools.defaultFontPixelWidth * 1.4
    color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5)
    radius:     ScreenTools.defaultFontPixelWidth * 0.7

    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property var    _planMasterController:      globals.planMasterControllerPlanView

    property bool   _controllerValid:           _planMasterController !== undefined && _planMasterController !== null
    property var    missionItems:               _controllerValid ? _planMasterController.missionController.visualItems : undefined
    property bool   _missionValid:              missionItems !== undefined

    property real   missionMaxAltitude:         _controllerValid ? _planMasterController.missionController.missionMaxAltitude : NaN
    property real   _missionMaxAltitude:        _missionValid ? missionMaxAltitude : NaN
    property real   _vehicleAltitude:           _activeVehicle ? _activeVehicle.altitudeRelative.rawValue : 0

    property string _missionMaxAltitudeText:    (isNaN(_missionMaxAltitude) || (_missionMaxAltitude <= 0)) ? "--" + " " + QGroundControl.unitsConversion.appSettingsDistanceUnitsString : QGroundControl.unitsConversion.metersToAppSettingsDistanceUnits(_missionMaxAltitude).toFixed(0) + " " + QGroundControl.unitsConversion.appSettingsDistanceUnitsString
    property string _vehicleAltitudeText:       isNaN(_vehicleAltitude) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsDistanceUnits(_vehicleAltitude).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsDistanceUnitsString
    property string _startAltitudeText:         isNaN(_vehicleAltitude) ? "-.-" : "0.0 " + QGroundControl.unitsConversion.appSettingsDistanceUnitsString

    function currentAltitudeRatio(){
        var ratio = height - (height * (_vehicleAltitude / _missionMaxAltitude))
        if (ratio > height){
            return height
        }
        else if (ratio < 0){
            return 0
        }
        else {
            return ratio
        }
    }

    Rectangle{
        id: altLevelBar
        width: ScreenTools.defaultFontPixelWidth
        radius: ScreenTools.defaultFontPixelWidth * 0.5
        height: ((_vehicleAltitude / _missionMaxAltitude) <= 1)
                    ? (parent.height - ScreenTools.defaultFontPixelWidth * 0.4) * (_vehicleAltitude / _missionMaxAltitude)
                    : (parent.height - ScreenTools.defaultFontPixelWidth * 0.4)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: ScreenTools.defaultFontPixelWidth * 0.2
        anchors.horizontalCenter: parent.horizontalCenter
        color:  qgcPal.colorGreen
        visible: (_missionMaxAltitude > 0) ? true : false
    }

    QGCLabel {
        id:                         missionMaxAltitudeText
        text:                       _missionMaxAltitudeText
        anchors.bottom:             parent.top
        anchors.horizontalCenter:   parent.horizontalCenter
    }

    Rectangle{
        id       : altLeveler
        height   : 2
        width    : altitudeIndicator.width * 1.5
        anchors.horizontalCenter: altitudeIndicator.horizontalCenter
        color    : qgcPal.text
        y        : currentAltitudeRatio()

        QGCLabel {
            id:                     altLevelerText
            anchors.verticalCenter: parent.verticalCenter
            anchors.left:           parent.right
            anchors.leftMargin:     2
            text:                   _vehicleAltitudeText
        }
    }

    QGCLabel {
        id:                         gndText
        anchors.top:                parent.bottom
        anchors.horizontalCenter:   parent.horizontalCenter
        font.pointSize:             ScreenTools.defaultFontPointSize * 0.8
        text:                       "GND" //_startAltitudeText
    }
}
