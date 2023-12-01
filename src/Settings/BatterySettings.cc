/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "BatterySettings.h"

#include <QQmlEngine>
#include <QtQml>

DECLARE_SETTINGGROUP(Battery, "Battery")
{
    qmlRegisterUncreatableType<BatterySettings>("QGroundControl.SettingsManager", 1, 0, "BatterySettings", "Reference only"); \
}

DECLARE_SETTINGSFACT(BatterySettings, batteryCellCount)
DECLARE_SETTINGSFACT(BatterySettings, showCellVoltage)


