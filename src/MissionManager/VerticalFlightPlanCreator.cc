/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "VerticalFlightPlanCreator.h"
#include "PlanMasterController.h"
#include "MissionSettingsItem.h"
#include "VerticalFlightComplexItem.h"

VerticalFlightPlanCreator::VerticalFlightPlanCreator(PlanMasterController* planMasterController, QObject* parent)
    : PlanCreator(planMasterController, VerticalFlightComplexItem::name, QStringLiteral("/qmlimages/PlanCreator/CorridorScanPlanCreator.png"), parent)
{

}

void VerticalFlightPlanCreator::createPlan(const QGeoCoordinate& mapCenterCoord)
{
    _planMasterController->removeAll();
    VisualMissionItem* takeoffItem = _missionController->insertTakeoffItem(mapCenterCoord, -1);
    _missionController->insertComplexMissionItem(VerticalFlightComplexItem::name, mapCenterCoord, -1);
    _missionController->insertLandItem(mapCenterCoord, -1);
    _missionController->setCurrentPlanViewSeqNum(takeoffItem->sequenceNumber(), true);
}
