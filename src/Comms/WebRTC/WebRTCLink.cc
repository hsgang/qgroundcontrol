#include "WebRTCLink.h"
#include <QDebug>
#include <QUrl>

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
      , _signalingPort(copy->_signalingPort)
      , _stunServer(copy->_stunServer)
      , _stunPort(copy->_stunPort)
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
        _signalingPort = src->_signalingPort;
        _stunServer = src->_stunServer;
        _stunPort = src->_stunPort;
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
    _targetPeerId = settings.value("targetPeerId", "peer2").toString();
    _signalingServer = settings.value("signalingServer", "ampkorea.duckdns.org").toString();
    _signalingPort = settings.value("signalingPort", 3000).toInt();
    _stunServer = settings.value("stunServer", "stun.l.google.com").toString();
    _stunPort = settings.value("stunPort", 19302).toInt();
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
    settings.setValue("signalingPort", _signalingPort);
    settings.setValue("stunServer", _stunServer);
    settings.setValue("stunPort", _stunPort);
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

void WebRTCConfiguration::setSignalingPort(int port)
{
    if (_signalingPort != port) {
        _signalingPort = port;
        emit signalingPortChanged();
    }
}

void WebRTCConfiguration::setStunServer(const QString &url)
{
    if (_stunServer != url) {
        _stunServer = url;
        emit stunServerChanged();
    }
}

void WebRTCConfiguration::setStunPort(int port)
{
    if (_stunPort != port) {
        _stunPort = port;
        emit stunPortChanged();
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
// WebRTCWorker Implementation
/*===========================================================================*/

WebRTCWorker::WebRTCWorker(const WebRTCConfiguration *config, QObject *parent)
    : QObject(parent)
      , _config(config)
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
}

void WebRTCWorker::_setupPeerConnection()
{
    // Configure ICE servers
    _rtcConfig.iceServers.clear();

    // Add STUN server
    if (!_config->stunServer().isEmpty()) {
        _rtcConfig.iceServers.emplace_back(_config->stunServer().toStdString());
        qCDebug(WebRTCLinkLog) << "STUN server configured:" << _config->stunServer().toStdString();
    }

    // Add TURN server
    if (!_config->turnServer().isEmpty()) {
        rtc::IceServer turnServer(_config->turnServer().toStdString());
        turnServer.username = _config->turnUsername().toStdString();
        turnServer.password = _config->turnPassword().toStdString();
        _rtcConfig.iceServers.emplace_back(turnServer);
        qCDebug(WebRTCLinkLog) << "TURN server configured:" << _config->turnServer().toStdString();
    }

    // Configure UDP mux
    _rtcConfig.enableIceUdpMux = _config->udpMuxEnabled();

    try {
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
            QJsonObject message;
            message["id"] = _config->peerId();
            message["to"] = _config->targetPeerId();
            message["type"] = QString::fromStdString(description.typeString());
            message["sdp"] = QString::fromStdString(description);
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

    dc->onMessage([this](auto data) {
        if (std::holds_alternative<rtc::binary>(data)) {
            const auto& binaryData = std::get<rtc::binary>(data);
            QByteArray byteArray(reinterpret_cast<const char*>(binaryData.data()), binaryData.size());
            emit bytesReceived(byteArray);
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

    qCDebug(WebRTCLinkLog) << "Received signaling message: " << message;

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

            auto answer = _peerConnection->createAnswer();
            _peerConnection->setLocalDescription(answer.type(), { std::string(answer) });
            // _peerConnection->createAnswer();
            QJsonObject answerMsg;
            answerMsg["type"] = "answer";
            answerMsg["sdp"]  = QString::fromStdString(answer);
            answerMsg["to"]   = _config->targetPeerId();  // peerDrone
            answerMsg["id"]   = _config->peerId();
            _sendSignalingMessage(answerMsg);

            _remoteDescriptionSet = true;
            _processPendingCandidates();

        } else if (type == "answer") {
            QString sdp = message["sdp"].toString();
            rtc::Description answer(sdp.toStdString(), "answer");
            _peerConnection->setRemoteDescription(answer);
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
        }
    } catch (const std::exception& e) {
        qCWarning(WebRTCLinkLog) << "Error handling signaling message:" << e.what();
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

    // 5초마다 라이브 스트림 통계 로깅
    auto *statsTimer = new QTimer(this);
    statsTimer->setInterval(5000);
    connect(statsTimer, &QTimer::timeout, this, [this]() {
        // RTT (nullptr 체크)
        auto rttOpt = _peerConnection->rtt();
        if (rttOpt.has_value()) {
            qCDebug(WebRTCLinkLog)
            << "STATS RTT:" << rttOpt.value().count() << "ms"
            << " Sent:" << _peerConnection->bytesSent()
            << " Recv:" << _peerConnection->bytesReceived();
        } else {
            qCDebug(WebRTCLinkLog) << "STATS RTT: n/a"
                                   << " Sent:" << _peerConnection->bytesSent()
                                   << " Recv:" << _peerConnection->bytesReceived();
        }
    });
    statsTimer->start();
}

void WebRTCWorker::_onDataChannelClosed()
{
    qCDebug(WebRTCLinkLog) << "Data channel closed";
    if (!_isDisconnecting) {
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
    qCDebug(WebRTCLinkLog) << "ICE gathering state changed:" << _gatheringStateToString(state);
}

QString WebRTCWorker::_stateToString(rtc::PeerConnection::State state) const
{
    switch (state) {
        case rtc::PeerConnection::State::New: return "New";
        case rtc::PeerConnection::State::Connecting: return "Connecting";
        case rtc::PeerConnection::State::Connected: return "Connected";
        case rtc::PeerConnection::State::Disconnected: return "Disconnected";
        case rtc::PeerConnection::State::Failed: return "Failed";
        case rtc::PeerConnection::State::Closed: return "Closed";
    }
    return "Unknown";
}

QString WebRTCWorker::_gatheringStateToString(rtc::PeerConnection::GatheringState state) const
{
    switch (state) {
        case rtc::PeerConnection::GatheringState::New: return "New";
        case rtc::PeerConnection::GatheringState::InProgress: return "InProgress";
        case rtc::PeerConnection::GatheringState::Complete: return "Complete";
    }
    return "Unknown";
}

void WebRTCWorker::_cleanup()
{
    _isDisconnecting = true;

    if (_dataChannel) {
        try {
            _dataChannel->close();
        } catch (...) {}
        _dataChannel.reset();
    }

    if (_peerConnection) {
        try {
            _peerConnection->close();
        } catch (...) {}
        _peerConnection.reset();
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
    emit connected();
}

void WebRTCLink::_onDisconnected()
{
    qDebug() << "[WebRTCLink] Disconnected";
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
