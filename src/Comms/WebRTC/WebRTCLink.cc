#include "WebRTCLink.h"
#include <QDebug>
#include <QUrl>
#include <QtQml/qqml.h>

Q_LOGGING_CATEGORY(WebRTCLinkLog, "WebRTCLink")

const QString WebRTCWorker::kDataChannelLabel = "mavlink";

/*===========================================================================*/
// WebRTCConfiguration Implementation
/*===========================================================================*/

WebRTCConfiguration::WebRTCConfiguration(const QString &name, QObject *parent)
    : LinkConfiguration(name, parent)
{
    _peerId = _generateRandomId();
    _targetPeerId = "peerDrone"; // Default target
}

WebRTCConfiguration::WebRTCConfiguration(const WebRTCConfiguration *copy, QObject *parent)
    : LinkConfiguration(copy, parent)
      , _peerId(copy->_peerId)
      , _targetPeerId(copy->_targetPeerId)
      , _signalingServer(copy->_signalingServer)
      , _stunServer(copy->_stunServer)
      , _turnServer(copy->_turnServer)
      , _turnUsername(copy->_turnUsername)
      , _turnPassword(copy->_turnPassword)
      , _udpMuxEnabled(copy->_udpMuxEnabled)
{
}

WebRTCConfiguration::~WebRTCConfiguration() = default;

void WebRTCConfiguration::copyFrom(const LinkConfiguration *source)
{
    LinkConfiguration::copyFrom(source);
    auto* src = qobject_cast<const WebRTCConfiguration*>(source);
    if (src) {
        _peerId = src->_peerId;
        _targetPeerId = src->_targetPeerId;
        _signalingServer = src->_signalingServer;
        _stunServer = src->_stunServer;
        _turnServer = src->_turnServer;
        _turnUsername = src->_turnUsername;
        _turnPassword = src->_turnPassword;
        _udpMuxEnabled = src->_udpMuxEnabled;
    }
}

void WebRTCConfiguration::loadSettings(QSettings &settings, const QString &root)
{
    settings.beginGroup(root);
    _peerId = settings.value("peerId", _generateRandomId()).toString();
    _targetPeerId = settings.value("targetPeerId", "").toString();
    _signalingServer = settings.value("signalingServer", "").toString();
    _stunServer = settings.value("stunServer", "stun.l.google.com:19302").toString();
    _turnServer = settings.value("turnServer", "").toString();
    _turnUsername = settings.value("turnUsername", "").toString();
    _turnPassword = settings.value("turnPassword", "").toString();
    _udpMuxEnabled = settings.value("udpMuxEnabled", false).toBool();
    settings.endGroup();
}

void WebRTCConfiguration::saveSettings(QSettings &settings, const QString &root) const
{
    settings.beginGroup(root);
    settings.setValue("peerId", _peerId);
    settings.setValue("targetPeerId", _targetPeerId);
    settings.setValue("signalingServer", _signalingServer);
    settings.setValue("stunServer", _stunServer);
    settings.setValue("turnServer", _turnServer);
    settings.setValue("turnUsername", _turnUsername);
    settings.setValue("turnPassword", _turnPassword);
    settings.setValue("udpMuxEnabled", _udpMuxEnabled);
    settings.endGroup();
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

void WebRTCConfiguration::setSignalingServer(const QString &url)
{
    if (_signalingServer != url) {
        _signalingServer = url;
        emit signalingServerChanged();
    }
}

void WebRTCConfiguration::setStunServer(const QString &url)
{
    if (_stunServer != url) {
        _stunServer = url;
        emit stunServerChanged();
    }
}

void WebRTCConfiguration::setTurnServer(const QString &url)
{
    if (_turnServer != url) {
        _turnServer = url;
        emit turnServerChanged();
    }
}

void WebRTCConfiguration::setTurnUsername(const QString &username)
{
    if (_turnUsername != username) {
        _turnUsername = username;
        emit turnUsernameChanged();
    }
}

void WebRTCConfiguration::setTurnPassword(const QString &password)
{
    if (_turnPassword != password) {
        _turnPassword = password;
        emit turnPasswordChanged();
    }
}

void WebRTCConfiguration::setUdpMuxEnabled(bool enabled)
{
    if (_udpMuxEnabled != enabled) {
        _udpMuxEnabled = enabled;
        emit udpMuxEnabledChanged();
    }
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
// WebRTCVideoBridge
/*===========================================================================*/


WebRTCVideoBridge::WebRTCVideoBridge(QObject* parent)
    : QObject(parent)
      , _udpSocket(new QUdpSocket(this))
{
}

WebRTCVideoBridge::~WebRTCVideoBridge()
{
    stopBridge();
}

bool WebRTCVideoBridge::startBridge(quint16 localPort)
{
    if (_isRunning) {
        return true;
    }

    // UDP 소켓 바인딩
    if (!_udpSocket->bind(QHostAddress::LocalHost, localPort, QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint)) {
        emit errorOccurred(QString("Failed to bind UDP socket: %1").arg(_udpSocket->errorString()));
        return false;
    }

    _localPort = _udpSocket->localPort();
    _isRunning = true;

    qDebug() << "WebRTC video bridge started on port:" << _localPort;
    emit bridgeStarted(_localPort);

    return true;
}

void WebRTCVideoBridge::stopBridge()
{
    if (!_isRunning) {
        return;
    }

    _udpSocket->close();
    _isRunning = false;
    _localPort = 0;

    qDebug() << "WebRTC video bridge stopped";
    emit bridgeStopped();
}

void WebRTCVideoBridge::forwardRTPData(const QByteArray& rtpData)
{
    if (!_isRunning || rtpData.isEmpty()) {
        return;
    }

    // 로컬호스트로 RTP 데이터 전송
    // qDebug() << "_udpSocket->state()" << _udpSocket->state();
    qint64 sent = _udpSocket->writeDatagram(rtpData,
                                            QHostAddress::LocalHost,
                                            _localPort);

    if (sent != rtpData.size()) {
        qWarning() << "Failed to send complete RTP packet:" << sent << "of" << rtpData.size();
    } else {
        _totalPackets++;
        _totalBytes += sent;
    }
}

QString WebRTCVideoBridge::getGStreamerURI() const
{
    if (!_isRunning) {
        return QString();
    }

    // GStreamer가 이해할 수 있는 UDP URI 반환
    return QString("udp://127.0.0.1:%1").arg(_localPort);
}




/*===========================================================================*/
// WebRTCWorker Implementation
/*===========================================================================*/

WebRTCWorker::WebRTCWorker(const WebRTCConfiguration *config, QObject *parent)
    : QObject(parent)
      , _config(config)
      , _videoBridge(nullptr)
      , _videoStreamActive(false)
{
    initializeLogger();
    _setupWebSocket();

    qCDebug(WebRTCLinkLog) << "WebRTCWorker created for peer:" << _config->peerId();
}

WebRTCWorker::~WebRTCWorker()
{
    _cleanup();
}

void WebRTCWorker::initializeLogger()
{
    //rtc::InitLogger(rtc::LogLevel::Debug);
}

void WebRTCWorker::start()
{
    qCDebug(WebRTCLinkLog) << "Starting WebRTC worker";
    _setupPeerConnection();
    _connectToSignalingServer();
}

void WebRTCWorker::writeData(const QByteArray &data)
{
    if (!_dataChannel || !_dataChannel->isOpen()) {
        qCWarning(WebRTCLinkLog) << "Data channel not available for sending data";
        return;
    }

    try {
        rtc::binary binaryData(reinterpret_cast<const std::byte*>(data.constData()),
                               reinterpret_cast<const std::byte*>(data.constData()) + data.size());
        _dataChannel->send(binaryData);
        emit bytesSent(data);
        //qCDebug(WebRTCLinkLog) << "Data sent, size:" << data.size();
    } catch (const std::exception& e) {
        qCWarning(WebRTCLinkLog) << "Failed to send data:" << e.what();
        emit errorOccurred(QString("Failed to send data: %1").arg(e.what()));
    }
}

void WebRTCWorker::disconnectLink()
{
    qCDebug(WebRTCLinkLog) << "Disconnecting WebRTC link";
    _isDisconnecting = true;
    _cleanup();
    _cleanupVideoBridge();
    emit disconnected();
}

void WebRTCWorker::createOffer()
{
    if (!_peerConnection) {
        qCWarning(WebRTCLinkLog) << "No peer connection available to create offer";
        return;
    }

    qCDebug(WebRTCLinkLog) << "Creating offer for target peer:" << _config->targetPeerId();
    _isOfferer = true;

    // Create data channel as offerer
    auto dc = _peerConnection->createDataChannel(kDataChannelLabel.toStdString());
    _dataChannel = std::shared_ptr<rtc::DataChannel>(dc);
    _setupDataChannel(_dataChannel);
}

bool WebRTCWorker::isDataChannelOpen() const
{
    return _dataChannel && _dataChannel->isOpen();
}

void WebRTCWorker::_setupWebSocket()
{
    _webSocket = new QWebSocket(QString(), QWebSocketProtocol::VersionLatest, this);

    connect(_webSocket, &QWebSocket::connected, this, &WebRTCWorker::_onWebSocketConnected);
    connect(_webSocket, &QWebSocket::disconnected, this, &WebRTCWorker::_onWebSocketDisconnected);
    connect(_webSocket, &QWebSocket::errorOccurred, this, &WebRTCWorker::_onWebSocketError);
    connect(_webSocket, &QWebSocket::textMessageReceived,
            this, &WebRTCWorker::_onWebSocketMessageReceived);
}

void WebRTCWorker::_connectToSignalingServer()
{
    if (_signalingConnected) {
        qCWarning(WebRTCLinkLog) << "Already connected to signaling server";
        return;
    }

    QString url = QString(_config->signalingServer());

    qCDebug(WebRTCLinkLog) << "Connecting to signaling server:" << url;
    _webSocket->open(QUrl(url));
    emit rtcStatusMessageChanged("Connect Socket");
}

void WebRTCWorker::_setupPeerConnection()
{
    // Configure ICE servers
    _rtcConfig.iceServers.clear();

    // Add STUN server
    if (!_config->stunServer().isEmpty()) {
        _rtcConfig.iceServers.emplace_back(_config->stunServer().toStdString());
        //qCDebug(WebRTCLinkLog) << "STUN server configured:" << _config->stunServer().toStdString();
    }

    // Add TURN server
    if (!_config->turnServer().isEmpty()) {
        rtc::IceServer turnServer(_config->turnServer().toStdString());
        turnServer.username = _config->turnUsername().toStdString();
        turnServer.password = _config->turnPassword().toStdString();
        _rtcConfig.iceServers.emplace_back(turnServer);
        //qCDebug(WebRTCLinkLog) << "TURN server configured:" << _config->turnServer().toStdString();
    }

    // Configure UDP mux
    _rtcConfig.enableIceUdpMux = _config->udpMuxEnabled();

    try {
        // _rtcConfig.disableAutoNegotiation = true;
        _peerConnection = std::make_shared<rtc::PeerConnection>(_rtcConfig);

        // Set up callbacks
        _peerConnection->onStateChange([this](rtc::PeerConnection::State state) {
            QMetaObject::invokeMethod(this, "_onPeerStateChanged",
                                      Qt::QueuedConnection, Q_ARG(rtc::PeerConnection::State, state));
        });

        _peerConnection->onGatheringStateChange([this](rtc::PeerConnection::GatheringState state) {
            QMetaObject::invokeMethod(this, "_onGatheringStateChanged",
                                      Qt::QueuedConnection, Q_ARG(rtc::PeerConnection::GatheringState, state));
        });

        _peerConnection->onLocalDescription([this](rtc::Description description) {
            QString descType = QString::fromStdString(description.typeString());
            QString sdpContent = QString::fromStdString(description);

            QJsonObject message;
            message["id"] = _config->peerId();
            message["to"] = _config->targetPeerId();
            message["type"] = descType;
            message["sdp"] = sdpContent;
            _sendSignalingMessage(message);
        });

        _peerConnection->onLocalCandidate([this](rtc::Candidate candidate) {
            QJsonObject message;
            message["id"] = _config->peerId();
            message["to"] = _config->targetPeerId();
            message["type"] = "candidate";
            message["candidate"] = QString::fromStdString(candidate);
            message["sdpMid"] = QString::fromStdString(candidate.mid());
            // message["sdpMLineIndex"] = candidate.sdpMLineIndex();
            _sendSignalingMessage(message);
        });

        _peerConnection->onDataChannel([this](std::shared_ptr<rtc::DataChannel> dc) {
            qCDebug(WebRTCLinkLog) << "Data channel received with label:"
                                   << QString::fromStdString(dc->label());
            _dataChannel = dc;
            _setupDataChannel(_dataChannel);
        });

        _peerConnection->onTrack([this](std::shared_ptr<rtc::Track> track) {
            auto desc = track->description();

            _videoTrack = track;

            if (desc.type() == "video") {
                qCDebug(WebRTCLinkLog) << "Video track received";
                emit videoTrackReceived();

                if( !_videoBridge) {
                    _setupVideoBridge();
                }

                track->onMessage([this](rtc::message_variant message) {
                    if(std::holds_alternative<rtc::binary>(message)) {
                        const auto& data = std::get<rtc::binary>(message);

                        _handleVideoTrackData(data);
                    }
                });

                auto session = std::make_shared<rtc::RtcpReceivingSession>();
                track->setMediaHandler(session);

            } else if (desc.type() == "audio") {
                qCDebug(WebRTCLinkLog) << "Audio track received";
            } else {
                qCDebug(WebRTCLinkLog) << "Other track type: " << desc.type();
            }
        });

        qCDebug(WebRTCLinkLog) << "Peer connection created successfully";

    } catch (const std::exception& e) {
        qCCritical(WebRTCLinkLog) << "Failed to create peer connection:" << e.what();
        emit errorOccurred(QString("Failed to create peer connection: %1").arg(e.what()));
    }
}

void WebRTCWorker::_setupDataChannel(std::shared_ptr<rtc::DataChannel> dc)
{
    if (!dc) return;

    dc->onOpen([this]() {
        QMetaObject::invokeMethod(this, "_onDataChannelOpen", Qt::QueuedConnection);
    });

    dc->onClosed([this]() {
        QMetaObject::invokeMethod(this, "_onDataChannelClosed", Qt::QueuedConnection);
    });

    dc->onMessage([this, dc](auto data) {
        if (std::holds_alternative<rtc::binary>(data)) {
            const auto& binaryData = std::get<rtc::binary>(data);
            QByteArray byteArray(reinterpret_cast<const char*>(binaryData.data()), binaryData.size());
            emit bytesReceived(byteArray);
        }
        else if (std::holds_alternative<std::string>(data)) {
            const std::string& text = std::get<std::string>(data);
            QJsonDocument doc = QJsonDocument::fromJson(QString::fromStdString(text).toUtf8());
            if (doc.isObject()) {
                QJsonObject obj = doc.object();
                if (obj["type"] == "ping") {
                    QJsonObject pong;
                    pong["type"] = "pong";
                    pong["timestamp"] = obj["timestamp"];
                    QJsonDocument docPong(pong);
                    dc->send(docPong.toJson(QJsonDocument::Compact).toStdString());
                }
                else if (obj["type"] == "pong") {
                    qint64 now = QDateTime::currentMSecsSinceEpoch();
                    qint64 rtt = now - obj["timestamp"].toVariant().toLongLong();
                    qCDebug(WebRTCLinkLog) << "[DataChannel] Measured RTT: " << rtt << "ms";
                    //emit rttUpdated(rtt);
                }
            }
        }
    });
}

void WebRTCWorker::_onWebSocketConnected()
{
    _signalingConnected = true;
    qCDebug(WebRTCLinkLog) << "WebSocket connected to signaling server";

    QJsonObject message;
    message["type"] = "register";
    message["id"] = _config->peerId();
    _webSocket->sendTextMessage(QJsonDocument(message).toJson(QJsonDocument::Compact));
}

void WebRTCWorker::_onWebSocketDisconnected()
{
    _signalingConnected = false;
    qCDebug(WebRTCLinkLog) << "WebSocket disconnected from signaling server";

    if (!_isDisconnecting) {
        // Auto-reconnect after delay
        QTimer::singleShot(kReconnectInterval, this, &WebRTCWorker::_connectToSignalingServer);
    }
}

void WebRTCWorker::_onWebSocketError(QAbstractSocket::SocketError error)
{
    QString errorString = _webSocket->errorString();
    qCWarning(WebRTCLinkLog) << "WebSocket error:" << errorString;
    emit errorOccurred(errorString);
}

void WebRTCWorker::_onWebSocketMessageReceived(const QString& message)
{
    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(message.toUtf8(), &parseError);

    //qCDebug(WebRTCLinkLog) << "Received signaling message: " << message;

    QJsonObject obj = doc.object();

    if (obj.contains("type")) {
        QString type = obj["type"].toString();
        qCDebug(WebRTCLinkLog) << "Received signaling message type:" << type;
    } else {
        qCWarning(WebRTCLinkLog) << "Received signaling message missing 'type' field";
    }

    if (parseError.error != QJsonParseError::NoError) {
        qCWarning(WebRTCLinkLog) << "Failed to parse signaling message:" << parseError.errorString();
        return;
    }

    _handleSignalingMessage(doc.object());
}

void WebRTCWorker::_handleSignalingMessage(const QJsonObject& message)
{
    if (!message.contains("type")) {
        qCWarning(WebRTCLinkLog) << "Invalid signaling message format: missing type";
        return;
    }

    QString remoteId = message["to"].toString();
    QString type = message["type"].toString();

    // Only handle messages from our target peer
    if (remoteId != _config->peerId()) {
        return;
    }

    try {
        if (type == "offer") {
            QString sdp = message["sdp"].toString();
            rtc::Description offer(sdp.toStdString(), "offer");
            _peerConnection->setRemoteDescription(offer);

            _remoteDescriptionSet = true;
            _processPendingCandidates();

        // } else if (type == "answer") {
        //     QString sdp = message["sdp"].toString();
        //     rtc::Description answer(sdp.toStdString(), "answer");
        //     _peerConnection->setRemoteDescription(answer);
        //     _remoteDescriptionSet = true;
        //     _processPendingCandidates();

        } else if (type == "candidate") {
            QString candidateStr = message["candidate"].toString();
            QString mid = message["sdpMid"].toString();
            rtc::Candidate candidate(candidateStr.toStdString(), mid.toStdString());

            if (_remoteDescriptionSet) {
                _peerConnection->addRemoteCandidate(candidate);
            } else {
                _pendingCandidates.push_back(candidate);
            }
        } else if (type == "idDisconnected") {
            QString disconnectedId = message["id"].toString();
            if (disconnectedId == _config->targetPeerId()) {
                qCWarning(WebRTCLinkLog) << "Peer disconnected by signaling server:" << disconnectedId;

                if (_dataChannel) {
                    _dataChannel->close();
                    _dataChannel = nullptr;
                }

                emit rttUpdated(-1);
                emit disconnected(); // -> WebRTCLink::_onDisconnected() 연결

                QTimer::singleShot(3000, this, [this]() {
                    qCDebug(WebRTCLinkLog) << "Cleaning up after remote disconnect";
                    _cleanup();
                    _setupPeerConnection();
                    createOffer();  // 재연결 시도
                });
            }
        }
    } catch (const std::exception& e) {
        //qCWarning(WebRTCLinkLog) << "Error handling signaling message:" << e.what();
        emit errorOccurred(QString("Error handling signaling message: %1").arg(e.what()));
    }
}

void WebRTCWorker::_sendSignalingMessage(const QJsonObject& message)
{
    if (!_signalingConnected) {
        qCWarning(WebRTCLinkLog) << "Cannot send signaling message: not connected";
        return;
    }

    QJsonDocument doc(message);
    _webSocket->sendTextMessage(doc.toJson(QJsonDocument::Compact));
}

void WebRTCWorker::_processPendingCandidates()
{
    for (const auto& candidate : _pendingCandidates) {
        try {
            _peerConnection->addRemoteCandidate(candidate);
        } catch (const std::exception& e) {
            qCWarning(WebRTCLinkLog) << "Failed to add pending candidate:" << e.what();
        }
    }
    _pendingCandidates.clear();
}

void WebRTCWorker::_onDataChannelOpen()
{
    qCDebug(WebRTCLinkLog) << "Data channel opened";
    emit connected();
    emit rtcStatusMessageChanged("Data Channel Opened");

    _ensureBridgeReady();

    // 별도 만든 rtt 측정 시작
    _startPingTimer();

    // 1초마다 라이브 스트림 통계 로깅
    if(!_rttTimer) {
        _rttTimer = new QTimer(this);
        connect(_rttTimer, &QTimer::timeout, this, &WebRTCWorker::_updateRtt);
        _rttTimer->start(1000); // 1초 주기 측정
    }
}

void WebRTCWorker::_onDataChannelClosed()
{
    qCDebug(WebRTCLinkLog) << "Data channel closed";
    if (_pingTimer) {
        _pingTimer->stop();
    }
    if (!_isDisconnecting) {
        emit rttUpdated(-1);
        // emit disconnected();
        // QTimer::singleShot(1000, this, [this]() {
        //     qCDebug(WebRTCLinkLog) << "Recreating PeerConnection and DataChannel";
        //     _cleanup();           // 기존 리소스 정리
        //     _setupPeerConnection(); // PeerConnection 재생성
        //     createOffer();        // Offerer 모드로 재협상 트리거
        // });
    }
}

void WebRTCWorker::_onPeerStateChanged(rtc::PeerConnection::State state)
{
    qCDebug(WebRTCLinkLog) << "Peer state changed:" << _stateToString(state);
    emit rtcStatusMessageChanged(_stateToString(state));
    if ((state == rtc::PeerConnection::State::Failed ||
         state == rtc::PeerConnection::State::Disconnected)
        && !_isDisconnecting) {
        qCDebug(WebRTCLinkLog) << "PeerConnection failed/disconnected – scheduling reconnect";
        QTimer::singleShot(2000, this, [this]() {
            _cleanup();
            _setupPeerConnection();
            createOffer();
        });
    }
}

void WebRTCWorker::_onGatheringStateChanged(rtc::PeerConnection::GatheringState state)
{
    emit rtcStatusMessageChanged(_gatheringStateToString(state));
    qCDebug(WebRTCLinkLog) << "ICE gathering state changed:" << _gatheringStateToString(state);
}

void WebRTCWorker::_updateRtt()
{
    if (!_peerConnection) return;

    auto rttOpt = _peerConnection->rtt();
    if (rttOpt.has_value()) {
        int rttMs = rttOpt.value().count();
        emit rttUpdated(rttMs);
        // qCDebug(WebRTCLinkLog) << "STATS RTT:" << rttMs << "ms"
        //                        << " Sent:" << _peerConnection->bytesSent()
        //                        << " Recv:" << _peerConnection->bytesReceived();
    } else {
        // qCDebug(WebRTCLinkLog) << "STATS RTT: n/a"
        //                        << " Sent:" << _peerConnection->bytesSent()
        //                        << " Recv:" << _peerConnection->bytesReceived();
    }
}

QString WebRTCWorker::_stateToString(rtc::PeerConnection::State state) const
{
    switch (state) {
        case rtc::PeerConnection::State::New: return "New Peer";
        case rtc::PeerConnection::State::Connecting: return "Peer Connecting";
        case rtc::PeerConnection::State::Connected: return "Peer Connected";
        case rtc::PeerConnection::State::Disconnected: return "Peer Disconnected";
        case rtc::PeerConnection::State::Failed: return "Peer Failed";
        case rtc::PeerConnection::State::Closed: return "Peer Closed";
    }
    return "Unknown";
}

QString WebRTCWorker::_gatheringStateToString(rtc::PeerConnection::GatheringState state) const
{
    switch (state) {
        case rtc::PeerConnection::GatheringState::New: return "New ICE Gathering";
        case rtc::PeerConnection::GatheringState::InProgress: return "ICE Gathering InProgress";
        case rtc::PeerConnection::GatheringState::Complete: return "ICE Gathering Complete";
    }
    return "Unknown";
}

void WebRTCWorker::_cleanup()
{
    qCDebug(WebRTCLinkLog) << "Cleaning up WebRTC resources";
    _isDisconnecting = true;
    _bridgeState = BRIDGE_NOT_READY;
    _videoManagerNotified = false;

    if (_pingTimer) {
        _pingTimer->stop();
        _pingTimer->deleteLater();
        _pingTimer = nullptr;
    }

    if (_rttTimer) {
        _rttTimer->stop();
        _rttTimer->deleteLater();
        _rttTimer = nullptr;
    }

    _cleanupVideoBridge();

    if (_dataChannel) {
        try {
            if (_dataChannel->isOpen()) {
                _dataChannel->close();
            }
        } catch (const std::exception& e) {
            qCWarning(WebRTCLinkLog) << "Error closing data channel:" << e.what();
        }
        _dataChannel.reset();
    }

    if (_peerConnection) {
        try {
            _peerConnection->close();
        } catch (const std::exception& e) {
            qCWarning(WebRTCLinkLog) << "Error closing peer connection:" << e.what();
        }
        _peerConnection.reset();
    }

    if (_webSocket && _webSocket->state() != QAbstractSocket::UnconnectedState) {
        _webSocket->close();
    }

    _signalingConnected = false;
    _remoteDescriptionSet = false;
    _pendingCandidates.clear();

}

void WebRTCWorker::_startPingTimer()
{
    if (!_pingTimer) {
        _pingTimer = new QTimer(this);
        connect(_pingTimer, &QTimer::timeout, this, &WebRTCWorker::_sendPing);
        _pingTimer->start(1000);
    }
}

void WebRTCWorker::_sendPing()
{
    if (!_dataChannel || !_dataChannel->isOpen()) return;

    QJsonObject ping;
    ping["type"] = "ping";
    ping["timestamp"] = QDateTime::currentMSecsSinceEpoch();

    QString json = QJsonDocument(ping).toJson(QJsonDocument::Compact);
    _dataChannel->send(json.toStdString());
    _lastPingSent = ping.value("timestamp").toVariant().toLongLong();
}

void WebRTCWorker::_setupVideoBridge()
{
    if (_videoBridge) {
        qCDebug(WebRTCLinkLog) << "Video bridge already exists";
        return;
    }

    qCDebug(WebRTCLinkLog) << "Setting up video bridge";
    _videoBridge = new WebRTCVideoBridge(this);

    // 비디오 브리지 시그널 연결
    connect(_videoBridge, &WebRTCVideoBridge::bridgeStarted,
            this, [this](quint16 port) {
                _currentVideoURI = QString("udp://127.0.0.1:%1").arg(port);
                _videoStreamActive = true;
                _bridgeState = BRIDGE_READY;

                qCDebug(WebRTCLinkLog) << "Video bridge ready, URI:" << _currentVideoURI;
                //emit videoStreamReady(_currentVideoURI);

                _onBridgeReady();
            });

    connect(_videoBridge, &WebRTCVideoBridge::bridgeStopped,
            this, [this]() {
                _videoStreamActive = false;
                _currentVideoURI.clear();
                qCDebug(WebRTCLinkLog) << "Video bridge stopped";
            });

    connect(_videoBridge, &WebRTCVideoBridge::errorOccurred,
            this, [this](const QString& error) {
                qCCritical(WebRTCLinkLog) << "Video bridge error:" << error;
                emit videoBridgeError(error);
            });

    // 브리지 시작
    if (!_videoBridge->startBridge(55000)) {
        qCCritical(WebRTCLinkLog) << "Failed to start video bridge";
        delete _videoBridge;
        _videoBridge = nullptr;
    }
}

void WebRTCWorker::_onBridgeReady()
{
    if (_videoManagerNotified) {
        qCDebug(WebRTCLinkLog) << "VideoManager already notified, skipping";
        return;
    }

    qCDebug(WebRTCLinkLog) << "🎯 Bridge ready";

    _notifyVideoManager();
}

void WebRTCWorker::_notifyVideoManager()
{
    if (_videoManagerNotified) {
        return;
    }

    _videoManagerNotified = true;
    _bridgeState = BRIDGE_STREAMING;

    qCDebug(WebRTCLinkLog) << "📡 Notifying VideoManager - Bridge fully ready:";
    qCDebug(WebRTCLinkLog) << "   URI:" << _currentVideoURI;
    qCDebug(WebRTCLinkLog) << "   State:" << _bridgeState;

    emit videoStreamReady(_currentVideoURI);
}

void WebRTCWorker::_ensureBridgeReady()
{
    if (_bridgeState != BRIDGE_NOT_READY) {
        qCDebug(WebRTCLinkLog) << "Bridge already in progress, state:" << _bridgeState;
        return;
    }

    _bridgeState = BRIDGE_STARTING;
    qCDebug(WebRTCLinkLog) << "🌉 Ensuring video bridge is ready...";

    if (!_videoBridge) {
        _setupVideoBridge();
    } else {
        _onBridgeReady();
    }
}

void WebRTCWorker::_cleanupVideoBridge()
{
    if (_videoBridge) {
        _videoBridge->stopBridge();
        _videoBridge->deleteLater();
        _videoBridge = nullptr;
    }

    _videoStreamActive = false;
    _currentVideoURI.clear();
}

void WebRTCWorker::_handleVideoTrackData(const rtc::binary& data)
{
    if (!_videoBridge || !_videoStreamActive) {
        return;
    }
    static int packetCount = 0;
    packetCount++;
    if (packetCount <= 3/* || packetCount % 1000 == 0*/) {
        qCDebug(WebRTCLinkLog) << "📦 Video packet" << packetCount
                               << "size:" << data.size()
                               << "to bridge port:" << _videoBridge->localPort();
    }

    QByteArray rtpData(reinterpret_cast<const char*>(data.data()), data.size());

    if (packetCount == 1 && rtpData.size() >= 12) {
        _analyzeFirstRTPPacket(rtpData);
    }

    // UDP 소켓으로 전달
    _videoBridge->forwardRTPData(rtpData);

    // 통계 업데이트
    _totalFramesReceived++;
    emit decodingStatsChanged(_totalFramesReceived, _totalFramesReceived, _droppedFrames);
}

void WebRTCWorker::_analyzeFirstRTPPacket(const QByteArray& rtpData)
{
    if (rtpData.size() < 12) return;

    quint8 version = (static_cast<quint8>(rtpData[0]) >> 6) & 0x03;
    quint8 padding = (static_cast<quint8>(rtpData[0]) >> 5) & 0x01;
    quint8 extension = (static_cast<quint8>(rtpData[0]) >> 4) & 0x01;
    quint8 cc = static_cast<quint8>(rtpData[0]) & 0x0F;
    quint8 marker = (static_cast<quint8>(rtpData[1]) >> 7) & 0x01;
    quint8 payloadType = static_cast<quint8>(rtpData[1]) & 0x7F;
    quint16 seqNum = (static_cast<quint8>(rtpData[2]) << 8) | static_cast<quint8>(rtpData[3]);
    quint32 timestamp = (static_cast<quint8>(rtpData[4]) << 24) |
                        (static_cast<quint8>(rtpData[5]) << 16) |
                        (static_cast<quint8>(rtpData[6]) << 8) |
                        static_cast<quint8>(rtpData[7]);
    quint32 ssrc = (static_cast<quint8>(rtpData[8]) << 24) |
                   (static_cast<quint8>(rtpData[9]) << 16) |
                   (static_cast<quint8>(rtpData[10]) << 8) |
                   static_cast<quint8>(rtpData[11]);

    qCDebug(WebRTCLinkLog) << "🔍 First RTP packet analysis:";
    qCDebug(WebRTCLinkLog) << "   Version:" << version << "PT:" << payloadType << "Marker:" << marker;
    qCDebug(WebRTCLinkLog) << "   Sequence:" << seqNum << "Timestamp:" << timestamp;
    qCDebug(WebRTCLinkLog) << "   SSRC:" << Qt::hex << ssrc << Qt::dec;
    qCDebug(WebRTCLinkLog) << "   CC:" << cc << "Padding:" << padding << "Extension:" << extension;

    // 페이로드 시작 부분 덤프
    if (rtpData.size() > 12) {
        QString payloadHex;
        int headerSize = 12 + (cc * 4); // 기본 헤더 + CSRC
        if (extension && rtpData.size() > headerSize + 4) {
            // Extension header length 읽기
            quint16 extLength = (static_cast<quint8>(rtpData[headerSize + 2]) << 8) |
                                static_cast<quint8>(rtpData[headerSize + 3]);
            headerSize += 4 + (extLength * 4);
        }

        if (rtpData.size() > headerSize) {
            int dumpSize = qMin(16, rtpData.size() - headerSize);
            for (int i = 0; i < dumpSize; ++i) {
                payloadHex += QString("%1 ").arg(static_cast<quint8>(rtpData[headerSize + i]), 2, 16, QChar('0'));
            }
            qCDebug(WebRTCLinkLog) << "   Payload start:" << payloadHex;
        }
    }
}


//------------------------------------------------------
// WebRTCLink (구현)
//------------------------------------------------------
WebRTCLink::WebRTCLink(SharedLinkConfigurationPtr &config, QObject *parent)
    : LinkInterface(config, parent)
{
    _rtcConfig = qobject_cast<const WebRTCConfiguration*>(config.get());
    _worker = new WebRTCWorker(_rtcConfig);
    _workerThread = new QThread(this);
    _worker->moveToThread(_workerThread);

            // 스레드 시작 시 worker도 시작
    connect(_workerThread, &QThread::started, _worker, &WebRTCWorker::start);
    connect(_workerThread, &QThread::finished, _worker, &QObject::deleteLater);

            // worker -> link 연결 상태 통보
    connect(_worker, &WebRTCWorker::connected, this, &WebRTCLink::_onConnected, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::disconnected, this, &WebRTCLink::_onDisconnected, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::errorOccurred, this, &WebRTCLink::_onErrorOccurred, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::bytesReceived, this, &WebRTCLink::_onDataReceived, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::bytesSent, this, &WebRTCLink::_onDataSent, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::rttUpdated, this, &WebRTCLink::_onRttUpdated, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::rtcStatusMessageChanged, this, &WebRTCLink::_onRtcStatusMessageChanged, Qt::QueuedConnection);

    connect(_worker, &WebRTCWorker::videoStreamReady, this, &WebRTCLink::_onVideoStreamReady, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::videoBridgeError, this, &WebRTCLink::_onVideoBridgeError, Qt::QueuedConnection);

    _workerThread->start();
}

WebRTCLink::~WebRTCLink()
{
    disconnect();

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
    qDebug() << "[WebRTCLink] Connected";
    _onRtcStatusMessageChanged("RTC Connected");
    emit connected();
}

void WebRTCLink::_onDisconnected()
{
    qDebug() << "[WebRTCLink] Disconnected";
    _onRtcStatusMessageChanged("RTC Disconnected");
    emit disconnected();
}

void WebRTCLink::_onErrorOccurred(const QString &errorString)
{
    qWarning() << "[WebRTCLink] Error: " << errorString;
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

void WebRTCLink::_onRtcStatusMessageChanged(QString message)
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

QString WebRTCLink::videoStreamUri() const
{
    return _worker ? _worker->currentVideoUri() : QString();
}

void WebRTCLink::_onVideoStreamReady(const QString& uri)
{
    emit videoStreamReady(uri);
    qCDebug(WebRTCLinkLog) << "uri: " << uri;
}

void WebRTCLink::_onVideoBridgeError(const QString& error)
{
    emit videoBridgeError(error);
}
