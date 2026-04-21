#include "AtmosphericSensorFactGroup.h"
#include "Vehicle.h"

#include <QtMath>
#include <QDateTime>
#include <cstring>

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
    quint64 unixTimeRaw;
    float sdVolumeRaw;
    uint8_t _pad[4];
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
    uint16_t _pad;
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

struct Tunnel_AWS_Ex {
    float logCount;
    float temp;
    float humi;
    float pres;
    float windDir;
    float windSpd;
    float hubTemp1;
    float hubTemp2;
    float hubHumi1;
    float hubHumi2;
    float hubPressure;
    float opc1;
    float opc2;
    float opc3;
    float radiation;
    float batt;
    uint64_t unixTime;
    float sdVolume;
    uint8_t windRef;
    uint8_t _pad[3];
};
static_assert(sizeof(Tunnel_AWS_Ex) == 80, "Tunnel_AWS_Ex layout must match firmware");

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
    _addFact(&_unixTimeFact);
    _addFact(&_timeHMSFact);
    _addFact(&_sdVolumeFact);
    _addFact(&_windRefFact);

    // Start out as not available "--.--"
    _logCountFact.setRawValue    (qQNaN());
    _temperatureFact.setRawValue (qQNaN());
    _humidityFact.setRawValue    (qQNaN());
    _pressureFact.setRawValue    (qQNaN());
    _windDirFact.setRawValue     (qQNaN());
    _windSpdFact.setRawValue     (qQNaN());
    _hubTemp1Fact.setRawValue    (qQNaN());
    _hubTemp2Fact.setRawValue    (qQNaN());
    _hubHumi1Fact.setRawValue    (qQNaN());
    _hubHumi2Fact.setRawValue    (qQNaN());
    _hubPressureFact.setRawValue (qQNaN());
    _opc1Fact.setRawValue        (qQNaN());
    _opc2Fact.setRawValue        (qQNaN());
    _opc3Fact.setRawValue        (qQNaN());
    _radiationFact.setRawValue   (qQNaN());
    _battFact.setRawValue        (qQNaN());
    _sdVolumeFact.setRawValue    (qQNaN());
}

void AtmosphericSensorFactGroup::handleMessage(Vehicle *vehicle, const mavlink_message_t &message)
{
    Q_UNUSED(vehicle)

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
    quint64 unixTimeRaw   = sP.unixTimeRaw;
    float sdVolumeRaw     = sP.sdVolumeRaw;

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
    if(unixTimeRaw > 0) {
        unixTime()->setRawValue(unixTimeRaw);
        QDateTime dateTime = QDateTime::fromSecsSinceEpoch(static_cast<qint64>(unixTimeRaw));
        QString timeString = dateTime.toString("hh:mm:ss");
        timeHMS()->setRawValue(timeString);
    }
    if(!qIsNaN(sdVolumeRaw)) {
        sdVolume()->setRawValue(sdVolumeRaw);
    }

    status()->setRawValue(data32.type);
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

            float tempRaw = sC.temperatureRaw * 0.01f;
            float humiRaw = sC.humidityRaw * 0.01f;
            float pressRaw = sC.pressureRaw;
            float windDRaw = sC.windHeadingRaw;
            float windSRaw = sC.windSpeedRaw * 0.1f;
            float opc1Raw = sC.pm1p0Raw * 0.1f;
            float opc2Raw = sC.pm2p5Raw * 0.1f;
            float opc3Raw = sC.pm10Raw * 0.1f;

            if(!qIsNaN(tempRaw))    {temperature()->setRawValue(tempRaw);}
            if(!qIsNaN(humiRaw))    {humidity()->setRawValue(humiRaw);}
            if(!qIsNaN(pressRaw))   {pressure()->setRawValue(pressRaw);}
            if(!qIsNaN(windDRaw) && !_windDirByWindPacket)    {windDir()->setRawValue(windDRaw);}
            if(!qIsNaN(windSRaw) && !_windDirByWindPacket)    {windSpd()->setRawValue(windSRaw);}
            if(!qIsNaN(opc1Raw))    {opc1()->setRawValue(opc1Raw);}
            if(!qIsNaN(opc2Raw))    {opc2()->setRawValue(opc2Raw);}
            if(!qIsNaN(opc3Raw))    {opc3()->setRawValue(opc3Raw);}

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
            quint64 unixTimeRaw     = tP.unixTimeRaw;
            float sdVolumeRaw       = tP.sdVolumeRaw;

            if(!qIsNaN(logCountRaw))     {logCount()->setRawValue(logCountRaw);}
            if(!qIsNaN(temperatureRaw))  {temperature()->setRawValue(temperatureRaw);}
            if(!qIsNaN(humidityRaw))     {humidity()->setRawValue(humidityRaw);}
            if(!qIsNaN(pressureRaw))     {pressure()->setRawValue(pressureRaw);}
            if(!qIsNaN(windDirRaw) && !_windDirByWindPacket)      {windDir()->setRawValue(windDirRaw);}
            if(!qIsNaN(windSpdRaw) && !_windDirByWindPacket)      {windSpd()->setRawValue(windSpdRaw);}
            if(!qIsNaN(hubTemp1Raw))     {hubTemp1()->setRawValue(hubTemp1Raw);}
            if(!qIsNaN(hubTemp2Raw))     {hubTemp2()->setRawValue(hubTemp2Raw);}
            if(!qIsNaN(hubHumi1Raw))     {hubHumi1()->setRawValue(hubHumi1Raw);}
            if(!qIsNaN(hubHumi2Raw))     {hubHumi2()->setRawValue(hubHumi2Raw);}
            if(!qIsNaN(hubPressureRaw))  {hubPressure()->setRawValue(hubPressureRaw);}
            if(!qIsNaN(opc1Raw))         {opc1()->setRawValue(opc1Raw);}
            if(!qIsNaN(opc2Raw))         {opc2()->setRawValue(opc2Raw);}
            if(!qIsNaN(opc3Raw))         {opc3()->setRawValue(opc3Raw);}
            if(!qIsNaN(radiationRaw))    {radiation()->setRawValue(radiationRaw);}
            if(!qIsNaN(battRaw))         {batt()->setRawValue(battRaw);}
            if(unixTimeRaw != 0)         {
                unixTime()->setRawValue(unixTimeRaw);
                QDateTime dateTime = QDateTime::fromSecsSinceEpoch(static_cast<qint64>(unixTimeRaw));
                QString timeString = dateTime.toString("hh:mm:ss");
                timeHMS()->setRawValue(timeString);
            }
            if(!qIsNaN(sdVolumeRaw))     {sdVolume()->setRawValue(sdVolumeRaw);}

            status()->setRawValue(tunnel.payload_type);
            break;
        }
        case 301: {
            // sid 방사능 데이터 특수 케이스
            struct Sensor_Tunnel_Legacy tL;

            memcpy(&tL, &tunnel.payload, sizeof(tL));

            float radiationRaw  = tL.sensor4;

            if(radiationRaw != 0.0f)    {radiation()->setRawValue(radiationRaw);}

            status()->setRawValue(tunnel.payload_type);
            break;
        }
        case 302: {
            struct Tunnel_AWS_Ex tE;

            memcpy(&tE, &tunnel.payload, sizeof(tE));

            float logCountRaw       = tE.logCount;
            float temperatureRaw    = tE.temp;
            float humidityRaw       = tE.humi;
            float pressureRaw       = tE.pres;
            float windDirRaw        = tE.windDir;
            float windSpdRaw        = tE.windSpd;
            float hubTemp1Raw       = tE.hubTemp1;
            float hubTemp2Raw       = tE.hubTemp2;
            float hubHumi1Raw       = tE.hubHumi1;
            float hubHumi2Raw       = tE.hubHumi2;
            float hubPressureRaw    = tE.hubPressure;
            float opc1Raw           = tE.opc1;
            float opc2Raw           = tE.opc2;
            float opc3Raw           = tE.opc3;
            float radiationRaw      = tE.radiation;
            float battRaw           = tE.batt;
            quint64 unixTimeRaw     = tE.unixTime;
            float sdVolumeRaw       = tE.sdVolume;

            // Firmware sends 0=N, 1=R, 2=T directly
            uint8_t windRefNorm = (tE.windRef <= 2) ? tE.windRef : 0;
            windRef()->setRawValue(windRefNorm);

            if(!qIsNaN(logCountRaw))     {logCount()->setRawValue(logCountRaw);}
            if(!qIsNaN(temperatureRaw))  {temperature()->setRawValue(temperatureRaw);}
            if(!qIsNaN(humidityRaw))     {humidity()->setRawValue(humidityRaw);}
            if(!qIsNaN(pressureRaw))     {pressure()->setRawValue(pressureRaw);}
            if(!qIsNaN(windDirRaw) && !_windDirByWindPacket)      {windDir()->setRawValue(windDirRaw);}
            if(!qIsNaN(windSpdRaw) && !_windDirByWindPacket)      {windSpd()->setRawValue(windSpdRaw);}
            if(!qIsNaN(hubTemp1Raw))     {hubTemp1()->setRawValue(hubTemp1Raw);}
            if(!qIsNaN(hubTemp2Raw))     {hubTemp2()->setRawValue(hubTemp2Raw);}
            if(!qIsNaN(hubHumi1Raw))     {hubHumi1()->setRawValue(hubHumi1Raw);}
            if(!qIsNaN(hubHumi2Raw))     {hubHumi2()->setRawValue(hubHumi2Raw);}
            if(!qIsNaN(hubPressureRaw))  {hubPressure()->setRawValue(hubPressureRaw);}
            if(!qIsNaN(opc1Raw))         {opc1()->setRawValue(opc1Raw);}
            if(!qIsNaN(opc2Raw))         {opc2()->setRawValue(opc2Raw);}
            if(!qIsNaN(opc3Raw))         {opc3()->setRawValue(opc3Raw);}
            if(!qIsNaN(radiationRaw))    {radiation()->setRawValue(radiationRaw);}
            if(!qIsNaN(battRaw))         {batt()->setRawValue(battRaw);}
            if(unixTimeRaw != 0)         {
                unixTime()->setRawValue(unixTimeRaw);
                QDateTime dateTime = QDateTime::fromSecsSinceEpoch(static_cast<qint64>(unixTimeRaw));
                QString timeString = dateTime.toString("hh:mm:ss");
                timeHMS()->setRawValue(timeString);
            }
            if(!qIsNaN(sdVolumeRaw))     {sdVolume()->setRawValue(sdVolumeRaw);}

            status()->setRawValue(tunnel.payload_type);
            break;
        }
        default:
            break;
    }
}

void AtmosphericSensorFactGroup::_handleWind(const mavlink_message_t &message)
{
    mavlink_wind_t wind;
    memset(&wind, 0, sizeof(wind));
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
