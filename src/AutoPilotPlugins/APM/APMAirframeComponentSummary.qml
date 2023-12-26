import QtQuick
import QtQuick.Controls

import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.Controllers
import QGroundControl.Palette

Item {
    anchors.fill:       parent

    APMAirframeComponentController {id: controller; }

    property Fact _frameClass:          controller.getParameterFact(-1, "FRAME_CLASS")
    property Fact _frameType:           controller.getParameterFact(-1, "FRAME_TYPE", false)
    property bool _frameTypeAvailable:  controller.parameterExists(-1, "FRAME_TYPE")
    property Fact _stat_bootcnt:        controller.getParameterFact(-1, "STAT_BOOTCNT")
    property Fact _stat_runtime:        controller.getParameterFact(-1, "STAT_RUNTIME")
    property Fact _stat_flttime:        controller.getParameterFact(-1, "STAT_FLTTIME")

    Column {
        anchors.fill:       parent

        VehicleSummaryRow {
            labelText:  qsTr("Frame Class")
            valueText:  _frameClass.enumStringValue
        }

        VehicleSummaryRow {
            labelText:  qsTr("Frame Type")
            valueText:  visible ? _frameType.enumStringValue : ""
            visible:    _frameTypeAvailable
        }

        VehicleSummaryRow {
            labelText:  qsTr("Boot Count")
            valueText:  visible ? _stat_bootcnt.valueString : ""
            visible:    _frameTypeAvailable
        }

        VehicleSummaryRow {
            labelText:  qsTr("Total Runtime")
            valueText:  visible ? _stat_runtime.valueString : ""
            visible:    _frameTypeAvailable
        }

        VehicleSummaryRow {
            labelText:  qsTr("Total Flight Time")
            valueText:  visible ? _stat_flttime.valueString : ""
            visible:    _frameTypeAvailable
        }

        VehicleSummaryRow {
            labelText: qsTr("Firmware Version")
            valueText: globals.activeVehicle.firmwareMajorVersion === -1 ? qsTr("Unknown") : globals.activeVehicle.firmwareMajorVersion + "." + globals.activeVehicle.firmwareMinorVersion + "." + globals.activeVehicle.firmwarePatchVersion + globals.activeVehicle.firmwareVersionTypeString
        }
    }
}
