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
    Q_PROPERTY(Fact* flags                  READ flags                  CONSTANT)
    Q_PROPERTY(Fact* velocity_variance      READ velocity_variance      CONSTANT)
    Q_PROPERTY(Fact* pos_horiz_variance     READ pos_horiz_variance     CONSTANT)
    Q_PROPERTY(Fact* pos_vert_variance      READ pos_vert_variance      CONSTANT)
    Q_PROPERTY(Fact* compass_variance       READ compass_variance       CONSTANT)
    Q_PROPERTY(Fact* terrain_alt_variance   READ terrain_alt_variance   CONSTANT)
    Q_PROPERTY(Fact* airspeed_variance      READ airspeed_variance      CONSTANT)

public:
    VehicleEKFStatusFactGroup(QObject* parent = nullptr);;

    Fact* flags                     () { return &_flagsFact; }
    Fact* velocity_variance         () { return &_velocity_varianceFact; }
    Fact* pos_horiz_variance        () { return &_pos_horiz_varianceFact; }
    Fact* pos_vert_variance         () { return &_pos_vert_varianceFact; }
    Fact* compass_variance          () { return &_compass_varianceFact; }
    Fact* terrain_alt_variance      () { return &_terrain_alt_varianceFact; }
    Fact* airspeed_variance         () { return &_airspeed_varianceFact; }

    // Overrides from FactGroup
    void handleMessage(Vehicle *vehicle, const mavlink_message_t &message) override;

private:
    Fact _flagsFact = Fact(0, QStringLiteral("flags"), FactMetaData::valueTypeUint16);
    Fact _velocity_varianceFact = Fact(0, QStringLiteral("velocity_variance"), FactMetaData::valueTypeDouble);
    Fact _pos_horiz_varianceFact = Fact(0, QStringLiteral("pos_horiz_variance"), FactMetaData::valueTypeDouble);
    Fact _pos_vert_varianceFact = Fact(0, QStringLiteral("pos_vert_variance"), FactMetaData::valueTypeDouble);
    Fact _compass_varianceFact = Fact(0, QStringLiteral("compass_variance"), FactMetaData::valueTypeDouble);
    Fact _terrain_alt_varianceFact = Fact(0, QStringLiteral("terrain_alt_variance"), FactMetaData::valueTypeDouble);
    Fact _airspeed_varianceFact = Fact(0, QStringLiteral("airspeed_variance"), FactMetaData::valueTypeDouble);
};
