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

VehicleEKFStatusFactGroup::VehicleEKFStatusFactGroup(QObject* parent)
    : FactGroup         (1000, ":/json/Vehicle/EKFStatusFact.json", parent)
{
    _addFact(&_flagsFact);
    _addFact(&_velocity_varianceFact);
    _addFact(&_pos_horiz_varianceFact);
    _addFact(&_pos_vert_varianceFact);
    _addFact(&_compass_varianceFact);
    _addFact(&_terrain_alt_varianceFact);
    _addFact(&_airspeed_varianceFact);

    // Start out as not available "--.--"
    _velocity_varianceFact.setRawValue(qQNaN());
    _pos_horiz_varianceFact.setRawValue(qQNaN());
    _pos_vert_varianceFact.setRawValue(qQNaN());
    _compass_varianceFact.setRawValue(qQNaN());
    _terrain_alt_varianceFact.setRawValue(qQNaN());
    _airspeed_varianceFact.setRawValue(qQNaN());
}

void VehicleEKFStatusFactGroup::handleMessage(Vehicle *vehicle, const mavlink_message_t &message)
{
    Q_UNUSED(vehicle);

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

