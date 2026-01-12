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

QGC_LOGGING_CATEGORY(SignalingServerManagerLog, "Comms.SignalingServerManager")

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

    // getDrones 타이머 설정
    _getDronesTimer = new QTimer(this);
    _getDronesTimer->setSingleShot(false);
    connect(_getDronesTimer, &QTimer::timeout, this, &SignalingServerManager::_sendGetDronesRequest);

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

void SignalingServerManager::connectToServer(const QString &serverUrl, const QString &gcsId, const QString &targetDroneId)
{
    // LinkManager와 동일한 패턴: 메인 스레드에서만 실행되므로 스레드 체크 불필요
    if (serverUrl.isEmpty() || gcsId.isEmpty()) {
        qCWarning(SignalingServerManagerLog) << "Invalid parameters for connection";
        emit connectionError("연결 매개변수가 올바르지 않습니다");
        return;
    }

    if (_connectionState == ConnectionState::Connected || _connectionState == ConnectionState::Connecting) {
        qCWarning(SignalingServerManagerLog) << "Already connected or connecting";
        return;
    }

    _serverUrl = serverUrl;
    _gcsId = gcsId;
    _targetDroneId = targetDroneId;
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
    _gcsId.clear();
    _targetDroneId.clear();
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

void SignalingServerManager::registerGCS(const QString &gcsId, const QString &targetDroneId)
{
    qCDebug(SignalingServerManagerLog) << "Registering GCS:" << gcsId << " with target drone:" << targetDroneId;
    
    _gcsId = gcsId;
    _targetDroneId = targetDroneId;
    _webSocketOnlyMode = false;
    
    if (isConnected()) {
        QJsonObject registerMessage;
        registerMessage["type"] = "register";
        registerMessage["id"] = _gcsId;
        registerMessage["deviceType"] = "gcs";
        registerMessage["targetDroneId"] = _targetDroneId;
        registerMessage["capabilities"] = QJsonArray::fromStringList({"telemetry", "webrtc", "control"});
        registerMessage["metadata"] = QJsonObject{
            {"model", "QGroundControl"},
            {"firmware", "1.0.0"},
            {"software", "QGroundControl"}
        };
        
        qCDebug(SignalingServerManagerLog) << "Sending GCS registration message";
        sendMessage(registerMessage);
        
        _updateConnectionStatus("GCS 등록 중...");

    } else {
        qCDebug(SignalingServerManagerLog) << "Not connected, establishing WebSocket connection first";
        connectToServerWebSocketOnly(_serverUrl);
    }
}

void SignalingServerManager::unregisterGCS(const QString &gcsId)
{
    if (!isConnected()) { return; }

    QJsonObject unregisterMessage;
    unregisterMessage["type"] = "unregister";
    unregisterMessage["id"] = gcsId;
    sendMessage(unregisterMessage);
    
    qCDebug(SignalingServerManagerLog) << "Unregistering GCS:" << gcsId;
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
        connectToServer(_serverUrl, _gcsId, _targetDroneId);
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
        qCDebug(SignalingServerManagerLog) << "User disconnected, skipping reconnection";
        return;
    }

    if (_reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
        qCWarning(SignalingServerManagerLog) << "Max reconnection attempts reached:" << _reconnectAttempts;
        _updateConnectionState(ConnectionState::Error);
        _updateConnectionStatus("최대 재연결 시도 횟수 초과");
        emit connectionError("최대 재연결 시도를 초과했습니다");
        return;
    }

    _updateConnectionState(ConnectionState::Reconnecting);
    
    int delay = _calculateReconnectDelay();
    _updateConnectionStatus(QString("재연결 시도 중... (%1초 후, 시도 %2/%3)").arg(delay / 1000).arg(_reconnectAttempts + 1).arg(MAX_RECONNECT_ATTEMPTS));
    
    qCDebug(SignalingServerManagerLog) << "Starting reconnect timer, delay:" << delay << "ms, attempt:" << (_reconnectAttempts + 1) << "/" << MAX_RECONNECT_ATTEMPTS;
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
        qCDebug(SignalingServerManagerLog) << "WebSocket-only mode: Ready for GCS registration";
    } else {
        _updateConnectionStatus("시그널링 서버 연결됨 - GCS 등록 중");
        
        if (!_gcsId.isEmpty()) {
            QJsonObject registerMessage;
            registerMessage["type"] = "register";
            registerMessage["id"] = _gcsId;
            registerMessage["deviceType"] = "gcs";
            registerMessage["targetDroneId"] = _targetDroneId;
            registerMessage["capabilities"] = QJsonArray::fromStringList({"telemetry", "webrtc", "control"});
            registerMessage["metadata"] = QJsonObject{
                {"model", "QGroundControl"},
                {"firmware", "1.0.0"},
                {"software", "QGroundControl"}
            };
            
            qCDebug(SignalingServerManagerLog) << "Auto-sending GCS registration after connection";
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
        
        // 연결이 너무 빨리 끊어지는지 확인 (연결 불안정성 체크)
        qint64 currentTime = QDateTime::currentMSecsSinceEpoch();
        if (_lastSuccessfulConnection > 0) {
            qint64 connectionDuration = currentTime - _lastSuccessfulConnection;
            if (connectionDuration < 10000) { // 10초 미만으로 연결이 유지된 경우
                qCWarning(SignalingServerManagerLog) << "Connection was unstable, duration:" << connectionDuration << "ms";
                // 불안정한 연결의 경우 재연결 간격을 늘림
                _reconnectAttempts = qMin(_reconnectAttempts + 2, MAX_RECONNECT_ATTEMPTS);
            }
        }
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
    } else if (messageType == "unregistered") {
        _handleUnregisterResponse(messageObj);
    } else if (messageType == "pong") {
        _handlePongResponse(messageObj);
    } else if (messageType == "connectionReplaced") {
        qCDebug(SignalingServerManagerLog) << "Ignoring connectionReplaced message";
        _updateConnectionStatus("연결 대체 무시됨 - WebSocket 연결 유지");
    } else if (messageType == "drones:list") {
        _handleDronesListResponse(messageObj);
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

void SignalingServerManager::_handleUnregisterResponse(const QJsonObject &message)
{
    QString gcsId = message["id"].toString();

    if (message.contains("success") && message["success"].toBool()) {
        qCDebug(SignalingServerManagerLog) << "Successfully unregistered GCS:" << gcsId;
        _updateConnectionStatus("GCS 등록 해제됨 - WebSocket 연결 유지됨");
        emit gcsUnregisteredSuccessfully(gcsId);
    } else {
        QString reason = message["reason"].toString();
        qCWarning(SignalingServerManagerLog) << "Failed to unregister GCS:" << reason;
        emit gcsUnregisterFailed(gcsId, reason);
    }
}

void SignalingServerManager::_handleDronesListResponse(const QJsonObject &message)
{
    // drones:list 응답 메시지 수신 및 로깅
    if (!message.contains("drones") || !message.contains("totalDrones")) {
        qCWarning(SignalingServerManagerLog) << "Invalid drones:list message format";
        return;
    }

    QJsonArray dronesArray = message["drones"].toArray();
    int totalDrones = message["totalDrones"].toInt();
    QString timestamp = message["timestamp"].toString();

    qCDebug(SignalingServerManagerLog) << "=== drones:list received ==="
                                       << "Total:" << totalDrones
                                       << "Timestamp:" << timestamp;

    // 드론 목록 업데이트
    QStringList newDronesList;
    for (int i = 0; i < dronesArray.size(); ++i) {
        QJsonObject drone = dronesArray[i].toObject();
        QString droneId = drone["id"].toString();
        QString status = drone["status"].toString();
        bool paired = drone["paired"].toBool();
        QString pairedWith = drone["pairedWith"].toString();
        int rtt = drone["rtt"].toInt();

        qCDebug(SignalingServerManagerLog) << "  [" << (i + 1) << "]"
                                           << "ID:" << droneId
                                           << "Status:" << status
                                           << "Paired:" << paired
                                           << "PairedWith:" << pairedWith
                                           << "RTT:" << rtt << "ms";

        if (!droneId.isEmpty() && status == "connected") {
            newDronesList.append(droneId);
        }
    }

    // 드론 목록이 변경된 경우에만 시그널 emit
    bool countChanged = (_connectedDronesCount != totalDrones);
    bool listChanged = (_connectedDronesList != newDronesList);

    if (countChanged) {
        qCDebug(SignalingServerManagerLog) << "[Signal] Emitting connectedDronesCountChanged:"
                                           << _connectedDronesCount << "->" << totalDrones;
        _connectedDronesCount = totalDrones;
        emit connectedDronesCountChanged();
    }

    if (listChanged) {
        qCDebug(SignalingServerManagerLog) << "[Signal] Emitting connectedDronesListChanged";
        qCDebug(SignalingServerManagerLog) << "  Old list:" << _connectedDronesList;
        qCDebug(SignalingServerManagerLog) << "  New list:" << newDronesList;
        _connectedDronesList = newDronesList;
        emit connectedDronesListChanged();
    }

    if (totalDrones == 0) {
        qCDebug(SignalingServerManagerLog) << "No drones currently connected";
    }
}

bool SignalingServerManager::isDroneConnected(const QString &droneId) const
{
    return _connectedDronesList.contains(droneId);
}

QString SignalingServerManager::_formatWebSocketUrl(const QString &baseUrl) const
{
    QString url = baseUrl;

    // wss:// 프로토콜 추가 (없는 경우)
    if (!url.startsWith("ws://") && !url.startsWith("wss://")) {
        url = "wss://" + url;
    }

    // 포트 번호 추가: wss:// 이후에만 포트를 확인
    QUrl qurl(url);
    if (qurl.port() == -1) {
        // 포트가 지정되지 않은 경우 :3000 추가
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

    if (_getDronesTimer) {
        _getDronesTimer->start(GET_DRONES_INTERVAL_MS);
        // 즉시 한 번 실행
        _sendGetDronesRequest();
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

    if (_getDronesTimer && _getDronesTimer->isActive()) {
        _getDronesTimer->stop();
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
    // 더 안정적인 재연결 전략: 선형 증가 + 지수 백오프
    int baseDelay = DEFAULT_RECONNECT_INTERVAL_MS;
    int delay;
    
    if (_reconnectAttempts <= 3) {
        // 처음 3번은 선형 증가
        delay = baseDelay + (_reconnectAttempts * 2000);
    } else {
        // 3번 이후는 지수 백오프
        delay = baseDelay * (1 << (_reconnectAttempts - 2));
    }
    
    // 최대 지연 시간 제한
    if (delay > MAX_RECONNECT_DELAY_MS) {
        delay = MAX_RECONNECT_DELAY_MS;
    }
    
    // 더 큰 랜덤성 추가 (네트워크 혼잡 방지)
    int jitter = (QRandomGenerator::global()->bounded(2000)) - 1000; // -1초 ~ +1초
    delay += jitter;
    
    if (delay < 3000) delay = 3000; // 최소 3초
    
    qCDebug(SignalingServerManagerLog) << "Calculated reconnect delay:" << delay << "ms for attempt:" << (_reconnectAttempts + 1);
    
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
    if (!_webSocketOnlyMode && !_gcsId.isEmpty()) {
        qCDebug(SignalingServerManagerLog) << "Auto re-registering GCS after reconnection";
        registerGCS(_gcsId, _targetDroneId);
    }
}

void SignalingServerManager::_sendGetDronesRequest()
{
    if (!isConnected() || _userDisconnected) {
        return;
    }

    QJsonObject getDronesMessage;
    getDronesMessage["type"] = "getDrones";

    qCDebug(SignalingServerManagerLog) << "Requesting drones list from server";
    sendMessage(getDronesMessage);
}

// 클라이언트 ping/pong 기반 연결 모니터링 완료
