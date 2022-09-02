#include "GeneratorStatusFactGroup.h"
#include "Vehicle.h"

#include <QtMath>

const char* GeneratorStatusFactGroup::_statusFactName =                 "status";
const char* GeneratorStatusFactGroup::_batteryCurrentFactName =         "batteryCurrent";
const char* GeneratorStatusFactGroup::_loadCurrentFactName =            "loadCurrent";
const char* GeneratorStatusFactGroup::_powerGeneratedFactName =         "powerGenerated";
const char* GeneratorStatusFactGroup::_busVoltageFactName =             "busVoltage";
const char* GeneratorStatusFactGroup::_batCurrentSetpointFactName =     "batCurrentSetpoint";
const char* GeneratorStatusFactGroup::_runtimeFactName =                "runtime";
const char* GeneratorStatusFactGroup::_timeUntilMaintenanceFactName =   "timeUntilMaintenance";
const char* GeneratorStatusFactGroup::_generatorSpeedFactName =         "generatorSpeed";
const char* GeneratorStatusFactGroup::_rectifierTemperatureFactName =   "rectifierTemperature";
const char* GeneratorStatusFactGroup::_generatorTemperatureFactName =   "generatorTemperature";

struct sensor_data32_Payload {
    float logCountRaw;
    float temperatureRaw;
    float humidityRaw;
    float pressureRaw;
    float windDirRaw;
    float windSpdRaw;
    int16_t extValue1Raw;
    int16_t extValue2Raw;
    int16_t extValue3Raw;
    int16_t extValue4Raw;
};

GeneratorStatusFactGroup::GeneratorStatusFactGroup(QObject* parent)
    : FactGroup(1000, ":/json/Vehicle/GeneratorStatusFactGroup.json", parent)
    , _statusFact               (0, _statusFactName,                FactMetaData::valueTypeUint64)
    , _batteryCurrentFact       (0, _batteryCurrentFactName,        FactMetaData::valueTypeFloat)
    , _loadCurrentFact          (0, _loadCurrentFactName,           FactMetaData::valueTypeFloat)
    , _powerGeneratedFact       (0, _powerGeneratedFactName,        FactMetaData::valueTypeFloat)
    , _busVoltageFact           (0, _busVoltageFactName,            FactMetaData::valueTypeFloat)
    , _batCurrentSetpointFact   (0, _batCurrentSetpointFactName,    FactMetaData::valueTypeFloat)
    , _runtimeFact              (0, _runtimeFactName,               FactMetaData::valueTypeUint32)
    , _timeUntilMaintenanceFact (0, _timeUntilMaintenanceFactName,  FactMetaData::valueTypeInt32)
    , _generatorSpeedFact       (0, _generatorSpeedFactName,        FactMetaData::valueTypeUint16)
    , _rectifierTemperatureFact (0, _rectifierTemperatureFactName,  FactMetaData::valueTypeInt16)
    , _generatorTemperatureFact (0, _generatorTemperatureFactName,  FactMetaData::valueTypeInt16)
{
    _addFact(&_statusFact,              _statusFactName);
    _addFact(&_batteryCurrentFact,      _batteryCurrentFactName);
    _addFact(&_loadCurrentFact,         _loadCurrentFactName);
    _addFact(&_powerGeneratedFact,      _powerGeneratedFactName);
    _addFact(&_busVoltageFact,          _busVoltageFactName);
    _addFact(&_batCurrentSetpointFact,  _batCurrentSetpointFactName);
    _addFact(&_runtimeFact,             _runtimeFactName);
    _addFact(&_timeUntilMaintenanceFact,_timeUntilMaintenanceFactName);
    _addFact(&_generatorSpeedFact,      _generatorSpeedFactName);
    _addFact(&_rectifierTemperatureFact,_rectifierTemperatureFactName);
    _addFact(&_generatorTemperatureFact,_generatorTemperatureFactName);

    // Start out as not available "--.--"
    _batteryCurrentFact.setRawValue         (qQNaN());
    _loadCurrentFact.setRawValue            (qQNaN());
    _powerGeneratedFact.setRawValue         (qQNaN());
    _busVoltageFact.setRawValue             (qQNaN());
    _batCurrentSetpointFact.setRawValue     (qQNaN());
    _runtimeFact.setRawValue                (qQNaN());
    _timeUntilMaintenanceFact.setRawValue   (qQNaN());
    _generatorSpeedFact.setRawValue         (qQNaN());
    _rectifierTemperatureFact.setRawValue   (qQNaN());
    _generatorTemperatureFact.setRawValue   (qQNaN());
}

void GeneratorStatusFactGroup::handleMessage(Vehicle* vehicle, mavlink_message_t& message)
{
    switch (message.msgid) {
    case MAVLINK_MSG_ID_GENERATOR_STATUS:
         _handleGeneratorStatus(message);
        break;
    default:
        break;
    }
}

void GeneratorStatusFactGroup::_handleGeneratorStatus(mavlink_message_t &message)
{
    mavlink_generator_status_t generator;
    mavlink_msg_generator_status_decode(&message, &generator);

    status()->setRawValue(generator.status);
    batteryCurrent()->setRawValue(generator.battery_current);
    loadCurrent()->setRawValue(generator.load_current);
    powerGenerated()->setRawValue(generator.power_generated);
    busVoltage()->setRawValue(generator.bus_voltage);
    batCurrentSetpoint()->setRawValue(generator.bat_current_setpoint);
    runtime()->setRawValue(generator.runtime);
    timeUntilMaintenance()->setRawValue(generator.time_until_maintenance);
    generatorSpeed()->setRawValue(generator.generator_speed);
    rectifierTemperature()->setRawValue(generator.rectifier_temperature);
    generatorTemperature()->setRawValue(generator.generator_temperature);
}

