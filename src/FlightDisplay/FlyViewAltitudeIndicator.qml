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
    id:         altitudeIndicator
    //height:     parent.height * 0.32
    width:      _rightPanelWidth * 0.08
    color:      "#80000000"
    radius:     _margins

    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property var    _planMasterController:      globals.planMasterControllerPlanView

    property bool   _controllerValid:           _planMasterController !== undefined && _planMasterController !== null
    property var    missionItems:               _controllerValid ? _planMasterController.missionController.visualItems : undefined
    property bool   _missionValid:              missionItems !== undefined

    property real   missionMaxAltitude:         _controllerValid ? _planMasterController.missionController.missionMaxAltitude : NaN
    property real   _missionMaxAltitude:        _missionValid ? missionMaxAltitude : NaN
    property real   _vehicleAltitude:           _activeVehicle ? _activeVehicle.altitudeRelative.rawValue : 0

    property string _missionMaxAltitudeText:    isNaN(_missionMaxAltitude) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsVerticalDistanceUnits(_missionMaxAltitude).toFixed(0) + " " + QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString
    property string _vehicleAltitudeText:       isNaN(_vehicleAltitude) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsVerticalDistanceUnits(_vehicleAltitude).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString
    property string _startAltitudeText:         isNaN(_vehicleAltitude) ? "-.-" : "0.0 " + QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString

    function currentAltitudeRatio(){
        currentAltitudeRatio = height - (height * (_vehicleAltitude / _missionMaxAltitude))
        if (currentAltitudeRatio > height){
            return height
        }
        else if (currentAltitudeRatio < 0){
            return 0
        }
        else {
            return currentAltitudeRatio
        }
    }

    QGCLabel {
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
            anchors.verticalCenter: parent.verticalCenter
            anchors.left:           parent.right
            anchors.leftMargin:     2
            text:                   _vehicleAltitudeText
        }
    }

    QGCLabel {
        anchors.top:                parent.bottom
        anchors.horizontalCenter:   parent.horizontalCenter
        text:                       "GND" //_startAltitudeText
    }
}
