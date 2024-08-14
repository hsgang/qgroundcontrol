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

//-------------------------------------------------------------------------
//-- Battery Indicator
Item {
    id:             control
    anchors.top:    parent.top
    anchors.bottom: parent.bottom
    width:          batteryIndicatorRow.width

    property bool       showIndicator:      true
    property bool       waitForParameters:  false   // UI won't show until parameters are ready
    property Component  expandedPageComponent

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    // property Fact   _indicatorDisplay:  QGroundControl.settingsManager.batteryIndicatorSettings.display
    // property bool   _showPercentage:    _indicatorDisplay.rawValue === 0
    // property bool   _showVoltage:       _indicatorDisplay.rawValue === 1
    // property bool   _showBoth:          _indicatorDisplay.rawValue === 2

    property var _batterySettings:  QGroundControl.settingsManager.batterySettings
    property real _batteryCellCount: _batterySettings.batteryCellCount.value
    property bool _showCellVoltage: QGroundControl.settingsManager.batterySettings.showCellVoltage.value

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
            mainWindow.showIndicatorDrawer(batteryIndicatorPage)
        }
    }

    Component {
        id: batteryIndicatorPage

        BatteryIndicatorPage {

        }
    }

    Component {
        id: batteryVisual

        Row {
            anchors.top:    parent.top
            anchors.bottom: parent.bottom

            property bool isBlink : false

            spacing: ScreenTools.defaultFontPixelHeight / 5

            function getBatteryColor() {
                if (battery.chargeState.rawValue) {
                    switch (battery.chargeState.rawValue) {
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_OK:
                        if(battery.percentRemaining.rawValue >= 0) {
                            if (battery.percentRemaining.rawValue < 15) {
                                isBlink = true
                                return qgcPal.colorRed
                            }else if (battery.percentRemaining.rawValue < 30) {
                                return qgcPal.colorOrange
                            }else if (battery.percentRemaining.rawValue >=30 ) {
                                isBlink = false
                                return qgcPal.colorGreen //qgcPal.text
                            }
                        } else {
                            return qgcPal.text
                        }
                        break;
                        //return qgcPal.colorGreen //qgcPal.text
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_LOW:
                        return qgcPal.colorOrange
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_CRITICAL:
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_EMERGENCY:
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_FAILED:
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_UNHEALTHY:
                        isBlink = true
                        return qgcPal.colorRed
                    default:
                        isBlink = false
                        return qgcPal.text
                    }
                } else if(battery.percentRemaining.rawValue) {
                    if (battery.percentRemaining.rawValue < 15 ) {
                        isBlink = true
                        return qgcPal.colorRed
                    } else if (battery.percentRemaining.rawValue < 30 ) {
                        return qgcPal.colorOrange
                    } else if (battery.percentRemaining.rawValue >=30 ) {
                        isBlink = false
                        return qgcPal.colorGreen //qgcPal.text
                    }
                } else{
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
                return qsTr("n/a")
            }

            function getBatteryVoltageText() {
                if (!isNaN(battery.voltage.rawValue)) {
                    return battery.voltage.valueString + battery.voltage.units
                } else if (battery.chargeState.rawValue !== MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED) {
                    return battery.chargeState.enumStringValue
                }
                return qsTr("n/a")
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

            state: isBlink ? "blinking" : ""

            states: [
                State {
                    name: "blinking"
                    when: isBlink
                }
            ]

//            transitions:[
//                Transition {
//                    from: ""
//                    to: "blinking"

//                    SequentialAnimation{
//                        loops:  Animation.Infinite
//                        PropertyAnimation {
//                            target: batteryIcon
//                            property: "opacity";
//                            from: 1.0;
//                            to: 0.0;
//                            duration: 500;
//                        }
//                        PropertyAnimation {
//                            target: batteryIcon
//                            property: "opacity";
//                            from: 0.0;
//                            to: 1.0;
//                            duration: 500;
//                        }
//                    }
//                }
//            ]

            QGCColoredImage {
                id:                 batteryIcon
                height:             parent.height
                width:              height * 0.7
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                source:             getBatteryIcon()
                sourceSize.height:  height
                fillMode:           Image.PreserveAspectCrop //Image.PreserveAspectFit
                color:              getBatteryColor()
            }

            Column {
                id:                     batteryValuesColumn
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin:     ScreenTools.defaultFontPixelWidth / 2

                QGCLabel {
                    id:                 batteryVoltageValue
                    anchors.left:       parent.left
                    font.pointSize:     ScreenTools.smallFontPointSize
                    color:              qgcPal.text
                    text:               _activeVehicle ? (_showCellVoltage ? _cellVoltage : battery.voltage.value.toFixed(1) + battery.voltage.units) : ""

                    property string _cellVoltage: (battery.voltage.value / _batteryCellCount).toFixed(2) + battery.voltage.units
                }

                QGCLabel {
                    anchors.left:       parent.left
                    color:              qgcPal.text
                    text:               getBatteryPercentageText()
                }
            }            

//            ColumnLayout {
//                id:                     batteryInfoColumn
//                anchors.top:            parent.top
//                anchors.bottom:         parent.bottom
//                spacing:                0

//                QGCLabel {
//                    Layout.alignment:       Qt.AlignHCenter
//                    verticalAlignment:      Text.AlignVCenter
//                    color:                  getBatteryColor()
//                    text:                   getBatteryPercentageText()
//                    font.pointSize:         _showBoth ? ScreenTools.defaultFontPointSize : ScreenTools.mediumFontPointSize
//                    visible:                _showBoth || _showPercentage
//                }

//                QGCLabel {
//                    Layout.alignment:       Qt.AlignHCenter
//                    font.pointSize:         _showBoth ? ScreenTools.defaultFontPointSize : ScreenTools.mediumFontPointSize
//                    color:                  getBatteryColor()
//                    text:                   getBatteryVoltageText()
//                    visible:                _showBoth || _showVoltage
//                }
//            }
        }
    }
}
