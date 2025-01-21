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

class GridSettings : public SettingsGroup
{
    Q_OBJECT
public:
    GridSettings(QObject* parent = nullptr);
    DEFINE_SETTING_NAME_GROUP()

    DEFINE_SETTINGFACT(latitude)
    DEFINE_SETTINGFACT(longitude)
    DEFINE_SETTINGFACT(rows)
    DEFINE_SETTINGFACT(columns)
    DEFINE_SETTINGFACT(value1)
    DEFINE_SETTINGFACT(value2)
    DEFINE_SETTINGFACT(value3)
    DEFINE_SETTINGFACT(value4)
    DEFINE_SETTINGFACT(gridSize)
};
