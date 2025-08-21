#include "SignalingServerManager.h"
#include <QDebug>
#include <QUrl>
#include <QRegularExpression>
#include <QtCore/QApplicationStatic>
#include "QGCLoggingCategory.h"
#include "SettingsManager.h"
#include "CloudSettings.h"

QGC_LOGGING_CATEGORY(SignalingServerManagerLog, "qgc.comms.signaling")

Q_APPLICATION_STATIC(SignalingServerManager, _signalingServerManagerInstance);

SignalingServerManager* SignalingServerManager::instance()
{
    return _signalingServerManagerInstance();
}

void SignalingServerManager::init()
{
    qCDebug(SignalingServerManagerLog) << "SignalingServerManager initialized";
    
    // 프로그램 시작 시 자동으로 시그널링 서버에 WebSocket 연결 시작
    QTimer::singleShot(2000, this, [this]() {
        qCDebug(SignalingServerManagerLog) << "Starting automatic WebSocket connection to signaling server";
        _serverUrl = SettingsManager::instance()->cloudSettings()->webrtcSignalingServer()->rawValue().toString();
        connectToServerWebSocketOnly(_serverUrl);
    });
}

void SignalingServerManager::shutdown()
{
    if (_signalingServerManagerInstance.exists()) {
        qCDebug(SignalingServerManagerLog) << "Shutting down SignalingServerManager";
        _signalingServerManagerInstance()->disconnectFromServer();
    }
}

SignalingServerManager::SignalingServerManager(QObject *parent)
    : QObject(parent)
{
    qCDebug(SignalingServerManagerLog) << "SignalingServerManager created";
    
    _setupWebSocket();
    
    // 재연결 타이머 설정
    _reconnectTimer = new QTimer(this);
    _reconnectTimer->setSingleShot(true);
    connect(_reconnectTimer, &QTimer::timeout, this, &SignalingServerManager::_onReconnectTimer);
    
    _updateConnectionState(ConnectionState::Disconnected);
    _updateConnectionStatus("초기화됨");
}

SignalingServerManager::~SignalingServerManager()
{
    qCDebug(SignalingServerManagerLog) << "SignalingServerManager destroyed";
    disconnectFromServer();
    _cleanupWebSocket();
}

// === 핵심 기능 구현 ===

void SignalingServerManager::connectToServer(const QString &serverUrl, const QString &peerId, const QString &roomId)
{
    if (serverUrl.isEmpty() || peerId.isEmpty() || roomId.isEmpty()) {
        qCWarning(SignalingServerManagerLog) << "Invalid parameters for connection";
        emit connectionError("연결 매개변수가 올바르지 않습니다");
        return;
    }

    if (_connectionState == ConnectionState::Connected || _connectionState == ConnectionState::Connecting) {
        qCWarning(SignalingServerManagerLog) << "Already connected or connecting";
        return;
    }

    _serverUrl = serverUrl;
    _peerId = peerId;
    _roomId = roomId;
    _webSocketOnlyMode = false;
    _userDisconnected = false;
    _reconnectAttempts = 0;

    qCDebug(SignalingServerManagerLog) << "Connecting to signaling server with room:" << _serverUrl;
    _updateConnectionState(ConnectionState::Connecting);
    _updateConnectionStatus("시그널링 서버 연결 중...");

    if (!_isValidUrl(_serverUrl)) {
        qCWarning(SignalingServerManagerLog) << "Invalid server URL:" << _serverUrl;
        emit connectionError("잘못된 서버 URL입니다");
        _updateConnectionState(ConnectionState::Error);
        return;
    }

    QString wsUrl = _formatWebSocketUrl(_serverUrl);
    qCDebug(SignalingServerManagerLog) << "WebSocket URL:" << wsUrl;
    
    _webSocket->open(QUrl(wsUrl));
}

void SignalingServerManager::connectToServerWebSocketOnly(const QString &serverUrl)
{
    if (serverUrl.isEmpty()) {
        qCWarning(SignalingServerManagerLog) << "Invalid server URL for WebSocket-only connection";
        emit connectionError("WebSocket 연결을 위한 서버 URL이 올바르지 않습니다");
        return;
    }

    if (_connectionState == ConnectionState::Connected || _connectionState == ConnectionState::Connecting) {
        qCWarning(SignalingServerManagerLog) << "Already connected or connecting";
        return;
    }

    _serverUrl = serverUrl;
    _peerId.clear();
    _roomId.clear();
    _webSocketOnlyMode = true;
    _userDisconnected = false;
    _reconnectAttempts = 0;

    qCDebug(SignalingServerManagerLog) << "Connecting to signaling server (WebSocket only):" << _serverUrl;
    _updateConnectionState(ConnectionState::Connecting);
    _updateConnectionStatus("시그널링 서버 WebSocket 연결 중...");

    if (!_isValidUrl(_serverUrl)) {
        qCWarning(SignalingServerManagerLog) << "Invalid server URL:" << _serverUrl;
        emit connectionError("잘못된 서버 URL입니다");
        _updateConnectionState(ConnectionState::Error);
        return;
    }

    QString wsUrl = _formatWebSocketUrl(_serverUrl);
    qCDebug(SignalingServerManagerLog) << "WebSocket URL:" << wsUrl;
    
    _webSocket->open(QUrl(wsUrl));
}

void SignalingServerManager::disconnectFromServer()
{
    qCDebug(SignalingServerManagerLog) << "Disconnecting from signaling server";
    
    _userDisconnected = true;
    _stopReconnectTimer();
    
    if (_webSocket && _webSocket->state() != QAbstractSocket::UnconnectedState) {
        _webSocket->close();
    }
    
    _updateConnectionState(ConnectionState::Disconnected);
    _updateConnectionStatus("연결 해제됨");
}

void SignalingServerManager::sendMessage(const QJsonObject &message)
{
    if (!isConnected()) {
        qCWarning(SignalingServerManagerLog) << "Cannot send message: not connected";
        return;
    }

    if (message.isEmpty()) {
        qCWarning(SignalingServerManagerLog) << "Cannot send empty message";
        return;
    }

    if (!_webSocket) {
        qCWarning(SignalingServerManagerLog) << "Cannot send message: WebSocket is null";
        return;
    }

    QJsonDocument doc(message);
    QString jsonString = doc.toJson(QJsonDocument::Compact);
    
    qCDebug(SignalingServerManagerLog) << "Sending message:" << message["type"].toString();
    
    qint64 bytesSent = _webSocket->sendTextMessage(jsonString);
    
    if (bytesSent == -1) {
        qCWarning(SignalingServerManagerLog) << "Failed to send message, WebSocket error:" << _webSocket->errorString();
    } else {
        qCDebug(SignalingServerManagerLog) << "Message sent successfully, bytes:" << bytesSent;
    }
    
    emit messageSent(message);
}

void SignalingServerManager::registerPeer(const QString &peerId, const QString &roomId)
{
    qCDebug(SignalingServerManagerLog) << "Registering peer:" << peerId << " in room:" << roomId;
    
    _peerId = peerId;
    _roomId = roomId;
    _webSocketOnlyMode = false;
    
    if (isConnected()) {
        QJsonObject registerMessage;
        registerMessage["type"] = "register";
        registerMessage["id"] = _peerId;
        registerMessage["roomId"] = _roomId;
        
        qCDebug(SignalingServerManagerLog) << "Sending registration message";
        sendMessage(registerMessage);
        
        _updateConnectionStatus("Room 등록 중...");

    } else {
        qCDebug(SignalingServerManagerLog) << "Not connected, establishing WebSocket connection first";
        connectToServerWebSocketOnly(_serverUrl);
    }
}

void SignalingServerManager::leavePeer(const QString &peerId, const QString &roomId)
{
    if (!isConnected()) { return; }

    QJsonObject leaveMessage;
    leaveMessage["type"] = "leave";
    leaveMessage["id"] = peerId;
    leaveMessage["roomId"] = roomId;
    sendMessage(leaveMessage);
    
    qCDebug(SignalingServerManagerLog) << "Leaving room:" << roomId << "with peer ID:" << peerId;
}

void SignalingServerManager::retryConnection()
{
    if (_userDisconnected) {
        qCDebug(SignalingServerManagerLog) << "User disconnected, not retrying";
        return;
    }

    if (_connectionState == ConnectionState::Connected || _connectionState == ConnectionState::Connecting) {
        qCDebug(SignalingServerManagerLog) << "Already connected or connecting, not retrying";
        return;
    }

    qCDebug(SignalingServerManagerLog) << "Retrying connection (attempt" << (_reconnectAttempts + 1) << ")";
    
    if (_webSocketOnlyMode) {
        connectToServerWebSocketOnly(_serverUrl);
    } else {
        connectToServer(_serverUrl, _peerId, _roomId);
    }
}

// === 내부 구현 ===

void SignalingServerManager::_setupWebSocket()
{
    if (_webSocket) {
        return;
    }

    _webSocket = new QWebSocket(QString(), QWebSocketProtocol::VersionLatest, this);

    connect(_webSocket, &QWebSocket::connected, 
            this, &SignalingServerManager::_onWebSocketConnected);
    connect(_webSocket, &QWebSocket::disconnected, 
            this, &SignalingServerManager::_onWebSocketDisconnected);
    connect(_webSocket, &QWebSocket::errorOccurred,
            this, &SignalingServerManager::_onWebSocketError);
    connect(_webSocket, &QWebSocket::textMessageReceived, 
            this, &SignalingServerManager::_onWebSocketMessageReceived);
}

void SignalingServerManager::_cleanupWebSocket()
{
    if (_webSocket) {
        _webSocket->disconnect();
        if (_webSocket->state() != QAbstractSocket::UnconnectedState) {
            _webSocket->close();
        }
        delete _webSocket;
        _webSocket = nullptr;
    }
}

void SignalingServerManager::_updateConnectionState(ConnectionState newState)
{
    if (_connectionState != newState) {
        ConnectionState oldState = _connectionState;
        _connectionState = newState;
        
        qCDebug(SignalingServerManagerLog) << "Connection state changed:" 
                                          << static_cast<int>(oldState) << "->" << static_cast<int>(newState);
        
        emit connectionStateChanged(newState);
        
        if (newState == ConnectionState::Connected) {
            emit connected();
        } else if (oldState == ConnectionState::Connected && newState != ConnectionState::Connected) {
            emit disconnected();
        }
    }
}

void SignalingServerManager::_updateConnectionStatus(const QString &status)
{
    if (_connectionStatusMessage != status) {
        _connectionStatusMessage = status;
        emit connectionStatusChanged(status);
        qCDebug(SignalingServerManagerLog) << "Status:" << status;
    }
}

void SignalingServerManager::_startReconnectTimer()
{
    if (_userDisconnected) {
        return;
    }

    if (_reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
        qCWarning(SignalingServerManagerLog) << "Max reconnection attempts reached";
        _updateConnectionState(ConnectionState::Error);
        _updateConnectionStatus("최대 재연결 시도 횟수 초과");
        emit connectionError("최대 재연결 시도 횟수를 초과했습니다");
        return;
    }

    _updateConnectionState(ConnectionState::Reconnecting);
    
    int delay = DEFAULT_RECONNECT_INTERVAL_MS * (1 + _reconnectAttempts);
    _updateConnectionStatus(QString("재연결 시도 중... (%1초 후)").arg(delay / 1000));
    
    qCDebug(SignalingServerManagerLog) << "Starting reconnect timer, delay:" << delay << "ms";
    _reconnectTimer->start(delay);
}

void SignalingServerManager::_stopReconnectTimer()
{
    if (_reconnectTimer && _reconnectTimer->isActive()) {
        _reconnectTimer->stop();
        qCDebug(SignalingServerManagerLog) << "Reconnect timer stopped";
    }
}

void SignalingServerManager::_onWebSocketConnected()
{
    qCDebug(SignalingServerManagerLog) << "WebSocket connected to signaling server";
    
    _reconnectAttempts = 0;
    _updateConnectionState(ConnectionState::Connected);
    
    if (_webSocketOnlyMode) {
        _updateConnectionStatus("시그널링 서버 연결됨 - WebRTC 대기 중");
        qCDebug(SignalingServerManagerLog) << "WebSocket-only mode: Ready for room registration";
    } else {
        _updateConnectionStatus("시그널링 서버 연결됨 - Peer 등록 중");
        
        if (!_peerId.isEmpty() && !_roomId.isEmpty()) {
            QJsonObject registerMessage;
            registerMessage["type"] = "register";
            registerMessage["id"] = _peerId;
            registerMessage["roomId"] = _roomId;
            
            qCDebug(SignalingServerManagerLog) << "Auto-sending registration after connection";
            sendMessage(registerMessage);
        }
    }
}

void SignalingServerManager::_onWebSocketDisconnected()
{
    qCDebug(SignalingServerManagerLog) << "WebSocket disconnected from signaling server";
    
    if (_connectionState == ConnectionState::Connected) {
        _updateConnectionStatus("시그널링 서버 연결 끊어짐");
    }
    
    if (!_userDisconnected) {
        _reconnectAttempts++;
        _startReconnectTimer();
    } else {
        _updateConnectionState(ConnectionState::Disconnected);
        _updateConnectionStatus("시그널링 서버 연결 해제됨");
    }
}

void SignalingServerManager::_onWebSocketError(QAbstractSocket::SocketError error)
{
    QString errorString = _webSocket->errorString();
    qCWarning(SignalingServerManagerLog) << "WebSocket error:" << error << errorString;
    
    _updateConnectionState(ConnectionState::Error);
    _updateConnectionStatus(QString("시그널링 서버 연결 실패: %1").arg(errorString));
    
    emit connectionError(errorString);
    
    if (!_userDisconnected) {
        _reconnectAttempts++;
        _startReconnectTimer();
    }
}

void SignalingServerManager::_onWebSocketMessageReceived(const QString &message)
{
    qCDebug(SignalingServerManagerLog) << "Message received, length:" << message.length();
    
    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(message.toUtf8(), &parseError);
    
    if (parseError.error != QJsonParseError::NoError) {
        qCWarning(SignalingServerManagerLog) << "Failed to parse message:" << parseError.errorString();
        return;
    }
    
    QJsonObject messageObj = doc.object();
    
    if (!messageObj.contains("type")) {
        qCWarning(SignalingServerManagerLog) << "Message missing 'type' field";
        return;
    }
    
    QString messageType = messageObj["type"].toString();
    qCDebug(SignalingServerManagerLog) << "Received message type:" << messageType;
    
    if (messageType == "registered") {
        _handleRegistrationResponse(messageObj);
    } else if (messageType == "left") {
        _handleLeaveResponse(messageObj);
    } else if (messageType == "connectionReplaced") {
        qCDebug(SignalingServerManagerLog) << "Ignoring connectionReplaced message";
        _updateConnectionStatus("연결 대체 무시됨 - WebSocket 연결 유지");
    } else if (messageType == "error") {
        qCWarning(SignalingServerManagerLog) << "Received error message from server:" << messageObj;
    }
    
    emit messageReceived(messageObj);
}

void SignalingServerManager::_onReconnectTimer()
{
    qCDebug(SignalingServerManagerLog) << "Reconnect timer triggered";
    retryConnection();
}

void SignalingServerManager::_handleRegistrationResponse(const QJsonObject &message)
{    
    if (message.contains("success") && message["success"].toBool()) {
        qCDebug(SignalingServerManagerLog) << "Registration successful";
        _updateConnectionStatus("등록 완료 - 피어 대기 중");
        emit registrationSuccessful();
    } else {
        QString reason = message["reason"].toString();
        qCWarning(SignalingServerManagerLog) << "Registration failed:" << reason;
        _updateConnectionStatus(QString("등록 실패: %1").arg(reason));
        emit registrationFailed(reason);
    }
}

void SignalingServerManager::_handleLeaveResponse(const QJsonObject &message)
{
    QString peerId = message["id"].toString();
    QString roomId = message["roomId"].toString();
    
    if (message.contains("success") && message["success"].toBool()) {
        qCDebug(SignalingServerManagerLog) << "Successfully left room:" << roomId << "with peer:" << peerId;
        _updateConnectionStatus("Room에서 나감 - WebSocket 연결 유지됨");
        emit peerLeftSuccessfully(peerId, roomId);
    } else {
        QString reason = message["reason"].toString();
        qCWarning(SignalingServerManagerLog) << "Failed to leave room:" << reason;
        emit peerLeaveFailed(peerId, reason);
    }
}

QString SignalingServerManager::_formatWebSocketUrl(const QString &baseUrl) const
{
    QString url = baseUrl;
    
    if (!url.startsWith("ws://") && !url.startsWith("wss://")) {
        url = "wss://" + url;
    }
    
    if (!url.contains(":") || url.count(":") == 1) {
        url += ":3000";
    }
    
    return url;
}

bool SignalingServerManager::_isValidUrl(const QString &url) const
{
    if (url.isEmpty()) {
        return false;
    }
    
    QUrl qurl(url);
    return qurl.isValid() || QRegularExpression(R"(^[\w\.-]+$)").match(url).hasMatch();
}
