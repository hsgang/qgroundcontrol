/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "FlyViewSettings.h"

#include <QQmlEngine>
#include <QtQml>

DECLARE_SETTINGGROUP(FlyView, "FlyView")
{
    qmlRegisterUncreatableType<FlyViewSettings>("QGroundControl.SettingsManager", 1, 0, "FlyViewSettings", "Reference only"); \
}

DECLARE_SETTINGSFACT(FlyViewSettings, guidedMinimumAltitude)
DECLARE_SETTINGSFACT(FlyViewSettings, guidedMaximumAltitude)
DECLARE_SETTINGSFACT(FlyViewSettings, showLogReplayStatusBar)
DECLARE_SETTINGSFACT(FlyViewSettings, alternateInstrumentPanel)
DECLARE_SETTINGSFACT(FlyViewSettings, showAdditionalIndicatorsCompass)
DECLARE_SETTINGSFACT(FlyViewSettings, showAttitudeHUD)
DECLARE_SETTINGSFACT(FlyViewSettings, lockNoseUpCompass)
DECLARE_SETTINGSFACT(FlyViewSettings, maxGoToLocationDistance)
DECLARE_SETTINGSFACT(FlyViewSettings, keepMapCenteredOnVehicle)
DECLARE_SETTINGSFACT(FlyViewSettings, showSimpleCameraControl)
DECLARE_SETTINGSFACT(FlyViewSettings, showObstacleDistanceOverlay)
DECLARE_SETTINGSFACT(FlyViewSettings, missionMaxAltitudeIndicator)
DECLARE_SETTINGSFACT(FlyViewSettings, showAtmosphericValueBar)
DECLARE_SETTINGSFACT(FlyViewSettings, showGeneratorStatus)
DECLARE_SETTINGSFACT(FlyViewSettings, showGimbalControlPannel)
DECLARE_SETTINGSFACT(FlyViewSettings, updateHomePosition)
DECLARE_SETTINGSFACT(FlyViewSettings, enableCustomActions)
DECLARE_SETTINGSFACT(FlyViewSettings, customActionDefinitions)
DECLARE_SETTINGSFACT(FlyViewSettings, showPhotoVideoControl)
DECLARE_SETTINGSFACT(FlyViewSettings, showMountControl)
DECLARE_SETTINGSFACT(FlyViewSettings, showWinchControl)
DECLARE_SETTINGSFACT(FlyViewSettings, showChartWidget)
DECLARE_SETTINGSFACT(FlyViewSettings, showMissionProgress)
DECLARE_SETTINGSFACT(FlyViewSettings, showTelemetryPanel)
DECLARE_SETTINGSFACT(FlyViewSettings, showVibrationStatus)
DECLARE_SETTINGSFACT(FlyViewSettings, showEKFStatus)
DECLARE_SETTINGSFACT(FlyViewSettings, flyviewWidgetOpacity)
DECLARE_SETTINGSFACT(FlyViewSettings, showWindvane)
DECLARE_SETTINGSFACT(FlyViewSettings, showVehicleInfoOnMap)
DECLARE_SETTINGSFACT(FlyViewSettings, showCameraProjectionOnMap)
DECLARE_SETTINGSFACT(FlyViewSettings, showEscStatus)


