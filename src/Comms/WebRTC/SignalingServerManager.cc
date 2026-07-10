#include "SignalingServerManager.h"
#include <QDebug>
#include <QUrl>
#include <QRegularExpression>
#include <QDateTime>
#include <QRandomGenerator>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrlQuery>
#include <QtCore/QApplicationStatic>
#include "QGCLoggingCategory.h"
#include "SettingsManager.h"
#include "CloudSettings.h"

QGC_LOGGING_CATEGORY(SignalingServerManagerLog, "Comms.SignalingServerManager")

Q_APPLICATION_STATIC(SignalingServerManager, _signalingServerManagerInstance);

SignalingServerManager* SignalingServerManager::instance()
{
    return _signalingServerManagerInstance();
}

void SignalingServerManager::init()
{
    qCDebug(SignalingServerManagerLog) << "SignalingServerManager initialized";
    
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
    qCDebug(SignalingServerManagerLog) << "SignalingServerManager created";
    
    // 클라이언트 ID 자동 생성
    _generateClientId();
    
    _setupWebSocket();
    
    // 재연결 타이머 설정 (강화됨)
    _reconnectTimer = new QTimer(this);
    _reconnectTimer->setSingleShot(true);
    connect(_reconnectTimer, &QTimer::timeout, this, &SignalingServerManager::_onReconnectTimer);
    

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

    _openWebSocketWithAuth(wsUrl);
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

    _openWebSocketWithAuth(wsUrl);
}

void SignalingServerManager::disconnectFromServer()
{
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

void SignalingServerManager::applyNewSettings()
{
    qCDebug(SignalingServerManagerLog) << "Applying new settings - reconnecting to signaling server";

    // 1. 기존 연결 해제
    _userDisconnected = false;  // 자동 재연결 방지를 위해 먼저 false로 설정
    _stopReconnectTimer();
    _stopConnectionMonitoring();

    // issuer/clientSecret 등이 바뀌었을 수 있으므로 캐시된 Bearer 토큰/TURN 자격을 폐기
    _jwtToken.clear();
    _jwtExpiresAtMs = 0;
    {
        QMutexLocker locker(&_bundleTurnMutex);
        _bundleTurn = {};
        _bundleTurnExpiresAtMs = 0;
    }

    if (_webSocket && _webSocket->state() != QAbstractSocket::UnconnectedState) {
        _webSocket->close();
    }

    _updateConnectionState(ConnectionState::Disconnected);
    _updateConnectionStatus("설정 적용 중...");

    // 2. 최신 설정으로 재연결 (약간의 딜레이 후)
    QTimer::singleShot(500, this, [this]() {
        _serverUrl = SettingsManager::instance()->cloudSettings()->webrtcSignalingServer()->rawValue().toString();
        qCDebug(SignalingServerManagerLog) << "Reconnecting with new server URL:" << _serverUrl;

        if (_serverUrl.isEmpty()) {
            _updateConnectionStatus("서버 주소가 설정되지 않음");
            _updateConnectionState(ConnectionState::Error);
            return;
        }

        connectToServerWebSocketOnly(_serverUrl);
    });
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
        // connectToServer()가 아니라 connectToServerWebSocketOnly()로 가면 _gcsId가
        // 지워지고 _webSocketOnlyMode=true가 되어, 연결 후 자동 등록이 영영 나가지
        // 않는다(등록 의도 유실). 등록 정보를 유지한 채 연결한다.
        qCDebug(SignalingServerManagerLog) << "Not connected, establishing WebSocket connection first";
        connectToServer(_serverUrl, _gcsId, _targetDroneId);
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
    } else if (messageType == "connectionReplaced") {
        qCDebug(SignalingServerManagerLog) << "Ignoring connectionReplaced message";
        _updateConnectionStatus("연결 대체 무시됨 - WebSocket 연결 유지");
    } else if (messageType == "drones:list") {
        _handleDronesListResponse(messageObj);
    } else if (messageType == "drone:connected") {
        _handleDroneConnected(messageObj);
    } else if (messageType == "drone:disconnected") {
        _handleDroneDisconnected(messageObj);
    } else if (messageType == "connected") {
        _handleServerConnected(messageObj);
    } else if (messageType == "serverShutdown") {
        _handleServerShutdown(messageObj);
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
        _updateConnectionStatus("등록 완료");
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

        qCDebug(SignalingServerManagerLog) << "  [" << (i + 1) << "]"
                                           << "ID:" << droneId
                                           << "Status:" << status
                                           << "Paired:" << paired
                                           << "PairedWith:" << pairedWith;

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

void SignalingServerManager::_handleDroneConnected(const QJsonObject &message)
{
    // 서버 푸시: 드론이 시그널링 서버에 접속함
    QJsonObject droneObj = message["drone"].toObject();
    QString droneId = droneObj["id"].toString();

    if (droneId.isEmpty()) {
        qCWarning(SignalingServerManagerLog) << "drone:connected message missing drone.id";
        return;
    }

    if (_connectedDronesList.contains(droneId)) {
        qCDebug(SignalingServerManagerLog) << "drone:connected for already-known drone, ignoring:" << droneId;
        return;
    }

    qCDebug(SignalingServerManagerLog) << "=== drone:connected ===" << droneId
                                       << "Timestamp:" << message["timestamp"].toString();

    _connectedDronesList.append(droneId);
    _connectedDronesCount = _connectedDronesList.size();

    emit connectedDronesListChanged();
    emit connectedDronesCountChanged();
}

void SignalingServerManager::_handleDroneDisconnected(const QJsonObject &message)
{
    // 서버 푸시: 드론이 시그널링 서버에서 끊김
    QString droneId = message["id"].toString();

    if (droneId.isEmpty()) {
        qCWarning(SignalingServerManagerLog) << "drone:disconnected message missing id";
        return;
    }

    qCDebug(SignalingServerManagerLog) << "=== drone:disconnected ===" << droneId
                                       << "Reason:" << message["reason"].toString()
                                       << "Timestamp:" << message["timestamp"].toString();

    if (!_connectedDronesList.removeOne(droneId)) {
        qCDebug(SignalingServerManagerLog) << "drone:disconnected for unknown drone, ignoring:" << droneId;
        return;
    }
    _connectedDronesCount = _connectedDronesList.size();

    emit connectedDronesListChanged();
    emit connectedDronesCountChanged();
}

void SignalingServerManager::_handleServerConnected(const QJsonObject &message)
{
    // WebSocket 연결 직후 서버가 자동 발신하는 환영 메시지
    // serverVersion / features / supportedMessageTypes 로깅으로 prototocl 호환성 확인 용이
    const QString serverVersion = message["serverVersion"].toString();
    const QJsonArray features = message["features"].toArray();
    const QJsonArray supportedTypes = message["supportedMessageTypes"].toArray();

    QStringList featureList;
    for (const auto &v : features) featureList << v.toString();

    QStringList typeList;
    for (const auto &v : supportedTypes) typeList << v.toString();

    qCDebug(SignalingServerManagerLog) << "=== server connected ==="
                                       << "Version:" << serverVersion
                                       << "Features:" << featureList
                                       << "SupportedTypes:" << typeList;
}

void SignalingServerManager::_handleServerShutdown(const QJsonObject &message)
{
    // 서버가 graceful shutdown 시작 — WS는 곧 close될 예정
    const QString reason = message["message"].toString();
    qCWarning(SignalingServerManagerLog) << "Server is shutting down:" << reason;
    _updateConnectionStatus(QString("서버 종료 중: %1").arg(reason.isEmpty() ? tr("점검") : reason));
}

bool SignalingServerManager::isDroneConnected(const QString &droneId) const
{
    return _connectedDronesList.contains(droneId);
}

QString SignalingServerManager::deriveAuthIssuerUrl()
{
    const QString server = SettingsManager::instance()->cloudSettings()->webrtcSignalingServer()->rawValue().toString().trimmed();
    if (server.isEmpty()) {
        return QString();
    }
    // 스킴이 없으면 임시로 붙여 host만 안전하게 파싱한다. (signaling 값에 경로/포트가
    // 섞여 있어도 host만 추출) issuer는 표준 https(443)에 있다고 보고 포트는 무시한다.
    const QString withScheme = server.contains("://") ? server : (QStringLiteral("https://") + server);
    const QString host = QUrl(withScheme).host();
    if (host.isEmpty()) {
        return QString();
    }
    return QStringLiteral("https://%1/auth-api").arg(host);
}

SignalingServerManager::TurnCredentials SignalingServerManager::cachedTurnCredentials() const
{
    QMutexLocker locker(&_bundleTurnMutex);
    // 만료 60초 전부터는 무효로 간주(워커가 폴백 발급하도록)
    if (!_bundleTurn.isValid() ||
        QDateTime::currentMSecsSinceEpoch() >= (_bundleTurnExpiresAtMs - 60000)) {
        return {};
    }
    return _bundleTurn;
}

QString SignalingServerManager::_formatWebSocketUrl(const QString &baseUrl) const
{
    QString url = baseUrl.trimmed();
    if (url.isEmpty()) {
        return url;
    }

    // wss:// 프로토콜 추가 (없는 경우)
    if (!url.startsWith("ws://") && !url.startsWith("wss://")) {
        url = "wss://" + url;
    }

    // 경로가 없으면(호스트만 입력) signaling 경로를 자동 부착해 issuer와 동일하게 호스트만으로
    // 동작하게 한다. 끝 슬래시(/signaling/)는 서버 라우팅상 필수. 이미 경로가 있으면
    // (예: .../signaling/) 그대로 두어 기존 값과 충돌하지 않는다.
    QUrl parsed(url);
    const QString path = parsed.path();
    if (path.isEmpty() || path == QStringLiteral("/")) {
        parsed.setPath(QStringLiteral("/signaling/"));
        url = parsed.toString();
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


void SignalingServerManager::_startConnectionMonitoring()
{
    if (_getDronesTimer) {
        _getDronesTimer->start(GET_DRONES_INTERVAL_MS);
        _sendGetDronesRequest();
    }

    qCDebug(SignalingServerManagerLog) << "Connection monitoring started";
}

void SignalingServerManager::_stopConnectionMonitoring()
{
    if (_getDronesTimer && _getDronesTimer->isActive()) {
        _getDronesTimer->stop();
    }

    qCDebug(SignalingServerManagerLog) << "Connection monitoring stopped";
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

void SignalingServerManager::_openWebSocketWithAuth(const QString &wsUrl)
{
    // 매 연결 시도마다 세대를 올려, 비동기 토큰 요청 도중 연결이 취소/재시작되면
    // 늦게 도착한 토큰 응답이 엉뚱하게 WebSocket을 열지 않도록 한다.
    const quint64 generation = ++_connectGeneration;

    // 유효한 캐시 토큰(만료 60초 전)이 있으면 issuer 왕복 없이 바로 사용
    if (!_jwtToken.isEmpty() &&
        QDateTime::currentMSecsSinceEpoch() < (_jwtExpiresAtMs - 60000)) {
        _openWebSocketWithToken(wsUrl, _jwtToken);
        return;
    }

    _requestAuthTokenAndOpen(wsUrl, generation);
}

void SignalingServerManager::_requestAuthTokenAndOpen(const QString &wsUrl, quint64 generation)
{
    CloudSettings *cloudSettings = SettingsManager::instance()->cloudSettings();
    const QString issuerUrl = deriveAuthIssuerUrl();   // 서버 호스트에서 파생
    const QString clientId = cloudSettings->webrtcAuthClientId()->rawValue().toString().trimmed();
    const QString clientSecret = cloudSettings->webrtcAuthClientSecret()->rawValue().toString();

    if (issuerUrl.isEmpty() || clientSecret.isEmpty()) {
        qCWarning(SignalingServerManagerLog) << "Auth issuer not configured, cannot obtain bearer token";
        _updateConnectionState(ConnectionState::Error);
        _updateConnectionStatus("인증 발급자(issuer)가 설정되지 않았습니다");
        emit connectionError("인증 발급자가 설정되지 않았습니다");
        return;
    }

    if (!_authNam) {
        _authNam = new QNetworkAccessManager(this);
    }

    // /token은 서버 전역 상수로 aud=relay-server 토큰만 발급하므로, 서비스별 aud 토큰을
    // 한꺼번에 내려주는 /bundle을 사용해 aud=signaling-server 토큰을 받는다.
    //   POST {issuer}/bundle (application/json)  { client_id, client_secret }
    //   -> { "tokens": { "relay": "<jwt>", "signaling": "<jwt aud=signaling-server>" },
    //        "turn": {...}, "token_type": "Bearer", "expires_in": <sec> }
    QString endpoint = issuerUrl;
    while (endpoint.endsWith('/')) {
        endpoint.chop(1);
    }
    endpoint += "/bundle";

    QNetworkRequest request{QUrl(endpoint)};
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    const QString effectiveClientId = clientId.isEmpty() ? QStringLiteral("operator-ui") : clientId;

    QJsonObject body;
    body["client_id"] = effectiveClientId;
    body["client_secret"] = clientSecret;

    _updateConnectionStatus("인증 토큰 요청 중...");
    qCDebug(SignalingServerManagerLog) << "Requesting bearer token from issuer:" << endpoint
                                       << "client_id:" << effectiveClientId;

    QNetworkReply *reply = _authNam->post(request, QJsonDocument(body).toJson(QJsonDocument::Compact));

    connect(reply, &QNetworkReply::finished, this, [this, reply, wsUrl, generation, endpoint, effectiveClientId]() {
        reply->deleteLater();

        // 취소/재시작된 연결 시도의 늦은 응답은 무시
        if (generation != _connectGeneration || _userDisconnected) {
            qCDebug(SignalingServerManagerLog) << "Ignoring stale/aborted auth token response";
            return;
        }

        const auto failAndRetry = [this](const QString &reason) {
            qCWarning(SignalingServerManagerLog) << "Bearer token error:" << reason;
            _updateConnectionState(ConnectionState::Error);
            _updateConnectionStatus(QString("인증 토큰 발급 실패: %1").arg(reason));
            emit connectionError(reason);
            if (!_userDisconnected) {
                _reconnectAttempts++;
                _startReconnectTimer();
            }
        };

        if (reply->error() != QNetworkReply::NoError) {
            // 서버가 내려준 본문에 실패 원인(필드/그랜트 불일치 등)이 담겨 있는 경우가 많아 함께 로깅.
            // 401 invalid_client 류를 진단하려면 HTTP 상태코드와 WWW-Authenticate 챌린지가 결정적이다.
            //   - 상태코드 401 + WWW-Authenticate 존재 → 서버가 표준 OAuth2 Basic 헤더 인증을 기대(방식 불일치)
            //   - 상태코드 401 + 챌린지 없음/본문 invalid_client → client_id/secret 값 불일치
            const QByteArray errBody = reply->readAll();
            const QVariant statusCodeVar = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute);
            const int httpStatus = statusCodeVar.isValid() ? statusCodeVar.toInt() : -1;
            const QByteArray wwwAuth = reply->rawHeader("WWW-Authenticate");
            qCWarning(SignalingServerManagerLog).nospace()
                << "Token endpoint auth failed - endpoint: " << endpoint
                << ", client_id: " << effectiveClientId
                << ", HTTP status: " << httpStatus
                << ", WWW-Authenticate: " << (wwwAuth.isEmpty() ? QByteArray("<none>") : wwwAuth)
                << ", body: " << errBody
                << ", qtError: " << reply->errorString();
            failAndRetry(reply->errorString());
            return;
        }

        QJsonParseError parseError;
        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll(), &parseError);
        if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
            failAndRetry(QStringLiteral("응답 파싱 실패"));
            return;
        }

        const QJsonObject obj = doc.object();
        // /bundle 응답의 tokens.signaling이 aud=signaling-server 토큰이다.
        const QString token = obj["tokens"].toObject()["signaling"].toString();
        if (token.isEmpty()) {
            failAndRetry(QStringLiteral("응답에 tokens.signaling 없음"));
            return;
        }

        const qint64 ttlSec = obj.contains("expires_in") ? obj["expires_in"].toVariant().toLongLong() : 600;
        _jwtToken = token;
        _jwtExpiresAtMs = QDateTime::currentMSecsSinceEpoch() + (ttlSec * 1000);

        // /bundle이 함께 준 TURN 임시자격을 캐시한다. 워커가 PeerConnection 셋업 시
        // 별도의 /turn-credentials 왕복 없이 cachedTurnCredentials()로 재사용한다.
        {
            const QJsonObject turnObj = obj["turn"].toObject();
            TurnCredentials turn;
            const QJsonValue urlsVal = turnObj["urls"];
            if (urlsVal.isArray()) {
                for (const QJsonValue &v : urlsVal.toArray()) {
                    const QString u = v.toString().trimmed();
                    if (!u.isEmpty()) {
                        turn.urls << u;
                    }
                }
            } else {
                const QString u = urlsVal.toString().trimmed();
                if (!u.isEmpty()) {
                    turn.urls << u;
                }
            }
            turn.username = turnObj["username"].toString();
            turn.credential = turnObj["credential"].toString();

            QMutexLocker locker(&_bundleTurnMutex);
            _bundleTurn = turn;
            // TURN 자격도 같은 발급에서 나왔으므로 토큰과 동일한 TTL을 사용
            _bundleTurnExpiresAtMs = turn.isValid() ? (QDateTime::currentMSecsSinceEpoch() + (ttlSec * 1000)) : 0;
            qCDebug(SignalingServerManagerLog) << "Cached bundle TURN credentials, valid:" << turn.isValid()
                                               << "urls:" << turn.urls.size();
        }

        // 발급된 JWT의 payload(claim)를 디버그 로깅한다(서명 검증 아님). aud/iss/exp가
        // 시그널링 서버 기대값(aud=signaling-server, iss=amp-auth-issuer)과 어긋날 때
        // 빠르게 진단하기 위한 용도. payload는 base64url JSON일 뿐 서명/시크릿은 포함되지 않는다.
        {
            const QStringList parts = token.split('.');
            if (parts.size() >= 2) {
                const QByteArray payload = QByteArray::fromBase64(
                    parts[1].toUtf8(), QByteArray::Base64UrlEncoding | QByteArray::OmitTrailingEquals);
                qCDebug(SignalingServerManagerLog) << "Issued signaling JWT claims:" << QString::fromUtf8(payload);
            } else {
                qCDebug(SignalingServerManagerLog) << "Signaling token is not a JWT (segments:" << parts.size() << ")";
            }
        }

        _openWebSocketWithToken(wsUrl, token);
    });
}

void SignalingServerManager::_openWebSocketWithToken(const QString &wsUrl, const QString &token)
{
    // 서버 verifyClient는 ?token= 쿼리를 우선 확인한다(server.js). 쿼리 방식은 nginx
    // proxy_pass로 보존되어 Authorization 헤더가 중간에서 떨어져 나가는 문제가 없다.
    // Authorization 헤더도 함께 실어 헤더만 읽는 경로(네이티브 직결 등)와 호환시킨다.
    // 주의: 토큰이 URL에 들어가므로 토큰 포함 URL은 로그로 남기지 않는다.
    QUrl url(wsUrl);
    QUrlQuery query(url.query());
    query.removeQueryItem(QStringLiteral("token"));
    query.addQueryItem(QStringLiteral("token"), token);
    url.setQuery(query);

    QNetworkRequest request(url);
    request.setRawHeader("Authorization", QByteArray("Bearer ") + token.toUtf8());
    qCDebug(SignalingServerManagerLog) << "Opening signaling WebSocket with bearer token (query + header)";

    _webSocket->open(request);
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
