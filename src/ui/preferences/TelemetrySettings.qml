/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.3
import QtQuick.Controls         1.2
import QtQuick.Controls.Styles  1.4
import QtQuick.Layouts          1.2

import QGroundControl                       1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.FactControls          1.0
import QGroundControl.Controls              1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.Palette               1.0

SettingsPage {
    property var    _settingsManager:           QGroundControl.settingsManager
    property var    _appSettings:               _settingsManager.appSettings
    property bool   _disableAllDataPersistence: _appSettings.disableAllPersistence.rawValue
    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property string _notConnectedStr:           qsTr("Not Connected")
    property bool   _isAPM:                     _activeVehicle ? _activeVehicle.apmFirmware : true
    property bool   _showAPMStreamRates:        QGroundControl.apmFirmwareSupported && _settingsManager.apmMavlinkStreamRateSettings.visible && _isAPM
    property var    _apmStartMavlinkStreams:   _appSettings.apmStartMavlinkStreams
    property real   _comboBoxPreferredWidth:    ScreenTools.defaultFontPixelWidth * 8


    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Ground Station")

        RowLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth * 2

            QGCLabel {
                Layout.fillWidth:   true
                text:               qsTr("MAVLink System ID")
            }

            QGCTextField {
                text:               QGroundControl.mavlinkSystemID.toString()
                numericValuesOnly:  true
                onEditingFinished: {
                    console.log("text", text)
                    QGroundControl.mavlinkSystemID = parseInt(text)
                }
            }
        }

        QGCCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Emit heartbeat")
            checked:            QGroundControl.multiVehicleManager.gcsHeartBeatEnabled
            onClicked:          QGroundControl.multiVehicleManager.gcsHeartBeatEnabled = checked
        }

        QGCCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Only connect to vehicle with same MAVLink protocol version")
            checked:            QGroundControl.isVersionCheckEnabled
            onClicked:          QGroundControl.isVersionCheckEnabled = checked
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("MAVLink Forwarding")

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Enable")
            fact:               _appSettings.forwardMavlink
            visible:            fact.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    ScreenTools.defaultFontPixelWidth * 20
            label:                      qsTr("Host name")
            fact:                       _appSettings.forwardMavlinkHostName
            visible:                    fact.visible
            enabled:                    _appSettings.forwardMavlink.rawValue
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Logging")
        visible:            !_disableAllDataPersistence

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Save log after each flight")
            fact:               _telemetrySave
            visible:            fact.visible
            property Fact _telemetrySave: _appSettings.telemetrySave
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Save logs even if vehicle was not armed")
            fact:               _telemetrySaveNotArmed
            visible:            fact.visible
            enabled:            _appSettings.telemetrySave.rawValue
            property Fact _telemetrySaveNotArmed: _appSettings.telemetrySaveNotArmed
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Save CSV log of telemetry data")
            fact:               _saveCsvTelemetry
            visible:            fact.visible
            property Fact _saveCsvTelemetry: _appSettings.saveCsvTelemetry
        }
        FactCheckBoxSlider {
            id:                 sensorSaveLog
            Layout.fillWidth:   true
            text:               qsTr("Save SensorData JSON log")
            fact:               QGroundControl.settingsManager.appSettings.saveSensorLog
            enabled:            !_disableAllDataPersistence
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Stream Rates (ArduPilot Only)")
        visible:            _showAPMStreamRates

        QGCCheckBoxSlider {
            id:                 controllerByVehicleCheckBox
            Layout.fillWidth:   true
            text:               qsTr("Controlled by Vehicle")
            checked:            !_apmStartMavlinkStreams.rawValue
            onClicked:          _apmStartMavlinkStreams.rawValue = !checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Raw Sensors")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateRawSensors
            description:        "RAW_IMU, SCALED_IMU2, SCALED_IMU3,\n
SCALED_PRESSURE, SCALED_PRESSURE2, SCALED_PRESSURE3"
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
            comboBoxPreferredWidth: _comboBoxPreferredWidth
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Extended Status")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateExtendedStatus
            description:        "SYS_STATUS, POWER_STATUS, MCU_STATUS, MEMINFO,\n
GPS_RAW_INT, GPS_RTK, GPS2_RAW_INT, GPS2_RTK,\n
NAV_CONTROLLER_OUTPUT, FENCE_STATUS, CURRENT_WAYPOINT,\n
GLOBAL_TARGET_POS_INT"
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
            comboBoxPreferredWidth: _comboBoxPreferredWidth
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("RC Channels")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateRCChannels
            description:        "SERVO_OUTPUT_RAW, RC_CHANNELS"
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
            comboBoxPreferredWidth: _comboBoxPreferredWidth
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Position")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRatePosition
            description:        "GLOBAL_POSITION_INT, LOCAL_POSITION_NED"
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
            comboBoxPreferredWidth: _comboBoxPreferredWidth
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Extra 1")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra1
            description:        "ATTITUDE, AHRS2, PID_TUNING"
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
            comboBoxPreferredWidth: _comboBoxPreferredWidth
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Extra 2")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra2
            description:        "VFR_HUD"
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
            comboBoxPreferredWidth: _comboBoxPreferredWidth
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Extra 3")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra3
            description:
"AHRS, SYSTEM_TIME, WIND, RANGEFINDER, DISTANCE_SENSOR, \n
TERRAIN_REQUEST, BATTERY_STATUS, OPTICAL_FLOW, \n
GIMBAL_DEVICE_ATTITUDE_STATUS, MAG_CAL_REPORT, \n
MAG_CAL_PROGRESS, EKF_STATUS_REPORT, VIBRATION, \n
RPM, ESC TELEMETRY, GENERATOR_STATUS, WINCH_STATUS"
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
            comboBoxPreferredWidth: _comboBoxPreferredWidth
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Link Status (Current Vehicle)")

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Total messages sent (computed)")
            labelText:          _activeVehicle ? _activeVehicle.mavlinkSentCount : _notConnectedStr
        }

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Total messages received")
            labelText:          _activeVehicle ? _activeVehicle.mavlinkReceivedCount : _notConnectedStr
        }

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Total messages loss")
            labelText:          _activeVehicle ? _activeVehicle.mavlinkLossCount : _notConnectedStr
        }

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Loss rate")
            labelText:          _activeVehicle ? _activeVehicle.mavlinkLossPercent.toFixed(0) + '%' : _notConnectedStr
        }
    }
}
