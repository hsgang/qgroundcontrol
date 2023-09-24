import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts  1.2
import QtQuick.Dialogs  1.2
import QtGraphicalEffects       1.12


import QGroundControl                   1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.Controls          1.0
import QGroundControl.FactControls      1.0
import QGroundControl.Palette           1.0

Rectangle {
    id:         altitudeIndicator
    //height:     parent.height * 0.32
    width:      ScreenTools.defaultFontPixelWidth * 1.6
    color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5)
    radius:     _margins

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

    Rectangle{
        id: altLevelBar
        width: parent.width * 0.7
        radius: _margins
        height: ((_vehicleAltitude / _missionMaxAltitude) <= 1) ? parent.height * (_vehicleAltitude / _missionMaxAltitude) : parent.height
        anchors.bottom: parent.bottom
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

    Glow {
        anchors.fill: missionMaxAltitudeText
        radius: 2
        samples: 5
        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
        source: missionMaxAltitudeText
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
        Glow {
            anchors.fill: altLevelerText
            radius: 2
            samples: 5
            color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
            source: altLevelerText
        }
    }

    QGCLabel {
        id:                         gndText
        anchors.top:                parent.bottom
        anchors.horizontalCenter:   parent.horizontalCenter
        font.pointSize:             ScreenTools.defaultFontPointSize * 0.8
        text:                       "GND" //_startAltitudeText
    }
    Glow {
        anchors.fill: gndText
        radius: 2
        samples: 5
        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
        source: gndText
    }
}
