/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "VehicleEKFStatusFactGroup.h"
#include "Vehicle.h"

const char* VehicleEKFStatusFactGroup::_flagsFactName =                 "flags";
const char* VehicleEKFStatusFactGroup::_velocity_varianceFactName =     "velocity_variance";
const char* VehicleEKFStatusFactGroup::_pos_horiz_varianceFactName =    "pos_horiz_variance";
const char* VehicleEKFStatusFactGroup::_pos_vert_varianceFactName =     "pos_vert_variance";
const char* VehicleEKFStatusFactGroup::_compass_varianceFactName =      "compass_variance";
const char* VehicleEKFStatusFactGroup::_terrain_alt_varianceFactName =  "terrain_alt_variance";
const char* VehicleEKFStatusFactGroup::_airspeed_varianceFactName =     "airspeed_variance";

VehicleEKFStatusFactGroup::VehicleEKFStatusFactGroup(QObject* parent)
    : FactGroup         (1000, ":/json/Vehicle/EKFStatusFact.json", parent)
    , _flagsFact                (0, _flagsFactName,                 FactMetaData::valueTypeUint16)
    , _velocity_varianceFact    (0, _velocity_varianceFactName,     FactMetaData::valueTypeDouble)
    , _pos_horiz_varianceFact   (0, _pos_horiz_varianceFactName,    FactMetaData::valueTypeDouble)
    , _pos_vert_varianceFact    (0, _pos_vert_varianceFactName,     FactMetaData::valueTypeDouble)
    , _compass_varianceFact     (0, _compass_varianceFactName,      FactMetaData::valueTypeDouble)
    , _terrain_alt_varianceFact (0, _terrain_alt_varianceFactName,  FactMetaData::valueTypeDouble)
    , _airspeed_varianceFact    (0, _airspeed_varianceFactName,     FactMetaData::valueTypeDouble)
{
    _addFact(&_flagsFact,                   _flagsFactName);
    _addFact(&_velocity_varianceFact,       _velocity_varianceFactName);
    _addFact(&_pos_horiz_varianceFact,      _pos_horiz_varianceFactName);
    _addFact(&_pos_vert_varianceFact,       _pos_vert_varianceFactName);
    _addFact(&_compass_varianceFact,        _compass_varianceFactName);
    _addFact(&_terrain_alt_varianceFact,    _terrain_alt_varianceFactName);
    _addFact(&_airspeed_varianceFact,       _airspeed_varianceFactName);

    // Start out as not available "--.--"
    _velocity_varianceFact.setRawValue(qQNaN());
    _pos_horiz_varianceFact.setRawValue(qQNaN());
    _pos_vert_varianceFact.setRawValue(qQNaN());
    _compass_varianceFact.setRawValue(qQNaN());
    _terrain_alt_varianceFact.setRawValue(qQNaN());
    _airspeed_varianceFact.setRawValue(qQNaN());
}

void VehicleEKFStatusFactGroup::handleMessage(Vehicle* /* vehicle */, mavlink_message_t& message)
{
    if (message.msgid != MAVLINK_MSG_ID_EKF_STATUS_REPORT) {
        return;
    }

    mavlink_ekf_status_report_t ekf;
    mavlink_msg_ekf_status_report_decode(&message, &ekf);

    flags()->setRawValue(ekf.flags);
    velocity_variance()->setRawValue(ekf.velocity_variance);
    pos_horiz_variance()->setRawValue(ekf.pos_horiz_variance);
    pos_vert_variance()->setRawValue(ekf.pos_vert_variance);
    compass_variance()->setRawValue(ekf.compass_variance);
    terrain_alt_variance()->setRawValue(ekf.terrain_alt_variance);
    airspeed_variance()->setRawValue(ekf.airspeed_variance);
    _setTelemetryAvailable(true);
}

