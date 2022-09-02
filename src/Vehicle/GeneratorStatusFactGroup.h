#pragma once

#include "FactGroup.h"
#include "QGCMAVLink.h"

class GeneratorStatusFactGroup : public FactGroup
{
    Q_OBJECT

public:
    GeneratorStatusFactGroup(QObject* parent = nullptr);

    Q_PROPERTY(Fact* status                 READ status                CONSTANT)
    Q_PROPERTY(Fact* batteryCurrent         READ batteryCurrent        CONSTANT)
    Q_PROPERTY(Fact* loadCurrent            READ loadCurrent           CONSTANT)
    Q_PROPERTY(Fact* powerGenerated         READ powerGenerated        CONSTANT)
    Q_PROPERTY(Fact* busVoltage             READ busVoltage            CONSTANT)
    Q_PROPERTY(Fact* batCurrentSetpoint     READ batCurrentSetpoint    CONSTANT)
    Q_PROPERTY(Fact* runtime                READ runtime               CONSTANT)
    Q_PROPERTY(Fact* timeUntilMaintenance   READ timeUntilMaintenance  CONSTANT)
    Q_PROPERTY(Fact* generatorSpeed         READ generatorSpeed        CONSTANT)
    Q_PROPERTY(Fact* rectifierTemperature   READ rectifierTemperature  CONSTANT)
    Q_PROPERTY(Fact* generatorTemperature   READ generatorTemperature  CONSTANT)

    Fact* status                           () { return &_statusFact; }
    Fact* batteryCurrent                   () { return &_batteryCurrentFact; }
    Fact* loadCurrent                      () { return &_loadCurrentFact; }
    Fact* powerGenerated                   () { return &_powerGeneratedFact; }
    Fact* busVoltage                       () { return &_busVoltageFact; }
    Fact* batCurrentSetpoint               () { return &_batCurrentSetpointFact; }
    Fact* runtime                          () { return &_runtimeFact; }
    Fact* timeUntilMaintenance             () { return &_timeUntilMaintenanceFact; }
    Fact* generatorSpeed                   () { return &_generatorSpeedFact; }
    Fact* rectifierTemperature             () { return &_rectifierTemperatureFact; }
    Fact* generatorTemperature             () { return &_generatorTemperatureFact; }

    // Overrides from FactGroup
    void handleMessage(Vehicle* vehicle, mavlink_message_t& message) override;

    static const char* _statusFactName;
    static const char* _batteryCurrentFactName;
    static const char* _loadCurrentFactName;
    static const char* _powerGeneratedFactName;
    static const char* _busVoltageFactName;
    static const char* _batCurrentSetpointFactName;
    static const char* _runtimeFactName;
    static const char* _timeUntilMaintenanceFactName;
    static const char* _generatorSpeedFactName;
    static const char* _rectifierTemperatureFactName;
    static const char* _generatorTemperatureFactName;

private:
    void _handleGeneratorStatus              (mavlink_message_t& message);

    Fact _statusFact;
    Fact _batteryCurrentFact;
    Fact _loadCurrentFact;
    Fact _powerGeneratedFact;
    Fact _busVoltageFact;
    Fact _batCurrentSetpointFact;
    Fact _runtimeFact;
    Fact _timeUntilMaintenanceFact;
    Fact _generatorSpeedFact;
    Fact _rectifierTemperatureFact;
    Fact _generatorTemperatureFact;
};
