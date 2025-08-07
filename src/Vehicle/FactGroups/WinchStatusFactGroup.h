#pragma once

#include "FactGroup.h"
#include "QGCMAVLink.h"

class WinchStatusFactGroup : public FactGroup
{
    Q_OBJECT
    Q_PROPERTY(Fact* timeUsec       READ timeUsec       CONSTANT)
    Q_PROPERTY(Fact* lineLength     READ lineLength     CONSTANT)
    Q_PROPERTY(Fact* speed          READ speed          CONSTANT)
    Q_PROPERTY(Fact* tension        READ tension        CONSTANT)
    Q_PROPERTY(Fact* voltage        READ voltage        CONSTANT)
    Q_PROPERTY(Fact* current        READ current        CONSTANT)
    Q_PROPERTY(Fact* temperature    READ temperature    CONSTANT)
    Q_PROPERTY(Fact* status         READ status         CONSTANT)

public:
    WinchStatusFactGroup(QObject* parent = nullptr);


    Fact *timeUsec      () { return &_timeUsecFact; }
    Fact *lineLength    () { return &_lineLengthFact; }
    Fact *speed         () { return &_speedFact; }
    Fact *tension       () { return &_tensionFact; }
    Fact *voltage       () { return &_voltageFact; }
    Fact *current       () { return &_currentFact; }
    Fact *temperature   () { return &_temperatureFact; }
    Fact *status        () { return &_statusFact; }

    // Overrides from FactGroup
    void handleMessage(Vehicle* vehicle, const mavlink_message_t& message) override;

private:
    void _handleWinchStatus (const mavlink_message_t& message);

    Fact _timeUsecFact = Fact(0, QStringLiteral("timeUsec"), FactMetaData::valueTypeUint64);
    Fact _lineLengthFact = Fact(0, QStringLiteral("lineLength"), FactMetaData::valueTypeFloat);
    Fact _speedFact = Fact(0, QStringLiteral("speed"), FactMetaData::valueTypeFloat);
    Fact _tensionFact = Fact(0, QStringLiteral("tension"), FactMetaData::valueTypeFloat);
    Fact _voltageFact = Fact(0, QStringLiteral("voltage"), FactMetaData::valueTypeFloat);
    Fact _currentFact = Fact(0, QStringLiteral("current"), FactMetaData::valueTypeFloat);
    Fact _temperatureFact = Fact(0, QStringLiteral("temperature"), FactMetaData::valueTypeInt16);
    Fact _statusFact = Fact(0, QStringLiteral("status"), FactMetaData::valueTypeUint32);
};
