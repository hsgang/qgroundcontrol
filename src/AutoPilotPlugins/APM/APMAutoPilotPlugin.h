/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


#pragma once

#include "AutoPilotPlugin.h"

class APMAirframeComponent;
class APMChannelsComponent;
class APMFlightModesComponent;
class APMRadioComponent;
class APMTuningComponent;
class APMSafetyComponent;
class APMSensorsComponent;
class APMPowerComponent;
class APMMotorComponent;
class APMCameraComponent;
class APMLightsComponent;
class APMSubFrameComponent;
class ESP8266Component;
class APMHeliComponent;
class APMRemoteSupportComponent;
class APMFollowComponent;
class Vehicle;

/// This is the APM specific implementation of the AutoPilot class.
class APMAutoPilotPlugin : public AutoPilotPlugin
{
    Q_OBJECT

public:
    APMAutoPilotPlugin(Vehicle* vehicle, QObject* parent);
    ~APMAutoPilotPlugin();

    // Overrides from AutoPilotPlugin
    const QVariantList& vehicleComponents(void) override;
    QString prerequisiteSetup(VehicleComponent* component) const override;

protected:
    bool                        _incorrectParameterVersion; ///< true: parameter version incorrect, setup not allowed
    APMAirframeComponent*       _airframeComponent;
    APMCameraComponent*         _cameraComponent;
    APMChannelsComponent*       _channelsComponent;
    APMLightsComponent*         _lightsComponent;
    APMSubFrameComponent*       _subFrameComponent;
    APMFlightModesComponent*    _flightModesComponent;
    APMPowerComponent*          _powerComponent;
    APMMotorComponent*          _motorComponent;
    APMRadioComponent*          _radioComponent;
    APMSafetyComponent*         _safetyComponent;
    APMSensorsComponent*        _sensorsComponent;
    APMTuningComponent*         _tuningComponent;
    ESP8266Component*           _esp8266Component;
    APMHeliComponent*           _heliComponent;
    APMRemoteSupportComponent*  _apmRemoteSupportComponent;
    APMFollowComponent *_followComponent = nullptr;

#if !defined(QGC_NO_SERIAL_LINK) && !defined(Q_OS_ANDROID)
private slots:
    void _checkForBadCubeBlack(void);
#endif

private:
    QVariantList                _components;
};
