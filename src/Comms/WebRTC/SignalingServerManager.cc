#include "SignalingServerManager.h"
#include <QDebug>
#include <QUrl>
#include <QRegularExpression>
#include <QDateTime>
#include <QRandomGenerator>
#include <QtCore/QApplicationStatic>
#include "QGCLoggingCategory.h"
#include "SettingsManager.h"
#include "CloudSettings.h"

QGC_LOGGING_CATEGORY(SignalingServerManagerLog, "qgc.comms.signaling")

Q_APPLICATION_STATIC(SignalingServerManager, _signalingServerManagerInstance);

SignalingServerManager* SignalingServerManager::instance()
{
    // LinkManager와 동일한 패턴: 단순한 싱글톤 접근
    // QGCApplication에서 메인 스레드에서만 호출되므로 스레드 안전성 보장됨
    return _signalingServerManagerInstance();
}

void SignalingServerManager::init()
{
    // LinkManager와 동일한 패턴: 메인 스레드에서만 실행
    qCDebug(SignalingServerManagerLog) << "SignalingServerManager initialized";
    
    // 프로그램 시작 시 자동으로 시그널링 서버에 WebSocket 연결 시작
    QTimer::singleShot(3000, this, [this]() {
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
    // LinkManager와 동일한 패턴: 생성자에서 메인 스레드 보장
    qCDebug(SignalingServerManagerLog) << "SignalingServerManager created";
    
    // 클라이언트 ID 자동 생성
    _generateClientId();
    
    _setupWebSocket();
    
    // 재연결 타이머 설정 (강화됨)
    _reconnectTimer = new QTimer(this);
    _reconnectTimer->setSingleShot(true);
    connect(_reconnectTimer, &QTimer::timeout, this, &SignalingServerManager::_onReconnectTimer);
    
    // 연결 모니터링 타이머 설정 (클라이언트 ping/pong 기반)
    _connectionHealthTimer = new QTimer(this);
    _connectionHealthTimer->setSingleShot(false);
    connect(_connectionHealthTimer, &QTimer::timeout, this, &SignalingServerManager::_onConnectionHealthTimer);
    
    // ping 타이머 설정
    _pingTimer = new QTimer(this);
    _pingTimer->setSingleShot(false);
    connect(_pingTimer, &QTimer::timeout, this, &SignalingServerManager::_onPingTimer);
    
    _updateConnectionState(ConnectionState::Disconnected);
    _updateConnectionStatus("초기화됨");
}

SignalingServerManager::~SignalingServerManager()
{
    qCDebug(SignalingServerManagerLog) << "SignalingServerManager destroyed";
    disconnectFromServer();
    _stopConnectionMonitoring();
    _cleanupWebSocket();
}

// === 핵심 기능 구현 ===

void SignalingServerManager::connectToServer(const QString &serverUrl, const QString &peerId, const QString &roomId)
{
    // LinkManager와 동일한 패턴: 메인 스레드에서만 실행되므로 스레드 체크 불필요
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
    // LinkManager와 동일한 패턴: 메인 스레드에서만 실행되므로 스레드 체크 불필요
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
    // LinkManager와 동일한 패턴: 메인 스레드에서만 실행되므로 스레드 체크 불필요
    qCDebug(SignalingServerManagerLog) << "Disconnecting from signaling server";
    
    _userDisconnected = true;
    _stopReconnectTimer();
    _stopConnectionMonitoring();
    
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
    
    // qCDebug(SignalingServerManagerLog) << "Sending message:" << message["type"].toString();
    
    qint64 bytesSent = _webSocket->sendTextMessage(jsonString);
    
    if (bytesSent == -1) {
        qCWarning(SignalingServerManagerLog) << "Failed to send message, WebSocket error:" << _webSocket->errorString();
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

    qCDebug(SignalingServerManagerLog) << "Retrying connection (attempt" << (_reconnectAttempts + 1) << "/" << MAX_RECONNECT_ATTEMPTS << ")";
    
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

    // 클라이언트 ID가 없으면 자동 생성
    if (_clientId.isEmpty()) {
        _generateClientId();
    }

    _webSocket = new QWebSocket(_clientId, QWebSocketProtocol::VersionLatest, this);

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
    
    int delay = _calculateReconnectDelay();
    _updateConnectionStatus(QString("재연결 시도 중... (%1초 후, 시도 %2/%3)").arg(delay / 1000).arg(_reconnectAttempts + 1).arg(MAX_RECONNECT_ATTEMPTS));
    
    qCDebug(SignalingServerManagerLog) << "Starting reconnect timer, delay:" << delay << "ms, attempt:" << (_reconnectAttempts + 1);
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
    qCDebug(SignalingServerManagerLog) << "WebSocket connected to signaling server with client ID:" << _clientId;
    
    _lastSuccessfulConnection = QDateTime::currentMSecsSinceEpoch();
    _resetReconnectAttempts();
    _updateConnectionState(ConnectionState::Connected);
    
    // 연결 모니터링 시작
    _startConnectionMonitoring();
    
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
    
    // 연결 모니터링 중지
    _stopConnectionMonitoring();
    
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
    
    // 연결 모니터링 중지
    _stopConnectionMonitoring();
    
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
        qCWarning(SignalingServerManagerLog) << "Parsed message object:" << messageObj;
        return;
    }
    
    QString messageType = messageObj["type"].toString();
    
    if (messageType == "registered") {
        _handleRegistrationResponse(messageObj);
    } else if (messageType == "left") {
        _handleLeaveResponse(messageObj);
    } else if (messageType == "pong") {
        _handlePongResponse(messageObj);
    } else if (messageType == "connectionReplaced") {
        qCDebug(SignalingServerManagerLog) << "Ignoring connectionReplaced message";
        _updateConnectionStatus("연결 대체 무시됨 - WebSocket 연결 유지");
    } else if (messageType == "error") {
        qCWarning(SignalingServerManagerLog) << "Received error message from server:" << messageObj;
    } else {
        qCDebug(SignalingServerManagerLog) << "Unknown message type:" << messageType << "Full message:" << messageObj;
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
        
        // 등록 실패 시 재연결 시도 (서버 문제일 수 있음)
        if (!_userDisconnected && _reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
            qCDebug(SignalingServerManagerLog) << "Registration failed, attempting reconnection";
            _reconnectAttempts++;
            _startReconnectTimer();
        }
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

void SignalingServerManager::sendPing()
{
    if (isConnected() && !_userDisconnected) {
        _sendPing();
    }
}

void SignalingServerManager::_sendPing()
{
    if (!isConnected() || _userDisconnected || _waitingForPong) {
        return;
    }
    
    qint64 currentTime = QDateTime::currentMSecsSinceEpoch();
    
    QJsonObject pingMessage;
    pingMessage["type"] = "ping";
    pingMessage["timestamp"] = currentTime;
    
    qCDebug(SignalingServerManagerLog) << "Sending ping to server";
    sendMessage(pingMessage);
    
    _lastPingSent = currentTime;
    _waitingForPong = true;
}

void SignalingServerManager::_handlePongResponse(const QJsonObject &message)
{
    qint64 currentTime = QDateTime::currentMSecsSinceEpoch();
    _lastPongReceived = currentTime;
    _waitingForPong = false;
    _consecutivePingFailures = 0; // pong을 받았으므로 연결 상태 양호
    
    qint64 pingLatency = currentTime - _lastPingSent;
    qCDebug(SignalingServerManagerLog) << "Received pong from server, latency:" << pingLatency << "ms";
}

void SignalingServerManager::_startConnectionMonitoring()
{
    // LinkManager와 동일한 패턴: 메인 스레드에서만 실행되므로 스레드 체크 불필요
    if (_connectionHealthTimer) {
        _connectionHealthTimer->start(CONNECTION_HEALTH_CHECK_MS);
    }
    
    if (_pingTimer) {
        _pingTimer->start(PING_INTERVAL_MS);
    }
    
    _consecutivePingFailures = 0;
    _waitingForPong = false;
    
    qCDebug(SignalingServerManagerLog) << "Connection monitoring started (client ping/pong based)";
}

void SignalingServerManager::_stopConnectionMonitoring()
{
    // LinkManager와 동일한 패턴: 메인 스레드에서만 실행되므로 스레드 체크 불필요
    if (_connectionHealthTimer && _connectionHealthTimer->isActive()) {
        _connectionHealthTimer->stop();
    }
    
    if (_pingTimer && _pingTimer->isActive()) {
        _pingTimer->stop();
    }
    
    _consecutivePingFailures = 0;
    _waitingForPong = false;
    
    qCDebug(SignalingServerManagerLog) << "Connection monitoring stopped";
}

void SignalingServerManager::_checkConnectionHealth()
{
    if (!isConnected() || _userDisconnected) {
        return;
    }

    qint64 currentTime = QDateTime::currentMSecsSinceEpoch();
    
    // ping 타임아웃 체크 (pong 응답을 10초 이상 받지 않으면 연결 문제로 간주)
    if (_waitingForPong && (currentTime - _lastPingSent) > PING_TIMEOUT_MS) {
        _consecutivePingFailures++;
        qCWarning(SignalingServerManagerLog) << "Ping timeout, consecutive failures:" << _consecutivePingFailures;
        
        if (_consecutivePingFailures >= MAX_CONSECUTIVE_PING_FAILURES) {
            qCWarning(SignalingServerManagerLog) << "Too many consecutive ping failures, forcing reconnection";
            _updateConnectionStatus("서버 연결 상태 불량 - 재연결 시도");
            _forceReconnection();
        } else {
            // 다시 ping 시도
            _sendPing();
        }
    }
}

void SignalingServerManager::_forceReconnection()
{
    qCDebug(SignalingServerManagerLog) << "Forcing reconnection due to connection health issues";
    
    if (_webSocket && _webSocket->state() != QAbstractSocket::UnconnectedState) {
        _webSocket->close();
    }
    
    _reconnectAttempts = 0; // 강제 재연결이므로 시도 횟수 리셋
    _startReconnectTimer();
}

void SignalingServerManager::_onPingTimer()
{
    if (isConnected() && !_userDisconnected && !_waitingForPong) {
        _sendPing();
    }
}

void SignalingServerManager::_onConnectionHealthTimer()
{
    _checkConnectionHealth();
}

int SignalingServerManager::_calculateReconnectDelay() const
{
    // 지수 백오프 전략: 2^attempt * base_delay, 최대 30초
    int baseDelay = DEFAULT_RECONNECT_INTERVAL_MS;
    int delay = baseDelay * (1 << _reconnectAttempts);
    
    // 최대 지연 시간 제한
    if (delay > MAX_RECONNECT_DELAY_MS) {
        delay = MAX_RECONNECT_DELAY_MS;
    }
    
    // 약간의 랜덤성 추가 (네트워크 혼잡 방지)
    int jitter = (QRandomGenerator::global()->bounded(1000)) - 500; // -500ms ~ +500ms
    delay += jitter;
    
    if (delay < 1000) delay = 1000; // 최소 1초
    
    return delay;
}

void SignalingServerManager::_resetReconnectAttempts()
{
    _reconnectAttempts = 0;
    qCDebug(SignalingServerManagerLog) << "Reconnect attempts reset";
}

void SignalingServerManager::setClientId(const QString &clientId)
{
    if (_clientId != clientId) {
        _clientId = clientId;
        qCDebug(SignalingServerManagerLog) << "Client ID set to:" << _clientId;
        
        // WebSocket이 이미 생성되어 있다면 새로운 ID로 재생성
        if (_webSocket) {
            _cleanupWebSocket();
            _setupWebSocket();
        }
    }
}

void SignalingServerManager::_generateClientId()
{
    // 타임스탬프 + 랜덤 숫자로 고유 ID 생성
    qint64 timestamp = QDateTime::currentMSecsSinceEpoch();
    int randomNum = QRandomGenerator::global()->bounded(10000);
    _clientId = QString("app_client_%1_%2").arg(timestamp).arg(randomNum);
    
    qCDebug(SignalingServerManagerLog) << "Generated client ID:" << _clientId;
}

void SignalingServerManager::_autoReRegister()
{
    if (!_webSocketOnlyMode && !_peerId.isEmpty() && !_roomId.isEmpty()) {
        qCDebug(SignalingServerManagerLog) << "Auto re-registering peer after reconnection";
        registerPeer(_peerId, _roomId);
    }
}

// 클라이언트 ping/pong 기반 연결 모니터링 완료
