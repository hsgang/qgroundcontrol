#pragma once

#include "FactGroup.h"
#include "QGCMAVLink.h"

class WinchStatusFactGroup : public FactGroup
{
    Q_OBJECT

public:
    WinchStatusFactGroup(QObject* parent = nullptr);

    Q_PROPERTY(Fact* timeUsec       READ timeUsec           CONSTANT)
    Q_PROPERTY(Fact* lineLength     READ lineLength         CONSTANT)
    Q_PROPERTY(Fact* speed          READ speed              CONSTANT)
    Q_PROPERTY(Fact* tension        READ tension            CONSTANT)
    Q_PROPERTY(Fact* voltage        READ voltage            CONSTANT)
    Q_PROPERTY(Fact* current        READ current            CONSTANT)
    Q_PROPERTY(Fact* temperature    READ temperature        CONSTANT)
    Q_PROPERTY(Fact* status         READ status             CONSTANT)

    Fact* timeUsec                      () { return &_timeUsecFact; }
    Fact* lineLength                    () { return &_lineLengthFact; }
    Fact* speed                         () { return &_speedFact; }
    Fact* tension                       () { return &_tensionFact; }
    Fact* voltage                       () { return &_voltageFact; }
    Fact* current                       () { return &_currentFact; }
    Fact* temperature                   () { return &_temperatureFact; }
    Fact* status                        () { return &_statusFact; }

    // Overrides from FactGroup
    void handleMessage(Vehicle* vehicle, mavlink_message_t& message) override;

    static const char* _timeUsecFactName;
    static const char* _lineLengthFactName;
    static const char* _speedFactName;
    static const char* _tensionFactName;
    static const char* _voltageFactName;
    static const char* _currentFactName;
    static const char* _temperatureFactName;
    static const char* _statusFactName;

private:
    void _handleWinchStatus              (mavlink_message_t& message);

    Fact _timeUsecFact;
    Fact _lineLengthFact;
    Fact _speedFact;
    Fact _tensionFact;
    Fact _voltageFact;
    Fact _currentFact;
    Fact _temperatureFact;
    Fact _statusFact;
};
