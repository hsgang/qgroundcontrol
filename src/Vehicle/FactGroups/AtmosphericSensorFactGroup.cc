#include "AtmosphericSensorFactGroup.h"
#include "Vehicle.h"

#include <QtMath>

struct Sensor_Payload {
    float logCountRaw;
    float temperatureRaw;
    float humidityRaw;
    float pressureRaw;
    float windDirRaw;
    float windSpdRaw;
    float hubTemp1Raw;
    float hubTemp2Raw;
    float hubHumi1Raw;
    float hubHumi2Raw;
    float hubPressureRaw;
    float opc1Raw;
    float opc2Raw;
    float opc3Raw;
    float radiationRaw;
    float battRaw;
};

struct Sensor_Tunnel_sC {
    int16_t temperatureRaw;
    uint16_t humidityRaw;
    float pressureRaw;
    uint16_t windSpeedRaw;
    uint16_t windHeadingRaw;
    uint16_t pm1p0Raw;
    uint16_t pm2p5Raw;
    uint16_t pm10Raw;
};

struct Sensor_Tunnel_Legacy {
    float logCount;
    float temp;
    float humi;
    float pres;
    float windDir;
    float windSpd;
    int16_t sensor1;
    int16_t sensor2;
    int16_t sensor3;
    int16_t sensor4;
};

AtmosphericSensorFactGroup::AtmosphericSensorFactGroup(QObject* parent)
    : FactGroup(500, ":/json/Vehicle/AtmosphericSensorFact.json", parent)
{
    _addFact(&_statusFact);
    _addFact(&_logCountFact);
    _addFact(&_temperatureFact);
    _addFact(&_humidityFact);
    _addFact(&_pressureFact);
    _addFact(&_windDirFact);
    _addFact(&_windSpdFact);
    _addFact(&_hubTemp1Fact);
    _addFact(&_hubTemp2Fact);
    _addFact(&_hubHumi1Fact);
    _addFact(&_hubHumi2Fact);
    _addFact(&_hubPressureFact);
    _addFact(&_opc1Fact);
    _addFact(&_opc2Fact);
    _addFact(&_opc3Fact);
    _addFact(&_radiationFact);
    _addFact(&_battFact);

    // Start out as not available "--.--"
    _temperatureFact.setRawValue (qQNaN());
    _humidityFact.setRawValue  (qQNaN());
    _pressureFact.setRawValue  (qQNaN());
    _windDirFact.setRawValue   (qQNaN());
    _windSpdFact.setRawValue   (qQNaN());
    _hubTemp1Fact.setRawValue (qQNaN());
    _hubTemp2Fact.setRawValue (qQNaN());
    _hubHumi1Fact.setRawValue (qQNaN());
    _hubHumi2Fact.setRawValue (qQNaN());
    _hubPressureFact.setRawValue(qQNaN());
    _opc1Fact.setRawValue (qQNaN());
    _opc2Fact.setRawValue (qQNaN());
    _opc3Fact.setRawValue (qQNaN());
    _radiationFact.setRawValue (qQNaN());
    _battFact.setRawValue(qQNaN());

}

void AtmosphericSensorFactGroup::handleMessage(Vehicle *vehicle, const mavlink_message_t &message)
{
    Q_UNUSED(vehicle);

    switch (message.msgid) {
    case MAVLINK_MSG_ID_DATA32:
        _handleData32(message);
        break;
    case MAVLINK_MSG_ID_WIND:
        _handleWind(message);
        break;
    case MAVLINK_MSG_ID_HYGROMETER_SENSOR:
        _handleHygrometerSensor(message);
        break;
    case MAVLINK_MSG_ID_TUNNEL:
        _handleTunnel(message);
        break;
    default:
        break;
    }
}

void AtmosphericSensorFactGroup::_handleData32(const mavlink_message_t &message)
{
    mavlink_data32_t data32;
    mavlink_msg_data32_decode(&message, &data32);

    struct Sensor_Payload sP;

    memcpy(&sP, &data32.data, sizeof (struct Sensor_Payload));

    float logCountRaw     = sP.logCountRaw;
    float temperatureRaw  = sP.temperatureRaw;
    float humidityRaw     = sP.humidityRaw;
    float pressureRaw     = sP.pressureRaw;
    float windDirRaw      = sP.windDirRaw;
    float windSpdRaw      = sP.windSpdRaw;
    float hubTemp1Raw     = sP.hubTemp1Raw;
    float hubTemp2Raw     = sP.hubTemp2Raw;
    float hubHumi1Raw     = sP.hubHumi1Raw;
    float hubHumi2Raw     = sP.hubHumi2Raw;
    float hubPressureRaw  = sP.hubPressureRaw;
    float opc1Raw         = sP.opc1Raw;
    float opc2Raw         = sP.opc2Raw;
    float opc3Raw         = sP.opc3Raw;
    float radiationRaw    = sP.radiationRaw;
    float battRaw         = sP.battRaw;

    if(!qIsNaN(logCountRaw))     {logCount()->setRawValue(logCountRaw);}
    if(temperatureRaw > -50 && temperatureRaw < 100)  {
        temperature()->setRawValue(temperatureRaw);
    }
    if(!qIsNaN(humidityRaw))     {humidity()->setRawValue(humidityRaw);}
    if(!qIsNaN(pressureRaw))     {pressure()->setRawValue(pressureRaw);}
    if(!qIsNaN(windDirRaw) && !_windDirByWindPacket)      {windDir()->setRawValue(windDirRaw);}
    if(!qIsNaN(windSpdRaw) && !_windDirByWindPacket)      {windSpd()->setRawValue(windSpdRaw);}
    if(hubTemp1Raw > -50 && hubTemp1Raw < 100) {
        hubTemp1()->setRawValue(hubTemp1Raw);
    }
    if(hubTemp2Raw > -50 && hubTemp2Raw < 100) {
        hubTemp2()->setRawValue(hubTemp2Raw);
    }
    if(hubHumi1Raw > 0 && hubHumi1Raw < 100) {
        hubHumi1()->setRawValue(hubHumi1Raw);
    }
    if(hubHumi2Raw > 0 && hubHumi2Raw < 100) {
        hubHumi2()->setRawValue(hubHumi2Raw);
    }
    if(hubPressureRaw > 0 && hubPressureRaw < 2000) {
        hubPressure()->setRawValue(hubPressureRaw);
    }
    if(!qIsNaN(opc1Raw))         {opc1()->setRawValue(opc1Raw);}
    if(!qIsNaN(opc2Raw))         {opc2()->setRawValue(opc2Raw);}
    if(!qIsNaN(opc3Raw))         {opc3()->setRawValue(opc3Raw);}
    if(!qIsNaN(radiationRaw))    {radiation()->setRawValue(radiationRaw);}
    if(battRaw > 0 && battRaw < 1000) {
        batt()->setRawValue(battRaw);
    }

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

void AtmosphericSensorFactGroup::_handleTunnel(const mavlink_message_t &message)
{
    mavlink_tunnel_t tunnel;
    mavlink_msg_tunnel_decode(&message, &tunnel);

    switch(tunnel.payload_type){
        case 0: {
            struct Sensor_Tunnel_sC sC;
            memcpy(&sC, &tunnel.payload, sizeof(sC));

            float tempRaw = sC.temperatureRaw * 0.01;
            float humiRaw = sC.humidityRaw * 0.01;
            float pressRaw = sC.pressureRaw;
            float windDRaw = sC.windHeadingRaw;
            float windSRaw = sC.windSpeedRaw * 0.1;
            float opc1Raw = sC.pm1p0Raw * 0.1;
            float opc2Raw = sC.pm2p5Raw * 0.1;
            float opc3Raw = sC.pm10Raw * 0.1;

            if(tempRaw)  {temperature()->setRawValue(tempRaw);}
            if(humiRaw)     {humidity()->setRawValue(humiRaw);}
            if(pressRaw)    {pressure()->setRawValue(pressRaw);}
            if(windDRaw && !_windDirByWindPacket)    {windDir()->setRawValue(windDRaw);}
            if(windSRaw && !_windDirByWindPacket)    {windSpd()->setRawValue(windSRaw);}
            if(opc1Raw)    {opc1()->setRawValue(opc1Raw);}
            if(opc2Raw)    {opc2()->setRawValue(opc2Raw);}
            if(opc3Raw)    {opc3()->setRawValue(opc3Raw);}

            status()->setRawValue(tunnel.payload_type);

            break;
        }
        case 300: {
            struct Sensor_Payload tP;

            memcpy(&tP, &tunnel.payload, sizeof(tP));

            float logCountRaw       = tP.logCountRaw;
            float temperatureRaw    = tP.temperatureRaw;
            float humidityRaw       = tP.humidityRaw;
            float pressureRaw       = tP.pressureRaw;
            float windDirRaw        = tP.windDirRaw;
            float windSpdRaw        = tP.windSpdRaw;
            float hubTemp1Raw       = tP.hubTemp1Raw;
            float hubTemp2Raw       = tP.hubTemp2Raw;
            float hubHumi1Raw       = tP.hubHumi1Raw;
            float hubHumi2Raw       = tP.hubHumi2Raw;
            float hubPressureRaw    = tP.hubPressureRaw;
            float opc1Raw           = tP.opc1Raw;
            float opc2Raw           = tP.opc2Raw;
            float opc3Raw           = tP.opc3Raw;
            float radiationRaw      = tP.radiationRaw;
            float battRaw           = tP.battRaw;

            if(logCountRaw)     {logCount()->setRawValue(logCountRaw);}
            if(temperatureRaw)  {temperature()->setRawValue(temperatureRaw);}
            if(humidityRaw)     {humidity()->setRawValue(humidityRaw);}
            if(pressureRaw)     {pressure()->setRawValue(pressureRaw);}
            if(windDirRaw && !_windDirByWindPacket)      {windDir()->setRawValue(windDirRaw);}
            if(windSpdRaw && !_windDirByWindPacket)      {windSpd()->setRawValue(windSpdRaw);}
            if(hubTemp1Raw)     {hubTemp1()->setRawValue(hubTemp1Raw);}
            if(hubTemp2Raw)     {hubTemp2()->setRawValue(hubTemp2Raw);}
            if(hubHumi1Raw)     {hubHumi1()->setRawValue(hubHumi1Raw);}
            if(hubHumi2Raw)     {hubHumi2()->setRawValue(hubHumi2Raw);}
            if(hubPressureRaw)  {hubPressure()->setRawValue(hubPressureRaw);}
            if(opc1Raw)         {opc1()->setRawValue(opc1Raw);}
            if(opc2Raw)         {opc2()->setRawValue(opc2Raw);}
            if(opc3Raw)         {opc3()->setRawValue(opc3Raw);}
            if(radiationRaw)    {radiation()->setRawValue(radiationRaw);}
            if(battRaw)         {batt()->setRawValue(battRaw);}

            status()->setRawValue(tunnel.payload_type);
            break;
        }
        case 301: {
            // sid 방사능 데이터 특수 케이스
            struct Sensor_Tunnel_Legacy tL;

            memcpy(&tL, &tunnel.payload, sizeof(tL));

            float radiationRaw  = tL.sensor4;

            if(radiationRaw)    {radiation()->setRawValue(radiationRaw);}

            status()->setRawValue(tunnel.payload_type);
            break;
        }
    }
}

void AtmosphericSensorFactGroup::_handleWind(const mavlink_message_t &message)
{
    mavlink_wind_t wind{};
    mavlink_msg_wind_decode(&message, &wind);

            // We don't want negative wind angles
    float windDirection = wind.direction;
    if (message.compid != 1) {
        if (windDirection < 0) {
            windDirection += 360;
        }
        windDir()->setRawValue(windDirection);
        windSpd()->setRawValue(wind.speed);
        //windVSpd()->setRawValue(wind.speed_z);

        _windDirByWindPacket = true;

        _setTelemetryAvailable(true);
    }
}
