#include "WebRTCConfiguration.h"
#include <QRandomGenerator>
#include "SettingsManager.h"
#include "CloudSettings.h"
#include "SignalingServerManager.h"

/*===========================================================================*/
// WebRTCConfiguration Implementation
/*===========================================================================*/

WebRTCConfiguration::WebRTCConfiguration(const QString &name, QObject *parent)
    : LinkConfiguration(name, parent)
{
    _gcsId = "gcs_" + _generateRandomId();
    _targetDroneId = "";

    // SignalingServerManager의 드론 리스트 변경 감지
    connect(SignalingServerManager::instance(), &SignalingServerManager::connectedDronesListChanged,
            this, &WebRTCConfiguration::serverConnectedChanged);
}

WebRTCConfiguration::WebRTCConfiguration(const WebRTCConfiguration *copy, QObject *parent)
    : LinkConfiguration(copy, parent)
      , _gcsId(copy->_gcsId)
      , _targetDroneId(copy->_targetDroneId)
{
    // SignalingServerManager의 드론 리스트 변경 감지
    connect(SignalingServerManager::instance(), &SignalingServerManager::connectedDronesListChanged,
            this, &WebRTCConfiguration::serverConnectedChanged);
}

WebRTCConfiguration::~WebRTCConfiguration() = default;

void WebRTCConfiguration::copyFrom(const LinkConfiguration *source)
{
    LinkConfiguration::copyFrom(source);
    auto* src = qobject_cast<const WebRTCConfiguration*>(source);
    if (src) {
        _gcsId = src->_gcsId;
        _targetDroneId = src->_targetDroneId;
    }
}

void WebRTCConfiguration::loadSettings(QSettings &settings, const QString &root)
{
    settings.beginGroup(root);
    _gcsId = settings.value("gcsId", "gcs_" + _generateRandomId()).toString();
    _targetDroneId = settings.value("targetDroneId", "").toString();
    settings.endGroup();
}

void WebRTCConfiguration::saveSettings(QSettings &settings, const QString &root) const
{
    settings.beginGroup(root);
    settings.setValue("gcsId", _gcsId);
    settings.setValue("targetDroneId", _targetDroneId);
    settings.endGroup();
}

void WebRTCConfiguration::setGcsId(const QString &id)
{
    if (_gcsId != id) {
        _gcsId = id;
        emit gcsIdChanged();
    }
}

void WebRTCConfiguration::setTargetDroneId(const QString &id)
{
    if (_targetDroneId != id) {
        _targetDroneId = id;
        emit targetDroneIdChanged();
        emit serverConnectedChanged(); // targetDroneId 변경 시에도 serverConnected 상태가 바뀜
    }
}

bool WebRTCConfiguration::serverConnected() const
{
    if (_targetDroneId.isEmpty()) {
        return false;
    }

    SignalingServerManager* signalingManager = SignalingServerManager::instance();
    if (!signalingManager) {
        return false;
    }

    return signalingManager->isDroneConnected(_targetDroneId);
}

// CloudSettings에서 WebRTC 설정을 가져오는 getter 메서드들
QString WebRTCConfiguration::stunServer() const
{
    return SettingsManager::instance()->cloudSettings()->webrtcStunServer()->rawValue().toString();
}

QString WebRTCConfiguration::turnServer() const
{
    QString turnServerHost = SettingsManager::instance()->cloudSettings()->webrtcTurnServer()->rawValue().toString();

    if (turnServerHost.isEmpty()) {
        return turnServerHost;
    }

    // turn. + turnserver + :3478 형식으로 변환
    QString result = turnServerHost;

    // turn. 프리픽스 추가 (없는 경우)
    if (!result.startsWith("turn.") && !result.startsWith("turn://") && !result.startsWith("turns://")) {
        result = "turn." + result;
    }

    // 포트 번호 추가 (없는 경우)
    if (!result.contains(":")) {
        result += ":3478";
    }

    return result;
}

QString WebRTCConfiguration::turnUsername() const
{
    return SettingsManager::instance()->cloudSettings()->webrtcTurnUsername()->rawValue().toString();
}

QString WebRTCConfiguration::turnPassword() const
{
    return SettingsManager::instance()->cloudSettings()->webrtcTurnPassword()->rawValue().toString();
}

QString WebRTCConfiguration::_generateRandomId(int length) const
{
    const QString characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    QString result;
    result.reserve(length);

    for (int i = 0; i < length; ++i) {
        int index = QRandomGenerator::global()->bounded(characters.length());
        result.append(characters.at(index));
    }

    return result;
}
