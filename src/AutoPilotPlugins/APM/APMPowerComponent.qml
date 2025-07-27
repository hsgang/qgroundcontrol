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
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl

import QGroundControl.FactControls

import QGroundControl.Controls
import QGroundControl.ScreenTools

SetupPage {
    id:             powerPage
    pageComponent:  powerPageComponent

    property real   _margins:                   ScreenTools.defaultFontPixelHeight
    property real _comboBoxPreferredWidth:  ScreenTools.defaultFontPixelWidth * 20
    property real _textFieldPreferredWidth: ScreenTools.defaultFontPixelWidth * 20

    Component {
        id: powerPageComponent

        Flow {
            id:         flowLayout
            width:      availableWidth
            spacing:     _margins / 2

        // ColumnLayout {
        //     width:      availableWidth
        //     spacing:    _margins

            FactPanelController { id: controller }
            QGCPalette { id: ggcPal; colorGroupEnabled: true }

            property Fact _batt1Monitor:            controller.getParameterFact(-1, "BATT_MONITOR")
            property Fact _batt2Monitor:            controller.getParameterFact(-1, "BATT2_MONITOR", false /* reportMissing */)
            property bool _batt2MonitorAvailable:   controller.parameterExists(-1, "BATT2_MONITOR")
            property bool _batt1MonitorEnabled:     _batt1Monitor.rawValue !== 0
            property bool _batt2MonitorEnabled:     _batt2MonitorAvailable && _batt2Monitor.rawValue !== 0
            property bool _batt1ParamsAvailable:    controller.parameterExists(-1, "BATT_CAPACITY")
            property bool _batt2ParamsAvailable:    controller.parameterExists(-1, "BATT2_CAPACITY")
            property bool _showBatt1Reboot:         _batt1MonitorEnabled && !_batt1ParamsAvailable
            property bool _showBatt2Reboot:         _batt2MonitorEnabled && !_batt2ParamsAvailable
            property bool _escCalibrationAvailable: controller.parameterExists(-1, "ESC_CALIBRATION")
            property Fact _escCalibration:          controller.getParameterFact(-1, "ESC_CALIBRATION", false /* reportMissing */)

            property string _restartRequired: qsTr("Requires vehicle reboot")

            Component {
                id: batteryComponent

                SettingsGroupLayout {
                    Layout.fillWidth:   true
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 40
                    heading:            title

                    property bool _showAdvanced:    sensorCombo.currentIndex === sensorModel.count - 1

                    Component.onCompleted: calcSensor()

                    function calcSensor() {
                        for (var i=0; i<sensorModel.count - 1; i++) {
                            if (sensorModel.get(i).voltPin === battVoltPin.value &&
                                    sensorModel.get(i).currPin === battCurrPin.value &&
                                    Math.abs(sensorModel.get(i).voltMult - battVoltMult.value) < 0.001 &&
                                    Math.abs(sensorModel.get(i).ampPerVolt - battAmpPerVolt.value) < 0.0001 &&
                                    Math.abs(sensorModel.get(i).ampOffset - battAmpOffset.value) < 0.0001) {
                                sensorCombo.currentIndex = i
                                return
                            }
                        }
                        sensorCombo.currentIndex = sensorModel.count - 1
                    }

                    ListModel {
                        id: sensorModel

                        ListElement {
                            text:       qsTr("Power Module 90A")
                            voltPin:    2
                            currPin:    3
                            voltMult:   10.1
                            ampPerVolt: 17.0
                            ampOffset:  0
                        }

                        ListElement {
                            text:       qsTr("Power Module HV")
                            voltPin:    2
                            currPin:    3
                            voltMult:   12.02
                            ampPerVolt: 39.877
                            ampOffset:  0
                        }

                        ListElement {
                            text:       qsTr("Custom")
                        }
                    }

                    LabelledFactComboBox {
                        label:              qsTr("Battery monitor")
                        fact:               battMonitor
                        indexModel:         false
                        comboBoxPreferredWidth: _comboBoxPreferredWidth
                    }
                    LabelledFactTextField {
                        Layout.fillWidth:   true
                        label:              qsTr("Battery capacity")
                        fact:               battCapacity
                        textFieldPreferredWidth: _textFieldPreferredWidth
                        textFieldShowUnits: true
                    }
                    LabelledFactTextField {
                        Layout.fillWidth:   true
                        label:              qsTr("Minimum arming voltage")
                        fact:               armVoltMin
                        textFieldPreferredWidth: _textFieldPreferredWidth
                        textFieldShowUnits: true
                    }

                    RowLayout {
                        Layout.fillWidth:   true

                        QGCLabel {
                            text:           qsTr("Sensor preset")
                            Layout.fillWidth: true
                        }

                        QGCComboBox {
                            id:                     sensorCombo
                            Layout.minimumWidth:    _comboBoxPreferredWidth
                            model:                  sensorModel
                            textRole:               "text"

                            onActivated: (index) => {
                                if (index < sensorModel.count - 1) {
                                    battVoltPin.value = sensorModel.get(index).voltPin
                                    battCurrPin.value = sensorModel.get(index).currPin
                                    battVoltMult.value = sensorModel.get(index).voltMult
                                    battAmpPerVolt.value = sensorModel.get(index).ampPerVolt
                                    battAmpOffset.value = sensorModel.get(index).ampOffset
                                } else {

                                }
                            }
                        }
                    }

                    LabelledFactComboBox {
                        visible:            _showAdvanced
                        label:              qsTr("Current pin")
                        fact:               battCurrPin
                        indexModel:         false
                        comboBoxPreferredWidth: _comboBoxPreferredWidth
                    }
                    LabelledFactComboBox {
                        visible:            _showAdvanced
                        label:              qsTr("Voltage pin")
                        fact:               battVoltPin
                        indexModel:         false
                        comboBoxPreferredWidth: _comboBoxPreferredWidth
                    }
                    RowLayout {
                        visible:            _showAdvanced
                        Layout.fillWidth:       true
                        LabelledFactTextField {
                            Layout.fillWidth:   true
                            label:              qsTr("Voltage multiplier")
                            fact:               battVoltMult
                            textFieldPreferredWidth: _textFieldPreferredWidth * 0.6
                        }
                        QGCButton {
                            text:       qsTr("Calculate")
                            onClicked:  calcVoltageMultiplierDlgComponent.createObject(mainWindow, { vehicleVoltageFact: vehicleVoltage, battVoltMultFact: battVoltMult }).open()
                        }
                    }
                    RowLayout{
                        visible:            _showAdvanced
                        Layout.fillWidth:       true
                        LabelledFactTextField {
                            Layout.fillWidth:   true
                            label:              qsTr("Amps per volt")
                            fact:               battAmpPerVolt
                            textFieldPreferredWidth: _textFieldPreferredWidth * 0.6
                        }
                        QGCButton {
                            text:       qsTr("Calculate")
                            onClicked:  calcAmpsPerVoltDlgComponent.createObject(mainWindow, { vehicleCurrentFact: vehicleCurrent, battAmpPerVoltFact: battAmpPerVolt }).open()
                        }
                    }
                    LabelledFactTextField {
                        visible:            _showAdvanced
                        Layout.fillWidth:   true
                        label:              qsTr("Amps Offset")
                        fact:               battAmpOffset
                        textFieldPreferredWidth: _textFieldPreferredWidth
                    }
                }
            }

            Component{
                id: battery1Monitor
                SettingsGroupLayout {
                    Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 50
                    Layout.alignment:       Qt.AlignHCenter
                    visible:                !_batt1MonitorEnabled || !_batt1ParamsAvailable
                    heading:                qsTr("Power Sensor 1")

                    LabelledFactComboBox {
                        label:              qsTr("Battery1 monitor")
                        fact:               _batt1Monitor
                        indexModel:         false
                        comboBoxPreferredWidth: _comboBoxPreferredWidth
                    }
                }
            }

            Loader {
                id:                     battery1MonitorLoader
                Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 50
                Layout.alignment:       Qt.AlignHCenter
                sourceComponent:        (!_batt1MonitorEnabled || !_batt1ParamsAvailable) ? battery1Monitor : undefined
            }

            Loader {
                id:                     battery1Loader
                Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 50
                Layout.alignment:       Qt.AlignHCenter
                sourceComponent:        (_batt1MonitorEnabled && _batt1ParamsAvailable) ? batteryComponent : undefined

                property string title:          qsTr("Power Sensor 1")
                property Fact armVoltMin:       controller.getParameterFact(-1, "r.BATT_ARM_VOLT", false /* reportMissing */)
                property Fact battAmpPerVolt:   controller.getParameterFact(-1, "r.BATT_AMP_PERVLT", false /* reportMissing */)
                property Fact battAmpOffset:    controller.getParameterFact(-1, "BATT_AMP_OFFSET", false /* reportMissing */)
                property Fact battCapacity:     controller.getParameterFact(-1, "BATT_CAPACITY", false /* reportMissing */)
                property Fact battCurrPin:      controller.getParameterFact(-1, "BATT_CURR_PIN", false /* reportMissing */)
                property Fact battMonitor:      controller.getParameterFact(-1, "BATT_MONITOR", false /* reportMissing */)
                property Fact battVoltMult:     controller.getParameterFact(-1, "BATT_VOLT_MULT", false /* reportMissing */)
                property Fact battVoltPin:      controller.getParameterFact(-1, "BATT_VOLT_PIN", false /* reportMissing */)
                property FactGroup  _batteryFactGroup:  _batt1MonitorEnabled && _batt1ParamsAvailable ? controller.vehicle.getFactGroup("battery0") : null
                property Fact vehicleVoltage:   _batteryFactGroup ? _batteryFactGroup.voltage : null
                property Fact vehicleCurrent:   _batteryFactGroup ? _batteryFactGroup.current : null
            }

            Component {
                id: battery2Monitor

                SettingsGroupLayout {
                    Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 50
                    Layout.alignment:       Qt.AlignHCenter
                    visible: !_batt2MonitorEnabled || !_batt2ParamsAvailable
                    heading:                qsTr("Power Sensor 2")

                    LabelledFactComboBox {
                        label:              qsTr("Battery2 monitor")
                        fact:               _batt2Monitor
                        indexModel:         false
                        comboBoxPreferredWidth: _comboBoxPreferredWidth
                    }
                }
            }

            Loader {
                id:                     battery2MonitorLoader
                Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 50
                Layout.alignment:       Qt.AlignHCenter
                sourceComponent:        (!_batt2MonitorEnabled || !_batt2ParamsAvailable) ? battery2Monitor : undefined
            }

            Loader {
                id:                     battery2Loader
                Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 50
                Layout.alignment:       Qt.AlignHCenter
                sourceComponent:        (_batt2MonitorEnabled && _batt2ParamsAvailable) ? batteryComponent : undefined

                property string title:          qsTr("Power Sensor 2")
                property Fact armVoltMin:       controller.getParameterFact(-1, "r.BATT2_ARM_VOLT", false /* reportMissing */)
                property Fact battAmpPerVolt:   controller.getParameterFact(-1, "r.BATT2_AMP_PERVLT", false /* reportMissing */)
                property Fact battAmpOffset:    controller.getParameterFact(-1, "BATT2_AMP_OFFSET", false /* reportMissing */)
                property Fact battCapacity:     controller.getParameterFact(-1, "BATT2_CAPACITY", false /* reportMissing */)
                property Fact battCurrPin:      controller.getParameterFact(-1, "BATT2_CURR_PIN", false /* reportMissing */)
                property Fact battMonitor:      controller.getParameterFact(-1, "BATT2_MONITOR", false /* reportMissing */)
                property Fact battVoltMult:     controller.getParameterFact(-1, "BATT2_VOLT_MULT", false /* reportMissing */)
                property Fact battVoltPin:      controller.getParameterFact(-1, "BATT2_VOLT_PIN", false /* reportMissing */)
                property FactGroup  _batteryFactGroup:  _batt2MonitorEnabled && _batt2ParamsAvailable ? controller.vehicle.getFactGroup("battery1") : null
                property Fact vehicleVoltage:   _batteryFactGroup ? _batteryFactGroup.voltage : null
                property Fact vehicleCurrent:   _batteryFactGroup ? _batteryFactGroup.current : null
            }
        }
    } // Component - powerPageComponent    

    Component {
        id: calcVoltageMultiplierDlgComponent

        QGCPopupDialog {
            title:      qsTr("Calculate Voltage Multiplier")
            buttons:    Dialog.Close

            property Fact vehicleVoltageFact
            property Fact battVoltMultFact

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight

                QGCLabel {
                    Layout.preferredWidth:  gridLayout.width
                    wrapMode:               Text.WordWrap
                    text:                   qsTr("Measure battery voltage using an external voltmeter and enter the value below. Click Calculate to set the new adjusted voltage multiplier.")
                }

                GridLayout {
                    id:         gridLayout
                    columns:    2

                    QGCLabel {
                        text: qsTr("Measured voltage:")
                    }
                    QGCTextField { id: measuredVoltage }

                    QGCLabel { text: qsTr("Vehicle voltage:") }
                    FactLabel { fact: vehicleVoltageFact }

                    QGCLabel { text: qsTr("Voltage multiplier:") }
                    FactLabel { fact: battVoltMultFact }
                }

                QGCButton {
                    text: qsTr("Calculate And Set")

                    onClicked:  {
                        var measuredVoltageValue = parseFloat(measuredVoltage.text)
                        if (measuredVoltageValue === 0 || isNaN(measuredVoltageValue) || !vehicleVoltageFact || !battVoltMultFact) {
                            return
                        }
                        var newVoltageMultiplier = (vehicleVoltageFact.value !== 0) ? (measuredVoltageValue * battVoltMultFact.value) / vehicleVoltageFact.value : 0
                        if (newVoltageMultiplier > 0) {
                            battVoltMultFact.value = newVoltageMultiplier
                        }
                    }
                }
            }
        }
    }

    Component {
        id: calcAmpsPerVoltDlgComponent

        QGCPopupDialog {
            title:      qsTr("Calculate Amps per Volt")
            buttons:    Dialog.Close

            property Fact vehicleCurrentFact
            property Fact battAmpPerVoltFact

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight

                QGCLabel {
                    Layout.preferredWidth:  gridLayout.width
                    wrapMode:               Text.WordWrap
                    text:                   qsTr("Measure current draw using an external current meter and enter the value below. Click Calculate to set the new amps per volt value.")
                }

                GridLayout {
                    id:         gridLayout
                    columns:    2

                    QGCLabel {
                        text: qsTr("Measured current:")
                    }
                    QGCTextField { id: measuredCurrent }

                    QGCLabel { text: qsTr("Vehicle current:") }
                    FactLabel { fact: vehicleCurrentFact }

                    QGCLabel { text: qsTr("Amps per volt:") }
                    FactLabel { fact: battAmpPerVoltFact }
                }

                QGCButton {
                    text: qsTr("Calculate And Set")

                    onClicked:  {
                        var measuredCurrentValue = parseFloat(measuredCurrent.text)
                        if (measuredCurrentValue === 0 || isNaN(measuredCurrentValue) || !vehicleCurrentFact || !battAmpPerVoltFact) {
                            return
                        }
                        var newAmpsPerVolt = (vehicleCurrentFact.value !== 0) ? (measuredCurrentValue * battAmpPerVoltFact.value) / vehicleCurrentFact.value : 0
                        if (newAmpsPerVolt !== 0) {
                            battAmpPerVoltFact.value = newAmpsPerVolt
                        }
                    }
                }
            }
        }
    }
} // SetupPage
