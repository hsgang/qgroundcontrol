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

    // ArduCopter 4.7+ renamed many parameters and converted units cm→m, cm/s→m/s.
    property bool _useNewParams:            _activeVehicle && _activeVehicle.firmwareMajorVersion >= 0 &&
                                            (_activeVehicle.firmwareMajorVersion > 4 ||
                                             (_activeVehicle.firmwareMajorVersion === 4 && _activeVehicle.firmwareMinorVersion >= 7))
    property real _speedScale:              _useNewParams ? 1.0 : 0.01
    property real _altScale:                _useNewParams ? 1.0 : 0.01
    property string _sliderUnit:            _useNewParams ? "m/s" : "cm/s"
    property string _radiusUnit:            _useNewParams ? "m"   : "cm"

    property Fact landSpeedFact:            _useNewParams
                                            ? controller.getParameterFact(-1, "LAND_SPD_MS", false)
                                            : controller.getParameterFact(-1, "LAND_SPEED", false)
    property Fact precisionLandingFact:     controller.getParameterFact(-1, "PLND_ENABLED", false)
    property Fact atcInputTCFact:           controller.getParameterFact(-1, "ATC_INPUT_TC", false)
    property Fact loitSpeedFact:            _useNewParams
                                            ? controller.getParameterFact(-1, "LOIT_SPEED_MS", false)
                                            : controller.getParameterFact(-1, "LOIT_SPEED", false)
    property Fact pilotSpeedUpFact:         _useNewParams
                                            ? controller.getParameterFact(-1, "PILOT_SPD_UP", false)
                                            : controller.getParameterFact(-1, "PILOT_SPEED_UP", false)
    property Fact pilotSpeedDnFact:         _useNewParams
                                            ? controller.getParameterFact(-1, "PILOT_SPD_DN", false)
                                            : controller.getParameterFact(-1, "PILOT_SPEED_DN", false)
    property bool isPilotSpeedDn:           pilotSpeedDnFact && (pilotSpeedDnFact.value !== 0)
    property Fact wpnavSpeedFact:           _useNewParams
                                            ? controller.getParameterFact(-1, "WP_SPD", false)
                                            : controller.getParameterFact(-1, "WPNAV_SPEED", false)
    property Fact wpnavSpeedUpFact:         _useNewParams
                                            ? controller.getParameterFact(-1, "WP_SPD_UP", false)
                                            : controller.getParameterFact(-1, "WPNAV_SPEED_UP", false)
    property Fact wpnavSpeedDnFact:         _useNewParams
                                            ? controller.getParameterFact(-1, "WP_SPD_DN", false)
                                            : controller.getParameterFact(-1, "WPNAV_SPEED_DN", false)
    property Fact wpnavRadiusFact:          _useNewParams
                                            ? controller.getParameterFact(-1, "WP_RADIUS_M", false)
                                            : controller.getParameterFact(-1, "WPNAV_RADIUS", false)
    property Fact rtlAltitudeFact:          _useNewParams
                                            ? controller.getParameterFact(-1, "RTL_ALT_M", false)
                                            : controller.getParameterFact(-1, "RTL_ALT", false)

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

    expandedComponent : Component {
        SettingsGroupLayout{
            Layout.fillWidth:       true
            Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 50
            heading: qsTr("Vehicle Parameter")

            LabelledFactSlider {
                label:              qsTr("Responsiveness")
                fact:               atcInputTCFact
                from:               0.01
                to:                 0.5
                majorTickStepSize:  0.05
                visible:            true
            }
            LabelledFactSlider {
                label:              qsTr("Loiter Horizontal Speed") + " (" + _sliderUnit + ")"
                fact:               loitSpeedFact
                from:               _useNewParams ? 5    : 500
                to:                 _useNewParams ? 15   : 1500
                majorTickStepSize:  _useNewParams ? 1    : 100
                visible:            loitSpeedFact
            }
            LabelledFactSlider {
                label:              qsTr("WP Horizontal Speed") + " (" + _sliderUnit + ")"
                fact:               wpnavSpeedFact
                from:               _useNewParams ? 5    : 500
                to:                 _useNewParams ? 15   : 1500
                majorTickStepSize:  _useNewParams ? 1    : 100
                visible:            wpnavSpeedFact
            }
            LabelledFactSlider {
                label:              qsTr("WP Climb Speed") + " (" + _sliderUnit + ")"
                fact:               wpnavSpeedUpFact
                from:               _useNewParams ? 1    : 100
                to:                 _useNewParams ? 5    : 500
                majorTickStepSize:  _useNewParams ? 0.5  : 50
                visible:            wpnavSpeedUpFact
            }
            LabelledFactSlider {
                label:              qsTr("WP Descent Speed") + " (" + _sliderUnit + ")"
                fact:               wpnavSpeedDnFact
                from:               _useNewParams ? 1    : 100
                to:                 _useNewParams ? 5    : 500
                majorTickStepSize:  _useNewParams ? 0.5  : 50
                visible:            wpnavSpeedDnFact
            }
            LabelledFactSlider {
                label:              qsTr("Mission Turning Radius") + " (" + _radiusUnit + ")"
                fact:               wpnavRadiusFact
                from:               _useNewParams ? 2    : 200
                to:                 _useNewParams ? 10   : 1000
                majorTickStepSize:  _useNewParams ? 1    : 100
                visible:            wpnavRadiusFact
            }

            LabelledFactTextField {
                label:      qsTr("RTL Altitude")
                fact:       rtlAltitudeFact
                visible:    rtlAltitudeFact
            }

            LabelledFactTextField {
                label:      qsTr("Land Speed")
                fact:       landSpeedFact
                visible:    landSpeedFact && controller.vehicle
                enabled:     controller.vehicle && !controller.vehicle.fixedWing
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
