#pragma once

#include "FactGroup.h"
#include "QGCMAVLink.h"

class ExternalPowerStatusFactGroup : public FactGroup
{
    Q_OBJECT

public:
    ExternalPowerStatusFactGroup(QObject* parent = nullptr);

    Q_PROPERTY(Fact* acInputVolatage1        READ acInputVolatage1        CONSTANT)
    Q_PROPERTY(Fact* acInputVolatage2        READ acInputVolatage2        CONSTANT)
    Q_PROPERTY(Fact* acInputVolatage3        READ acInputVolatage3        CONSTANT)
    Q_PROPERTY(Fact* dcOutputVolatage1       READ dcOutputVolatage1       CONSTANT)
    Q_PROPERTY(Fact* dcOutputVolatage2       READ dcOutputVolatage2       CONSTANT)
    Q_PROPERTY(Fact* dcOutputVolatage3       READ dcOutputVolatage3       CONSTANT)
    Q_PROPERTY(Fact* dcOutputCurrent1        READ dcOutputCurrent1        CONSTANT)
    Q_PROPERTY(Fact* dcOutputCurrent2        READ dcOutputCurrent2        CONSTANT)
    Q_PROPERTY(Fact* dcOutputCurrent3        READ dcOutputCurrent3        CONSTANT)
    Q_PROPERTY(Fact* temperature             READ temperature             CONSTANT)
    Q_PROPERTY(Fact* batteryVoltage          READ batteryVoltage          CONSTANT)
    Q_PROPERTY(Fact* batteryChange           READ batteryChange           CONSTANT)

    Fact* acInputVolatage1                    () { return &_acInputVolatage1Fact; }
    Fact* acInputVolatage2                    () { return &_acInputVolatage2Fact; }
    Fact* acInputVolatage3                    () { return &_acInputVolatage3Fact; }
    Fact* dcOutputVolatage1                   () { return &_dcOutputVolatage1Fact; }
    Fact* dcOutputVolatage2                   () { return &_dcOutputVolatage2Fact; }
    Fact* dcOutputVolatage3                   () { return &_dcOutputVolatage3Fact; }
    Fact* dcOutputCurrent1                    () { return &_dcOutputCurrent1Fact; }
    Fact* dcOutputCurrent2                    () { return &_dcOutputCurrent2Fact; }
    Fact* dcOutputCurrent3                    () { return &_dcOutputCurrent3Fact; }
    Fact* temperature                         () { return &_temperatureFact; }
    Fact* batteryVoltage                      () { return &_batteryVoltageFact; }
    Fact* batteryChange                       () { return &_batteryChangeFact; }

    // Overrides from FactGroup
    void handleMessage(Vehicle* vehicle, mavlink_message_t& message) override;

    static const char* _acInputVolatage1FactName;
    static const char* _acInputVolatage2FactName;
    static const char* _acInputVolatage3FactName;
    static const char* _dcOutputVolatage1FactName;
    static const char* _dcOutputVolatage2FactName;
    static const char* _dcOutputVolatage3FactName;
    static const char* _dcOutputCurrent1FactName;
    static const char* _dcOutputCurrent2FactName;
    static const char* _dcOutputCurrent3FactName;
    static const char* _temperatureFactName;
    static const char* _batteryVoltageFactName;
    static const char* _batteryChangeFactName;

private:
    void _handleExternalPowerStatus              (mavlink_message_t& message);

    Fact _acInputVolatage1Fact;
    Fact _acInputVolatage2Fact;
    Fact _acInputVolatage3Fact;
    Fact _dcOutputVolatage1Fact;
    Fact _dcOutputVolatage2Fact;
    Fact _dcOutputVolatage3Fact;
    Fact _dcOutputCurrent1Fact;
    Fact _dcOutputCurrent2Fact;
    Fact _dcOutputCurrent3Fact;
    Fact _temperatureFact;
    Fact _batteryVoltageFact;
    Fact _batteryChangeFact;
};
