/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include "SettingsGroup.h"

class SIYISettings : public SettingsGroup
{
    Q_OBJECT
public:
    SIYISettings(QObject* parent = nullptr);
    DEFINE_SETTING_NAME_GROUP()

    DEFINE_SETTINGFACT(siyiDeviceModel)
    DEFINE_SETTINGFACT(siyiUniRCEnabled)
    DEFINE_SETTINGFACT(siyiUniRCIp)
    DEFINE_SETTINGFACT(siyiUniRCTransportMode)
    DEFINE_SETTINGFACT(siyiUniRCSerialPort)
    DEFINE_SETTINGFACT(siyiUniRCSerialBaud)
    DEFINE_SETTINGFACT(siyiUniRCRelayPort)
    DEFINE_SETTINGFACT(siyiTransmitterEnabled)
    DEFINE_SETTINGFACT(siyiTransmitterIp)
    DEFINE_SETTINGFACT(siyiCameraEnabled)
    DEFINE_SETTINGFACT(siyiCameraIp)

private slots:
    // Applies the enabled-service / IP preset for the selected siyiDeviceModel.
    // Custom (0) is a no-op so manual settings are preserved.
    void _applyDeviceModelPreset();
};
