/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


#include "APMChannelsComponent.h"
#include "Vehicle.h"

APMChannelsComponent::APMChannelsComponent(Vehicle* vehicle, AutoPilotPlugin* autopilot, QObject* parent)
    : VehicleComponent(vehicle, autopilot, AutoPilotPlugin::KnownChannelVehicleComponent, parent)
    , _name(tr("Channels"))
{
}

QString APMChannelsComponent::name() const
{
    return _name;
}

QString APMChannelsComponent::description() const
{
    return tr("Channels Setup is used to configure the rc/servo functions of the Vehicle.");
}

QString APMChannelsComponent::iconResource() const
{
    return QStringLiteral("/qmlimages/TuningComponentIcon.png");
}

bool APMChannelsComponent::requiresSetup() const
{
    return false;
}

bool APMChannelsComponent::setupComplete() const
{
    return true;
}

QStringList APMChannelsComponent::setupCompleteChangedTriggerList() const
{
    return QStringList();
}
