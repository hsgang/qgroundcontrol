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

class VehicleSensorFactGroup : public FactGroup
{
    Q_OBJECT

public:
    VehicleSensorFactGroup(QObject* parent = nullptr);

    Q_PROPERTY(Fact* sensorTemp         READ sensorTemp         CONSTANT)
    Q_PROPERTY(Fact* sensorHumi         READ sensorHumi         CONSTANT)
    Q_PROPERTY(Fact* sensorBaro         READ sensorBaro         CONSTANT)
    Q_PROPERTY(Fact* sensorWindDir      READ sensorWindDir      CONSTANT)
    Q_PROPERTY(Fact* sensorWindSpd      READ sensorWindSpd      CONSTANT)
    Q_PROPERTY(Fact* sensorPM1p0        READ sensorPM1p0        CONSTANT)
    Q_PROPERTY(Fact* sensorPM2p5        READ sensorPM2p5        CONSTANT)
    Q_PROPERTY(Fact* sensorPM10         READ sensorPM10         CONSTANT)
    Q_PROPERTY(Fact* sensorSensor1      READ sensorSensor1      CONSTANT)
    Q_PROPERTY(Fact* sensorSensor2      READ sensorSensor2      CONSTANT)
    Q_PROPERTY(Fact* sensorSensor3      READ sensorSensor3      CONSTANT)
    Q_PROPERTY(Fact* sensorSensor4      READ sensorSensor4      CONSTANT)
    Q_PROPERTY(Fact* sensorSensor5      READ sensorSensor5      CONSTANT)
    Q_PROPERTY(Fact* sensorStatus       READ sensorStatus       CONSTANT)
    Q_PROPERTY(Fact* sensorCount        READ sensorCount        CONSTANT)

    Fact* sensorTemp                        () { return &_sensorTempFact; }
    Fact* sensorHumi                        () { return &_sensorHumiFact; }
    Fact* sensorBaro                        () { return &_sensorBaroFact; }
    Fact* sensorWindDir                     () { return &_sensorWindDirFact; }
    Fact* sensorWindSpd                     () { return &_sensorWindSpdFact; }
    Fact* sensorPM1p0                       () { return &_sensorPM1p0Fact; }
    Fact* sensorPM2p5                       () { return &_sensorPM2p5Fact; }
    Fact* sensorPM10                        () { return &_sensorPM10Fact; }
    Fact* sensorSensor1                     () { return &_sensorSensor1Fact; }
    Fact* sensorSensor2                     () { return &_sensorSensor2Fact; }
    Fact* sensorSensor3                     () { return &_sensorSensor3Fact; }
    Fact* sensorSensor4                     () { return &_sensorSensor4Fact; }
    Fact* sensorSensor5                     () { return &_sensorSensor5Fact; }
    Fact* sensorStatus                      () { return &_sensorStatusFact; }
    Fact* sensorCount                       () { return &_sensorCountFact; }

    // Overrides from FactGroup
    void handleMessage(Vehicle* vehicle, mavlink_message_t& message) override;

    static const char* _sensorTempFactName;
    static const char* _sensorHumiFactName;
    static const char* _sensorBaroFactName;
    static const char* _sensorWindDirFactName;
    static const char* _sensorWindSpdFactName;
    static const char* _sensorPM1p0FactName;
    static const char* _sensorPM2p5FactName;
    static const char* _sensorPM10FactName;
    static const char* _sensorSensor1FactName;
    static const char* _sensorSensor2FactName;
    static const char* _sensorSensor3FactName;
    static const char* _sensorSensor4FactName;
    static const char* _sensorSensor5FactName;
    static const char* _sensorStatusFactName;
    static const char* _sensorCountFactName;

private:
    void _handleData32     (mavlink_message_t &message);
    void _handleScaledPressure     (mavlink_message_t &message);
//    void _handleV2_extension (mavlink_message_t& message);
//    void _initializeSensorData          ();
//    void _writeSensorDataLine           ();
#if !defined(NO_ARDUPILOT_DIALECT)
    void _handleWind        (mavlink_message_t &message);
#endif

    Fact _sensorTempFact;
    Fact _sensorHumiFact;
    Fact _sensorBaroFact;
    Fact _sensorWindDirFact;
    Fact _sensorWindSpdFact;
    Fact _sensorPM1p0Fact;
    Fact _sensorPM2p5Fact;
    Fact _sensorPM10Fact;
    Fact _sensorSensor1Fact;
    Fact _sensorSensor2Fact;
    Fact _sensorSensor3Fact;
    Fact _sensorSensor4Fact;
    Fact _sensorSensor5Fact;
    Fact _sensorStatusFact;
    Fact _sensorCountFact;

//    QTimer              _sensorLogTimer;
//    QFile               _sensorLogFile;

};
