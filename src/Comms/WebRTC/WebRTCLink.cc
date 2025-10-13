#include "WebRTCLink.h"
#include <QDebug>
#include <QUrl>
#include <QtQml/qqml.h>
#include "QGCLoggingCategory.h"
#include "VideoManager.h"
#include "SignalingServerManager.h"
#include "SettingsManager.h"
#include "CloudSettings.h"

QGC_LOGGING_CATEGORY(WebRTCLinkLog, "Comms.WEBRTCLink")

const QString WebRTCWorker::kDataChannelLabel = "mavlink";

/*===========================================================================*/
// WebRTCConfiguration Implementation
/*===========================================================================*/

WebRTCConfiguration::WebRTCConfiguration(const QString &name, QObject *parent)
    : LinkConfiguration(name, parent)
{
    _gcsId = "gcs_" + _generateRandomId();
    _targetDroneId = "";
}

WebRTCConfiguration::WebRTCConfiguration(const WebRTCConfiguration *copy, QObject *parent)
    : LinkConfiguration(copy, parent)
      , _gcsId(copy->_gcsId)
      , _targetDroneId(copy->_targetDroneId)
{
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
    }
}

// CloudSettings에서 WebRTC 설정을 가져오는 getter 메서드들
QString WebRTCConfiguration::stunServer() const
{
    return SettingsManager::instance()->cloudSettings()->webrtcStunServer()->rawValue().toString();
}

QString WebRTCConfiguration::turnServer() const
{
    return SettingsManager::instance()->cloudSettings()->webrtcTurnServer()->rawValue().toString();
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

/*===========================================================================*/
// WebRTCWorker Implementation
/*===========================================================================*/

WebRTCWorker::WebRTCWorker(const WebRTCConfiguration *config, 
    const QString &stunServer, 
    const QString &turnServer, 
    const QString &turnUsername, 
    const QString &turnPassword, 
    QObject *parent)
    : QObject(parent)
      , _config(config)
      , _stunServer(stunServer)
      , _turnServer(turnServer)
      , _turnUsername(turnUsername)
      , _turnPassword(turnPassword)
      , _videoStreamActive(false)
      , _isDisconnecting(false)
{
    initializeLogger();
    _setupSignalingManager();

    _statsTimer = new QTimer(this);
    connect(_statsTimer, &QTimer::timeout, this, &WebRTCWorker::_updateAllStatistics);

    // 재연결 타이머는 유지하되 자동 실행은 비활성화
    _reconnectTimer = new QTimer(this);
    _reconnectTimer->setSingleShot(true);
    connect(_reconnectTimer, &QTimer::timeout, this, &WebRTCWorker::reconnectToRoom);

    _remoteDescriptionSet.store(false);
}

WebRTCWorker::~WebRTCWorker()
{
    _cleanupComplete();
}

void WebRTCWorker::initializeLogger()
{
    //rtc::InitLogger(rtc::LogLevel::Debug);
}

void WebRTCWorker::start()
{
    //qCDebug(WebRTCLinkLog) << "Starting WebRTC worker";
    
    // Reset shutdown state for new connection
    _isShuttingDown.store(false);
    _isDisconnecting = false;
    _dataChannelOpened.store(false);
    _remoteDescriptionSet.store(false);
    
    // Clear any existing state
    {
        QMutexLocker locker(&_candidateMutex);
        _pendingCandidates.clear();
    }
    
    // Store current GCS and target drone information
    _currentGcsId = _config->gcsId();
    _currentTargetDroneId = _config->targetDroneId();
    _gcsRegistered = false;
    
    // SignalingServerManager에 GCS 등록 요청
    if (_signalingManager) {
        qCDebug(WebRTCLinkLog) << "Requesting GCS registration to SignalingServerManager";
        qCDebug(WebRTCLinkLog) << "GCS ID:" << _config->gcsId() << " Target Drone:" << _config->targetDroneId();
        _signalingManager->registerGCS(_config->gcsId(), _config->targetDroneId());
    } else {
        qCWarning(WebRTCLinkLog) << "Signaling manager not available";
    }
}

void WebRTCWorker::writeData(const QByteArray &data)
{
    if (_isShuttingDown.load()) {
        return;
    }

    try {
        if (_mavlinkDataChannel && _mavlinkDataChannel->isOpen()) {
            std::string_view view(data.constData(), data.size());
            _mavlinkDataChannel->send(rtc::binary(reinterpret_cast<const std::byte*>(view.data()),
                                           reinterpret_cast<const std::byte*>(view.data() + view.size())));

            _dataChannelSentCalc.addData(data.size());

            emit bytesSent(data);
        }
    } catch (const std::exception& e) {
        if (!_isShuttingDown.load()) {
            qCWarning(WebRTCLinkLog) << "Failed to send data:" << e.what();
            emit errorOccurred(QString("Failed to send data: %1").arg(e.what()));
        }
    }
}

void WebRTCWorker::sendCustomMessage(const QString& message)
{
    if (_isShuttingDown.load()) {
        qCWarning(WebRTCLinkLog) << "Cannot send custom message: shutting down";
        return;
    }

    try {
        if (_customDataChannel && _customDataChannel->isOpen()) {
            // QString을 binary 데이터로 변환하여 전송
            QByteArray data = message.toUtf8();
            std::string_view view(data.constData(), data.size());
            _customDataChannel->send(rtc::binary(
                reinterpret_cast<const std::byte*>(view.data()),
                reinterpret_cast<const std::byte*>(view.data() + view.size())
                ));

            qCDebug(WebRTCLinkLog) << "Custom message sent:" << message;
        } else {
            qCWarning(WebRTCLinkLog) << "Custom DataChannel not available or not open";
        }
    } catch (const std::exception& e) {
        if (!_isShuttingDown.load()) {
            qCWarning(WebRTCLinkLog) << "Failed to send custom message:" << e.what();
        }
    }
}

void WebRTCWorker::disconnectLink()
{
    qCDebug(WebRTCLinkLog) << "Disconnecting WebRTC link (user initiated)";
    
    // 사용자 의도적 해제로 표시
    _isShuttingDown.store(true);
    
    // 자동 재연결 중일 때는 실제 연결 해제를 하지 않음
    if (_waitingForReconnect.load()) {
        qCDebug(WebRTCLinkLog) << "Auto-reconnection in progress, ignoring manual disconnect request";
        return;
    }
    
    // Check signaling server connection status before disconnection
    if (_signalingManager) {
        qCDebug(WebRTCLinkLog) << "Signaling server connection status before disconnect:"
                              << " isConnected:" << _signalingManager->isConnected()
                              << " WebSocket state:" << (_signalingManager->isConnected() ? "Connected" : "Disconnected");
    }
    
    // Stop reconnection timer if running and disable auto-reconnect
    if (_reconnectTimer && _reconnectTimer->isActive()) {
        _reconnectTimer->stop();
        qCDebug(WebRTCLinkLog) << "Stopped auto-reconnect timer";
    }
    _waitingForReconnect.store(false);
    
    // Unregister GCS if we're currently registered
    if (_signalingManager && !_currentGcsId.isEmpty()) {
        qCDebug(WebRTCLinkLog) << "Unregistering GCS:" << _currentGcsId;
        _signalingManager->unregisterGCS(_currentGcsId);
        emit rtcStatusMessageChanged("서버에서 GCS 등록 해제중...");
        
        // Give some time for the leave message to be sent before cleanup
        QTimer::singleShot(1000, this, [this]() {
                    // 자동 재연결 중이 아닐 때만 완전한 정리 수행
        if (!_waitingForReconnect.load()) {
            _cleanupComplete();
        }
            emit rttUpdated(-1);
            emit disconnected();
        });
    } else {
        // If not in a room, cleanup immediately
        if (!_waitingForReconnect.load()) {
            _cleanupComplete();
        }
        emit rttUpdated(-1);
        emit disconnected();
    }
}

bool WebRTCWorker::isDataChannelOpen() const
{
    return _mavlinkDataChannel && _mavlinkDataChannel->isOpen();
}

bool WebRTCWorker::isOperational() const {
    return !_isShuttingDown.load() && !_isDisconnecting;
}

void WebRTCWorker::_setupSignalingManager()
{
    // Use singleton instance instead of creating new one
    _signalingManager = SignalingServerManager::instance();

    // Qt::QueuedConnection을 사용하여 스레드 간 안전한 시그널 연결
    connect(_signalingManager, &SignalingServerManager::connected, 
            this, &WebRTCWorker::_onSignalingConnected, Qt::QueuedConnection);
    connect(_signalingManager, &SignalingServerManager::disconnected, 
            this, &WebRTCWorker::_onSignalingDisconnected, Qt::QueuedConnection);
    connect(_signalingManager, &SignalingServerManager::connectionError, 
            this, &WebRTCWorker::_onSignalingError, Qt::QueuedConnection);
    connect(_signalingManager, &SignalingServerManager::messageReceived, 
            this, &WebRTCWorker::_onSignalingMessageReceived, Qt::QueuedConnection);
    
    // Connect registration signals
    connect(_signalingManager, &SignalingServerManager::registrationSuccessful,
            this, &WebRTCWorker::_onRegistrationSuccessful, Qt::QueuedConnection);
    connect(_signalingManager, &SignalingServerManager::registrationFailed,
            this, &WebRTCWorker::_onRegistrationFailed, Qt::QueuedConnection);
    
    // Connect GCS management signals
    connect(_signalingManager, &SignalingServerManager::gcsUnregisteredSuccessfully,
            this, &WebRTCWorker::_onGcsUnregisteredSuccessfully, Qt::QueuedConnection);
    connect(_signalingManager, &SignalingServerManager::gcsUnregisterFailed,
            this, &WebRTCWorker::_onGcsUnregisterFailed, Qt::QueuedConnection);
}

void WebRTCWorker::_onSignalingConnected()
{
    qCDebug(WebRTCLinkLog) << "Signaling server connected";
    emit rtcStatusMessageChanged("서버와 연결됨");
}

void WebRTCWorker::_onSignalingDisconnected()
{
    qCDebug(WebRTCLinkLog) << "Signaling server disconnected";
    
    if (_signalingManager && _signalingManager->isWebSocketOnlyConnected()) {
        qCDebug(WebRTCLinkLog) << "WebSocket-only mode: Ignoring disconnection event";
        return;
    }
    
    emit rtcStatusMessageChanged("서버와 연결 해제됨");
}

void WebRTCWorker::_onSignalingError(const QString& error)
{
    qCWarning(WebRTCLinkLog) << "Signaling error:" << error;
    emit rtcStatusMessageChanged(QString("서버 오류: %1").arg(error));
    emit errorOccurred(error);
}

void WebRTCWorker::_onSignalingMessageReceived(const QJsonObject& message)
{
    _handleSignalingMessage(message);
}

void WebRTCWorker::_onRegistrationSuccessful()
{
    //qCDebug(WebRTCLinkLog) << "Registration successful signal received";
    emit rtcStatusMessageChanged("서버에 등록 완료");
}

void WebRTCWorker::_onRegistrationFailed(const QString& reason)
{
    qCWarning(WebRTCLinkLog) << "Registration failed:" << reason;
    emit rtcStatusMessageChanged(QString("서버에 등록 실패: %1").arg(reason));
    emit errorOccurred(QString("Registration failed: %1").arg(reason));
}

void WebRTCWorker::_onGcsUnregisteredSuccessfully(const QString& gcsId)
{
    if (gcsId != _currentGcsId) {
        return; // Not our GCS
    }
    
    qCDebug(WebRTCLinkLog) << "Successfully unregistered GCS:" << gcsId;
    _gcsRegistered = false;
    
    // Clear current GCS information
    _currentGcsId.clear();
    _currentTargetDroneId.clear();
    
    // Reset connection state
    _dataChannelOpened.store(false);
    _remoteDescriptionSet.store(false);
    _isDisconnecting = false;
    
    // Clear pending candidates
    {
        QMutexLocker locker(&_candidateMutex);
        _pendingCandidates.clear();
    }
    
    qCDebug(WebRTCLinkLog) << "GCS unregistered successfully";
    
    emit rtcStatusMessageChanged("서버에서 GCS 등록 해제");
    
    // 자동 재연결 중일 때는 완전한 정리를 하지 않음
    if (_waitingForReconnect.load()) {
        qCDebug(WebRTCLinkLog) << "Auto-reconnection in progress, skipping complete cleanup";
        return;
    }
}

void WebRTCWorker::_onGcsUnregisterFailed(const QString& gcsId, const QString& reason)
{
    if (gcsId != _currentGcsId) {
        return; // Not our GCS
    }
    
    qCWarning(WebRTCLinkLog) << "Failed to unregister GCS:" << reason;
    emit rtcStatusMessageChanged(QString("서버에서 GCS 등록 해제 실패: %1").arg(reason));
    
    // Still clear the GCS info and proceed with cleanup
    _currentGcsId.clear();
    _currentTargetDroneId.clear();
    
    // Reset connection state even on failure
    _dataChannelOpened.store(false);
    _remoteDescriptionSet.store(false);
    _isDisconnecting = false;
    
    // Clear pending candidates
    {
        QMutexLocker locker(&_candidateMutex);
        _pendingCandidates.clear();
    }
    
    // 자동 재연결 중일 때는 완전한 정리를 하지 않음
    if (_waitingForReconnect.load()) {
        qCDebug(WebRTCLinkLog) << "Auto-reconnection in progress, skipping complete cleanup after unregister failure";
        return;
    }
}

void WebRTCWorker::reconnectToRoom()
{
    if (_isShuttingDown.load()) {
        qCDebug(WebRTCLinkLog) << "Shutting down, not reconnecting";
        return;
    }
    
    // 재연결 시도 횟수 체크
    if (_reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
        qCWarning(WebRTCLinkLog) << "Max reconnection attempts reached:" << MAX_RECONNECT_ATTEMPTS;
        emit rtcStatusMessageChanged("최대 재연결 시도 횟수 초과");
        emit errorOccurred("최대 재연결 시도 횟수를 초과했습니다");
        _waitingForReconnect.store(false);
        return;
    }
    
    _reconnectAttempts++;
    qCDebug(WebRTCLinkLog) << "Attempting to reconnect to signaling server (attempt" << _reconnectAttempts << "/" << MAX_RECONNECT_ATTEMPTS << ")";
    
    // SignalingServerManager가 연결 상태를 자동으로 관리하므로 여기서는 확인만
    qCDebug(WebRTCLinkLog) << "Requesting reconnection, SignalingServerManager handles connection state";
    
    // Reset state properly
    _waitingForReconnect.store(false);
    _isDisconnecting = false;
    _isShuttingDown.store(false);  // 재연결을 위해 리셋
    _dataChannelOpened.store(false);
    _remoteDescriptionSet.store(false);
    
    // Clear pending candidates
    {
        QMutexLocker locker(&_candidateMutex);
        _pendingCandidates.clear();
    }
    
    // Setup new peer connection
    _setupPeerConnection();
    
    // Store GCS and target drone information again
    _currentGcsId = _config->gcsId();
    _currentTargetDroneId = _config->targetDroneId();
    _gcsRegistered = false;
    
    if (_signalingManager) {
        qCDebug(WebRTCLinkLog) << "Reconnection GCS ID:" << _config->gcsId() << " target drone:" << _config->targetDroneId();
        _signalingManager->registerGCS(_config->gcsId(), _config->targetDroneId());
        emit rtcStatusMessageChanged(QString("재연결 시도 중 (%1/%2)").arg(_reconnectAttempts).arg(MAX_RECONNECT_ATTEMPTS));
    } else {
        qCWarning(WebRTCLinkLog) << "Signaling manager not available for reconnection";
        emit rtcStatusMessageChanged("시그널링 매니저 사용 불가");
    }
}

void WebRTCWorker::_setupPeerConnection()
{
    // SCTP 글로벌 설정 적용 (PeerConnection 생성 전에 설정)
    rtcSctpSettings sctpSettings = {};
    sctpSettings.recvBufferSize = 262144;          // 256KB 수신 버퍼
    sctpSettings.sendBufferSize = 262144;          // 256KB 송신 버퍼
    sctpSettings.maxChunksOnQueue = 1000;          // 큐 최대 청크 수
    sctpSettings.initialCongestionWindow = 10;     // 초기 혼잡 제어 윈도우
    sctpSettings.maxBurst = 5;                     // 최대 버스트
    sctpSettings.congestionControlModule = 0;      // RFC2581 혼잡 제어
    sctpSettings.delayedSackTimeMs = 200;          // 지연된 SACK
    sctpSettings.minRetransmitTimeoutMs = 1000;    // 최소 재전송 타임아웃
    sctpSettings.maxRetransmitTimeoutMs = 5000;   // 최대 재전송 타임아웃
    sctpSettings.initialRetransmitTimeoutMs = 3000; // 초기 재전송 타임아웃
    sctpSettings.maxRetransmitAttempts = 5;        // 최대 재전송 시도
    sctpSettings.heartbeatIntervalMs = 10000;      // 하트비트 간격
    rtcSetSctpSettings(&sctpSettings);

    _rtcConfig.iceServers.clear();

    // 스레드 안전성을 위해 복사된 설정값 사용
    if (!_stunServer.isEmpty()) {
        _rtcConfig.iceServers.emplace_back(_stunServer.toStdString());
    }

    // Add TURN server
    if (!_turnServer.isEmpty()) {
        rtc::IceServer turnServer(
            _turnServer.toStdString(),  // hostname
            3478,                       // 포트 (필요시 파싱)
            _turnUsername.toStdString(),
            _turnPassword.toStdString(),
            rtc::IceServer::RelayType::TurnUdp
            );
        _rtcConfig.iceServers.emplace_back(turnServer);
    }

    try {
        _peerConnection = std::make_shared<rtc::PeerConnection>(_rtcConfig);

        _peerConnection->onStateChange([this](rtc::PeerConnection::State state) {
            if (isOperational()) {
                QMetaObject::invokeMethod(this, "handlePeerStateChange",
                                          Qt::QueuedConnection,
                                          Q_ARG(int, static_cast<int>(state)));
            }
        });

        _peerConnection->onLocalDescription([this](rtc::Description description) {
            if (isOperational()) {
                QString descType = QString::fromStdString(description.typeString());
                QString sdpContent = QString::fromStdString(description);

                QMetaObject::invokeMethod(this, "handleLocalDescription",
                                          Qt::QueuedConnection,
                                          Q_ARG(QString, descType),
                                          Q_ARG(QString, sdpContent));
            }
        });

        _peerConnection->onLocalCandidate([this](rtc::Candidate candidate) {
            if (isOperational()) {
                QString candidateStr = QString::fromStdString(candidate);
                QString mid = QString::fromStdString(candidate.mid());

                QMetaObject::invokeMethod(this, "handleLocalCandidate",
                                          Qt::QueuedConnection,
                                          Q_ARG(QString, candidateStr),
                                          Q_ARG(QString, mid));
            }
        });

        _peerConnection->onTrack([this](std::shared_ptr<rtc::Track> track) {
            if (isOperational()) {
                QMetaObject::invokeMethod(this, [this, track]() {
                    if (isOperational()) {
                        _handleTrackReceived(track);
                    }
                }, Qt::QueuedConnection);
            }
        });

        _peerConnection->onDataChannel([this](std::shared_ptr<rtc::DataChannel> dc) {
            if (!dc) {
                qCDebug(WebRTCLinkLog) << "[DATACHANNEL] ERROR: DataChannel is null!";
                return;
            }

            if (_isShuttingDown.load()) {
                qCDebug(WebRTCLinkLog) << "[DATACHANNEL] Shutting down, ignoring";
                return;
            }

            std::string label = dc->label();
            // qCDebug(WebRTCLinkLog) << "[DATACHANNEL] DataChannel received - Label:"
            //                           << QString::fromStdString(label);

            if (label == "mavlink") {
                //qCDebug(WebRTCLinkLog) << "[DATACHANNEL] Setting up mavlink DataChannel";
                _mavlinkDataChannel = dc;
                _setupMavlinkDataChannel(dc);
            } else if (label == "custom") {
                //qCDebug(WebRTCLinkLog) << "[DATACHANNEL] Setting up custom DataChannel";
                _customDataChannel = dc;
                _setupCustomDataChannel(dc);
            } else {
                qCDebug(WebRTCLinkLog) << "[DATACHANNEL] Unknown DataChannel label:" << QString::fromStdString(label);
            }

            // 즉시 상태 확인
            if (dc->isOpen()) {
                _processDataChannelOpen();
            }
        });

        //qCDebug(WebRTCLinkLog) << "Peer connection created successfully";

    } catch (const std::exception& e) {
        qCDebug(WebRTCLinkLog) << "Failed to create peer connection:" << e.what();
        emit errorOccurred(QString("Failed to create peer connection: %1").arg(e.what()));
    }
}

void WebRTCWorker::handleLocalDescription(const QString& descType, const QString& sdpContent) {
    if (!isOperational()) return;

    qCDebug(WebRTCLinkLog) << "[SDP] Local description created, type:" << descType;

    QJsonObject message;
    message["id"] = _currentGcsId;
    message["to"] = _currentTargetDroneId;
    message["type"] = descType;
    message["sdp"] = sdpContent;

    _sendSignalingMessage(message);
}

void WebRTCWorker::handleLocalCandidate(const QString& candidateStr, const QString& mid) {
    if (!isOperational()) return;

    qCDebug(WebRTCLinkLog) << "[ICE] Local candidate generated:" << candidateStr.left(50) << "...";

    QJsonObject message;
    message["id"] = _currentGcsId;
    message["to"] = _currentTargetDroneId;
    message["type"] = "candidate";
    message["candidate"] = candidateStr;
    message["sdpMid"] = mid;

    _sendSignalingMessage(message);
}

void WebRTCWorker::handlePeerStateChange(int stateValue) {
    if (!isOperational()) return;

    auto state = static_cast<rtc::PeerConnection::State>(stateValue);
    //qCDebug(WebRTCLinkLog) << "[STATE] PeerConnection state changed to:" << stateValue;
    _onPeerStateChanged(state);
}



void WebRTCWorker::_setupMavlinkDataChannel(std::shared_ptr<rtc::DataChannel> dc)
{
    if (!dc) return;

    dc->onOpen([this]() {
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] MavlinkDataChannel OPENED";
        if (!_isShuttingDown.load()) {
            _processDataChannelOpen();
        }
    });

    dc->onClosed([this]() {
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] DataChannel CLOSED";
        if (!_isShuttingDown.load()) {
            _dataChannelOpened = false;
            QMetaObject::invokeMethod(this, [this]() {
                if (!_isDisconnecting) {
                    emit rttUpdated(-1);
                }
            }, Qt::QueuedConnection);
        }
    });

    dc->onError([this](std::string error) {
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] ERROR:" << QString::fromStdString(error);
        if (!_isShuttingDown.load()) {
            QString errorMsg = QString::fromStdString(error);
            QMetaObject::invokeMethod(this, [this, errorMsg]() {
                emit errorOccurred("DataChannel error: " + errorMsg);
            }, Qt::QueuedConnection);
        }
    });

    dc->onMessage([this, dc](auto data) {
        if (_isShuttingDown.load()) return;

        if (std::holds_alternative<rtc::binary>(data)) {
            const auto& binaryData = std::get<rtc::binary>(data);
            QByteArray byteArray(reinterpret_cast<const char*>(binaryData.data()), binaryData.size());
            _dataChannelReceivedCalc.addData(byteArray.size());

            emit bytesReceived(byteArray);
        }
        else if (std::holds_alternative<std::string>(data)) {
            const std::string& text = std::get<std::string>(data);
        }
    });
}

void WebRTCWorker::_setupCustomDataChannel(std::shared_ptr<rtc::DataChannel> dc)
{
    if (!dc) return;

    dc->onOpen([this]() {
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] CustomDataChannel OPENED";
    });

    dc->onClosed([this]() {
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] CustomDataChannel CLOSED";
    });

    dc->onError([this](std::string error) {
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] CustomDataChannel ERROR:" << QString::fromStdString(error);
    });

    dc->onMessage([this, dc](auto data) {
        
        if (_isShuttingDown.load()) {
            return;
        }

        if (std::holds_alternative<rtc::binary>(data)) {
            const auto& binaryData = std::get<rtc::binary>(data);
            qCDebug(WebRTCLinkLog) << "[CUSTOM] Binary data size:" << binaryData.size() << "bytes";
            
            auto byteArrayPtr = std::make_shared<QByteArray>(
                reinterpret_cast<const char*>(binaryData.data()), binaryData.size()
                );

            _dataChannelReceivedCalc.addData(binaryData.size());

            // 바이너리 데이터를 문자열로 변환
            QString receivedText = QString::fromUtf8(*byteArrayPtr);
            qCDebug(WebRTCLinkLog) << "[CUSTOM] Raw text:" << receivedText;
            
        } else if (std::holds_alternative<std::string>(data)) {
            const std::string& receivedText = std::get<std::string>(data);
            //qCDebug(WebRTCLinkLog) << "[CUSTOM] String data received:" << QString::fromStdString(receivedText);

            // JSON 파싱 시도
            QJsonParseError parseError;
            QJsonDocument jsonDoc = QJsonDocument::fromJson(QString::fromStdString(receivedText).toUtf8(), &parseError);
            
            if (parseError.error == QJsonParseError::NoError) {
                QJsonObject jsonObj = jsonDoc.object();
                
                // system_info 타입인지 확인
                if (jsonObj.contains("type") && jsonObj["type"].toString() == "system_info") {
                    // RTCModuleSystemInfo 구조체로 파싱하여 효율적으로 전달
                    RTCModuleSystemInfo systemInfo(jsonObj);
                    
                    if (systemInfo.isValid()) {
                        //qCDebug(WebRTCLinkLog) << "RTC Module System Info:" << systemInfo.toString();
                        emit rtcModuleSystemInfoUpdated(systemInfo);
                    } else {
                        qCWarning(WebRTCLinkLog) << "Invalid RTC module system info received";
                    }
                } else if (jsonObj.contains("type") && jsonObj["type"].toString() == "version_check") {
                    // RTCModuleVersionInfo 구조체로 파싱하여 효율적으로 전달
                    RTCModuleVersionInfo versionInfo(jsonObj);
                    
                    if (versionInfo.isValid()) {
                        qCDebug(WebRTCLinkLog) << "RTC Module Version Info:" << versionInfo.toString();
                        emit rtcModuleVersionInfoUpdated(versionInfo);
                    } else {
                        qCWarning(WebRTCLinkLog) << "Invalid RTC module version info received";
                    }
                } else {
                    // 다른 타입의 JSON 데이터인 경우
                    qCDebug(WebRTCLinkLog) << "CustomDataChannel received JSON (String):" << QString::fromStdString(receivedText);
                }
            } else {
                qCDebug(WebRTCLinkLog) << "CustomDataChannel received plain text:" << QString::fromStdString(receivedText);
            }
        } else {
            qCDebug(WebRTCLinkLog) << "[CUSTOM] Unknown data type received";
        }
    });
}

void WebRTCWorker::_processDataChannelOpen()
{
    if (_dataChannelOpened.exchange(true)) {
        //qCDebug(WebRTCLinkLog) << "[DATACHANNEL] Already opened, ignoring";
        return;
    }

    if (_isShuttingDown.load()) {
        //qCDebug(WebRTCLinkLog) << "[DATACHANNEL] Shutting down, ignoring open";
        return;
    }

    if (!_mavlinkDataChannel || !_mavlinkDataChannel->isOpen()) {
        //qCDebug(WebRTCLinkLog) << "[DATACHANNEL] ERROR: DataChannel not actually open!";
        _dataChannelOpened.store(false);
        return;
    }

    QMetaObject::invokeMethod(this, [this]() {
        emit connected();
        emit rtcStatusMessageChanged("데이터 채널 연결 성공");

        _startTimers();
    }, Qt::QueuedConnection);
}

void WebRTCWorker::_startTimers()
{
    if (!_rttTimer) {
        _rttTimer = new QTimer(this);
        connect(_rttTimer, &QTimer::timeout, this, &WebRTCWorker::_updateRtt);
        _rttTimer->start(1000);
    }

    if (!_statsTimer->isActive()) {
        _statsTimer->start(1000);
    }
}

void WebRTCWorker::_handleTrackReceived(std::shared_ptr<rtc::Track> track)
{
    auto desc = track->description();

    if (desc.type() == "video") {
        qCDebug(WebRTCLinkLog) << "[WebRTC] Video track received";
        _videoTrack = track;
        emit videoTrackReceived();

        if (VideoManager::instance()->isWebRtcInternalModeEnabled()) {
            _videoStreamActive = true;
            qCDebug(WebRTCLinkLog) << "[WebRTC] Internal mode: video stream active";
        }

        track->onMessage([this](rtc::message_variant message) {
            if (std::holds_alternative<rtc::binary>(message)) {
                if (_isShuttingDown.load() || !_videoStreamActive) {
                    return;
                }

                const auto& binaryData = std::get<rtc::binary>(message);
                QByteArray rtpData(reinterpret_cast<const char*>(binaryData.data()), binaryData.size());

                if (VideoManager::instance() && VideoManager::instance()->isWebRtcInternalModeEnabled()) {
                    _videoReceivedCalc.addData(rtpData.size());
                    VideoManager::instance()->pushWebRtcRtp(rtpData);
                }
            }
        });

        auto session = std::make_shared<rtc::RtcpReceivingSession>();
        track->setMediaHandler(session);
    }
}



void WebRTCWorker::_handleSignalingMessage(const QJsonObject& message)
{
    if (!message.contains("type")) {
        qCWarning(WebRTCLinkLog) << "Invalid signaling message format: missing type";
        return;
    }

    QString remoteId = message["to"].toString();
    QString type = message["type"].toString();

    // if (remoteId != _config->peerId()) {
    //     return;
    // }

    // offer 타입은 _onWebRTCOfferReceived에서 처리됨
    
    if (type == "answer") {
        qCDebug(WebRTCLinkLog) << "[SIGNALING] Processing ANSWER";

        try {
            QString sdp = message["sdp"].toString();
            rtc::Description answer(sdp.toStdString(), "answer");

            if (!_peerConnection) {
                qCWarning(WebRTCLinkLog) << "[ANSWER] No peer connection available";
                return;
            }

            _peerConnection->setRemoteDescription(answer);
            _remoteDescriptionSet.store(true);
            _processPendingCandidates();

            qCDebug(WebRTCLinkLog) << "[ANSWER] Processed successfully";

        } catch (const std::exception& e) {
            qCWarning(WebRTCLinkLog) << "[ANSWER] Processing failed:" << e.what();
        }

    } else if (type == "peerDisconnected") {
        QString disconnectedId = message["id"].toString();
        if (disconnectedId == _currentTargetDroneId) {
            qCWarning(WebRTCLinkLog) << "Peer disconnected by signaling server:" << disconnectedId;

            _handlePeerDisconnection();
        }

    } else if (type == "registered") {
        _onGCSRegistered(message);
    } else if (type == "offer") {
        _onWebRTCOfferReceived(message);
    } else if (type == "candidate") {
        _handleICECandidate(message);
    } else if (type == "ping") {
        _sendPongResponse(message);
    } else if (type == "error") {
        _onErrorReceived(message);
    }
}

void WebRTCWorker::_onGCSRegistered(const QJsonObject& message)
{
    if (message["success"].toBool()) {
        QString pairedDroneId = message["pairedWith"].toString();
        qCDebug(WebRTCLinkLog) << "GCS registered successfully, paired with drone:" << pairedDroneId;
        
        // 드론과 페어링 완료, 드론의 WebRTC offer 대기
        emit rtcStatusMessageChanged("서버 등록 완료, 기체 연결 대기 중...");
        
        // GCS는 offer를 받을 준비만 하고, 직접 연결을 시작하지 않음
        _prepareForWebRTCOffer();
    } else {
        QString reason = message["reason"].toString();
        qCWarning(WebRTCLinkLog) << "GCS registration failed:" << reason;
        emit rtcStatusMessageChanged(QString("등록 실패: %1").arg(reason));
        emit errorOccurred(QString("등록 실패: %1").arg(reason));
    }
}

void WebRTCWorker::_prepareForWebRTCOffer()
{
    // GCS는 answerer 역할이므로 offer를 기다림
    // PeerConnection은 offer를 받을 때 설정 (중복 설정 방지)
    qCDebug(WebRTCLinkLog) << "GCS prepared as WebRTC answerer, waiting for drone offer";
}

void WebRTCWorker::_onWebRTCOfferReceived(const QJsonObject& message)
{
    QString fromDroneId = message["from"].toString();

    // 표준 WebRTC offer 형식 처리
    QString sdp = message["sdp"].toString();
    if (sdp.isEmpty()) {
        qCWarning(WebRTCLinkLog) << "Invalid offer format: missing 'sdp' field";
        return;
    }

    qCDebug(WebRTCLinkLog) << "Received WebRTC offer from drone:" << fromDroneId;

    try {
        // WebRTC offer 처리
        rtc::Description droneOffer(sdp.toStdString(), "offer");

        // 재협상(re-handshake) 처리: 기존 연결이 있으면 재설정
        if (_peerConnection) {
            qCDebug(WebRTCLinkLog) << "Re-handshake detected: resetting existing PeerConnection";

            // 기존 PeerConnection 정리
            _resetPeerConnection();

            // 재협상을 위한 상태 초기화
            _remoteDescriptionSet.store(false);
            _dataChannelOpened.store(false);

            // pending candidates 정리
            {
                QMutexLocker locker(&_candidateMutex);
                _pendingCandidates.clear();
            }

            emit rtcStatusMessageChanged("재협상 시작: 기존 연결 재설정 중...");
        }

        // 새 PeerConnection 생성 (초기 연결 또는 재협상)
        qCDebug(WebRTCLinkLog) << "Creating new PeerConnection for drone offer";
        _setupPeerConnection();

        // 드론의 offer를 remote description으로 설정
        _peerConnection->setRemoteDescription(droneOffer);
        _remoteDescriptionSet.store(true);

        // pending candidates 처리
        _processPendingCandidates();

        qCDebug(WebRTCLinkLog) << "Drone offer processed successfully, creating answer";

        // GCS는 answerer이므로 answer 생성
        _peerConnection->setLocalDescription(rtc::Description::Type::Answer);

        emit rtcStatusMessageChanged("드론으로부터 WebRTC offer 수신, 연결 설정 중...");

    } catch (const std::exception& e) {
        qCWarning(WebRTCLinkLog) << "Failed to process drone offer:" << e.what();
        emit errorOccurred(QString("드론 offer 처리 실패: %1").arg(e.what()));
    }
}

void WebRTCWorker::_handleICECandidate(const QJsonObject& message)
{
    QString fromDroneId = message["from"].toString();
    
    // 표준 WebRTC ICE candidate 형식 처리
    QString candidateStr = message["candidate"].toString();
    QString sdpMid = message["sdpMid"].toString();
    
    if (candidateStr.isEmpty() || sdpMid.isEmpty()) {
        qCWarning(WebRTCLinkLog) << "Invalid ICE candidate format: missing 'candidate' or 'sdpMid' field";
        return;
    }
    
    if (!_peerConnection) {
        qCWarning(WebRTCLinkLog) << "No peer connection available for candidate";
        return;
    }
    
    qCDebug(WebRTCLinkLog) << "Received ICE candidate from:" << fromDroneId;
    
    try {
        rtc::Candidate iceCandidate(candidateStr.toStdString(), sdpMid.toStdString());
        
        if (_remoteDescriptionSet.load(std::memory_order_acquire)) {
            qCDebug(WebRTCLinkLog) << "Adding ICE candidate immediately";
            _peerConnection->addRemoteCandidate(iceCandidate);
        } else {
            // Remote description이 설정되지 않았으면 대기
            QMutexLocker locker(&_candidateMutex);
            _pendingCandidates.push_back(iceCandidate);
            qCDebug(WebRTCLinkLog) << "ICE candidate queued, waiting for remote description";
        }
    } catch (const std::exception& e) {
        qCWarning(WebRTCLinkLog) << "Failed to process ICE candidate:" << e.what();
    }
}

void WebRTCWorker::_sendPongResponse(const QJsonObject& pingMsg)
{
    QJsonObject pongMsg;
    pongMsg["type"] = "pong";
    pongMsg["timestamp"] = pingMsg["timestamp"];
    
    _sendSignalingMessage(pongMsg);
}

void WebRTCWorker::_onErrorReceived(const QJsonObject& message)
{
    QString errorMessage = message["message"].toString();
    QString errorCode = message["code"].toString();
    
    qCWarning(WebRTCLinkLog) << "Signaling server error:" << errorCode << "-" << errorMessage;
    if (errorCode == "drone_already_paired") {
        emit rtcStatusMessageChanged(QString("기체가 다른 장치와 페어링되어 있습니다"));
    } else {
        emit rtcStatusMessageChanged(QString("서버 오류: %1").arg(errorMessage));
    }
    emit errorOccurred(QString("서버 오류: %1").arg(errorMessage));
}

void WebRTCWorker::_handlePeerDisconnection()
{
    qCDebug(WebRTCLinkLog) << "[DISCONNECT] Handling peer disconnection";

    _dataChannelOpened.store(false);
    _isDisconnecting = false;

    // WebRTC 연결이 끊어지면 GCS 등록 해제
    if (_signalingManager && !_currentGcsId.isEmpty()) {
        qCDebug(WebRTCLinkLog) << "Unregistering GCS due to peer disconnection:" << _currentGcsId;
        _signalingManager->unregisterGCS(_currentGcsId);
        emit rtcStatusMessageChanged("피어 연결 해제 - GCS 등록 해제 중...");
    }

    _cleanupForReconnection();

    emit rttUpdated(-1);
    emit disconnected();
    
    // 사용자가 의도적으로 해제한 경우가 아닐 때만 자동 재연결 시작
    if (!_isShuttingDown.load() && !_waitingForReconnect.load()) {
        qCDebug(WebRTCLinkLog) << "[DISCONNECT] Starting automatic reconnection";
        emit rtcStatusMessageChanged("자동 재연결 시작...");
        
        // 재연결 시도 횟수 증가
        _reconnectAttempts++;
        
        if (_reconnectAttempts <= MAX_RECONNECT_ATTEMPTS) {
            int reconnectDelay = _calculateReconnectDelay();
            qCDebug(WebRTCLinkLog) << "[DISCONNECT] Scheduling reconnection in" << reconnectDelay << "ms (attempt" << _reconnectAttempts << "/" << MAX_RECONNECT_ATTEMPTS << ")";
            
            _waitingForReconnect.store(true);
            _reconnectTimer->start(reconnectDelay);
        } else {
            qCWarning(WebRTCLinkLog) << "[DISCONNECT] Max reconnection attempts reached, manual reconnection required";
            emit rtcStatusMessageChanged("최대 재연결 시도 횟수 초과, 수동 재연결 필요");
        }
    } else {
        qCDebug(WebRTCLinkLog) << "[DISCONNECT] Manual reconnection required (shutting down or already reconnecting)";
        emit rtcStatusMessageChanged("기체 연결 해제됨, 수동 재연결 필요");
    }
}

void WebRTCWorker::_resetPeerConnection()
{
    if (_mavlinkDataChannel) {
        try {
            if (_mavlinkDataChannel->isOpen()) {
                _mavlinkDataChannel->close();
            }
        } catch (const std::exception& e) {
            qCWarning(WebRTCLinkLog) << "Error closing mavlink data channel:" << e.what();
        }
        _mavlinkDataChannel.reset();
    }

    if (_customDataChannel) {
        try {
            if (_customDataChannel->isOpen()) {
                _customDataChannel->close();
            }
        } catch (const std::exception& e) {
            qCWarning(WebRTCLinkLog) << "Error closing custom data channel:" << e.what();
        }
        _customDataChannel.reset();
    }

    if (_peerConnection) {
        _peerConnection->onStateChange(nullptr);
        _peerConnection->onGatheringStateChange(nullptr);
        _peerConnection->onLocalDescription(nullptr);
        _peerConnection->onLocalCandidate(nullptr);
        _peerConnection->onDataChannel(nullptr);
        _peerConnection->onTrack(nullptr);

        try {
            _peerConnection->close();
        } catch (const std::exception& e) {
            qCWarning(WebRTCLinkLog) << "Error closing peer connection:" << e.what();
        }
        _peerConnection.reset();
    }

    _remoteDescriptionSet.store(false);
    {
        QMutexLocker locker(&_candidateMutex);
        _pendingCandidates.clear();
    }
}

void WebRTCWorker::_cleanupForReconnection()
{
    qCDebug(WebRTCLinkLog) << "[CLEANUP] Cleaning up for reconnection (keeping WebSocket)";

    _resetPeerConnection();
    _videoTrack.reset();

    _remoteDescriptionSet.store(false);
    {
        QMutexLocker locker(&_candidateMutex);
        _pendingCandidates.clear();
    }

    if (_rttTimer) {
        _rttTimer->stop();
        _rttTimer->deleteLater();
        _rttTimer = nullptr;
    }

    if (_statsTimer && _statsTimer->isActive()) {
        _statsTimer->stop();
    }

    _dataChannelSentCalc.reset();
    _dataChannelReceivedCalc.reset();
    _videoReceivedCalc.reset();

    qCDebug(WebRTCLinkLog) << "[CLEANUP] Cleanup completed, ready for new connection";
}



void WebRTCWorker::_sendSignalingMessage(const QJsonObject& message)
{
    if (!_signalingManager) {
        qCWarning(WebRTCLinkLog) << "Cannot send signaling message: signaling manager not available";
        return;
    }
    _signalingManager->sendMessage(message);
}

void WebRTCWorker::_processPendingCandidates()
{
    QMutexLocker locker(&_candidateMutex);

    if (!_peerConnection || _pendingCandidates.empty()) {
        return;
    }

    qCDebug(WebRTCLinkLog) << "Processing" << _pendingCandidates.size() << "pending candidates";

    auto candidatesToProcess = std::move(_pendingCandidates);
    _pendingCandidates.clear();

    for (const auto& candidate : candidatesToProcess) {
        try {
            _peerConnection->addRemoteCandidate(candidate);
            qCDebug(WebRTCLinkLog) << "Added pending candidate:"
                                   << QString::fromStdString(candidate);
        } catch (const std::exception& e) {
            qCWarning(WebRTCLinkLog) << "Failed to add pending candidate:" << e.what();
        }
    }
}

void WebRTCWorker::_onPeerStateChanged(rtc::PeerConnection::State state)
{
    QString stateStr = _stateToString(state);
    //qCDebug(WebRTCLinkLog) << "PeerConnection State Changed:" << stateStr;

    emit rtcStatusMessageChanged(stateStr);

    if (state == rtc::PeerConnection::State::Connected) {
        qCDebug(WebRTCLinkLog) << "PeerConnection fully connected!";
        // 연결 성공 시 재연결 타이머 중지
        if (_reconnectTimer && _reconnectTimer->isActive()) {
            _reconnectTimer->stop();
            qCDebug(WebRTCLinkLog) << "Stopped reconnection timer - connection successful";
        }
        _waitingForReconnect.store(false);
        _resetReconnectAttempts(); // 재연결 시도 횟수 리셋
        
        if (_mavlinkDataChannel && _mavlinkDataChannel->isOpen()) {
            qCDebug(WebRTCLinkLog) << "DataChannel already open, no reconnection needed";
            return;
        }
    }

    if ((state == rtc::PeerConnection::State::Failed ||
         state == rtc::PeerConnection::State::Disconnected) && !_isDisconnecting) {
        qCDebug(WebRTCLinkLog) << "[DEBUG] PeerConnection failed/disconnected – scheduling reconnect";

        // WebRTC 연결이 끊어져도 시그널링 서버 연결은 유지
        // 방에서 나가지 않고 WebRTC만 재연결
        emit rtcStatusMessageChanged("WebRTC 연결 끊김 - 재연결 시도 중...");

        // 재연결 타이머 시작 (지수 백오프 적용)
        if (!_waitingForReconnect.load()) {
            _waitingForReconnect.store(true);
            int reconnectDelay = _calculateReconnectDelay();
            qCDebug(WebRTCLinkLog) << "Starting reconnection timer with delay:" << reconnectDelay << "ms";
            _reconnectTimer->start(reconnectDelay);
        }
    }
}

void WebRTCWorker::_onGatheringStateChanged(rtc::PeerConnection::GatheringState state)
{
    emit rtcStatusMessageChanged(_gatheringStateToString(state));
    qCDebug(WebRTCLinkLog) << "ICE gathering state changed:" << _gatheringStateToString(state);

    if (state == rtc::PeerConnection::GatheringState::Complete) {
        if (_peerConnection->localDescription().has_value()) {
            auto desc = _peerConnection->localDescription().value();
            qCDebug(WebRTCLinkLog) << "[DEBUG] ICE Gathering Complete";
        } else {
            qCDebug(WebRTCLinkLog) << "[DEBUG] ICE Gathering Complete → Local Description: [None]";
        }

        for (auto &ice : _rtcConfig.iceServers) {
            qCDebug(WebRTCLinkLog) << "[DEBUG] Configured ICE Server: "
                                   << QString::fromStdString(ice.hostname);
        }
    }
}

void WebRTCWorker::_updateRtt()
{
    if (!_peerConnection) return;

    auto rttOpt = _peerConnection->rtt();
    if (rttOpt.has_value()) {
        int rttMs = rttOpt.value().count();
        _rttMs = rttMs; // RTT 값을 저장
        
        // WebRTCStats 구조체로 통합하여 전달
        WebRTCStats stats;
        stats.rttMs = _rttMs;
        stats.webRtcSent = _dataChannelSentCalc.getCurrentRate();
        stats.webRtcRecv = _dataChannelReceivedCalc.getCurrentRate();
        stats.videoRateKBps = _videoReceivedCalc.getCurrentRate();
        stats.videoPacketCount = _videoReceivedCalc.getStats().totalPackets;
        stats.videoBytesReceived = _videoReceivedCalc.getStats().totalBytes;
        
        emit webRtcStatsUpdated(stats);
        
        // 기존 시그널도 유지 (호환성을 위해)
        emit rttUpdated(rttMs);
    }
}

QString WebRTCWorker::_stateToString(rtc::PeerConnection::State state) const
{
    switch (state) {
        case rtc::PeerConnection::State::New: return "피어 생성";
        case rtc::PeerConnection::State::Connecting: return "피어 연결중...";
        case rtc::PeerConnection::State::Connected: return "피어 연결됨";
        case rtc::PeerConnection::State::Disconnected: return "피어 연결 끊김";
        case rtc::PeerConnection::State::Failed: return "피어 연결 실패";
        case rtc::PeerConnection::State::Closed: return "피어 연결 해제";
    }
    return "Unknown";
}

QString WebRTCWorker::_gatheringStateToString(rtc::PeerConnection::GatheringState state) const
{
    switch (state) {
        case rtc::PeerConnection::GatheringState::New: return "새로운 ICE 수집중...";
        case rtc::PeerConnection::GatheringState::InProgress: return "ICE 수집 처리중...";
        case rtc::PeerConnection::GatheringState::Complete: return "ICE 수집 완료";
    }
    return "Unknown";
}

void WebRTCWorker::_cleanup()
{
    // _isShuttingDown을 true로 설정하지 않음 (재연결을 위해)
    _isDisconnecting = true;
    _dataChannelOpened.store(false);

    qCDebug(WebRTCLinkLog) << "Cleaning up WebRTC resources";

    // 통계 타이머 정리
    if (_statsTimer) {
        _statsTimer->stop();
    }

    _resetPeerConnection();

    if (_rttTimer) {
        _rttTimer->stop();
        _rttTimer->deleteLater();
        _rttTimer = nullptr;
    }

    _remoteDescriptionSet.store(false);
    {
        QMutexLocker locker(&_candidateMutex);
        _pendingCandidates.clear();
    }
}

void WebRTCWorker::_cleanupComplete()
{
    // 자동 재연결 중이 아닐 때만 완전한 종료 수행
    if (_waitingForReconnect) {
        qCDebug(WebRTCLinkLog) << "Auto-reconnection in progress, skipping complete cleanup";
        return;
    }
    
    // 완전한 종료 시에만 _isShuttingDown 설정
    _isShuttingDown.store(true);
    _cleanup();
    
    // Clear GCS information
    _currentGcsId.clear();
    _currentTargetDroneId.clear();
    _gcsRegistered = false;
    
    // Check signaling server connection status after cleanup
    if (_signalingManager) {
        qCDebug(WebRTCLinkLog) << "Signaling server connection status after cleanup:"
                              << " isConnected:" << _signalingManager->isConnected()
                              << " WebSocket state:" << (_signalingManager->isConnected() ? "Connected" : "Disconnected");
        qCDebug(WebRTCLinkLog) << "Note: Signaling server connection remains active for other peers";
    }
    
    // Don't disconnect the global signaling manager, it remains connected for other peers
}

// Video bridge related functions removed

void WebRTCWorker::_updateAllStatistics()
{
    _dataChannelSentCalc.updateRate();
    _dataChannelReceivedCalc.updateRate();
    _videoReceivedCalc.updateRate();

    // WebRTCStats 구조체로 통합하여 전달
    WebRTCStats stats;
    stats.rttMs = _rttMs;
    stats.webRtcSent = _dataChannelSentCalc.getCurrentRate();
    stats.webRtcRecv = _dataChannelReceivedCalc.getCurrentRate();
    stats.videoRateKBps = _videoReceivedCalc.getCurrentRate();
    stats.videoPacketCount = _videoReceivedCalc.getStats().totalPackets;
    stats.videoBytesReceived = _videoReceivedCalc.getStats().totalBytes;

    // qCDebug(WebRTCLinkLog) << "[DC]" << "SENT:" << stats.webRtcSent << "KB/s"
    //                         << " RECV:" << stats.webRtcRecv << "KB/s"
    //                         << "[Video]" << "RECV:" << stats.videoRateKBps << "KB/s";

    // 통합된 통계 시그널 발생
    emit webRtcStatsUpdated(stats);
    
    // 기존 개별 시그널들도 유지 (호환성을 위해)
    emit dataChannelStatsUpdated(stats.webRtcSent, stats.webRtcRecv);
    emit videoStatsUpdated(stats.videoRateKBps, stats.videoPacketCount, stats.videoBytesReceived);
    emit videoRateChanged(stats.videoRateKBps);
}

void WebRTCWorker::_calculateDataChannelRates(qint64 currentTime)
{
    // DataChannel 송신/수신 통계 업데이트
    _dataChannelSentCalc.updateRate();
    _dataChannelReceivedCalc.updateRate();
    
    // 비디오 통계 업데이트
    _videoReceivedCalc.updateRate();
    
    // WebRTCStats 구조체로 통합하여 전달
    WebRTCStats stats;
    stats.rttMs = _rttMs;
    stats.webRtcSent = _dataChannelSentCalc.getCurrentRate();
    stats.webRtcRecv = _dataChannelReceivedCalc.getCurrentRate();
    stats.videoRateKBps = _videoReceivedCalc.getCurrentRate();
    stats.videoPacketCount = _videoReceivedCalc.getStats().totalPackets;
    stats.videoBytesReceived = _videoReceivedCalc.getStats().totalBytes;
    
    // 통합된 통계 시그널 발생
    emit webRtcStatsUpdated(stats);
    
    // 기존 개별 시그널들도 유지 (호환성을 위해)
    emit dataChannelStatsUpdated(stats.webRtcSent, stats.webRtcRecv);
    emit videoStatsUpdated(stats.videoRateKBps, stats.videoPacketCount, stats.videoBytesReceived);
    emit videoRateChanged(stats.videoRateKBps);
    
    // 전체 통계 업데이트 시그널
    emit statisticsUpdated();
}

int WebRTCWorker::_calculateReconnectDelay() const
{
    // 지수 백오프 전략: 2^attempt * base_delay, 최대 30초
    int delay = BASE_RECONNECT_DELAY_MS * (1 << _reconnectAttempts);
    
    // 최대 지연 시간 제한
    if (delay > MAX_RECONNECT_DELAY_MS) {
        delay = MAX_RECONNECT_DELAY_MS;
    }
    
    // 약간의 랜덤성 추가 (네트워크 혼잡 방지)
    int jitter = (QRandomGenerator::global()->bounded(1000)) - 500; // -500ms ~ +500ms
    delay += jitter;
    
    if (delay < 1000) delay = 1000; // 최소 1초
    
    qCDebug(WebRTCLinkLog) << "Calculated reconnect delay:" << delay << "ms (attempt:" << _reconnectAttempts << ")";
    return delay;
}

void WebRTCWorker::_resetReconnectAttempts()
{
    _reconnectAttempts = 0;
    //qCDebug(WebRTCLinkLog) << "Reconnect attempts reset";
}

bool WebRTCWorker::isWaitingForReconnect() const
{
    return _waitingForReconnect.load();
}

//------------------------------------------------------
// WebRTCLink (구현)
//------------------------------------------------------
WebRTCLink::WebRTCLink(SharedLinkConfigurationPtr &config, QObject *parent)
    : LinkInterface(config, parent)
{
    // 메타타입 등록
    qRegisterMetaType<RTCModuleSystemInfo>("RTCModuleSystemInfo");
    qRegisterMetaType<WebRTCStats>("WebRTCStats");
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
    connect(_worker, &WebRTCWorker::rtcModuleVersionInfoUpdated, this, &WebRTCLink::_onRtcModuleVersionInfoUpdated, Qt::QueuedConnection);

    _workerThread->start();
}

WebRTCLink::~WebRTCLink()
{
    if (_worker) {
        // 자동 재연결 중이 아닐 때만 disconnectLink 호출
        QMetaObject::invokeMethod(_worker, "disconnectLink", Qt::BlockingQueuedConnection);
    }
    _workerThread->quit();
    _workerThread->wait();
}

bool WebRTCLink::isConnected() const
{
    // Worker가 존재하고 DataChannel이 열려있는지 확인
    if (!_worker) {
        return false;
    }
    
    // DataChannel 상태 확인
    if (!_worker->isDataChannelOpen()) {
        return false;
    }
    
    // Worker의 전체적인 운영 상태 확인
    if (!_worker->isOperational()) {
        return false;
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
        // 수동 재연결 시 재연결 시도 횟수 리셋
        QMetaObject::invokeMethod(_worker, "_resetReconnectAttempts", Qt::QueuedConnection);
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


