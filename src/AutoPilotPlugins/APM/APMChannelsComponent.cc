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
    : VehicleComponent(vehicle, autopilot, parent)
    , _name(tr("Channels"))
{
}

QString APMChannelsComponent::name(void) const
{
    return _name;
}

QString APMChannelsComponent::description(void) const
{
    return tr("Channels Setup is used to configure the rc/servo functions of the Vehicle.");
}

QString APMChannelsComponent::iconResource(void) const
{
    return QStringLiteral("/qmlimages/TuningComponentIcon.png");
}

bool APMChannelsComponent::requiresSetup(void) const
{
    return false;
}

bool APMChannelsComponent::setupComplete(void) const
{
    return true;
}

QStringList APMChannelsComponent::setupCompleteChangedTriggerList(void) const
{
    return QStringList();
}

QUrl APMChannelsComponent::setupSource(void) const
{
    return QUrl::fromUserInput(QStringLiteral("qrc:/qml/APMChannelsComponent.qml"));
}

QUrl APMChannelsComponent::summaryQmlSource(void) const
{
    return QUrl();
}