#include "GeneratorStatusFactGroup.h"
#include "Vehicle.h"

#include <QtMath>

GeneratorStatusFactGroup::GeneratorStatusFactGroup(QObject* parent)
    : FactGroup(1000, ":/json/Vehicle/GeneratorStatusFactGroup.json", parent)
{
    _addFact(&_statusFact);
    _addFact(&_batteryCurrentFact);
    _addFact(&_loadCurrentFact);
    _addFact(&_powerGeneratedFact);
    _addFact(&_busVoltageFact);
    _addFact(&_batCurrentSetpointFact);
    _addFact(&_runtimeFact);
    _addFact(&_timeUntilMaintenanceFact);
    _addFact(&_generatorSpeedFact);
    _addFact(&_rectifierTemperatureFact);
    _addFact(&_generatorTemperatureFact);

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

void GeneratorStatusFactGroup::handleMessage(Vehicle* vehicle, const mavlink_message_t& message)
{
    switch (message.msgid) {
    case MAVLINK_MSG_ID_GENERATOR_STATUS:
         _handleGeneratorStatus(message);
        break;
    default:
        break;
    }
}

void GeneratorStatusFactGroup::_handleGeneratorStatus(const mavlink_message_t &message)
{
    mavlink_generator_status_t generator;
    mavlink_msg_generator_status_decode(&message, &generator);

    QVariant generatorStatus = QVariant::fromValue(generator.status);

    //status()->setRawValue(generator.status);
    status()->setRawValue(generatorStatus);
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

