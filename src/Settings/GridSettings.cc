/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "GridSettings.h"

#include <QQmlEngine>
#include <QtQml>

DECLARE_SETTINGGROUP(Grid, "Grid")
{
    qmlRegisterUncreatableType<GridSettings>("QGroundControl.SettingsManager", 1, 0, "GridSettings", "Reference only");
}

DECLARE_SETTINGSFACT(GridSettings, valueSource)
DECLARE_SETTINGSFACT(GridSettings, latitude)
DECLARE_SETTINGSFACT(GridSettings, longitude)
DECLARE_SETTINGSFACT(GridSettings, rows)
DECLARE_SETTINGSFACT(GridSettings, columns)
DECLARE_SETTINGSFACT(GridSettings, value1)
DECLARE_SETTINGSFACT(GridSettings, value2)
DECLARE_SETTINGSFACT(GridSettings, value3)
DECLARE_SETTINGSFACT(GridSettings, value4)
DECLARE_SETTINGSFACT(GridSettings, gridSize)
