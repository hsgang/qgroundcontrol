#pragma once

#include "FactGroup.h"
#include "QGCMAVLink.h"

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
    Q_PROPERTY(Fact* opcPM1p0     READ opcPM1p0     CONSTANT)
    Q_PROPERTY(Fact* opcPM2p5     READ opcPM2p5     CONSTANT)
    Q_PROPERTY(Fact* opcPM10      READ opcPM10      CONSTANT)
    Q_PROPERTY(Fact* extValue1    READ extValue1    CONSTANT)
    Q_PROPERTY(Fact* extValue2    READ extValue2    CONSTANT)
    Q_PROPERTY(Fact* extValue3    READ extValue3    CONSTANT)
    Q_PROPERTY(Fact* extValue4    READ extValue4    CONSTANT)
    Q_PROPERTY(Fact* extValue5    READ extValue5    CONSTANT)
    Q_PROPERTY(Fact* windDir      READ windDir      CONSTANT)
    Q_PROPERTY(Fact* windSpd      READ windSpd      CONSTANT)
    Q_PROPERTY(Fact* windSpdVer   READ windSpdVer   CONSTANT)

    Fact* status                      () { return &_statusFact; }
    Fact* logCount                    () { return &_logCountFact; }
    Fact* temperature                 () { return &_temperatureFact; }
    Fact* humidity                    () { return &_humidityFact; }
    Fact* pressure                    () { return &_pressureFact; }
    Fact* opcPM1p0                    () { return &_opcPM1p0Fact; }
    Fact* opcPM2p5                    () { return &_opcPM2p5Fact; }
    Fact* opcPM10                     () { return &_opcPM10Fact; }
    Fact* extValue1                   () { return &_extValue1Fact; }
    Fact* extValue2                   () { return &_extValue2Fact; }
    Fact* extValue3                   () { return &_extValue3Fact; }
    Fact* extValue4                   () { return &_extValue4Fact; }
    Fact* extValue5                   () { return &_extValue5Fact; }
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
    static const char* _opcPM1p0FactName;
    static const char* _opcPM2p5FactName;
    static const char* _opcPM10FactName;
    static const char* _extValue1FactName;
    static const char* _extValue2FactName;
    static const char* _extValue3FactName;
    static const char* _extValue4FactName;
    static const char* _extValue5FactName;
    static const char* _windDirFactName;
    static const char* _windSpdFactName;
    static const char* _windSpdVerFactName;

private:
    void _handleData32              (mavlink_message_t& message);
    void _handleScaledPressure      (mavlink_message_t& message);
    void _handleAtmosphericSensor   (mavlink_message_t& message);
    void _handleWind                (mavlink_message_t& message);

    Fact _statusFact;
    Fact _logCountFact;
    Fact _temperatureFact;
    Fact _humidityFact;
    Fact _pressureFact;
    Fact _opcPM1p0Fact;
    Fact _opcPM2p5Fact;
    Fact _opcPM10Fact;
    Fact _extValue1Fact;
    Fact _extValue2Fact;
    Fact _extValue3Fact;
    Fact _extValue4Fact;
    Fact _extValue5Fact;
    Fact _windDirFact;
    Fact _windSpdFact;
    Fact _windSpdVerFact;
};
