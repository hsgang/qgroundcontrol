#include "VehicleLandingTargetFactGroup.h"
#include "Vehicle.h"

const char* VehicleLandingTargetFactGroup::_targetNumFactName       = "targetNum";
const char* VehicleLandingTargetFactGroup::_angleXFactName          = "angleX";
const char* VehicleLandingTargetFactGroup::_angleYFactName          = "angleY";
const char* VehicleLandingTargetFactGroup::_distanceFactName        = "distance";
const char* VehicleLandingTargetFactGroup::_sizeXFactName           = "sizeX";
const char* VehicleLandingTargetFactGroup::_sizeYFactName           = "sizeY";
const char* VehicleLandingTargetFactGroup::_xFactName               = "x";
const char* VehicleLandingTargetFactGroup::_yFactName               = "y";
const char* VehicleLandingTargetFactGroup::_zFactName               = "z";
const char* VehicleLandingTargetFactGroup::_qFactName               = "q";
const char* VehicleLandingTargetFactGroup::_typeFactName            = "type";
const char* VehicleLandingTargetFactGroup::_positionValidFactName   = "postionValid";

VehicleLandingTargetFactGroup::VehicleLandingTargetFactGroup(QObject* parent)
    : FactGroup             (200, ":/json/Vehicle/LandingTargetFactGroup.json", parent)
    , _targetNumFact        (0, _targetNumFactName,     FactMetaData::valueTypeUint8)
    , _angleXFact           (0, _angleXFactName,        FactMetaData::valueTypeDouble)
    , _angleYFact           (0, _angleYFactName,        FactMetaData::valueTypeDouble)
    , _distanceFact         (0, _distanceFactName,      FactMetaData::valueTypeDouble)
    , _sizeXFact            (0, _sizeXFactName,         FactMetaData::valueTypeDouble)
    , _sizeYFact            (0, _sizeYFactName,         FactMetaData::valueTypeDouble)
    , _xFact                (0, _xFactName,             FactMetaData::valueTypeDouble)
    , _yFact                (0, _yFactName,             FactMetaData::valueTypeDouble)
    , _zFact                (0, _zFactName,             FactMetaData::valueTypeDouble)
    , _qFact                (0, _qFactName,             FactMetaData::valueTypeDouble)
    , _typeFact             (0, _typeFactName,          FactMetaData::valueTypeUint8)
    , _positionValidFact    (0, _positionValidFactName, FactMetaData::valueTypeUint8)
{
    _addFact(&_targetNumFact,       _targetNumFactName);
    _addFact(&_angleXFact,          _angleXFactName);
    _addFact(&_angleYFact,          _angleYFactName);
    _addFact(&_distanceFact,        _distanceFactName);
    _addFact(&_sizeXFact,           _sizeXFactName);
    _addFact(&_sizeYFact,           _sizeYFactName);
    _addFact(&_xFact,               _xFactName);
    _addFact(&_yFact,               _yFactName);
    _addFact(&_zFact,               _zFactName);
    _addFact(&_qFact,               _qFactName);
    _addFact(&_typeFact,            _typeFactName);
    _addFact(&_positionValidFact,   _positionValidFactName);
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

    targetNum()->setRawValue(landingtarget.target_num);
    angleX()->setRawValue(landingtarget.angle_x);
    angleY()->setRawValue(landingtarget.angle_y);
    distance()->setRawValue(landingtarget.distance);
    positionValid()->setRawValue(landingtarget.position_valid);
}
