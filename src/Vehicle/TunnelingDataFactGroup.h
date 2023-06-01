#pragma once

#include "FactGroup.h"

class TunnelingDataFactGroup : public FactGroup
{
    Q_OBJECT

public:
    TunnelingDataFactGroup(QObject* parent = nullptr);

    Q_PROPERTY(Fact* temperature    READ temperature     CONSTANT)
    Q_PROPERTY(Fact* humidity       READ humidity        CONSTANT)
    Q_PROPERTY(Fact* pressure       READ pressure        CONSTANT)
    Q_PROPERTY(Fact* windspeed      READ windspeed       CONSTANT)
    Q_PROPERTY(Fact* winddirection  READ winddirection   CONSTANT)
    Q_PROPERTY(Fact* pm1p0          READ pm1p0           CONSTANT)
    Q_PROPERTY(Fact* pm2p5          READ pm2p5           CONSTANT)
    Q_PROPERTY(Fact* pm10           READ pm10            CONSTANT)

    Fact* temperature                 () { return &_temperatureFact; }
    Fact* humidity                    () { return &_humidityFact; }
    Fact* pressure                    () { return &_pressureFact; }
    Fact* windspeed                   () { return &_windspeedFact; }
    Fact* winddirection               () { return &_winddirectionFact; }
    Fact* pm1p0                       () { return &_pm1p0Fact; }
    Fact* pm2p5                       () { return &_pm2p5Fact; }
    Fact* pm10                        () { return &_pm10Fact; }

    // Overrides from FactGroup
    void handleMessage(Vehicle* vehicle, mavlink_message_t& message) override;

    static const char* _temperatureFactName;
    static const char* _humidityFactName;
    static const char* _pressureFactName;
    static const char* _windspeedFactName;
    static const char* _winddirectionFactName;
    static const char* _pm1p0FactName;
    static const char* _pm2p5FactName;
    static const char* _pm10FactName;

private:
    void _handleTunnel              (mavlink_message_t& message);

    Fact _temperatureFact;
    Fact _humidityFact;
    Fact _pressureFact;
    Fact _windspeedFact;
    Fact _winddirectionFact;
    Fact _pm1p0Fact;
    Fact _pm2p5Fact;
    Fact _pm10Fact;

    struct tunneling_Payload {
        int16_t temperatureRaw;
        uint16_t humidityRaw;
        float pressureRaw;
        uint16_t windspeedRaw;
        uint16_t winddirectionRaw;
        uint16_t pm1p0Raw;
        uint16_t pm2p5Raw;
        uint16_t pm10Raw;
    };
};
