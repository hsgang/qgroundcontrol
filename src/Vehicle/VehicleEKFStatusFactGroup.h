/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include "FactGroup.h"
#include "QGCMAVLink.h"

class VehicleEKFStatusFactGroup : public FactGroup
{
    Q_OBJECT

public:
    VehicleEKFStatusFactGroup(QObject* parent = nullptr);;

    Q_PROPERTY(Fact* flags                  READ flags                  CONSTANT)
    Q_PROPERTY(Fact* velocity_variance      READ velocity_variance      CONSTANT)
    Q_PROPERTY(Fact* pos_horiz_variance     READ pos_horiz_variance     CONSTANT)
    Q_PROPERTY(Fact* pos_vert_variance      READ pos_vert_variance      CONSTANT)
    Q_PROPERTY(Fact* compass_variance       READ compass_variance       CONSTANT)
    Q_PROPERTY(Fact* terrain_alt_variance   READ terrain_alt_variance   CONSTANT)
    Q_PROPERTY(Fact* airspeed_variance      READ airspeed_variance      CONSTANT)

    Fact* flags                     () { return &_flagsFact; }
    Fact* velocity_variance         () { return &_velocity_varianceFact; }
    Fact* pos_horiz_variance        () { return &_pos_horiz_varianceFact; }
    Fact* pos_vert_variance         () { return &_pos_vert_varianceFact; }
    Fact* compass_variance          () { return &_compass_varianceFact; }
    Fact* terrain_alt_variance      () { return &_terrain_alt_varianceFact; }
    Fact* airspeed_variance         () { return &_airspeed_varianceFact; }

    // Overrides from FactGroup
    void handleMessage(Vehicle* vehicle, mavlink_message_t& message) override;

    static const char* _flagsFactName;
    static const char* _velocity_varianceFactName;
    static const char* _pos_horiz_varianceFactName;
    static const char* _pos_vert_varianceFactName;
    static const char* _compass_varianceFactName;
    static const char* _terrain_alt_varianceFactName;
    static const char* _airspeed_varianceFactName;

private:
    Fact        _flagsFact;
    Fact        _velocity_varianceFact;
    Fact        _pos_horiz_varianceFact;
    Fact        _pos_vert_varianceFact;
    Fact        _compass_varianceFact;
    Fact        _terrain_alt_varianceFact;
    Fact        _airspeed_varianceFact;
};
