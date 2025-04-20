#pragma once

#include "FactGroup.h"

class TunnelingDataFactGroup : public FactGroup
{
    Q_OBJECT
    Q_PROPERTY(Fact* temperature    READ temperature     CONSTANT)
    Q_PROPERTY(Fact* humidity       READ humidity        CONSTANT)
    Q_PROPERTY(Fact* pressure       READ pressure        CONSTANT)
    Q_PROPERTY(Fact* windspeed      READ windspeed       CONSTANT)
    Q_PROPERTY(Fact* winddirection  READ winddirection   CONSTANT)
    Q_PROPERTY(Fact* pm1p0          READ pm1p0           CONSTANT)
    Q_PROPERTY(Fact* pm2p5          READ pm2p5           CONSTANT)
    Q_PROPERTY(Fact* pm10           READ pm10            CONSTANT)
    Q_PROPERTY(Fact* radiation      READ radiation       CONSTANT)

public:
    TunnelingDataFactGroup(QObject* parent = nullptr);    

    Fact *temperature() { return &_temperatureFact; }
    Fact *humidity() { return &_humidityFact; }
    Fact *pressure() { return &_pressureFact; }
    Fact *windspeed() { return &_windspeedFact; }
    Fact *winddirection() { return &_winddirectionFact; }
    Fact *pm1p0() { return &_pm1p0Fact; }
    Fact *pm2p5() { return &_pm2p5Fact; }
    Fact *pm10() { return &_pm10Fact; }
    Fact *radiation() { return &_radiationFact; }

    // Overrides from FactGroup
    void handleMessage(Vehicle* vehicle, const mavlink_message_t& message) override;

private:
    void _handleTunnel(const mavlink_message_t& message);

    Fact _temperatureFact = Fact(0, QStringLiteral("temperature"), FactMetaData::valueTypeDouble);
    Fact _humidityFact = Fact(0, QStringLiteral("humidity"), FactMetaData::valueTypeDouble);
    Fact _pressureFact = Fact(0, QStringLiteral("pressure"), FactMetaData::valueTypeDouble);
    Fact _windspeedFact = Fact(0, QStringLiteral("windSpeed"), FactMetaData::valueTypeDouble);
    Fact _winddirectionFact = Fact(0, QStringLiteral("windDirection"), FactMetaData::valueTypeDouble);
    Fact _pm1p0Fact = Fact(0, QStringLiteral("pm1p0"), FactMetaData::valueTypeDouble);
    Fact _pm2p5Fact = Fact(0, QStringLiteral("pm2p5"), FactMetaData::valueTypeDouble);
    Fact _pm10Fact = Fact(0, QStringLiteral("pm10"), FactMetaData::valueTypeDouble);
    Fact _radiationFact = Fact(0, QStringLiteral("radiation"), FactMetaData::valueTypeDouble);

    struct tunneling_Payload {
        int16_t temperatureRaw;
        uint16_t humidityRaw;
        float pressureRaw;
        uint16_t windspeedRaw;
        uint16_t winddirectionRaw;
        uint16_t pm1p0Raw;
        uint16_t pm2p5Raw;
        uint16_t pm10Raw;
        float radiationRaw;
    };
};
