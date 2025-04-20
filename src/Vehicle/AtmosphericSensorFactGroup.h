#pragma once

//#define USE_ATMOSPHERIC_VALUE

#include "FactGroup.h"

class AtmosphericSensorFactGroup : public FactGroup
{
    Q_OBJECT
    Q_PROPERTY(Fact* status       READ status       CONSTANT)
    Q_PROPERTY(Fact* logCount     READ logCount     CONSTANT)
    Q_PROPERTY(Fact* temperature  READ temperature  CONSTANT)
    Q_PROPERTY(Fact* humidity     READ humidity     CONSTANT)
    Q_PROPERTY(Fact* pressure     READ pressure     CONSTANT)
    Q_PROPERTY(Fact* extValue1    READ extValue1    CONSTANT)
    Q_PROPERTY(Fact* extValue2    READ extValue2    CONSTANT)
    Q_PROPERTY(Fact* extValue3    READ extValue3    CONSTANT)
    Q_PROPERTY(Fact* extValue4    READ extValue4    CONSTANT)
    Q_PROPERTY(Fact* windDir      READ windDir      CONSTANT)
    Q_PROPERTY(Fact* windSpd      READ windSpd      CONSTANT)
    Q_PROPERTY(Fact* windSpdVer   READ windSpdVer   CONSTANT)

public:
    AtmosphericSensorFactGroup(QObject* parent = nullptr);   

    Fact* status        () { return &_statusFact; }
    Fact* logCount      () { return &_logCountFact; }
    Fact* temperature   () { return &_temperatureFact; }
    Fact* humidity      () { return &_humidityFact; }
    Fact* pressure      () { return &_pressureFact; }
    Fact* extValue1     () { return &_extValue1Fact; }
    Fact* extValue2     () { return &_extValue2Fact; }
    Fact* extValue3     () { return &_extValue3Fact; }
    Fact* extValue4     () { return &_extValue4Fact; }
    Fact* windDir       () { return &_windDirFact; }
    Fact* windSpd       () { return &_windSpdFact; }
    Fact* windSpdVer    () { return &_windSpdVerFact; }

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
    Fact _logCountFact = Fact(0, QStringLiteral("logCount"), FactMetaData::valueTypeDouble);
    Fact _temperatureFact = Fact(0, QStringLiteral("temperature"), FactMetaData::valueTypeDouble);
    Fact _humidityFact = Fact(0, QStringLiteral("humidity"), FactMetaData::valueTypeDouble);
    Fact _pressureFact = Fact(0, QStringLiteral("pressure"), FactMetaData::valueTypeDouble);
    Fact _extValue1Fact = Fact(0, QStringLiteral("extValue1"), FactMetaData::valueTypeInt16);
    Fact _extValue2Fact = Fact(0, QStringLiteral("extValue2"), FactMetaData::valueTypeInt16);
    Fact _extValue3Fact = Fact(0, QStringLiteral("extValue3"), FactMetaData::valueTypeInt16);
    Fact _extValue4Fact = Fact(0, QStringLiteral("extValue4"), FactMetaData::valueTypeInt16);
    Fact _windDirFact = Fact(0, QStringLiteral("windDir"), FactMetaData::valueTypeDouble);
    Fact _windSpdFact = Fact(0, QStringLiteral("windSpd"), FactMetaData::valueTypeDouble);
    Fact _windSpdVerFact = Fact(0, QStringLiteral("windSpdVer"), FactMetaData::valueTypeDouble);;
};
