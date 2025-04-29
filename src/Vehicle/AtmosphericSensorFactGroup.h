#pragma once

//#define USE_ATMOSPHERIC_VALUE

#include "FactGroup.h"

class AtmosphericSensorFactGroup : public FactGroup
{
    Q_OBJECT
    Q_PROPERTY(Fact *status       READ status       CONSTANT)
    Q_PROPERTY(Fact *logCount     READ logCount     CONSTANT)
    Q_PROPERTY(Fact *temperature  READ temperature  CONSTANT)
    Q_PROPERTY(Fact *humidity     READ humidity     CONSTANT)
    Q_PROPERTY(Fact *pressure     READ pressure     CONSTANT)
    Q_PROPERTY(Fact *windDir      READ windDir      CONSTANT)
    Q_PROPERTY(Fact *windSpd      READ windSpd      CONSTANT)
    Q_PROPERTY(Fact *hubTemp1     READ hubTemp1     CONSTANT)
    Q_PROPERTY(Fact *hubTemp2     READ hubTemp2     CONSTANT)
    Q_PROPERTY(Fact *hubHumi1     READ hubHumi1     CONSTANT)
    Q_PROPERTY(Fact *hubHumi2     READ hubHumi2     CONSTANT)
    Q_PROPERTY(Fact *hubPressure  READ hubPressure  CONSTANT)
    Q_PROPERTY(Fact *opc1         READ opc1         CONSTANT)
    Q_PROPERTY(Fact *opc2         READ opc2         CONSTANT)
    Q_PROPERTY(Fact *opc3         READ opc3         CONSTANT)
    Q_PROPERTY(Fact *radiation    READ radiation    CONSTANT)

public:
    AtmosphericSensorFactGroup(QObject* parent = nullptr);   

    Fact *status        () { return &_statusFact; }
    Fact *logCount      () { return &_logCountFact; }
    Fact *temperature   () { return &_temperatureFact; }
    Fact *humidity      () { return &_humidityFact; }
    Fact *pressure      () { return &_pressureFact; }
    Fact *windDir       () { return &_windDirFact; }
    Fact *windSpd       () { return &_windSpdFact; }
    Fact *hubTemp1      () { return &_hubTemp1Fact; }
    Fact *hubTemp2      () { return &_hubTemp2Fact; }
    Fact *hubHumi1      () { return &_hubHumi1Fact; }
    Fact *hubHumi2      () { return &_hubHumi2Fact; }
    Fact *hubPressure   () { return &_hubPressureFact; }
    Fact *opc1          () { return &_opc1Fact; }
    Fact *opc2          () { return &_opc2Fact; }
    Fact *opc3          () { return &_opc3Fact; }
    Fact *radiation     () { return &_radiationFact; }

    // Overrides from FactGroup
    void handleMessage(Vehicle *vehicle, const mavlink_message_t &message) override;

protected:
    void _handleData32              (const mavlink_message_t &message);
    void _handleTunnel              (const mavlink_message_t &message);
    void _handleScaledPressure      (const mavlink_message_t &message);
#if defined(USE_ATMOSPHERIC_VALUE)
    void _handleAtmosphericValue    (mavlink_message_t& message);
#endif
// #if !defined(NO_ARDUPILOT_DIALECT)
    void _handleWind        (const mavlink_message_t &message);
// #endif
    void _handleHygrometerSensor    (const mavlink_message_t &message);

    Fact _statusFact = Fact(0, QStringLiteral("status"), FactMetaData::valueTypeUint8);
    Fact _logCountFact = Fact(0, QStringLiteral("logCount"), FactMetaData::valueTypeFloat);
    Fact _temperatureFact = Fact(0, QStringLiteral("temperature"), FactMetaData::valueTypeFloat);
    Fact _humidityFact = Fact(0, QStringLiteral("humidity"), FactMetaData::valueTypeFloat);
    Fact _pressureFact = Fact(0, QStringLiteral("pressure"), FactMetaData::valueTypeFloat);
    Fact _windDirFact = Fact(0, QStringLiteral("windDir"), FactMetaData::valueTypeFloat);
    Fact _windSpdFact = Fact(0, QStringLiteral("windSpd"), FactMetaData::valueTypeFloat);
    Fact _hubTemp1Fact = Fact(0, QStringLiteral("hubTemp1"), FactMetaData::valueTypeFloat);
    Fact _hubTemp2Fact = Fact(0, QStringLiteral("hubTemp2"), FactMetaData::valueTypeFloat);
    Fact _hubHumi1Fact = Fact(0, QStringLiteral("hubHumi1"), FactMetaData::valueTypeFloat);
    Fact _hubHumi2Fact = Fact(0, QStringLiteral("hubHumi2"), FactMetaData::valueTypeFloat);
    Fact _hubPressureFact = Fact(0, QStringLiteral("hubPressure"), FactMetaData::valueTypeFloat);
    Fact _opc1Fact = Fact(0, QStringLiteral("opc1"), FactMetaData::valueTypeFloat);
    Fact _opc2Fact = Fact(0, QStringLiteral("opc2"), FactMetaData::valueTypeFloat);
    Fact _opc3Fact = Fact(0, QStringLiteral("opc3"), FactMetaData::valueTypeFloat);
    Fact _radiationFact = Fact(0, QStringLiteral("radiation"), FactMetaData::valueTypeFloat);

};
