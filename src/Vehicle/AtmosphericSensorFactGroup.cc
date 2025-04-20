#include "AtmosphericSensorFactGroup.h"
#include "Vehicle.h"

#include <QtMath>

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

struct sensor_tunnel_forSmartCity {
    int16_t temperatureRaw;
    uint16_t humidityRaw;
    float pressureRaw;
    uint16_t windSpeedRaw;
    uint16_t windHeadingRaw;
    uint16_t pm1p0Raw;
    uint16_t pm2p5Raw;
    uint16_t pm10Raw;
};

AtmosphericSensorFactGroup::AtmosphericSensorFactGroup(QObject* parent)
    : FactGroup(500, ":/json/Vehicle/AtmosphericSensorFact.json", parent)
{
    _addFact(&_statusFact);
    _addFact(&_logCountFact);
    _addFact(&_temperatureFact);
    _addFact(&_humidityFact);
    _addFact(&_pressureFact);
    _addFact(&_extValue1Fact);
    _addFact(&_extValue2Fact);
    _addFact(&_extValue3Fact);
    _addFact(&_extValue4Fact);
    _addFact(&_windDirFact);
    _addFact(&_windSpdFact);
    _addFact(&_windSpdVerFact);

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

void AtmosphericSensorFactGroup::handleMessage(Vehicle *vehicle, const mavlink_message_t &message)
{
    Q_UNUSED(vehicle);

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
#if defined(USE_ATMOSPHERIC_VALUE)
    case MAVLINK_MSG_ID_ATMOSPHERIC_VALUE:
        _handleAtmosphericValue(message);
        break;
#endif
// #if !defined(NO_ARDUPILOT_DIALECT)
    case MAVLINK_MSG_ID_WIND:
        _handleWind(message);
        break;
// #endif
    default:
        break;
    }
}

void AtmosphericSensorFactGroup::_handleData32(const mavlink_message_t &message)
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

    if(logCountRaw)     {logCount()->setRawValue(logCountRaw);}
    if(temperatureRaw)  {temperature()->setRawValue(temperatureRaw);}
    if(humidityRaw)     {humidity()->setRawValue(humidityRaw);}
    if(pressureRaw)     {pressure()->setRawValue(pressureRaw);}
    if(windDirRaw)      {windDir()->setRawValue(windDirRaw);}
    if(windSpdRaw)      {windSpd()->setRawValue(windSpdRaw);}
    if(extValue1Raw)    {extValue1()->setRawValue(extValue1Raw);}
    if(extValue2Raw)    {extValue2()->setRawValue(extValue2Raw);}
    if(extValue3Raw)    {extValue3()->setRawValue(extValue3Raw);}
    if(extValue4Raw)    {extValue4()->setRawValue(extValue4Raw);}

    status()->setRawValue(data32.type);
}

void AtmosphericSensorFactGroup::_handleScaledPressure(const mavlink_message_t& message)
{
    mavlink_scaled_pressure_t pressure;
    mavlink_msg_scaled_pressure_decode(&message, &pressure);
    //sensorBaro()->setRawValue(pressure.press_abs);
}

void AtmosphericSensorFactGroup::_handleHygrometerSensor(const mavlink_message_t& message)
{
    mavlink_hygrometer_sensor_t hygrometer;
    mavlink_msg_hygrometer_sensor_decode(&message, &hygrometer);

    temperature()->setRawValue((hygrometer.temperature) * 0.01);
    humidity()->setRawValue((hygrometer.humidity) * 0.01);
}

#if defined(USE_ATMOSPHERIC_VALUE)
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

void AtmosphericSensorFactGroup::_handleTunnel(const mavlink_message_t &message)
{
    mavlink_tunnel_t tunnel;
    mavlink_msg_tunnel_decode(&message, &tunnel);

    switch(tunnel.payload_type){
        case 0: {
            struct sensor_tunnel_forSmartCity sC;
            memcpy(&sC, &tunnel.payload, sizeof(sC));

            float tempRaw = sC.temperatureRaw * 0.01;
            float humiRaw = sC.humidityRaw * 0.01;
            float pressRaw = sC.pressureRaw;
            float windDRaw = sC.windHeadingRaw;
            float windSRaw = sC.windSpeedRaw * 0.1;
            int16_t ext1Raw = sC.pm1p0Raw * 0.1;
            int16_t ext2Raw = sC.pm2p5Raw * 0.1;
            int16_t ext3Raw = sC.pm10Raw * 0.1;

            if(tempRaw)  {temperature()->setRawValue(tempRaw);}
            if(humiRaw)     {humidity()->setRawValue(humiRaw);}
            if(pressRaw)    {pressure()->setRawValue(pressRaw);}
            if(windDRaw)    {windDir()->setRawValue(windDRaw);}
            if(windSRaw)    {windSpd()->setRawValue(windSRaw);}
            if(ext1Raw)    {extValue1()->setRawValue(ext1Raw);}
            if(ext2Raw)    {extValue2()->setRawValue(ext2Raw);}
            if(ext3Raw)    {extValue3()->setRawValue(ext3Raw);}

            status()->setRawValue(tunnel.payload_type);

            break;
        }
        case 300: {
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

            if(logCountRaw)     {logCount()->setRawValue(logCountRaw);}
            if(temperatureRaw)  {temperature()->setRawValue(temperatureRaw);}
            if(humidityRaw)     {humidity()->setRawValue(humidityRaw);}
            if(pressureRaw)     {pressure()->setRawValue(pressureRaw);}
            if(windDirRaw)      {windDir()->setRawValue(windDirRaw);}
            if(windSpdRaw)      {windSpd()->setRawValue(windSpdRaw);}
            if(extValue1Raw)    {extValue1()->setRawValue(extValue1Raw);}
            if(extValue2Raw)    {extValue2()->setRawValue(extValue2Raw);}
            if(extValue3Raw)    {extValue3()->setRawValue(extValue3Raw);}
            if(extValue4Raw)    {extValue4()->setRawValue(extValue4Raw);}

            status()->setRawValue(tunnel.payload_type);
            break;
        }
        case 301: {
            // sid 방사능 데이터 특수 케이스
            struct sensor_data32_Payload tPs;

            memcpy(&tPs, &tunnel.payload, sizeof(tPs));

            int16_t extValue4Raw  = tPs.extValue4Raw;

            if(extValue4Raw)    {extValue4()->setRawValue(extValue4Raw);}

            status()->setRawValue(tunnel.payload_type);
            break;
        }
    }
}

// #if !defined(NO_ARDUPILOT_DIALECT)
void AtmosphericSensorFactGroup::_handleWind(const mavlink_message_t& message)
{
    mavlink_wind_t wind;
    mavlink_msg_wind_decode(&message, &wind);

    float direction = wind.direction;
    if (direction < 0) {
        direction += 360;
    }

    uint8_t compId = message.compid;

    if (compId == MAV_COMPONENT::MAV_COMP_ID_PERIPHERAL) {
        if(wind.direction)  {windDir()->setRawValue(direction);}
        if(wind.speed)      {windSpd()->setRawValue(wind.speed);}
    }
}
// #endif

