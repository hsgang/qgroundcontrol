#include "ExternalPowerStatusFactGroup.h"
#include "Vehicle.h"

#include <QtMath>

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
    : FactGroup(1000, ":/json/Vehicle/ExternalPowerStatusFactGroup.json", parent)
{
    _addFact(&_acInputVolatage1Fact);
    _addFact(&_acInputVolatage2Fact);
    _addFact(&_acInputVolatage3Fact);
    _addFact(&_dcOutputVolatage1Fact);
    _addFact(&_dcOutputVolatage2Fact);
    _addFact(&_dcOutputVolatage3Fact);
    _addFact(&_dcOutputCurrent1Fact);
    _addFact(&_dcOutputCurrent2Fact);
    _addFact(&_dcOutputCurrent3Fact);
    _addFact(&_temperatureFact);
    _addFact(&_batteryVoltageFact);
    _addFact(&_batteryChangeFact);

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

void ExternalPowerStatusFactGroup::handleMessage(Vehicle* vehicle, const mavlink_message_t& message)
{
    switch (message.msgid) {
    case MAVLINK_MSG_ID_TUNNEL:
         _handleExternalPowerStatus(message);
        break;
    default:
        break;
    }
}

void ExternalPowerStatusFactGroup::_handleExternalPowerStatus(const mavlink_message_t &message)
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

