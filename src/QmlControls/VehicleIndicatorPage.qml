/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

//-------------------------------------------------------------------------
ToolIndicatorPage {
    property real _margins:                 ScreenTools.defaultFontPixelHeight / 2
    property var  _activeVehicle:           QGroundControl.multiVehicleManager.activeVehicle

    FactPanelController { id: controller }
    APMAirframeComponentController { id: apmController }

    property Fact _frameClass:              apmController.getParameterFact(-1, "FRAME_CLASS")
    property bool _frameTypeAvailable:      apmController.parameterExists(-1, "FRAME_TYPE")
    property Fact _stat_bootcnt:            apmController.getParameterFact(-1, "STAT_BOOTCNT")
    property Fact _stat_runtime:            apmController.getParameterFact(-1, "STAT_RUNTIME")
    property Fact _stat_flttime:            apmController.getParameterFact(-1, "STAT_FLTTIME")

    // Always query the newest parameter names; ParameterManager auto-remaps to legacy
    // names on ArduCopter ≤4.6 via ArduCopterFirmwarePlugin._remapParamName.
    property Fact landSpeedFact:            controller.getParameterFact(-1, "LAND_SPD_MS",   false)
    property Fact loitSpeedFact:            controller.getParameterFact(-1, "LOIT_SPEED_MS", false)
    property Fact pilotSpeedUpFact:         controller.getParameterFact(-1, "PILOT_SPD_UP",  false)
    property Fact pilotSpeedDnFact:         controller.getParameterFact(-1, "PILOT_SPD_DN",  false)
    property bool isPilotSpeedDn:           pilotSpeedDnFact && (pilotSpeedDnFact.value !== 0)
    property Fact wpnavSpeedFact:           controller.getParameterFact(-1, "WP_SPD",        false)
    property Fact wpnavSpeedUpFact:         controller.getParameterFact(-1, "WP_SPD_UP",     false)
    property Fact wpnavSpeedDnFact:         controller.getParameterFact(-1, "WP_SPD_DN",     false)
    property Fact rtlAltitudeFact:          controller.getParameterFact(-1, "RTL_ALT_M",     false)

    // 4.7+ stores values natively in m/s and m; ≤4.6 in cm/s and cm. The "noremap." prefix
    // bypasses the rename mapping so we detect the *actual* on-vehicle parameter.
    property bool _unitsInSI:               controller.parameterExists(-1, "noremap.LOIT_SPEED_MS")
    property real _speedScale:              _unitsInSI ? 1.0 : 0.01
    property real _altScale:                _unitsInSI ? 1.0 : 0.01

    contentComponent: Component {
        ColumnLayout {
            spacing: _margins

            SettingsGroupLayout {
                Layout.fillWidth: true
                heading: qsTr("Vehicle Information")

                LabelledLabel {
                    label: qsTr("Firmware Type")
                    labelText: _activeVehicle.firmwareTypeString
                }

                LabelledLabel {
                    label: qsTr("Firmware Version")
                    labelText: globals.activeVehicle.firmwareMajorVersion === -1 ? qsTr("Unknown") : globals.activeVehicle.firmwareMajorVersion + "." + globals.activeVehicle.firmwareMinorVersion + "." + globals.activeVehicle.firmwarePatchVersion + globals.activeVehicle.firmwareVersionTypeString
                }

                LabelledLabel {
                    label:  qsTr("Frame Class")
                    labelText:  _frameClass.enumStringValue
                }
            }

            SettingsGroupLayout{
                Layout.fillWidth: true
                heading: qsTr("Parameter Summary")

                LabelledLabel {
                    label: qsTr("Loiter Speed")
                    labelText: loitSpeedFact ? (loitSpeedFact.value * _speedScale).toFixed(1) + " m/s" : qsTr("N/A")
                    visible: loitSpeedFact
                }

                LabelledLabel {
                    label: qsTr("Pilot Climb Speed")
                    labelText: pilotSpeedUpFact ? (pilotSpeedUpFact.value * _speedScale).toFixed(1) + " m/s" : qsTr("N/A")
                    visible: pilotSpeedUpFact
                }

                LabelledLabel {
                    label: qsTr("Pilot Descent Speed")
                    labelText: isPilotSpeedDn
                                ? (pilotSpeedDnFact.value * _speedScale).toFixed(1) + " m/s"
                                : (pilotSpeedUpFact ? (pilotSpeedUpFact.value * _speedScale).toFixed(1) + " m/s" : qsTr("N/A"))
                    visible: pilotSpeedDnFact || pilotSpeedUpFact
                }

                LabelledLabel {
                    label: qsTr("WP Horizontal Speed")
                    labelText: wpnavSpeedFact ? (wpnavSpeedFact.value * _speedScale).toFixed(1) + " m/s" : qsTr("N/A")
                    visible: wpnavSpeedFact
                }

                LabelledLabel {
                    label: qsTr("WP Climb Speed")
                    labelText: wpnavSpeedUpFact ? (wpnavSpeedUpFact.value * _speedScale).toFixed(1) + " m/s" : qsTr("N/A")
                    visible: wpnavSpeedUpFact
                }

                LabelledLabel {
                    label: qsTr("WP Descent Speed")
                    labelText: wpnavSpeedDnFact ? (wpnavSpeedDnFact.value * _speedScale).toFixed(1) + " m/s" : qsTr("N/A")
                    visible: wpnavSpeedDnFact
                }

                LabelledLabel {
                    label: qsTr("RTL Altitude")
                    labelText: rtlAltitudeFact ? (rtlAltitudeFact.value * _altScale).toFixed(1) + " m" : qsTr("N/A")
                    visible: rtlAltitudeFact
                }

                LabelledLabel {
                    label: qsTr("Land Speed")
                    labelText: landSpeedFact ? (landSpeedFact.value * _speedScale).toFixed(1) + " m/s" : qsTr("N/A")
                    visible: landSpeedFact
                }
            }

            SettingsGroupLayout{
                Layout.fillWidth: true
                heading: qsTr("Operating Summary")

                LabelledLabel {
                    label:  qsTr("Boot Count")
                    labelText:  visible ? _stat_bootcnt.valueString : ""
                    visible:    _frameTypeAvailable
                }

                LabelledLabel {
                    label:  qsTr("Total Runtime")
                    labelText:  visible ? _stat_runtime.valueString + " s" : ""
                    visible:    _frameTypeAvailable
                }

                LabelledLabel {
                    label:  qsTr("Total Flight Time")
                    labelText:  visible ? _stat_flttime.valueString + " s": ""
                    visible:    _frameTypeAvailable
                }
            }
        }
    }

}
