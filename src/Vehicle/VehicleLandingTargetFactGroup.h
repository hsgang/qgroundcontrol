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

class Vehicle;

class VehicleLandingTargetFactGroup : public FactGroup
{
    Q_OBJECT

public:
    VehicleLandingTargetFactGroup(QObject* parent = nullptr);

    Q_PROPERTY(Fact* angleX       READ angleX       CONSTANT)
    Q_PROPERTY(Fact* angleY       READ angleY        CONSTANT)

    Fact* angleX      () { return &_angleXFact; }
    Fact* angleY      () { return &_angleYFact; }

    // Overrides from FactGroup
    void handleMessage(Vehicle* vehicle, mavlink_message_t& message);

    static const char* _angleXFactName;
    static const char* _angleYFactName;

private:
    void _handleLandingTarget (mavlink_message_t &message);

    Fact _angleXFact;
    Fact _angleYFact;
};
