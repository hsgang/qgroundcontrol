#include "AtmosphericSensorFactGroup.h"
#include "Vehicle.h"

#include <QtMath>

const char* AtmosphericSensorFactGroup::_statusFactName =       "status";
const char* AtmosphericSensorFactGroup::_logCountFactName =     "logCount";
const char* AtmosphericSensorFactGroup::_temperatureFactName =  "temperature";
const char* AtmosphericSensorFactGroup::_humidityFactName =     "humidity";
const char* AtmosphericSensorFactGroup::_pressureFactName =     "pressure";
const char* AtmosphericSensorFactGroup::_extValue1FactName =    "extValue1";
const char* AtmosphericSensorFactGroup::_extValue2FactName =    "extValue2";
const char* AtmosphericSensorFactGroup::_extValue3FactName =    "extValue3";
const char* AtmosphericSensorFactGroup::_extValue4FactName =    "extValue4";
const char* AtmosphericSensorFactGroup::_windDirFactName =      "windDir";
const char* AtmosphericSensorFactGroup::_windSpdFactName =      "windSpd";
const char* AtmosphericSensorFactGroup::_windSpdVerFactName =   "windSpdVer";

struct sensor_data32_Payload {
    float logCountRaw;
    float temperatureRaw;
    float humidityRaw;
    float pressureRaw;
    float windDirRaw;
    float windSpdRaw;
    int16_t extValue1Raw;
    int16_t extValue2Raw;
    int16_t extValue3Raw;
    int16_t extValue4Raw;
};

AtmosphericSensorFactGroup::AtmosphericSensorFactGroup(QObject* parent)
    : FactGroup(500, ":/json/Vehicle/AtmosphericSensorFact.json", parent)
    , _statusFact     (0, _statusFactName,     FactMetaData::valueTypeUint8)
    , _logCountFact   (0, _logCountFactName,   FactMetaData::valueTypeDouble)
    , _temperatureFact(0, _temperatureFactName,FactMetaData::valueTypeDouble)
    , _humidityFact   (0, _humidityFactName,   FactMetaData::valueTypeDouble)
    , _pressureFact   (0, _pressureFactName,   FactMetaData::valueTypeDouble)
    , _extValue1Fact  (0, _extValue1FactName,  FactMetaData::valueTypeInt16)
    , _extValue2Fact  (0, _extValue2FactName,  FactMetaData::valueTypeInt16)
    , _extValue3Fact  (0, _extValue3FactName,  FactMetaData::valueTypeInt16)
    , _extValue4Fact  (0, _extValue4FactName,  FactMetaData::valueTypeInt16)
    , _windDirFact    (0, _windDirFactName,    FactMetaData::valueTypeDouble)
    , _windSpdFact    (0, _windSpdFactName,    FactMetaData::valueTypeDouble)
    , _windSpdVerFact (0, _windSpdVerFactName, FactMetaData::valueTypeDouble)
{
    _addFact(&_statusFact,        _statusFactName);
    _addFact(&_logCountFact,      _logCountFactName);
    _addFact(&_temperatureFact,   _temperatureFactName);
    _addFact(&_humidityFact,      _humidityFactName);
    _addFact(&_pressureFact,      _pressureFactName);
    _addFact(&_extValue1Fact,     _extValue1FactName);
    _addFact(&_extValue2Fact,     _extValue2FactName);
    _addFact(&_extValue3Fact,     _extValue3FactName);
    _addFact(&_extValue4Fact,     _extValue4FactName);
    _addFact(&_windDirFact,       _windDirFactName);
    _addFact(&_windSpdFact,       _windSpdFactName);
    _addFact(&_windSpdVerFact,    _windSpdVerFactName);

    // Start out as not available "--.--"
    _temperatureFact.setRawValue (qQNaN());
    _humidityFact.setRawValue  (qQNaN());
    _pressureFact.setRawValue  (qQNaN());
    _extValue1Fact.setRawValue (qQNaN());
    _extValue2Fact.setRawValue (qQNaN());
    _extValue3Fact.setRawValue (qQNaN());
    _extValue4Fact.setRawValue (qQNaN());
    _windDirFact.setRawValue   (qQNaN());
    _windSpdFact.setRawValue   (qQNaN());
    _windSpdVerFact.setRawValue(qQNaN());
}

void AtmosphericSensorFactGroup::handleMessage(Vehicle* vehicle, mavlink_message_t& message)
{
    switch (message.msgid) {
    case MAVLINK_MSG_ID_DATA32:
         _handleData32(message);
        break;
    case MAVLINK_MSG_ID_HYGROMETER_SENSOR:
        _handleHygrometerSensor(message);
        break;
    case MAVLINK_MSG_ID_TUNNEL:
        _handleTunnel(message);
        break;
#if defined(MAVLINK_MSG_ID_ATMOSPHERIC_VALUE)
    case MAVLINK_MSG_ID_ATMOSPHERIC_VALUE:
        _handleAtmosphericValue(message);
        break;
#endif

//#if !defined(NO_ARDUPILOT_DIALECT)
//    case MAVLINK_MSG_ID_WIND:
//        _handleWind(message);
//        break;
//#endif
    default:
        break;
    }
}

void AtmosphericSensorFactGroup::_handleData32(mavlink_message_t &message)
{
    mavlink_data32_t data32;
    mavlink_msg_data32_decode(&message, &data32);

    struct sensor_data32_Payload sP;

    memcpy(&sP, &data32.data, sizeof (struct sensor_data32_Payload));

    float logCountRaw     = sP.logCountRaw;
    float temperatureRaw  = sP.temperatureRaw;
    float humidityRaw     = sP.humidityRaw;
    float pressureRaw     = sP.pressureRaw;
    float windDirRaw      = sP.windDirRaw;
    float windSpdRaw      = sP.windSpdRaw;
    int16_t extValue1Raw  = sP.extValue1Raw;
    int16_t extValue2Raw  = sP.extValue2Raw;
    int16_t extValue3Raw  = sP.extValue3Raw;
    int16_t extValue4Raw  = sP.extValue4Raw;

    logCount()->setRawValue(logCountRaw);
    temperature()->setRawValue(temperatureRaw);
    humidity()->setRawValue(humidityRaw);
    pressure()->setRawValue(pressureRaw);
    windDir()->setRawValue(windDirRaw);
    windSpd()->setRawValue(windSpdRaw);
    extValue1()->setRawValue(extValue1Raw);
    extValue2()->setRawValue(extValue2Raw);
    extValue3()->setRawValue(extValue3Raw);
    extValue4()->setRawValue(extValue4Raw);

    status()->setRawValue(data32.type);
}

void AtmosphericSensorFactGroup::_handleScaledPressure(mavlink_message_t& message)
{
    mavlink_scaled_pressure_t pressure;
    mavlink_msg_scaled_pressure_decode(&message, &pressure);
    //sensorBaro()->setRawValue(pressure.press_abs);
}

void AtmosphericSensorFactGroup::_handleHygrometerSensor(mavlink_message_t& message)
{
    mavlink_hygrometer_sensor_t hygrometer;
    mavlink_msg_hygrometer_sensor_decode(&message, &hygrometer);

    temperature()->setRawValue((hygrometer.temperature) * 0.01);
    humidity()->setRawValue((hygrometer.humidity) * 0.01);
}

#if defined(MAVLINK_MSG_ID_ATMOSPHERIC_VALUE)
void AtmosphericSensorFactGroup::_handleAtmosphericValue(mavlink_message_t& message)
{
    mavlink_atmospheric_value_t atmospheric;
    mavlink_msg_atmospheric_value_decode(&message, &atmospheric);

    logCount()->setRawValue(atmospheric.count);
    temperature()->setRawValue(atmospheric.temperature);
    humidity()->setRawValue(atmospheric.humidity);
    pressure()->setRawValue(atmospheric.pressure);
    windDir()->setRawValue(atmospheric.wind_direction);
    windSpd()->setRawValue(atmospheric.wind_speed);
}
#endif

void AtmosphericSensorFactGroup::_handleTunnel(mavlink_message_t &message)
{
    mavlink_tunnel_t tunnel;
    mavlink_msg_tunnel_decode(&message, &tunnel);

    if(tunnel.payload_type == 300){
        struct sensor_data32_Payload tP;

        memcpy(&tP, &tunnel.payload, sizeof(tP));

        float logCountRaw     = tP.logCountRaw;
        float temperatureRaw  = tP.temperatureRaw;
        float humidityRaw     = tP.humidityRaw;
        float pressureRaw     = tP.pressureRaw;
        float windDirRaw      = tP.windDirRaw;
        float windSpdRaw      = tP.windSpdRaw;
        int16_t extValue1Raw  = tP.extValue1Raw;
        int16_t extValue2Raw  = tP.extValue2Raw;
        int16_t extValue3Raw  = tP.extValue3Raw;
        int16_t extValue4Raw  = tP.extValue4Raw;

        logCount()->setRawValue(logCountRaw);
        temperature()->setRawValue(temperatureRaw);
        humidity()->setRawValue(humidityRaw);
        pressure()->setRawValue(pressureRaw);
        windDir()->setRawValue(windDirRaw);
        windSpd()->setRawValue(windSpdRaw);
        extValue1()->setRawValue(extValue1Raw);
        extValue2()->setRawValue(extValue2Raw);
        extValue3()->setRawValue(extValue3Raw);
        extValue4()->setRawValue(extValue4Raw);

        status()->setRawValue(tunnel.payload_type);
    }
}

