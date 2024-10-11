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

import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Controls

Item {
    anchors.fill: parent

    FactPanelController { id: controller; }

    property Fact _followEnabled: controller.getParameterFact(-1, "FOLL_ENABLE")
    property bool _followParamsAvailable: controller.parameterExists(-1, "FOLL_SYSID")
    property Fact _followDistanceMax: controller.getParameterFact(-1, "FOLL_DIST_MAX", false /* reportMissing */)
    property Fact _followSysId: controller.getParameterFact(-1, "FOLL_SYSID", false /* reportMissing */)
    property Fact _followOffsetX: controller.getParameterFact(-1, "FOLL_OFS_X", false /* reportMissing */)
    property Fact _followOffsetY: controller.getParameterFact(-1, "FOLL_OFS_Y", false /* reportMissing */)
    property Fact _followOffsetZ: controller.getParameterFact(-1, "FOLL_OFS_Z", false /* reportMissing */)
    property Fact _followOffsetType: controller.getParameterFact(-1, "FOLL_OFS_TYPE", false /* reportMissing */)
    property Fact _followAltitudeType: controller.getParameterFact(-1, "FOLL_ALT_TYPE", false /* reportMissing */)
    property Fact _followYawBehavior: controller.getParameterFact(-1, "FOLL_YAW_BEHAVE", false /* reportMissing */)

    Column {
        anchors.fill: parent

        VehicleSummaryRow {
            labelText: qsTr("Follow Enabled")
            valueText: _followEnabled.enumStringValue
        }

        VehicleSummaryRow {
            labelText: qsTr("Follow System ID")
            valueText: _followParamsAvailable ? _followSysId.valueString : qsTr("N/A")
            visible: _followParamsAvailable
        }

        VehicleSummaryRow {
            labelText: qsTr("Follow Max Distance")
            valueText: _followParamsAvailable ? _followDistanceMax.valueString + " " + _followDistanceMax.units : qsTr("N/A")
            visible: _followParamsAvailable
        }

        VehicleSummaryRow {
            labelText: qsTr("Follow Offset X")
            valueText: _followParamsAvailable ? _followOffsetX.valueString + " " + _followOffsetX.units : qsTr("N/A")
            visible: _followParamsAvailable
        }

        VehicleSummaryRow {
            labelText: qsTr("Follow Offset Y")
            valueText: _followParamsAvailable ? _followOffsetY.valueString + " " + _followOffsetY.units : qsTr("N/A")
            visible: _followParamsAvailable
        }

        VehicleSummaryRow {
            labelText: qsTr("Follow Offset Z")
            valueText: _followParamsAvailable ? _followOffsetZ.valueString + " " + _followOffsetZ.units : qsTr("N/A")
            visible: _followParamsAvailable
        }

        VehicleSummaryRow {
            labelText: qsTr("Follow Offset Type")
            valueText: _followParamsAvailable ? _followOffsetType.enumStringValue : qsTr("N/A")
            visible: _followParamsAvailable
        }

        VehicleSummaryRow {
            labelText: qsTr("Follow Altitude Type")
            valueText: _followParamsAvailable ? _followAltitudeType.enumStringValue : qsTr("N/A")
            visible: _followParamsAvailable
        }

        VehicleSummaryRow {
            labelText: qsTr("Follow Yaw Behavior")
            valueText: _followParamsAvailable ? _followYawBehavior.enumStringValue : qsTr("N/A")
            visible: _followParamsAvailable
        }
    }
}
