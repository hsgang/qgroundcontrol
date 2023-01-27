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
    : FactGroup(1000, ":/json/Vehicle/GeneratorStatusFactGroup.json", parent)
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
    , _batteryChangeFact        (0, _batteryChangeFactName,         FactMetaData::valueTypeInt8)
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
    _acInputVolatage1Fact.setRawValue       (qQNaN());
    _acInputVolatage2Fact.setRawValue       (qQNaN());
    _acInputVolatage3Fact.setRawValue       (qQNaN());
    _dcOutputVolatage1Fact.setRawValue      (qQNaN());
    _dcOutputVolatage2Fact.setRawValue      (qQNaN());
    _dcOutputVolatage3Fact.setRawValue      (qQNaN());
    _dcOutputCurrent1Fact.setRawValue       (qQNaN());
    _dcOutputCurrent2Fact.setRawValue       (qQNaN());
    _dcOutputCurrent3Fact.setRawValue       (qQNaN());
    _temperatureFact.setRawValue            (qQNaN());
    _batteryVoltageFact.setRawValue         (qQNaN());
    _batteryChangeFact.setRawValue          (qQNaN());
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

        float acInputVolt1Raw   = eP.acInputVolt1 * 0.1;
        float acInputVolt2Raw   = eP.acInputVolt2 * 0.1;
        float acInputVolt3Raw   = eP.acInputVolt3 * 0.1;
        float dcOutVolt1Raw     = eP.dcOutVolt1 * 0.1;
        float dcOutVolt2Raw     = eP.dcOutVolt2 * 0.1;
        float dcOutVolt3Raw     = eP.dcOutVolt3 * 0.1;
        float dcOutCurr1Raw     = eP.dcOutCurr1 * 0.1;
        float dcOutCurr2Raw     = eP.dcOutCurr2 * 0.1;
        float dcOutCurr3Raw     = eP.dcOutCurr3 * 0.1;
        float temperatureRaw    = eP.temperature * 0.1;
        float battVoltRaw       = eP.battVolt * 0.1;
        float battChangeRaw     = eP.battChange * 0.1;

        acInputVolatage1()->setRawValue(acInputVolt1Raw);
        acInputVolatage2()->setRawValue(acInputVolt2Raw);
        acInputVolatage3()->setRawValue(acInputVolt3Raw);
        dcOutputVolatage1()->setRawValue(dcOutVolt1Raw);
        dcOutputVolatage2()->setRawValue(dcOutVolt2Raw);
        dcOutputVolatage3()->setRawValue(dcOutVolt3Raw);
        dcOutputCurrent1()->setRawValue(dcOutCurr1Raw);
        dcOutputCurrent2()->setRawValue(dcOutCurr2Raw);
        dcOutputCurrent3()->setRawValue(dcOutCurr3Raw);
        temperature()->setRawValue(temperatureRaw);
        batteryVoltage()->setRawValue(battVoltRaw);
        batteryChange()->setRawValue(battChangeRaw);
    }
}

