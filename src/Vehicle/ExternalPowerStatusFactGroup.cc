#include "ExternalPowerStatusFactGroup.h"
#include "Vehicle.h"

#include <QtMath>

const char* ExternalPowerStatusFactGroup::_acInputVolatage1FactName =  "acInputVolatage1";
const char* ExternalPowerStatusFactGroup::_acInputVolatage2FactName =  "acInputVolatage2";
const char* ExternalPowerStatusFactGroup::_acInputVolatage3FactName =  "acInputVolatage3";
const char* ExternalPowerStatusFactGroup::_dcOutputVolatage1FactName = "dcOutputVolatage1";
const char* ExternalPowerStatusFactGroup::_dcOutputVolatage2FactName = "dcOutputVolatage2";
const char* ExternalPowerStatusFactGroup::_dcOutputVolatage3FactName = "dcOutputVolatage3";
const char* ExternalPowerStatusFactGroup::_dcOutputCurrent1FactName =  "dcOutputCurrent1";
const char* ExternalPowerStatusFactGroup::_dcOutputCurrent2FactName =  "dcOutputCurrent2";
const char* ExternalPowerStatusFactGroup::_dcOutputCurrent3FactName =  "dcOutputCurrent3";
const char* ExternalPowerStatusFactGroup::_temperatureFactName =       "temperature";
const char* ExternalPowerStatusFactGroup::_batteryVoltageFactName =    "batteryVoltage";
const char* ExternalPowerStatusFactGroup::_batteryChangeFactName =     "batteryChange";

struct externalPower_Payload {
    uint16_t acInputVolt1;
    uint16_t acInputVolt2;
    uint16_t acInputVolt3;
    uint16_t dcOutVolt1;
    uint16_t dcOutVolt2;
    uint16_t dcOutVolt3;
    uint16_t dcOutCurr1;
    uint16_t dcOutCurr2;
    uint16_t dcOutCurr3;
    uint16_t temperature;
    uint16_t battVolt;
    uint16_t battChange;
};

ExternalPowerStatusFactGroup::ExternalPowerStatusFactGroup(QObject* parent)
    : FactGroup(250, ":/json/Vehicle/ExternalPowerStatusFactGroup.json", parent)
    , _acInputVolatage1Fact     (0, _acInputVolatage1FactName,      FactMetaData::valueTypeFloat)
    , _acInputVolatage2Fact     (0, _acInputVolatage2FactName,      FactMetaData::valueTypeFloat)
    , _acInputVolatage3Fact     (0, _acInputVolatage3FactName,      FactMetaData::valueTypeFloat)
    , _dcOutputVolatage1Fact    (0, _dcOutputVolatage1FactName,     FactMetaData::valueTypeFloat)
    , _dcOutputVolatage2Fact    (0, _dcOutputVolatage2FactName,     FactMetaData::valueTypeFloat)
    , _dcOutputVolatage3Fact    (0, _dcOutputVolatage3FactName,     FactMetaData::valueTypeFloat)
    , _dcOutputCurrent1Fact     (0, _dcOutputCurrent1FactName,      FactMetaData::valueTypeFloat)
    , _dcOutputCurrent2Fact     (0, _dcOutputCurrent2FactName,      FactMetaData::valueTypeFloat)
    , _dcOutputCurrent3Fact     (0, _dcOutputCurrent3FactName,      FactMetaData::valueTypeFloat)
    , _temperatureFact          (0, _temperatureFactName,           FactMetaData::valueTypeFloat)
    , _batteryVoltageFact       (0, _temperatureFactName,           FactMetaData::valueTypeFloat)
    , _batteryChangeFact        (0, _batteryChangeFactName,         FactMetaData::valueTypeUint8)
{
    _addFact(&_acInputVolatage1Fact,      _acInputVolatage1FactName);
    _addFact(&_acInputVolatage2Fact,      _acInputVolatage2FactName);
    _addFact(&_acInputVolatage3Fact,      _acInputVolatage3FactName);
    _addFact(&_dcOutputVolatage1Fact,     _dcOutputVolatage1FactName);
    _addFact(&_dcOutputVolatage2Fact,     _dcOutputVolatage2FactName);
    _addFact(&_dcOutputVolatage3Fact,     _dcOutputVolatage3FactName);
    _addFact(&_dcOutputCurrent1Fact,      _dcOutputCurrent1FactName);
    _addFact(&_dcOutputCurrent2Fact,      _dcOutputCurrent2FactName);
    _addFact(&_dcOutputCurrent3Fact,      _dcOutputCurrent3FactName);
    _addFact(&_temperatureFact,           _temperatureFactName);
    _addFact(&_batteryVoltageFact,        _batteryVoltageFactName);
    _addFact(&_batteryChangeFact,         _batteryChangeFactName);

    // Start out as not available "--.--"
    _acInputVolatage1Fact.setRawValue       (std::numeric_limits<float>::quiet_NaN());
    _acInputVolatage2Fact.setRawValue       (std::numeric_limits<float>::quiet_NaN());
    _acInputVolatage3Fact.setRawValue       (std::numeric_limits<float>::quiet_NaN());
    _dcOutputVolatage1Fact.setRawValue      (std::numeric_limits<float>::quiet_NaN());
    _dcOutputVolatage2Fact.setRawValue      (std::numeric_limits<float>::quiet_NaN());
    _dcOutputVolatage3Fact.setRawValue      (std::numeric_limits<float>::quiet_NaN());
    _dcOutputCurrent1Fact.setRawValue       (std::numeric_limits<float>::quiet_NaN());
    _dcOutputCurrent2Fact.setRawValue       (std::numeric_limits<float>::quiet_NaN());
    _dcOutputCurrent3Fact.setRawValue       (std::numeric_limits<float>::quiet_NaN());
    _temperatureFact.setRawValue            (std::numeric_limits<float>::quiet_NaN());
    _batteryVoltageFact.setRawValue         (std::numeric_limits<float>::quiet_NaN());
//    _batteryChangeFact.setRawValue          (qQNaN());
}

void ExternalPowerStatusFactGroup::handleMessage(Vehicle* vehicle, mavlink_message_t& message)
{
    switch (message.msgid) {
    case MAVLINK_MSG_ID_TUNNEL:
         _handleExternalPowerStatus(message);
        break;
    default:
        break;
    }
}

void ExternalPowerStatusFactGroup::_handleExternalPowerStatus(mavlink_message_t &message)
{
    mavlink_tunnel_t extPower;
    mavlink_msg_tunnel_decode(&message, &extPower);

    if(extPower.payload_type == 500){
        struct externalPower_Payload eP;

        memcpy(&eP, &extPower.payload, sizeof(eP));

        acInputVolatage1()->setRawValue(float(eP.acInputVolt1 * 0.1));
        acInputVolatage2()->setRawValue(float(eP.acInputVolt2 * 0.1));
        acInputVolatage3()->setRawValue(float(eP.acInputVolt3 * 0.1));
        dcOutputVolatage1()->setRawValue(float(eP.dcOutVolt1 * 0.1));
        dcOutputVolatage2()->setRawValue(float(eP.dcOutVolt2 * 0.1));
        dcOutputVolatage3()->setRawValue(float(eP.dcOutVolt3 * 0.1));
        dcOutputCurrent1()->setRawValue(float(eP.dcOutCurr1 * 0.1) * 2);
        dcOutputCurrent2()->setRawValue(float(eP.dcOutCurr2 * 0.1) * 2);
        dcOutputCurrent3()->setRawValue(float(eP.dcOutCurr3 * 0.1) * 2);
        temperature()->setRawValue(float(eP.temperature * 0.1));
        batteryVoltage()->setRawValue(float(eP.battVolt * 0.1));
        batteryChange()->setRawValue(uint8_t(eP.battChange * 0.1));
    }
}

