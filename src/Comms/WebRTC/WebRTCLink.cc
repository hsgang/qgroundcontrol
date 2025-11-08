#include "WebRTCLink.h"
#include <QDebug>
#include <QtQml/qqml.h>
#include "QGCLoggingCategory.h"

//------------------------------------------------------
// WebRTCLink (구현)
//------------------------------------------------------
WebRTCLink::WebRTCLink(SharedLinkConfigurationPtr &config, QObject *parent)
    : LinkInterface(config, parent)
{
    // 메타타입 등록
    qRegisterMetaType<RTCModuleSystemInfo>("RTCModuleSystemInfo");
    qRegisterMetaType<WebRTCStats>("WebRTCStats");
    qRegisterMetaType<VideoMetrics>("VideoMetrics");
    qRegisterMetaType<RTCModuleVersionInfo>("RTCModuleVersionInfo");

    _rtcConfig = qobject_cast<const WebRTCConfiguration*>(config.get());

    QString stunServer = _rtcConfig->stunServer();
    QString turnServer = _rtcConfig->turnServer();
    QString turnUsername = _rtcConfig->turnUsername();
    QString turnPassword = _rtcConfig->turnPassword();

    _worker = new WebRTCWorker(_rtcConfig, stunServer, turnServer, turnUsername, turnPassword);
    _workerThread = new QThread(this);
    _worker->moveToThread(_workerThread);

    connect(_workerThread, &QThread::started, _worker, &WebRTCWorker::start);
    connect(_workerThread, &QThread::finished, _worker, &QObject::deleteLater);

    connect(_worker, &WebRTCWorker::connected, this, &WebRTCLink::_onConnected, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::disconnected, this, &WebRTCLink::_onDisconnected, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::errorOccurred, this, &WebRTCLink::_onErrorOccurred, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::bytesReceived, this, &WebRTCLink::_onDataReceived, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::bytesSent, this, &WebRTCLink::_onDataSent, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::rtcStatusMessageChanged, this, &WebRTCLink::_onRtcStatusMessageChanged, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::rtcModuleSystemInfoUpdated, this, &WebRTCLink::_onRtcModuleSystemInfoUpdated, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::webRtcStatsUpdated, this, &WebRTCLink::_onWebRtcStatsUpdated, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::videoMetricsUpdated, this, &WebRTCLink::_onVideoMetricsUpdated, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::rtcModuleVersionInfoUpdated, this, &WebRTCLink::_onRtcModuleVersionInfoUpdated, Qt::QueuedConnection);

    _workerThread->start();
}

WebRTCLink::~WebRTCLink()
{
    qCDebug(WebRTCLinkLog) << "[WebRTCLink] Destructor called";

    if (_worker) {
        // SignalingServerManager와의 연결을 먼저 끊음 (싱글톤이므로 매우 중요!)
        QMetaObject::invokeMethod(_worker, "disconnectFromSignalingManager", Qt::BlockingQueuedConnection);

        // 워커에게 정리 요청
        QMetaObject::invokeMethod(_worker, "disconnectLink", Qt::BlockingQueuedConnection);
    }

    // 스레드 종료 요청
    _workerThread->quit();

    // 최대 5초 대기
    if (!_workerThread->wait(5000)) {
        qCWarning(WebRTCLinkLog) << "[WebRTCLink] Worker thread did not finish in time, forcing termination";
        _workerThread->terminate();
        _workerThread->wait(1000);
    }

    qCDebug(WebRTCLinkLog) << "[WebRTCLink] Destructor completed";
}

bool WebRTCLink::isConnected() const
{
    // 디버깅: 각 조건 확인
    static int debugCount = 0;
    bool shouldDebug = (++debugCount % 100 == 1); // 첫 번째와 100번마다

    // Worker가 존재하고 DataChannel이 열려있는지 확인
    if (!_worker) {
        if (shouldDebug) {
            qCDebug(WebRTCLinkLog) << "[isConnected] FALSE: _worker is null";
        }
        return false;
    }

    // DataChannel 상태 확인
    bool dcOpen = _worker->isDataChannelOpen();
    if (!dcOpen) {
        if (shouldDebug) {
            qCDebug(WebRTCLinkLog) << "[isConnected] FALSE: DataChannel not open";
        }
        return false;
    }

    // Worker의 전체적인 운영 상태 확인
    bool operational = _worker->isOperational();
    if (!operational) {
        if (shouldDebug) {
            qCDebug(WebRTCLinkLog) << "[isConnected] FALSE: Worker not operational";
        }
        return false;
    }

    if (shouldDebug) {
        qCDebug(WebRTCLinkLog) << "[isConnected] TRUE: All checks passed";
    }
    return true;
}

void WebRTCLink::connectLink()
{
    QMetaObject::invokeMethod(this, "_connect", Qt::QueuedConnection);
}

void WebRTCLink::reconnectLink()
{
    qCDebug(WebRTCLinkLog) << "Manual reconnection requested";

    if (_worker) {
        // 수동 재연결 요청
        QMetaObject::invokeMethod(_worker, "reconnectToRoom", Qt::QueuedConnection);
    } else {
        qCWarning(WebRTCLinkLog) << "Worker not available for reconnection";
    }
}

bool WebRTCLink::isReconnecting() const
{
    if (!_worker) {
        return false;
    }

    // Worker의 자동 재연결 상태를 직접 확인 (스레드 안전하지 않지만 빠름)
    // 실제로는 _waitingForReconnect가 atomic이 아니므로 더 안전한 방법 필요
    return _worker->isWaitingForReconnect();
}

bool WebRTCLink::_connect()
{
    // 실제 연결은 이미 worker가 WebSocket에서 시작하고 있음.
    return true;
}

void WebRTCLink::disconnect()
{
    if (_worker) {
        QMetaObject::invokeMethod(_worker, "disconnectLink", Qt::QueuedConnection);
    }
}

void WebRTCLink::_writeBytes(const QByteArray& bytes)
{
    QMetaObject::invokeMethod(_worker, "writeData", Qt::QueuedConnection, Q_ARG(QByteArray, bytes));
}

void WebRTCLink::_onConnected()
{
    qCDebug(WebRTCLinkLog) << "[WebRTCLink] Connected";

    _onRtcStatusMessageChanged("RTC 연결됨");
    emit connected();
}

void WebRTCLink::_onDisconnected()
{
    qCDebug(WebRTCLinkLog) << "[WebRTCLink] Disconnected";

    // 재연결 중이 아닐 때만 disconnected 시그널 발생
    if (_worker && !_worker->isWaitingForReconnect()) {
        qCDebug(WebRTCLinkLog) << "[WebRTCLink] Emitting disconnected signal (not reconnecting)";
        _onRtcStatusMessageChanged("RTC 연결 종료");
        emit disconnected();
    } else {
        qCDebug(WebRTCLinkLog) << "[WebRTCLink] Skipping disconnected signal (reconnecting)";
        _onRtcStatusMessageChanged("RTC 재연결 중...");
    }
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
    return _worker ? _worker->isVideoStreamActive() : false;
}

void WebRTCLink::_onWebRtcStatsUpdated(const WebRTCStats& stats)
{
    // 구조체 비교를 통한 효율적인 변경 감지
    if (_webRtcStats != stats) {
        // Candidate 변경 여부 로그
        if (_webRtcStats.iceCandidate != stats.iceCandidate) {
            qCDebug(WebRTCLinkLog) << "ICE candidate changed:"
                                  << _webRtcStats.iceCandidate << "->" << stats.iceCandidate;
        }

        _webRtcStats = stats;
        //qCDebug(WebRTCLinkLog) << "WebRTC Stats Updated:" << stats.toString();
        emit webRtcStatsChanged(stats);
    }
}

void WebRTCLink::_onRtcModuleSystemInfoUpdated(const RTCModuleSystemInfo& systemInfo)
{
    // 구조체 비교를 통한 효율적인 변경 감지
    if (_rtcModuleSystemInfo != systemInfo) {
        _rtcModuleSystemInfo = systemInfo;
        //qCDebug(WebRTCLinkLog) << "RTC Module System Info Updated:" << systemInfo.toString();
        emit rtcModuleSystemInfoChanged(systemInfo);
    }
}

void WebRTCLink::_onVideoMetricsUpdated(const VideoMetrics& videoMetrics)
{
    // 구조체 비교를 통한 효율적인 변경 감지
    if (_videoMetrics != videoMetrics) {
        _videoMetrics = videoMetrics;
        //qCDebug(WebRTCLinkLog) << "Video Metrics Updated:" << videoMetrics.toString();
        emit videoMetricsChanged(videoMetrics);
    }
}

void WebRTCLink::_onRtcModuleVersionInfoUpdated(const RTCModuleVersionInfo& versionInfo)
{
    // 구조체 비교를 통한 효율적인 변경 감지
    if (_rtcModuleVersionInfo != versionInfo) {
        _rtcModuleVersionInfo = versionInfo;
        qCDebug(WebRTCLinkLog) << "RTC Module Version Info Updated:" << versionInfo.toString();
        emit rtcModuleVersionInfoChanged(versionInfo);
    }
}

void WebRTCLink::sendCustomMessage(const QString& message)
{
    if (_worker) {
        QMetaObject::invokeMethod(_worker, "sendCustomMessage",
                                  Qt::QueuedConnection,
                                  Q_ARG(QString, message));
    } else {
        qCWarning(WebRTCLinkLog) << "Cannot send custom message: worker not available";
    }
}
