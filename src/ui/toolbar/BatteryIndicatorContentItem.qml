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
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.FactControls          1.0
import MAVLink                              1.0

ColumnLayout {
    id:         mainLayout
    spacing:    ScreenTools.defaultFontPixelHeight / 2
    Layout.fillWidth: true

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    property var _batterySettings: QGroundControl.settingsManager.batterySettings
    property real _batteryCellCount: _batterySettings.batteryCellCount.value
    property real _margins: ScreenTools.defaultFontPixelHeight / 2

    Component {
        id: batteryValuesAvailableComponent

        QtObject {
            property bool functionAvailable:        battery.function.rawValue !== MAVLink.MAV_BATTERY_FUNCTION_UNKNOWN
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
        font.family:        ScreenTools.demiboldFontFamily
    }


    ColumnLayout {
        spacing: _margins

        Repeater {
            model: _activeVehicle ? _activeVehicle.batteries : 0

            Rectangle {
                Layout.preferredHeight: batteryColumnLayout.height + _margins //ScreenTools.defaultFontPixelHeight / 2
                Layout.preferredWidth:  batteryColumnLayout.width + _margins //ScreenTools.defaultFontPixelHeight
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
                    spacing:            _margins

                // ColumnLayout {
                //     spacing: ScreenTools.defaultFontPixelHeight / 2
                //     Layout.fillWidth: true

                    // property var batteryValuesAvailable: nameAvailableLoader.item

                    // Loader {
                    //     id:                 nameAvailableLoader
                    //     sourceComponent:    batteryValuesAvailableComponent

                    //     property var battery: object
                    // }

                    ComponentLabelValueRow {
                        labelText:  qsTr("Battery ID")
                        valueText:  qsTr("Battery %1").arg(object.id.rawValue)
                    }
                    ComponentLabelValueRow {
                        labelText:  qsTr("Charge State")
                        valueText:  object.chargeState.enumStringValue
                        visible:    batteryValuesAvailable.chargeStateAvailable
                    }
                    ComponentLabelValueRow {
                        labelText:  qsTr("Remaining Time")
                        valueText:  object.timeRemainingStr.value
                        visible:    batteryValuesAvailable.timeRemainingAvailable
                    }
                    ComponentLabelValueRow {
                        labelText:  qsTr("Remaining")
                        valueText:  object.percentRemaining.valueString + " " + object.percentRemaining.units
                    }
                    ComponentLabelValueRow {
                        labelText:  qsTr("Voltage")
                        valueText:  object.voltage.valueString + " " + object.voltage.units
                    }
                    ComponentLabelValueRow {
                        labelText:  qsTr("Cell Voltage")
                        valueText:  (object.voltage.value / _batteryCellCount).toFixed(2) + " " + object.voltage.units
                    }
                    ComponentLabelValueRow {
                        labelText:  qsTr("Current")
                        valueText:  object.current.valueString + " " + object.current.units
                        visible:    batteryValuesAvailable.currentAvailable
                    }
                    ComponentLabelValueRow {
                        labelText:  qsTr("Consumed")
                        valueText:  object.mahConsumed.valueString + " " + object.mahConsumed.units
                        visible:    batteryValuesAvailable.mahConsumedAvailable
                    }
                    ComponentLabelValueRow {
                        labelText:  qsTr("Temperature")
                        valueText:  object.temperature.valueString + " " + object.temperature.units
                        visible:    batteryValuesAvailable.temperatureAvailable
                    }
                    ComponentLabelValueRow {
                        labelText:  qsTr("Function")
                        valueText:  object.function.enumStringValue
                        visible:    batteryValuesAvailable.functionAvailable
                    }
                }
            }
        } // columnlayout
    }
}
