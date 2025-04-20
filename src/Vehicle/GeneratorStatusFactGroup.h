#pragma once

#include "FactGroup.h"

class GeneratorStatusFactGroup : public FactGroup
{
    Q_OBJECT
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

public:
    GeneratorStatusFactGroup(QObject* parent = nullptr);

    Fact *status                () { return &_statusFact; }
    Fact *batteryCurrent        () { return &_batteryCurrentFact; }
    Fact *loadCurrent           () { return &_loadCurrentFact; }
    Fact *powerGenerated        () { return &_powerGeneratedFact; }
    Fact *busVoltage            () { return &_busVoltageFact; }
    Fact *batCurrentSetpoint    () { return &_batCurrentSetpointFact; }
    Fact *runtime               () { return &_runtimeFact; }
    Fact *timeUntilMaintenance  () { return &_timeUntilMaintenanceFact; }
    Fact *generatorSpeed        () { return &_generatorSpeedFact; }
    Fact *rectifierTemperature  () { return &_rectifierTemperatureFact; }
    Fact *generatorTemperature  () { return &_generatorTemperatureFact; }

    // Overrides from FactGroup
    void handleMessage(Vehicle *vehicle, const mavlink_message_t &message) override;

private:
    void _handleGeneratorStatus (const mavlink_message_t &message);

    Fact _statusFact = Fact(0, QStringLiteral("status"), FactMetaData::valueTypeUint64);
    Fact _batteryCurrentFact = Fact(0, QStringLiteral("batteryCurrent"), FactMetaData::valueTypeFloat);
    Fact _loadCurrentFact = Fact(0, QStringLiteral("loadCurrent"), FactMetaData::valueTypeFloat);
    Fact _powerGeneratedFact = Fact(0, QStringLiteral("powerGenerated"), FactMetaData::valueTypeFloat);
    Fact _busVoltageFact = Fact(0, QStringLiteral("busVoltage"), FactMetaData::valueTypeFloat);
    Fact _batCurrentSetpointFact = Fact(0, QStringLiteral("batCurrentSetpoint"), FactMetaData::valueTypeFloat);
    Fact _runtimeFact = Fact(0, QStringLiteral("runtime"), FactMetaData::valueTypeUint32);
    Fact _timeUntilMaintenanceFact = Fact(0, QStringLiteral("timeUntilMaintenance"), FactMetaData::valueTypeInt32);
    Fact _generatorSpeedFact = Fact(0, QStringLiteral("generatorSpeed"), FactMetaData::valueTypeUint16);
    Fact _rectifierTemperatureFact = Fact(0, QStringLiteral("rectifierTemperature"), FactMetaData::valueTypeInt16);
    Fact _generatorTemperatureFact = Fact(0, QStringLiteral("generatorTemperature"), FactMetaData::valueTypeInt16);
};
