#include "TunnelingDataFactGroup.h"
#include "Vehicle.h"

#include <QtMath>

TunnelingDataFactGroup::TunnelingDataFactGroup(QObject* parent)
    : FactGroup(1000, ":/json/Vehicle/TunnelingDataFact.json", parent)
{
    _addFact(&_temperatureFact);
    _addFact(&_humidityFact);
    _addFact(&_pressureFact);
    _addFact(&_windspeedFact);
    _addFact(&_winddirectionFact);
    _addFact(&_pm1p0Fact);
    _addFact(&_pm2p5Fact);
    _addFact(&_pm10Fact);
    _addFact(&_radiationFact);
}

void TunnelingDataFactGroup::handleMessage(Vehicle *vehicle, const mavlink_message_t& message)
{
    Q_UNUSED(vehicle);

    switch (message.msgid) {

    case MAVLINK_MSG_ID_TUNNEL:
        _handleTunnel(message);
        break;
    default:
        break;
    }
}

void TunnelingDataFactGroup::_handleTunnel(const mavlink_message_t &message)
{
    mavlink_tunnel_t tunnel;
    mavlink_msg_tunnel_decode(&message, &tunnel);

    switch(tunnel.payload_type){
        case 0:
            struct tunneling_Payload tP;

            memcpy(&tP, &tunnel.payload, sizeof(tP));

            _temperatureFact.setRawValue(tP.temperatureRaw/100.f);
            _humidityFact.setRawValue(tP.humidityRaw/100.f);
            _pressureFact.setRawValue(tP.pressureRaw);
            _windspeedFact.setRawValue(tP.windspeedRaw/10.f);
            _winddirectionFact.setRawValue(tP.winddirectionRaw);
            _pm1p0Fact.setRawValue(tP.pm1p0Raw/10.f);
            _pm2p5Fact.setRawValue(tP.pm2p5Raw/10.f);
            _pm10Fact.setRawValue(tP.pm10Raw/10.f);
            _radiationFact.setRawValue(tP.radiationRaw);

            break;
    }
}

