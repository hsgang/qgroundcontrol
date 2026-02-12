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

class CloudSettings : public SettingsGroup
{
    Q_OBJECT
public:
    CloudSettings(QObject* parent = nullptr);
    DEFINE_SETTING_NAME_GROUP()

    DEFINE_SETTINGFACT(cloudEmail)
    DEFINE_SETTINGFACT(cloudPassword)
    DEFINE_SETTINGFACT(cloudToken)
    DEFINE_SETTINGFACT(minioAccessKey)
    DEFINE_SETTINGFACT(minioSecretKey)
    DEFINE_SETTINGFACT(minioEndpoint)
    DEFINE_SETTINGFACT(firebaseAPIKey)
    
    // WebRTC 설정
    DEFINE_SETTINGFACT(webrtcApiKey)
    DEFINE_SETTINGFACT(webrtcSignalingServer)
    DEFINE_SETTINGFACT(webrtcStunServer)
    DEFINE_SETTINGFACT(webrtcTurnServer)
    DEFINE_SETTINGFACT(webrtcTurnUsername)
    DEFINE_SETTINGFACT(webrtcTurnPassword)
};
