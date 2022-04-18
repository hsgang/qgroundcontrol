#include "VehicleLandingTargetFactGroup.h"
#include "Vehicle.h"

const char* VehicleLandingTargetFactGroup::_angleXFactName = "angleX";
const char* VehicleLandingTargetFactGroup::_angleYFactName = "angleY";

VehicleLandingTargetFactGroup::VehicleLandingTargetFactGroup(QObject* parent)
    : FactGroup             (200, ":/json/Vehicle/LandingTargetFactGroup.json", parent)
    , _angleXFact     (0, _angleXFactName,      FactMetaData::valueTypeDouble)
    , _angleYFact     (0, _angleYFactName,      FactMetaData::valueTypeDouble)
{
    _addFact(&_angleXFact,        _angleXFactName);
    _addFact(&_angleYFact,        _angleYFactName);
}

void VehicleLandingTargetFactGroup::handleMessage(Vehicle* /* vehicle */, mavlink_message_t& message)
{
    switch (message.msgid) {
    case MAVLINK_MSG_ID_LANDING_TARGET:
        _handleLandingTarget(message);
        break;
    default:
        break;
    }
}

void VehicleLandingTargetFactGroup::_handleLandingTarget(mavlink_message_t &message)
{
    mavlink_landing_target_t landingtarget;
    mavlink_msg_landing_target_decode(&message, &landingtarget);

    angleX()->setRawValue(landingtarget.angle_x);
    angleY()->setRawValue(landingtarget.angle_y);
}
