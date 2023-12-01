/****************************************************************************
 *
 * (c) 2009-2022 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts  1.11

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.FactControls          1.0

RowLayout {
    id: _root
    spacing: 0

    property bool showIndicator: true

    property real fontPointSize: ScreenTools.largeFontPointSize
    property var  activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    property real editFieldWidth: ScreenTools.defaultFontPixelWidth * 13

    RowLayout {
        Layout.fillWidth: true

        QGCColoredImage {
            id:         flightModeIcon
            width:      ScreenTools.defaultFontPixelWidth * 3
            height:     ScreenTools.defaultFontPixelHeight
            fillMode:   Image.PreserveAspectFit
            mipmap:     true
            color:      qgcPal.text
            source:     "/qmlimages/vehicleQuadRotor.svg"
        }

        QGCLabel {
            id:                 modeLabel
            text:               activeVehicle ? activeVehicle.flightMode : qsTr("N/A", "No data to display")
            font.pointSize:     fontPointSize * 0.9
            Layout.alignment:   Qt.AlignCenter

            MouseArea {
                anchors.fill:   parent
                onClicked:      mainWindow.showIndicatorDrawer(drawerComponent)
            }
        }
    }

    Component {
        id:             drawerComponent

        ToolIndicatorPage {
            id:         mainLayout
            showExpand: true

            FactPanelController { id: controller }

            property var  activeVehicle:            QGroundControl.multiVehicleManager.activeVehicle

            property Fact landSpeedFact:            controller.getParameterFact(-1, "LAND_SPEED", false)
            property Fact precisionLandingFact:     controller.getParameterFact(-1, "PLND_ENABLED", false)
            property Fact atcInputTCFact:           controller.getParameterFact(-1, "ATC_INPUT_TC", false)
            property Fact loitSpeedFact:            controller.getParameterFact(-1, "LOIT_SPEED", false)
            property Fact wpnavSpeedFact:           controller.getParameterFact(-1, "WPNAV_SPEED", false)
            property Fact wpnavSpeedUpFact:         controller.getParameterFact(-1, "WPNAV_SPEED_UP", false)
            property Fact wpnavSpeedDnFact:         controller.getParameterFact(-1, "WPNAV_SPEED_DN", false)
            property Fact wpnavRadiusFact:          controller.getParameterFact(-1, "WPNAV_RADIUS", false)

            property var  qgcPal:                   QGroundControl.globalPalette
            property real margins:                  ScreenTools.defaultFontPixelHeight
            property real valueColumnWidth:         editFieldWidth

            property var params : ListModel{
//                ListElement {
//                    title:          qsTr("Responsiveness")
//                    param:          "ATC_INPUT_TC"
//                    description:    ""
//                    min:            0.01
//                    max:            1
//                    step:           0.01
//                }
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
            contentItem: FlightModeToolIndicatorContentItem { }

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
                            fact:                   controller.getParameterFact(-1, "RTL_ALT")
                            Layout.preferredWidth:  valueColumnWidth
                            visible:                landSpeedFact
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

                        QGCLabel { Layout.fillWidth: true; text: qsTr("RC Transmitter Flight Modes") }
                        QGCButton {
                            text: qsTr("Configure")
                            onClicked: {
                                mainWindow.showVehicleSetupTool(qsTr("Radio"))
                                indicatorDrawer.close()
                                componentDrawer.visible = false
                            }
                        }
                    }
                }

            }
        }
    }
}
