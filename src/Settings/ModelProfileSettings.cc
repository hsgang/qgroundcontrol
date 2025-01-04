/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "ModelProfileSettings.h"

#include <QQmlEngine>
#include <QtQml>

DECLARE_SETTINGGROUP(ModelProfile, "ModelProfile")
{
    qmlRegisterUncreatableType<ModelProfileSettings>("QGroundControl.SettingsManager", 1, 0, "ModelProfileSettings", "Reference only");
}

DECLARE_SETTINGSFACT(ModelProfileSettings, modelProfileFile)
