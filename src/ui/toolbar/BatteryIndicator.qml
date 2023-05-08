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

//-------------------------------------------------------------------------
//-- Battery Indicator
Item {
    id:             _root
    anchors.top:    parent.top
    anchors.bottom: parent.bottom
    width:          batteryIndicatorRow.width

    property bool showIndicator: true

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    Row {
        id:             batteryIndicatorRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        spacing:        ScreenTools.defaultFontPixelWidth / 2

        Repeater {
            model: _activeVehicle ? _activeVehicle.batteries : 0

            Loader {
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                sourceComponent:    batteryVisual

                property var battery: object
            }
        }
    }
    MouseArea {
        anchors.fill:   parent
        onClicked: {
            mainWindow.showIndicatorDrawer(batteryPopup)
        }
    }

    Component {
        id: batteryPopup

        ToolIndicatorPage {
            showExpand: true

            property real _margins: ScreenTools.defaultFontPixelHeight

            FactPanelController { id: controller }

            contentItem: BatteryIndicatorContentItem { }

            expandedItem: ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight / 2

                IndicatorPageGroupLayout {
                    Layout.fillWidth:   true
                    heading:            qsTr("Low Battery Failsafe")

                    GridLayout {
                        columns: 2
                        columnSpacing: ScreenTools.defaultFontPixelHeight

                        QGCLabel { text: qsTr("Battery Low Level") }
                        FactTextField {
                            Layout.fillWidth:       true
                            Layout.preferredWidth:  editFieldWidth
                            fact:                   controller.getParameterFact(-1, "BATT_LOW_VOLT")
                        }

                        QGCLabel { text: qsTr("Battery Low Action") }
                        FactComboBox {
                            Layout.fillWidth:       true
                            fact:                   controller.getParameterFact(-1, "BATT_FS_LOW_ACT")
                            indexModel:             false
                        }

                        QGCLabel { text: qsTr("Battery Critical Level") }
                        FactTextField {
                            Layout.fillWidth:       true
                            Layout.preferredWidth:  editFieldWidth
                            fact:                   controller.getParameterFact(-1, "BATT_CRT_VOLT")
                        }

                        QGCLabel { text: qsTr("Battery Critical Action") }
                        FactComboBox {
                            Layout.fillWidth:       true
                            fact:                   controller.getParameterFact(-1, "BATT_FS_CRT_ACT")
                            indexModel:             false
                        }
                    }
                }

                IndicatorPageGroupLayout {
                    Layout.fillWidth:   true
                    showDivider:        false

                    RowLayout {
                        Layout.fillWidth: true

                        QGCLabel { Layout.fillWidth: true; text: qsTr("Vehicle Power") }
                        QGCButton {
                            text: qsTr("Configure")
                            onClicked: {
                                mainWindow.showVehicleSetupTool(qsTr("Power"))
                                indicatorDrawer.close()
                            }
                        }
                    }
                }
            }
        }
    }

//    Component {
//        id: batteryPopup

//        RowLayout {
//            spacing: _margins

//            property bool showExpand: true

//            property real _margins: ScreenTools.defaultFontPixelHeight

//            FactPanelController { id: controller }

//            ColumnLayout {
//                id:                 mainLayout
//                Layout.alignment:   Qt.AlignTop
//                spacing:            ScreenTools.defaultFontPixelHeight

//                QGCLabel {
//                    Layout.alignment:   Qt.AlignCenter
//                    text:               qsTr("Battery Status")
//                    font.family:        ScreenTools.demiboldFontFamily
//                }

//                RowLayout {
//                    spacing: ScreenTools.defaultFontPixelWidth

//                    ColumnLayout {
//                        Repeater {
//                            model: _activeVehicle ? _activeVehicle.batteries : 0

//                            ColumnLayout {
//                                spacing: 0

//                                property var batteryValuesAvailable: nameAvailableLoader.item

//                                Loader {
//                                    id:                 nameAvailableLoader
//                                    sourceComponent:    batteryValuesAvailableComponent

//                                    property var battery: object
//                                }

//                                QGCLabel { text: qsTr("Battery %1").arg(object.id.rawValue) }
//                                QGCLabel { text: qsTr("Charge State");                          visible: batteryValuesAvailable.chargeStateAvailable }
//                                QGCLabel { text: qsTr("Remaining");                             visible: batteryValuesAvailable.timeRemainingAvailable }
//                                QGCLabel { text: qsTr("Remaining") }
//                                QGCLabel { text: qsTr("Voltage") }
//                                QGCLabel { text: qsTr("Consumed");                              visible: batteryValuesAvailable.mahConsumedAvailable }
//                                QGCLabel { text: qsTr("Temperature");                           visible: batteryValuesAvailable.temperatureAvailable }
//                                QGCLabel { text: qsTr("Function");                              visible: batteryValuesAvailable.functionAvailable }
//                            }
//                        }
//                    }

//                    ColumnLayout {
//                        Repeater {
//                            model: _activeVehicle ? _activeVehicle.batteries : 0

//                            ColumnLayout {
//                                spacing: 0

//                                property var batteryValuesAvailable: valueAvailableLoader.item

//                                Loader {
//                                    id:                 valueAvailableLoader
//                                    sourceComponent:    batteryValuesAvailableComponent

//                                    property var battery: object
//                                }

//                                QGCLabel { text: "" }
//                                QGCLabel { text: object.chargeState.enumStringValue;                                        visible: batteryValuesAvailable.chargeStateAvailable }
//                                QGCLabel { text: object.timeRemainingStr.value;                                             visible: batteryValuesAvailable.timeRemainingAvailable }
//                                QGCLabel { text: object.percentRemaining.valueString + " " + object.percentRemaining.units }
//                                QGCLabel { text: object.voltage.valueString + " " + object.voltage.units }
//                                QGCLabel { text: object.mahConsumed.valueString + " " + object.mahConsumed.units;           visible: batteryValuesAvailable.mahConsumedAvailable }
//                                QGCLabel { text: object.temperature.valueString + " " + object.temperature.units;           visible: batteryValuesAvailable.temperatureAvailable }
//                                QGCLabel { text: object.function.enumStringValue;                                           visible: batteryValuesAvailable.functionAvailable }
//                            }
//                        }
//                    }
//                }
//            }

//            Rectangle {
//                Layout.fillHeight:  true
//                width:              1
//                color:              QGroundControl.globalPalette.text
//                visible:            expanded
//            }

//            ColumnLayout {
//                Layout.alignment:   Qt.AlignTop
//                visible:            expanded
//                spacing:            ScreenTools.defaultFontPixelHeight / 2

//                QGCLabel { text: qsTr("Low Battery Failsafe") }

//                GridLayout {
//                    columns: 2
//                    columnSpacing: ScreenTools.defaultFontPixelHeight

//                    QGCLabel { text: qsTr("Battery Low Level") }
//                    FactTextField {
//                        fact: controller.getParameterFact(-1, "BATT_LOW_VOLT")
//                    }

//                    QGCLabel { text: qsTr("Battery Low Action") }
//                    FactComboBox {
//                        Layout.fillWidth:   true
//                        fact:               controller.getParameterFact(-1, "BATT_FS_LOW_ACT")
//                        indexModel:         false
//                    }

//                    QGCLabel { text: qsTr("Battery Critical Level") }
//                    FactTextField {
//                        Layout.fillWidth:   true
//                        fact:               controller.getParameterFact(-1, "BATT_CRT_VOLT")
//                    }

//                    QGCLabel { text: qsTr("Battery Critical Action") }
//                    FactComboBox {
//                        Layout.fillWidth:   true
//                        fact:               controller.getParameterFact(-1, "BATT_FS_CRT_ACT")
//                        indexModel:         false
//                    }
//                }

//                Rectangle {
//                    height:             1
//                    Layout.fillWidth:   true
//                    color:              QGroundControl.globalPalette.text
//                }

//                RowLayout {
//                    Layout.fillWidth: true

//                    QGCLabel { Layout.fillWidth: true; text: qsTr("Vehicle Power") }
//                    QGCButton {
//                        text: qsTr("Configure")
//                        onClicked: {
//                            mainWindow.showVehicleSetupTool(qsTr("Power"))
//                            indicatorDrawer.close()
//                        }
//                    }
//                }
//            }
//        }
//    }

    Component {
        id: batteryVisual

        Row {
            anchors.top:    parent.top
            anchors.bottom: parent.bottom

            spacing: ScreenTools.defaultFontPixelWidth/2

            function getBatteryColor() {
                if (battery.chargeState.rawValue) {
                    switch (battery.chargeState.rawValue) {
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_OK: {
                        if(battery.percentRemaining.rawValue) {
                            if (battery.percentRemaining.rawValue < 15)
                                return qgcPal.colorRed
                            if (battery.percentRemaining.rawValue < 30)
                                return qgcPal.colorOrange
                            return qgcPal.colorGreen //qgcPal.text
                            }
                        }
                        //return qgcPal.colorGreen //qgcPal.text
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_LOW:
                        return qgcPal.colorOrange
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_CRITICAL:
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_EMERGENCY:
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_FAILED:
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_UNHEALTHY:
                        return qgcPal.colorRed
                    default:
                        return qgcPal.text
                    }
                }
                else if(battery.percentRemaining.rawValue) {
                    if (battery.percentRemaining.rawValue < 15)
                        return qgcPal.colorRed
                    if (battery.percentRemaining.rawValue < 30)
                        return qgcPal.colorOrange
                    return qgcPal.colorGreen //qgcPal.text
                }

                else{
                    return qgcPal.text
                }
            }

            function getBatteryPercentageText() {
                if (!isNaN(battery.percentRemaining.rawValue)) {
                    if (battery.percentRemaining.rawValue > 98.9) {
                        return qsTr("100%")
                    } else {
                        return battery.percentRemaining.valueString + battery.percentRemaining.units
                    }
                } else if (!isNaN(battery.voltage.rawValue)) {
                    return battery.voltage.valueString + battery.voltage.units
                } else if (battery.chargeState.rawValue !== MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED) {
                    return battery.chargeState.enumStringValue
                }
                return ""
            }

            function getBatteryIcon(){
                if (battery.percentRemaining.rawValue < 10)
                    return "/qmlimages/battery_0.svg"
                if (battery.percentRemaining.rawValue < 30)
                    return "/qmlimages/battery_20.svg"
                if (battery.percentRemaining.rawValue < 50)
                    return "/qmlimages/battery_40.svg"
                if (battery.percentRemaining.rawValue < 70)
                    return "/qmlimages/battery_60.svg"
                if (battery.percentRemaining.rawValue < 90)
                    return "/qmlimages/battery_80.svg"
                return "/qmlimages/battery_100.svg"
            }

            Rectangle{
                width:              1
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                color:              qgcPal.text
                opacity:            0.5
            }

            QGCColoredImage {
                id:                 batteryIcon
                width:              height
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                source:             getBatteryIcon()
                sourceSize.height:  height
                fillMode:           Image.PreserveAspectFit
                color:              getBatteryColor()
            }

            Column {
                id:                     batteryValuesColumn
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin:     ScreenTools.defaultFontPixelWidth / 2
                //anchors.left:           batteryIcon.right

                QGCLabel {
                    id:         batteryVoltageValue
                    //visible:    _activeVehicle && !isNaN(_activeVehicle.battery.voltage.rawValue)
                    color:      qgcPal.text
                    text:       _activeVehicle ? battery.voltage.valueString + battery.voltage.units : ""
                }

                QGCLabel {
                    text:                   getBatteryPercentageText()
                    //font.pointSize:         ScreenTools.mediumFontPointSize
                    color:                  qgcPal.text
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

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
}
