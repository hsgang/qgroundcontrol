/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include "FactGroup.h"
#include "QGCMAVLink.h"

class Vehicle;

class VehicleEscStatusFactGroup : public FactGroup
{
    Q_OBJECT

public:
    VehicleEscStatusFactGroup(QObject* parent = nullptr);

    Q_PROPERTY(Fact* index              READ index              CONSTANT)

    Q_PROPERTY(Fact* rpmFirst           READ rpmFirst           CONSTANT)
    Q_PROPERTY(Fact* rpmSecond          READ rpmSecond          CONSTANT)
    Q_PROPERTY(Fact* rpmThird           READ rpmThird           CONSTANT)
    Q_PROPERTY(Fact* rpmFourth          READ rpmFourth          CONSTANT)
    Q_PROPERTY(Fact* rpmFifth           READ rpmFifth           CONSTANT)
    Q_PROPERTY(Fact* rpmSixth           READ rpmSixth           CONSTANT)
    Q_PROPERTY(Fact* rpmSeventh         READ rpmSeventh         CONSTANT)
    Q_PROPERTY(Fact* rpmEighth          READ rpmEighth          CONSTANT)

    Q_PROPERTY(Fact* currentFirst       READ currentFirst       CONSTANT)
    Q_PROPERTY(Fact* currentSecond      READ currentSecond      CONSTANT)
    Q_PROPERTY(Fact* currentThird       READ currentThird       CONSTANT)
    Q_PROPERTY(Fact* currentFourth      READ currentFourth      CONSTANT)
    Q_PROPERTY(Fact* currentFifth       READ currentFifth       CONSTANT)
    Q_PROPERTY(Fact* currentSixth       READ currentSixth       CONSTANT)
    Q_PROPERTY(Fact* currentSeventh     READ currentSeventh     CONSTANT)
    Q_PROPERTY(Fact* currentEighth      READ currentEighth      CONSTANT)

    Q_PROPERTY(Fact* voltageFirst       READ voltageFirst       CONSTANT)
    Q_PROPERTY(Fact* voltageSecond      READ voltageSecond      CONSTANT)
    Q_PROPERTY(Fact* voltageThird       READ voltageThird       CONSTANT)
    Q_PROPERTY(Fact* voltageFourth      READ voltageFourth      CONSTANT)
    Q_PROPERTY(Fact* voltageFifth       READ voltageFifth       CONSTANT)
    Q_PROPERTY(Fact* voltageSixth       READ voltageSixth       CONSTANT)
    Q_PROPERTY(Fact* voltageSeventh     READ voltageSeventh     CONSTANT)
    Q_PROPERTY(Fact* voltageEighth      READ voltageEighth      CONSTANT)

    Q_PROPERTY(Fact* temperatureFirst   READ temperatureFirst   CONSTANT)
    Q_PROPERTY(Fact* temperatureSecond  READ temperatureSecond  CONSTANT)
    Q_PROPERTY(Fact* temperatureThird   READ temperatureThird   CONSTANT)
    Q_PROPERTY(Fact* temperatureFourth  READ temperatureFourth  CONSTANT)
    Q_PROPERTY(Fact* temperatureFifth   READ temperatureFifth   CONSTANT)
    Q_PROPERTY(Fact* temperatureSixth   READ temperatureSixth   CONSTANT)
    Q_PROPERTY(Fact* temperatureSeventh READ temperatureSeventh CONSTANT)
    Q_PROPERTY(Fact* temperatureEighth  READ temperatureEighth  CONSTANT)

    Fact* index                         () { return &_indexFact; }

    Fact* rpmFirst                      () { return &_rpmFirstFact; }
    Fact* rpmSecond                     () { return &_rpmSecondFact; }
    Fact* rpmThird                      () { return &_rpmThirdFact; }
    Fact* rpmFourth                     () { return &_rpmFourthFact; }
    Fact* rpmFifth                      () { return &_rpmFifthFact; }
    Fact* rpmSixth                      () { return &_rpmSixthFact; }
    Fact* rpmSeventh                    () { return &_rpmSeventhFact; }
    Fact* rpmEighth                     () { return &_rpmEighthFact; }

    Fact* currentFirst                  () { return &_currentFirstFact; }
    Fact* currentSecond                 () { return &_currentSecondFact; }
    Fact* currentThird                  () { return &_currentThirdFact; }
    Fact* currentFourth                 () { return &_currentFourthFact; }
    Fact* currentFifth                  () { return &_currentFifthFact; }
    Fact* currentSixth                  () { return &_currentSixthFact; }
    Fact* currentSeventh                () { return &_currentSeventhFact; }
    Fact* currentEighth                 () { return &_currentEighthFact; }

    Fact* voltageFirst                  () { return &_voltageFirstFact; }
    Fact* voltageSecond                 () { return &_voltageSecondFact; }
    Fact* voltageThird                  () { return &_voltageThirdFact; }
    Fact* voltageFourth                 () { return &_voltageFourthFact; }
    Fact* voltageFifth                  () { return &_voltageFifthFact; }
    Fact* voltageSixth                  () { return &_voltageSixthFact; }
    Fact* voltageSeventh                () { return &_voltageSeventhFact; }
    Fact* voltageEighth                 () { return &_voltageEighthFact; }

    Fact* temperatureFirst              () { return &_temperatureFirstFact; }
    Fact* temperatureSecond             () { return &_temperatureSecondFact; }
    Fact* temperatureThird              () { return &_temperatureThirdFact; }
    Fact* temperatureFourth             () { return &_temperatureFourthFact; }
    Fact* temperatureFifth              () { return &_temperatureFifthFact; }
    Fact* temperatureSixth              () { return &_temperatureSixthFact; }
    Fact* temperatureSeventh            () { return &_temperatureSeventhFact; }
    Fact* temperatureEighth             () { return &_temperatureEighthFact; }

    // Overrides from FactGroup
    void handleMessage(Vehicle* vehicle, mavlink_message_t& message) override;

private:
    const QString _indexFactName =                            QStringLiteral("index");

    const QString _rpmFirstFactName =                         QStringLiteral("rpm1");
    const QString _rpmSecondFactName =                        QStringLiteral("rpm2");
    const QString _rpmThirdFactName =                         QStringLiteral("rpm3");
    const QString _rpmFourthFactName =                        QStringLiteral("rpm4");
    const QString _rpmFifthFactName =                         QStringLiteral("rpm5");
    const QString _rpmSixthFactName =                         QStringLiteral("rpm6");
    const QString _rpmSeventhFactName =                       QStringLiteral("rpm7");
    const QString _rpmEighthFactName =                        QStringLiteral("rpm8");

    const QString _currentFirstFactName =                     QStringLiteral("current1");
    const QString _currentSecondFactName =                    QStringLiteral("current2");
    const QString _currentThirdFactName =                     QStringLiteral("current3");
    const QString _currentFourthFactName =                    QStringLiteral("current4");
    const QString _currentFifthFactName =                     QStringLiteral("current5");
    const QString _currentSixthFactName =                     QStringLiteral("current6");
    const QString _currentSeventhFactName =                   QStringLiteral("current7");
    const QString _currentEighthFactName =                    QStringLiteral("current8");

    const QString _voltageFirstFactName =                     QStringLiteral("voltage1");
    const QString _voltageSecondFactName =                    QStringLiteral("voltage2");
    const QString _voltageThirdFactName =                     QStringLiteral("voltage3");
    const QString _voltageFourthFactName =                    QStringLiteral("voltage4");
    const QString _voltageFifthFactName =                     QStringLiteral("voltage5");
    const QString _voltageSixthFactName =                     QStringLiteral("voltage6");
    const QString _voltageSeventhFactName =                   QStringLiteral("voltage7");
    const QString _voltageEighthFactName =                    QStringLiteral("voltage8");

    const QString _temperatureFirstFactName =                 QStringLiteral("temperature1");
    const QString _temperatureSecondFactName =                QStringLiteral("temperature2");
    const QString _temperatureThirdFactName =                 QStringLiteral("temperature3");
    const QString _temperatureFourthFactName =                QStringLiteral("temperature4");
    const QString _temperatureFifthFactName =                 QStringLiteral("temperature5");
    const QString _temperatureSixthFactName =                 QStringLiteral("temperature6");
    const QString _temperatureSeventhFactName =               QStringLiteral("temperature7");
    const QString _temperatureEighthFactName =                QStringLiteral("temperature8");

    void _handleEscStatus           (mavlink_message_t& message);
    void _handleEscTelemetry1to4    (mavlink_message_t& message);
    void _handleEscTelemetry5to8    (mavlink_message_t& message);

    Fact _indexFact;

    Fact _rpmFirstFact;
    Fact _rpmSecondFact;
    Fact _rpmThirdFact;
    Fact _rpmFourthFact;
    Fact _rpmFifthFact;
    Fact _rpmSixthFact;
    Fact _rpmSeventhFact;
    Fact _rpmEighthFact;

    Fact _currentFirstFact;
    Fact _currentSecondFact;
    Fact _currentThirdFact;
    Fact _currentFourthFact;
    Fact _currentFifthFact;
    Fact _currentSixthFact;
    Fact _currentSeventhFact;
    Fact _currentEighthFact;

    Fact _voltageFirstFact;
    Fact _voltageSecondFact;
    Fact _voltageThirdFact;
    Fact _voltageFourthFact;
    Fact _voltageFifthFact;
    Fact _voltageSixthFact;
    Fact _voltageSeventhFact;
    Fact _voltageEighthFact;

    Fact _temperatureFirstFact;
    Fact _temperatureSecondFact;
    Fact _temperatureThirdFact;
    Fact _temperatureFourthFact;
    Fact _temperatureFifthFact;
    Fact _temperatureSixthFact;
    Fact _temperatureSeventhFact;
    Fact _temperatureEighthFact;
};
