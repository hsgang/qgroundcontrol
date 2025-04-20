#pragma once

#include "FactGroup.h"
#include "QGCMAVLink.h"

class ExternalPowerStatusFactGroup : public FactGroup
{
    Q_OBJECT
    Q_PROPERTY(Fact* ACInputVolatage1   READ acInputVolatage1   CONSTANT)
    Q_PROPERTY(Fact* ACInputVolatage2   READ acInputVolatage2   CONSTANT)
    Q_PROPERTY(Fact* ACInputVolatage3   READ acInputVolatage3   CONSTANT)
    Q_PROPERTY(Fact* DCOutputVolatage1  READ dcOutputVolatage1  CONSTANT)
    Q_PROPERTY(Fact* DCOutputVolatage2  READ dcOutputVolatage2  CONSTANT)
    Q_PROPERTY(Fact* DCOutputVolatage3  READ dcOutputVolatage3  CONSTANT)
    Q_PROPERTY(Fact* DCOutputCurrent1   READ dcOutputCurrent1   CONSTANT)
    Q_PROPERTY(Fact* DCOutputCurrent2   READ dcOutputCurrent2   CONSTANT)
    Q_PROPERTY(Fact* DCOutputCurrent3   READ dcOutputCurrent3   CONSTANT)
    Q_PROPERTY(Fact* Temperature        READ temperature        CONSTANT)
    Q_PROPERTY(Fact* BatteryVoltage     READ batteryVoltage     CONSTANT)
    Q_PROPERTY(Fact* BatteryChange      READ batteryChange      CONSTANT)

public:
    ExternalPowerStatusFactGroup(QObject* parent = nullptr);


    Fact *acInputVolatage1  () { return &_acInputVolatage1Fact; }
    Fact *acInputVolatage2  () { return &_acInputVolatage2Fact; }
    Fact *acInputVolatage3  () { return &_acInputVolatage3Fact; }
    Fact *dcOutputVolatage1 () { return &_dcOutputVolatage1Fact; }
    Fact *dcOutputVolatage2 () { return &_dcOutputVolatage2Fact; }
    Fact *dcOutputVolatage3 () { return &_dcOutputVolatage3Fact; }
    Fact *dcOutputCurrent1  () { return &_dcOutputCurrent1Fact; }
    Fact *dcOutputCurrent2  () { return &_dcOutputCurrent2Fact; }
    Fact *dcOutputCurrent3  () { return &_dcOutputCurrent3Fact; }
    Fact *temperature       () { return &_temperatureFact; }
    Fact *batteryVoltage    () { return &_batteryVoltageFact; }
    Fact *batteryChange     () { return &_batteryChangeFact; }

    // Overrides from FactGroup
    void handleMessage(Vehicle* vehicle, const mavlink_message_t& message) override;

private:
    void _handleExternalPowerStatus (const mavlink_message_t& message);

    Fact _acInputVolatage1Fact = Fact(0, QStringLiteral("acInputVolatage1"), FactMetaData::valueTypeFloat);
    Fact _acInputVolatage2Fact = Fact(0, QStringLiteral("acInputVolatage2"), FactMetaData::valueTypeFloat);
    Fact _acInputVolatage3Fact = Fact(0, QStringLiteral("acInputVolatage3"), FactMetaData::valueTypeFloat);
    Fact _dcOutputVolatage1Fact = Fact(0, QStringLiteral("dcOutputVolatage1"), FactMetaData::valueTypeFloat);
    Fact _dcOutputVolatage2Fact = Fact(0, QStringLiteral("dcOutputVolatage2"), FactMetaData::valueTypeFloat);
    Fact _dcOutputVolatage3Fact = Fact(0, QStringLiteral("dcOutputVolatage3"), FactMetaData::valueTypeFloat);
    Fact _dcOutputCurrent1Fact = Fact(0, QStringLiteral("dcOutputCurrent1"), FactMetaData::valueTypeFloat);
    Fact _dcOutputCurrent2Fact = Fact(0, QStringLiteral("dcOutputCurrent2"), FactMetaData::valueTypeFloat);
    Fact _dcOutputCurrent3Fact = Fact(0, QStringLiteral("dcOutputCurrent3"), FactMetaData::valueTypeFloat);
    Fact _temperatureFact = Fact(0, QStringLiteral("temperature"), FactMetaData::valueTypeFloat);
    Fact _batteryVoltageFact = Fact(0, QStringLiteral("batteryVoltage"), FactMetaData::valueTypeFloat);
    Fact _batteryChangeFact = Fact(0, QStringLiteral("batteryChange"), FactMetaData::valueTypeInt8);
};
