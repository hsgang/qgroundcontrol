/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick 2.3
import QtQuick.Layouts 1.2

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.Controllers           1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.FactControls          1.0

//-------------------------------------------------------------------------
ToolIndicatorPage {
    showExpand: true

    property real _margins:                 ScreenTools.defaultFontPixelHeight / 2
    property var  _activeVehicle:           QGroundControl.multiVehicleManager.activeVehicle

    FactPanelController { id: controller }
    APMAirframeComponentController { id: apmController }

    property Fact _frameClass:              apmController.getParameterFact(-1, "FRAME_CLASS")
    property Fact _frameType:               apmController.getParameterFact(-1, "FRAME_TYPE", false)
    property bool _frameTypeAvailable:      apmController.parameterExists(-1, "FRAME_TYPE")
    property Fact _stat_bootcnt:            apmController.getParameterFact(-1, "STAT_BOOTCNT")
    property Fact _stat_runtime:            apmController.getParameterFact(-1, "STAT_RUNTIME")
    property Fact _stat_flttime:            apmController.getParameterFact(-1, "STAT_FLTTIME")

    property Fact landSpeedFact:            controller.getParameterFact(-1, "LAND_SPEED", false)
    property Fact precisionLandingFact:     controller.getParameterFact(-1, "PLND_ENABLED", false)
    property Fact atcInputTCFact:           controller.getParameterFact(-1, "ATC_INPUT_TC", false)
    property Fact loitSpeedFact:            controller.getParameterFact(-1, "LOIT_SPEED", false)
    property Fact pilotSpeedUpFact:         controller.getParameterFact(-1, "PILOT_SPEED_UP", false)
    property Fact pilotSpeedDnFact:         controller.getParameterFact(-1, "PILOT_SPEED_DN", false)
    property bool isPilotSpeedDn:           (pilotSpeedDnFact.value !== 0) ? true : false
    property Fact wpnavSpeedFact:           controller.getParameterFact(-1, "WPNAV_SPEED", false)
    property Fact wpnavSpeedUpFact:         controller.getParameterFact(-1, "WPNAV_SPEED_UP", false)
    property Fact wpnavSpeedDnFact:         controller.getParameterFact(-1, "WPNAV_SPEED_DN", false)
    property Fact wpnavRadiusFact:          controller.getParameterFact(-1, "WPNAV_RADIUS", false)
    property Fact rtlAltitudeFact:          controller.getParameterFact(-1, "RTL_ALT", false)

    contentComponent: Component {
        ColumnLayout {
            spacing: _margins

            SettingsGroupLayout {
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
                heading: qsTr("Parameter Summary")

                LabelledLabel {
                    label: qsTr("Loiter Speed")
                    labelText: (loitSpeedFact.value * 0.01).toFixed(1) + " m/s"
                }

                LabelledLabel {
                    label: qsTr("Pilot Climb Speed")
                    labelText: (pilotSpeedUpFact.value * 0.01).toFixed(1) + " m/s"
                }

                LabelledLabel {
                    label: qsTr("Pilot Descent Speed")
                    labelText: { isPilotSpeedDn ?
                                (pilotSpeedDnFact.value * 0.01).toFixed(1) + " m/s" :
                                (pilotSpeedUpFact.value * 0.01).toFixed(1) + " m/s"
                    }
                }

                LabelledLabel {
                    label: qsTr("WP Horizontal Speed")
                    labelText: (wpnavSpeedFact.value * 0.01).toFixed(1) + " m/s"
                }

                LabelledLabel {
                    label: qsTr("WP Climb Speed")
                    labelText: (wpnavSpeedUpFact.value * 0.01).toFixed(1) + " m/s"
                }

                LabelledLabel {
                    label: qsTr("WP Descent Speed")
                    labelText: (wpnavSpeedDnFact.value * 0.01).toFixed(1) + " m/s"
                }

                LabelledLabel {
                    label: qsTr("RTL Altitude")
                    labelText: (rtlAltitudeFact.value * 0.01).toFixed(1) + " m"
                }

                LabelledLabel {
                    label: qsTr("Land Speed")
                    labelText: (landSpeedFact.value * 0.01).toFixed(1) + " m/s"
                }
            }

            SettingsGroupLayout{
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

    expandedComponent : Component {
        SettingsGroupLayout{
            heading: qsTr("Vehicle Parameter")

            LabelledFactSlider {
                label:      qsTr("Responsiveness")
                fact:       atcInputTCFact
                from:       0.01
                to:         0.5
                stepSize:   0.01
                visible:    true
            }
            LabelledFactSlider {
                label:      qsTr("Loiter Horizontal Speed(cm/s)")
                fact:       loitSpeedFact
                from:       500
                to:         1500
                stepSize:   100
                visible:    true
            }
            LabelledFactSlider {
                label:      qsTr("WP Horizontal Speed(cm/s)")
                fact:       wpnavSpeedFact
                from:       500
                to:         1500
                stepSize:   100
                visible:    true
            }
            LabelledFactSlider {
                label:      qsTr("WP Climb Speed(cm/s)")
                fact:       wpnavSpeedUpFact
                from:       100
                to:         500
                stepSize:   50
                visible:    true
            }
            LabelledFactSlider {
                label:      qsTr("WP Descent Speed(cm/s)")
                fact:       wpnavSpeedDnFact
                from:       100
                to:         500
                stepSize:   50
                visible:    true
            }
            LabelledFactSlider {
                label:      qsTr("Mission Turning Radius(cm)")
                fact:       wpnavRadiusFact
                from:       200
                to:         1000
                stepSize:   100
                visible:    true
            }

            LabelledFactTextField {
                label:      qsTr("RTL Altitude")
                fact:       rtlAltitudeFact
                visible:    true
            }

            LabelledFactTextField {
                label:      qsTr("Land Speed")
                fact:       landSpeedFact
                visible:    landSpeedFact && controller.vehicle
                enabled:     !controller.vehicle.fixedWing
            }

            FactCheckBoxSlider {
                Layout.fillWidth:   true
                Layout.columnSpan:  2
                text:               qsTr("Precision Landing")
                description:        "별도의 정밀착륙 장치를 장착하고 추가 설정이 필요"
                fact:               precisionLandingFact
                visible:            precisionLandingFact
            }
        }
    }
}
