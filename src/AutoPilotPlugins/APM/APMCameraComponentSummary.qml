import QtQuick
import QtQuick.Controls

import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.Palette

Item {
    anchors.fill:   parent

    FactPanelController { id: controller; }

//    property Fact _mountRCInTilt:   controller.getParameterFact(-1, "MNT_RC_IN_TILT")
//    property Fact _mountRCInRoll:   controller.getParameterFact(-1, "MNT_RC_IN_ROLL")
//    property Fact _mountRCInPan:    controller.getParameterFact(-1, "MNT_RC_IN_PAN")

    property bool   _camTypeExists: controller.parameterExists(-1, "CAM1_TYPE")
    property string _camTypeValue: _camTypeExists ? controller.getParameterFact(-1, "CAM1_TYPE").enumStringValue : ""

    // MNT_TYPE parameter is not in older firmware versions
    property bool   _mountTypeExists: controller.parameterExists(-1, "MNT1_TYPE")
    property string _mountTypeValue: _mountTypeExists ? controller.getParameterFact(-1, "MNT1_TYPE").enumStringValue : ""

    Column {
        anchors.fill:       parent

        VehicleSummaryRow {
            visible:    _mountTypeExists
            labelText:  qsTr("Gimbal type")
            valueText:  _mountTypeValue
        }

        VehicleSummaryRow {
            visible:    _camTypeExists
            labelText:  qsTr("Camera type")
            valueText:  _camTypeValue
        }

//        VehicleSummaryRow {
//            labelText:  qsTr("Tilt input channel")
//            valueText:  _mountRCInTilt.enumStringValue
//        }

//        VehicleSummaryRow {
//            labelText:  qsTr("Pan input channel")
//            valueText:  _mountRCInPan.enumStringValue
//        }

//        VehicleSummaryRow {
//            labelText:  qsTr("Roll input channel")
//            valueText:  _mountRCInRoll.enumStringValue
//        }
    }
}
