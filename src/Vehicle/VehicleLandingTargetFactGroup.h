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

    Q_PROPERTY(Fact* targetNum      READ targetNum          CONSTANT);
    Q_PROPERTY(Fact* angleX         READ angleX             CONSTANT);
    Q_PROPERTY(Fact* angleY         READ angleY             CONSTANT);
    Q_PROPERTY(Fact* distance       READ distance           CONSTANT);
    Q_PROPERTY(Fact* sizeX          READ sizeX              CONSTANT);
    Q_PROPERTY(Fact* sizeY          READ sizeY              CONSTANT);
    Q_PROPERTY(Fact* x              READ x                  CONSTANT);
    Q_PROPERTY(Fact* y              READ y                  CONSTANT);
    Q_PROPERTY(Fact* z              READ z                  CONSTANT);
    Q_PROPERTY(Fact* q              READ q                  CONSTANT);
    Q_PROPERTY(Fact* type           READ type               CONSTANT);
    Q_PROPERTY(Fact* positionValid  READ positionValid      CONSTANT);

    Fact* targetNum     () { return &_targetNumFact; }
    Fact* angleX        () { return &_angleXFact; }
    Fact* angleY        () { return &_angleYFact; }
    Fact* distance      () { return &_distanceFact; }
    Fact* sizeX         () { return &_sizeXFact; }
    Fact* sizeY         () { return &_sizeYFact; }
    Fact* x             () { return &_xFact; }
    Fact* y             () { return &_yFact; }
    Fact* z             () { return &_zFact; }
    Fact* q             () { return &_qFact; }
    Fact* type          () { return &_typeFact; }
    Fact* positionValid () { return &_positionValidFact; }

    // Overrides from FactGroup
    void handleMessage(Vehicle* vehicle, mavlink_message_t& message);

    static const char* _targetNumFactName;
    static const char* _angleXFactName;
    static const char* _angleYFactName;
    static const char* _distanceFactName;
    static const char* _sizeXFactName;
    static const char* _sizeYFactName;
    static const char* _xFactName;
    static const char* _yFactName;
    static const char* _zFactName;
    static const char* _qFactName;
    static const char* _typeFactName;
    static const char* _positionValidFactName;

private:
    void _handleLandingTarget (mavlink_message_t &message);

    Fact _targetNumFact;
    Fact _angleXFact;
    Fact _angleYFact;
    Fact _distanceFact;
    Fact _sizeXFact;
    Fact _sizeYFact;
    Fact _xFact;
    Fact _yFact;
    Fact _zFact;
    Fact _qFact;
    Fact _typeFact;
    Fact _positionValidFact;
};
