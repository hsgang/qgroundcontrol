#pragma once

#include <QtQmlIntegration/QtQmlIntegration>

#include "SettingsGroup.h"

class FlyViewSettings : public SettingsGroup
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    FlyViewSettings(QObject* parent = nullptr);

    DEFINE_SETTING_NAME_GROUP()

    DEFINE_SETTINGFACT(guidedMinimumAltitude)
    DEFINE_SETTINGFACT(guidedMaximumAltitude)
    DEFINE_SETTINGFACT(showLogReplayStatusBar)
    DEFINE_SETTINGFACT(showAdditionalIndicatorsCompass)
    DEFINE_SETTINGFACT(showAttitudeHUD)
    DEFINE_SETTINGFACT(lockNoseUpCompass)
    DEFINE_SETTINGFACT(maxGoToLocationDistance)
    DEFINE_SETTINGFACT(forwardFlightGoToLocationLoiterRad)
    DEFINE_SETTINGFACT(goToLocationRequiresConfirmInGuided)
    DEFINE_SETTINGFACT(keepMapCenteredOnVehicle)
    DEFINE_SETTINGFACT(showSimpleCameraControl)
    DEFINE_SETTINGFACT(showObstacleDistanceOverlay)
    DEFINE_SETTINGFACT(missionMaxAltitudeIndicator)
    DEFINE_SETTINGFACT(showAtmosphericValueBar)
    DEFINE_SETTINGFACT(showGeneratorStatus)
    DEFINE_SETTINGFACT(showGimbalControlPannel)
    DEFINE_SETTINGFACT(updateHomePosition)
    DEFINE_SETTINGFACT(enableCustomActions)
    DEFINE_SETTINGFACT(customActionDefinitions)
    DEFINE_SETTINGFACT(showPhotoVideoControl)
    DEFINE_SETTINGFACT(showMountControl)
    DEFINE_SETTINGFACT(showWinchControl)
    DEFINE_SETTINGFACT(showChartWidget)
    DEFINE_SETTINGFACT(showMissionProgress)
    DEFINE_SETTINGFACT(showTelemetryPanel)
    DEFINE_SETTINGFACT(showVibrationStatus)
    DEFINE_SETTINGFACT(showEKFStatus)
    DEFINE_SETTINGFACT(flyviewWidgetOpacity)
    DEFINE_SETTINGFACT(instrumentQmlFile)
    DEFINE_SETTINGFACT(showWindvane)
    DEFINE_SETTINGFACT(showVehicleInfoOnMap)
    DEFINE_SETTINGFACT(showCameraProjectionOnMap)
    DEFINE_SETTINGFACT(showEscStatus)
    DEFINE_SETTINGFACT(showSiyiCameraControl)
    DEFINE_SETTINGFACT(showGridOnMap)
    DEFINE_SETTINGFACT(showGridViewer)
    DEFINE_SETTINGFACT(showVehicleStepMoveControl)
    DEFINE_SETTINGFACT(vehicleMoveStep)
    DEFINE_SETTINGFACT(showLandingGuideView)
    DEFINE_SETTINGFACT(instrumentQmlFile2)
    DEFINE_SETTINGFACT(requestControlAllowTakeover)
    DEFINE_SETTINGFACT(requestControlTimeout)
    DEFINE_SETTINGFACT(showJoystickIndicatorInToolbar)
    DEFINE_SETTINGFACT(enableAutomaticMissionPopups)
};
