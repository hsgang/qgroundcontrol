#include "WebRTCLink.h"
#include <QDebug>
#include <QUrl>
#include <QtQml/qqml.h>
// #include "SettingsManager.h"
// #include "VideoSettings.h"
#include "VideoManager.h"
#include "QGCLoggingCategory.h"

QGC_LOGGING_CATEGORY(WebRTCLinkLog, "WebRTCLink")

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
        _roomId = src->_roomId;
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
    _roomId = settings.value("roomId", "").toString();
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
    settings.setValue("roomId", _roomId);
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
      , _decodingCheckTimer(new QTimer(this))
      , _retryCount(0)
{
    _decodingCheckTimer->setSingleShot(true);
    connect(_decodingCheckTimer, &QTimer::timeout, this, &WebRTCVideoBridge::_checkDecodingStatus);
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

    if (!_udpSocket->bind(QHostAddress::LocalHost, localPort, QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint)) {
        emit errorOccurred(QString("Failed to bind UDP socket: %1").arg(_udpSocket->errorString()));
        return false;
    }

    _localPort = _udpSocket->localPort();
    _isRunning = true;

    // SettingsManager::instance()->videoSettings()->videoSource()->setRawValue(VideoSettings::videoSourceUDPH264);
    // QString udpUrl = QString("127.0.0.1:%1").arg(_localPort);
    // SettingsManager::instance()->videoSettings()->udpUrl()->setRawValue(udpUrl);
    // SettingsManager::instance()->videoSettings()->lowLatencyMode()->setRawValue(true);

    // qDebug() << "WebRTC video bridge started on port:" << _localPort;
    emit bridgeStarted(_localPort);

    return true;
}

void WebRTCVideoBridge::stopBridge()
{
    if (!_isRunning) {
        return;
    }

    _decodingCheckTimer->stop();

    _udpSocket->close();
    _isRunning = false;
    _localPort = 0;
    _firstPacketSent = false;

    qDebug() << "WebRTC video bridge stopped";
    emit bridgeStopped();
}

void WebRTCVideoBridge::forwardRTPData(const QByteArray& rtpData)
{
    //qCDebug(WebRTCLinkLog) << "[UDP] Sending packet size:" << rtpData.size();

    if (!_isRunning || rtpData.isEmpty()) {
        qWarning() << "[Bridge] Not running, drop packet";
        return;
    }

    if( !_udpSocket || !_udpSocket->isValid()) {
        qWarning() << "[Bridge] UDP socket invalid!";
        return;
    }

    if (_localPort == 0) {
        qWarning() << "[Bridge] Invalid local port!";
        return;
    }

    if (!_firstPacketSent) {
        _firstPacketSent = true;
        QMetaObject::invokeMethod(this, "_startDecodingCheckTimer", Qt::QueuedConnection);  // 수정
        //qDebug() << "[Bridge] First RTP packet sent, starting decoding check timer";
    }

    // 로컬호스트로 RTP 데이터 전송
    //qDebug() << "_udpSocket->state()" << _udpSocket->state();
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

void WebRTCVideoBridge::_startDecodingCheckTimer()
{
    // 메인 스레드에서 실행되도록 보장
    if (QThread::currentThread() != this->thread()) {
        QMetaObject::invokeMethod(this, "_startDecodingCheckTimer", Qt::QueuedConnection);
        return;
    }

    // 1초 후에 디코딩 상태 체크
    _decodingCheckTimer->start(2000);
}

void WebRTCVideoBridge::_checkDecodingStatus()
{
    // VideoManager 인스턴스에서 디코딩 상태 확인
    VideoManager* videoManager = VideoManager::instance();

    if (!videoManager || !videoManager->decoding()) {
        _retryCount++;
        qWarning() << QString("[Bridge] VideoManager not decoding after 2 second (retry %1/3)").arg(_retryCount);

        if (_retryCount <= 5) {  // 최대 5번 재시도
            qDebug() << "[Bridge] Retrying video bridge setup...";
            emit retryBridgeRequested();
        } else {
            qCritical() << "[Bridge] Max retries reached, giving up";
            emit errorOccurred("VideoManager failed to start decoding after multiple attempts");
        }
    } else {
        qDebug() << "[Bridge] VideoManager is decoding successfully";
        _retryCount = 0;  // 성공 시 재시도 카운터 리셋
    }
}

void WebRTCVideoBridge::resetRetryCount()
{
    _retryCount = 0;
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

    //qCDebug(WebRTCLinkLog) << "WebRTCWorker created for peer:" << _config->roomId();
}

WebRTCWorker::~WebRTCWorker()
{
    _cleanup();
}

void WebRTCWorker::initializeLogger()
{
    rtc::InitLogger(rtc::LogLevel::Debug);
}

void WebRTCWorker::start()
{
    //qCDebug(WebRTCLinkLog) << "Starting WebRTC worker";
    _setupPeerConnection();
    _connectToSignalingServer();
}

void WebRTCWorker::writeData(const QByteArray &data)
{
    if (_isShuttingDown.load()) {
        return;
    }

    if (!_dataChannel || !_dataChannel->isOpen()) {
        qCWarning(WebRTCLinkLog) << "Data channel not available for sending data";
        return;
    }

    try {
        rtc::binary binaryData(reinterpret_cast<const std::byte*>(data.constData()),
                               reinterpret_cast<const std::byte*>(data.constData()) + data.size());
        // 원자적 체크 후 전송
        if (!_isShuttingDown.load() && _dataChannel && _dataChannel->isOpen()) {
            _dataChannel->send(binaryData);
            emit bytesSent(data);
        }
    } catch (const std::exception& e) {
        if (!_isShuttingDown.load()) {
            qCWarning(WebRTCLinkLog) << "Failed to send data:" << e.what();
            emit errorOccurred(QString("Failed to send data: %1").arg(e.what()));
        }
    }
}

void WebRTCWorker::disconnectLink()
{
    _isShuttingDown.store(true);

    qCDebug(WebRTCLinkLog) << "Disconnecting WebRTC link";
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
    emit rtcStatusMessageChanged("서버 소켓 연결");
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
        rtc::IceServer turnServer(
            _config->turnServer().toStdString(),  // hostname
            3478,                                 // 포트 (필요시 파싱)
            _config->turnUsername().toStdString(),
            _config->turnPassword().toStdString(),
            rtc::IceServer::RelayType::TurnUdp
            );
        _rtcConfig.iceServers.emplace_back(turnServer);
    }

    // Configure UDP mux
    _rtcConfig.enableIceUdpMux = false;

    try {
        // _rtcConfig.disableAutoNegotiation = true;
        _peerConnection = std::make_shared<rtc::PeerConnection>(_rtcConfig);

        // QPointer로 안전한 참조 생성
        QPointer<WebRTCWorker> weakSelf(this);

        _peerConnection->onStateChange([weakSelf](rtc::PeerConnection::State state) {
            if (weakSelf) {
                QMetaObject::invokeMethod(weakSelf, [weakSelf, state]() {
                    if (weakSelf && !weakSelf->_isShuttingDown.load()) {
                        weakSelf->_onPeerStateChanged(state);
                    }
                }, Qt::QueuedConnection);
            }
        });

        _peerConnection->onGatheringStateChange([weakSelf](rtc::PeerConnection::GatheringState state) {
            if (weakSelf) {
                QMetaObject::invokeMethod(weakSelf, [weakSelf, state]() {
                    if (weakSelf && !weakSelf->_isShuttingDown.load()) {
                        weakSelf->_onGatheringStateChanged(state);
                    }
                }, Qt::QueuedConnection);
            }
        });

        _peerConnection->onLocalDescription([weakSelf](rtc::Description description) {
            if (weakSelf) {
                QString descType = QString::fromStdString(description.typeString());
                QString sdpContent = QString::fromStdString(description);

                QMetaObject::invokeMethod(weakSelf, [weakSelf, descType, sdpContent]() {
                    if (weakSelf && !weakSelf->_isShuttingDown.load()) {
                        QJsonObject message;
                        message["id"] = weakSelf->_config->peerId();
                        message["to"] = weakSelf->_config->targetPeerId();
                        message["type"] = descType;
                        message["sdp"] = sdpContent;
                        weakSelf->_sendSignalingMessage(message);
                    }
                }, Qt::QueuedConnection);
            }
        });

        _peerConnection->onLocalCandidate([weakSelf](rtc::Candidate candidate) {
            if (weakSelf) {
                QString candidateStr = QString::fromStdString(candidate);
                QString mid = QString::fromStdString(candidate.mid());

                QMetaObject::invokeMethod(weakSelf, [weakSelf, candidateStr, mid]() {
                    if (weakSelf && !weakSelf->_isShuttingDown.load()) {
                        QJsonObject message;
                        message["id"] = weakSelf->_config->peerId();
                        message["to"] = weakSelf->_config->targetPeerId();
                        message["type"] = "candidate";
                        message["candidate"] = candidateStr;
                        message["sdpMid"] = mid;
                        weakSelf->_sendSignalingMessage(message);
                    }
                }, Qt::QueuedConnection);
            }
        });

        _peerConnection->onDataChannel([weakSelf](std::shared_ptr<rtc::DataChannel> dc) {
            if (weakSelf) {
                QMetaObject::invokeMethod(weakSelf, [weakSelf, dc]() {
                    if (weakSelf && !weakSelf->_isShuttingDown.load()) {
                        qCDebug(WebRTCLinkLog) << "Data channel received with label:"
                                               << QString::fromStdString(dc->label());
                        weakSelf->_dataChannel = dc;
                        weakSelf->_setupDataChannel(weakSelf->_dataChannel);
                    }
                }, Qt::QueuedConnection);
            }
        });

        _peerConnection->onTrack([weakSelf](std::shared_ptr<rtc::Track> track) {
            if (weakSelf) {
                QMetaObject::invokeMethod(weakSelf, [weakSelf, track]() {
                    if (weakSelf && !weakSelf->_isShuttingDown.load()) {
                        weakSelf->_handleTrackReceived(track);
                    }
                }, Qt::QueuedConnection);
            }
        });

        qCDebug(WebRTCLinkLog) << "Peer connection created successfully";

    } catch (const std::exception& e) {
        qCCritical(WebRTCLinkLog) << "Failed to create peer connection:" << e.what();
        emit errorOccurred(QString("Failed to create peer connection: %1").arg(e.what()));
    }
}

void WebRTCWorker::_handleTrackReceived(std::shared_ptr<rtc::Track> track)
{
    auto desc = track->description();

    if (desc.type() == "video") {
        qCDebug(WebRTCLinkLog) << "Video track received";
        _videoTrack = track;
        emit videoTrackReceived();

        if (!_videoBridgeAtomic.loadAcquire()) {
            _setupVideoBridge();
        }

                // weak_ptr로 안전한 콜백 설정
        std::weak_ptr<rtc::Track> weakTrack = track;
        track->onMessage([this, weakTrack](rtc::message_variant message) {
            if (auto strongTrack = weakTrack.lock()) {
                if (std::holds_alternative<rtc::binary>(message)) {
                    const auto& data = std::get<rtc::binary>(message);
                    _handleVideoTrackData(data);
                }
            }
        });

        auto session = std::make_shared<rtc::RtcpReceivingSession>();
        track->setMediaHandler(session);
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
    message["roomId"] = _config->roomId();
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
        qCDebug(WebRTCLinkLog) << "Received signaling message type:" << type << message;
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
                    //createOffer();  // 재연결 시도
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
    emit rtcStatusMessageChanged("데이터 채널 연결 성공");

    _startVideoStatsMonitoring();

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
            //createOffer();
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
    _isShuttingDown.store(true);
    _isDisconnecting = true;

    qCDebug(WebRTCLinkLog) << "Cleaning up WebRTC resources";

    if (_peerConnection) {
        try {
            _peerConnection->close();
        } catch (const std::exception& e) {
            qCWarning(WebRTCLinkLog) << "Error closing peer connection:" << e.what();
        }
        _peerConnection.reset();
    }

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

    if (_rttTimer) {
        _rttTimer->stop();
        _rttTimer->deleteLater();
        _rttTimer = nullptr;
    }

    if (_videoStatsTimer) {
        _videoStatsTimer->stop();
        _videoStatsTimer->deleteLater();
        _videoStatsTimer = nullptr;
    }

    _cleanupVideoBridge();

    if (_webSocket && _webSocket->state() != QAbstractSocket::UnconnectedState) {
        _webSocket->close();
    }

    _signalingConnected = false;
    _remoteDescriptionSet = false;
    _pendingCandidates.clear();

    // 통계 리셋
    {
        QMutexLocker locker(&_videoStatsMutex);
        _videoBytesReceived = 0;
        _lastVideoBytesReceived = 0;
        _videoPacketCount = 0;
        _currentVideoRateKBps = 0.0;
        _averagePacketSize = 0.0;
    }
    _isDisconnecting = false;
}

void WebRTCWorker::_setupVideoBridge()
{
    if (_videoBridgeAtomic.loadAcquire()) {
        qCDebug(WebRTCLinkLog) << "Video bridge already exists";
        return;
    }

    qCDebug(WebRTCLinkLog) << "Setting up video bridge";

    if (QThread::currentThread() == this->thread()) {
        // 같은 스레드면 직접 호출
        _createVideoBridge();
    } else {
        // 다른 스레드면 QueuedConnection
        QMetaObject::invokeMethod(this, [this]() {
            _createVideoBridge();
        }, Qt::QueuedConnection);
    }
}

void WebRTCWorker::_createVideoBridge()
{
    // 이미 생성되었는지 다시 체크
    if (_videoBridgeAtomic.loadAcquire() || _isShuttingDown.load()) {
        return;
    }

    WebRTCVideoBridge* bridge = new WebRTCVideoBridge(this);

    // QPointer로 안전한 참조
    QPointer<WebRTCVideoBridge> safeBridge(bridge);
    QPointer<WebRTCWorker> safeSelf(this);

    // 시그널 연결
    connect(bridge, &WebRTCVideoBridge::bridgeStarted,
            this, [this](quint16 port) {
                if (!_isShuttingDown.load()) {
                    QMutexLocker locker(&_videoBridgeMutex);
                    _currentVideoURI = QString("udp://127.0.0.1:%1").arg(port);
                    _videoStreamActive = true;
                    qCDebug(WebRTCLinkLog) << "Video bridge started on port:" << port;
                }
            }, Qt::QueuedConnection);

    connect(bridge, &WebRTCVideoBridge::bridgeStopped,
            this, [this]() {
                QMutexLocker locker(&_videoBridgeMutex);
                _videoStreamActive = false;
                _currentVideoURI.clear();
                qCDebug(WebRTCLinkLog) << "Video bridge stopped";
            }, Qt::QueuedConnection);

    connect(bridge, &WebRTCVideoBridge::errorOccurred,
            this, [this](const QString& error) {
                if (!_isShuttingDown.load()) {
                    qCWarning(WebRTCLinkLog) << "Video bridge error:" << error;
                    emit videoBridgeError(error);
                }
            }, Qt::QueuedConnection);

    connect(bridge, &WebRTCVideoBridge::retryBridgeRequested,
            this, [this]() {
                if (!_isShuttingDown.load()) {
                    QTimer::singleShot(1000, this, [this]() {
                        _cleanupVideoBridge();
                        _setupVideoBridge();
                    });
                }
            }, Qt::QueuedConnection);

            // 원자적으로 설정
    _videoBridgeAtomic.storeRelease(bridge);

    // 비동기적으로 시작
    QTimer::singleShot(0, this, [this, bridge]() {
        if (!_isShuttingDown.load()) {
            // 다시 한번 체크 - 다른 스레드에서 변경되었을 수 있음
            WebRTCVideoBridge* currentBridge = _videoBridgeAtomic.loadAcquire();
            if (currentBridge == bridge) {
                if (!bridge->startBridge(55000)) {
                    qCCritical(WebRTCLinkLog) << "Failed to start video bridge";
                    // testAndSetOrdered로 안전하게 제거
                    if (_videoBridgeAtomic.testAndSetOrdered(bridge, nullptr)) {
                        bridge->deleteLater();
                    }
                }
            }
        }
    });
}

void WebRTCWorker::_cleanupVideoBridge()
{
    WebRTCVideoBridge* bridge = _videoBridgeAtomic.fetchAndStoreRelease(nullptr);

    if (bridge) {
        // 안전하게 정리
        QMetaObject::invokeMethod(bridge, [bridge]() {
            bridge->stopBridge();
            bridge->deleteLater();
        }, Qt::QueuedConnection);
    }

    QMutexLocker locker(&_videoBridgeMutex);
    _videoStreamActive = false;
    _currentVideoURI.clear();
}

void WebRTCWorker::_handleVideoTrackData(const rtc::binary& data)
{
    if (_isShuttingDown.load() || !_videoStreamActive) {
        return;
    }

    // 데이터 복사 (WebRTC 스레드에서)
    QByteArray rtpData(reinterpret_cast<const char*>(data.data()), data.size());

    // QPointer로 안전한 참조
    QPointer<WebRTCWorker> weakSelf(this);

    // 메인 스레드로 안전하게 전달
    QMetaObject::invokeMethod(this, [weakSelf, rtpData]() {
        if (weakSelf && !weakSelf->_isShuttingDown.load()) {
            WebRTCVideoBridge* bridge = weakSelf->_videoBridgeAtomic.loadAcquire();
            if (bridge && weakSelf->_videoStreamActive) {
                bridge->forwardRTPData(rtpData);
                weakSelf->_updateVideoStatisticsSync(rtpData.size());
            }
        }
    }, Qt::QueuedConnection);
}

void WebRTCWorker::_updateVideoStatisticsSync(int dataSize)
{
    if (_isShuttingDown.load()) return;

    QMutexLocker locker(&_videoStatsMutex);
    _videoPacketCount++;
    _videoBytesReceived += dataSize;
    _averagePacketSize = (_averagePacketSize * (_videoPacketCount - 1) + dataSize) / _videoPacketCount;
    _totalFramesReceived++;

    emit decodingStatsChanged(_totalFramesReceived, _totalFramesReceived, _droppedFrames);
}

int WebRTCWorker::_parseRtpHeaderOffset(const QByteArray& rtpData)
{
    if (rtpData.size() < 12) {
        qWarning() << "[RTP] Packet too small.";
        return -1;
    }

    quint8 b0 = static_cast<quint8>(rtpData[0]);
    quint8 extension = (b0 >> 4) & 0x01;
    quint8 cc = b0 & 0x0F;

    int headerSize = 12 + (cc * 4);

    if (rtpData.size() < headerSize) {
        qWarning() << "[RTP] Packet too small for CSRC.";
        return -1;
    }

    if (extension) {
        if (rtpData.size() < headerSize + 4) {
            qWarning() << "[RTP] Packet too small for Extension.";
            return -1;
        }
        quint16 extLength = (static_cast<quint8>(rtpData[headerSize + 2]) << 8)
                            | static_cast<quint8>(rtpData[headerSize + 3]);
        headerSize += 4 + (extLength * 4);
    }

    return headerSize;
}

void WebRTCWorker::_analyzeFirstRTPPacket(const QByteArray& rtpData)
{
    if (rtpData.size() < 12) return;

    quint8 version = (static_cast<quint8>(rtpData[0]) >> 6) & 0x03;
    quint8 extension = (static_cast<quint8>(rtpData[0]) >> 4) & 0x01;
    quint8 cc = static_cast<quint8>(rtpData[0]) & 0x0F;
    quint8 payloadType = static_cast<quint8>(rtpData[1]) & 0x7F;

    quint16 seqNum = (static_cast<quint8>(rtpData[2]) << 8) | static_cast<quint8>(rtpData[3]);
    quint32 timestamp = (static_cast<quint8>(rtpData[4]) << 24)
                        | (static_cast<quint8>(rtpData[5]) << 16)
                        | (static_cast<quint8>(rtpData[6]) << 8)
                        | static_cast<quint8>(rtpData[7]);
    quint32 ssrc = (static_cast<quint8>(rtpData[8]) << 24)
                   | (static_cast<quint8>(rtpData[9]) << 16)
                   | (static_cast<quint8>(rtpData[10]) << 8)
                   | static_cast<quint8>(rtpData[11]);

    int headerSize = _parseRtpHeaderOffset(rtpData);

    qCDebug(WebRTCLinkLog) << "🔍 First RTP packet:"
                           << "Version:" << version
                           << "PT:" << payloadType
                           << "Seq:" << seqNum
                           << "Timestamp:" << timestamp
                           << "SSRC:" << Qt::hex << ssrc << Qt::dec
                           << "CC:" << cc
                           << "Extension:" << extension
                           << "HeaderSize:" << headerSize;

    if (headerSize >= 0 && headerSize < rtpData.size()) {
        int dumpSize = qMin(16, rtpData.size() - headerSize);
        QString payloadHex;
        for (int i = 0; i < dumpSize; ++i) {
            payloadHex += QString("%1 ").arg(static_cast<quint8>(rtpData[headerSize + i]), 2, 16, QChar('0'));
        }
        qCDebug(WebRTCLinkLog) << "Payload start:" << payloadHex;
    }
}

void WebRTCWorker::_startVideoStatsMonitoring()
{
    if (!_videoStatsTimer) {
        _videoStatsTimer = new QTimer(this);
        connect(_videoStatsTimer, &QTimer::timeout, this, &WebRTCWorker::_updateVideoStats);
        _videoStatsTimer->start(1000); // Update every second
    }

    // Initialize timing
    _lastVideoStatsTime = QDateTime::currentMSecsSinceEpoch();
    _videoBytesReceived = 0;
    _lastVideoBytesReceived = 0;
    _videoPacketCount = 0;
    _currentVideoRateKBps = 0.0;
}

void WebRTCWorker::_updateVideoStats()
{
    _calculateVideoRate();

    // Emit statistics
    emit videoRateChanged(_currentVideoRateKBps);
    emit videoStatsChanged(_videoPacketCount, _averagePacketSize, _currentVideoRateKBps);

    // Log statistics periodically
    static int logCounter = 0;
    if (++logCounter % 5 == 0) { // Log every 5 seconds
        qCDebug(WebRTCLinkLog) << QString("📊 Video Stats: %1 kB/s, %2 packets, avg size: %3 bytes")
                                      .arg(_currentVideoRateKBps, 0, 'f', 1)
                                      .arg(_videoPacketCount)
                                      .arg(_averagePacketSize, 0, 'f', 1);
    }
}

void WebRTCWorker::_calculateVideoRate()
{
    qint64 currentTime = QDateTime::currentMSecsSinceEpoch();
    qint64 timeDiff = currentTime - _lastVideoStatsTime;

    if (timeDiff > 0) {
        qint64 bytesDiff = _videoBytesReceived - _lastVideoBytesReceived;

        // Calculate rate in kb/s (kilobits per second)
        // bytes/ms * 8 bits/byte * 1000 ms/s * 1/1000 kb/bits = bytes/ms * 8
        _currentVideoRateKBps = bytesDiff / timeDiff;

        // Update for next calculation
        _lastVideoBytesReceived = _videoBytesReceived;
        _lastVideoStatsTime = currentTime;
    }
}

double WebRTCWorker::currentVideoRateKBps() const
{
    return _currentVideoRateKBps;
}

int WebRTCWorker::videoPacketCount() const
{
    return _videoPacketCount;
}

qint64 WebRTCWorker::videoBytesReceived() const
{
    return _videoBytesReceived;
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

    connect(_worker, &WebRTCWorker::videoBridgeError, this, &WebRTCLink::_onVideoBridgeError, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::videoRateChanged, this, &WebRTCLink::_onVideoRateChanged, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::videoStatsChanged, this, &WebRTCLink::_onVideoStatsChanged, Qt::QueuedConnection);

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
    _onRtcStatusMessageChanged("RTC 연결됨");
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
    //qCDebug(WebRTCLinkLog) << "uri: " << uri;
}

void WebRTCLink::_onVideoBridgeError(const QString& error)
{
    emit videoBridgeError(error);
}

void WebRTCLink::_onVideoRateChanged(double KBps)
{
    if (_videoRateKBps != KBps) {
        _videoRateKBps = KBps;
        emit videoRateKBpsChanged();
    }
}

void WebRTCLink::_onVideoStatsChanged(int packets, double avgSize, double rate)
{
    bool changed = false;

    if (_videoPacketCount != packets) {
        _videoPacketCount = packets;
        emit videoPacketCountChanged();
        changed = true;
    }

    if (_videoBytesReceived != _worker->videoBytesReceived()) {
        _videoBytesReceived = _worker->videoBytesReceived();
        emit videoBytesReceivedChanged();
        changed = true;
    }

    if (changed) {
        emit videoStatsUpdated(rate, packets, _videoBytesReceived);
    }
}
