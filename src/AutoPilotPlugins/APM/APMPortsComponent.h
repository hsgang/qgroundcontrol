/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


#pragma once

#include "VehicleComponent.h"

class APMPortsComponent : public VehicleComponent
{
    Q_OBJECT
    
public:
    APMPortsComponent(Vehicle* vehicle, AutoPilotPlugin* autopilot, QObject* parent = nullptr);
    
    // Virtuals from VehicleComponent
    QStringList setupCompleteChangedTriggerList() const final;
    
    // Virtuals from VehicleComponent
    QString name() const final;
    QString description() const final;
    QString iconResource() const final;
    bool requiresSetup() const final;
    bool setupComplete() const final;
    QUrl setupSource() const final { return QUrl::fromUserInput(QStringLiteral("qrc:/qml/QGroundControl/AutoPilotPlugins/APM/APMPortsComponent.qml")); }
    QUrl summaryQmlSource() const final { return QUrl(); }
    bool allowSetupWhileArmed() const final { return false; }

private:
    const QString   _name;
    QVariantList    _summaryItems;
};
