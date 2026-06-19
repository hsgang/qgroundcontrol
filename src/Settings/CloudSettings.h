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
    DEFINE_SETTINGFACT(webrtcSignalingServer)
    DEFINE_SETTINGFACT(webrtcStunServer)
    DEFINE_SETTINGFACT(webrtcTurnServer)
    DEFINE_SETTINGFACT(webrtcTurnUsername)
    DEFINE_SETTINGFACT(webrtcTurnPassword)

    // auth-issuer 설정: 시그널링 Bearer JWT(client_credentials) + TURN 임시자격 발급에 공용 사용.
    // issuer 주소는 webrtcSignalingServer 호스트에서 파생되므로 별도 URL 설정은 없음.
    DEFINE_SETTINGFACT(webrtcAuthClientId)
    DEFINE_SETTINGFACT(webrtcAuthClientSecret)

    // 멀티홈 환경에서 ICE가 인터넷 NIC로만 게더링하도록 바인딩할 로컬 IP (비우면 자동 선택)
    DEFINE_SETTINGFACT(webrtcBindAddress)
};
