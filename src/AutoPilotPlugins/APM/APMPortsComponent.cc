/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


#include "APMPortsComponent.h"
#include "Vehicle.h"

APMPortsComponent::APMPortsComponent(Vehicle* vehicle, AutoPilotPlugin* autopilot, QObject* parent)
    : VehicleComponent(vehicle, autopilot, AutoPilotPlugin::KnownPortsVehicleComponent, parent)
    , _name(tr("Ports"))
{
}

QString APMPortsComponent::name() const
{
    return _name;
}

QString APMPortsComponent::description() const
{
    return tr("Ports Setup is used to configure the serial port functions of the Vehicle.");
}

QString APMPortsComponent::iconResource() const
{
    return QStringLiteral("/qmlimages/TuningComponentIcon.png");
}

bool APMPortsComponent::requiresSetup() const
{
    return false;
}

bool APMPortsComponent::setupComplete() const
{
    return true;
}

QStringList APMPortsComponent::setupCompleteChangedTriggerList() const
{
    return QStringList();
}
