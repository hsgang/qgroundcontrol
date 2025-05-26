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

QString APMPortsComponent::name(void) const
{
    return _name;
}

QString APMPortsComponent::description(void) const
{
    return tr("Ports Setup is used to configure the serial port functions of the Vehicle.");
}

QString APMPortsComponent::iconResource(void) const
{
    return QStringLiteral("/qmlimages/TuningComponentIcon.png");
}

bool APMPortsComponent::requiresSetup(void) const
{
    return false;
}

bool APMPortsComponent::setupComplete(void) const
{
    return true;
}

QStringList APMPortsComponent::setupCompleteChangedTriggerList(void) const
{
    return QStringList();
}

QUrl APMPortsComponent::setupSource(void) const
{
    return QUrl::fromUserInput(QStringLiteral("qrc:/qml/APMPortsComponent.qml"));
}

QUrl APMPortsComponent::summaryQmlSource(void) const
{
    return QUrl();
}
