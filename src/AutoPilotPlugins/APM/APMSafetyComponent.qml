/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

SetupPage {
    id:             safetyPage
    pageComponent:  safetyPageComponent

    Component {
        id: safetyPageComponent

        Flow {
            id:         flowLayout
            width:      availableWidth
            spacing:     _margins / 2

        // ColumnLayout{
        //     width:      Math.max(implicitWidth, ScreenTools.defaultFontPixelWidth * 50)
        //     spacing:    ScreenTools.defaultFontPixelHeight

            FactPanelController { id: controller; }

            QGCPalette { id: ggcPal; colorGroupEnabled: true }

            property Fact _batt1Monitor:                    controller.getParameterFact(-1, "BATT_MONITOR")
            property Fact _batt2Monitor:                    controller.getParameterFact(-1, "BATT2_MONITOR", false /* reportMissing */)
            property bool _batt2MonitorAvailable:           controller.parameterExists(-1, "BATT2_MONITOR")
            property bool _batt1MonitorEnabled:             _batt1Monitor.rawValue !== 0
            property bool _batt2MonitorEnabled:             _batt2MonitorAvailable ? _batt2Monitor.rawValue !== 0 : false
            property bool _batt1ParamsAvailable:            controller.parameterExists(-1, "BATT_CAPACITY")
            property bool _batt2ParamsAvailable:            controller.parameterExists(-1, "BATT2_CAPACITY")

            property Fact _failsafeBatt1LowAct:             controller.getParameterFact(-1, "BATT_FS_LOW_ACT", false /* reportMissing */)
            property Fact _failsafeBatt2LowAct:             controller.getParameterFact(-1, "BATT2_FS_LOW_ACT", false /* reportMissing */)
            property Fact _failsafeBatt1CritAct:            controller.getParameterFact(-1, "BATT_FS_CRT_ACT", false /* reportMissing */)
            property Fact _failsafeBatt2CritAct:            controller.getParameterFact(-1, "BATT2_FS_CRT_ACT", false /* reportMissing */)
            property Fact _failsafeBatt1LowMah:             controller.getParameterFact(-1, "BATT_LOW_MAH", false /* reportMissing */)
            property Fact _failsafeBatt2LowMah:             controller.getParameterFact(-1, "BATT2_LOW_MAH", false /* reportMissing */)
            property Fact _failsafeBatt1CritMah:            controller.getParameterFact(-1, "BATT_CRT_MAH", false /* reportMissing */)
            property Fact _failsafeBatt2CritMah:            controller.getParameterFact(-1, "BATT2_CRT_MAH", false /* reportMissing */)
            property Fact _failsafeBatt1LowVoltage:         controller.getParameterFact(-1, "BATT_LOW_VOLT", false /* reportMissing */)
            property Fact _failsafeBatt2LowVoltage:         controller.getParameterFact(-1, "BATT2_LOW_VOLT", false /* reportMissing */)
            property Fact _failsafeBatt1CritVoltage:        controller.getParameterFact(-1, "BATT_CRT_VOLT", false /* reportMissing */)
            property Fact _failsafeBatt2CritVoltage:        controller.getParameterFact(-1, "BATT2_CRT_VOLT", false /* reportMissing */)

            property Fact _armingCheck: controller.getParameterFact(-1, "ARMING_CHECK")

            property real _margins:                 ScreenTools.defaultFontPixelHeight
            property real _comboBoxPreferredWidth:  ScreenTools.defaultFontPixelWidth * 20
            property real _textFieldPreferredWidth: ScreenTools.defaultFontPixelWidth * 20
            property real _innerMargin:     _margins / 2
            property bool _showIcon:        !ScreenTools.isTinyScreen
            property bool _roverFirmware:   controller.parameterExists(-1, "MODE1") // This catches all usage of ArduRover firmware vehicle types: Rover, Boat...

            property string _restartRequired: qsTr("Requires vehicle reboot")

            Component {
                id: copterGeneralFS

                SettingsGroupLayout {
                    Layout.fillWidth:       true
                    width: ScreenTools.defaultFontPixelWidth * 40
                    heading:                qsTr("Communication Failsafe")

                    Image {
                        Layout.alignment:   Qt.AlignHCenter
                        height:             ScreenTools.defaultFontPixelHeight * 4
                        //width:              ScreenTools.defaultFontPixelWidth * 12
                        sourceSize.width:   width
                        mipmap:             true
                        fillMode:           Image.PreserveAspectFit
                        source:             qgcPal.globalTheme === QGCPalette.Light ? "/qmlimages/DatalinkLossLight.svg" : "/qmlimages/DatalinkLoss.svg"
                    }

                    LabelledFactComboBox {
                        label:              qsTr("Ground Station failsafe")
                        fact:               _failsafeGCSEnable
                        indexModel:         false
                        comboBoxPreferredWidth: _comboBoxPreferredWidth
                    }
                    LabelledFactComboBox {
                        label:              qsTr("Throttle failsafe")
                        fact:               _failsafeThrEnable
                        indexModel:         false
                        comboBoxPreferredWidth: _comboBoxPreferredWidth
                    }
                    // LabelledFactTextField {
                    //     Layout.fillWidth:   true
                    //     label:              qsTr("PWM threshold")
                    //     fact:               _failsafeThrValue
                    //     textFieldShowUnits: true
                    //     textFieldPreferredWidth: _textFieldPreferredWidth
                    // }
                }
            }

            Loader {
                id:                 copterGeneralFSLoader
                width: ScreenTools.defaultFontPixelWidth * 40
                Layout.alignment:   Qt.AlignHCenter
                sourceComponent: controller.vehicle.multiRotor ? copterGeneralFS : undefined

                property Fact _failsafeGCSEnable:               controller.getParameterFact(-1, "FS_GCS_ENABLE")
                property Fact _failsafeBattLowAct:              controller.getParameterFact(-1, "r.BATT_FS_LOW_ACT", false /* reportMissing */)
                property Fact _failsafeBattMah:                 controller.getParameterFact(-1, "r.BATT_LOW_MAH", false /* reportMissing */)
                property Fact _failsafeBattVoltage:             controller.getParameterFact(-1, "r.BATT_LOW_VOLT", false /* reportMissing */)
                property Fact _failsafeThrEnable:               controller.getParameterFact(-1, "FS_THR_ENABLE")
                property Fact _failsafeThrValue:                controller.getParameterFact(-1, "FS_THR_VALUE")

            }

            Component {
                id: batteryFailsafeComponent

                SettingsGroupLayout {
                    Layout.fillWidth:       true
                    width: ScreenTools.defaultFontPixelWidth * 40
                    heading:                title

                    Image {
                        Layout.alignment:       Qt.AlignHCenter
                        height:                 ScreenTools.defaultFontPixelHeight * 4
                        //width:              ScreenTools.defaultFontPixelWidth * 12
                        sourceSize.width:       width
                        mipmap:                 true
                        fillMode:               Image.PreserveAspectFit
                        source:                 qgcPal.globalTheme === QGCPalette.Light ? "/qmlimages/LowBatteryLight.svg" : "/qmlimages/LowBattery.svg"
                    }

                    LabelledFactTextField {
                        Layout.fillWidth:       true
                        label:                  qsTr("Low voltage threshold")
                        fact:                   failsafeBattLowVoltage
                        textFieldPreferredWidth: _textFieldPreferredWidth
                        textFieldShowUnits:     true
                    }
                    LabelledFactComboBox {
                        label:                  qsTr("Low action")
                        fact:                   failsafeBattLowAct
                        indexModel:             false
                        comboBoxPreferredWidth: _comboBoxPreferredWidth
                    }
                    LabelledFactTextField {
                        Layout.fillWidth:       true
                        label:                  qsTr("Critical voltage threshold")
                        fact:                   failsafeBattCritVoltage
                        textFieldPreferredWidth: _textFieldPreferredWidth
                        textFieldShowUnits:     true
                    }
                    LabelledFactComboBox {
                        label:                  qsTr("Critical action")
                        fact:                   failsafeBattCritAct
                        indexModel:             false
                        comboBoxPreferredWidth: _comboBoxPreferredWidth
                    }
                }
            }

            Component {
                id: restartRequiredComponent

                ColumnLayout {
                    spacing: ScreenTools.defaultFontPixelWidth

                    QGCLabel {
                        text: _restartRequired
                    }

                    QGCButton {
                        text:       qsTr("Reboot vehicle")
                        onClicked:  controller.vehicle.rebootVehicle()
                    }
                }
            }

            Loader {
                id:                 battery1FailsafeLoader
                width: ScreenTools.defaultFontPixelWidth * 40
                Layout.alignment:   Qt.AlignHCenter
                sourceComponent:    _batt1ParamsAvailable ? batteryFailsafeComponent : undefined

                property string title:                  _batt2MonitorEnabled ? qsTr("Battery1 Failsafe Triggers") : qsTr("Battery Failsafe Triggers")
                property Fact battMonitor:              _batt1Monitor
                property bool battParamsAvailable:      _batt1ParamsAvailable
                property Fact failsafeBattLowAct:       _failsafeBatt1LowAct
                property Fact failsafeBattCritAct:      _failsafeBatt1CritAct
                property Fact failsafeBattLowMah:       _failsafeBatt1LowMah
                property Fact failsafeBattCritMah:      _failsafeBatt1CritMah
                property Fact failsafeBattLowVoltage:   _failsafeBatt1LowVoltage
                property Fact failsafeBattCritVoltage:  _failsafeBatt1CritVoltage
            }

            Loader {
                id:                 battery2FailsafeLoader
                width: ScreenTools.defaultFontPixelWidth * 40
                Layout.alignment:   Qt.AlignHCenter
                sourceComponent:    _batt2ParamsAvailable ? batteryFailsafeComponent : undefined

                property string title:                  qsTr("Battery2 Failsafe Triggers")
                property Fact battMonitor:              _batt2Monitor
                property bool battParamsAvailable:      _batt2ParamsAvailable
                property Fact failsafeBattLowAct:       _failsafeBatt2LowAct
                property Fact failsafeBattCritAct:      _failsafeBatt2CritAct
                property Fact failsafeBattLowMah:       _failsafeBatt2LowMah
                property Fact failsafeBattCritMah:      _failsafeBatt2CritMah
                property Fact failsafeBattLowVoltage:   _failsafeBatt2LowVoltage
                property Fact failsafeBattCritVoltage:  _failsafeBatt2CritVoltage
            }

            Component {
                id: copterGeoFence

                SettingsGroupLayout {
                    Layout.fillWidth:   true
                    //Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 40
                    width: ScreenTools.defaultFontPixelWidth * 40
                    heading:            qsTr("GeoFence")

                    Image {
                        Layout.alignment:   Qt.AlignHCenter
                        height:             ScreenTools.defaultFontPixelHeight * 4
                        //width:              ScreenTools.defaultFontPixelWidth * 20
                        sourceSize.width:   width
                        mipmap:             true
                        fillMode:           Image.PreserveAspectFit
                        source:             qgcPal.globalTheme === QGCPalette.Light ? "/qmlimages/GeoFenceLight.svg" : "/qmlimages/GeoFence.svg"
                    }

                    FactCheckBoxSlider {
                        Layout.fillWidth:   true
                        text:               qsTr("Enabled")
                        fact:               _fenceEnable
                    }

                    RowLayout {
                        visible:            _fenceEnable.rawValue
                        Layout.fillWidth:   true
                        QGCLabel {
                            text:   qsTr("Altitude Geofence")
                            Layout.fillWidth: true
                        }
                        QGCCheckBoxSlider {
                            id:                 altitudeFenceChecker
                            Layout.alignment:   Qt.AlignRight
                            checked:    _fenceType.rawValue & _maxAltitudeFenceBitMask

                            onClicked: {
                                if (checked) {
                                    _fenceType.rawValue |= _maxAltitudeFenceBitMask
                                } else {
                                    _fenceType.value &= ~_maxAltitudeFenceBitMask
                                }
                            }
                        }
                    }

                    LabelledFactTextField {
                        visible:            altitudeFenceChecker.checked
                        Layout.fillWidth:   true
                        label:              qsTr("Maximum Altitude")
                        fact:               _fenceAltMax
                        textFieldShowUnits: true
                        textFieldPreferredWidth: _textFieldPreferredWidth
                    }

                    RowLayout {
                        visible:            _fenceEnable.rawValue
                        Layout.fillWidth:   true
                        QGCLabel {
                            text:   qsTr("Circle centered on Home")
                            Layout.fillWidth: true
                        }
                        QGCCheckBoxSlider {
                            id:                 circleFenceChecker
                            Layout.alignment:   Qt.AlignRight
                            checked:            _fenceType.rawValue & _circleFenceBitMask

                            onClicked: {
                                if (checked) {
                                    _fenceType.rawValue |= _circleFenceBitMask
                                } else {
                                    _fenceType.value &= ~_circleFenceBitMask
                                }
                            }
                        }
                    }

                    LabelledFactTextField {
                        visible:            circleFenceChecker.checked
                        Layout.fillWidth:   true
                        label:              qsTr("Maximum Radius")
                        fact:               _fenceRadius
                        textFieldShowUnits: true
                        textFieldPreferredWidth: _textFieldPreferredWidth
                    }

                    RowLayout {
                        visible:            _fenceEnable.rawValue
                        Layout.fillWidth:   true
                        QGCLabel {
                            text:   qsTr("Polygons Fence")
                            Layout.fillWidth: true
                        }
                        QGCCheckBoxSlider {
                            Layout.alignment:   Qt.AlignRight
                            checked:    _fenceType.rawValue & _polygonFenceBitMask

                            onClicked: {
                                if (checked) {
                                    _fenceType.rawValue |= _polygonFenceBitMask
                                } else {
                                    _fenceType.value &= ~_polygonFenceBitMask
                                }
                            }
                        }
                    }

                    LabelledFactComboBox {
                        visible:            _fenceEnable.rawValue
                        label:              qsTr("Breach action")
                        fact:               _fenceAction
                        indexModel:         false
                        comboBoxPreferredWidth: _comboBoxPreferredWidth
                    }

                    LabelledFactTextField {
                        visible:            _fenceEnable.rawValue
                        Layout.fillWidth:   true
                        label:              qsTr("Fence margin")
                        fact:               _fenceMargin
                        textFieldShowUnits: true
                        textFieldPreferredWidth: _textFieldPreferredWidth
                    }
                }
            }

            Loader {
                id:                 copterGeoFenceLoader
                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 40
                Layout.alignment:   Qt.AlignHCenter
                sourceComponent: controller.vehicle.multiRotor ? copterGeoFence : undefined

                property Fact _fenceAction: controller.getParameterFact(-1, "FENCE_ACTION")
                property Fact _fenceAltMax: controller.getParameterFact(-1, "FENCE_ALT_MAX")
                property Fact _fenceAltMin: controller.getParameterFact(-1, "FENCE_ALT_MIN")
                property Fact _fenceEnable: controller.getParameterFact(-1, "FENCE_ENABLE")
                property Fact _fenceMargin: controller.getParameterFact(-1, "FENCE_MARGIN")
                property Fact _fenceRadius: controller.getParameterFact(-1, "FENCE_RADIUS")
                property Fact _fenceType:   controller.getParameterFact(-1, "FENCE_TYPE")

                readonly property int _maxAltitudeFenceBitMask: 1
                readonly property int _circleFenceBitMask:      2
                readonly property int _polygonFenceBitMask:     4
            }


            Component {
                id: copterRTL

                SettingsGroupLayout {
                    Layout.fillWidth:       true
                    width: ScreenTools.defaultFontPixelWidth * 40
                    heading:                qsTr("Return to Launch")

                    QGCColoredImage {
                        Layout.alignment:   Qt.AlignHCenter
                        height:             ScreenTools.defaultFontPixelHeight * 4
                        width:              ScreenTools.defaultFontPixelWidth * 20
                        color:              ggcPal.text
                        sourceSize.width:   width
                        mipmap:             true
                        fillMode:           Image.PreserveAspectFit
                        source:             controller.vehicle.multiRotor ? "/qmlimages/ReturnToHomeAltitudeCopter.svg" : "/qmlimages/ReturnToHomeAltitude.svg"
                    }

                    LabelledFactTextField {
                        Layout.fillWidth:   true
                        label:              qsTr("Return at specified altitude")
                        fact:               _rtlAltFact
                        textFieldShowUnits: true
                        textFieldPreferredWidth: _textFieldPreferredWidth
                    }

                    LabelledFactTextField {
                        Layout.fillWidth:   true
                        label:              qsTr("Loiter above Home for")
                        fact:               _rtlLoitTimeFact
                        textFieldShowUnits: true
                        textFieldPreferredWidth: _textFieldPreferredWidth
                    }
                }
            }

            Loader {
                id:                 copterRTLLoader
                width: ScreenTools.defaultFontPixelWidth * 40
                Layout.alignment:   Qt.AlignHCenter
                sourceComponent: controller.vehicle.multiRotor ? copterRTL : undefined

                property Fact _rtlAltFact:      controller.getParameterFact(-1, "RTL_ALT")
                property Fact _rtlLoitTimeFact: controller.getParameterFact(-1, "RTL_LOIT_TIME")
            }

            Component {
                id: copterLand

                SettingsGroupLayout {
                    Layout.fillWidth:       true
                    width: ScreenTools.defaultFontPixelWidth * 40
                    heading:                qsTr("Land Mode Settings")

                    QGCColoredImage {
                        Layout.alignment:   Qt.AlignHCenter
                        height:             ScreenTools.defaultFontPixelHeight * 4
                        width:              ScreenTools.defaultFontPixelWidth * 20
                        color:              ggcPal.text
                        sourceSize.width:   width
                        mipmap:             true
                        fillMode:           Image.PreserveAspectFit
                        source:             controller.vehicle.multiRotor ? "/qmlimages/LandModeCopter.svg" : "/qmlimages/LandMode.svg"
                    }
                    
                    LabelledFactTextField {
                        Layout.fillWidth:   true
                        label:              qsTr("Land stage altitude")
                        fact:               _landAltLow
                        textFieldShowUnits: true
                        textFieldPreferredWidth: _textFieldPreferredWidth
                    }

                    LabelledFactTextField {
                        Layout.fillWidth:   true
                        label:              qsTr("Land stage descent speed")
                        fact:               _landSpeedFact
                        textFieldShowUnits: true
                        textFieldPreferredWidth: _textFieldPreferredWidth
                    }
                }
            }

            Loader {
                id:                 copterLandLoader
                width: ScreenTools.defaultFontPixelWidth * 40
                Layout.alignment:   Qt.AlignHCenter
                sourceComponent: controller.vehicle.multiRotor ? copterLand : undefined

                property Fact _landSpeedFact:   controller.getParameterFact(-1, "LAND_SPEED")
                property Fact _landAltLow:      controller.getParameterFact(-1, "LAND_ALT_LOW")
            }
        }

        //     Component {
        //         id: planeGeneralFS

        //         Column {
        //             spacing: _margins / 2

        //             property Fact _failsafeThrEnable:   controller.getParameterFact(-1, "THR_FAILSAFE")
        //             property Fact _failsafeThrValue:    controller.getParameterFact(-1, "THR_FS_VALUE")
        //             property Fact _failsafeGCSEnable:   controller.getParameterFact(-1, "FS_GCS_ENABL")

        //             QGCLabel {
        //                 text:       qsTr("Failsafe Triggers")
        //                 font.family: ScreenTools.demiboldFontFamily
        //             }

        //             Rectangle {
        //                 width:  fsColumn.x + fsColumn.width + _margins
        //                 height: fsColumn.y + fsColumn.height + _margins
        //                 color:  qgcPal.windowShade
        //                 radius: ScreenTools.defaultFontPixelHeight * 0.25

        //                 ColumnLayout {
        //                     id:                 fsColumn
        //                     anchors.margins:    _margins
        //                     anchors.left:       parent.left
        //                     anchors.top:        parent.top

        //                     RowLayout {
        //                         QGCCheckBox {
        //                             id:                 throttleEnableCheckBox
        //                             text:               qsTr("Throttle PWM threshold:")
        //                             checked:            _failsafeThrEnable.value === 1

        //                             onClicked: _failsafeThrEnable.value = (checked ? 1 : 0)
        //                         }

        //                         FactTextField {
        //                             fact:               _failsafeThrValue
        //                             showUnits:          true
        //                             enabled:            throttleEnableCheckBox.checked
        //                         }
        //                     }

        //                     QGCCheckBox {
        //                         text:       qsTr("GCS failsafe")
        //                         checked:    _failsafeGCSEnable.value != 0
        //                         onClicked:  _failsafeGCSEnable.value = checked ? 1 : 0
        //                     }
        //                 }
        //             } // Rectangle - Failsafe trigger settings
        //         } // Column - Failsafe trigger settings
        //     }

        //     Loader {
        //         sourceComponent: controller.vehicle.fixedWing ? planeGeneralFS : undefined
        //     }

        //     Component {
        //         id: roverGeneralFS

        //         Column {
        //             spacing: _margins / 2

        //             property Fact _failsafeGCSEnable:   controller.getParameterFact(-1, "FS_GCS_ENABLE")
        //             property Fact _failsafeThrEnable:   controller.getParameterFact(-1, "FS_THR_ENABLE")
        //             property Fact _failsafeThrValue:    controller.getParameterFact(-1, "FS_THR_VALUE")
        //             property Fact _failsafeAction:      controller.getParameterFact(-1, "FS_ACTION")
        //             property Fact _failsafeCrashCheck:  controller.getParameterFact(-1, "FS_CRASH_CHECK")

        //             QGCLabel {
        //                 id:         failsafeLabel
        //                 text:       qsTr("Failsafe Triggers")
        //                 font.family: ScreenTools.demiboldFontFamily
        //             }

        //             Rectangle {
        //                 id:     failsafeSettings
        //                 width:  fsGrid.x + fsGrid.width + _margins
        //                 height: fsGrid.y + fsGrid.height + _margins
        //                 color:  ggcPal.windowShade
        //                 radius: ScreenTools.defaultFontPixelHeight * 0.25

        //                 GridLayout {
        //                     id:                 fsGrid
        //                     anchors.margins:    _margins
        //                     anchors.left:       parent.left
        //                     anchors.top:        parent.top
        //                     columns:            2

        //                     QGCLabel { text: qsTr("Ground Station failsafe:") }
        //                     FactComboBox {
        //                         Layout.fillWidth:   true
        //                         fact:               _failsafeGCSEnable
        //                         indexModel:         false
        //                     }

        //                     QGCLabel { text: qsTr("Throttle failsafe:") }
        //                     FactComboBox {
        //                         Layout.fillWidth:   true
        //                         fact:               _failsafeThrEnable
        //                         indexModel:         false
        //                     }

        //                     QGCLabel { text: qsTr("PWM threshold:") }
        //                     FactTextField {
        //                         Layout.fillWidth:   true
        //                         fact:               _failsafeThrValue
        //                     }

        //                     QGCLabel { text: qsTr("Failsafe Crash Check:") }
        //                     FactComboBox {
        //                         Layout.fillWidth:   true
        //                         fact:               _failsafeCrashCheck
        //                         indexModel:         false
        //                     }
        //                 }
        //             } // Rectangle - Failsafe Settings
        //         } // Column - Failsafe Settings
        //     }

        //     Loader {
        //         sourceComponent: _roverFirmware ? roverGeneralFS : undefined
        //     }



        //     Component {
        //         id: planeRTL

        //         Column {
        //             spacing: _margins / 2

        //             property Fact _rtlAltFact: controller.getParameterFact(-1, "ALT_HOLD_RTL")

        //             QGCLabel {
        //                 text:           qsTr("Return to Launch")
        //                 font.family:    ScreenTools.demiboldFontFamily
        //             }

        //             Rectangle {
        //                 width:  rltAltField.x + rltAltField.width + _margins
        //                 height: rltAltField.y + rltAltField.height + _margins
        //                 color:  qgcPal.windowShade
        //                 radius: ScreenTools.defaultFontPixelHeight * 0.25

        //                 QGCRadioButton {
        //                     id:                 returnAtCurrentRadio
        //                     anchors.margins:    _margins
        //                     anchors.left:       parent.left
        //                     anchors.top:        parent.top
        //                     text:               qsTr("Return at current altitude")
        //                     checked:            _rtlAltFact.value < 0

        //                     onClicked: _rtlAltFact.value = -1
        //                 }

        //                 QGCRadioButton {
        //                     id:                 returnAltRadio
        //                     anchors.topMargin:  _margins / 2
        //                     anchors.left:       returnAtCurrentRadio.left
        //                     anchors.top:        returnAtCurrentRadio.bottom
        //                     text:               qsTr("Return at specified altitude:")
        //                     checked:            _rtlAltFact.value >= 0

        //                     onClicked: _rtlAltFact.value = 10000
        //                 }

        //                 FactTextField {
        //                     id:                 rltAltField
        //                     anchors.leftMargin: _margins
        //                     anchors.left:       returnAltRadio.right
        //                     anchors.baseline:   returnAltRadio.baseline
        //                     fact:               _rtlAltFact
        //                     showUnits:          true
        //                     enabled:            returnAltRadio.checked
        //                 }
        //             } // Rectangle - RTL Settings
        //         } // Column - RTL Settings
        //     }

        //     Loader {
        //         sourceComponent: controller.vehicle.fixedWing ? planeRTL : undefined
        //     }

    } // Component - safetyPageComponent
} // SetupView
