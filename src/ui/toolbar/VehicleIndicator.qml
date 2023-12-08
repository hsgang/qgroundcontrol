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
import QGroundControl.Controllers           1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.FactControls          1.0

//-------------------------------------------------------------------------
Item {
    id:             _root
    width:          vehicleRow.width
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator: true

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    Row {
        id: vehicleRow
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: ScreenTools.defaultFontPixelWidth / 2

        QGCColoredImage {
            id:                 roiIcon
            width:              height
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            sourceSize.height:  height
            source:             "/qmlimages/vehicleQuadRotor.svg"
            color:              _activeVehicle.readyToFlyAvailable && _activeVehicle.readyToFly ? qgcPal.colorGreen : qgcPal.text
            fillMode:           Image.PreserveAspectFit
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorDrawer(vehicleInfoComponent)
    }

    Component {
        id: vehicleInfoComponent

        ToolIndicatorPage {
            id:         mainLayout
            showExpand: true

            FactPanelController { id: controller }
            APMAirframeComponentController { id: apmController }

            property var  activeVehicle:            QGroundControl.multiVehicleManager.activeVehicle

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

            property var  qgcPal:                   QGroundControl.globalPalette
            property real margins:                  ScreenTools.defaultFontPixelHeight
            property real valueColumnWidth:         editFieldWidth

            property var params : ListModel{
                ListElement {
                   title:          qsTr("Responsiveness")
                   param:          "ATC_INPUT_TC"
                   description:    ""
                   min:            0.01
                   max:            0.5
                   step:           0.05
                }
                ListElement {
                    title:          qsTr("Loiter Horizontal Speed(cm/s)")
                    param:          "LOIT_SPEED"
                    description:    ""
                    min:            100
                    max:            1500
                    step:           100
                }
                ListElement {
                    title:          qsTr("WP Horizontal Speed(cm/s)")
                    param:          "WPNAV_SPEED"
                    description:    ""
                    min:            100
                    max:            1500
                    step:           100
                }
                ListElement {
                    title:          qsTr("WP Climb Speed(cm/s)")
                    param:          "WPNAV_SPEED_UP"
                    description:    ""
                    min:            100
                    max:            500
                    step:           50
                }
                ListElement {
                    title:          qsTr("WP Descent Speed(cm/s)")
                    param:          "WPNAV_SPEED_DN"
                    description:    ""
                    min:            100
                    max:            500
                    step:           50
                }
                ListElement {
                    title:          qsTr("Mission Turning Radius(cm)")
                    param:          "WPNAV_RADIUS"
                    description:    ""
                    min:            100
                    max:            1000
                    step:           100
                }
            }

            // Mode list
            contentItem: ColumnLayout {
                Layout.preferredWidth:  parent.width
                Layout.alignment:       Qt.AlignTop
                spacing:                ScreenTools.defaultFontPixelHeight

                QGCLabel {
                    text:                   qsTr("Vehicle Information")
                    font.family:            ScreenTools.demiboldFontFamily
                    Layout.fillWidth:       true
                    horizontalAlignment:    Text.AlignHCenter
                }

                ColumnLayout {
                    Layout.fillWidth:   true
                    spacing: ScreenTools.defaultFontPixelHeight * 0.5

                    VehicleSummaryRow {
                        labelText: qsTr("Firmware Type")
                        valueText: _activeVehicle.firmwareTypeString
                    }

                    VehicleSummaryRow {
                        labelText: qsTr("Firmware Version")
                        valueText: globals.activeVehicle.firmwareMajorVersion === -1 ? qsTr("Unknown") : globals.activeVehicle.firmwareMajorVersion + "." + globals.activeVehicle.firmwareMinorVersion + "." + globals.activeVehicle.firmwarePatchVersion + globals.activeVehicle.firmwareVersionTypeString
                    }

                    VehicleSummaryRow {
                        labelText:  qsTr("Frame Class")
                        valueText:  _frameClass.enumStringValue
                    }

                    Rectangle {
                        height:             1
                        Layout.fillWidth:   true
                        color:              QGroundControl.globalPalette.text
                    }

                    VehicleSummaryRow {
                        labelText: qsTr("Loiter Speed")
                        valueText: (loitSpeedFact.value * 0.01).toFixed(1) + " m/s"
                    }

                    VehicleSummaryRow {
                        labelText: qsTr("Pilot Climb Speed")
                        valueText: (pilotSpeedUpFact.value * 0.01).toFixed(1) + " m/s"
                    }

                    VehicleSummaryRow {
                        labelText: qsTr("Pilot Descent Speed")
                        valueText: { isPilotSpeedDn ?
                                    (pilotSpeedDnFact.value * 0.01).toFixed(1) + " m/s" :
                                    (pilotSpeedUpFact.value * 0.01).toFixed(1) + " m/s"
                        }
                    }

                    Rectangle {
                        height:             1
                        Layout.fillWidth:   true
                        color:              QGroundControl.globalPalette.text
                    }

                    VehicleSummaryRow {
                        labelText: qsTr("WP Horizontal Speed")
                        valueText: (wpnavSpeedFact.value * 0.01).toFixed(1) + " m/s"
                    }

                    VehicleSummaryRow {
                        labelText: qsTr("WP Climb Speed")
                        valueText: (wpnavSpeedUpFact.value * 0.01).toFixed(1) + " m/s"
                    }

                    VehicleSummaryRow {
                        labelText: qsTr("WP Descent Speed")
                        valueText: (wpnavSpeedDnFact.value * 0.01).toFixed(1) + " m/s"
                    }

                    Rectangle {
                        height:             1
                        Layout.fillWidth:   true
                        color:              QGroundControl.globalPalette.text
                    }

                    VehicleSummaryRow {
                        labelText: qsTr("RTL Altitude")
                        valueText: (rtlAltitudeFact.value * 0.01).toFixed(1) + " m"
                    }

                    VehicleSummaryRow {
                        labelText: qsTr("Land Speed")
                        valueText: (landSpeedFact.value * 0.01).toFixed(1) + " m/s"
                    }

                    Rectangle {
                        height:             1
                        Layout.fillWidth:   true
                        color:              QGroundControl.globalPalette.text
                    }

                    VehicleSummaryRow {
                        labelText:  qsTr("Boot Count")
                        valueText:  visible ? _stat_bootcnt.valueString : ""
                        visible:    _frameTypeAvailable
                    }

                    VehicleSummaryRow {
                        labelText:  qsTr("Total Runtime")
                        valueText:  visible ? _stat_runtime.valueString + " s" : ""
                        visible:    _frameTypeAvailable
                    }

                    VehicleSummaryRow {
                        labelText:  qsTr("Total Flight Time")
                        valueText:  visible ? _stat_flttime.valueString + " s": ""
                        visible:    _frameTypeAvailable
                    }
                }
            }

            // Settings
            expandedItem: ColumnLayout{
                Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 50
                spacing:                margins / 2

                IndicatorPageGroupLayout {
                    Layout.fillWidth: true

                    GridLayout {
                        Layout.fillWidth:   true
                        columns:            2

                        QGCLabel {
                            Layout.fillWidth: true
                            text: qsTr("RTL Altitude")
                            visible:                landSpeedFact
                        }

                        FactTextField {
                            fact:                   rtlAltitudeFact
                            Layout.preferredWidth:  valueColumnWidth
                            visible:                landSpeedFact
                            horizontalAlignment:    Text.AlignRight;
                        }

                        QGCLabel {
                            id:                     landDescentLabel
                            Layout.fillWidth:       true
                            text:                   qsTr("Land Descent Rate")
                            visible:                landSpeedFact && controller.vehicle && !controller.vehicle.fixedWing
                        }

                        FactTextField {
                            fact:                   landSpeedFact
                            Layout.preferredWidth:  valueColumnWidth
                            visible:                landSpeedFact && controller.vehicle && !controller.vehicle.fixedWing
                            horizontalAlignment:    Text.AlignRight;
                        }

//                        QGCLabel {
//                            Layout.fillWidth:       true
//                            text:                   qsTr("Precision Landing")
//                            visible:                precisionLandingCombo.visible
//                        }

//                        FactComboBox {
//                            id:                     precisionLandingCombo
//                            Layout.minimumWidth:    editFieldWidth
//                            fact:                   precisionLandingFact
//                            indexModel:             false
//                            sizeToContents:         true
//                            visible:                precisionLandingFact
//                        }
                    }
                }

                IndicatorPageGroupLayout {
                    Layout.fillWidth:   true
                    visible:            atcInputTCFact

                    ColumnLayout {
                        Layout.fillWidth:   true

                        FactSliderPanel {
                            width:       parent.width
                            sliderModel: params
                        }
                    }

                    Item {
                        height:             1
                        Layout.fillWidth:   true
                    }
                }

                IndicatorPageGroupLayout {
                    Layout.fillWidth:   true
                    showDivider:        false

                    RowLayout {
                        Layout.fillWidth: true

                        QGCLabel { Layout.fillWidth: true; text: qsTr("Vehicle Summary") }
                        QGCButton {
                            text: qsTr("Configure")
                            onClicked: {
                                mainWindow.showVehicleSetupTool(qsTr("Summary"))
                                indicatorDrawer.close()
                                componentDrawer.visible = false
                            }
                        }
                    }
                } // IndicatorPageGroupLayout
            } // expandedItem: ColumnLayout
        } // ToolIndicatorPage
    } // Component
} // Item
