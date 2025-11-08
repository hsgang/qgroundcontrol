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

    _pcContext.remoteDescriptionSet.store(false);
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
    _pcContext.dataChannelOpened.store(false);
    _pcContext.remoteDescriptionSet.store(false);
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
    if (_isShuttingDown.load()) {
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
    return _pcContext.mavlinkDc && _pcContext.mavlinkDc->isOpen();
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
    _pcContext.dataChannelOpened.store(false);
    _pcContext.remoteDescriptionSet.store(false);
    _isDisconnecting.store(false);

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
    _isDisconnecting.store(false);

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
    qCDebug(WebRTCLinkLog) << "Reconnect requested";

    // 이전 connections이 아직 남아있으면 정리
    if (_pcContext.pc) {
        qCDebug(WebRTCLinkLog) << "Cleaning up existing connections before reconnect";
        _resetPeerConnection();
    }

    qCDebug(WebRTCLinkLog) << "Attempting to reconnect (attempt" << _reconnectAttempts << ")";

    // Reset ALL state flags for reconnection
    _isShuttingDown.store(false);      // 재연결을 위해 리셋 (중요!)
    _isDisconnecting.store(false);
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
        qCDebug(WebRTCLinkLog) << "Reconnection GCS ID:" << _connectionConfig.gcsId << " target drone:" << _connectionConfig.targetDroneId;
        _signalingManager->registerGCS(_connectionConfig.gcsId, _connectionConfig.targetDroneId);
        emit rtcStatusMessageChanged(QString("재연결 시도 중 (%1)").arg(_reconnectAttempts));
    } else {
        qCWarning(WebRTCLinkLog) << "Signaling manager not available for reconnection";
        emit rtcStatusMessageChanged("시그널링 매니저 사용 불가");
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
                                self->_cachedCandidate = QString("%1 ↔ %2 [%3]")
                                                                .arg(localAddrStr)
                                                                .arg(remoteAddrStr)
                                                                .arg(candidateType);
                                qCDebug(WebRTCLinkLog) << "[WEBRTC] Candidate cached:" << self->_cachedCandidate;
                            } else {
                                // candidate pair를 가져오지 못했을 때는 이전 캐시 유지
                                qCDebug(WebRTCLinkLog) << "[WEBRTC] Cannot get candidate pair, keeping previous cached value:"
                                                      << self->_cachedCandidate;
                            }
                        }
                    } catch (const std::exception& e) {
                        qCWarning(WebRTCLinkLog) << "[WEBRTC] Failed to cache candidate:" << e.what();
                    }
                }
            } else if (state == rtc::PeerConnection::State::Failed ||
                       state == rtc::PeerConnection::State::Disconnected ||
                       state == rtc::PeerConnection::State::Closed) {
                self->_cachedCandidate.clear();
                self->_rttMs = 0;
                qCWarning(WebRTCLinkLog) << "[WEBRTC] Connection failed/disconnected, candidate and RTT cleared";

                emit self->rtcStatusMessageChanged("연결 끊김 - 재연결 시도");
                QMetaObject::invokeMethod(self, [self]() {
                    if (self && !self->_waitingForReconnect.load() && !self->_isShuttingDown.load()) {
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

        if (self->_isShuttingDown.load()) {
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

            // 즉시 상태 확인
            if (dc->isOpen()) {
                self->_processDataChannelOpen();
            }
        }, Qt::QueuedConnection);
    });

    // Track callback
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
    //qCDebug(WebRTCLinkLog) << "[STATE] PeerConnection state changed to:" << stateValue;
    _onPeerStateChanged(state);
}



void WebRTCWorker::_setupMavlinkDataChannel(std::shared_ptr<rtc::DataChannel> dc)
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

        self->_pcContext.dataChannelOpened.store(false);
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

    dc->onMessage([self](auto data) {
        if (!self || self->_isShuttingDown.load()) return;

        if (std::holds_alternative<rtc::binary>(data)) {
            const auto& binaryData = std::get<rtc::binary>(data);
            QByteArray byteArray(reinterpret_cast<const char*>(binaryData.data()), binaryData.size());

            // 단일 경로: 직접 전달
            self->_dataChannelReceivedCalc.addData(byteArray.size());
            emit self->bytesReceived(byteArray);
        }
    });
}

void WebRTCWorker::_setupCustomDataChannel(std::shared_ptr<rtc::DataChannel> dc)
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
    if (_pcContext.dataChannelOpened.exchange(true)) {
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] Already opened, ignoring";
        return;
    }

    if (_isShuttingDown.load()) {
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] Shutting down, ignoring open";
        return;
    }

    // Single path: check if mavlink data channel is open
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

        // QPointer로 객체 수명 보호
        QPointer<WebRTCWorker> self(this);

        track->onMessage([self](rtc::message_variant message) {
            if (!self || !std::holds_alternative<rtc::binary>(message)) return;
            if (self->_isShuttingDown.load() || !self->_videoStreamActive.load()) return;

            const auto& binaryData = std::get<rtc::binary>(message);
            QByteArray rtpData(reinterpret_cast<const char*>(binaryData.data()), binaryData.size());

            if (VideoManager::instance() && VideoManager::instance()->isWebRtcInternalModeEnabled()) {
                // 통계
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

    // if (remoteId != _config->peerId()) {
    //     return;
    // }

    // offer 타입은 _onWebRTCOfferReceived에서 처리됨

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

    // 표준 WebRTC offer 형식 처리
    QString sdp = message["sdp"].toString();
    if (sdp.isEmpty()) {
        qCWarning(WebRTCLinkLog) << "Invalid offer format: missing 'sdp' field";
        return;
    }

    qCDebug(WebRTCLinkLog) << "Received WebRTC offer from drone:" << fromDroneId;

    // Offer를 받았으므로 재연결 모드 활성화 (shutdown 해제)
    _isShuttingDown.store(false);

    try {
        // WebRTC offer 처리
        rtc::Description droneOffer(sdp.toStdString(), "offer");

        // 기존 PeerConnection이 있는 경우의 처리
        if (_pcContext.pc) {
            auto currentState = _pcContext.pc->state();
            auto signalingState = _pcContext.pc->signalingState();

            qCDebug(WebRTCLinkLog) << "[WEBRTC] Existing connection found -"
                                  << "State:" << _stateToString(currentState)
                                  << "Signaling:" << static_cast<int>(signalingState);

            // 연결이 이미 진행 중이거나 연결되어 있으면 offer 무시 (중복 방지)
            if (currentState == rtc::PeerConnection::State::Connecting ||
                currentState == rtc::PeerConnection::State::Connected) {
                qCDebug(WebRTCLinkLog) << "[WEBRTC] Ignoring duplicate offer - connection already in progress/connected";
                return;
            }

            // Failed/Disconnected 상태인 경우에만 리셋
            if (currentState == rtc::PeerConnection::State::Failed ||
                currentState == rtc::PeerConnection::State::Disconnected) {
                qCDebug(WebRTCLinkLog) << "[WEBRTC] Resetting failed/disconnected connection";
                emit rtcStatusMessageChanged("재연결 시작: 기존 연결 재설정 중...");
                _resetPeerConnection();
            }
        }

        // PeerConnection이 없으면 새로 생성
        if (!_pcContext.pc) {
            qCDebug(WebRTCLinkLog) << "[WEBRTC] Creating new PeerConnection for drone offer";
            _setupPeerConnection();

            if (!_pcContext.pc) {
                qCWarning(WebRTCLinkLog) << "[WEBRTC] Failed to create PeerConnection";
                emit errorOccurred("PeerConnection 생성 실패");
                return;
            }

            // PeerConnection이 제대로 생성되었는지 확인
            auto newState = _pcContext.pc->state();
            auto newSignalingState = _pcContext.pc->signalingState();
            qCDebug(WebRTCLinkLog) << "[WEBRTC] New PeerConnection created -"
                                  << "State:" << _stateToString(newState)
                                  << "Signaling:" << static_cast<int>(newSignalingState);
        }

        // Remote description 설정 (answer는 onLocalDescription 콜백에서 자동 생성됨)
        qCDebug(WebRTCLinkLog) << "[WEBRTC] Setting remote description (answer will be auto-generated)...";
        _pcContext.pc->setRemoteDescription(droneOffer);
        _pcContext.remoteDescriptionSet.store(true);
        qCDebug(WebRTCLinkLog) << "[WEBRTC] Remote description set, answer will be sent via onLocalDescription callback";
        emit rtcStatusMessageChanged("드론으로부터 offer 수신 완료");

    } catch (const std::exception& e) {
        qCWarning(WebRTCLinkLog) << "[WEBRTC] Failed to process drone offer:" << e.what();
        emit errorOccurred(QString("드론 offer 처리 실패: %1").arg(e.what()));

        // 실패 시 연결 완전히 리셋
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

        if (!_pcContext.pc) {
            qCWarning(WebRTCLinkLog) << "[WEBRTC] No PeerConnection available for candidate";
            return;
        }

        if (_pcContext.remoteDescriptionSet.load(std::memory_order_acquire)) {
            qCDebug(WebRTCLinkLog) << "[WEBRTC] Adding ICE candidate immediately";
            _pcContext.pc->addRemoteCandidate(iceCandidate);
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
        // 재연결 시 발생할 수 있는 정상적인 상황
        QString pairedWith = message["pairedWith"].toString();

        // 자신과 페어링된 경우라면 재등록 시도
        if (pairedWith == _currentGcsId) {
            qCDebug(WebRTCLinkLog) << "Already paired with self, forcing re-registration";
            emit rtcStatusMessageChanged("재연결 중 - 기존 세션 정리");

            // 강제 unregister 후 재등록
            if (_signalingManager && !_currentGcsId.isEmpty()) {
                _signalingManager->unregisterGCS(_currentGcsId);

                // 짧은 지연 후 재등록 시도
                QTimer::singleShot(500, this, [this]() {
                    if (!_isShuttingDown.load() && !_currentGcsId.isEmpty() && !_currentTargetDroneId.isEmpty()) {
                        qCDebug(WebRTCLinkLog) << "Retrying registration after forced unregister";
                        _signalingManager->registerGCS(_currentGcsId, _currentTargetDroneId);
                    }
                });
            }
            return; // 에러로 처리하지 않음
        } else {
            emit rtcStatusMessageChanged(QString("기체가 다른 장치와 페어링되어 있습니다: %1").arg(pairedWith));
        }
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

    _pcContext.dataChannelOpened.store(false);
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

    // Use PeerConnectionContext reset method
    _pcContext.reset();

    // RTT 및 통계 정보 초기화
    _rttMs = 0;
    _cachedCandidate.clear();

    // 통계 계산기 초기화
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

void WebRTCWorker::_processPendingCandidates()
{
    // Dual-path 모드에서는 각 경로별로 후보를 처리하므로 이 함수는 더 이상 사용되지 않음
    qCDebug(WebRTCLinkLog) << "Legacy _processPendingCandidates called - ignored in dual-path mode";
}

void WebRTCWorker::_onPeerStateChanged(rtc::PeerConnection::State state)
{
    QString stateStr = _stateToString(state);
    emit rtcStatusMessageChanged(stateStr);

    if (state == rtc::PeerConnection::State::Connected) {
        qCDebug(WebRTCLinkLog) << "PeerConnection fully connected!";
        // 연결 성공 시 재연결 카운터 리셋
        _onReconnectSuccess();
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
        qCDebug(WebRTCLinkLog) << "[DEBUG] ICE Gathering Complete for dual-path connection";
    }
}

void WebRTCWorker::_updateRtt()
{
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
    if (!_cachedCandidate.isEmpty() && _cachedCandidate != lastCandidate) {
        qCDebug(WebRTCLinkLog) << "[RTT_UPDATE] Candidate changed:"
                              << (lastCandidate.isEmpty() ? "(empty)" : lastCandidate)
                              << "->" << _cachedCandidate;
        lastCandidate = _cachedCandidate;
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
    _pcContext.dataChannelOpened.store(false);

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

    // 통계 초기화
    _rttMs = 0;
    _cachedCandidate.clear();
    _dataChannelSentCalc.reset();
    _dataChannelReceivedCalc.reset();
    _videoReceivedCalc.reset();
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

    // ICE Candidate 정보
    stats.iceCandidate = _cachedCandidate;

    // 송수신 통계
    stats.webRtcSent = _dataChannelSentCalc.getCurrentRate();
    stats.webRtcRecv = _dataChannelReceivedCalc.getCurrentRate();

    // 비디오 통계
    stats.videoRateKBps = _videoReceivedCalc.getCurrentRate();
    stats.videoPacketCount = _videoReceivedCalc.getStats().totalPackets;
    stats.videoBytesReceived = _videoReceivedCalc.getStats().totalBytes;

    return stats;
}

void WebRTCWorker::_updateAllStatistics()
{
    // 통계 업데이트
    _dataChannelSentCalc.updateRate();
    _dataChannelReceivedCalc.updateRate();
    _videoReceivedCalc.updateRate();

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
    // 통계 업데이트
    _dataChannelSentCalc.updateRate();
    _dataChannelReceivedCalc.updateRate();
    _videoReceivedCalc.updateRate();

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
    if (!_pcContext.mavlinkDc || !_pcContext.mavlinkDc->isOpen()) {
        return;
    }

    if (_pendingMessages.isEmpty()) {
        return;
    }

    qCDebug(WebRTCLinkLog) << "[BUFFER] Processing" << _pendingMessages.size() << "pending messages";

    int sentCount = 0;
    while (!_pendingMessages.isEmpty()) {
        // 버퍼 상태 확인
        size_t buffered = _pcContext.mavlinkDc->bufferedAmount();
        if (buffered > BUFFER_WARNING_THRESHOLD) {
            qCDebug(WebRTCLinkLog) << "[BUFFER] Buffer full, pausing. Remaining messages:"
                                   << _pendingMessages.size();
            break;
        }

        QByteArray data = _pendingMessages.takeFirst();
        writeData(data);
        sentCount++;
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
    if (!_pcContext.mavlinkDc || !_pcContext.mavlinkDc->isOpen()) {
        return;
    }

    size_t buffered = _pcContext.mavlinkDc->bufferedAmount();
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
    if (!_pcContext.mavlinkDc || !_pcContext.mavlinkDc->isOpen()) {
        return false;
    }

    // 버퍼가 가득 차지 않았는지 확인
    size_t buffered = _pcContext.mavlinkDc->bufferedAmount();
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

