#include "WebRTCLink.h"
#include <QDebug>
#include <QUrl>
#include <QtQml/qqml.h>
// #include "SettingsManager.h"
// #include "VideoSettings.h"
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

    int bufferSize = 2 * 1024 * 1024; // 버퍼 크기 2MB
    _udpSocket->setSocketOption(QAbstractSocket::SendBufferSizeSocketOption, bufferSize);

    _localPort = _udpSocket->localPort();
    _isRunning = true;

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

void WebRTCVideoBridge::forwardRTPData(const rtc::binary& rtpData)
{
    if (!_isRunning || rtpData.empty()) {
        qWarning() << "[Bridge] Not running, drop packet";
        return;
    }

    if( !_udpSocket || !_udpSocket->isValid()) {
        qWarning() << "[Bridge] UDP socket invalid!";
        return;
    }

    if (!_firstPacketSent) {
        _firstPacketSent = true;
        QMetaObject::invokeMethod(this, "_startDecodingCheckTimer", Qt::QueuedConnection);  // 수정
    }

    qint64 sent = _udpSocket->writeDatagram(
        reinterpret_cast<const char*>(rtpData.data()),
        rtpData.size(),
        QHostAddress::LocalHost,
        _localPort
    );

    if (sent != rtpData.size()) {
        qWarning() << "Failed to send complete RTP packet:" << sent << "of" << rtpData.size();
    } else {
        _totalPackets++;
        _totalBytes += sent;
    }
}

void WebRTCVideoBridge::_startDecodingCheckTimer()
{
    if (QThread::currentThread() != this->thread()) {
        QMetaObject::invokeMethod(this, "_startDecodingCheckTimer", Qt::QueuedConnection);
        return;
    }

    _decodingCheckTimer->start(2000);
}

void WebRTCVideoBridge::_checkDecodingStatus()
{
    VideoManager* videoManager = VideoManager::instance();

    if (!videoManager || !videoManager->decoding()) {
        _retryCount++;
        qWarning() << QString("[Bridge] VideoManager not decoding after 2 second (retry %1/5)").arg(_retryCount);

        if (_retryCount <= 5) {
            qDebug() << "[Bridge] Retrying video bridge setup";
            emit retryBridgeRequested();
        } else {
            qCritical() << "[Bridge] Max retries reached, giving up";
            emit errorOccurred("VideoManager failed to start decoding after multiple attempts");
        }
    } else {
        qDebug() << "[Bridge] VideoManager is decoding successfully";
        _retryCount = 0;
    }
}

/*===========================================================================*/
// WebRTCWorker Implementation
/*===========================================================================*/

WebRTCWorker::WebRTCWorker(const WebRTCConfiguration *config, QObject *parent)
    : QObject(parent)
      , _config(config)
      , _videoStreamActive(false)
      , _signalingConnected(false)
      , _isDisconnecting(false)
      , _isOfferer(false)
{
    initializeLogger();
    _setupWebSocket();

    _statsTimer = new QTimer(this);
    connect(_statsTimer, &QTimer::timeout, this, &WebRTCWorker::_updateAllStatistics);

    connect(VideoManager::instance(), &VideoManager::decodingChanged, this, [this]() {
        if (!VideoManager::instance()->decoding()) {
            qCWarning(WebRTCLinkLog) << "[WebRTCWorker] decoding=false, restarting video bridge";
            _restartVideoBridge();
        }
    });

    // connect(VideoManager::instance(), &VideoManager::streamingChanged, this, [this]() {
    //     if (!VideoManager::instance()->streaming()) {
    //         qCWarning(WebRTCLinkLog) << "[WebRTCWorker] streaming=false, restarting video bridge";
    //         _restartVideoBridge();
    //     }
    // });

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
    _setupPeerConnection();
    _connectToSignalingServer();
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
    _isShuttingDown.store(true);

    qCDebug(WebRTCLinkLog) << "Disconnecting WebRTC link";
    _cleanupComplete();
    _cleanupVideoBridge();

    emit disconnected();
}

bool WebRTCWorker::isDataChannelOpen() const
{
    return _mavlinkDataChannel && _mavlinkDataChannel->isOpen();
}

bool WebRTCWorker::isOperational() const {
    return !_isShuttingDown.load() && !_isDisconnecting;
}

void WebRTCWorker::_setupWebSocket()
{
    _webSocket = new QWebSocket(QString(), QWebSocketProtocol::VersionLatest, this);

    connect(_webSocket, &QWebSocket::connected, this, &WebRTCWorker::_onWebSocketConnected);
    connect(_webSocket, &QWebSocket::disconnected, this, &WebRTCWorker::_onWebSocketDisconnected);
    connect(_webSocket, &QWebSocket::errorOccurred, this, &WebRTCWorker::_onWebSocketError);
    connect(_webSocket, &QWebSocket::textMessageReceived, this, &WebRTCWorker::_onWebSocketMessageReceived);
}

void WebRTCWorker::_connectToSignalingServer()
{
    if (_signalingConnected) {
        qCWarning(WebRTCLinkLog) << "Already connected to signaling server";
        return;
    }

    QString url = QString("wss://%1:3000").arg(_config->signalingServer());

    qCDebug(WebRTCLinkLog) << "Connecting to signaling server:" << url;
    _webSocket->open(QUrl(url));
    emit rtcStatusMessageChanged("중계 서버 연결중");
}

void WebRTCWorker::_setupPeerConnection()
{
    _rtcConfig.iceServers.clear();

    if (!_config->stunServer().isEmpty()) {
        _rtcConfig.iceServers.emplace_back(_config->stunServer().toStdString());
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

    _rtcConfig.enableIceUdpMux = false;

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
                // shared_ptr을 직접 전달하기 위해 람다 사용 (Q_ARG로는 불가능)
                QMetaObject::invokeMethod(this, [this, track]() {
                    if (isOperational()) {
                        _handleTrackReceived(track);
                    }
                }, Qt::QueuedConnection);
            }
        });

        _peerConnection->onDataChannel([this](std::shared_ptr<rtc::DataChannel> dc) {
            if (!dc) {
                qCCritical(WebRTCLinkLog) << "[DATACHANNEL] ERROR: DataChannel is null!";
                return;
            }

            if (_isShuttingDown.load()) {
                qCCritical(WebRTCLinkLog) << "[DATACHANNEL] Shutting down, ignoring";
                return;
            }

            std::string label = dc->label();
            qCCritical(WebRTCLinkLog) << "[DATACHANNEL] DataChannel received - Label:"
                                      << QString::fromStdString(label);

            if (label == "mavlink") {
                _mavlinkDataChannel = dc;
                _setupMavlinkDataChannel(dc);
            } else if (label == "custom") {
                _customDataChannel = dc;
                _setupCustomDataChannel(dc);
            }

            // 즉시 상태 확인
            if (dc->isOpen()) {
                qCCritical(WebRTCLinkLog) << "[DATACHANNEL] Opened, Processing immediately";
                _processDataChannelOpen();
            }
        });

        qCDebug(WebRTCLinkLog) << "Peer connection created successfully";

    } catch (const std::exception& e) {
        qCCritical(WebRTCLinkLog) << "Failed to create peer connection:" << e.what();
        emit errorOccurred(QString("Failed to create peer connection: %1").arg(e.what()));
    }
}

void WebRTCWorker::handlePeerStateChange(int stateValue) {
    if (!isOperational()) return;

    auto state = static_cast<rtc::PeerConnection::State>(stateValue);
    qCDebug(WebRTCLinkLog) << "[STATE] PeerConnection state changed to:" << stateValue;
    _onPeerStateChanged(state);
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

void WebRTCWorker::_setupMavlinkDataChannel(std::shared_ptr<rtc::DataChannel> dc)
{
    if (!dc) return;

    qCCritical(WebRTCLinkLog) << "[DATACHANNEL] Setting up callbacks only";

    dc->onOpen([this]() {
        qCCritical(WebRTCLinkLog) << "[DATACHANNEL] *** DataChannel OPENED! ***";
        if (!_isShuttingDown.load()) {
            _processDataChannelOpen();
        }
    });

    dc->onClosed([this]() {
        qCCritical(WebRTCLinkLog) << "[DATACHANNEL] DataChannel CLOSED";
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
        qCCritical(WebRTCLinkLog) << "[DATACHANNEL] ERROR:" << QString::fromStdString(error);
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
            auto byteArrayPtr = std::make_shared<QByteArray>(
                reinterpret_cast<const char*>(binaryData.data()), binaryData.size()
                );

            _dataChannelReceivedCalc.addData(binaryData.size());

            QMetaObject::invokeMethod(this, [this, byteArrayPtr]() {
                emit bytesReceived(*byteArrayPtr);
            }, Qt::QueuedConnection);
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
        qCCritical(WebRTCLinkLog) << "[DATACHANNEL] *** CustomDataChannel OPENED! ***";
    });

    dc->onClosed([this]() {
        qCCritical(WebRTCLinkLog) << "[DATACHANNEL] CustomDataChannel CLOSED";
    });

    dc->onError([this](std::string error) {
        qCCritical(WebRTCLinkLog) << "[DATACHANNEL] CustomDataChannel ERROR:" << QString::fromStdString(error);
    });

    dc->onMessage([this, dc](auto data) {
        if (_isShuttingDown.load()) return;

        if (std::holds_alternative<rtc::binary>(data)) {
            const auto& binaryData = std::get<rtc::binary>(data);
            auto byteArrayPtr = std::make_shared<QByteArray>(
                reinterpret_cast<const char*>(binaryData.data()), binaryData.size()
                );

            _dataChannelReceivedCalc.addData(binaryData.size());

            // 바이너리 데이터를 문자열로 출력
            QString receivedText = QString::fromUtf8(*byteArrayPtr);
            qCDebug(WebRTCLinkLog) << "CustomDataChannel received:" << receivedText;
        }
    });
}

void WebRTCWorker::_processDataChannelOpen()
{
    if (_dataChannelOpened.exchange(true)) {
        qCCritical(WebRTCLinkLog) << "[DATACHANNEL] Already opened, ignoring";
        return;
    }

    if (_isShuttingDown.load()) {
        qCCritical(WebRTCLinkLog) << "[DATACHANNEL] Shutting down, ignoring open";
        return;
    }

    if (!_mavlinkDataChannel || !_mavlinkDataChannel->isOpen()) {
        qCCritical(WebRTCLinkLog) << "[DATACHANNEL] ERROR: DataChannel not actually open!";
        _dataChannelOpened.store(false);
        return;
    }

    qCCritical(WebRTCLinkLog) << "[DATACHANNEL] Data channel opened successfully";

    QMetaObject::invokeMethod(this, [this]() {
        emit connected();
        emit rtcStatusMessageChanged("데이터 채널 연결 완료");

        _startQtTimers();
    }, Qt::QueuedConnection);

    qCCritical(WebRTCLinkLog) << "[DATACHANNEL] Connection setup completed";
}

void WebRTCWorker::_startQtTimers()
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

        if (!_videoBridge) {
            _createVideoBridge();
        }

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
    if (!_signalingConnected) return;

    _signalingConnected = false;
    qCDebug(WebRTCLinkLog) << "WebSocket disconnected from signaling server";

    if (!_isDisconnecting) {
        QTimer::singleShot(kReconnectInterval, this, &WebRTCWorker::_connectToSignalingServer);
    }
}

void WebRTCWorker::_onWebSocketError(QAbstractSocket::SocketError error)
{
    QString errorString = _webSocket->errorString();
    qCWarning(WebRTCLinkLog) << "WebSocket error:" << errorString;
    emit errorOccurred(errorString);
    emit rtcStatusMessageChanged(errorString);
}

void WebRTCWorker::_onWebSocketMessageReceived(const QString& message)
{
    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(message.toUtf8(), &parseError);

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

    // if (remoteId != _config->peerId()) {
    //     return;
    // }

    try {
        if (type == "offer") {
            qCCritical(WebRTCLinkLog) << "[SIGNALING] Processing OFFER as answerer";

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
                qCCritical(WebRTCLinkLog) << "[OFFER] Processing failed:" << e.what();

                // 실패 시 재시도 로직
                QTimer::singleShot(1000, this, [this, message]() {
                    qCDebug(WebRTCLinkLog) << "[OFFER] Retrying after failure";
                    _setupPeerConnection();
                });
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

    _cleanupForReconnection();

    emit rttUpdated(-1);
    emit disconnected();
    emit rtcStatusMessageChanged("기체 연결 해제됨, 재연결 대기중");

    qCDebug(WebRTCLinkLog) << "[DISCONNECT] Ready for reconnection";
}

void WebRTCWorker::_cleanupForReconnection()
{
    qCDebug(WebRTCLinkLog) << "[CLEANUP] Cleaning up for reconnection (keeping WebSocket)";

    if (_mavlinkDataChannel) {
        try {
            if (_mavlinkDataChannel->isOpen()) {
                _mavlinkDataChannel->close();
            }
        } catch (const std::exception& e) {
            qCWarning(WebRTCLinkLog) << "Error closing data channel:" << e.what();
        }
        _mavlinkDataChannel.reset();
    }

    if (_customDataChannel) {
        try {
            if (_customDataChannel->isOpen()) {
                _customDataChannel->close();
            }
        } catch (const std::exception& e) {
            qCWarning(WebRTCLinkLog) << "Error closing data channel:" << e.what();
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

    _cleanupVideoBridge();
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
    if (!_signalingConnected) {
        qCWarning(WebRTCLinkLog) << "Cannot send signaling message: not connected";
        return;
    }

    QJsonDocument doc(message);
    _webSocket->sendTextMessage(doc.toJson(QJsonDocument::Compact));
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
    qCDebug(WebRTCLinkLog) << "[DEBUG] PeerConnection State Changed:" << stateStr;

    emit rtcStatusMessageChanged(stateStr);

    if (state == rtc::PeerConnection::State::Connected) {
        qCDebug(WebRTCLinkLog) << "[DEBUG] PeerConnection fully connected!";
        if (_mavlinkDataChannel && _mavlinkDataChannel->isOpen()) {
            qCDebug(WebRTCLinkLog) << "DataChannel already open, no reconnection needed";
            return;
        }
    }

    if ((state == rtc::PeerConnection::State::Failed ||
         state == rtc::PeerConnection::State::Disconnected) && !_isDisconnecting) {
        qCDebug(WebRTCLinkLog) << "[DEBUG] PeerConnection failed/disconnected – scheduling reconnect";

        QTimer::singleShot(1000, this, [this]() {
            _cleanup();
            _setupPeerConnection();
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
    _isShuttingDown.store(true);
    _isDisconnecting = true;
    _dataChannelOpened.store(false);

    qCDebug(WebRTCLinkLog) << "Cleaning up WebRTC resources";

    // 통계 타이머 정리
    if (_statsTimer) {
        _statsTimer->stop();
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

    if (_mavlinkDataChannel) {
        try {
            if (_mavlinkDataChannel->isOpen()) {
                _mavlinkDataChannel->close();
            }
        } catch (const std::exception& e) {
            qCWarning(WebRTCLinkLog) << "Error closing data channel:" << e.what();
        }
        _mavlinkDataChannel.reset();
    }

    if (_customDataChannel) {
        try {
            if (_customDataChannel->isOpen()) {
                _customDataChannel->close();
            }
        } catch (const std::exception& e) {
            qCWarning(WebRTCLinkLog) << "Error closing data channel:" << e.what();
        }
        _customDataChannel.reset();
    }

    if (_rttTimer) {
        _rttTimer->stop();
        _rttTimer->deleteLater();
        _rttTimer = nullptr;
    }

    _cleanupVideoBridge();

    _remoteDescriptionSet = false;
    _pendingCandidates.clear();
}

void WebRTCWorker::_cleanupComplete()
{
    _cleanup();

    if (_webSocket && _webSocket->state() != QAbstractSocket::UnconnectedState) {
        _webSocket->close();
    }
    _signalingConnected = false;
}

void WebRTCWorker::_createVideoBridge()
{
    QMutexLocker locker(&_videoBridgeMutex);
    if (_videoBridge || _isShuttingDown.load()) {
        return;
    }

    _videoBridge = new WebRTCVideoBridge(this);

    // 시그널 연결
    connect(_videoBridge, &WebRTCVideoBridge::bridgeStarted,
            this, [this](quint16 port) {
                if (!_isShuttingDown.load()) {
                    QMutexLocker locker(&_videoBridgeMutex);
                    _currentVideoURI = QString("udp://127.0.0.1:%1").arg(port);
                    _videoStreamActive = true;
                    qCDebug(WebRTCLinkLog) << "Video bridge started on port:" << port;
                }
            }, Qt::QueuedConnection);

    connect(_videoBridge, &WebRTCVideoBridge::bridgeStopped,
            this, [this]() {
                QMutexLocker locker(&_videoBridgeMutex);
                _videoStreamActive = false;
                _currentVideoURI.clear();
                qCDebug(WebRTCLinkLog) << "Video bridge stopped";
            }, Qt::QueuedConnection);

    connect(_videoBridge, &WebRTCVideoBridge::errorOccurred,
            this, [this](const QString& error) {
                if (!_isShuttingDown.load()) {
                    qCWarning(WebRTCLinkLog) << "[Video] Bridge error (isolated):" << error;

                    if (_mavlinkDataChannel && _mavlinkDataChannel->isOpen()) {
                        qCDebug(WebRTCLinkLog) << "[Video] DataChannel OK, retrying video only";
                        QTimer::singleShot(3000, this, [this]() {
                            if (_mavlinkDataChannel && _mavlinkDataChannel->isOpen()) {
                                _restartVideoBridge();
                            }
                        });
                    }
                }
            }, Qt::QueuedConnection);

    connect(_videoBridge, &WebRTCVideoBridge::retryBridgeRequested,
            this, [this]() {
                if (!_isShuttingDown.load()) {
                    QTimer::singleShot(1000, this, [this]() {
                        _restartVideoBridge();
                    });
                }
            }, Qt::QueuedConnection);

    QTimer::singleShot(0, this, [this]() {
        QMutexLocker locker(&_videoBridgeMutex);
        if (!_isShuttingDown.load() && _videoBridge) {
            if (!_videoBridge->startBridge(55000)) {
                qCCritical(WebRTCLinkLog) << "Failed to start video bridge";
                delete _videoBridge;
                _videoBridge = nullptr;
            }
        }
    });
}

void WebRTCWorker::_restartVideoBridge()
{
    {
        QMutexLocker locker(&_videoBridgeMutex);

        if (_videoBridge) {
            disconnect(_videoBridge, nullptr, this, nullptr);
            _videoBridge->stopBridge();
            _videoBridge->deleteLater();
            _videoBridge = nullptr;
        }

        _videoStreamActive = false;
        _currentVideoURI.clear();
    }

    _createVideoBridge();
}

void WebRTCWorker::_cleanupVideoBridge()
{
    QMutexLocker locker(&_videoBridgeMutex);
    WebRTCVideoBridge* bridge = _videoBridge;
    _videoBridge = nullptr;

    if (bridge) {
        QMetaObject::invokeMethod(bridge, [bridge]() {
            bridge->stopBridge();
            bridge->deleteLater();
        }, Qt::QueuedConnection);
    }

    _videoStreamActive = false;
    _currentVideoURI.clear();
}

void WebRTCWorker::_handleVideoTrackData(const rtc::binary& data)
{
    if (_isShuttingDown.load() || !_videoStreamActive) {
        return;
    }

    _videoReceivedCalc.addData(data.size());

    if(_videoBridge) {
        _videoBridge->forwardRTPData(data);
    }

    // QByteArray rtpData(reinterpret_cast<const char*>(data.data()), data.size());
    // QPointer<WebRTCWorker> weakSelf(this);
    // QMetaObject::invokeMethod(this, [weakSelf, rtpData]() {
    //     if (weakSelf && !weakSelf->_isShuttingDown.load()) {
    //         QMutexLocker locker(&weakSelf->_videoBridgeMutex);
    //         WebRTCVideoBridge* bridge = weakSelf->_videoBridge;
    //         if (bridge && weakSelf->_videoStreamActive) {
    //             bridge->forwardRTPData(rtpData);
    //         }
    //     }
    // }, Qt::QueuedConnection);
}

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
    _worker = new WebRTCWorker(_rtcConfig);
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

    connect(_worker, &WebRTCWorker::videoBridgeError, this, &WebRTCLink::_onVideoBridgeError, Qt::QueuedConnection);
    connect(_worker, &WebRTCWorker::videoRateChanged, this, &WebRTCLink::_onVideoRateChanged, Qt::QueuedConnection);

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
    _onRtcStatusMessageChanged("RTC 연결 해제됨");
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

QString WebRTCLink::videoStreamUri() const
{
    return _worker ? _worker->currentVideoUri() : QString();
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

void WebRTCLink::sendCustomMessage(QString message)
{
    if (_worker) {
        QMetaObject::invokeMethod(_worker, "sendCustomMessage",
                                  Qt::QueuedConnection,
                                  Q_ARG(QString, message));
    } else {
        qCWarning(WebRTCLinkLog) << "Cannot send custom message: worker not available";
    }
}
