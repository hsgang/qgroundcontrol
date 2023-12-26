/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "SIYISettings.h"

#include <QQmlEngine>
#include <QtQml>

DECLARE_SETTINGGROUP(SIYI, "SIYI")
{
    qmlRegisterUncreatableType<SIYISettings>("QGroundControl.SettingsManager", 1, 0, "SIYISettings", "Reference only");
}

DECLARE_SETTINGSFACT(SIYISettings, siyiTransmitterEnabled)
DECLARE_SETTINGSFACT(SIYISettings, siyiCameraEnabled)
