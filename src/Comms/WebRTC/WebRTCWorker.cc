#include "WebRTCWorker.h"
#include <QDebug>
#include <QRandomGenerator>
#include "QGCLoggingCategory.h"
#include "VideoManager.h"
#include "SignalingServerManager.h"

QGC_LOGGING_CATEGORY(WebRTCLinkLog, "Comms.WEBRTCLink")

const QString WebRTCWorker::kDataChannelLabel = "mavlink";

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
{
    // 설정값을 값 객체로 복사하여 포인터 의존성 제거
    _connectionConfig.gcsId = config->gcsId();
    _connectionConfig.targetDroneId = config->targetDroneId();
    _connectionConfig.stunServer = stunServer;
    _connectionConfig.turnServer = turnServer;
    _connectionConfig.turnUsername = turnUsername;
    _connectionConfig.turnPassword = turnPassword;

    initializeLogger();
    _setupSignalingManager();

    _statsTimer = new QTimer(this);
    connect(_statsTimer, &QTimer::timeout, this, &WebRTCWorker::_updateAllStatistics);

    // 재연결 타이머 설정
    _reconnectTimer = new QTimer(this);
    _reconnectTimer->setSingleShot(true);
    connect(_reconnectTimer, &QTimer::timeout, this, &WebRTCWorker::reconnectToRoom);

    _remoteDescriptionSet.store(false);

    // 해시 링 버퍼 초기화
    _hashRingBuffer.fill(0);
}

WebRTCWorker::~WebRTCWorker()
{
    qCDebug(WebRTCLinkLog) << "WebRTCWorker destructor called";

    // 먼저 모든 타이머 정지 및 삭제
    if (_cleanupTimer) {
        _cleanupTimer->stop();
        _cleanupTimer->disconnect();
        _cleanupTimer->deleteLater();
        _cleanupTimer = nullptr;
    }

    if (_reconnectTimer) {
        _reconnectTimer->stop();
        _reconnectTimer->disconnect();
        _reconnectTimer->deleteLater();
        _reconnectTimer = nullptr;
    }

    if (_rttTimer) {
        _rttTimer->stop();
        _rttTimer->disconnect();
        _rttTimer->deleteLater();
        _rttTimer = nullptr;
    }

    if (_statsTimer) {
        _statsTimer->stop();
        _statsTimer->disconnect();
        _statsTimer->deleteLater();
        _statsTimer = nullptr;
    }

    // SignalingServerManager와의 모든 시그널 연결 끊기 (싱글톤이므로 중요!)
    if (_signalingManager) {
        disconnect(_signalingManager, nullptr, this, nullptr);
    }

    // 리소스 정리
    _cleanup(CleanupMode::Complete);

    qCDebug(WebRTCLinkLog) << "WebRTCWorker destructor completed";
}

void WebRTCWorker::initializeLogger()
{
    //rtc::InitLogger(rtc::LogLevel::Debug);
}

void WebRTCWorker::start()
{
    qCDebug(WebRTCLinkLog) << "Starting WebRTC worker";

    // Reset ALL state flags FIRST (이것이 가장 중요!)
    _isShuttingDown.store(false);
    _isDisconnecting.store(false);
    _isCleaningUp.store(false);
    _dataChannelOpened.store(false);
    _remoteDescriptionSet.store(false);
    _videoStreamActive.store(false);
    _waitingForReconnect.store(false);  // 재연결 플래그도 리셋

    // SignalingServerManager 시그널 재연결 (싱글톤이므로 이전 연결이 남아있을 수 있음)
    if (_signalingManager) {
        // 기존 연결 모두 제거
        disconnect(_signalingManager, nullptr, this, nullptr);

        // 새로 연결
        connect(_signalingManager, &SignalingServerManager::connected,
                this, &WebRTCWorker::_onSignalingConnected, Qt::QueuedConnection);
        connect(_signalingManager, &SignalingServerManager::disconnected,
                this, &WebRTCWorker::_onSignalingDisconnected, Qt::QueuedConnection);
        connect(_signalingManager, &SignalingServerManager::connectionError,
                this, &WebRTCWorker::_onSignalingError, Qt::QueuedConnection);
        connect(_signalingManager, &SignalingServerManager::messageReceived,
                this, &WebRTCWorker::_onSignalingMessageReceived, Qt::QueuedConnection);
        connect(_signalingManager, &SignalingServerManager::registrationSuccessful,
                this, &WebRTCWorker::_onRegistrationSuccessful, Qt::QueuedConnection);
        connect(_signalingManager, &SignalingServerManager::registrationFailed,
                this, &WebRTCWorker::_onRegistrationFailed, Qt::QueuedConnection);
        connect(_signalingManager, &SignalingServerManager::gcsUnregisteredSuccessfully,
                this, &WebRTCWorker::_onGcsUnregisteredSuccessfully, Qt::QueuedConnection);
        connect(_signalingManager, &SignalingServerManager::gcsUnregisterFailed,
                this, &WebRTCWorker::_onGcsUnregisterFailed, Qt::QueuedConnection);

        qCDebug(WebRTCLinkLog) << "Reconnected SignalingServerManager signals";
    }

    // 진행 중인 cleanup 타이머 취소
    if (_cleanupTimer) {
        qCDebug(WebRTCLinkLog) << "Cancelling pending cleanup timer";
        _cleanupTimer->stop();
        _cleanupTimer->disconnect();  // 모든 시그널 연결 끊기
        _cleanupTimer->deleteLater();
        _cleanupTimer = nullptr;
    }

    // 재연결 타이머도 정지
    if (_reconnectTimer && _reconnectTimer->isActive()) {
        _reconnectTimer->stop();
    }

    // 이전 PeerConnection이 남아있으면 완전히 정리
    if (_peerConnection || _mavlinkDataChannel || _customDataChannel || _videoTrack) {
        qCDebug(WebRTCLinkLog) << "Cleaning up previous connection before start";
        _resetPeerConnection();
    }

    // Clear any existing state
    {
        QMutexLocker locker(&_candidateMutex);
        _pendingCandidates.clear();
    }

    // Store current GCS and target drone information
    _currentGcsId = _connectionConfig.gcsId;
    _currentTargetDroneId = _connectionConfig.targetDroneId;
    _gcsRegistered = false;

    qCDebug(WebRTCLinkLog) << "start() completed successfully";

    // TEMPORARY DEBUG: registerGCS 호출 전후 상세 로깅
    qCDebug(WebRTCLinkLog) << "[DEBUG] About to schedule registerGCS call";
    qCDebug(WebRTCLinkLog) << "[DEBUG] _signalingManager pointer:" << (void*)_signalingManager;
    qCDebug(WebRTCLinkLog) << "[DEBUG] SignalingServerManager::instance():" << (void*)SignalingServerManager::instance();

    // SignalingServerManager에 GCS 등록 요청 (비동기로 실행하여 start()가 완전히 완료된 후 실행)
    QPointer<WebRTCWorker> self(this);
    QMetaObject::invokeMethod(this, [self]() {
        qCDebug(WebRTCLinkLog) << "[DEBUG] Lambda for registerGCS started";

        if (!self) {
            qCWarning(WebRTCLinkLog) << "Worker deleted before GCS registration";
            return;
        }

        qCDebug(WebRTCLinkLog) << "[DEBUG] Worker still alive, checking managers";
        qCDebug(WebRTCLinkLog) << "[DEBUG] _signalingManager:" << (void*)self->_signalingManager;
        qCDebug(WebRTCLinkLog) << "[DEBUG] instance():" << (void*)SignalingServerManager::instance();
        qCDebug(WebRTCLinkLog) << "[DEBUG] _isShuttingDown:" << self->_isShuttingDown.load();

        try {
            if (self->_signalingManager && SignalingServerManager::instance() && !self->_isShuttingDown.load()) {
                qCDebug(WebRTCLinkLog) << "[DEBUG] About to call registerGCS";
                qCDebug(WebRTCLinkLog) << "Requesting GCS registration to SignalingServerManager";
                qCDebug(WebRTCLinkLog) << "GCS ID:" << self->_connectionConfig.gcsId << " Target Drone:" << self->_connectionConfig.targetDroneId;

                qCDebug(WebRTCLinkLog) << "[DEBUG] Calling registerGCS NOW";
                self->_signalingManager->registerGCS(self->_connectionConfig.gcsId, self->_connectionConfig.targetDroneId);
                qCDebug(WebRTCLinkLog) << "[DEBUG] registerGCS call completed successfully";
            } else {
                qCWarning(WebRTCLinkLog) << "Signaling manager not available or worker shutting down";
            }
        } catch (const std::exception& e) {
            qCWarning(WebRTCLinkLog) << "Exception during GCS registration:" << e.what();
        } catch (...) {
            qCWarning(WebRTCLinkLog) << "Unknown exception during GCS registration";
        }

        qCDebug(WebRTCLinkLog) << "[DEBUG] Lambda for registerGCS completed";
    }, Qt::QueuedConnection);
}

void WebRTCWorker::writeData(const QByteArray &data)
{
    if (_isShuttingDown.load()) {
        qCDebug(WebRTCLinkLog) << "[WRITE] Rejected: shutting down";
        return;
    }

    // 이중 경로 모드인지 확인: 양쪽 경로가 모두 존재해야 함
    bool dualPathMode = (_mavlinkDataChannelDirect && _mavlinkDataChannelRelay);

    if (dualPathMode) {
        // 이중 경로 사용: 양쪽 모두 전송 (진정한 이중화)
        _sendDataViaPath(data, PathType::Both);
        return;
    }

    // 기존 단일 경로 (하위 호환성)
    if (!_mavlinkDataChannel || !_mavlinkDataChannel->isOpen()) {
        return;
    }

    try {
        // 버퍼 상태 확인
        size_t buffered = _mavlinkDataChannel->bufferedAmount();

        // Critical 상태: 버퍼가 75% 이상 차면 큐에 저장
        if (buffered > BUFFER_CRITICAL_THRESHOLD) {
            if (_pendingMessages.size() < MAX_PENDING_MESSAGES) {
                _pendingMessages.append(data);
                qCDebug(WebRTCLinkLog) << "Buffer critical:" << buffered
                                       << "bytes, queued message. Queue size:"
                                       << _pendingMessages.size();

                if (!_isCongested) {
                    _isCongested = true;
                    emit congestionDetected();
                    emit bufferCritical(buffered);
                }
            } else {
                qCWarning(WebRTCLinkLog) << "Message queue full, dropping packet";
            }
            return;
        }

        // Warning 상태: 버퍼가 25% 이상 차면 경고
        if (buffered > BUFFER_WARNING_THRESHOLD) {
            _consecutiveBufferWarnings++;
            if (_consecutiveBufferWarnings == 1) {
                qCDebug(WebRTCLinkLog) << "Buffer warning:" << buffered << "bytes";
                emit bufferWarning(buffered);
            }
        } else {
            _consecutiveBufferWarnings = 0;

            // 혼잡 상태에서 정상으로 회복
            if (_isCongested) {
                _isCongested = false;
                emit congestionCleared();
                qCDebug(WebRTCLinkLog) << "Congestion cleared, buffer:" << buffered << "bytes";
            }
        }

        // 데이터 전송
        std::string_view view(data.constData(), data.size());
        _mavlinkDataChannel->send(rtc::binary(reinterpret_cast<const std::byte*>(view.data()),
                                       reinterpret_cast<const std::byte*>(view.data() + view.size())));

        _dataChannelSentCalc.addData(data.size());
        emit bytesSent(data);

        // 버퍼 상태 업데이트
        _lastBufferedAmount = buffered;
        _lastBufferCheckTime = QDateTime::currentMSecsSinceEpoch();

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

void WebRTCWorker::disconnectFromSignalingManager()
{
    qCDebug(WebRTCLinkLog) << "Disconnecting from SignalingServerManager";

    if (_signalingManager) {
        disconnect(_signalingManager, nullptr, this, nullptr);
        qCDebug(WebRTCLinkLog) << "Disconnected all SignalingServerManager signals";
    }
}

void WebRTCWorker::disconnectLink()
{
    qCDebug(WebRTCLinkLog) << "Disconnecting WebRTC link (user initiated)";

    // 자동 재연결 중일 때는 먼저 재연결을 취소하고 진행
    if (_waitingForReconnect.load()) {
        qCDebug(WebRTCLinkLog) << "Canceling auto-reconnection for manual disconnect";
        _cancelReconnect();
    }

    // 이미 종료 중이고 cleanup 타이머가 실행 중이면 중복 호출 방지
    if (_isShuttingDown.load() && _cleanupTimer && _cleanupTimer->isActive()) {
        qCDebug(WebRTCLinkLog) << "Already shutting down with active cleanup timer, ignoring duplicate disconnect request";
        return;
    }

    // 사용자 의도적 해제로 표시
    _isShuttingDown.store(true);

    // Check signaling server connection status before disconnection
    if (_signalingManager) {
        qCDebug(WebRTCLinkLog) << "Signaling server connection status before disconnect:"
                              << " isConnected:" << _signalingManager->isConnected()
                              << " WebSocket state:" << (_signalingManager->isConnected() ? "Connected" : "Disconnected");
    }

    // Stop reconnection if running
    _cancelReconnect();

    // Unregister GCS if we're currently registered
    if (_signalingManager && !_currentGcsId.isEmpty()) {
        qCDebug(WebRTCLinkLog) << "Unregistering GCS:" << _currentGcsId;
        _signalingManager->unregisterGCS(_currentGcsId);
        emit rtcStatusMessageChanged("서버에서 GCS 등록 해제중...");

        // QPointer로 객체 수명 보호
        QPointer<WebRTCWorker> self(this);

        // 기존 타이머가 있으면 취소
        if (_cleanupTimer) {
            _cleanupTimer->stop();
            _cleanupTimer->deleteLater();
            _cleanupTimer = nullptr;
        }

        // Give some time for the leave message to be sent before cleanup
        _cleanupTimer = new QTimer(this);
        _cleanupTimer->setSingleShot(true);
        connect(_cleanupTimer, &QTimer::timeout, this, [self]() {
            if (!self) return;

            // start()가 다시 호출되었는지 확인
            if (!self->_isShuttingDown.load()) {
                qCDebug(WebRTCLinkLog) << "Cleanup timer fired but not shutting down, skipping cleanup";
                return;
            }

            // 완전한 정리 수행 (재연결 플래그는 이미 취소됨)
            self->_cleanup(CleanupMode::Complete);
            emit self->rttUpdated(0);
            emit self->disconnected();

            // 타이머 정리
            if (self->_cleanupTimer) {
                self->_cleanupTimer->deleteLater();
                self->_cleanupTimer = nullptr;
            }
        });
        _cleanupTimer->start(1000);
    } else {
        // If not in a room, cleanup immediately
        _cleanup(CleanupMode::Complete);
        emit rttUpdated(0);
        emit disconnected();
    }
}

bool WebRTCWorker::isDataChannelOpen() const
{
    // Dual-path 모드 확인
    if (_mavlinkDataChannelDirect || _mavlinkDataChannelRelay) {
        // Dual-path: 둘 중 하나라도 열려있으면 true
        bool directOpen = _mavlinkDataChannelDirect && _mavlinkDataChannelDirect->isOpen();
        bool relayOpen = _mavlinkDataChannelRelay && _mavlinkDataChannelRelay->isOpen();
        return directOpen || relayOpen;
    }

    // Single-path (legacy)
    return _mavlinkDataChannel && _mavlinkDataChannel->isOpen();
}

bool WebRTCWorker::isOperational() const {
    return !_isShuttingDown.load() && !_isDisconnecting.load();
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
    _isDisconnecting.store(false);

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
    _isDisconnecting.store(false);

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
    qCDebug(WebRTCLinkLog) << "Reconnect requested";

    // 이전 PeerConnection이 아직 남아있으면 정리
    if (_peerConnection) {
        qCDebug(WebRTCLinkLog) << "Cleaning up existing PeerConnection before reconnect";
        _resetPeerConnection();
    }

    qCDebug(WebRTCLinkLog) << "Attempting to reconnect (attempt" << _reconnectAttempts << ")";

    // Reset ALL state flags for reconnection
    _isShuttingDown.store(false);      // 재연결을 위해 리셋 (중요!)
    _isDisconnecting.store(false);
    _dataChannelOpened.store(false);
    _remoteDescriptionSet.store(false);
    _videoStreamActive.store(false);

    // Clear pending candidates
    {
        QMutexLocker locker(&_candidateMutex);
        _pendingCandidates.clear();
    }

    // Setup new peer connection
    _setupPeerConnection();

    // Store GCS and target drone information again
    _currentGcsId = _connectionConfig.gcsId;
    _currentTargetDroneId = _connectionConfig.targetDroneId;
    _gcsRegistered = false;

    if (_signalingManager) {
        qCDebug(WebRTCLinkLog) << "Reconnection GCS ID:" << _connectionConfig.gcsId << " target drone:" << _connectionConfig.targetDroneId;
        _signalingManager->registerGCS(_connectionConfig.gcsId, _connectionConfig.targetDroneId);
        emit rtcStatusMessageChanged(QString("재연결 시도 중 (%1)").arg(_reconnectAttempts));
    } else {
        qCWarning(WebRTCLinkLog) << "Signaling manager not available for reconnection";
        emit rtcStatusMessageChanged("시그널링 매니저 사용 불가");
    }
}

void WebRTCWorker::_setupDualPathConnections()
{
    qCDebug(WebRTCLinkLog) << "[DUAL-PATH] Setting up dual connections (Direct + Relay)";

    // SCTP 글로벌 설정 적용
    rtcSctpSettings sctpSettings = {};
    sctpSettings.recvBufferSize = SCTP_RECV_BUFFER_SIZE;
    sctpSettings.sendBufferSize = SCTP_SEND_BUFFER_SIZE;
    sctpSettings.maxChunksOnQueue = SCTP_MAX_CHUNKS_ON_QUEUE;
    sctpSettings.initialCongestionWindow = SCTP_INITIAL_CONGESTION_WINDOW;
    sctpSettings.maxBurst = SCTP_MAX_BURST;
    sctpSettings.congestionControlModule = SCTP_CONGESTION_CONTROL_MODULE;
    sctpSettings.delayedSackTimeMs = SCTP_DELAYED_SACK_TIME_MS;
    sctpSettings.minRetransmitTimeoutMs = SCTP_MIN_RETRANSMIT_TIMEOUT_MS;
    sctpSettings.maxRetransmitTimeoutMs = SCTP_MAX_RETRANSMIT_TIMEOUT_MS;
    sctpSettings.initialRetransmitTimeoutMs = SCTP_INITIAL_RETRANSMIT_TIMEOUT_MS;
    sctpSettings.maxRetransmitAttempts = SCTP_MAX_RETRANSMIT_ATTEMPTS;
    sctpSettings.heartbeatIntervalMs = SCTP_HEARTBEAT_INTERVAL_MS;
    rtcSetSctpSettings(&sctpSettings);

    // Direct P2P 연결 생성
    _setupSinglePeerConnection(_peerConnectionDirect, true);

    // Relay 연결 생성
    _setupSinglePeerConnection(_peerConnectionRelay, false);

    qCDebug(WebRTCLinkLog) << "[DUAL-PATH] Both connections created successfully";
}

void WebRTCWorker::_setupSinglePeerConnection(std::shared_ptr<rtc::PeerConnection>& pc, bool isDirect)
{
    QString pathName = isDirect ? "direct" : "relay";
    qCDebug(WebRTCLinkLog) << "[DUAL-PATH] Creating" << pathName << "PeerConnection";

    rtc::Configuration config;
    config.iceServers.clear();

    if (isDirect) {
        // Direct P2P: STUN만 사용
        if (!_connectionConfig.stunServer.isEmpty()) {
            config.iceServers.emplace_back(_connectionConfig.stunServer.toStdString());
            qCDebug(WebRTCLinkLog) << "[DUAL-PATH] Direct: Added STUN server";
        }
    } else {
        // Relay: TURN만 사용 (Direct 차단)
        if (!_connectionConfig.turnServer.isEmpty()) {
            rtc::IceServer turnServer(
                _connectionConfig.turnServer.toStdString(),
                3478,
                _connectionConfig.turnUsername.toStdString(),
                _connectionConfig.turnPassword.toStdString(),
                rtc::IceServer::RelayType::TurnUdp
            );
            config.iceServers.emplace_back(turnServer);
            qCDebug(WebRTCLinkLog) << "[DUAL-PATH] Relay: Added TURN server";
        }
    }

    try {
        pc = std::make_shared<rtc::PeerConnection>(config);
        _setupPeerConnectionCallbacks(pc, isDirect);
        qCDebug(WebRTCLinkLog) << "[DUAL-PATH]" << pathName << "PeerConnection created successfully";
    } catch (const std::exception& e) {
        qCWarning(WebRTCLinkLog) << "[DUAL-PATH] Failed to create" << pathName << "PC:" << e.what();
        emit errorOccurred(QString("Failed to create %1 connection: %2").arg(pathName, e.what()));
    }
}

void WebRTCWorker::_setupPeerConnectionCallbacks(std::shared_ptr<rtc::PeerConnection> pc, bool isDirect)
{
    if (!pc) return;

    QString pathName = isDirect ? "direct" : "relay";
    QPointer<WebRTCWorker> self(this);
    std::weak_ptr<rtc::PeerConnection> weakPC = pc;

    pc->onStateChange([self, weakPC, isDirect, pathName](rtc::PeerConnection::State state) {
        auto pc = weakPC.lock();
        if (!pc || !self || !self->isOperational()) return;

        QMetaObject::invokeMethod(self, [self, state, isDirect, pathName]() {
            if (!self) return;

            QString stateStr = self->_stateToString(state);
            qCDebug(WebRTCLinkLog) << "[DUAL-PATH]" << pathName << "state:" << stateStr;

            if (state == rtc::PeerConnection::State::Connected) {
                if (isDirect) {
                    self->_directPathActive.store(true);
                    qCDebug(WebRTCLinkLog) << "[DUAL-PATH] Direct P2P connected!";
                    emit self->rtcStatusMessageChanged("연결됨(Direct)");
                } else {
                    self->_relayPathActive.store(true);
                    qCDebug(WebRTCLinkLog) << "[DUAL-PATH] Relay connected!";
                    emit self->rtcStatusMessageChanged("연결됨(Relay)");
                }
            } else if (state == rtc::PeerConnection::State::Failed ||
                       state == rtc::PeerConnection::State::Disconnected ||
                       state == rtc::PeerConnection::State::Closed) {
                if (isDirect) {
                    self->_directPathActive.store(false);
                    qCWarning(WebRTCLinkLog) << "[DUAL-PATH] Direct path failed/disconnected";
                    if (self->_relayPathActive.load()) {
                        emit self->rtcStatusMessageChanged("Direct 실패, Relay 사용 중");
                    } else {
                        emit self->rtcStatusMessageChanged("모든 경로 연결 끊김");
                    }
                } else {
                    self->_relayPathActive.store(false);
                    qCWarning(WebRTCLinkLog) << "[DUAL-PATH] Relay path failed/disconnected";
                    if (self->_directPathActive.load()) {
                        emit self->rtcStatusMessageChanged("Relay 실패, Direct 사용 중");
                    } else {
                        emit self->rtcStatusMessageChanged("모든 경로 연결 끊김");
                    }
                }
            }
        }, Qt::QueuedConnection);
    });

    pc->onLocalDescription([self, weakPC, isDirect, pathName](rtc::Description description) {
        auto pc = weakPC.lock();
        if (!pc || !self || !self->isOperational()) return;

        QString descType = QString::fromStdString(description.typeString());
        QString sdpContent = QString::fromStdString(description);

        qCDebug(WebRTCLinkLog) << "[DUAL-PATH]" << pathName << "local description created:" << descType;

        QMetaObject::invokeMethod(self, [self, descType, sdpContent, isDirect, pathName]() {
            if (!self) return;

            // SDP에 경로 정보 추가
            QJsonObject message;
            message["id"] = self->_currentGcsId;
            message["to"] = self->_currentTargetDroneId;
            message["type"] = descType;
            message["sdp"] = sdpContent;
            message["path"] = isDirect ? "direct" : "relay";  // 경로 식별자 추가

            self->_sendSignalingMessage(message);
        }, Qt::QueuedConnection);
    });

    pc->onLocalCandidate([self, weakPC, isDirect, pathName](rtc::Candidate candidate) {
        auto pc = weakPC.lock();
        if (!pc || !self || !self->isOperational()) return;

        QString candidateStr = QString::fromStdString(candidate);
        QString mid = QString::fromStdString(candidate.mid());

        QMetaObject::invokeMethod(self, [self, candidateStr, mid, isDirect, pathName]() {
            if (!self) return;

            QJsonObject message;
            message["id"] = self->_currentGcsId;
            message["to"] = self->_currentTargetDroneId;
            message["type"] = "candidate";
            message["candidate"] = candidateStr;
            message["sdpMid"] = mid;
            message["path"] = isDirect ? "direct" : "relay";  // 경로 식별자 추가

            self->_sendSignalingMessage(message);
        }, Qt::QueuedConnection);
    });

    pc->onDataChannel([self, weakPC, isDirect, pathName](std::shared_ptr<rtc::DataChannel> dc) {
        auto pc = weakPC.lock();
        if (!pc || !self || !dc) {
            qCDebug(WebRTCLinkLog) << "[DUAL-PATH] ERROR: PeerConnection, Worker or DataChannel is null!";
            return;
        }

        if (self->_isShuttingDown.load()) {
            qCDebug(WebRTCLinkLog) << "[DUAL-PATH] Shutting down, ignoring";
            return;
        }

        std::string label = dc->label();

        QMetaObject::invokeMethod(self, [self, dc, label, isDirect, pathName]() {
            if (!self || !self->isOperational()) return;

            qCDebug(WebRTCLinkLog) << "[DUAL-PATH]" << pathName << "DataChannel received:"
                                   << QString::fromStdString(label);

            if (label == "mavlink") {
                if (isDirect) {
                    self->_mavlinkDataChannelDirect = dc;
                    qCDebug(WebRTCLinkLog) << "[DUAL-PATH] Direct mavlink DataChannel created";
                } else {
                    self->_mavlinkDataChannelRelay = dc;
                    qCDebug(WebRTCLinkLog) << "[DUAL-PATH] Relay mavlink DataChannel created";
                }
                self->_setupMavlinkDataChannel(dc, isDirect);
            } else if (label == "custom") {
                if (isDirect) {
                    self->_customDataChannelDirect = dc;
                } else {
                    self->_customDataChannelRelay = dc;
                }
                self->_setupCustomDataChannel(dc, isDirect);
            }

            // 즉시 상태 확인
            if (dc->isOpen()) {
                if (isDirect) {
                    self->_dataChannelOpenedDirect.store(true);
                } else {
                    self->_dataChannelOpenedRelay.store(true);
                }
                self->_processDataChannelOpen();
            }
        }, Qt::QueuedConnection);
    });

    pc->onTrack([self, weakPC, isDirect, pathName](std::shared_ptr<rtc::Track> track) {
        auto pc = weakPC.lock();
        if (!pc || !self || !self->isOperational()) return;

        QMetaObject::invokeMethod(self, [self, track, isDirect, pathName]() {
            if (!self || !self->isOperational()) return;

            qCDebug(WebRTCLinkLog) << "[DUAL-PATH]" << pathName << "video track received";

            if (isDirect) {
                self->_videoTrackDirect = track;
            } else {
                self->_videoTrackRelay = track;
            }

            self->_handleTrackReceived(track, isDirect);
        }, Qt::QueuedConnection);
    });
}

void WebRTCWorker::_setupPeerConnection()
{
    // 이중 경로 사용 여부 확인
    bool useDualPath = !_connectionConfig.turnServer.isEmpty() &&
                       !_connectionConfig.stunServer.isEmpty();

    if (useDualPath) {
        qCDebug(WebRTCLinkLog) << "Using dual-path mode (Direct + Relay)";
        _setupDualPathConnections();
        return;
    }

    // 기존 단일 연결 로직 (하위 호환성)
    qCDebug(WebRTCLinkLog) << "Using single-path mode (legacy)";

    // SCTP 글로벌 설정 적용 (PeerConnection 생성 전에 설정)
    rtcSctpSettings sctpSettings = {};
    sctpSettings.recvBufferSize = SCTP_RECV_BUFFER_SIZE;
    sctpSettings.sendBufferSize = SCTP_SEND_BUFFER_SIZE;
    sctpSettings.maxChunksOnQueue = SCTP_MAX_CHUNKS_ON_QUEUE;
    sctpSettings.initialCongestionWindow = SCTP_INITIAL_CONGESTION_WINDOW;
    sctpSettings.maxBurst = SCTP_MAX_BURST;
    sctpSettings.congestionControlModule = SCTP_CONGESTION_CONTROL_MODULE;
    sctpSettings.delayedSackTimeMs = SCTP_DELAYED_SACK_TIME_MS;
    sctpSettings.minRetransmitTimeoutMs = SCTP_MIN_RETRANSMIT_TIMEOUT_MS;
    sctpSettings.maxRetransmitTimeoutMs = SCTP_MAX_RETRANSMIT_TIMEOUT_MS;
    sctpSettings.initialRetransmitTimeoutMs = SCTP_INITIAL_RETRANSMIT_TIMEOUT_MS;
    sctpSettings.maxRetransmitAttempts = SCTP_MAX_RETRANSMIT_ATTEMPTS;
    sctpSettings.heartbeatIntervalMs = SCTP_HEARTBEAT_INTERVAL_MS;
    rtcSetSctpSettings(&sctpSettings);

    _rtcConfig.iceServers.clear();

    // 값 객체로 복사된 설정값 사용
    if (!_connectionConfig.stunServer.isEmpty()) {
        _rtcConfig.iceServers.emplace_back(_connectionConfig.stunServer.toStdString());
    }

    // Add TURN server
    if (!_connectionConfig.turnServer.isEmpty()) {
        rtc::IceServer turnServer(
            _connectionConfig.turnServer.toStdString(),
            3478,                       // 포트 (필요시 파싱)
            _connectionConfig.turnUsername.toStdString(),
            _connectionConfig.turnPassword.toStdString(),
            rtc::IceServer::RelayType::TurnUdp
            );
        _rtcConfig.iceServers.emplace_back(turnServer);
    }

    try {
        _peerConnection = std::make_shared<rtc::PeerConnection>(_rtcConfig);

        // QPointer로 객체 수명 보호
        QPointer<WebRTCWorker> self(this);

        // PeerConnection의 weak_ptr를 캡처하여 콜백 실행 중 삭제 방지
        std::weak_ptr<rtc::PeerConnection> weakPC = _peerConnection;

        _peerConnection->onStateChange([self, weakPC](rtc::PeerConnection::State state) {
            auto pc = weakPC.lock();
            if (!pc || !self || !self->isOperational()) return;

            QMetaObject::invokeMethod(self, "handlePeerStateChange",
                                      Qt::QueuedConnection,
                                      Q_ARG(int, static_cast<int>(state)));
        });

        _peerConnection->onLocalDescription([self, weakPC](rtc::Description description) {
            auto pc = weakPC.lock();
            if (!pc || !self || !self->isOperational()) return;

            QString descType = QString::fromStdString(description.typeString());
            QString sdpContent = QString::fromStdString(description);

            QMetaObject::invokeMethod(self, "handleLocalDescription",
                                      Qt::QueuedConnection,
                                      Q_ARG(QString, descType),
                                      Q_ARG(QString, sdpContent));
        });

        _peerConnection->onLocalCandidate([self, weakPC](rtc::Candidate candidate) {
            auto pc = weakPC.lock();
            if (!pc || !self || !self->isOperational()) return;

            QString candidateStr = QString::fromStdString(candidate);
            QString mid = QString::fromStdString(candidate.mid());

            QMetaObject::invokeMethod(self, "handleLocalCandidate",
                                      Qt::QueuedConnection,
                                      Q_ARG(QString, candidateStr),
                                      Q_ARG(QString, mid));
        });

        _peerConnection->onTrack([self, weakPC](std::shared_ptr<rtc::Track> track) {
            auto pc = weakPC.lock();
            if (!pc || !self || !self->isOperational()) return;

            QMetaObject::invokeMethod(self, [self, track]() {
                if (!self || !self->isOperational()) return;
                self->_handleTrackReceived(track);
            }, Qt::QueuedConnection);
        });

        _peerConnection->onDataChannel([self, weakPC](std::shared_ptr<rtc::DataChannel> dc) {
            auto pc = weakPC.lock();
            if (!pc || !self || !dc) {
                qCDebug(WebRTCLinkLog) << "[DATACHANNEL] ERROR: PeerConnection, Worker or DataChannel is null!";
                return;
            }

            if (self->_isShuttingDown.load()) {
                qCDebug(WebRTCLinkLog) << "[DATACHANNEL] Shutting down, ignoring";
                return;
            }

            std::string label = dc->label();

            QMetaObject::invokeMethod(self, [self, dc, label]() {
                if (!self || !self->isOperational()) return;

                if (label == "mavlink") {
                    self->_mavlinkDataChannel = dc;
                    self->_setupMavlinkDataChannel(dc);
                } else if (label == "custom") {
                    self->_customDataChannel = dc;
                    self->_setupCustomDataChannel(dc);
                } else {
                    qCDebug(WebRTCLinkLog) << "[DATACHANNEL] Unknown DataChannel label:" << QString::fromStdString(label);
                }

                // 즉시 상태 확인
                if (dc->isOpen()) {
                    self->_processDataChannelOpen();
                }
            }, Qt::QueuedConnection);
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



void WebRTCWorker::_setupMavlinkDataChannel(std::shared_ptr<rtc::DataChannel> dc, bool isDirect)
{
    if (!dc) return;

    // QPointer로 객체 수명 보호
    QPointer<WebRTCWorker> self(this);

    // BufferedAmountLow 임계값 설정
    dc->setBufferedAmountLowThreshold(BUFFER_LOW_THRESHOLD);

    // BufferedAmountLow 콜백 설정 - 버퍼가 비워지면 대기 중인 메시지 전송
    dc->onBufferedAmountLow([self]() {
        if (!self || self->_isShuttingDown.load()) return;
        qCDebug(WebRTCLinkLog) << "[BUFFER] Buffer low, processing pending messages";
        self->_processPendingMessages();
    });

    dc->onOpen([self]() {
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] MavlinkDataChannel OPENED";
        if (!self || self->_isShuttingDown.load()) return;

        // 버퍼 상태 초기화
        self->_lastBufferedAmount = 0;
        self->_consecutiveBufferWarnings = 0;
        self->_isCongested = false;
        self->_pendingMessages.clear();

        self->_processDataChannelOpen();
    });

    dc->onClosed([self]() {
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] DataChannel CLOSED";
        if (!self || self->_isShuttingDown.load()) return;

        self->_dataChannelOpened.store(false);
        QMetaObject::invokeMethod(self, [self]() {
            if (!self || self->_isDisconnecting.load()) return;
            emit self->rttUpdated(0);
        }, Qt::QueuedConnection);
    });

    dc->onError([self](std::string error) {
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] ERROR:" << QString::fromStdString(error);
        if (!self || self->_isShuttingDown.load()) return;

        QString errorMsg = QString::fromStdString(error);
        QMetaObject::invokeMethod(self, [self, errorMsg]() {
            if (!self) return;
            emit self->errorOccurred("DataChannel error: " + errorMsg);
        }, Qt::QueuedConnection);
    });

    dc->onMessage([self, isDirect](auto data) {
        if (!self || self->_isShuttingDown.load()) return;

        if (std::holds_alternative<rtc::binary>(data)) {
            const auto& binaryData = std::get<rtc::binary>(data);
            QByteArray byteArray(reinterpret_cast<const char*>(binaryData.data()), binaryData.size());

            // 이중 경로 모드인지 확인: 양쪽 경로가 모두 존재해야 함
            bool dualPathMode = (self->_mavlinkDataChannelDirect && self->_mavlinkDataChannelRelay);

            if (dualPathMode) {
                // 이중 경로: 중복 제거 처리
                self->_processReceivedData(byteArray, isDirect);
            } else {
                // 단일 경로: 직접 전달
                self->_dataChannelReceivedCalc.addData(byteArray.size());
                emit self->bytesReceived(byteArray);
            }
        }
    });
}

void WebRTCWorker::_setupCustomDataChannel(std::shared_ptr<rtc::DataChannel> dc, bool isDirect)
{
    if (!dc) return;

    // QPointer로 객체 수명 보호
    QPointer<WebRTCWorker> self(this);

    dc->onOpen([self]() {
        if (!self) return;
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] CustomDataChannel OPENED";
    });

    dc->onClosed([self]() {
        if (!self) return;
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] CustomDataChannel CLOSED";
    });

    dc->onError([self](std::string error) {
        if (!self) return;
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] CustomDataChannel ERROR:" << QString::fromStdString(error);
    });

    dc->onMessage([self](auto data) {
        if (!self || self->_isShuttingDown.load()) return;

        if (std::holds_alternative<rtc::binary>(data)) {
            const auto& binaryData = std::get<rtc::binary>(data);
            qCDebug(WebRTCLinkLog) << "[CUSTOM] Binary data size:" << binaryData.size() << "bytes";

            self->_dataChannelReceivedCalc.addData(binaryData.size());

            QByteArray byteArray(reinterpret_cast<const char*>(binaryData.data()), binaryData.size());
            QString receivedText = QString::fromUtf8(byteArray);
            qCDebug(WebRTCLinkLog) << "[CUSTOM] Binary data:" << receivedText;

        } else if (std::holds_alternative<std::string>(data)) {
            const std::string& receivedText = std::get<std::string>(data);

            // JSON 파싱 시도
            QJsonParseError parseError;
            QJsonDocument jsonDoc = QJsonDocument::fromJson(QString::fromStdString(receivedText).toUtf8(), &parseError);

            if (parseError.error == QJsonParseError::NoError) {
                QJsonObject jsonObj = jsonDoc.object();

                // system_info 타입인지 확인
                if (jsonObj.contains("type") && jsonObj["type"].toString() == "system_info") {
                    RTCModuleSystemInfo systemInfo(jsonObj);
                    if (systemInfo.isValid()) {
                        emit self->rtcModuleSystemInfoUpdated(systemInfo);
                    } else {
                        qCWarning(WebRTCLinkLog) << "Invalid RTC module system info received";
                    }
                } else if (jsonObj.contains("type") && jsonObj["type"].toString() == "video_metrics") {
                    VideoMetrics videoMetrics(jsonObj);
                    if (videoMetrics.isValid()) {
                        qCDebug(WebRTCLinkLog) << "[Video Metrics]" << videoMetrics.toString();
                        emit self->videoMetricsUpdated(videoMetrics);
                    } else {
                        qCWarning(WebRTCLinkLog) << "Invalid video metrics received";
                    }
                } else if (jsonObj.contains("type") && jsonObj["type"].toString() == "version_check") {
                    RTCModuleVersionInfo versionInfo(jsonObj);
                    if (versionInfo.isValid()) {
                        qCDebug(WebRTCLinkLog) << "RTC Module Version Info:" << versionInfo.toString();
                        emit self->rtcModuleVersionInfoUpdated(versionInfo);
                    } else {
                        qCWarning(WebRTCLinkLog) << "Invalid RTC module version info received";
                    }
                } else {
                    qCDebug(WebRTCLinkLog) << "CustomDataChannel received JSON:" << QString::fromStdString(receivedText);
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
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] Already opened, ignoring";
        return;
    }

    if (_isShuttingDown.load()) {
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] Shutting down, ignoring open";
        return;
    }

    // Dual-path 모드 확인
    bool isDualPath = (_mavlinkDataChannelDirect || _mavlinkDataChannelRelay);
    bool isConnected = false;

    if (isDualPath) {
        // Dual-path: 둘 중 하나라도 열려있으면 연결됨
        bool directOpen = _mavlinkDataChannelDirect && _mavlinkDataChannelDirect->isOpen();
        bool relayOpen = _mavlinkDataChannelRelay && _mavlinkDataChannelRelay->isOpen();
        isConnected = directOpen || relayOpen;

        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] Dual-path check - Direct:" << directOpen
                               << "Relay:" << relayOpen << "Connected:" << isConnected;
    } else {
        // Single-path (legacy)
        isConnected = _mavlinkDataChannel && _mavlinkDataChannel->isOpen();
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] Single-path check - Connected:" << isConnected;
    }

    if (!isConnected) {
        qCWarning(WebRTCLinkLog) << "[DATACHANNEL] ERROR: No DataChannel is actually open!";
        _dataChannelOpened.store(false);
        return;
    }

    qCDebug(WebRTCLinkLog) << "[DATACHANNEL] ✅ Connection established! Emitting connected signal";

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
        _rttTimer->start(RTT_UPDATE_INTERVAL_MS);
    }

    if (!_statsTimer->isActive()) {
        _statsTimer->start(STATS_UPDATE_INTERVAL_MS);
    }
}

void WebRTCWorker::_handleTrackReceived(std::shared_ptr<rtc::Track> track, bool isDirect)
{
    auto desc = track->description();

    if (desc.type() == "video") {
        QString pathName = isDirect ? "Direct" : "Relay";
        qCDebug(WebRTCLinkLog) << "[WebRTC]" << pathName << "video track received";
        _videoTrack = track;
        emit videoTrackReceived();

        if (VideoManager::instance()->isWebRtcInternalModeEnabled()) {
            _videoStreamActive.store(true);
            qCDebug(WebRTCLinkLog) << "[WebRTC] Internal mode: video stream active on" << pathName << "path";
        }

        // QPointer로 객체 수명 보호
        QPointer<WebRTCWorker> self(this);

        track->onMessage([self, isDirect, pathName](rtc::message_variant message) {
            if (!self || !std::holds_alternative<rtc::binary>(message)) return;
            if (self->_isShuttingDown.load() || !self->_videoStreamActive.load()) return;

            const auto& binaryData = std::get<rtc::binary>(message);
            QByteArray rtpData(reinterpret_cast<const char*>(binaryData.data()), binaryData.size());

            if (VideoManager::instance() && VideoManager::instance()->isWebRtcInternalModeEnabled()) {
                // 전체 통계
                self->_videoReceivedCalc.addData(rtpData.size());

                // 경로별 통계
                if (isDirect) {
                    self->_videoReceivedDirectCalc.addData(rtpData.size());
                } else {
                    self->_videoReceivedRelayCalc.addData(rtpData.size());
                }

                VideoManager::instance()->pushWebRtcRtp(rtpData);
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
            QString path = message["path"].toString();  // "direct" 또는 "relay"
            rtc::Description answer(sdp.toStdString(), "answer");

            // 이중 경로 모드
            if (!path.isEmpty()) {
                bool isDirect = (path == "direct");
                auto& pc = isDirect ? _peerConnectionDirect : _peerConnectionRelay;
                auto& remoteDescSet = isDirect ? _remoteDescriptionSetDirect : _remoteDescriptionSetRelay;

                if (!pc) {
                    qCWarning(WebRTCLinkLog) << "[ANSWER] No" << path << "peer connection available";
                    return;
                }

                qCDebug(WebRTCLinkLog) << "[DUAL-PATH] Setting remote description for" << path << "path";
                pc->setRemoteDescription(answer);
                remoteDescSet.store(true);

                qCDebug(WebRTCLinkLog) << "[ANSWER]" << path << "path processed successfully";
            } else {
                // 기존 단일 경로 (하위 호환성)
                if (!_peerConnection) {
                    qCWarning(WebRTCLinkLog) << "[ANSWER] No peer connection available";
                    return;
                }

                _peerConnection->setRemoteDescription(answer);
                _remoteDescriptionSet.store(true);
                _processPendingCandidates();

                qCDebug(WebRTCLinkLog) << "[ANSWER] Processed successfully";
            }

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
    // Shutting down 중이면 offer 무시
    if (_isShuttingDown.load()) {
        qCDebug(WebRTCLinkLog) << "Shutting down, ignoring WebRTC offer";
        return;
    }

    QString fromDroneId = message["from"].toString();
    QString path = message["path"].toString();  // Drone이 보낸 경로 정보

    // 표준 WebRTC offer 형식 처리
    QString sdp = message["sdp"].toString();
    if (sdp.isEmpty()) {
        qCWarning(WebRTCLinkLog) << "Invalid offer format: missing 'sdp' field";
        return;
    }

    qCDebug(WebRTCLinkLog) << "Received WebRTC offer from drone:" << fromDroneId
                           << "path:" << (path.isEmpty() ? "single (legacy)" : path);

    // Offer를 받았으므로 재연결 모드 활성화 (shutdown 해제)
    _isShuttingDown.store(false);

    try {
        // WebRTC offer 처리
        rtc::Description droneOffer(sdp.toStdString(), "offer");

        // Drone이 path 정보를 보냈는지 확인 (이중 경로 지원 여부)
        bool droneSupportsPath = !path.isEmpty();

        // 이중 경로 모드에서는 두 개의 offer가 순차적으로 도착함
        // 재협상 여부 판단: path가 다르면 같은 세션의 두 번째 offer
        bool isDualPathSecondOffer = droneSupportsPath &&
                                     (_peerConnectionDirect || _peerConnectionRelay) &&
                                     ((path == "relay" && _peerConnectionDirect) ||
                                      (path == "direct" && _peerConnectionRelay));

        // 재협상(re-handshake) 처리: 기존 연결이 있고, 이중 경로의 두 번째 offer가 아닌 경우에만 리셋
        if ((_peerConnection || _peerConnectionDirect || _peerConnectionRelay) && !isDualPathSecondOffer) {
            qCDebug(WebRTCLinkLog) << "Re-handshake detected: resetting existing connections";
            emit rtcStatusMessageChanged("재협상 시작: 기존 연결 재설정 중...");

            // 기존 연결 정리
            _resetPeerConnection();
            _resetDualPathConnections();
        }

        // PeerConnection이 없으면 새로 생성
        if (!_peerConnection && !_peerConnectionDirect && !_peerConnectionRelay) {
            qCDebug(WebRTCLinkLog) << "Creating new PeerConnection for drone offer";
            _setupPeerConnection();
        } else if (isDualPathSecondOffer) {
            qCDebug(WebRTCLinkLog) << "[DUAL-PATH] Received second offer for" << path << "path (dual-path mode)";
        }

        // 이중 경로 모드 확인: GCS와 Drone 모두 지원해야 함
        bool useDualPath = (_peerConnectionDirect || _peerConnectionRelay) && droneSupportsPath;

        if (useDualPath) {
            // 이중 경로 모드: path에 따라 해당 PeerConnection에만 설정
            qCDebug(WebRTCLinkLog) << "[DUAL-PATH] Processing offer for" << path << "path";

            bool isDirect = (path == "direct");
            auto& pc = isDirect ? _peerConnectionDirect : _peerConnectionRelay;
            auto& remoteDescSet = isDirect ? _remoteDescriptionSetDirect : _remoteDescriptionSetRelay;

            if (pc) {
                pc->setRemoteDescription(droneOffer);
                remoteDescSet.store(true);
                pc->setLocalDescription(rtc::Description::Type::Answer);
                qCDebug(WebRTCLinkLog) << "[DUAL-PATH]" << path << "answer will be created";
            } else {
                qCWarning(WebRTCLinkLog) << "[DUAL-PATH] No PeerConnection for" << path << "path";
            }

            emit rtcStatusMessageChanged(QString("드론으로부터 %1 offer 수신 중...").arg(path));
        } else {
            // 단일 경로 모드 (Drone이 이중 경로 미지원)
            if (_peerConnectionDirect || _peerConnectionRelay) {
                qCDebug(WebRTCLinkLog) << "Drone doesn't support dual-path, cleaning up dual connections";
                _resetDualPathConnections();
            }

            if (!_peerConnection) {
                qCWarning(WebRTCLinkLog) << "Failed to create PeerConnection";
                emit errorOccurred("PeerConnection 생성 실패");
                return;
            }

            // 드론의 offer를 remote description으로 설정
            _peerConnection->setRemoteDescription(droneOffer);
            _remoteDescriptionSet.store(true);

            // pending candidates 처리
            _processPendingCandidates();

            qCDebug(WebRTCLinkLog) << "Drone offer processed successfully, creating answer";

            // GCS는 answerer이므로 answer 생성
            _peerConnection->setLocalDescription(rtc::Description::Type::Answer);

            emit rtcStatusMessageChanged("드론으로부터 WebRTC offer 수신, 연결 설정 중...");
        }

    } catch (const std::exception& e) {
        qCWarning(WebRTCLinkLog) << "Failed to process drone offer:" << e.what();
        emit errorOccurred(QString("드론 offer 처리 실패: %1").arg(e.what()));
    }
}

void WebRTCWorker::_handleICECandidate(const QJsonObject& message)
{
    QString fromDroneId = message["from"].toString();
    QString candidateStr = message["candidate"].toString();
    QString sdpMid = message["sdpMid"].toString();
    QString path = message["path"].toString();  // "direct" 또는 "relay"

    if (candidateStr.isEmpty() || sdpMid.isEmpty()) {
        qCWarning(WebRTCLinkLog) << "Invalid ICE candidate format: missing 'candidate' or 'sdpMid' field";
        return;
    }

    qCDebug(WebRTCLinkLog) << "Received ICE candidate from:" << fromDroneId << "path:" << path;

    try {
        rtc::Candidate iceCandidate(candidateStr.toStdString(), sdpMid.toStdString());

        // 이중 경로 모드
        if (!path.isEmpty()) {
            bool isDirect = (path == "direct");
            auto& pc = isDirect ? _peerConnectionDirect : _peerConnectionRelay;
            auto& remoteDescSet = isDirect ? _remoteDescriptionSetDirect : _remoteDescriptionSetRelay;

            if (!pc) {
                qCWarning(WebRTCLinkLog) << "No" << path << "peer connection available for candidate";
                return;
            }

            if (remoteDescSet.load(std::memory_order_acquire)) {
                qCDebug(WebRTCLinkLog) << "[DUAL-PATH] Adding ICE candidate to" << path << "path immediately";
                pc->addRemoteCandidate(iceCandidate);
            } else {
                qCDebug(WebRTCLinkLog) << "[DUAL-PATH] ICE candidate for" << path << "queued, waiting for remote description";
                // TODO: 경로별 pending candidate 큐 구현 필요
            }
        } else {
            // 기존 단일 경로 (하위 호환성)
            if (!_peerConnection) {
                qCWarning(WebRTCLinkLog) << "No peer connection available for candidate";
                return;
            }

            if (_remoteDescriptionSet.load(std::memory_order_acquire)) {
                qCDebug(WebRTCLinkLog) << "Adding ICE candidate immediately";
                _peerConnection->addRemoteCandidate(iceCandidate);
            } else {
                // Remote description이 설정되지 않았으면 대기
                QMutexLocker locker(&_candidateMutex);
                _pendingCandidates.push_back(iceCandidate);
                qCDebug(WebRTCLinkLog) << "ICE candidate queued, waiting for remote description";
            }
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

    // 상태 모니터링 타이머 정지
    if (_statsTimer) {
        _statsTimer->stop();
    }
    if (_rttTimer) {
        _rttTimer->stop();
    }

    _dataChannelOpened.store(false);
    _isDisconnecting.store(false);

    // WebRTC 연결이 끊어지면 GCS 등록 해제
    if (_signalingManager && !_currentGcsId.isEmpty()) {
        qCDebug(WebRTCLinkLog) << "Unregistering GCS due to peer disconnection:" << _currentGcsId;
        _signalingManager->unregisterGCS(_currentGcsId);
        emit rtcStatusMessageChanged("피어 연결 해제 - GCS 등록 해제 중...");
    }

    _cleanup(CleanupMode::ForReconnection);

    emit rttUpdated(0);
    emit disconnected();

    // 사용자가 의도적으로 해제한 경우가 아닐 때만 자동 재연결 시작
    if (!_isShuttingDown.load() && !_waitingForReconnect.load()) {
        qCDebug(WebRTCLinkLog) << "[DISCONNECT] Starting automatic reconnection";
        emit rtcStatusMessageChanged("자동 재연결 시작...");

        _scheduleReconnect();
    } else {
        qCDebug(WebRTCLinkLog) << "[DISCONNECT] Manual reconnection required (shutting down or already reconnecting)";
        emit rtcStatusMessageChanged("기체 연결 해제됨, 수동 재연결 필요");
    }
}

void WebRTCWorker::_resetPeerConnection()
{
    qCDebug(WebRTCLinkLog) << "[RESET] Resetting peer connection";

    // 먼저 콜백 제거 (진행 중인 콜백이 객체 접근하지 못하도록)
    if (_peerConnection) {
        try {
            _peerConnection->onStateChange(nullptr);
        } catch (...) { }
        try {
            _peerConnection->onGatheringStateChange(nullptr);
        } catch (...) { }
        try {
            _peerConnection->onLocalDescription(nullptr);
        } catch (...) { }
        try {
            _peerConnection->onLocalCandidate(nullptr);
        } catch (...) { }
        try {
            _peerConnection->onDataChannel(nullptr);
        } catch (...) { }
        try {
            _peerConnection->onTrack(nullptr);
        } catch (...) { }
    }

    // DataChannel 정리 (콜백 제거 후)
    if (_mavlinkDataChannel) {
        // 각 콜백 제거를 개별 try-catch로 보호
        try { _mavlinkDataChannel->onOpen(nullptr); } catch (...) { }
        try { _mavlinkDataChannel->onClosed(nullptr); } catch (...) { }
        try { _mavlinkDataChannel->onError(nullptr); } catch (...) { }
        try { _mavlinkDataChannel->onMessage(nullptr); } catch (...) { }
        try { _mavlinkDataChannel->onBufferedAmountLow(nullptr); } catch (...) { }

        try {
            if (_mavlinkDataChannel->isOpen()) {
                _mavlinkDataChannel->close();
            }
        } catch (...) { }

        _mavlinkDataChannel.reset();
    }

    if (_customDataChannel) {
        // 각 콜백 제거를 개별 try-catch로 보호
        try { _customDataChannel->onOpen(nullptr); } catch (...) { }
        try { _customDataChannel->onClosed(nullptr); } catch (...) { }
        try { _customDataChannel->onError(nullptr); } catch (...) { }
        try { _customDataChannel->onMessage(nullptr); } catch (...) { }

        try {
            if (_customDataChannel->isOpen()) {
                _customDataChannel->close();
            }
        } catch (...) { }

        _customDataChannel.reset();
    }

    // Video Track 정리
    if (_videoTrack) {
        try {
            _videoTrack->onMessage(nullptr);
        } catch (...) { }
        _videoTrack.reset();
    }

    // PeerConnection 닫기 및 정리
    if (_peerConnection) {
        try {
            _peerConnection->close();
        } catch (const std::exception& e) {
            qCWarning(WebRTCLinkLog) << "[RESET] Error closing peer connection:" << e.what();
        }

        // shared_ptr를 로컬 변수로 이동하여 스코프가 끝날 때 자동 해제
        auto peerConnectionToDelete = std::move(_peerConnection);
        // peerConnectionToDelete는 이 함수가 끝날 때 자동으로 삭제됨
    }

    // 상태 초기화
    _remoteDescriptionSet.store(false);
    {
        QMutexLocker locker(&_candidateMutex);
        _pendingCandidates.clear();
    }

    qCDebug(WebRTCLinkLog) << "[RESET] Peer connection reset completed";
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
        // 연결 성공 시 재연결 카운터 리셋
        _onReconnectSuccess();

        if (_mavlinkDataChannel && _mavlinkDataChannel->isOpen()) {
            qCDebug(WebRTCLinkLog) << "DataChannel already open, no reconnection needed";
            return;
        }
    }

    if ((state == rtc::PeerConnection::State::Failed ||
         state == rtc::PeerConnection::State::Disconnected) && !_isDisconnecting.load()) {
        qCDebug(WebRTCLinkLog) << "[DEBUG] PeerConnection failed/disconnected – scheduling reconnect";

        // WebRTC 연결이 끊어져도 시그널링 서버 연결은 유지
        emit rtcStatusMessageChanged("WebRTC 연결 끊김 - 재연결 시도 중...");

        // 재연결 스케줄링
        if (!_waitingForReconnect.load()) {
            _scheduleReconnect();
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
    // Dual-path 모드 확인
    bool isDualPath = (_peerConnectionDirect || _peerConnectionRelay);

    if (isDualPath) {
        // Dual-path: 양쪽 RTT 모두 수집

        if (_peerConnectionDirect) {
            auto rttOpt = _peerConnectionDirect->rtt();
            if (rttOpt.has_value()) {
                _rttDirectMs = rttOpt.value().count();
            }
        }

        if (_peerConnectionRelay) {
            auto rttOpt = _peerConnectionRelay->rtt();
            if (rttOpt.has_value()) {
                _rttRelayMs = rttOpt.value().count();
            }
        }

        // 통합 RTT: 더 낮은 값 사용 (또는 사용 가능한 것)
        if (_rttDirectMs > 0 && _rttRelayMs > 0) {
            _rttMs = std::min(_rttDirectMs, _rttRelayMs);
        } else if (_rttDirectMs > 0) {
            _rttMs = _rttDirectMs;
        } else if (_rttRelayMs > 0) {
            _rttMs = _rttRelayMs;
        } else {
            _rttMs = 0; // 둘 다 없음
        }

        static int candidateUpdateCounter = 0;
        const int CANDIDATE_UPDATE_INTERVAL = 50; // 예: _rttTimer가 100ms라면 약 5초 간격

        if (++candidateUpdateCounter >= CANDIDATE_UPDATE_INTERVAL) {
            candidateUpdateCounter = 0;

            if (_peerConnectionDirect) {
                try {
                    auto localAddr = _peerConnectionDirect->localAddress();
                    auto remoteAddr = _peerConnectionDirect->remoteAddress();
                    if (localAddr.has_value() && remoteAddr.has_value()) {
                        _cachedDirectCandidate = QString("%1 ↔ %2")
                                                  .arg(QString::fromStdString(*localAddr))
                                                  .arg(QString::fromStdString(*remoteAddr));
                    }
                } catch (...) {
                    // 무시
                }
            }

            if (_peerConnectionRelay) {
                try {
                    auto localAddr = _peerConnectionRelay->localAddress();
                    auto remoteAddr = _peerConnectionRelay->remoteAddress();
                    if (localAddr.has_value() && remoteAddr.has_value()) {
                        _cachedRelayCandidate = QString("%1 ↔ %2")
                                                 .arg(QString::fromStdString(*localAddr))
                                                 .arg(QString::fromStdString(*remoteAddr));
                    }
                } catch (...) {
                    // 무시
                }
            }
        }

        // WebRTCStats에 양쪽 RTT 및 candidate 정보 모두 포함
        WebRTCStats stats = _collectWebRTCStats();
        stats.rttDirectMs = _rttDirectMs;
        stats.rttRelayMs = _rttRelayMs;
        stats.iceCandidateDirect = _cachedDirectCandidate;
        stats.iceCandidateRelay = _cachedRelayCandidate;
        emit webRtcStatsUpdated(stats);

        // 기존 시그널도 유지 (통합 RTT)
        if (_rttMs > 0) {
            emit rttUpdated(_rttMs);
        }

        // // 상세 로그 (10초마다)
        // static int rttLogCount = 0;
        // if (++rttLogCount % 10 == 0) {
        //     qCDebug(WebRTCLinkLog) << "[RTT UPDATE] Direct:"
        //                            << (_rttDirectMs > 0 ? QString::number(_rttDirectMs) + "ms" : "N/A")
        //                            << "  Relay:"
        //                            << (_rttRelayMs > 0 ? QString::number(_rttRelayMs) + "ms" : "N/A");
        // }
    } else {
        // Single-path (legacy)
        if (!_peerConnection) return;

        auto rttOpt = _peerConnection->rtt();
        if (rttOpt.has_value()) {
            _rttMs = rttOpt.value().count();

            WebRTCStats stats = _collectWebRTCStats();
            emit webRtcStatsUpdated(stats);
            emit rttUpdated(_rttMs);
        }
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

void WebRTCWorker::_cleanup(CleanupMode mode)
{
    // 이미 cleanup 진행 중이면 중복 호출 방지
    if (_isCleaningUp.exchange(true)) {
        qCDebug(WebRTCLinkLog) << "Cleanup already in progress, ignoring duplicate call";
        return;
    }

    qCDebug(WebRTCLinkLog) << "Cleaning up WebRTC resources, mode:"
                          << (mode == CleanupMode::Complete ? "Complete" : "ForReconnection");

    // 자동 재연결 중이고 완전 정리 모드인 경우 스킵
    if (mode == CleanupMode::Complete && _waitingForReconnect.load()) {
        qCDebug(WebRTCLinkLog) << "Auto-reconnection in progress, skipping complete cleanup";
        _isCleaningUp.store(false);  // 플래그 해제
        return;
    }

    _isDisconnecting.store(true);
    _dataChannelOpened.store(false);

    // 통계 타이머 정리
    if (_statsTimer) {
        _statsTimer->stop();
    }

    // RTT 타이머 정리 (PeerConnection보다 먼저)
    if (_rttTimer) {
        _rttTimer->stop();
        _rttTimer->deleteLater();
        _rttTimer = nullptr;
    }

    // PeerConnection 정리 (콜백과 DataChannel, VideoTrack 모두 정리)
    _resetPeerConnection();

    // 상태 초기화
    _remoteDescriptionSet.store(false);
    {
        QMutexLocker locker(&_candidateMutex);
        _pendingCandidates.clear();
    }

    // 통계 초기화
    _rttMs = 0;
    _rttDirectMs = 0;
    _rttRelayMs = 0;
    _cachedDirectCandidate.clear();
    _cachedRelayCandidate.clear();
    _dataChannelSentCalc.reset();
    _dataChannelReceivedCalc.reset();
    _dataChannelSentDirectCalc.reset();
    _dataChannelRecvDirectCalc.reset();
    _dataChannelSentRelayCalc.reset();
    _dataChannelRecvRelayCalc.reset();
    _videoReceivedCalc.reset();
    _videoReceivedDirectCalc.reset();
    _videoReceivedRelayCalc.reset();

    // Dual-path 중복 제거 통계 초기화
    {
        QMutexLocker locker(&_hashMutex);
        _hashRingBuffer.fill(0);
        _hashRingIndex.store(0);
    }
    _duplicatePacketsFromDirect.store(0);
    _duplicatePacketsFromRelay.store(0);
    _totalPacketsReceived.store(0);

    // WebRTCStats 초기화하여 UI 업데이트
    // WebRTCStats emptyStats;
    // emit webRtcStatsUpdated(emptyStats);

    // 완전 정리 모드인 경우 추가 작업
    if (mode == CleanupMode::Complete) {
        _isShuttingDown.store(true);

        // GCS 정보 초기화
        _currentGcsId.clear();
        _currentTargetDroneId.clear();
        _gcsRegistered = false;

        qCDebug(WebRTCLinkLog) << "Complete cleanup finished. Signaling server remains connected for other peers";
    } else {
        qCDebug(WebRTCLinkLog) << "Cleanup for reconnection completed, ready for new connection";
    }

    // cleanup 플래그 해제
    _isCleaningUp.store(false);
}

// Video bridge related functions removed

WebRTCStats WebRTCWorker::_collectWebRTCStats() const
{
    WebRTCStats stats;
    stats.rttMs = _rttMs;
    stats.rttDirectMs = _rttDirectMs;
    stats.rttRelayMs = _rttRelayMs;

    // 통합 송수신 통계
    stats.webRtcSent = _dataChannelSentCalc.getCurrentRate();
    stats.webRtcRecv = _dataChannelReceivedCalc.getCurrentRate();

    // 경로별 송수신 통계
    stats.webRtcSentDirect = _dataChannelSentDirectCalc.getCurrentRate();
    stats.webRtcRecvDirect = _dataChannelRecvDirectCalc.getCurrentRate();
    stats.webRtcSentRelay = _dataChannelSentRelayCalc.getCurrentRate();
    stats.webRtcRecvRelay = _dataChannelRecvRelayCalc.getCurrentRate();

    // 비디오 통계
    stats.videoRateKBps = _videoReceivedCalc.getCurrentRate();
    stats.videoPacketCount = _videoReceivedCalc.getStats().totalPackets;
    stats.videoBytesReceived = _videoReceivedCalc.getStats().totalBytes;

    // 경로별 비디오 통계
    stats.videoRateDirectKBps = _videoReceivedDirectCalc.getCurrentRate();
    stats.videoPacketCountDirect = _videoReceivedDirectCalc.getStats().totalPackets;
    stats.videoBytesReceivedDirect = _videoReceivedDirectCalc.getStats().totalBytes;

    stats.videoRateRelayKBps = _videoReceivedRelayCalc.getCurrentRate();
    stats.videoPacketCountRelay = _videoReceivedRelayCalc.getStats().totalPackets;
    stats.videoBytesReceivedRelay = _videoReceivedRelayCalc.getStats().totalBytes;

    return stats;
}

void WebRTCWorker::_updateAllStatistics()
{
    // 통합 통계 업데이트
    _dataChannelSentCalc.updateRate();
    _dataChannelReceivedCalc.updateRate();
    _videoReceivedCalc.updateRate();

    // 경로별 통계 업데이트
    _dataChannelSentDirectCalc.updateRate();
    _dataChannelRecvDirectCalc.updateRate();
    _dataChannelSentRelayCalc.updateRate();
    _dataChannelRecvRelayCalc.updateRate();

    // 경로별 비디오 통계 업데이트
    _videoReceivedDirectCalc.updateRate();
    _videoReceivedRelayCalc.updateRate();

    WebRTCStats stats = _collectWebRTCStats();

    // 통합된 통계 시그널 발생
    emit webRtcStatsUpdated(stats);

    // 기존 개별 시그널들도 유지 (호환성을 위해)
    emit dataChannelStatsUpdated(stats.webRtcSent, stats.webRtcRecv);
    emit videoStatsUpdated(stats.videoRateKBps, stats.videoPacketCount, stats.videoBytesReceived);
    emit videoRateChanged(stats.videoRateKBps);
}

void WebRTCWorker::_calculateDataChannelRates(qint64 currentTime)
{
    // 통합 통계 업데이트
    _dataChannelSentCalc.updateRate();
    _dataChannelReceivedCalc.updateRate();
    _videoReceivedCalc.updateRate();

    // 경로별 통계 업데이트
    _dataChannelSentDirectCalc.updateRate();
    _dataChannelRecvDirectCalc.updateRate();
    _dataChannelSentRelayCalc.updateRate();
    _dataChannelRecvRelayCalc.updateRate();

    // 경로별 비디오 통계 업데이트
    _videoReceivedDirectCalc.updateRate();
    _videoReceivedRelayCalc.updateRate();

    WebRTCStats stats = _collectWebRTCStats();

    // 통합된 통계 시그널 발생
    emit webRtcStatsUpdated(stats);

    // 기존 개별 시그널들도 유지 (호환성을 위해)
    emit dataChannelStatsUpdated(stats.webRtcSent, stats.webRtcRecv);
    emit videoStatsUpdated(stats.videoRateKBps, stats.videoPacketCount, stats.videoBytesReceived);
    emit videoRateChanged(stats.videoRateKBps);

    // 전체 통계 업데이트 시그널
    emit statisticsUpdated();
}

bool WebRTCWorker::isWaitingForReconnect() const
{
    return _waitingForReconnect.load();
}

void WebRTCWorker::_processPendingMessages()
{
    if (!_mavlinkDataChannel || !_mavlinkDataChannel->isOpen()) {
        return;
    }

    if (_pendingMessages.isEmpty()) {
        return;
    }

    qCDebug(WebRTCLinkLog) << "[BUFFER] Processing" << _pendingMessages.size() << "pending messages";

    int sentCount = 0;
    while (!_pendingMessages.isEmpty()) {
        size_t buffered = _mavlinkDataChannel->bufferedAmount();

        // 버퍼가 다시 경고 수준에 도달하면 중단
        if (buffered > BUFFER_WARNING_THRESHOLD) {
            qCDebug(WebRTCLinkLog) << "[BUFFER] Buffer filling up again, pausing at"
                                   << buffered << "bytes. Remaining messages:"
                                   << _pendingMessages.size();
            break;
        }

        QByteArray data = _pendingMessages.takeFirst();

        try {
            std::string_view view(data.constData(), data.size());
            _mavlinkDataChannel->send(rtc::binary(
                reinterpret_cast<const std::byte*>(view.data()),
                reinterpret_cast<const std::byte*>(view.data() + view.size())
            ));

            _dataChannelSentCalc.addData(data.size());
            emit bytesSent(data);
            sentCount++;

        } catch (const std::exception& e) {
            qCWarning(WebRTCLinkLog) << "[BUFFER] Failed to send pending message:" << e.what();
            // 실패한 메시지는 큐 앞에 다시 추가
            _pendingMessages.prepend(data);
            break;
        }
    }

    qCDebug(WebRTCLinkLog) << "[BUFFER] Sent" << sentCount << "pending messages."
                           << "Remaining:" << _pendingMessages.size();

    // 모든 대기 메시지가 전송되면 혼잡 상태 해제
    if (_pendingMessages.isEmpty() && _isCongested) {
        _isCongested = false;
        emit congestionCleared();
    }
}

void WebRTCWorker::_checkBufferHealth()
{
    if (!_mavlinkDataChannel || !_mavlinkDataChannel->isOpen()) {
        return;
    }

    size_t buffered = _mavlinkDataChannel->bufferedAmount();
    qint64 now = QDateTime::currentMSecsSinceEpoch();

    // 버퍼 증가율 계산 (bytes/sec)
    if (_lastBufferCheckTime > 0) {
        qint64 timeDiff = now - _lastBufferCheckTime;
        if (timeDiff > 0) {
            double bufferGrowthRate = static_cast<double>(buffered - _lastBufferedAmount) / timeDiff * 1000;

            static constexpr double RAPID_BUFFER_GROWTH_THRESHOLD = 100000.0; // 100KB/s
            if (bufferGrowthRate > RAPID_BUFFER_GROWTH_THRESHOLD) {
                qCDebug(WebRTCLinkLog) << "[BUFFER] Rapid buffer growth detected:"
                                       << bufferGrowthRate / 1024 << "KB/s";
            }
        }
    }

    _lastBufferedAmount = buffered;
    _lastBufferCheckTime = now;
}

bool WebRTCWorker::_canSendData() const
{
    if (!_mavlinkDataChannel || !_mavlinkDataChannel->isOpen()) {
        return false;
    }

    size_t buffered = _mavlinkDataChannel->bufferedAmount();
    return buffered < BUFFER_CRITICAL_THRESHOLD;
}

/*===========================================================================*/
// Reconnection Management Methods
/*===========================================================================*/

int WebRTCWorker::_calculateReconnectDelay() const
{
    // 지수 백오프 전략: 2^attempt * base_delay, 최대 30초
    int delay = BASE_RECONNECT_DELAY_MS * (1 << _reconnectAttempts);

    // 최대 지연 시간 제한
    if (delay > MAX_RECONNECT_DELAY_MS) {
        delay = MAX_RECONNECT_DELAY_MS;
    }

    // 약간의 랜덤성 추가 (네트워크 혼잡 방지)
    int jitter = (QRandomGenerator::global()->bounded(RECONNECT_JITTER_MS * 2)) - RECONNECT_JITTER_MS;
    delay += jitter;

    if (delay < RECONNECT_DELAY_MIN_MS) {
        delay = RECONNECT_DELAY_MIN_MS;
    }

    return delay;
}

void WebRTCWorker::_scheduleReconnect()
{
    if (_waitingForReconnect.load()) {
        qCDebug(WebRTCLinkLog) << "Already waiting for reconnect, ignoring";
        return;
    }

    if (_reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
        qCWarning(WebRTCLinkLog) << "Max reconnection attempts reached:" << MAX_RECONNECT_ATTEMPTS;
        emit rtcStatusMessageChanged("최대 재연결 시도 횟수 도달");
        return;
    }

    _reconnectAttempts++;
    int delay = _calculateReconnectDelay();

    qCDebug(WebRTCLinkLog) << "Scheduling reconnect in" << delay << "ms"
                          << "(attempt" << _reconnectAttempts << "/" << MAX_RECONNECT_ATTEMPTS << ")";

    _waitingForReconnect.store(true);

    if (_reconnectTimer) {
        _reconnectTimer->start(delay);
    }
}

void WebRTCWorker::_cancelReconnect()
{
    if (_reconnectTimer && _reconnectTimer->isActive()) {
        _reconnectTimer->stop();
        qCDebug(WebRTCLinkLog) << "Reconnection cancelled";
    }

    _waitingForReconnect.store(false);
}

void WebRTCWorker::_onReconnectSuccess()
{
    qCDebug(WebRTCLinkLog) << "Reconnection successful, resetting attempts";
    _reconnectAttempts = 0;
    _waitingForReconnect.store(false);

    if (_reconnectTimer && _reconnectTimer->isActive()) {
        _reconnectTimer->stop();
    }
}

/*===========================================================================*/
// Dual-Path Data Transmission Methods
/*===========================================================================*/

WebRTCWorker::PathType WebRTCWorker::_selectBestPath() const
{
    // 연결 상태 확인
    bool directOpen = _mavlinkDataChannelDirect && _mavlinkDataChannelDirect->isOpen();
    bool relayOpen = _mavlinkDataChannelRelay && _mavlinkDataChannelRelay->isOpen();

    if (!directOpen && !relayOpen) {
        return PathType::Direct;  // 기본값 (실패하겠지만)
    }

    if (directOpen && !relayOpen) {
        return PathType::Direct;
    }

    if (!directOpen && relayOpen) {
        return PathType::Relay;
    }

    // 둘 다 열려있으면 품질 기반 선택

    // 1. 중복 패킷 통계 기반: 어느 경로가 더 자주 먼저 도착하는지
    uint64_t directDuplicates = _duplicatePacketsFromDirect.load();
    uint64_t relayDuplicates = _duplicatePacketsFromRelay.load();
    uint64_t totalPackets = _totalPacketsReceived.load();

    // 충분한 통계가 쌓이면 (100개 이상) 통계 기반 선택
    if (totalPackets > 100 && (directDuplicates + relayDuplicates) > 50) {
        // Direct에서 중복이 많이 발생 = Relay가 더 자주 먼저 도착
        // Relay에서 중복이 많이 발생 = Direct가 더 자주 먼저 도착
        if (directDuplicates > relayDuplicates * 1.5) {
            // Direct가 느림 -> Relay 선택
            return PathType::Relay;
        } else if (relayDuplicates > directDuplicates * 1.5) {
            // Relay가 느림 -> Direct 선택
            return PathType::Direct;
        }
    }

    // 2. RTT 비교 (낮을수록 좋음)
    if (_peerConnectionDirect && _peerConnectionRelay) {
        if (_rttDirectMs && _rttRelayMs) {
            // Direct가 Relay보다 10% 이상 빠르면 Direct 선택
            if (_rttDirectMs < _rttRelayMs * 0.9) {
                return PathType::Direct;
            } else if (_rttRelayMs < _rttDirectMs * 0.9) {
                // Relay가 Direct보다 10% 이상 빠르면 Relay 선택
                return PathType::Relay;
            }
        }
    }

    // 버퍼 상태 비교
    if (_mavlinkDataChannelDirect && _mavlinkDataChannelRelay) {
        size_t directBuffer = _mavlinkDataChannelDirect->bufferedAmount();
        size_t relayBuffer = _mavlinkDataChannelRelay->bufferedAmount();

        // Direct 버퍼가 덜 차있으면 Direct 선택
        if (directBuffer < relayBuffer * 0.8) {
            return PathType::Direct;
        }
    }

    // 기본값: Direct (지연시간 우선)
    return PathType::Direct;
}

void WebRTCWorker::_sendDataViaPath(const QByteArray& data, PathType pathType)
{
    if (_isShuttingDown.load()) {
        return;
    }

    // 원본 MAVLink 패킷 그대로 전송 (변형 없음)
    std::string_view view(data.constData(), data.size());
    auto binaryData = rtc::binary(
        reinterpret_cast<const std::byte*>(view.data()),
        reinterpret_cast<const std::byte*>(view.data() + view.size())
    );

    try {
        switch (pathType) {
        case PathType::Direct:
            if (_mavlinkDataChannelDirect && _mavlinkDataChannelDirect->isOpen()) {
                _mavlinkDataChannelDirect->send(binaryData);
                _dataChannelSentCalc.addData(data.size());
                _dataChannelSentDirectCalc.addData(data.size());  // Direct 경로 통계
                qCDebug(WebRTCLinkLog) << "[DUAL-PATH] Sent via Direct:" << data.size() << "bytes";
            }
            break;

        case PathType::Relay:
            if (_mavlinkDataChannelRelay && _mavlinkDataChannelRelay->isOpen()) {
                _mavlinkDataChannelRelay->send(binaryData);
                _dataChannelSentCalc.addData(data.size());
                _dataChannelSentRelayCalc.addData(data.size());  // Relay 경로 통계
                qCDebug(WebRTCLinkLog) << "[DUAL-PATH] Sent via Relay:" << data.size() << "bytes";
            }
            break;

        case PathType::Best:
        {
            // 최적 경로 선택
            PathType bestPath = _selectBestPath();
            _sendDataViaPath(data, bestPath);
            break;
        }

        case PathType::Both:
        {
            // 양쪽 경로로 모두 전송 (중복 전송)
            bool directSent = false;
            bool relaySent = false;
            bool directExists = (bool)_mavlinkDataChannelDirect;
            bool directOpen = directExists && _mavlinkDataChannelDirect->isOpen();
            bool relayExists = (bool)_mavlinkDataChannelRelay;
            bool relayOpen = relayExists && _mavlinkDataChannelRelay->isOpen();

            if (directOpen) {
                _mavlinkDataChannelDirect->send(binaryData);
                _dataChannelSentCalc.addData(data.size());
                _dataChannelSentDirectCalc.addData(data.size());  // Direct 경로 통계
                directSent = true;
            }

            if (relayOpen) {
                _mavlinkDataChannelRelay->send(binaryData);
                _dataChannelSentCalc.addData(data.size());
                _dataChannelSentRelayCalc.addData(data.size());  // Relay 경로 통계
                relaySent = true;
            }

            // 경고: 한쪽만 전송된 경우
            if (directSent && !relaySent) {
                static int directOnlyCount = 0;
                if (++directOnlyCount % 50 == 1) {  // 처음과 50번마다
                    qCWarning(WebRTCLinkLog) << "[DUAL-PATH] WARNING: Only Direct sent (Relay exist="
                                             << relayExists << "open=" << relayOpen << ")";
                }
            } else if (!directSent && relaySent) {
                static int relayOnlyCount = 0;
                if (++relayOnlyCount % 50 == 1) {  // 처음과 50번마다
                    qCWarning(WebRTCLinkLog) << "[DUAL-PATH] WARNING: Only Relay sent (Direct exist="
                                             << directExists << "open=" << directOpen << ")";
                }
            } else if (!directSent && !relaySent) {
                qCWarning(WebRTCLinkLog) << "[DUAL-PATH] ERROR: Both paths failed! (Direct exist="
                                         << directExists << "open=" << directOpen
                                         << ", Relay exist=" << relayExists << "open=" << relayOpen << ")";
            }
            break;
        }
        }

        emit bytesSent(data);

    } catch (const std::exception& e) {
        qCWarning(WebRTCLinkLog) << "[DUAL-PATH] Failed to send data:" << e.what();
        emit errorOccurred(QString("Failed to send data: %1").arg(e.what()));
    }
}

void WebRTCWorker::_processReceivedData(const QByteArray& data, bool fromDirect)
{
    if (_isShuttingDown.load()) {
        return;
    }

    // 패킷 크기 검증 (MAVLink 최소 패킷: 8바이트)
    if (data.size() < 8) {
        qCWarning(WebRTCLinkLog) << "[DUAL-PATH] Received packet too small:" << data.size();
        return;
    }

    // 패킷 해시 계산 (원본 데이터 그대로 사용)
    // 해시값이 0인 경우를 처리하기 위해 1을 더함 (0은 빈 슬롯을 의미)
    uint rawHash = qHash(data);
    uint packetHash = (rawHash == 0) ? 1 : rawHash;

    // Thread-safe 중복 검사
    bool isDuplicate = false;
    {
        QMutexLocker locker(&_hashMutex);

        // 원형 버퍼에서 중복 검사 (0은 빈 슬롯이므로 건너뜀)
        for (int i = 0; i < MAX_HASH_HISTORY; ++i) {
            if (_hashRingBuffer[i] != 0 && _hashRingBuffer[i] == packetHash) {
                isDuplicate = true;
                break;
            }
        }

        if (!isDuplicate) {
            // 새 패킷: 원형 버퍼에 추가
            int index = _hashRingIndex.fetch_add(1) % MAX_HASH_HISTORY;
            _hashRingBuffer[index] = packetHash;
        }
    }

    if (isDuplicate) {
        // 중복 패킷 통계 업데이트
        if (fromDirect) {
            _duplicatePacketsFromDirect.fetch_add(1);
        } else {
            _duplicatePacketsFromRelay.fetch_add(1);
        }

        // 로그는 100개마다 한 번씩만 출력
        uint64_t totalDuplicates = _duplicatePacketsFromDirect.load() + _duplicatePacketsFromRelay.load();
        if (totalDuplicates % 100 == 0) {
            qCDebug(WebRTCLinkLog) << "[DUAL-PATH] Duplicate stats - Direct:"
                                   << _duplicatePacketsFromDirect.load()
                                   << "Relay:" << _duplicatePacketsFromRelay.load()
                                   << "Total received:" << _totalPacketsReceived.load();
        }
        return;
    }

    // 새 패킷 처리
    uint64_t packetCount = _totalPacketsReceived.fetch_add(1) + 1;

    // 처음 100개 패킷은 어느 경로가 먼저 도착했는지 로그 출력
    if (packetCount <= 100 && packetCount % 10 == 0) {
        QString path = fromDirect ? "Direct" : "Relay";
        qCDebug(WebRTCLinkLog) << "[DUAL-PATH] Packet" << packetCount << "arrived first from" << path;
    }

    // 원본 MAVLink 패킷을 그대로 전달 (변형 없음)
    _dataChannelReceivedCalc.addData(data.size());

    // 경로별 수신 통계 기록
    if (fromDirect) {
        _dataChannelRecvDirectCalc.addData(data.size());
    } else {
        _dataChannelRecvRelayCalc.addData(data.size());
    }

    emit bytesReceived(data);
}

void WebRTCWorker::_resetDualPathConnections()
{
    qCDebug(WebRTCLinkLog) << "[DUAL-PATH] Resetting dual path connections";

    // Direct 경로 정리
    if (_peerConnectionDirect) {
        try {
            _peerConnectionDirect->close();
        } catch (...) {}
        _peerConnectionDirect.reset();
    }

    if (_mavlinkDataChannelDirect) {
        try {
            if (_mavlinkDataChannelDirect->isOpen()) {
                _mavlinkDataChannelDirect->close();
            }
        } catch (...) {}
        _mavlinkDataChannelDirect.reset();
    }

    if (_customDataChannelDirect) {
        try {
            if (_customDataChannelDirect->isOpen()) {
                _customDataChannelDirect->close();
            }
        } catch (...) {}
        _customDataChannelDirect.reset();
    }

    if (_videoTrackDirect) {
        _videoTrackDirect.reset();
    }

    // Relay 경로 정리
    if (_peerConnectionRelay) {
        try {
            _peerConnectionRelay->close();
        } catch (...) {}
        _peerConnectionRelay.reset();
    }

    if (_mavlinkDataChannelRelay) {
        try {
            if (_mavlinkDataChannelRelay->isOpen()) {
                _mavlinkDataChannelRelay->close();
            }
        } catch (...) {}
        _mavlinkDataChannelRelay.reset();
    }

    if (_customDataChannelRelay) {
        try {
            if (_customDataChannelRelay->isOpen()) {
                _customDataChannelRelay->close();
            }
        } catch (...) {}
        _customDataChannelRelay.reset();
    }

    if (_videoTrackRelay) {
        _videoTrackRelay.reset();
    }

    // 상태 초기화
    _directPathActive.store(false);
    _relayPathActive.store(false);
    _remoteDescriptionSetDirect.store(false);
    _remoteDescriptionSetRelay.store(false);
    _dataChannelOpenedDirect.store(false);
    _dataChannelOpenedRelay.store(false);

    // RTT 및 통계 정보 초기화
    _rttMs = 0;
    _rttDirectMs = 0;
    _rttRelayMs = 0;
    _cachedDirectCandidate.clear();
    _cachedRelayCandidate.clear();

    // 통계 계산기 초기화
    _dataChannelSentCalc.reset();
    _dataChannelReceivedCalc.reset();
    _dataChannelSentDirectCalc.reset();
    _dataChannelRecvDirectCalc.reset();
    _dataChannelSentRelayCalc.reset();
    _dataChannelRecvRelayCalc.reset();
    _videoReceivedCalc.reset();
    _videoReceivedDirectCalc.reset();
    _videoReceivedRelayCalc.reset();

    // Dual-path 중복 제거 통계 초기화
    {
        QMutexLocker locker(&_hashMutex);
        _hashRingBuffer.fill(0);
        _hashRingIndex.store(0);
    }
    _duplicatePacketsFromDirect.store(0);
    _duplicatePacketsFromRelay.store(0);
    _totalPacketsReceived.store(0);

    // WebRTCStats 초기화하여 UI 업데이트
    // WebRTCStats emptyStats;
    // emit webRtcStatsUpdated(emptyStats);

    qCDebug(WebRTCLinkLog) << "[DUAL-PATH] Dual path connections reset completed";
}
