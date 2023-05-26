#include "TunnelingDataFactGroup.h"
#include "Vehicle.h"

#include <QtMath>

const char* TunnelingDataFactGroup::_temperatureFactName =      "temperature";
const char* TunnelingDataFactGroup::_humidityFactName =         "humidity";
const char* TunnelingDataFactGroup::_windspeedFactName =        "windSpeed";
const char* TunnelingDataFactGroup::_winddirectionFactName =    "windDirection";
const char* TunnelingDataFactGroup::_pm2_5FactName =            "pm2_5";
const char* TunnelingDataFactGroup::_pm10FactName =             "pm10";
const char* TunnelingDataFactGroup::_radiationFactName =        "radiation";

TunnelingDataFactGroup::TunnelingDataFactGroup(QObject* parent)
    : FactGroup(1000, ":/json/Vehicle/TunnelingDataFact.json", parent)
    , _temperatureFact  (0, _temperatureFactName,   FactMetaData::valueTypeDouble)
    , _humidityFact     (0, _humidityFactName,      FactMetaData::valueTypeDouble)
    , _windspeedFact    (0, _windspeedFactName,     FactMetaData::valueTypeDouble)
    , _winddirectionFact(0, _winddirectionFactName, FactMetaData::valueTypeDouble)
    , _pm2_5Fact        (0, _pm2_5FactName,         FactMetaData::valueTypeDouble)
    , _pm10Fact         (0, _pm10FactName,          FactMetaData::valueTypeDouble)
    , _radiationFact    (0, _radiationFactName,     FactMetaData::valueTypeDouble)
{
    _addFact(&_temperatureFact,     _temperatureFactName);
    _addFact(&_humidityFact,        _humidityFactName);
    _addFact(&_windspeedFact,       _windspeedFactName);
    _addFact(&_winddirectionFact,   _winddirectionFactName);
    _addFact(&_pm2_5Fact,           _pm2_5FactName);
    _addFact(&_pm10Fact,            _pm10FactName);
    _addFact(&_radiationFact,       _radiationFactName);
}

void TunnelingDataFactGroup::handleMessage(Vehicle* vehicle, mavlink_message_t& message)
{
    switch (message.msgid) {

    case MAVLINK_MSG_ID_TUNNEL:
        _handleTunnel(message);
        break;
    default:
        break;
    }
}

void TunnelingDataFactGroup::_handleTunnel(mavlink_message_t &message)
{
    mavlink_tunnel_t tunnel;
    mavlink_msg_tunnel_decode(&message, &tunnel);

    switch(tunnel.payload_type){
        case 2:
            struct tunneling_Payload tP;

            memcpy(&tP, &tunnel.payload, sizeof(tP));

            _temperatureFact.setRawValue(tP.temperatureRaw/10.f);
            _humidityFact.setRawValue(tP.humidityRaw/10.f);
            _windspeedFact.setRawValue(tP.windspeedRaw/10.f);
            _winddirectionFact.setRawValue(tP.winddirectionRaw);
            _pm2_5Fact.setRawValue(tP.pm2_5Raw/10.f);
            _pm10Fact.setRawValue(tP.pm10Raw/10.f);
            _radiationFact.setRawValue(tP.radiationRaw);

            break;
    }
}

