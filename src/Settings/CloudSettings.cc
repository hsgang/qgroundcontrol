/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "CloudSettings.h"
#include "FactMetaData.h"
#include "QGCLoggingCategory.h"

#include <QQmlEngine>
#include <QtQml>
#include <QtCore/QSettings>

QGC_LOGGING_CATEGORY(CloudSettingsLog, "Settings.CloudSettings")

DECLARE_SETTINGGROUP(Cloud, "Cloud")
{
    qmlRegisterUncreatableType<CloudSettings>("QGroundControl.SettingsManager", 1, 0, "CloudSettings", "Reference only");
    _applyBuildTimeDefaults();
}

void CloudSettings::_applyBuildTimeDefaults()
{
    // Credentials injected at build time (see CMakeLists.txt). Each entry
    // overrides the JSON Fact default only when a non-empty value was baked in,
    // so unconfigured builds keep the defaults from Cloud.SettingsGroup.json.
    // User-saved values in QSettings still take precedence over these defaults.
    const struct { const char *factName; const char *buildValue; } overrides[] = {
        { webrtcSignalingServerName,  QGC_WEBRTC_SIGNALING_SERVER },
        { webrtcStunServerName,       QGC_WEBRTC_STUN_SERVER },
        { webrtcTurnServerName,       QGC_WEBRTC_TURN_SERVER },
        { webrtcTurnUsernameName,     QGC_WEBRTC_TURN_USERNAME },
        { webrtcTurnPasswordName,     QGC_WEBRTC_TURN_PASSWORD },
        { webrtcAuthClientIdName,     QGC_WEBRTC_AUTH_CLIENT_ID },
        { webrtcAuthClientSecretName, QGC_WEBRTC_AUTH_CLIENT_SECRET },
    };

    // A baked credential is deployment-fixed and its input is hidden in the UI.
    // Drop any stale stored value so it can't shadow the baked default and trap
    // the user with a hidden, empty field (see SettingsFact: stored value wins).
    QSettings settings;
    if (!_settingsGroup.isEmpty()) {
        settings.beginGroup(_settingsGroup);
    }

    for (const auto &o : overrides) {
        if (!o.buildValue || (o.buildValue[0] == '\0')) {
            continue;
        }
        const auto it = _nameToMetaDataMap.constFind(QString::fromLatin1(o.factName));
        if ((it != _nameToMetaDataMap.constEnd()) && it.value()) {
            it.value()->setRawDefaultValue(QString::fromUtf8(o.buildValue));
        }
        settings.remove(QString::fromLatin1(o.factName));
    }

    // Let the settings UI hide inputs whose value is fixed by the build.
    _webrtcSignalingServerFromBuild  = (QGC_WEBRTC_SIGNALING_SERVER[0] != '\0');
    _webrtcAuthClientSecretFromBuild = (QGC_WEBRTC_AUTH_CLIENT_SECRET[0] != '\0');

    // Diagnostic only — never logs the secret value, just whether it was baked in.
    qCInfo(CloudSettingsLog).nospace()
        << "WebRTC build-time credentials: signalingServer="
        << (_webrtcSignalingServerFromBuild ? "baked" : "empty")
        << ", authClientSecret="
        << (_webrtcAuthClientSecretFromBuild ? "baked" : "empty");
}

DECLARE_SETTINGSFACT(CloudSettings, cloudEmail)
DECLARE_SETTINGSFACT(CloudSettings, cloudPassword)
DECLARE_SETTINGSFACT(CloudSettings, cloudToken)
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
