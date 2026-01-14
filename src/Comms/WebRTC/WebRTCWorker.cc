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

    _reconnectTimer = new QTimer(this);
    _reconnectTimer->setSingleShot(true);
    connect(_reconnectTimer, &QTimer::timeout, this, &WebRTCWorker::reconnectToRoom);

    _pcContext.remoteDescriptionSet.store(false);
}

WebRTCWorker::~WebRTCWorker()
{
    qCDebug(WebRTCLinkLog) << "WebRTCWorker destructor called";

    WorkerState currentState = _state.load();
    if (currentState != WorkerState::Shutdown) {
        transitionState(currentState, WorkerState::Shutdown);
    }

    if (_cleanupTimer) {
        _cleanupTimer->stop();
        _cleanupTimer->disconnect();
        delete _cleanupTimer; // deleteLater → delete
        _cleanupTimer = nullptr;
    }

    if (_reconnectTimer) {
        _reconnectTimer->stop();
        _reconnectTimer->disconnect();
        delete _reconnectTimer; // deleteLater → delete
        _reconnectTimer = nullptr;
    }

    if (_rttTimer) {
        _rttTimer->stop();
        _rttTimer->disconnect();
        delete _rttTimer; // deleteLater → delete
        _rttTimer = nullptr;
    }

    if (_statsTimer) {
        _statsTimer->stop();
        _statsTimer->disconnect();
        delete _statsTimer; // deleteLater → delete
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
    qCDebug(WebRTCLinkLog) << "Starting WebRTC worker, current state:" << stateToString();

    // 상태 머신을 사용한 상태 체크
    WorkerState currentState = _state.load();

    // Idle 또는 Reconnecting 상태에서만 시작 가능
    if (currentState != WorkerState::Idle && currentState != WorkerState::Reconnecting) {
        qCWarning(WebRTCLinkLog) << "Cannot start: invalid state" << stateToString();
        return;
    }

    // 상태 전이: Idle/Reconnecting -> Starting
    if (!transitionState(currentState, WorkerState::Starting)) {
        qCWarning(WebRTCLinkLog) << "Failed to transition to Starting state";
        return;
    }

    // Reset connection state flags (PeerConnection 관련만)
    _pcContext.dataChannelOpened.store(false);
    _pcContext.remoteDescriptionSet.store(false);
    _videoStreamActive.store(false);

    // SignalingServerManager 시그널 재연결 (싱글톤이므로 이전 연결이 남아있을 수 있음)
    _connectSignalingSignals();
    qCDebug(WebRTCLinkLog) << "Reconnected SignalingServerManager signals";

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

    // 이전 connections이 남아있으면 완전히 정리
    if (_pcContext.pc || _pcContext.mavlinkDc || _pcContext.customDc || _pcContext.videoTrack) {
        qCDebug(WebRTCLinkLog) << "Cleaning up previous connections before start";
        _resetPeerConnection();
    }

    // Clear any existing state
    {
        QMutexLocker locker(&_pcContext.candidateMutex);
        _pcContext.pendingCandidates.clear();
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
        qCDebug(WebRTCLinkLog) << "[DEBUG] Current state:" << self->stateToString();

        try {
            // Starting 또는 Connecting 상태에서만 등록 진행
            if (self->_signalingManager && SignalingServerManager::instance() &&
                (self->isInState(WorkerState::Starting) || self->isInState(WorkerState::Connecting))) {
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
    if (isShuttingDown()) {
        qCDebug(WebRTCLinkLog) << "[WRITE] Rejected: shutting down";
        return;
    }

    if (!_pcContext.mavlinkDc || !_pcContext.mavlinkDc->isOpen()) {
        qCWarning(WebRTCLinkLog) << "[WRITE] DataChannel not available or not open";
        return;
    }

    // Single path: send data directly
    std::string_view view(data.constData(), data.size());
    auto binaryData = rtc::binary(
        reinterpret_cast<const std::byte*>(view.data()),
        reinterpret_cast<const std::byte*>(view.data() + view.size())
    );

    try {
        _pcContext.mavlinkDc->send(binaryData);
        _dataChannelSentCalc.addData(data.size());
        emit bytesSent(data);
    } catch (const std::exception& e) {
        qCWarning(WebRTCLinkLog) << "[WRITE] Failed to send data:" << e.what();
        emit errorOccurred(QString("Failed to send data: %1").arg(e.what()));
    }
}

void WebRTCWorker::sendCustomMessage(const QString& message)
{
    if (isShuttingDown()) {
        qCWarning(WebRTCLinkLog) << "Cannot send custom message: shutting down";
        return;
    }

    if (!_pcContext.customDc || !_pcContext.customDc->isOpen()) {
        qCWarning(WebRTCLinkLog) << "Custom DataChannel not available or not open";
        return;
    }

    // QString을 binary 데이터로 변환
    QByteArray data = message.toUtf8();
    std::string_view view(data.constData(), data.size());
    auto binaryData = rtc::binary(
        reinterpret_cast<const std::byte*>(view.data()),
        reinterpret_cast<const std::byte*>(view.data() + view.size())
    );

    try {
        _pcContext.customDc->send(binaryData);
        qCDebug(WebRTCLinkLog) << "Custom message sent:" << message;
    } catch (const std::exception& e) {
        if (!isShuttingDown()) {
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
    qCDebug(WebRTCLinkLog) << "Disconnecting WebRTC link (user initiated), state:" << stateToString();

    // 현재 상태 확인
    WorkerState currentState = _state.load();

    // 이미 Disconnecting, CleaningUp, Shutdown 상태면 무시
    if (currentState == WorkerState::Disconnecting ||
        currentState == WorkerState::CleaningUp ||
        currentState == WorkerState::Shutdown) {
        qCDebug(WebRTCLinkLog) << "Already disconnecting/shutting down, ignoring";
        return;
    }

    // 자동 재연결 중일 때는 먼저 재연결을 취소하고 진행
    if (currentState == WorkerState::Reconnecting) {
        qCDebug(WebRTCLinkLog) << "Canceling auto-reconnection for manual disconnect";
        _cancelReconnect();
    }

    // 상태 전이: 현재 상태 -> Disconnecting
    if (!transitionState(currentState, WorkerState::Disconnecting)) {
        qCWarning(WebRTCLinkLog) << "Failed to transition to Disconnecting state";
        return;
    }

    // 즉시 모든 타이머 중지 (RTT 업데이트 등)
    if (_rttTimer) {
        _rttTimer->stop();
    }
    if (_statsTimer) {
        _statsTimer->stop();
    }

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

            // 사용자가 다시 연결을 시작했는지 확인
            WorkerState state = self->_state.load();
            if (state != WorkerState::Disconnecting && state != WorkerState::CleaningUp) {
                qCDebug(WebRTCLinkLog) << "Cleanup timer fired but state changed to"
                                      << self->stateToString(state) << ", skipping cleanup";
                return;
            }

            qCDebug(WebRTCLinkLog) << "Cleanup timer fired, performing complete cleanup";

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
    return _pcContext.mavlinkDc && _pcContext.mavlinkDc->isOpen();
}

bool WebRTCWorker::isOperational() const {
    WorkerState state = _state.load();
    return state != WorkerState::Shutdown &&
           state != WorkerState::Disconnecting &&
           state != WorkerState::CleaningUp;
}

void WebRTCWorker::_setupSignalingManager()
{
    // Use singleton instance instead of creating new one
    _signalingManager = SignalingServerManager::instance();
    _connectSignalingSignals();
}

void WebRTCWorker::_connectSignalingSignals()
{
    if (!_signalingManager) return;

    // 기존 연결 제거 (중복 방지)
    disconnect(_signalingManager, nullptr, this, nullptr);

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
    _pcContext.dataChannelOpened.store(false);
    _pcContext.remoteDescriptionSet.store(false);

    // Clear pending candidates
    {
        QMutexLocker locker(&_pcContext.candidateMutex);
        _pcContext.pendingCandidates.clear();
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
    _pcContext.dataChannelOpened.store(false);
    _pcContext.remoteDescriptionSet.store(false);

    // Clear pending candidates
    {
        QMutexLocker locker(&_pcContext.candidateMutex);
        _pcContext.pendingCandidates.clear();
    }

    // 자동 재연결 중일 때는 완전한 정리를 하지 않음
    if (_waitingForReconnect.load()) {
        qCDebug(WebRTCLinkLog) << "Auto-reconnection in progress, skipping complete cleanup after unregister failure";
        return;
    }
}

void WebRTCWorker::reconnectToRoom()
{
    qCDebug(WebRTCLinkLog) << "Reconnect requested, state:" << stateToString();

    // Reconnecting 상태에서만 실행 가능
    if (!isInState(WorkerState::Reconnecting)) {
        qCWarning(WebRTCLinkLog) << "Invalid state for reconnect:" << stateToString();
        return;
    }

    // 이전 connections이 아직 남아있으면 정리
    if (_pcContext.pc) {
        qCDebug(WebRTCLinkLog) << "Cleaning up existing connections before reconnect";
        _resetPeerConnection();
    }

    qCDebug(WebRTCLinkLog) << "Attempting to reconnect (attempt" << _reconnectAttempts << ")";

    // Reset connection state flags for reconnection
    _pcContext.dataChannelOpened.store(false);
    _pcContext.remoteDescriptionSet.store(false);
    _videoStreamActive.store(false);

    // Clear pending candidates
    {
        QMutexLocker locker(&_pcContext.candidateMutex);
        _pcContext.pendingCandidates.clear();
    }

    // Setup new peer connection
    _setupPeerConnection();

    // Store GCS and target drone information again
    _currentGcsId = _connectionConfig.gcsId;
    _currentTargetDroneId = _connectionConfig.targetDroneId;
    _gcsRegistered = false;

    if (_signalingManager) {
        // Reconnecting -> Connecting 상태 전이
        if (transitionState(WorkerState::Reconnecting, WorkerState::Connecting)) {
            qCDebug(WebRTCLinkLog) << "Reconnection GCS ID:" << _connectionConfig.gcsId << " target drone:" << _connectionConfig.targetDroneId;
            _signalingManager->registerGCS(_connectionConfig.gcsId, _connectionConfig.targetDroneId);
            emit rtcStatusMessageChanged(QString("재연결 시도 중 (%1)").arg(_reconnectAttempts));
        } else {
            qCWarning(WebRTCLinkLog) << "Failed to transition to Connecting state during reconnect";
        }
    } else {
        qCWarning(WebRTCLinkLog) << "Signaling manager not available for reconnection";
        emit rtcStatusMessageChanged("시그널링 매니저 사용 불가");
    }
}

void WebRTCWorker::manualReconnect()
{
    qCDebug(WebRTCLinkLog) << "Manual reconnection requested, state:" << stateToString();

    WorkerState currentState = _state.load();

    // Disconnecting, CleaningUp, Shutdown 상태에서는 재연결 불가
    if (currentState == WorkerState::Disconnecting ||
        currentState == WorkerState::CleaningUp ||
        currentState == WorkerState::Shutdown) {
        qCWarning(WebRTCLinkLog) << "Cannot reconnect from state:" << stateToString();
        emit rtcStatusMessageChanged("재연결 불가 상태");
        return;
    }

    // 이미 Reconnecting 상태면 무시
    if (currentState == WorkerState::Reconnecting) {
        qCDebug(WebRTCLinkLog) << "Already reconnecting, ignoring manual reconnect request";
        return;
    }

    qCDebug(WebRTCLinkLog) << "Starting manual reconnection process";

    // 재연결을 위해 기존 PeerConnection 정리 (Reconnecting 상태로 전환)
    if (transitionState(currentState, WorkerState::Reconnecting)) {
        // 타이머 중지
        if (_rttTimer) {
            _rttTimer->stop();
        }
        if (_statsTimer) {
            _statsTimer->stop();
        }

        // 기존 PeerConnection 정리
        if (_pcContext.pc) {
            qCDebug(WebRTCLinkLog) << "Cleaning up existing connections for manual reconnect";
            _resetPeerConnection();
        }

        // Reset connection state flags for reconnection
        _pcContext.dataChannelOpened.store(false);
        _pcContext.remoteDescriptionSet.store(false);
        _videoStreamActive.store(false);

        // Clear pending candidates
        {
            QMutexLocker locker(&_pcContext.candidateMutex);
            _pcContext.pendingCandidates.clear();
        }

        // Setup new peer connection
        _setupPeerConnection();

        // Store GCS and target drone information again
        _currentGcsId = _connectionConfig.gcsId;
        _currentTargetDroneId = _connectionConfig.targetDroneId;
        _gcsRegistered = false;

        if (_signalingManager) {
            // Reconnecting -> Connecting 상태 전이
            if (transitionState(WorkerState::Reconnecting, WorkerState::Connecting)) {
                qCDebug(WebRTCLinkLog) << "Manual reconnection GCS ID:" << _connectionConfig.gcsId
                                      << " target drone:" << _connectionConfig.targetDroneId;
                _signalingManager->registerGCS(_connectionConfig.gcsId, _connectionConfig.targetDroneId);
                emit rtcStatusMessageChanged("수동 재연결 중...");
            } else {
                qCWarning(WebRTCLinkLog) << "Failed to transition to Connecting state during manual reconnect";
            }
        } else {
            qCWarning(WebRTCLinkLog) << "Signaling manager not available for manual reconnection";
            emit rtcStatusMessageChanged("시그널링 매니저 사용 불가");
        }
    } else {
        qCWarning(WebRTCLinkLog) << "Failed to transition to Reconnecting state for manual reconnect";
    }
}

void WebRTCWorker::_setupPeerConnectionCallbacks(std::shared_ptr<rtc::PeerConnection> pc)
{
    if (!pc) return;

    QPointer<WebRTCWorker> self(this);
    std::weak_ptr<rtc::PeerConnection> weakPC = pc;

    // State change callback
    pc->onStateChange([self, weakPC](rtc::PeerConnection::State state) {
        auto pc = weakPC.lock();
        if (!pc || !self || !self->isOperational()) return;

        QMetaObject::invokeMethod(self, [self, weakPC, state]() {
            if (!self) return;

            QString stateStr = self->_stateToString(state);
            qCDebug(WebRTCLinkLog) << "[WEBRTC] PeerConnection state:" << stateStr;

            if (state == rtc::PeerConnection::State::Connected) {
                qCDebug(WebRTCLinkLog) << "[WEBRTC] Connected!";
                emit self->rtcStatusMessageChanged("연결됨");

                // ICE candidate 정보 캐싱 (타입 포함)
                if (auto pc = weakPC.lock()) {
                    try {
                        auto localAddr = pc->localAddress();
                        auto remoteAddr = pc->remoteAddress();
                        if (localAddr.has_value() && remoteAddr.has_value()) {
                            QString localAddrStr = QString::fromStdString(*localAddr);
                            QString remoteAddrStr = QString::fromStdString(*remoteAddr);

                            // getSelectedCandidatePair() API 사용하여 candidate 타입 확인
                            rtc::Candidate localCand, remoteCand;
                            if (pc->getSelectedCandidatePair(&localCand, &remoteCand)) {
                                QString candidateType = "unknown";
                                // Candidate::Type enum을 사용하여 타입 확인
                                switch (localCand.type()) {
                                    case rtc::Candidate::Type::Relayed:
                                        candidateType = "relay (TURN)";
                                        break;
                                    case rtc::Candidate::Type::ServerReflexive:
                                        candidateType = "srflx (STUN)";
                                        break;
                                    case rtc::Candidate::Type::PeerReflexive:
                                        candidateType = "prflx (Peer Reflexive)";
                                        break;
                                    case rtc::Candidate::Type::Host:
                                        candidateType = "host (Direct)";
                                        break;
                                    default:
                                        candidateType = "unknown";
                                        break;
                                }
                                qCDebug(WebRTCLinkLog) << "[WEBRTC] Selected candidate type:" << candidateType
                                                      << "Local:" << QString::fromStdString(localCand.candidate())
                                                      << "Remote:" << QString::fromStdString(remoteCand.candidate());

                                // candidate pair를 성공적으로 가져왔을 때만 캐시 업데이트
                                QString candidateInfo = QString("%1 ↔ %2 [%3]")
                                                                .arg(localAddrStr)
                                                                .arg(remoteAddrStr)
                                                                .arg(candidateType);
                                {
                                    QMutexLocker locker(&self->_cachedCandidateMutex);
                                    self->_cachedCandidate = candidateInfo;
                                }
                                qCDebug(WebRTCLinkLog) << "[WEBRTC] Candidate cached:" << candidateInfo;
                            } else {
                                // candidate pair를 가져오지 못했을 때는 이전 캐시 유지
                                QString currentCache;
                                {
                                    QMutexLocker locker(&self->_cachedCandidateMutex);
                                    currentCache = self->_cachedCandidate;
                                }
                                qCDebug(WebRTCLinkLog) << "[WEBRTC] Cannot get candidate pair, keeping previous cached value:"
                                                      << currentCache;
                            }
                        }
                    } catch (const std::exception& e) {
                        qCWarning(WebRTCLinkLog) << "[WEBRTC] Failed to cache candidate:" << e.what();
                    }
                }
            } else if (state == rtc::PeerConnection::State::Failed ||
                       state == rtc::PeerConnection::State::Disconnected ||
                       state == rtc::PeerConnection::State::Closed) {
                {
                    QMutexLocker locker(&self->_cachedCandidateMutex);
                    self->_cachedCandidate.clear();
                }
                self->_rttMs = 0;
                qCWarning(WebRTCLinkLog) << "[WEBRTC] Connection failed/disconnected, candidate and RTT cleared";

                emit self->rtcStatusMessageChanged("연결 끊김 - 재연결 시도");
                QMetaObject::invokeMethod(self, [self]() {
                    if (self && !self->_waitingForReconnect.load() && !self->isShuttingDown()) {
                        self->_handlePeerDisconnection();
                    }
                }, Qt::QueuedConnection);
            }
        }, Qt::QueuedConnection);
    });

    // Local description callback
    pc->onLocalDescription([self, weakPC](rtc::Description description) {
        auto pc = weakPC.lock();
        if (!pc || !self || !self->isOperational()) return;

        QString descType = QString::fromStdString(description.typeString());
        QString sdpContent = QString::fromStdString(description);

        qCDebug(WebRTCLinkLog) << "[WEBRTC] Local description created:" << descType;

        QMetaObject::invokeMethod(self, [self, descType, sdpContent]() {
            if (!self) return;

            QJsonObject message;
            message["id"] = self->_currentGcsId;
            message["to"] = self->_currentTargetDroneId;
            message["type"] = descType;
            message["sdp"] = sdpContent;

            self->_sendSignalingMessage(message);
        }, Qt::QueuedConnection);
    });

    // Local candidate callback
    pc->onLocalCandidate([self, weakPC](rtc::Candidate candidate) {
        auto pc = weakPC.lock();
        if (!pc || !self || !self->isOperational()) return;

        QString candidateStr = QString::fromStdString(candidate);
        QString mid = QString::fromStdString(candidate.mid());

        QMetaObject::invokeMethod(self, [self, candidateStr, mid]() {
            if (!self) return;

            QJsonObject message;
            message["id"] = self->_currentGcsId;
            message["to"] = self->_currentTargetDroneId;
            message["type"] = "candidate";
            message["candidate"] = candidateStr;
            message["sdpMid"] = mid;

            self->_sendSignalingMessage(message);
        }, Qt::QueuedConnection);
    });

    // Data channel callback
    pc->onDataChannel([self, weakPC](std::shared_ptr<rtc::DataChannel> dc) {
        auto pc = weakPC.lock();
        if (!pc || !self || !dc) {
            qCDebug(WebRTCLinkLog) << "[WEBRTC] ERROR: PeerConnection, Worker or DataChannel is null!";
            return;
        }

        if (self->isShuttingDown()) {
            qCDebug(WebRTCLinkLog) << "[WEBRTC] Shutting down, ignoring";
            return;
        }

        std::string label = dc->label();

        QMetaObject::invokeMethod(self, [self, dc, label]() {
            if (!self || !self->isOperational()) return;

            qCDebug(WebRTCLinkLog) << "[WEBRTC] DataChannel received:" << QString::fromStdString(label);

            if (label == "mavlink") {
                self->_pcContext.mavlinkDc = dc;
                qCDebug(WebRTCLinkLog) << "[WEBRTC] mavlink DataChannel created";
                self->_setupMavlinkDataChannel(dc);
            } else if (label == "custom") {
                self->_pcContext.customDc = dc;
                self->_setupCustomDataChannel(dc);
            }

            // mavlink 채널일 때만 _processDataChannelOpen 호출
            // (custom 채널이 먼저 열리면 mavlinkDc가 아직 없어서 경고 발생 방지)
            if (label == "mavlink" && dc->isOpen()) {
                self->_processDataChannelOpen();
            }
        }, Qt::QueuedConnection);
    });

    pc->onTrack([self, weakPC](std::shared_ptr<rtc::Track> track) {
        auto pc = weakPC.lock();
        if (!pc || !self || !self->isOperational()) return;

        QMetaObject::invokeMethod(self, [self, track]() {
            if (!self || !self->isOperational()) return;

            qCDebug(WebRTCLinkLog) << "[WEBRTC] video track received";
            self->_pcContext.videoTrack = track;
            self->_handleTrackReceived(track);
        }, Qt::QueuedConnection);
    });
}

void WebRTCWorker::_setupPeerConnection()
{
    qCDebug(WebRTCLinkLog) << "Setting up single PeerConnection with ICE auto-selection";

    try {
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

        // Configuration 생성 (STUN + TURN 모두 포함)
        rtc::Configuration config;
        config.iceServers.clear();

        // STUN 서버 추가 (P2P 직접 연결용)
        if (!_connectionConfig.stunServer.isEmpty()) {
            config.iceServers.emplace_back(_connectionConfig.stunServer.toStdString());
            qCDebug(WebRTCLinkLog) << "Added STUN server:" << _connectionConfig.stunServer;
        }

        // TURN 서버 추가 (중계 연결용)
        if (!_connectionConfig.turnServer.isEmpty()) {
            rtc::IceServer turnServer(_connectionConfig.turnServer.toStdString());
            turnServer.username = _connectionConfig.turnUsername.toStdString();
            turnServer.password = _connectionConfig.turnPassword.toStdString();
            config.iceServers.emplace_back(turnServer);
            qCDebug(WebRTCLinkLog) << "Added TURN server:" << _connectionConfig.turnServer;
        }

        // PeerConnection 생성
        _pcContext.pc = std::make_shared<rtc::PeerConnection>(config);
        _setupPeerConnectionCallbacks(_pcContext.pc);
        qCDebug(WebRTCLinkLog) << "PeerConnection created successfully with STUN+TURN (ICE auto-selection)";

    } catch (const std::exception& e) {
        qCWarning(WebRTCLinkLog) << "Failed to create PeerConnection:" << e.what();
        emit errorOccurred(QString("Failed to create PeerConnection: %1").arg(e.what()));
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
    _onPeerStateChanged(state);
}



void WebRTCWorker::_setupMavlinkDataChannel(std::shared_ptr<rtc::DataChannel> dc)
{
    if (!dc) return;

    QPointer<WebRTCWorker> self(this);

    dc->setBufferedAmountLowThreshold(BUFFER_LOW_THRESHOLD);

    dc->onOpen([self]() {
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] MavlinkDataChannel OPENED";
        if (!self || self->isShuttingDown()) return;

        self->_processDataChannelOpen();
    });

    dc->onClosed([self]() {
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] DataChannel CLOSED";
        if (!self || self->isShuttingDown()) return;

        self->_pcContext.dataChannelOpened.store(false);
        QMetaObject::invokeMethod(self, [self]() {
            if (!self || self->isDisconnecting()) return;
            emit self->rttUpdated(0);
        }, Qt::QueuedConnection);
    });

    dc->onError([self](std::string error) {
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] ERROR:" << QString::fromStdString(error);
        if (!self || self->isShuttingDown()) return;

        QString errorMsg = QString::fromStdString(error);
        QMetaObject::invokeMethod(self, [self, errorMsg]() {
            if (!self) return;
            emit self->errorOccurred("DataChannel error: " + errorMsg);
        }, Qt::QueuedConnection);
    });

    dc->onMessage([self](auto data) {
        if (!self || self->isShuttingDown()) return;

        if (std::holds_alternative<rtc::binary>(data)) {
            const auto& binaryData = std::get<rtc::binary>(data);
            QByteArray byteArray(reinterpret_cast<const char*>(binaryData.data()), binaryData.size());

            self->_dataChannelReceivedCalc.addData(byteArray.size());
            emit self->bytesReceived(byteArray);
        }
    });
}

void WebRTCWorker::_setupCustomDataChannel(std::shared_ptr<rtc::DataChannel> dc)
{
    if (!dc) return;

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
        if (!self || self->isShuttingDown()) return;

        if (std::holds_alternative<rtc::binary>(data)) {
            const auto& binaryData = std::get<rtc::binary>(data);
            qCDebug(WebRTCLinkLog) << "[CUSTOM] Binary data size:" << binaryData.size() << "bytes";

            self->_dataChannelReceivedCalc.addData(binaryData.size());

            QByteArray byteArray(reinterpret_cast<const char*>(binaryData.data()), binaryData.size());
            QString receivedText = QString::fromUtf8(byteArray);
            qCDebug(WebRTCLinkLog) << "[CUSTOM] Binary data:" << receivedText;

        } else if (std::holds_alternative<std::string>(data)) {
            const std::string& receivedText = std::get<std::string>(data);

            QJsonParseError parseError;
            QJsonDocument jsonDoc = QJsonDocument::fromJson(QString::fromStdString(receivedText).toUtf8(), &parseError);

            if (parseError.error == QJsonParseError::NoError) {
                QJsonObject jsonObj = jsonDoc.object();

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
    if (_pcContext.dataChannelOpened.exchange(true)) {
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] Already opened, ignoring";
        return;
    }

    if (isShuttingDown()) {
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] Shutting down, ignoring open";
        return;
    }

    bool isConnected = _pcContext.mavlinkDc && _pcContext.mavlinkDc->isOpen();

    qCDebug(WebRTCLinkLog) << "[DATACHANNEL] Connection check - Connected:" << isConnected;

    if (!isConnected) {
        qCWarning(WebRTCLinkLog) << "[DATACHANNEL] ERROR: DataChannel is not actually open!";
        _pcContext.dataChannelOpened.store(false);
        return;
    }

    qCDebug(WebRTCLinkLog) << "[DATACHANNEL] Connection established! Emitting connected signal";

    QMetaObject::invokeMethod(this, [this]() {
        emit connected();
        emit rtcStatusMessageChanged("연결 성공");

        _startTimers();
    }, Qt::QueuedConnection);
}

void WebRTCWorker::_startTimers()
{
    if (!_rttTimer) {
        _rttTimer = new QTimer(this);
        connect(_rttTimer, &QTimer::timeout, this, &WebRTCWorker::_updateRtt);
    }
    if (_rttTimer && !_rttTimer->isActive()) {
        _rttTimer->start(RTT_UPDATE_INTERVAL_MS);
    }

    if (_statsTimer && !_statsTimer->isActive()) {
        _statsTimer->start(STATS_UPDATE_INTERVAL_MS);
    }
}

void WebRTCWorker::_handleTrackReceived(std::shared_ptr<rtc::Track> track)
{
    auto desc = track->description();

    if (desc.type() == "video") {
        qCDebug(WebRTCLinkLog) << "[WebRTC] video track received";

        _pcContext.videoTrack = track;
        emit videoTrackReceived();

        if (VideoManager::instance()->isWebRtcInternalModeEnabled()) {
            _videoStreamActive.store(true);
            qCDebug(WebRTCLinkLog) << "[WebRTC] Internal mode: video stream active";
        }

        QPointer<WebRTCWorker> self(this);

        track->onMessage([self](rtc::message_variant message) {
            if (!self || !std::holds_alternative<rtc::binary>(message)) return;
            if (self->isShuttingDown() || !self->_videoStreamActive.load()) return;

            const auto& binaryData = std::get<rtc::binary>(message);
            QByteArray rtpData(reinterpret_cast<const char*>(binaryData.data()), binaryData.size());

            if (VideoManager::instance() && VideoManager::instance()->isWebRtcInternalModeEnabled()) {
                self->_videoReceivedCalc.addData(rtpData.size());
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

    if (type == "answer") {
        qCDebug(WebRTCLinkLog) << "[SIGNALING] Processing ANSWER";

        try {
            QString sdp = message["sdp"].toString();
            rtc::Description answer(sdp.toStdString(), "answer");

            if (!_pcContext.pc) {
                qCWarning(WebRTCLinkLog) << "[ANSWER] No peer connection available";
                return;
            }

            qCDebug(WebRTCLinkLog) << "[WEBRTC] Setting remote description for answer";
            _pcContext.pc->setRemoteDescription(answer);
            _pcContext.remoteDescriptionSet.store(true);

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

        // GCS는 answerer 역할이므로 offer를 기다림
        // PeerConnection은 offer를 받을 때 설정 (중복 설정 방지)
        qCDebug(WebRTCLinkLog) << "GCS prepared as WebRTC answerer, waiting for drone offer";
    } else {
        QString reason = message["reason"].toString();
        qCWarning(WebRTCLinkLog) << "GCS registration failed:" << reason;
        emit rtcStatusMessageChanged(QString("등록 실패: %1").arg(reason));
        emit errorOccurred(QString("등록 실패: %1").arg(reason));
    }
}

void WebRTCWorker::_onWebRTCOfferReceived(const QJsonObject& message)
{
    if (isShuttingDown()) {
        qCDebug(WebRTCLinkLog) << "Shutting down, ignoring WebRTC offer";
        return;
    }

    QString fromDroneId = message["from"].toString();

    QString sdp = message["sdp"].toString();
    if (sdp.isEmpty()) {
        qCWarning(WebRTCLinkLog) << "Invalid offer format: missing 'sdp' field";
        return;
    }

    qCDebug(WebRTCLinkLog) << "Received WebRTC offer from drone:" << fromDroneId;

    try {
        rtc::Description droneOffer(sdp.toStdString(), "offer");

        if (_pcContext.pc) {
            auto currentState = _pcContext.pc->state();
            auto signalingState = _pcContext.pc->signalingState();

            qCDebug(WebRTCLinkLog) << "[WEBRTC] Existing connection found -"
                                  << "State:" << _stateToString(currentState)
                                  << "Signaling:" << static_cast<int>(signalingState);

            if (currentState == rtc::PeerConnection::State::Connecting ||
                currentState == rtc::PeerConnection::State::Connected) {
                qCDebug(WebRTCLinkLog) << "[WEBRTC] Ignoring duplicate offer - connection already in progress/connected";
                return;
            }

            if (currentState == rtc::PeerConnection::State::Failed ||
                currentState == rtc::PeerConnection::State::Disconnected) {
                qCDebug(WebRTCLinkLog) << "[WEBRTC] Resetting failed/disconnected connection";
                emit rtcStatusMessageChanged("재연결 시작: 기존 연결 재설정 중...");
                _resetPeerConnection();
            }
        }

        if (!_pcContext.pc) {
            qCDebug(WebRTCLinkLog) << "[WEBRTC] Creating new PeerConnection for drone offer";
            _setupPeerConnection();

            if (!_pcContext.pc) {
                qCWarning(WebRTCLinkLog) << "[WEBRTC] Failed to create PeerConnection, scheduling retry";
                emit errorOccurred("PeerConnection 생성 실패 - 자동 재시도 예정");

                if (!_waitingForReconnect.load() && !isShuttingDown()) {
                    qCDebug(WebRTCLinkLog) << "[WEBRTC] Scheduling reconnect after PeerConnection creation failure";
                    _scheduleReconnect();
                }
                return;
            }

            auto newState = _pcContext.pc->state();
            auto newSignalingState = _pcContext.pc->signalingState();
            qCDebug(WebRTCLinkLog) << "[WEBRTC] New PeerConnection created -"
                                  << "State:" << _stateToString(newState)
                                  << "Signaling:" << static_cast<int>(newSignalingState);
        }

        qCDebug(WebRTCLinkLog) << "[WEBRTC] Setting remote description (answer will be auto-generated)...";
        _pcContext.pc->setRemoteDescription(droneOffer);
        _pcContext.remoteDescriptionSet.store(true);
        qCDebug(WebRTCLinkLog) << "[WEBRTC] Remote description set, answer will be sent via onLocalDescription callback";
        emit rtcStatusMessageChanged("드론으로부터 offer 수신 완료");

    } catch (const std::exception& e) {
        qCWarning(WebRTCLinkLog) << "[WEBRTC] Failed to process drone offer:" << e.what();
        emit errorOccurred(QString("드론 offer 처리 실패: %1").arg(e.what()));

        qCWarning(WebRTCLinkLog) << "[WEBRTC] Resetting connection after offer processing failure";
        _resetPeerConnection();
    }
}

void WebRTCWorker::_handleICECandidate(const QJsonObject& message)
{
    QString fromDroneId = message["from"].toString();
    QString candidateStr = message["candidate"].toString();
    QString sdpMid = message["sdpMid"].toString();

    if (candidateStr.isEmpty() || sdpMid.isEmpty()) {
        qCWarning(WebRTCLinkLog) << "Invalid ICE candidate format: missing 'candidate' or 'sdpMid' field";
        return;
    }

    qCDebug(WebRTCLinkLog) << "Received ICE candidate from:" << fromDroneId;

    try {
        rtc::Candidate iceCandidate(candidateStr.toStdString(), sdpMid.toStdString());

        auto pc = _pcContext.pc;
        if (!pc) {
            qCWarning(WebRTCLinkLog) << "[WEBRTC] No PeerConnection available for candidate";
            return;
        }

        if (_pcContext.remoteDescriptionSet.load(std::memory_order_acquire)) {
            qCDebug(WebRTCLinkLog) << "[WEBRTC] Adding ICE candidate immediately";

            if (pc) {
                try {
                    pc->addRemoteCandidate(iceCandidate);
                    qCDebug(WebRTCLinkLog) << "[WEBRTC] Remote candidate added successfully";
                } catch (const std::exception& e) {
                    qCWarning(WebRTCLinkLog) << "[WEBRTC] Failed to add remote candidate:" << e.what();
                }
            } else {
                qCWarning(WebRTCLinkLog) << "[WEBRTC] PeerConnection became null during candidate addition";
            }
        } else {
            qCDebug(WebRTCLinkLog) << "[WEBRTC] ICE candidate queued, waiting for remote description";
            QMutexLocker locker(&_pcContext.candidateMutex);
            _pcContext.pendingCandidates.push_back(iceCandidate);
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
        QString pairedWith = message["pairedWith"].toString();

        // 자신과 페어링된 경우라면 재등록 시도
        if (pairedWith == _currentGcsId) {
            qCDebug(WebRTCLinkLog) << "Already paired with self, forcing re-registration";
            emit rtcStatusMessageChanged("재연결 중 - 기존 세션 정리");

            // 강제 unregister 후 재등록
            if (_signalingManager && !_currentGcsId.isEmpty()) {
                _signalingManager->unregisterGCS(_currentGcsId);

                QPointer<WebRTCWorker> self(this);

                QTimer::singleShot(1000, this, [self]() {
                    if (!self || self->isShuttingDown()) {
                        return;
                    }
                    if (self->_currentGcsId.isEmpty() || self->_currentTargetDroneId.isEmpty()) {
                        return;
                    }

                    qCDebug(WebRTCLinkLog) << "Retrying registration after forced unregister";
                    self->_signalingManager->registerGCS(self->_currentGcsId, self->_currentTargetDroneId);
                });
            }
            return; // 에러로 처리하지 않음
        }

        // 다른 GCS와 페어링된 경우
        QString msg = QString("기체가 다른 장치와 페어링되어 있습니다: %1").arg(pairedWith);
        emit rtcStatusMessageChanged(msg);
        emit errorOccurred(msg);
        return;
    }

    QString msg = QString("서버 오류: %1").arg(errorMessage);
    emit rtcStatusMessageChanged(msg);
    emit errorOccurred(msg);
}

void WebRTCWorker::_handlePeerDisconnection()
{
    qCDebug(WebRTCLinkLog) << "[DISCONNECT] Handling peer disconnection, current state:"
                           << static_cast<int>(_state.load());

    if (isInState(WorkerState::Shutdown) || isInState(WorkerState::CleaningUp)) {
        qCDebug(WebRTCLinkLog) << "[DISCONNECT] Already shutting down, ignoring disconnection";
        return;
    }

    WorkerState currentState = _state.load();
    if (currentState == WorkerState::Connected ||
        currentState == WorkerState::EstablishingPeer ||
        currentState == WorkerState::WaitingForOffer) {

        if (!transitionState(currentState, WorkerState::Reconnecting)) {
            qCWarning(WebRTCLinkLog) << "[DISCONNECT] Failed to transition to Reconnecting state from"
                                     << static_cast<int>(currentState);
        }
    }

    if (_statsTimer) {
        _statsTimer->stop();
    }
    if (_rttTimer) {
        _rttTimer->stop();
    }

    _pcContext.dataChannelOpened.store(false);

    if (_signalingManager && !_currentGcsId.isEmpty()) {
        qCDebug(WebRTCLinkLog) << "Unregistering GCS due to peer disconnection:" << _currentGcsId;
        _signalingManager->unregisterGCS(_currentGcsId);
        emit rtcStatusMessageChanged("피어 연결 해제 - GCS 등록 해제 중...");
    }

    _cleanup(CleanupMode::ForReconnection);

    emit rttUpdated(0);
    emit disconnected();

    if (!isInState(WorkerState::Shutdown) && !_waitingForReconnect.load()) {
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

    _pcContext.reset();

    _rttMs = 0;
    {
        QMutexLocker locker(&_cachedCandidateMutex);
        _cachedCandidate.clear();
    }

    _dataChannelSentCalc.reset();
    _dataChannelReceivedCalc.reset();
    _videoReceivedCalc.reset();

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

void WebRTCWorker::_onPeerStateChanged(rtc::PeerConnection::State state)
{
    QString stateStr = _stateToString(state);
    emit rtcStatusMessageChanged(stateStr);

    qCDebug(WebRTCLinkLog) << "[PEER_STATE] Changed to:" << stateStr
                           << "Worker state:" << static_cast<int>(_state.load());

    if (state == rtc::PeerConnection::State::Connected) {
        qCDebug(WebRTCLinkLog) << "PeerConnection fully connected!";

        WorkerState currentState = _state.load();
        if (currentState == WorkerState::EstablishingPeer ||
            currentState == WorkerState::WaitingForOffer ||
            currentState == WorkerState::Reconnecting) {

            if (transitionState(currentState, WorkerState::Connected)) {
                qCDebug(WebRTCLinkLog) << "[PEER_STATE] Successfully transitioned to Connected state";
                // 연결 성공 시 재연결 카운터 리셋
                _onReconnectSuccess();
            } else {
                qCWarning(WebRTCLinkLog) << "[PEER_STATE] Failed to transition to Connected state from"
                                        << static_cast<int>(currentState);
            }
        }
    }

    if ((state == rtc::PeerConnection::State::Failed ||
         state == rtc::PeerConnection::State::Disconnected) &&
         !isInState(WorkerState::Disconnecting) &&
         !isInState(WorkerState::Shutdown)) {

        qCDebug(WebRTCLinkLog) << "[DEBUG] PeerConnection failed/disconnected – scheduling reconnect";

        emit rtcStatusMessageChanged("WebRTC 연결 끊김 - 재연결 시도 중...");

        WorkerState currentState = _state.load();
        if (currentState == WorkerState::Connected ||
            currentState == WorkerState::EstablishingPeer) {

            if (transitionState(currentState, WorkerState::Reconnecting)) {
                qCDebug(WebRTCLinkLog) << "[PEER_STATE] Transitioned to Reconnecting state";
            }
        }

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
        qCDebug(WebRTCLinkLog) << "[DEBUG] ICE Gathering Complete for dual-path connection";
    }
}

void WebRTCWorker::_updateRtt()
{
    // Disconnecting/Shutdown 상태에서는 RTT 업데이트 스킵
    if (isDisconnecting() || isShuttingDown()) {
        return;
    }

    // Single path: collect RTT from the single peer connection
    if (_pcContext.pc) {
        auto rttOpt = _pcContext.pc->rtt();
        if (rttOpt.has_value()) {
            _rttMs = rttOpt.value().count();
        }
    } else {
        _rttMs = 0;
    }

    // WebRTCStats 수집 (RTT와 candidate 정보 모두 포함)
    WebRTCStats stats = _collectWebRTCStats();

    // 디버그: Candidate가 실제로 변경되었을 때만 로그 출력 (빈 값 무시)
    static QString lastCandidate;
    QString currentCandidate;
    {
        QMutexLocker locker(&_cachedCandidateMutex);
        currentCandidate = _cachedCandidate;
    }
    if (!currentCandidate.isEmpty() && currentCandidate != lastCandidate) {
        qCDebug(WebRTCLinkLog) << "[RTT_UPDATE] Candidate changed:"
                              << (lastCandidate.isEmpty() ? "(empty)" : lastCandidate)
                              << "->" << currentCandidate;
        lastCandidate = currentCandidate;
    }

    emit webRtcStatsUpdated(stats);

    // 기존 시그널도 유지
    if (_rttMs > 0) {
        emit rttUpdated(_rttMs);
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
    WorkerState currentState = _state.load();

    if (isInState(WorkerState::CleaningUp)) {
        qCDebug(WebRTCLinkLog) << "Already in CleaningUp state, ignoring duplicate call";
        return;
    }

    bool transitioned = false;
    if (mode == CleanupMode::Complete) {
        if (currentState != WorkerState::Shutdown) {
            transitioned = transitionState(currentState, WorkerState::CleaningUp);
        }
    } else {
        if (currentState == WorkerState::Disconnecting ||
            currentState == WorkerState::Reconnecting ||
            currentState == WorkerState::Connected) {
            transitioned = transitionState(currentState, WorkerState::CleaningUp);
        }
    }

    if (!transitioned && currentState != WorkerState::CleaningUp) {
        qCWarning(WebRTCLinkLog) << "Cannot transition to CleaningUp from state:"
                                 << stateToString(currentState) << "mode:"
                                 << (mode == CleanupMode::Complete ? "Complete" : "ForReconnection");
        return;
    }

    qCDebug(WebRTCLinkLog) << "Cleaning up WebRTC resources, mode:"
                          << (mode == CleanupMode::Complete ? "Complete" : "ForReconnection")
                          << "from state:" << stateToString(currentState);

    if (mode == CleanupMode::Complete && _waitingForReconnect.load()) {
        qCDebug(WebRTCLinkLog) << "Auto-reconnection in progress, skipping complete cleanup";
        transitionState(WorkerState::CleaningUp, WorkerState::Idle);
        return;
    }

    _pcContext.dataChannelOpened.store(false);

    _safeDeleteTimer(_rttTimer, "RTT Timer");

    if (_statsTimer) {
        _statsTimer->stop();
    }

    _resetPeerConnection();

    _rttMs = 0;
    {
        QMutexLocker locker(&_cachedCandidateMutex);
        _cachedCandidate.clear();
    }
    _dataChannelSentCalc.reset();
    _dataChannelReceivedCalc.reset();
    _videoReceivedCalc.reset();

    if (mode == CleanupMode::Complete) {
        _currentGcsId.clear();
        _currentTargetDroneId.clear();
        _gcsRegistered = false;

        qCDebug(WebRTCLinkLog) << "Complete cleanup finished. Signaling server remains connected for other peers";

        transitionState(WorkerState::CleaningUp, WorkerState::Shutdown);
    } else {
        qCDebug(WebRTCLinkLog) << "Cleanup for reconnection completed, ready for new connection";

        if (_waitingForReconnect.load()) {
            transitionState(WorkerState::CleaningUp, WorkerState::Reconnecting);
        } else {
            transitionState(WorkerState::CleaningUp, WorkerState::Idle);
        }
    }
}

WebRTCStats WebRTCWorker::_collectWebRTCStats() const
{
    WebRTCStats stats;
    stats.rttMs = _rttMs;

    {
        QMutexLocker locker(&_cachedCandidateMutex);
        stats.iceCandidate = _cachedCandidate;
    }

    stats.webRtcSent = _dataChannelSentCalc.getCurrentRate();
    stats.webRtcRecv = _dataChannelReceivedCalc.getCurrentRate();

    stats.videoRateKBps = _videoReceivedCalc.getCurrentRate();
    stats.videoPacketCount = _videoReceivedCalc.getStats().totalPackets;
    stats.videoBytesReceived = _videoReceivedCalc.getStats().totalBytes;

    return stats;
}

void WebRTCWorker::_updateAllStatistics()
{
    _dataChannelSentCalc.updateRate();
    _dataChannelReceivedCalc.updateRate();
    _videoReceivedCalc.updateRate();

    WebRTCStats stats = _collectWebRTCStats();

    emit webRtcStatsUpdated(stats);

    emit dataChannelStatsUpdated(stats.webRtcSent, stats.webRtcRecv);
    emit videoStatsUpdated(stats.videoRateKBps, stats.videoPacketCount, stats.videoBytesReceived);
    emit videoRateChanged(stats.videoRateKBps);

    emit statisticsUpdated();
}

bool WebRTCWorker::isWaitingForReconnect() const
{
    return _waitingForReconnect.load();
}

/*===========================================================================*/
// State Machine Methods
/*===========================================================================*/

bool WebRTCWorker::transitionState(WorkerState expected, WorkerState desired)
{
    if (!canTransitionTo(desired)) {
        qCWarning(WebRTCLinkLog) << "Invalid state transition:"
                                 << stateToString(expected) << "->" << stateToString(desired);
        return false;
    }

    if (_state.compare_exchange_strong(expected, desired)) {
        qCDebug(WebRTCLinkLog) << "[STATE] Transition successful:"
                               << stateToString(expected) << "->" << stateToString(desired);
        return true;
    } else {
        WorkerState currentState = _state.load();
        qCWarning(WebRTCLinkLog) << "[STATE] Transition failed. Current:"
                                 << stateToString(currentState) << "Expected:"
                                 << stateToString(expected) << "Desired:" << stateToString(desired);
        return false;
    }
}

bool WebRTCWorker::canTransitionTo(WorkerState newState) const
{
    WorkerState currentState = _state.load();

    if (currentState == newState) {
        return true;
    }

    if (currentState == WorkerState::Shutdown) {
        return false;
    }

    if (newState == WorkerState::CleaningUp || newState == WorkerState::Shutdown) {
        return true;
    }

    // 상태별 유효한 전이 정의
    switch (currentState) {
        case WorkerState::Idle:
            return newState == WorkerState::Starting;

        case WorkerState::Starting:
            return newState == WorkerState::Connecting ||
                   newState == WorkerState::Disconnecting ||
                   newState == WorkerState::Reconnecting;

        case WorkerState::Connecting:
            return newState == WorkerState::WaitingForOffer ||
                   newState == WorkerState::Disconnecting ||
                   newState == WorkerState::Reconnecting;

        case WorkerState::WaitingForOffer:
            return newState == WorkerState::EstablishingPeer ||
                   newState == WorkerState::Disconnecting ||
                   newState == WorkerState::Reconnecting;

        case WorkerState::EstablishingPeer:
            return newState == WorkerState::Connected ||
                   newState == WorkerState::Disconnecting ||
                   newState == WorkerState::Reconnecting;

        case WorkerState::Connected:
            return newState == WorkerState::Disconnecting ||
                   newState == WorkerState::Reconnecting;

        case WorkerState::Disconnecting:
            return newState == WorkerState::Idle;

        case WorkerState::Reconnecting:
            return newState == WorkerState::Starting ||
                   newState == WorkerState::Connecting ||
                   newState == WorkerState::Disconnecting;

        case WorkerState::CleaningUp:
            return newState == WorkerState::Idle ||
                   newState == WorkerState::Reconnecting;

        default:
            return false;
    }
}

QString WebRTCWorker::stateToString() const
{
    return stateToString(_state.load());
}

QString WebRTCWorker::stateToString(WorkerState state) const
{
    switch (state) {
        case WorkerState::Idle:              return "Idle";
        case WorkerState::Starting:          return "Starting";
        case WorkerState::Connecting:        return "Connecting";
        case WorkerState::WaitingForOffer:   return "WaitingForOffer";
        case WorkerState::EstablishingPeer:  return "EstablishingPeer";
        case WorkerState::Connected:         return "Connected";
        case WorkerState::Disconnecting:     return "Disconnecting";
        case WorkerState::Reconnecting:      return "Reconnecting";
        case WorkerState::CleaningUp:        return "CleaningUp";
        case WorkerState::Shutdown:          return "Shutdown";
        default:                             return "Unknown";
    }
}

/*===========================================================================*/
// Timer Management Methods
/*===========================================================================*/

void WebRTCWorker::_safeDeleteTimer(QTimer*& timer, const char* name)
{
    if (!timer) {
        return;
    }

    qCDebug(WebRTCLinkLog) << "Cleaning up timer:" << name;
    timer->stop();
    timer->disconnect();

    if (isShuttingDown()) {
        delete timer;
    } else {
        timer->deleteLater();
    }
    timer = nullptr;
}

/*===========================================================================*/
// Reconnection Management Methods
/*===========================================================================*/

int WebRTCWorker::_calculateReconnectDelay() const
{
    // 배열 기반 재연결 지연 (빠른 초기 재시도, 점진적 증가)
    static const int DELAYS_MS[] = {
        100,    // 1차: 0.1초 (빠른 재시도)
        500,   // 2차: 0.5초
        1000,   // 3차: 1초
        3000,   // 4차: 3초
        5000,  // 5차: 5초
        10000   // 6차 이상: 10초
    };
    static const int NUM_DELAYS = sizeof(DELAYS_MS) / sizeof(int);

    // 배열 범위 내 인덱스 선택
    int index = std::min(_reconnectAttempts, NUM_DELAYS - 1);
    int baseDelay = DELAYS_MS[index];

    // 약간의 랜덤성 추가 (±10%, 네트워크 혼잡 방지)
    int jitter = baseDelay / 10;
    jitter = (QRandomGenerator::global()->bounded(jitter * 2)) - jitter;

    int finalDelay = baseDelay + jitter;

    qCDebug(WebRTCLinkLog) << "Reconnect delay calculation: attempt" << _reconnectAttempts
                          << "base:" << baseDelay << "ms, jitter:" << jitter << "ms, final:" << finalDelay << "ms";

    return finalDelay;
}

void WebRTCWorker::_scheduleReconnect()
{
    if (isInState(WorkerState::Shutdown)) {
        qCDebug(WebRTCLinkLog) << "In Shutdown state, not scheduling reconnect";
        return;
    }

    if (_waitingForReconnect.load()) {
        qCDebug(WebRTCLinkLog) << "Already waiting for reconnect, ignoring";
        return;
    }

    if (_reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
        qCWarning(WebRTCLinkLog) << "Max reconnection attempts reached:" << MAX_RECONNECT_ATTEMPTS;
        emit rtcStatusMessageChanged("최대 재연결 시도 횟수 도달");

        WorkerState currentState = _state.load();
        if (currentState == WorkerState::Reconnecting) {
            transitionState(currentState, WorkerState::Idle);
        }
        return;
    }

    WorkerState currentState = _state.load();
    if (!isInState(WorkerState::Reconnecting)) {
        if (currentState == WorkerState::Connected ||
            currentState == WorkerState::EstablishingPeer ||
            currentState == WorkerState::WaitingForOffer ||
            currentState == WorkerState::Connecting ||
            currentState == WorkerState::CleaningUp) {

            if (!transitionState(currentState, WorkerState::Reconnecting)) {
                qCWarning(WebRTCLinkLog) << "Failed to transition to Reconnecting from"
                                       << stateToString(currentState);
            }
        }
    }

    _reconnectAttempts++;
    int delay = _calculateReconnectDelay();

    qCDebug(WebRTCLinkLog) << "Scheduling reconnect in" << delay << "ms"
                          << "(attempt" << _reconnectAttempts << "/" << MAX_RECONNECT_ATTEMPTS << ")"
                          << "State:" << stateToString();

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

    if (isInState(WorkerState::Reconnecting)) {
        transitionState(WorkerState::Reconnecting, WorkerState::Idle);
    }
}

void WebRTCWorker::_onReconnectSuccess()
{
    qCDebug(WebRTCLinkLog) << "Reconnection successful, resetting attempts. State:" << stateToString();
    _reconnectAttempts = 0;
    _waitingForReconnect.store(false);

    if (_reconnectTimer && _reconnectTimer->isActive()) {
        _reconnectTimer->stop();
    }
}

