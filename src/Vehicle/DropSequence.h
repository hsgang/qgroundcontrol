#pragma once

#include <QtQmlIntegration/QtQmlIntegration>

#include "Vehicle.h"
#include "MAVLinkLib.h"

class DropSequence : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")

public:
    explicit DropSequence(Vehicle *vehicle);

    Q_PROPERTY(bool      dropSequenceInProgress   READ dropSequenceInProgress     NOTIFY dropSequenceChanged)
    Q_PROPERTY(float     dropSequenceProgress     READ dropSequenceProgress       NOTIFY dropSequenceChanged)
    Q_PROPERTY(QString   dropSequenceStatus       READ dropSequenceStatus         NOTIFY dropSequenceChanged)
    Q_PROPERTY(int       dropSequenceIndex        READ dropSequenceIndex          NOTIFY dropSequenceChanged)

    Q_INVOKABLE void startDropSequence(int tagId, float targetAltitude);
    Q_INVOKABLE void stopDropSequence();
    Q_INVOKABLE void testDropSequence(int tagId, float targetAltitude);

    static void ackHandler      (void* resultHandlerData,   int compId, const mavlink_command_ack_t& ack, Vehicle::MavCmdResultFailureCode_t failureCode);
    static void progressHandler (void* progressHandlerData, int compId, const mavlink_command_ack_t& ack);

    bool      dropSequenceInProgress () { return _dropSequenceInProgress; }
    float     dropSequenceProgress   () { return _dropSequenceProgress; }
    QString   dropSequenceStatus     () { return _dropSequenceStatus; }
    int       dropSequenceIndex      () { return _dropSequenceIndex; }

public slots:
    void sendMavlinkRequest(int autoAction);

signals:
    void dropSequenceChanged ();

private:
    void handleAckStatus(uint8_t ackProgress, uint8_t sequenceIndex);
    void handleAckFailure();
    void handleAckError(uint8_t ackError);

private:
    Vehicle* _vehicle                    {nullptr};
    bool     _dropSequenceInProgress     {false};
    float    _dropSequenceProgress       {0.0};
    QString  _dropSequenceStatus         {tr("Not started")};
    int      _dropSequenceIndex          {0};
    int      _tagId                      {0};
    float    _targetAltitude             {3.0};

};
