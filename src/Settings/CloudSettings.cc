/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "CloudSettings.h"

#include <QQmlEngine>
#include <QtQml>

DECLARE_SETTINGGROUP(Cloud, "Cloud")
{
    qmlRegisterUncreatableType<CloudSettings>("QGroundControl.SettingsManager", 1, 0, "CloudSettings", "Reference only");
}

DECLARE_SETTINGSFACT(CloudSettings, cloudEmail)
DECLARE_SETTINGSFACT(CloudSettings, cloudPassword)
DECLARE_SETTINGSFACT(CloudSettings, cloudToken)
DECLARE_SETTINGSFACT(CloudSettings, minioAccessKey)
DECLARE_SETTINGSFACT(CloudSettings, minioSecretKey)
DECLARE_SETTINGSFACT(CloudSettings, minioEndpoint)
DECLARE_SETTINGSFACT(CloudSettings, firebaseAPIKey)

// WebRTC 설정
DECLARE_SETTINGSFACT(CloudSettings, webrtcSignalingServer)
DECLARE_SETTINGSFACT(CloudSettings, webrtcStunServer)
DECLARE_SETTINGSFACT(CloudSettings, webrtcTurnServer)
DECLARE_SETTINGSFACT(CloudSettings, webrtcTurnUsername)
DECLARE_SETTINGSFACT(CloudSettings, webrtcTurnPassword)

// TURN 임시자격 발급용 auth-issuer 설정 (issuer URL은 서버 호스트에서 파생)
DECLARE_SETTINGSFACT(CloudSettings, webrtcAuthClientId)
DECLARE_SETTINGSFACT(CloudSettings, webrtcAuthClientSecret)

// 멀티홈 환경용 ICE 바인딩 주소
DECLARE_SETTINGSFACT(CloudSettings, webrtcBindAddress)
