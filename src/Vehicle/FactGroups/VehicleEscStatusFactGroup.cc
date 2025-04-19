/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "VehicleEscStatusFactGroup.h"
#include "Vehicle.h"

VehicleEscStatusFactGroup::VehicleEscStatusFactGroup(QObject *parent)
    : FactGroup(1000, QStringLiteral(":/json/Vehicle/EscStatusFactGroup.json"), parent)
{
    _addFact(&_indexFact);

    _addFact(&_rpmFirstFact,                    _rpmFirstFactName);
    _addFact(&_rpmSecondFact,                   _rpmSecondFactName);
    _addFact(&_rpmThirdFact,                    _rpmThirdFactName);
    _addFact(&_rpmFourthFact,                   _rpmFourthFactName);
    _addFact(&_rpmFifthFact,                    _rpmFifthFactName);
    _addFact(&_rpmSixthFact,                    _rpmSixthFactName);
    _addFact(&_rpmSeventhFact,                  _rpmSeventhFactName);
    _addFact(&_rpmEighthFact,                   _rpmEighthFactName);

    _addFact(&_currentFirstFact,                _currentFirstFactName);
    _addFact(&_currentSecondFact,               _currentSecondFactName);
    _addFact(&_currentThirdFact,                _currentThirdFactName);
    _addFact(&_currentFourthFact,               _currentFourthFactName);
    _addFact(&_currentFifthFact,                _currentFifthFactName);
    _addFact(&_currentSixthFact,                _currentSixthFactName);
    _addFact(&_currentSeventhFact,              _currentSeventhFactName);
    _addFact(&_currentEighthFact,               _currentEighthFactName);

    _addFact(&_voltageFirstFact,                _voltageFirstFactName);
    _addFact(&_voltageSecondFact,               _voltageSecondFactName);
    _addFact(&_voltageThirdFact,                _voltageThirdFactName);
    _addFact(&_voltageFourthFact,               _voltageFourthFactName);
    _addFact(&_voltageFifthFact,                _voltageFifthFactName);
    _addFact(&_voltageSixthFact,                _voltageSixthFactName);
    _addFact(&_voltageSeventhFact,              _voltageSeventhFactName);
    _addFact(&_voltageEighthFact,               _voltageEighthFactName);

    _addFact(&_temperatureFirstFact,            _temperatureFirstFactName);
    _addFact(&_temperatureSecondFact,           _temperatureSecondFactName);
    _addFact(&_temperatureThirdFact,            _temperatureThirdFactName);
    _addFact(&_temperatureFourthFact,           _temperatureFourthFactName);
    _addFact(&_temperatureFifthFact,            _temperatureFifthFactName);
    _addFact(&_temperatureSixthFact,            _temperatureSixthFactName);
    _addFact(&_temperatureSeventhFact,          _temperatureSeventhFactName);
    _addFact(&_temperatureEighthFact,           _temperatureEighthFactName);
}

void VehicleEscStatusFactGroup::handleMessage(Vehicle*, mavlink_message_t& message)
{
    switch ( message.msgid) {
    case MAVLINK_MSG_ID_ESC_STATUS:
        _handleEscStatus(message);
        break;
    case MAVLINK_MSG_ID_ESC_TELEMETRY_1_TO_4:
        _handleEscTelemetry1to4(message);
        break;
    case MAVLINK_MSG_ID_ESC_TELEMETRY_5_TO_8:
        _handleEscTelemetry5to8(message);
        break;
    default:
        break;
    }
}

void VehicleEscStatusFactGroup::_handleEscStatus(mavlink_message_t &message)
{
    mavlink_esc_status_t content{};
    mavlink_msg_esc_status_decode(&message, &content);

    index()->setRawValue(content.index);

    rpmFirst()->setRawValue(content.rpm[0]);
    rpmSecond()->setRawValue(content.rpm[1]);
    rpmThird()->setRawValue(content.rpm[2]);
    rpmFourth()->setRawValue(content.rpm[3]);

    currentFirst()->setRawValue(content.current[0]);
    currentSecond()->setRawValue(content.current[1]);
    currentThird()->setRawValue(content.current[2]);
    currentFourth()->setRawValue(content.current[3]);

    voltageFirst()->setRawValue(content.voltage[0]);
    voltageSecond()->setRawValue(content.voltage[1]);
    voltageThird()->setRawValue(content.voltage[2]);
    voltageFourth()->setRawValue(content.voltage[3]);

    _setTelemetryAvailable(true);
}

void VehicleEscStatusFactGroup::_handleEscTelemetry1to4(mavlink_message_t &message)
{
    mavlink_esc_telemetry_1_to_4_t esc4;
    mavlink_msg_esc_telemetry_1_to_4_decode(&message, &esc4);

    rpmFirst()->setRawValue                     (esc4.rpm[0]);
    rpmSecond()->setRawValue                    (esc4.rpm[1]);
    rpmThird()->setRawValue                     (esc4.rpm[2]);
    rpmFourth()->setRawValue                    (esc4.rpm[3]);

    currentFirst()->setRawValue                 (esc4.current[0] * 0.01);
    currentSecond()->setRawValue                (esc4.current[1] * 0.01);
    currentThird()->setRawValue                 (esc4.current[2] * 0.01);
    currentFourth()->setRawValue                (esc4.current[3] * 0.01);

    voltageFirst()->setRawValue                 (esc4.voltage[0] * 0.01);
    voltageSecond()->setRawValue                (esc4.voltage[1] * 0.01);
    voltageThird()->setRawValue                 (esc4.voltage[2] * 0.01);
    voltageFourth()->setRawValue                (esc4.voltage[3] * 0.01);

    temperatureFirst()->setRawValue             (esc4.temperature[0]);
    temperatureSecond()->setRawValue            (esc4.temperature[1]);
    temperatureThird()->setRawValue             (esc4.temperature[2]);
    temperatureFourth()->setRawValue            (esc4.temperature[3]);
}

void VehicleEscStatusFactGroup::_handleEscTelemetry5to8(mavlink_message_t &message)
{
    mavlink_esc_telemetry_5_to_8_t esc8;
    mavlink_msg_esc_telemetry_5_to_8_decode(&message, &esc8);

    rpmFifth()->setRawValue                     (esc8.rpm[0]);
    rpmSixth()->setRawValue                     (esc8.rpm[1]);
    rpmSeventh()->setRawValue                   (esc8.rpm[2]);
    rpmEighth()->setRawValue                    (esc8.rpm[3]);

    currentFifth()->setRawValue                 (esc8.current[0] * 0.01);
    currentSixth()->setRawValue                 (esc8.current[1] * 0.01);
    currentSeventh()->setRawValue               (esc8.current[2] * 0.01);
    currentEighth()->setRawValue                (esc8.current[3] * 0.01);

    voltageFifth()->setRawValue                 (esc8.voltage[0] * 0.01);
    voltageSixth()->setRawValue                 (esc8.voltage[1] * 0.01);
    voltageSeventh()->setRawValue               (esc8.voltage[2] * 0.01);
    voltageEighth()->setRawValue                (esc8.voltage[3] * 0.01);

    temperatureFifth()->setRawValue             (esc8.temperature[0]);
    temperatureSixth()->setRawValue             (esc8.temperature[1]);
    temperatureSeventh()->setRawValue           (esc8.temperature[2]);
    temperatureEighth()->setRawValue            (esc8.temperature[3]);
}
