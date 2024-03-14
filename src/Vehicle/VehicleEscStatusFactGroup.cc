/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "VehicleEscStatusFactGroup.h"
#include "Vehicle.h"

const char* VehicleEscStatusFactGroup::_indexFactName =                             "index";

const char* VehicleEscStatusFactGroup::_rpmFirstFactName =                          "rpm1";
const char* VehicleEscStatusFactGroup::_rpmSecondFactName =                         "rpm2";
const char* VehicleEscStatusFactGroup::_rpmThirdFactName =                          "rpm3";
const char* VehicleEscStatusFactGroup::_rpmFourthFactName =                         "rpm4";

const char* VehicleEscStatusFactGroup::_currentFirstFactName =                      "current1";
const char* VehicleEscStatusFactGroup::_currentSecondFactName =                     "current2";
const char* VehicleEscStatusFactGroup::_currentThirdFactName =                      "current3";
const char* VehicleEscStatusFactGroup::_currentFourthFactName =                     "current4";

const char* VehicleEscStatusFactGroup::_voltageFirstFactName =                      "voltage1";
const char* VehicleEscStatusFactGroup::_voltageSecondFactName =                     "voltage2";
const char* VehicleEscStatusFactGroup::_voltageThirdFactName =                      "voltage3";
const char* VehicleEscStatusFactGroup::_voltageFourthFactName =                     "voltage4";

const char* VehicleEscStatusFactGroup::_temperatureFirstFactName =                  "temperature1";
const char* VehicleEscStatusFactGroup::_temperatureSecondFactName =                 "temperature2";
const char* VehicleEscStatusFactGroup::_temperatureThirdFactName =                  "temperature3";
const char* VehicleEscStatusFactGroup::_temperatureFourthFactName =                 "temperature4";

VehicleEscStatusFactGroup::VehicleEscStatusFactGroup(QObject* parent)
    : FactGroup                         (1000, ":/json/Vehicle/EscStatusFactGroup.json", parent)
    , _indexFact                        (0, _indexFactName,                         FactMetaData::valueTypeUint8)

    , _rpmFirstFact                     (0, _rpmFirstFactName,                      FactMetaData::valueTypeFloat)
    , _rpmSecondFact                    (0, _rpmSecondFactName,                     FactMetaData::valueTypeFloat)
    , _rpmThirdFact                     (0, _rpmThirdFactName,                      FactMetaData::valueTypeFloat)
    , _rpmFourthFact                    (0, _rpmFourthFactName,                     FactMetaData::valueTypeFloat)

    , _currentFirstFact                 (0, _currentFirstFactName,                  FactMetaData::valueTypeFloat)
    , _currentSecondFact                (0, _currentSecondFactName,                 FactMetaData::valueTypeFloat)
    , _currentThirdFact                 (0, _currentThirdFactName,                  FactMetaData::valueTypeFloat)
    , _currentFourthFact                (0, _currentFourthFactName,                 FactMetaData::valueTypeFloat)

    , _voltageFirstFact                 (0, _voltageFirstFactName,                  FactMetaData::valueTypeFloat)
    , _voltageSecondFact                (0, _voltageSecondFactName,                 FactMetaData::valueTypeFloat)
    , _voltageThirdFact                 (0, _voltageThirdFactName,                  FactMetaData::valueTypeFloat)
    , _voltageFourthFact                (0, _voltageFourthFactName,                 FactMetaData::valueTypeFloat)

    , _temperatureFirstFact             (0, _temperatureFirstFactName,              FactMetaData::valueTypeUint8)
    , _temperatureSecondFact            (0, _temperatureSecondFactName,             FactMetaData::valueTypeUint8)
    , _temperatureThirdFact             (0, _temperatureThirdFactName,              FactMetaData::valueTypeUint8)
    , _temperatureFourthFact            (0, _temperatureFourthFactName,             FactMetaData::valueTypeUint8)
{
    _addFact(&_indexFact,                       _indexFactName);

    _addFact(&_rpmFirstFact,                    _rpmFirstFactName);
    _addFact(&_rpmSecondFact,                   _rpmSecondFactName);
    _addFact(&_rpmThirdFact,                    _rpmThirdFactName);
    _addFact(&_rpmFourthFact,                   _rpmFourthFactName);

    _addFact(&_currentFirstFact,                _currentFirstFactName);
    _addFact(&_currentSecondFact,               _currentSecondFactName);
    _addFact(&_currentThirdFact,                _currentThirdFactName);
    _addFact(&_currentFourthFact,               _currentFourthFactName);

    _addFact(&_voltageFirstFact,                _voltageFirstFactName);
    _addFact(&_voltageSecondFact,               _voltageSecondFactName);
    _addFact(&_voltageThirdFact,                _voltageThirdFactName);
    _addFact(&_voltageFourthFact,               _voltageFourthFactName);

    _addFact(&_temperatureFirstFact,            _temperatureFirstFactName);
    _addFact(&_temperatureSecondFact,           _temperatureSecondFactName);
    _addFact(&_temperatureThirdFact,            _temperatureThirdFactName);
    _addFact(&_temperatureFourthFact,           _temperatureFourthFactName);
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


