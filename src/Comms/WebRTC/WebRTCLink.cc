#include "WebRTCLink.h"
#include <QDebug>
#include <QUrl>
#include <QtQml/qqml.h>
#include "QGCLoggingCategory.h"
#include "VideoManager.h"
#include "SignalingServerManager.h"
#include "SettingsManager.h"
#include "CloudSettings.h"

QGC_LOGGING_CATEGORY(WebRTCLinkLog, "qgc.comms.webrtclink")

const QString WebRTCWorker::kDataChannelLabel = "mavlink";

/*===========================================================================*/
// WebRTCConfiguration Implementation
/*===========================================================================*/

WebRTCConfiguration::WebRTCConfiguration(const QString &name, QObject *parent)
    : LinkConfiguration(name, parent)
{
    _roomId = _generateRandomId();
    _peerId = "app_"+_roomId;
    _targetPeerId = "vehicle_"+_roomId;
}

WebRTCConfiguration::WebRTCConfiguration(const WebRTCConfiguration *copy, QObject *parent)
    : LinkConfiguration(copy, parent)
      , _roomId(copy->_roomId)
      , _peerId(copy->_peerId)
      , _targetPeerId(copy->_targetPeerId)
{
}

WebRTCConfiguration::~WebRTCConfiguration() = default;

void WebRTCConfiguration::copyFrom(const LinkConfiguration *source)
{
    LinkConfiguration::copyFrom(source);
    auto* src = qobject_cast<const WebRTCConfiguration*>(source);
    if (src) {
        _roomId = src->_roomId;
        _peerId = src->_peerId;
        _targetPeerId = src->_targetPeerId;
    }
}

void WebRTCConfiguration::loadSettings(QSettings &settings, const QString &root)
{
    settings.beginGroup(root);
    _roomId = settings.value("roomId", "").toString();
    _peerId = settings.value("peerId", _generateRandomId()).toString();
    _targetPeerId = settings.value("targetPeerId", "").toString();
    settings.endGroup();
}

void WebRTCConfiguration::saveSettings(QSettings &settings, const QString &root) const
{
    settings.beginGroup(root);
    settings.setValue("roomId", _roomId);
    settings.setValue("peerId", _peerId);
    settings.setValue("targetPeerId", _targetPeerId);
    settings.endGroup();
}

void WebRTCConfiguration::setRoomId(const QString &id)
{
    if (_roomId != id) {
        _roomId = id;
        emit roomIdChanged();
    }
}


void WebRTCConfiguration::setPeerId(const QString &id)
{
    if (_peerId != id) {
        _peerId = id;
        emit peerIdChanged();
    }
}

void WebRTCConfiguration::setTargetPeerId(const QString &id)
{
    if (_targetPeerId != id) {
        _targetPeerId = id;
        emit targetPeerIdChanged();
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
    qCDebug(WebRTCLinkLog) << "Starting WebRTC worker";
    
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
    
    _setupPeerConnection();
    
    // Store current room and peer information
    _currentRoomId = _config->roomId();
    _currentPeerId = _config->peerId();
    _roomLeftSuccessfully = false;
    
    // SignalingServerManager에 peer 등록 요청
    if (_signalingManager) {
        qCDebug(WebRTCLinkLog) << "Requesting peer registration to SignalingServerManager";
        qCDebug(WebRTCLinkLog) << "Peer ID:" << _config->peerId() << " Room:" << _config->roomId();
        _signalingManager->registerPeer(_config->peerId(), _config->roomId());
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
    qCDebug(WebRTCLinkLog) << "Disconnecting WebRTC link";
    
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
    _waitingForReconnect = false;
    
    // Leave the room if we're currently in one
    if (_signalingManager && !_currentRoomId.isEmpty() && !_currentPeerId.isEmpty()) {
        qCDebug(WebRTCLinkLog) << "Leaving room:" << _currentRoomId << "with peer:" << _currentPeerId;
        _signalingManager->leavePeer(_currentPeerId, _currentRoomId);
        emit rtcStatusMessageChanged("시그널링 서버 룸(Room) 해제 중");
        
        // Give some time for the leave message to be sent before cleanup
        QTimer::singleShot(1000, this, [this]() {
            _cleanupComplete();
            emit disconnected();
        });
    } else {
        // If not in a room, cleanup immediately
        _cleanupComplete();
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
    
    // Connect room management signals
    connect(_signalingManager, &SignalingServerManager::peerLeftSuccessfully,
            this, &WebRTCWorker::_onPeerLeftSuccessfully, Qt::QueuedConnection);
    connect(_signalingManager, &SignalingServerManager::peerLeaveFailed,
            this, &WebRTCWorker::_onPeerLeaveFailed, Qt::QueuedConnection);
}

void WebRTCWorker::_onSignalingConnected()
{
    qCDebug(WebRTCLinkLog) << "Signaling server connected";
    emit rtcStatusMessageChanged("시그널링 서버 연결됨");
}

void WebRTCWorker::_onSignalingDisconnected()
{
    qCDebug(WebRTCLinkLog) << "Signaling server disconnected";
    
    if (_signalingManager && _signalingManager->isWebSocketOnlyConnected()) {
        qCDebug(WebRTCLinkLog) << "WebSocket-only mode: Ignoring disconnection event";
        return;
    }
    
    emit rtcStatusMessageChanged("시그널링 서버 연결 해제됨");
}

void WebRTCWorker::_onSignalingError(const QString& error)
{
    qCWarning(WebRTCLinkLog) << "Signaling error:" << error;
    emit rtcStatusMessageChanged(QString("시그널링 오류: %1").arg(error));
    emit errorOccurred(error);
}

void WebRTCWorker::_onSignalingMessageReceived(const QJsonObject& message)
{
    _handleSignalingMessage(message);
}

void WebRTCWorker::_onRegistrationSuccessful()
{
    qCDebug(WebRTCLinkLog) << "Registration successful signal received";
    emit rtcStatusMessageChanged("시그널링 서버 등록 완료");
}

void WebRTCWorker::_onRegistrationFailed(const QString& reason)
{
    qCWarning(WebRTCLinkLog) << "Registration failed:" << reason;
    emit rtcStatusMessageChanged(QString("시그널링 서버 등록 실패: %1").arg(reason));
    emit errorOccurred(QString("Registration failed: %1").arg(reason));
}

void WebRTCWorker::_onPeerLeftSuccessfully(const QString& peerId, const QString& roomId)
{
    if (peerId != _currentPeerId || roomId != _currentRoomId) {
        return; // Not our peer/room
    }
    
    qCDebug(WebRTCLinkLog) << "Successfully left room:" << roomId;
    _roomLeftSuccessfully = true;
    
    // Clear current room information
    _currentRoomId.clear();
    _currentPeerId.clear();
    
    // Reset connection state
    _dataChannelOpened.store(false);
    _remoteDescriptionSet.store(false);
    _isDisconnecting = false;
    
    // Clear pending candidates
    {
        QMutexLocker locker(&_candidateMutex);
        _pendingCandidates.clear();
    }
    
    qCDebug(WebRTCLinkLog) << "Signaling room left successfully";
    
    emit rtcStatusMessageChanged("시그널링 서버 룸(Room) 해제");
}

void WebRTCWorker::_onPeerLeaveFailed(const QString& peerId, const QString& reason)
{
    if (peerId != _currentPeerId) {
        return; // Not our peer
    }
    
    qCWarning(WebRTCLinkLog) << "Failed to leave room:" << reason;
    emit rtcStatusMessageChanged(QString("시그널링 서버 룸(Room) 해제 실패: %1").arg(reason));
    
    // Still clear the room info and proceed with cleanup
    _currentRoomId.clear();
    _currentPeerId.clear();
    
    // Reset connection state even on failure
    _dataChannelOpened.store(false);
    _remoteDescriptionSet.store(false);
    _isDisconnecting = false;
    
    // Clear pending candidates
    {
        QMutexLocker locker(&_candidateMutex);
        _pendingCandidates.clear();
    }
}

void WebRTCWorker::reconnectToRoom()
{
    if (_isShuttingDown.load()) {
        qCDebug(WebRTCLinkLog) << "Shutting down, not reconnecting";
        return;
    }
    
    qCDebug(WebRTCLinkLog) << "Attempting to reconnect to room";
    
    // SignalingServerManager가 연결 상태를 자동으로 관리하므로 여기서는 확인만
    qCDebug(WebRTCLinkLog) << "Requesting reconnection, SignalingServerManager handles connection state";
    
    // Reset state properly
    _waitingForReconnect = false;
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
    
    // Store room and peer information again
    _currentRoomId = _config->roomId();
    _currentPeerId = _config->peerId();
    _roomLeftSuccessfully = false;
    
    if (_signalingManager) {
        qCDebug(WebRTCLinkLog) << "Reconnection peer ID:" << _config->peerId() << " room:" << _config->roomId();
        _signalingManager->registerPeer(_config->peerId(), _config->roomId());
        emit rtcStatusMessageChanged("재연결 시도 중");
    } else {
        qCWarning(WebRTCLinkLog) << "Signaling manager not available for reconnection";
        emit rtcStatusMessageChanged("시그널링 매니저 사용 불가");
    }
}

void WebRTCWorker::_setupPeerConnection()
{
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
            qCDebug(WebRTCLinkLog) << "[DATACHANNEL] DataChannel received - Label:"
                                      << QString::fromStdString(label);

            if (label == "mavlink") {
                qCDebug(WebRTCLinkLog) << "[DATACHANNEL] Setting up mavlink DataChannel";
                _mavlinkDataChannel = dc;
                _setupMavlinkDataChannel(dc);
            } else if (label == "custom") {
                qCDebug(WebRTCLinkLog) << "[DATACHANNEL] Setting up custom DataChannel";
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

        qCDebug(WebRTCLinkLog) << "Peer connection created successfully";

    } catch (const std::exception& e) {
        qCDebug(WebRTCLinkLog) << "Failed to create peer connection:" << e.what();
        emit errorOccurred(QString("Failed to create peer connection: %1").arg(e.what()));
    }
}

void WebRTCWorker::handleLocalDescription(const QString& descType, const QString& sdpContent) {
    if (!isOperational()) return;

    qCDebug(WebRTCLinkLog) << "[SDP] Local description created, type:" << descType;

    QJsonObject message;
    message["id"] = _config->peerId();
    message["to"] = _config->targetPeerId();
    message["type"] = descType;
    message["sdp"] = sdpContent;

    _sendSignalingMessage(message);
}

void WebRTCWorker::handleLocalCandidate(const QString& candidateStr, const QString& mid) {
    if (!isOperational()) return;

    qCDebug(WebRTCLinkLog) << "[ICE] Local candidate generated:" << candidateStr.left(50) << "...";

    QJsonObject message;
    message["id"] = _config->peerId();
    message["to"] = _config->targetPeerId();
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
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] *** DataChannel OPENED! ***";
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
        qCDebug(WebRTCLinkLog) << "[DATACHANNEL] *** CustomDataChannel OPENED! ***";
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

                    
                    emit rtcModuleSystemInfoUpdated(
                        jsonObj["cpu_usage"].toDouble(),
                        jsonObj["cpu_temperature"].toDouble(),
                        jsonObj["memory_usage_percent"].toDouble(),
                        jsonObj["network_rx_mbps"].toDouble(),
                        jsonObj["network_tx_mbps"].toDouble(),
                        jsonObj["network_interface"].toString()
                    );
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
        emit rtcStatusMessageChanged("데이터 채널 연결 완료");

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
        qCDebug(WebRTCLinkLog) << "Video track received";
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

    try {
        if (type == "offer") {
            qCDebug(WebRTCLinkLog) << "[SIGNALING] Processing OFFER as answerer";

            try {
                QString sdp = message["sdp"].toString();
                rtc::Description offer(sdp.toStdString(), "offer");

                if (!_peerConnection) {
                    qCWarning(WebRTCLinkLog) << "[OFFER] No peer connection, setting up new one";
                    _setupPeerConnection();
                }

                _peerConnection->setRemoteDescription(offer);
                _remoteDescriptionSet.store(true);
                _processPendingCandidates();

                qCDebug(WebRTCLinkLog) << "[OFFER] Processed successfully";

            } catch (const std::exception& e) {
                qCDebug(WebRTCLinkLog) << "[OFFER] Processing failed:" << e.what();

                // 실패 시 재시도 로직
                QTimer::singleShot(1000, this, [this, message]() {
                    qCDebug(WebRTCLinkLog) << "[OFFER] Retrying after failure";
                    _setupPeerConnection();
                });
            }

        } else if (type == "answer") {
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

        } else if (type == "candidate") {
            _handleCandidate(message);

        } else if (type == "peerDisconnected") {
            QString disconnectedId = message["id"].toString();
            if (disconnectedId == _config->targetPeerId()) {
                qCWarning(WebRTCLinkLog) << "Peer disconnected by signaling server:" << disconnectedId;

                _handlePeerDisconnection();
            }

        } else if (type == "registered") {
            qCDebug(WebRTCLinkLog) << "Successfully registered with signaling server";
            emit rtcStatusMessageChanged("기체 연결 대기중");
        }

    } catch (const std::exception& e) {
        emit errorOccurred(QString("Error handling signaling message: %1").arg(e.what()));
    }
}

void WebRTCWorker::_handlePeerDisconnection()
{
    qCDebug(WebRTCLinkLog) << "[DISCONNECT] Handling peer disconnection";

    _dataChannelOpened.store(false);
    _isDisconnecting = false;

    // WebRTC 연결이 끊어지면 방에서 나가기
            if (_signalingManager && !_currentRoomId.isEmpty() && !_currentPeerId.isEmpty()) {
            qCDebug(WebRTCLinkLog) << "Leaving room due to peer disconnection:" << _currentRoomId;
            _signalingManager->leavePeer(_currentPeerId, _currentRoomId);
        emit rtcStatusMessageChanged("피어 연결 해제 - 방에서 나가는 중...");
    }

            _cleanupForReconnection();

        emit rttUpdated(-1);
        emit disconnected();
        emit rtcStatusMessageChanged("기체 연결 해제됨, 수동 재연결 필요");

        qCDebug(WebRTCLinkLog) << "[DISCONNECT] Manual reconnection required";
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

void WebRTCWorker::_handleCandidate(const QJsonObject& message)
{
    if (!_peerConnection) {
        qCWarning(WebRTCLinkLog) << "No peer connection available for candidate";
        return;
    }

    QString candidateStr = message["candidate"].toString();
    QString mid = message["sdpMid"].toString();

    if (candidateStr.isEmpty()) {
        qCWarning(WebRTCLinkLog) << "Empty candidate string received";
        return;
    }

    try {
        rtc::Candidate candidate(candidateStr.toStdString(), mid.toStdString());

        if (_remoteDescriptionSet.load(std::memory_order_acquire)) {
            qCDebug(WebRTCLinkLog) << "Adding remote candidate immediately";
            _peerConnection->addRemoteCandidate(candidate);

        } else {
            QMutexLocker locker(&_candidateMutex);
            _pendingCandidates.push_back(candidate);
            qCDebug(WebRTCLinkLog) << "RemoteDescription not set → Candidate queued";
        }
    } catch (const std::exception& e) {
        qCWarning(WebRTCLinkLog) << "Failed to process candidate:" << e.what();
    }
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
    qCDebug(WebRTCLinkLog) << "PeerConnection State Changed:" << stateStr;

    emit rtcStatusMessageChanged(stateStr);

    if (state == rtc::PeerConnection::State::Connected) {
        qCDebug(WebRTCLinkLog) << "PeerConnection fully connected!";
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

        QTimer::singleShot(1000, this, [this]() {
            _cleanup();
            _setupPeerConnection();
            
            // WebRTC 재연결 시 시그널링 서버에 다시 등록
            if (_signalingManager && !_currentRoomId.isEmpty() && !_currentPeerId.isEmpty()) {
                qCDebug(WebRTCLinkLog) << "Re-registering with signaling server after WebRTC reconnection";
                _signalingManager->registerPeer(_currentPeerId, _currentRoomId);
            }
        });
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
        emit rttUpdated(rttMs);
    }
}

QString WebRTCWorker::_stateToString(rtc::PeerConnection::State state) const
{
    switch (state) {
        case rtc::PeerConnection::State::New: return "Peer 생성";
        case rtc::PeerConnection::State::Connecting: return "피어 연결중";
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
        case rtc::PeerConnection::GatheringState::New: return "새로운 ICE 수집중";
        case rtc::PeerConnection::GatheringState::InProgress: return "ICE 수집 처리중";
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
    // 완전한 종료 시에만 _isShuttingDown 설정
    _isShuttingDown.store(true);
    _cleanup();
    
    // Clear room information
    _currentRoomId.clear();
    _currentPeerId.clear();
    _roomLeftSuccessfully = false;
    
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

    // qCDebug(WebRTCLinkLog) << "[DC]" << "SENT:" << _dataChannelSentCalc.getCurrentRate() << "KB/s"
    //                         << " RECV:" << _dataChannelReceivedCalc.getCurrentRate() << "KB/s"
    //                         << "[Video]" << "RECV:" << _videoReceivedCalc.getCurrentRate() << "KB/s";

    emit dataChannelStatsUpdated(
        _dataChannelSentCalc.getCurrentRate(),
        _dataChannelReceivedCalc.getCurrentRate()
        );

    emit videoStatsUpdated(
        _videoReceivedCalc.getCurrentRate(),
        _videoReceivedCalc.getStats().totalPackets,
        _videoReceivedCalc.getStats().totalBytes
        );

    emit videoRateChanged(
        _videoReceivedCalc.getCurrentRate()
        );
}


//------------------------------------------------------
// WebRTCLink (구현)
//------------------------------------------------------
WebRTCLink::WebRTCLink(SharedLinkConfigurationPtr &config, QObject *parent)
    : LinkInterface(config, parent)
{
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
    connect(_worker, &WebRTCWorker::rttUpdated, this, &WebRTCLink::_onRttUpdated, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::dataChannelStatsUpdated, this, &WebRTCLink::_onDataChannelStatsChanged, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::rtcStatusMessageChanged, this, &WebRTCLink::_onRtcStatusMessageChanged, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::videoRateChanged, this, &WebRTCLink::_onVideoRateChanged, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::rtcModuleSystemInfoUpdated, this, &WebRTCLink::_onRtcModuleSystemInfoUpdated, Qt::QueuedConnection);

    _workerThread->start();
}

WebRTCLink::~WebRTCLink()
{
    if (_worker) {
        QMetaObject::invokeMethod(_worker, "disconnectLink", Qt::BlockingQueuedConnection);
    }
    _workerThread->quit();
    _workerThread->wait();
}

bool WebRTCLink::isConnected() const
{
    return _worker && _worker->isDataChannelOpen();
}

void WebRTCLink::connectLink()
{
    QMetaObject::invokeMethod(this, "_connect", Qt::QueuedConnection);
}

void WebRTCLink::reconnectLink()
{
    if (_worker) {
        QMetaObject::invokeMethod(_worker, "reconnectToRoom", Qt::QueuedConnection);
    }
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
    _onRtcStatusMessageChanged("RTC 연결 해제됨");
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

void WebRTCLink::_onRttUpdated(int rtt)
{
    if (_rttMs != rtt) {
        _rttMs = rtt;
        emit rttMsChanged();
    }
}

void WebRTCLink::_onRtcStatusMessageChanged(const QString& message)
{
    if (_rtcStatusMessage != message) {
        _rtcStatusMessage = message;
        emit rtcStatusMessageChanged();
    }
}

void WebRTCLink::_onDataChannelStatsChanged(double sendRate, double receiveRate)
{
    if (_webRtcSent != sendRate) {
        _webRtcSent = sendRate;
        emit webRtcSentChanged();
    }
    if (_webRtcRecv != receiveRate) {
        _webRtcRecv = receiveRate;
        emit webRtcRecvChanged();
    }
}

bool WebRTCLink::isVideoStreamActive() const
{
    return _worker ? _worker->isVideoStreamActive() : false;
}

void WebRTCLink::_onVideoRateChanged(double KBps)
{
    if (_videoRateKBps != KBps) {
        _videoRateKBps = KBps;
        emit videoRateKBpsChanged();
    }
}

void WebRTCLink::_onRtcModuleSystemInfoUpdated(double cpuUsage, double cpuTemperature, double memoryUsage,
                                              double networkRx, double networkTx, const QString& networkInterface)
{    
    bool changed = false;
    
    if (_rtcModuleCpuUsage != cpuUsage) {
        _rtcModuleCpuUsage = cpuUsage;
        changed = true;
    }
    if (_rtcModuleCpuTemperature != cpuTemperature) {
        _rtcModuleCpuTemperature = cpuTemperature;
        changed = true;
    }
    if (_rtcModuleMemoryUsage != memoryUsage) {
        _rtcModuleMemoryUsage = memoryUsage;
        changed = true;
    }
    if (_rtcModuleNetworkRx != networkRx) {
        _rtcModuleNetworkRx = networkRx;
        changed = true;
    }
    if (_rtcModuleNetworkTx != networkTx) {
        _rtcModuleNetworkTx = networkTx;
        changed = true;
    }
    if (_rtcModuleNetworkInterface != networkInterface) {
        _rtcModuleNetworkInterface = networkInterface;
        changed = true;
    }
    
    if (changed) {
        emit rtcModuleSystemInfoChanged(cpuUsage, cpuTemperature, memoryUsage, networkRx, networkTx, networkInterface);
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
