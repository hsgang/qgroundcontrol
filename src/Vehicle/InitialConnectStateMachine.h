/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include "StateMachine.h"
#include "MAVLinkLib.h"
#include "Vehicle.h"

#include <QtCore/QLoggingCategory>

Q_DECLARE_LOGGING_CATEGORY(InitialConnectStateMachineLog)

class InitialConnectStateMachine : public StateMachine
{
    Q_OBJECT

public:
    InitialConnectStateMachine(Vehicle *vehicle, QObject *parent = nullptr);
    ~InitialConnectStateMachine();

    // Overrides from StateMachine
    int             stateCount      (void) const final;
    const StateFn*  rgStates        (void) const final;
    void            statesCompleted (void) const final;

    void advance() override;

signals:
    void progressUpdate(float progress);

private slots:
    void gotProgressUpdate(double progressValue);
    void standardModesRequestCompleted();

private:
    static void _stateRequestAutopilotVersion           (StateMachine* stateMachine);
    static void _stateRequestProtocolVersion            (StateMachine* stateMachine);
    static void _stateRequestCompInfo                   (StateMachine* stateMachine);
    static void _stateRequestStandardModes              (StateMachine* stateMachine);
    static void _stateRequestCompInfoComplete           (void* requestAllCompleteFnData);
    static void _stateRequestParameters                 (StateMachine* stateMachine);
    static void _stateRequestMission                    (StateMachine* stateMachine);
    static void _stateRequestGeoFence                   (StateMachine* stateMachine);
    static void _stateRequestRallyPoints                (StateMachine* stateMachine);
    static void _stateSignalInitialConnectComplete      (StateMachine* stateMachine);

    static void _autopilotVersionRequestMessageHandler  (void* resultHandlerData, MAV_RESULT commandResult, Vehicle::RequestMessageResultHandlerFailureCode_t failureCode, const mavlink_message_t& message);
    static void _protocolVersionRequestMessageHandler   (void* resultHandlerData, MAV_RESULT commandResult, Vehicle::RequestMessageResultHandlerFailureCode_t failureCode, const mavlink_message_t& message);

    float _progress(float subProgress = 0.f);

    Vehicle* _vehicle;

    int _progressWeightTotal;

    static constexpr const StateMachine::StateFn _rgStates[] = {
        _stateRequestAutopilotVersion,
        _stateRequestProtocolVersion,
        _stateRequestStandardModes,
        _stateRequestCompInfo,
        _stateRequestParameters,
        _stateRequestMission,
        _stateRequestGeoFence,
        _stateRequestRallyPoints,
        _stateSignalInitialConnectComplete
    };

    static constexpr const int _rgProgressWeights[] = {
        0, //1_stateRequestCapabilities
        0, //1_stateRequestProtocolVersion
        0, //1_stateRequestStandardModes
        0, //5_stateRequestCompInfo
        5, //5_stateRequestParameters
        2, //2_stateRequestMission
        1, //1_stateRequestGeoFence
        1, //1_stateRequestRallyPoints
        1, //1_stateSignalInitialConnectComplete
    };

    static constexpr int _cStates = sizeof(_rgStates) / sizeof(_rgStates[0]);
};
