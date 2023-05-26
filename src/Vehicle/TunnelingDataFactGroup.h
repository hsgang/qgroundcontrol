#pragma once

#include "FactGroup.h"

class TunnelingDataFactGroup : public FactGroup
{
    Q_OBJECT

public:
    TunnelingDataFactGroup(QObject* parent = nullptr);

    Q_PROPERTY(Fact* temperature    READ temperature     CONSTANT)
    Q_PROPERTY(Fact* humidity       READ humidity        CONSTANT)
    Q_PROPERTY(Fact* windspeed      READ windspeed       CONSTANT)
    Q_PROPERTY(Fact* winddirection  READ winddirection   CONSTANT)
    Q_PROPERTY(Fact* pm2_5          READ pm2_5           CONSTANT)
    Q_PROPERTY(Fact* pm10           READ pm10            CONSTANT)
    Q_PROPERTY(Fact* radiation      READ radiation       CONSTANT)

    Fact* temperature                 () { return &_temperatureFact; }
    Fact* humidity                    () { return &_humidityFact; }
    Fact* windspeed                   () { return &_windspeedFact; }
    Fact* winddirection               () { return &_winddirectionFact; }
    Fact* pm2_5                       () { return &_pm2_5Fact; }
    Fact* pm10                        () { return &_pm10Fact; }
    Fact* radiation                   () { return &_radiationFact; }

    // Overrides from FactGroup
    void handleMessage(Vehicle* vehicle, mavlink_message_t& message) override;

    static const char* _temperatureFactName;
    static const char* _humidityFactName;
    static const char* _windspeedFactName;
    static const char* _winddirectionFactName;
    static const char* _pm2_5FactName;
    static const char* _pm10FactName;
    static const char* _radiationFactName;

private:
    void _handleTunnel              (mavlink_message_t& message);

    Fact _temperatureFact;
    Fact _humidityFact;
    Fact _windspeedFact;
    Fact _winddirectionFact;
    Fact _pm2_5Fact;
    Fact _pm10Fact;
    Fact _radiationFact;

    struct tunneling_Payload {
        int16_t temperatureRaw;
        uint16_t humidityRaw;
        uint16_t windspeedRaw;
        uint16_t winddirectionRaw;
        uint16_t pm2_5Raw;
        uint16_t pm10Raw;
        float radiationRaw;
    };
};
