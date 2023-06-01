#include "TunnelingDataFactGroup.h"
#include "Vehicle.h"

#include <QtMath>

const char* TunnelingDataFactGroup::_temperatureFactName =      "temperature";
const char* TunnelingDataFactGroup::_humidityFactName =         "humidity";
const char* TunnelingDataFactGroup::_pressureFactName =         "pressure";
const char* TunnelingDataFactGroup::_windspeedFactName =        "windSpeed";
const char* TunnelingDataFactGroup::_winddirectionFactName =    "windDirection";
const char* TunnelingDataFactGroup::_pm1p0FactName =            "pm1p0";
const char* TunnelingDataFactGroup::_pm2p5FactName =            "pm2p5";
const char* TunnelingDataFactGroup::_pm10FactName =             "pm10";

TunnelingDataFactGroup::TunnelingDataFactGroup(QObject* parent)
    : FactGroup(1000, ":/json/Vehicle/TunnelingDataFact.json", parent)
    , _temperatureFact  (0, _temperatureFactName,   FactMetaData::valueTypeDouble)
    , _humidityFact     (0, _humidityFactName,      FactMetaData::valueTypeDouble)
    , _pressureFact     (0, _pressureFactName,      FactMetaData::valueTypeDouble)
    , _windspeedFact    (0, _windspeedFactName,     FactMetaData::valueTypeDouble)
    , _winddirectionFact(0, _winddirectionFactName, FactMetaData::valueTypeDouble)
    , _pm1p0Fact        (0, _pm1p0FactName,         FactMetaData::valueTypeDouble)
    , _pm2p5Fact        (0, _pm2p5FactName,         FactMetaData::valueTypeDouble)
    , _pm10Fact         (0, _pm10FactName,          FactMetaData::valueTypeDouble)
{
    _addFact(&_temperatureFact,     _temperatureFactName);
    _addFact(&_humidityFact,        _humidityFactName);
    _addFact(&_pressureFact,        _pressureFactName);
    _addFact(&_windspeedFact,       _windspeedFactName);
    _addFact(&_winddirectionFact,   _winddirectionFactName);
    _addFact(&_pm1p0Fact,           _pm1p0FactName);
    _addFact(&_pm2p5Fact,           _pm2p5FactName);
    _addFact(&_pm10Fact,            _pm10FactName);
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

            break;
    }
}

