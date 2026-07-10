#include "WebRTCLink.h"
#include <QDebug>
#include <QtQml/qqml.h>
#include "QGCLoggingCategory.h"
#include "SettingsManager.h"
#include "CloudSettings.h"

#ifdef QGC_GST_STREAMING
#include "WebRTCBinSession.h"
#include "SignalingServerManager.h"
#endif

QGC_LOGGING_CATEGORY(WebRTCLinkLog, "Comms.WEBRTCLink")

//------------------------------------------------------
// WebRTCLink — GStreamer webrtcbin backend (WebRTCBinSession).
//------------------------------------------------------
WebRTCLink::WebRTCLink(SharedLinkConfigurationPtr &config, QObject *parent)
    : LinkInterface(config, parent)
{
    qRegisterMetaType<RTCModuleSystemInfo>("RTCModuleSystemInfo");
    qRegisterMetaType<WebRTCStats>("WebRTCStats");
    qRegisterMetaType<VideoMetrics>("VideoMetrics");
    qRegisterMetaType<RTCModuleVersionInfo>("RTCModuleVersionInfo");

    _rtcConfig = qobject_cast<const WebRTCConfiguration*>(config.get());

    // Pre-create these SettingsFacts on the main thread so later access doesn't
    // build them off-thread and trip QML binding cross-thread errors.
    auto* cloudSettings = SettingsManager::instance()->cloudSettings();
    (void)cloudSettings->webrtcAuthClientId();
    (void)cloudSettings->webrtcAuthClientSecret();
    (void)cloudSettings->webrtcBindAddress();

#ifdef QGC_GST_STREAMING
    WebRTCBinSession::Config cfg;
    cfg.gcsId         = _rtcConfig->gcsId();
    cfg.targetDroneId = _rtcConfig->targetDroneId();
    QString stun = _rtcConfig->stunServer();
    if (!stun.isEmpty() && !stun.startsWith(QStringLiteral("stun:"))) {
        stun = QStringLiteral("stun://") + stun;
    }
    cfg.stunServer = stun;
    const auto turn = SignalingServerManager::instance()->cachedTurnCredentials();
    cfg.turn.urls       = turn.urls;
    cfg.turn.username   = turn.username;
    cfg.turn.credential = turn.credential;

    _binSession = new WebRTCBinSession(cfg, this);
    connect(_binSession, &WebRTCBinSession::connected,                   this, &WebRTCLink::_onConnected);
    connect(_binSession, &WebRTCBinSession::disconnected,               this, &WebRTCLink::_onDisconnected);
    connect(_binSession, &WebRTCBinSession::mavlinkDataReceived,        this, &WebRTCLink::_onDataReceived);
    connect(_binSession, &WebRTCBinSession::bytesSent,                  this, &WebRTCLink::_onDataSent);
    connect(_binSession, &WebRTCBinSession::rtcModuleSystemInfoUpdated, this, &WebRTCLink::_onRtcModuleSystemInfoUpdated);
    connect(_binSession, &WebRTCBinSession::videoMetricsUpdated,        this, &WebRTCLink::_onVideoMetricsUpdated);
    connect(_binSession, &WebRTCBinSession::rtcModuleVersionInfoUpdated,this, &WebRTCLink::_onRtcModuleVersionInfoUpdated);
    connect(_binSession, &WebRTCBinSession::webRtcStatsUpdated,         this, &WebRTCLink::_onWebRtcStatsUpdated);
    _binSession->start();
    qCInfo(WebRTCLinkLog) << "WebRTCLink using webrtcbin backend";
#else
    qCWarning(WebRTCLinkLog) << "WebRTC requires GStreamer video streaming (QGC_ENABLE_GST_VIDEOSTREAMING); link is inert";
#endif
}

WebRTCLink::~WebRTCLink()
{
    qCDebug(WebRTCLinkLog) << "[WebRTCLink] Destructor called";
#ifdef QGC_GST_STREAMING
    if (_binSession) {
        _binSession->stop();   // unregisters the GCS + tears down the pipeline
    }
#endif
    qCDebug(WebRTCLinkLog) << "[WebRTCLink] Destructor completed";
}

bool WebRTCLink::isConnected() const
{
    // Reflect the real webrtcbin peer state, not merely that the session object
    // exists. The Link Management UI reads this (linkConnected) to decide the
    // "연결됨/대기" chip and the "해제/연결" toggle; returning true while the peer is
    // down left the card stuck showing a live connection after the drone dropped.
    return _connected;
}

void WebRTCLink::connectLink()
{
    QMetaObject::invokeMethod(this, "_connect", Qt::QueuedConnection);
}

void WebRTCLink::reconnectLink()
{
    qCDebug(WebRTCLinkLog) << "Manual reconnection requested";
#ifdef QGC_GST_STREAMING
    if (_binSession) {
        _binSession->stop();
        _binSession->start();
    }
#endif
}

bool WebRTCLink::isReconnecting() const
{
    return false;
}

bool WebRTCLink::_connect()
{
    // Connection is driven by the signaling server / webrtcbin session on construction.
    return true;
}

void WebRTCLink::disconnect()
{
    // Guard against re-entrant/multiple calls, as the LinkInterface contract requires.
    // disconnected() below runs LinkManager/VehicleLinkManager cleanup which, via
    // LinkInterface::_connectionRemoved(), calls disconnect() again — without this guard
    // that re-entry (nested inside the QML "해제" handler) tore down twice and froze the UI.
    if (_disconnecting) {
        return;
    }
    _disconnecting = true;

#ifdef QGC_GST_STREAMING
    if (_binSession) {
        _binSession->stop();   // tears down the pipeline + unregisters the GCS
    }
#endif

    if (_connected) {
        _connected = false;
        emit linkConnectedChanged();
    }

    // Defer the disconnected() cascade out of the current call stack. It frees this link
    // (and can delete us) and updates QML; emitting it synchronously from inside the QML
    // click handler / the _connectionRemoved() re-entry deadlocked the UI. A queued emit
    // lets the caller fully unwind first. Safe if we're destroyed meanwhile — Qt drops the
    // pending event.
    QMetaObject::invokeMethod(this, [this]() { emit disconnected(); }, Qt::QueuedConnection);
}

void WebRTCLink::_writeBytes(const QByteArray& bytes)
{
#ifdef QGC_GST_STREAMING
    if (_binSession) {
        _binSession->sendMavlink(bytes);
    }
#else
    Q_UNUSED(bytes)
#endif
}

void WebRTCLink::_onConnected()
{
    qCDebug(WebRTCLinkLog) << "[WebRTCLink] Connected";
    _onRtcStatusMessageChanged("RTC 연결됨");
    if (!_connected) {
        _connected = true;
        emit linkConnectedChanged();   // updates linkConnected in the Link Management UI
    }
    emit connected();
}

void WebRTCLink::_onDisconnected()
{
    qCDebug(WebRTCLinkLog) << "[WebRTCLink] Disconnected";
    _onRtcStatusMessageChanged("RTC 연결 종료");
    if (_connected) {
        _connected = false;
        emit linkConnectedChanged();   // card reverts to "대기/연결" instead of staying "연결됨/해제"
    }
    emit disconnected();
}

void WebRTCLink::_onErrorOccurred(const QString &errorString)
{
    qCDebug(WebRTCLinkLog) << "[WebRTCLink] Error: " << errorString;
}

void WebRTCLink::_onDataReceived(const QByteArray &data)
{
    emit bytesReceived(this, data);
}

void WebRTCLink::_onDataSent(const QByteArray &data)
{
    emit bytesSent(this, data);
}

void WebRTCLink::_onRtcStatusMessageChanged(const QString& message)
{
    if (_rtcStatusMessage != message) {
        _rtcStatusMessage = message;
        emit rtcStatusMessageChanged();
    }
}

bool WebRTCLink::isVideoStreamActive() const
{
    return _binSession != nullptr;
}

void WebRTCLink::_onWebRtcStatsUpdated(const WebRTCStats& stats)
{
    if (_webRtcStats != stats) {
        if (_webRtcStats.iceCandidate != stats.iceCandidate) {
            qCDebug(WebRTCLinkLog) << "ICE candidate changed:"
                                  << _webRtcStats.iceCandidate << "->" << stats.iceCandidate;
        }
        _webRtcStats = stats;
        emit webRtcStatsChanged(stats);
    }
}

void WebRTCLink::_onRtcModuleSystemInfoUpdated(const RTCModuleSystemInfo& systemInfo)
{
    if (_rtcModuleSystemInfo != systemInfo) {
        _rtcModuleSystemInfo = systemInfo;
        emit rtcModuleSystemInfoChanged(systemInfo);
    }
}

void WebRTCLink::_onVideoMetricsUpdated(const VideoMetrics& videoMetrics)
{
    if (_videoMetrics != videoMetrics) {
        _videoMetrics = videoMetrics;
        emit videoMetricsChanged(videoMetrics);
    }
}

void WebRTCLink::_onRtcModuleVersionInfoUpdated(const RTCModuleVersionInfo& versionInfo)
{
    if (_rtcModuleVersionInfo != versionInfo) {
        _rtcModuleVersionInfo = versionInfo;
        qCDebug(WebRTCLinkLog) << "RTC Module Version Info Updated:" << versionInfo.toString();
        emit rtcModuleVersionInfoChanged(versionInfo);
    }
}

void WebRTCLink::sendCustomMessage(const QString& message)
{
    Q_UNUSED(message)
    qCDebug(WebRTCLinkLog) << "sendCustomMessage is not supported on the webrtcbin backend";
}
