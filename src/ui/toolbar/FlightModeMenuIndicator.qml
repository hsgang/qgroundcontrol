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

    property real editFieldWidth:        ScreenTools.defaultFontPixelWidth * 13

    RowLayout {
        Layout.fillWidth: true

        QGCColoredImage {
            id:         flightModeIcon
            width:      ScreenTools.defaultFontPixelWidth * 3
            height:     ScreenTools.defaultFontPixelHeight
            fillMode:   Image.PreserveAspectFit
            mipmap:     true
            color:      qgcPal.text
            source:     "/qmlimages/FlightModesComponentIcon.png"
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

            property var  activeVehicle:            QGroundControl.multiVehicleManager.activeVehicle

            property Fact landSpeedFact:            controller.getParameterFact(-1, "LAND_SPEED", false)
            property Fact precisionLandingFact:     controller.getParameterFact(-1, "PLND_ENABLED", false)
            property Fact atcInputTCFact:           controller.getParameterFact(-1, "ATC_INPUT_TC", false)
            property Fact loitSpeedFact:            controller.getParameterFact(-1, "LOIT_SPEED", false)
            property Fact wpnavRadiusFact:          controller.getParameterFact(-1, "WPNAV_RADIUS", false)

            property var  qgcPal:                   QGroundControl.globalPalette
            property real margins:                  ScreenTools.defaultFontPixelHeight
            property real valueColumnWidth:         Math.max(editFieldWidth, precisionLandingCombo.implicitWidth)

            FactPanelController { id: controller }

            // Mode list
            contentItem: FlightModeToolIndicatorContentItem { }

            // Settings
            expandedItem: ColumnLayout{
                Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 60
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

                        QGCLabel {
                            Layout.fillWidth:       true
                            text:                   qsTr("Precision Landing")
                            visible:                precisionLandingCombo.visible
                        }

                        FactComboBox {
                            id:                     precisionLandingCombo
                            Layout.minimumWidth:    editFieldWidth
                            fact:                   precisionLandingFact
                            indexModel:             false
                            sizeToContents:         true
                            visible:                precisionLandingFact
                        }
                    }
                }

                IndicatorPageGroupLayout {
                    Layout.fillWidth:   true
                    visible:            atcInputTCFact

                    ColumnLayout {
                        Layout.fillWidth:   true

//                        QGCCheckBoxSlider {
//                            id:                 responsivenessCheckBox
//                            Layout.fillWidth:   true
//                            text:               qsTr("Overall Responsiveness")
//                            checked:            atcInputTCFact && atcInputTCFact.value >= 0

//                            onClicked: {
//                                if (checked) {
//                                    atcInputTCFact.value = Math.abs(atcInputTCFact.value)
//                                } else {
//                                    atcInputTCFact.value = -Math.abs(atcInputTCFact.value)
//                                }
//                            }
//                        }

                        QGCLabel { text: qsTr("Responsiveness") }

                        FactSlider {
                            width:              parent.width
                            //enabled:            responsivenessCheckBox.checked
                            fact:               atcInputTCFact
                            from:               0.01
                            to:                 1
                            stepSize:           0.01
                        }

//                        QGCLabel {
//                            Layout.fillWidth:   true
//                            enabled:            responsivenessCheckBox.checked
//                            text:               qsTr("A higher value makes the vehicle react faster. Be aware that this affects braking as well, and a combination of slow responsiveness with high maximum velocity will lead to long braking distances.")
//                            wrapMode:           QGCLabel.WordWrap
//                        }
//                        QGCLabel {
//                            Layout.fillWidth:   true
//                            visible:            atcInputTCFact && atcInputTCFact.value > 0.8
//                            color:              qgcPal.warningText
//                            text:               qsTr("Warning: a high responsiveness requires a vehicle with large thrust-to-weight ratio. The vehicle might lose altitude otherwise.")
//                            wrapMode:           QGCLabel.WordWrap
//                        }
                    }

                    Item {
                        height:             1
                        Layout.fillWidth:   true
                    }

                    ColumnLayout {
                        Layout.fillWidth:   true
                        visible:            loitSpeedFact

//                        QGCCheckBoxSlider {
//                            id:                 xyVelCheckBox
//                            Layout.fillWidth:   true
//                            text:               qsTr("Overall Horizontal Velocity (cm/s)")
//                            checked:            loitSpeedFact && loitSpeedFact.value >= 0

//                            onClicked: {
//                                if (checked) {
//                                    loitSpeedFact.value = Math.abs(loitSpeedFact.value)
//                                } else {
//                                    loitSpeedFact.value = -Math.abs(loitSpeedFact.value)
//                                }
//                            }
//                        }

                        QGCLabel { text: qsTr("Horizontal Velocity (cm/s)") }

                        FactSlider {
                            width:      parent.width
                            //enabled:    xyVelCheckBox.checked
                            fact:       loitSpeedFact
                            from:       50
                            to:         2000
                            stepSize:   50
                        }
                    }
                }

                IndicatorPageGroupLayout {
                    Layout.fillWidth:   true

                    ColumnLayout {
                        Layout.fillWidth:   true
                        visible:            wpnavRadiusFact

                        QGCLabel { text: qsTr("Mission Turning Radius(cm)") }

                        FactSlider {
                            width:      parent.width
                            fact:       wpnavRadiusFact
                            from:       100
                            to:         1000
                            stepSize:   100
                        }

//                        QGCLabel {
//                            width:      parent.width
//                            text:       qsTr("Increasing this leads to rounder turns in missions (corner cutting). Use the minimum value for accurate corner tracking.")
//                            wrapMode:   QGCLabel.WordWrap
//                        }
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
                            }
                        }
                    }
                }

            }
        }
    }
}
