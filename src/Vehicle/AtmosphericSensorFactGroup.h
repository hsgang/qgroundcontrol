#pragma once

//#define USE_ATMOSPHERIC_VALUE

#include "FactGroup.h"

class AtmosphericSensorFactGroup : public FactGroup
{
    Q_OBJECT

public:
    AtmosphericSensorFactGroup(QObject* parent = nullptr);

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

    Fact* status                      () { return &_statusFact; }
    Fact* logCount                    () { return &_logCountFact; }
    Fact* temperature                 () { return &_temperatureFact; }
    Fact* humidity                    () { return &_humidityFact; }
    Fact* pressure                    () { return &_pressureFact; }
    Fact* extValue1                   () { return &_extValue1Fact; }
    Fact* extValue2                   () { return &_extValue2Fact; }
    Fact* extValue3                   () { return &_extValue3Fact; }
    Fact* extValue4                   () { return &_extValue4Fact; }
    Fact* windDir                     () { return &_windDirFact; }
    Fact* windSpd                     () { return &_windSpdFact; }
    Fact* windSpdVer                  () { return &_windSpdVerFact; }

    // Overrides from FactGroup
    void handleMessage(Vehicle* vehicle, mavlink_message_t& message) override;

    static const char* _statusFactName;
    static const char* _logCountFactName;
    static const char* _temperatureFactName;
    static const char* _humidityFactName;
    static const char* _pressureFactName;
    static const char* _extValue1FactName;
    static const char* _extValue2FactName;
    static const char* _extValue3FactName;
    static const char* _extValue4FactName;
    static const char* _windDirFactName;
    static const char* _windSpdFactName;
    static const char* _windSpdVerFactName;

private:
    void _handleData32              (mavlink_message_t& message);
    void _handleTunnel              (mavlink_message_t& message);
    void _handleScaledPressure      (mavlink_message_t& message);
#if defined(USE_ATMOSPHERIC_VALUE)
    void _handleAtmosphericValue    (mavlink_message_t& message);
#endif
#if !defined(NO_ARDUPILOT_DIALECT)
    void _handleWind        (mavlink_message_t& message);
#endif
    void _handleHygrometerSensor    (mavlink_message_t& message);

    Fact _statusFact;
    Fact _logCountFact;
    Fact _temperatureFact;
    Fact _humidityFact;
    Fact _pressureFact;
    Fact _extValue1Fact;
    Fact _extValue2Fact;
    Fact _extValue3Fact;
    Fact _extValue4Fact;
    Fact _windDirFact;
    Fact _windSpdFact;
    Fact _windSpdVerFact;
};
