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

    property bool   waitForParameters:  false   // UI won't show until parameters are ready
    property real   _margins: ScreenTools.defaultFontPixelHeight / 2

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property real   _labelledItemWidth:     ScreenTools.defaultFontPixelWidth * 10
    // property Fact   _indicatorDisplay:  QGroundControl.settingsManager.batteryIndicatorSettings.display
    // property bool   _showPercentage:    _indicatorDisplay.rawValue === 0
    // property bool   _showVoltage:       _indicatorDisplay.rawValue === 1
    // property bool   _showBoth:          _indicatorDisplay.rawValue === 2

    FactPanelController { id: controller }

    property var    batterySettings:  QGroundControl.settingsManager.batteryIndicatorSettings
    property real   batteryCellCount: batterySettings.batteryCellCount.rawValue
    property bool   showCellVoltage:  batterySettings.showCellVoltage.rawValue

    contentComponent: Component {
        ColumnLayout {
            //property var batterySettings: QGroundControl.settingsManager.batteryIndicatorSettings
            //property real batteryCellCount: batterySettings.batteryCellCount.rawValue
            //property real margins: ScreenTools.defaultFontPixelHeight / 2

            Component {
                id: batteryValuesAvailableComponent

                QtObject {
                    property bool functionAvailable:         battery.function.rawValue !== MAVLink.MAV_BATTERY_FUNCTION_UNKNOWN
                    property bool showFunction:              functionAvailable && battery.function.rawValue !== MAVLink.MAV_BATTERY_FUNCTION_ALL
                    property bool temperatureAvailable:      !isNaN(battery.temperature.rawValue)
                    property bool currentAvailable:          !isNaN(battery.current.rawValue)
                    property bool mahConsumedAvailable:      !isNaN(battery.mahConsumed.rawValue)
                    property bool timeRemainingAvailable:    !isNaN(battery.timeRemaining.rawValue)
                    property bool percentRemainingAvailable: !isNaN(battery.percentRemaining.rawValue)
                    property bool chargeStateAvailable:      battery.chargeState.rawValue !== MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED
                }
            }

            Repeater {
                model: _activeVehicle ? _activeVehicle.batteries : 0

                SettingsGroupLayout {
                    heading:        qsTr("Battery %1").arg(_activeVehicle.batteries.length === 1 ? qsTr("Status") : object.id.rawValue)
                    //contentSpacing: 0
                    //showDividers:   false

                    property var batteryValuesAvailable: batteryValuesAvailableLoader.item

                    Loader {
                        id:                 batteryValuesAvailableLoader
                        sourceComponent:    batteryValuesAvailableComponent

                        property var battery: object
                    }

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
                        labelText:  (object.voltage.value / batteryCellCount).toFixed(2) + " " + object.voltage.units
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

        ColumnLayout {
            spacing: ScreenTools.defaultFontPixelHeight / 2

            SettingsGroupLayout {
                Layout.fillWidth: true

                RowLayout {
                    Layout.fillWidth: true

                    QGCLabel { Layout.fillWidth: true; text: qsTr("Battery Display") }
                    FactComboBox {
                        id:             editModeCheckBox
                        fact:           QGroundControl.settingsManager.batteryIndicatorSettings.display
                        sizeToContents: true
                    }
                }

                // RowLayout {
                //     Layout.fillWidth: true

                //     QGCLabel { Layout.fillWidth: true; text: qsTr("Vehicle Power") }
                //     QGCButton {
                //         text: qsTr("Configure")
                //         onClicked: {
                //             mainWindow.showVehicleSetupTool(qsTr("Power"))
                //             mainWindow.closeIndicatorDrawer()
                //         }
                //     }
                // }
            }

            SettingsGroupLayout {
                heading: qsTr("Battery Settings")

                FactCheckBoxSlider {
                    text:                   qsTr("Show Cell Voltage")
                    Layout.columnSpan:      2
                    Layout.fillWidth:       true
                    fact:                   batterySettings.showCellVoltage
                }

                LabelledFactTextField {
                    label:                  qsTr("Battery Cells")
                    fact:                   batterySettings.batteryCellCount
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

            SettingsGroupLayout {
                heading: qsTr("Battery State Display")
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelHeight * 0.05  // Reduced outer spacing
                visible: batteryState  // Control visibility of the entire group

                RowLayout {
                    spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Reduced spacing between elements

                    // Battery 100%
                    RowLayout {
                        spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Tighter spacing for icon and label
                        QGCColoredImage {
                            source: "/qmlimages/BatteryGreen.svg"
                            height: ScreenTools.defaultFontPixelHeight * 5
                            width: ScreenTools.defaultFontPixelWidth * 6
                            fillMode: Image.PreserveAspectFit
                            color: qgcPal.colorGreen
                        }
                        QGCLabel { text: qsTr("100%") }
                    }

                    // Threshold 1
                    RowLayout {
                        spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Tighter spacing for icon and field
                        QGCColoredImage {
                            source: "/qmlimages/BatteryYellowGreen.svg"
                            height: ScreenTools.defaultFontPixelHeight * 5
                            width: ScreenTools.defaultFontPixelWidth * 6
                            fillMode: Image.PreserveAspectFit
                            color: qgcPal.colorYellowGreen
                        }
                        FactTextField {
                            id: threshold1Field
                            fact: batterySettings.threshold1
                            implicitWidth: ScreenTools.defaultFontPixelWidth * 5.5
                            height: ScreenTools.defaultFontPixelHeight * 1.5
                            visible: threshold1visible
                            onEditingFinished: {
                                // Validate and set the new threshold value
                                batterySettings.setThreshold1(parseInt(text));
                            }
                        }
                    }
                    QGCLabel {
                        visible: !threshold1visible
                        text: qsTr("") + batterySettings.threshold1.rawValue.toString() + qsTr("%")
                    }

                    // Threshold 2
                    RowLayout {
                        spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Tighter spacing for icon and field
                        QGCColoredImage {
                            source: "/qmlimages/BatteryYellow.svg"
                            height: ScreenTools.defaultFontPixelHeight * 5
                            width: ScreenTools.defaultFontPixelWidth * 6
                            fillMode: Image.PreserveAspectFit
                            color: qgcPal.colorYellow
                        }
                        FactTextField {
                            id: threshold2Field
                            fact: batterySettings.threshold2
                            implicitWidth: ScreenTools.defaultFontPixelWidth * 5.5
                            height: ScreenTools.defaultFontPixelHeight * 1.5
                            visible: threshold2visible
                            onEditingFinished: {
                                // Validate and set the new threshold value
                                batterySettings.setThreshold2(parseInt(text));
                            }
                        }
                    }
                    QGCLabel {
                        visible: !threshold2visible
                        text: qsTr("") + batterySettings.threshold2.rawValue.toString() + qsTr("%")
                    }

                    // Low state
                    RowLayout {
                        spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Tighter spacing for icon and label
                        QGCColoredImage {
                            source: "/qmlimages/BatteryOrange.svg"
                            height: ScreenTools.defaultFontPixelHeight * 5
                            width: ScreenTools.defaultFontPixelWidth * 6
                            fillMode: Image.PreserveAspectFit
                            color: qgcPal.colorOrange
                        }
                        QGCLabel { text: qsTr("Low") }
                    }

                    // Critical state
                    RowLayout {
                        spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Tighter spacing for icon and label
                        QGCColoredImage {
                            source: "/qmlimages/BatteryCritical.svg"
                            height: ScreenTools.defaultFontPixelHeight * 5
                            width: ScreenTools.defaultFontPixelWidth * 6
                            fillMode: Image.PreserveAspectFit
                            color: qgcPal.colorRed
                        }
                        QGCLabel { text: qsTr("Critical") }
                    }
                }
            }
        }
    }
}
