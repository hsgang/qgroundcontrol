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

ColumnLayout {
    id:         mainLayout
    spacing:    ScreenTools.defaultFontPixelHeight / 2
    Layout.fillWidth: true

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    property var _batterySettings: QGroundControl.settingsManager.batterySettings
    property real _batteryCellCount: _batterySettings.batteryCellCount.value
    property real _margins: ScreenTools.defaultFontPixelHeight / 2
    property real _columnSpacing:   ScreenTools.defaultFontPixelHeight / 3

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

    QGCLabel {
        Layout.alignment:   Qt.AlignCenter
        text:               qsTr("Battery Status")
        font.bold:          true
    }


    ColumnLayout {
        spacing: _margins

        Repeater {
            model: _activeVehicle ? _activeVehicle.batteries : 0

            Rectangle {
                Layout.preferredHeight: batteryColumnLayout.height + _margins
                Layout.preferredWidth:  batteryColumnLayout.width + _margins
                color:                  qgcPal.windowShade
                radius:                 _margins / 2
                Layout.fillWidth:       true

                property var batteryValuesAvailable: nameAvailableLoader.item

                Loader {
                    id:                 nameAvailableLoader
                    sourceComponent:    batteryValuesAvailableComponent

                    property var battery: object
                }

                ColumnLayout {
                    id:                 batteryColumnLayout
                    anchors.margins:    _margins / 2
                    anchors.top:        parent.top
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    spacing:            _columnSpacing

                    ComponentLabelValueRow {
                        labelText:  qsTr("Battery ID")
                        valueText:  qsTr("Battery %1").arg(object.id.rawValue)
                    }
                    Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; visible: batteryValuesAvailable.chargeStateAvailable;}

                    ComponentLabelValueRow {
                        labelText:  qsTr("Charge State")
                        valueText:  object.chargeState.enumStringValue
                        visible:    batteryValuesAvailable.chargeStateAvailable
                    }
                    Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; visible: batteryValuesAvailable.timeRemainingAvailable;}

                    ComponentLabelValueRow {
                        labelText:  qsTr("Remaining Time")
                        valueText:  object.timeRemainingStr.value
                        visible:    batteryValuesAvailable.timeRemainingAvailable
                    }
                    Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; }

                    ComponentLabelValueRow {
                        labelText:  qsTr("Remaining")
                        valueText:  object.percentRemaining.valueString + " " + object.percentRemaining.units
                    }
                    Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; }

                    ComponentLabelValueRow {
                        labelText:  qsTr("Voltage")
                        valueText:  object.voltage.valueString + " " + object.voltage.units
                    }
                    Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; }

                    ComponentLabelValueRow {
                        labelText:  qsTr("Cell Voltage")
                        valueText:  (object.voltage.value / _batteryCellCount).toFixed(2) + " " + object.voltage.units
                    }
                    Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; visible:    batteryValuesAvailable.currentAvailable;}

                    ComponentLabelValueRow {
                        labelText:  qsTr("Current")
                        valueText:  object.current.valueString + " " + object.current.units
                        visible:    batteryValuesAvailable.currentAvailable
                    }
                    Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; visible:    batteryValuesAvailable.mahConsumedAvailable;}

                    ComponentLabelValueRow {
                        labelText:  qsTr("Consumed")
                        valueText:  object.mahConsumed.valueString + " " + object.mahConsumed.units
                        visible:    batteryValuesAvailable.mahConsumedAvailable
                    }
                    Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; visible:    batteryValuesAvailable.temperatureAvailable;}

                    ComponentLabelValueRow {
                        labelText:  qsTr("Temperature")
                        valueText:  object.temperature.valueString + " " + object.temperature.units
                        visible:    batteryValuesAvailable.temperatureAvailable
                    }
                    Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; visible:    batteryValuesAvailable.functionAvailable;}

                    ComponentLabelValueRow {
                        labelText:  qsTr("Function")
                        valueText:  object.function.enumStringValue
                        visible:    batteryValuesAvailable.functionAvailable
                    }
                } //columnlayout
            } // rectangle
        } // repeater
    }
}
