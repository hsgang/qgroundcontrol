/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "PlanViewSettings.h"

DECLARE_SETTINGGROUP(PlanView, "PlanView")
{
}

DECLARE_SETTINGSFACT(PlanViewSettings, displayPresetsTabFirst)
DECLARE_SETTINGSFACT(PlanViewSettings, showMissionItemStatus)
DECLARE_SETTINGSFACT(PlanViewSettings, useConditionGate)
DECLARE_SETTINGSFACT(PlanViewSettings, takeoffItemNotRequired)
DECLARE_SETTINGSFACT(PlanViewSettings, allowMultipleLandingPatterns)
DECLARE_SETTINGSFACT(PlanViewSettings, showGimbalOnlyWhenSet)
DECLARE_SETTINGSFACT(PlanViewSettings, vtolTransitionDistance)
DECLARE_SETTINGSFACT(PlanViewSettings, showROIToolstrip)
DECLARE_SETTINGSFACT(PlanViewSettings, missionDownload)
