/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "SIYISettings.h"
#include "Fact.h"

#include <QQmlEngine>
#include <QtQml>

DECLARE_SETTINGGROUP(SIYI, "SIYI")
{
    qmlRegisterUncreatableType<SIYISettings>("QGroundControl.SettingsManager", 1, 0, "SIYISettings", "Reference only");

    // Selecting a device model applies its service preset. Connect after the
    // group is constructed so the fact is available.
    connect(siyiDeviceModel(), &Fact::rawValueChanged, this, &SIYISettings::_applyDeviceModelPreset);
}

DECLARE_SETTINGSFACT(SIYISettings, siyiDeviceModel)
DECLARE_SETTINGSFACT(SIYISettings, siyiUniRCEnabled)
DECLARE_SETTINGSFACT(SIYISettings, siyiUniRCIp)
DECLARE_SETTINGSFACT(SIYISettings, siyiUniRCTransportMode)
DECLARE_SETTINGSFACT(SIYISettings, siyiUniRCSerialPort)
DECLARE_SETTINGSFACT(SIYISettings, siyiUniRCSerialBaud)
DECLARE_SETTINGSFACT(SIYISettings, siyiUniRCRelayPort)
DECLARE_SETTINGSFACT(SIYISettings, siyiTransmitterEnabled)
DECLARE_SETTINGSFACT(SIYISettings, siyiTransmitterIp)
DECLARE_SETTINGSFACT(SIYISettings, siyiCameraEnabled)
DECLARE_SETTINGSFACT(SIYISettings, siyiCameraIp)

void SIYISettings::_applyDeviceModelPreset()
{
    const int model = siyiDeviceModel()->rawValue().toInt();

    // Camera/Gimbal (TCP 37256) is shared by every model.
    siyiCameraEnabled()->setRawValue(true);
    siyiCameraIp()->setRawValue(QStringLiteral("192.168.144.25"));

    if (model == 0) {
        // UniRC 7: datalink SDK over UDP (0x5566 framing, 0x40-0x4F incl. the
        // 0x4E/0x4F extensions). No TCP transmitter link.
        siyiUniRCEnabled()->setRawValue(true);
        siyiUniRCIp()->setRawValue(QStringLiteral("192.168.144.20"));
        siyiTransmitterEnabled()->setRawValue(false);
    } else {
        // MK15 (1) / MK32 (2): link status comes from the legacy TCP transmitter
        // client (192.168.144.12:5864), not the UniRC UDP datalink.
        siyiUniRCEnabled()->setRawValue(false);
        siyiTransmitterEnabled()->setRawValue(true);
        siyiTransmitterIp()->setRawValue(QStringLiteral("192.168.144.12"));
    }
}
