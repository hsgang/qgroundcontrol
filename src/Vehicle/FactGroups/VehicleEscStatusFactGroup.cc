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

VehicleEscStatusFactGroup::VehicleEscStatusFactGroup(QObject* parent)
    : FactGroup                         (1000, ":/json/Vehicle/EscStatusFactGroup.json", parent)
    , _indexFact                        (0, _indexFactName,                         FactMetaData::valueTypeUint8)

    , _rpmFirstFact                     (0, _rpmFirstFactName,                      FactMetaData::valueTypeFloat)
    , _rpmSecondFact                    (0, _rpmSecondFactName,                     FactMetaData::valueTypeFloat)
    , _rpmThirdFact                     (0, _rpmThirdFactName,                      FactMetaData::valueTypeFloat)
    , _rpmFourthFact                    (0, _rpmFourthFactName,                     FactMetaData::valueTypeFloat)
    , _rpmFifthFact                     (0, _rpmFifthFactName,                      FactMetaData::valueTypeFloat)
    , _rpmSixthFact                     (0, _rpmSixthFactName,                      FactMetaData::valueTypeFloat)
    , _rpmSeventhFact                   (0, _rpmSeventhFactName,                    FactMetaData::valueTypeFloat)
    , _rpmEighthFact                    (0, _rpmEighthFactName,                     FactMetaData::valueTypeFloat)

    , _currentFirstFact                 (0, _currentFirstFactName,                  FactMetaData::valueTypeFloat)
    , _currentSecondFact                (0, _currentSecondFactName,                 FactMetaData::valueTypeFloat)
    , _currentThirdFact                 (0, _currentThirdFactName,                  FactMetaData::valueTypeFloat)
    , _currentFourthFact                (0, _currentFourthFactName,                 FactMetaData::valueTypeFloat)
    , _currentFifthFact                 (0, _currentFifthFactName,                  FactMetaData::valueTypeFloat)
    , _currentSixthFact                 (0, _currentSixthFactName,                  FactMetaData::valueTypeFloat)
    , _currentSeventhFact               (0, _currentSeventhFactName,                FactMetaData::valueTypeFloat)
    , _currentEighthFact                (0, _currentEighthFactName,                 FactMetaData::valueTypeFloat)

    , _voltageFirstFact                 (0, _voltageFirstFactName,                  FactMetaData::valueTypeFloat)
    , _voltageSecondFact                (0, _voltageSecondFactName,                 FactMetaData::valueTypeFloat)
    , _voltageThirdFact                 (0, _voltageThirdFactName,                  FactMetaData::valueTypeFloat)
    , _voltageFourthFact                (0, _voltageFourthFactName,                 FactMetaData::valueTypeFloat)
    , _voltageFifthFact                 (0, _voltageFifthFactName,                  FactMetaData::valueTypeFloat)
    , _voltageSixthFact                 (0, _voltageSixthFactName,                  FactMetaData::valueTypeFloat)
    , _voltageSeventhFact               (0, _voltageSeventhFactName,                FactMetaData::valueTypeFloat)
    , _voltageEighthFact                (0, _voltageEighthFactName,                 FactMetaData::valueTypeFloat)

    , _temperatureFirstFact             (0, _temperatureFirstFactName,              FactMetaData::valueTypeUint8)
    , _temperatureSecondFact            (0, _temperatureSecondFactName,             FactMetaData::valueTypeUint8)
    , _temperatureThirdFact             (0, _temperatureThirdFactName,              FactMetaData::valueTypeUint8)
    , _temperatureFourthFact            (0, _temperatureFourthFactName,             FactMetaData::valueTypeUint8)
    , _temperatureFifthFact             (0, _temperatureFifthFactName,              FactMetaData::valueTypeUint8)
    , _temperatureSixthFact             (0, _temperatureSixthFactName,              FactMetaData::valueTypeUint8)
    , _temperatureSeventhFact           (0, _temperatureSeventhFactName,            FactMetaData::valueTypeUint8)
    , _temperatureEighthFact            (0, _temperatureEighthFactName,             FactMetaData::valueTypeUint8)
{
    _addFact(&_indexFact,                       _indexFactName);

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
    mavlink_esc_status_t esc;
    mavlink_msg_esc_status_decode(&message, &esc);

    index()->setRawValue                        (esc.index);

    rpmFirst()->setRawValue                     (esc.rpm[0]);
    rpmSecond()->setRawValue                    (esc.rpm[1]);
    rpmThird()->setRawValue                     (esc.rpm[2]);
    rpmFourth()->setRawValue                    (esc.rpm[3]);

    currentFirst()->setRawValue                 (esc.current[0]);
    currentSecond()->setRawValue                (esc.current[1]);
    currentThird()->setRawValue                 (esc.current[2]);
    currentFourth()->setRawValue                (esc.current[3]);

    voltageFirst()->setRawValue                 (esc.voltage[0]);
    voltageSecond()->setRawValue                (esc.voltage[1]);
    voltageThird()->setRawValue                 (esc.voltage[2]);
    voltageFourth()->setRawValue                (esc.voltage[3]);
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
