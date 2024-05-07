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
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.FactSystem
import QGroundControl.FactControls
import MAVLink

ToolIndicatorPage {
    showExpand: true

    property bool       waitForParameters:  false   // UI won't show until parameters are ready
    property real       _margins: ScreenTools.defaultFontPixelHeight / 2

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property real   _labelledItemWidth:     ScreenTools.defaultFontPixelWidth * 10
    // property Fact   _indicatorDisplay:  QGroundControl.settingsManager.batteryIndicatorSettings.display
    // property bool   _showPercentage:    _indicatorDisplay.rawValue === 0
    // property bool   _showVoltage:       _indicatorDisplay.rawValue === 1
    // property bool   _showBoth:          _indicatorDisplay.rawValue === 2

    FactPanelController { id: controller }

    property var    _batterySettings:  QGroundControl.settingsManager.batterySettings
    property real   _batteryCellCount: _batterySettings.batteryCellCount.value
    property bool   _showCellVoltage: QGroundControl.settingsManager.batterySettings.showCellVoltage.value

    contentComponent: Component {
        ColumnLayout {
            property var _batterySettings: QGroundControl.settingsManager.batterySettings
            property real _batteryCellCount: _batterySettings.batteryCellCount.value
            property real _margins: ScreenTools.defaultFontPixelHeight / 2

            Component {
                id: batteryValuesAvailableComponent

                QtObject {
                    property bool functionAvailable:        battery.function.rawValue !== MAVLink.MAV_BATTERY_FUNCTION_UNKNOWN
                    property bool showFunction:             functionAvailable && battery.function.rawValue != MAVLink.MAV_BATTERY_FUNCTION_ALL
                    property bool temperatureAvailable:     !isNaN(battery.temperature.rawValue)
                    property bool currentAvailable:         !isNaN(battery.current.rawValue)
                    property bool mahConsumedAvailable:     !isNaN(battery.mahConsumed.rawValue)
                    property bool timeRemainingAvailable:   !isNaN(battery.timeRemaining.rawValue)
                    property bool chargeStateAvailable:     battery.chargeState.rawValue !== MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED
                }
            }


            Repeater {
                model: _activeVehicle ? _activeVehicle.batteries : 0

                SettingsGroupLayout {
                    heading:        qsTr("Battery %1").arg(_activeVehicle.batteries.length === 1 ? qsTr("Status") : object.id.rawValue)

                    Loader {
                        id:                 nameAvailableLoader
                        sourceComponent:    batteryValuesAvailableComponent

                        property var battery: object
                    }

                    property var batteryValuesAvailable: nameAvailableLoader.item

                    LabelledLabel {
                        label :  qsTr("Battery ID")
                        labelText:  qsTr("Battery %1").arg(object.id.rawValue)
                    }
                    LabelledLabel {
                        label:  qsTr("Charge State")
                        labelText:  object.chargeState.enumStringValue
                        visible:    batteryValuesAvailable.chargeStateAvailable
                    }
                    LabelledLabel {
                        label:  qsTr("Remaining Time")
                        labelText:  object.timeRemainingStr.value
                        visible:    batteryValuesAvailable.timeRemainingAvailable
                    }
                    LabelledLabel {
                        label:  qsTr("Remaining")
                        labelText:  object.percentRemaining.valueString + " " + object.percentRemaining.units
                    }
                    LabelledLabel {
                        label:  qsTr("Voltage")
                        labelText:  object.voltage.valueString + " " + object.voltage.units
                    }
                    LabelledLabel {
                        label:  qsTr("Cell Voltage")
                        labelText:  (object.voltage.value / _batteryCellCount).toFixed(2) + " " + object.voltage.units
                    }
                    LabelledLabel {
                        label:  qsTr("Current")
                        labelText:  object.current.valueString + " " + object.current.units
                        visible:    batteryValuesAvailable.currentAvailable
                    }
                    LabelledLabel {
                        label:  qsTr("Consumed")
                        labelText:  object.mahConsumed.valueString + " " + object.mahConsumed.units
                        visible:    batteryValuesAvailable.mahConsumedAvailable
                    }
                    LabelledLabel {
                        label:  qsTr("Temperature")
                        labelText:  object.temperature.valueString + " " + object.temperature.units
                        visible:    batteryValuesAvailable.temperatureAvailable
                    }
                    LabelledLabel {
                        label:  qsTr("Function")
                        labelText:  object.function.enumStringValue
                        visible:    batteryValuesAvailable.functionAvailable
                    }
                }
            } // repeater
        }
    }

    expandedComponent: Component {
        SettingsGroupLayout {
            heading: qsTr("Battery Settings")

            FactCheckBoxSlider {
                text:                   qsTr("Show Cell Voltage")
                Layout.columnSpan:      2
                Layout.fillWidth:       true
                fact:                   _batterySettings.showCellVoltage
            }

            LabelledFactTextField {
                label:                  qsTr("Battery Cells")
                fact:                   _batterySettings.batteryCellCount
                visible:                true
                textFieldPreferredWidth: _labelledItemWidth
            }

            LabelledFactTextField {
                label:                  qsTr("Battery Low Level")
                fact:                   controller.getParameterFact(-1, "BATT_LOW_VOLT")
                textFieldPreferredWidth: _labelledItemWidth
            }

            LabelledFactComboBox {
                label:                  qsTr("Battery Low Action")
                fact:                   controller.getParameterFact(-1, "BATT_FS_LOW_ACT")
                indexModel:             false
                comboBoxPreferredWidth: _labelledItemWidth
            }

            LabelledFactTextField {
                label:                  qsTr("Battery Critical Level")
                fact:                   controller.getParameterFact(-1, "BATT_CRT_VOLT")
                textFieldPreferredWidth: _labelledItemWidth
            }

            LabelledFactComboBox {
                label:                  qsTr("Battery Critical Action")
                fact:                   controller.getParameterFact(-1, "BATT_FS_CRT_ACT")
                indexModel:             false
                comboBoxPreferredWidth: _labelledItemWidth
            }
        }
    }
}
