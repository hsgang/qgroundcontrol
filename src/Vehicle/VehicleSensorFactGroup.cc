/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "VehicleSensorFactGroup.h"
#include "Vehicle.h"

#include <QtMath>

const char* VehicleSensorFactGroup::_sensorTempFactName =       "sensorTemp";
const char* VehicleSensorFactGroup::_sensorHumiFactName =       "sensorHumi";
const char* VehicleSensorFactGroup::_sensorBaroFactName =       "sensorBaro";
const char* VehicleSensorFactGroup::_sensorWindDirFactName =    "sensorWindDir";
const char* VehicleSensorFactGroup::_sensorWindSpdFactName =    "sensorWindSpd";
const char* VehicleSensorFactGroup::_sensorPM1p0FactName =      "sensorPM1p0";
const char* VehicleSensorFactGroup::_sensorPM2p5FactName =      "sensorPM2p5";
const char* VehicleSensorFactGroup::_sensorPM10FactName =       "sensorPM10";
const char* VehicleSensorFactGroup::_sensorStatusFactName =     "sensorStatus";
const char* VehicleSensorFactGroup::_sensorCountFactName =      "sensorCount";

struct sensor_data32_Payload {
    float sensorCountRaw;
    float sensorTempRaw;
    float sensorHumiRaw;
    float sensorBaroRaw;
    uint16_t sensorPM1p0Raw;
    uint16_t sensorPM2p5Raw;
    uint16_t sensorPM10Raw;
};

VehicleSensorFactGroup::VehicleSensorFactGroup(QObject* parent)
    : FactGroup(1000, ":/json/Vehicle/SensorFact.json", parent)
    , _sensorTempFact    (0, _sensorTempFactName,       FactMetaData::valueTypeDouble)
    , _sensorHumiFact    (0, _sensorHumiFactName,       FactMetaData::valueTypeDouble)
    , _sensorBaroFact    (0, _sensorBaroFactName,       FactMetaData::valueTypeDouble)
    , _sensorWindDirFact (0, _sensorWindDirFactName,    FactMetaData::valueTypeDouble)
    , _sensorWindSpdFact (0, _sensorWindSpdFactName,    FactMetaData::valueTypeDouble)
    , _sensorPM1p0Fact   (0, _sensorPM1p0FactName,      FactMetaData::valueTypeUint16)
    , _sensorPM2p5Fact   (0, _sensorPM2p5FactName,      FactMetaData::valueTypeUint16)
    , _sensorPM10Fact    (0, _sensorPM10FactName,       FactMetaData::valueTypeUint16)
    , _sensorStatusFact  (0, _sensorStatusFactName,     FactMetaData::valueTypeUint8)
    , _sensorCountFact   (0, _sensorCountFactName,      FactMetaData::valueTypeDouble)
{
    _addFact(&_sensorTempFact,          _sensorTempFactName);
    _addFact(&_sensorHumiFact,          _sensorHumiFactName);
    _addFact(&_sensorBaroFact,          _sensorBaroFactName);
    _addFact(&_sensorWindDirFact,       _sensorWindDirFactName);
    _addFact(&_sensorWindSpdFact,       _sensorWindSpdFactName);
    _addFact(&_sensorPM1p0Fact,         _sensorPM1p0FactName);
    _addFact(&_sensorPM2p5Fact,         _sensorPM2p5FactName);
    _addFact(&_sensorPM10Fact,          _sensorPM10FactName);
    _addFact(&_sensorStatusFact,        _sensorStatusFactName);
    _addFact(&_sensorCountFact,         _sensorCountFactName);

    // Start out as not available "--.--"
    _sensorTempFact.setRawValue      (qQNaN());
    _sensorHumiFact.setRawValue      (qQNaN());
    _sensorBaroFact.setRawValue      (qQNaN());
    _sensorWindDirFact.setRawValue   (qQNaN());
    _sensorWindSpdFact.setRawValue   (qQNaN());
    _sensorPM1p0Fact.setRawValue     (qQNaN());
    _sensorPM2p5Fact.setRawValue     (qQNaN());
    _sensorPM10Fact.setRawValue      (qQNaN());
    _sensorStatusFact.setRawValue    (qQNaN());
    _sensorCountFact.setRawValue     (qQNaN());
}

void VehicleSensorFactGroup::handleMessage(Vehicle* /* vehicle */, mavlink_message_t& message)
{
    switch (message.msgid) {
    case MAVLINK_MSG_ID_V2_EXTENSION:
//        _handleV2_extension(message);
        break;
    case MAVLINK_MSG_ID_DATA32:
        if(message.compid == 158){
         _handleData32(message);
        }
        break;
    case MAVLINK_MSG_ID_SCALED_PRESSURE:
        //_handleScaledPressure(message);
        break;
#if !defined(NO_ARDUPILOT_DIALECT)
    case MAVLINK_MSG_ID_WIND:
        if(message.compid == 158){
        _handleWind(message);
        }
        break;
#endif
    }
}

void VehicleSensorFactGroup::_handleData32(mavlink_message_t &message)
{
    mavlink_data32_t data32;
    mavlink_msg_data32_decode(&message, &data32);

    struct sensor_data32_Payload sP;

    memcpy(&sP, &data32.data, sizeof (struct sensor_data32_Payload));

    float sensorCountRaw = sP.sensorCountRaw;
    float sensorTempRaw     = sP.sensorTempRaw;
    float sensorHumiRaw     = sP.sensorHumiRaw;
    float sensorBaroRaw     = sP.sensorBaroRaw;
    uint16_t sensorPM1p0Raw = sP.sensorPM1p0Raw;
    uint16_t sensorPM2p5Raw = sP.sensorPM2p5Raw;
    uint16_t sensorPM10Raw  = sP.sensorPM10Raw;

    /*
    double sensorTempRaw = v2_extension.payload[0]+v2_extension.payload[1];
    double sensorHumiRaw = v2_extension.payload[2]+v2_extension.payload[3];
    double sensorBaroRaw = v2_extension.payload[4]+v2_extension.payload[5];
    double sensorWindDirRaw = v2_extension.payload[6]+v2_extension.payload[7];
    double sensorWindSpdRaw = v2_extension.payload[8]+v2_extension.payload[9];
*/
    sensorCount()->setRawValue(sensorCountRaw);
    sensorTemp()->setRawValue(sensorTempRaw);
    sensorHumi()->setRawValue(sensorHumiRaw);
    sensorBaro()->setRawValue(sensorBaroRaw);
    sensorPM1p0()->setRawValue(sensorPM1p0Raw);
    sensorPM2p5()->setRawValue(sensorPM2p5Raw);
    sensorPM10()->setRawValue(sensorPM10Raw);

    sensorStatus()->setRawValue(data32.type);
}

void VehicleSensorFactGroup::_handleScaledPressure(mavlink_message_t &message)
{
    mavlink_scaled_pressure_t pressure;
    mavlink_msg_scaled_pressure_decode(&message, &pressure);
    sensorBaro()->setRawValue(pressure.press_abs);
    _setTelemetryAvailable(true);
}

void VehicleSensorFactGroup::_handleWind(mavlink_message_t &message)
{
    mavlink_wind_t wind;
    mavlink_msg_wind_decode(&message, &wind);
    sensorWindDir()->setRawValue(wind.direction);
    sensorWindSpd()->setRawValue(wind.speed);
}

//void VehicleSensorFactGroup::_handleV2_extension(mavlink_message_t &message)
//{
//    mavlink_v2_extension_t v2_extension;
//    mavlink_msg_v2_extension_decode(&message, &v2_extension);

//    struct sensorPayload sP;

//    memcpy(&sP, &v2_extension.payload, sizeof (struct sensorPayload));

//    float sensorTempRaw = sP.sensorTempRaw;
//    float sensorHumiRaw = sP.sensorHumiRaw;
//    float sensorBaroRaw = sP.sensorBaroRaw;
//    float sensorWindDirRaw = sP.sensorWindDirRaw;
//    float sensorWindSpdRaw = sP.sensorWindSpdRaw;

//    /*
//    double sensorTempRaw = v2_extension.payload[0]+v2_extension.payload[1];
//    double sensorHumiRaw = v2_extension.payload[2]+v2_extension.payload[3];
//    double sensorBaroRaw = v2_extension.payload[4]+v2_extension.payload[5];
//    double sensorWindDirRaw = v2_extension.payload[6]+v2_extension.payload[7];
//    double sensorWindSpdRaw = v2_extension.payload[8]+v2_extension.payload[9];
//*/
//    sensorTemp()->setRawValue(sensorTempRaw);
//    sensorHumi()->setRawValue(sensorHumiRaw);
//    sensorBaro()->setRawValue(sensorBaroRaw);
//    sensorWindDir()->setRawValue(sensorWindDirRaw);
//    sensorWindSpd()->setRawValue(sensorWindSpdRaw);

//}
