/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.11
import QtQuick.Layouts  1.11

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.Controllers           1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.FactControls          1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0
import MAVLink                              1.0
import QGroundControl.PX4                   1.0

Item {
    id:             _root
    anchors.top:    parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    //anchors.bottom: parent.bottom
    width:          powerIndicator.width
    height:         powerIndicator.height

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    FactPanelController { id: controller; }

    property bool _fullParameterVehicleAvailable: QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable && !QGroundControl.multiVehicleManager.activeVehicle.parameterManager.missingParameters

    property Fact _batt1Monitor:            controller.getParameterFact(-1, "BATT_MONITOR")
    property Fact _batt2Monitor:            controller.getParameterFact(-1, "BATT2_MONITOR", false /* reportMissing */)
    property bool _batt2MonitorAvailable:   controller.parameterExists(-1, "BATT2_MONITOR")
    property bool _batt1MonitorEnabled:     _batt1Monitor.rawValue !== 0
    property bool _batt2MonitorEnabled:     _batt2MonitorAvailable && _batt2Monitor.rawValue !== 0
    property Fact _battCapacity:            controller.getParameterFact(-1, "BATT_CAPACITY", false /* reportMissing */)
    property Fact _batt2Capacity:           controller.getParameterFact(-1, "BATT2_CAPACITY", false /* reportMissing */)
    property bool _battCapacityAvailable:   controller.parameterExists(-1, "BATT_CAPACITY")

    property real batteryCurrent:   0 //_activeVehicle ? _activeVehicle.batteries.current.rawValue : 0
    property real remainRatio:      0 //_activeVehicle ? 50 : 0

    function isPowerAvailable(){
        if(_fullParameterVehicleAvailable){
            console.log(_batt1Monitor)
        }
        else{
            var battCapacity = _battCapacity.valueString
            console.log(battCapacity)
        }
    }

    Rectangle {
        id: powerIndicator

        ColumnLayout{

            QGCLabel{
                text: _fullParameterVehicleAvailable ? _battCapacity.valueString + " " + _battCapacity.units : 999
            }
            QGCLabel{
                text: "temporary"
            }
            QGCLabel{
                text: "remainRatio"
            }
            QGCLabel{
                text: _fullParameterVehicleAvailable ? "parameterReadyVehicle" : "parameterNotReadyVehicle"
                //visible: _fullParameterVehicleAvailable
            }
        }
    }
}
