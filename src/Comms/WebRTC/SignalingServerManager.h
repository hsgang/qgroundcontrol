#pragma once

#include <QtCore/QObject>
#include <QtCore/QTimer>
#include <QtCore/QThread>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtCore/QLoggingCategory>
#include <QtWebSockets/QWebSocket>
#include <QtNetwork/QAbstractSocket>
#include <climits>

Q_DECLARE_LOGGING_CATEGORY(SignalingServerManagerLog)

/**
 * @brief SignalingServerManager - WebRTC 시그널링 서버 연결 관리 (강화된 재연결 버전)
 * 
 * 개선된 기능:
 * - 강화된 WebSocket 연결 관리
 * - 지수 백오프 재연결 전략
 * - 연결 상태 모니터링 (핑/퐁)
 * - 자동 재등록 기능
 * - 연결 품질 모니터링
 */
class SignalingServerManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionStateChanged)
    Q_PROPERTY(QString connectionStatus READ connectionStatus NOTIFY connectionStatusChanged)

public:
    enum class ConnectionState {
        Disconnected = 0,
        Connecting,
        Connected,
        Reconnecting,
        Error
    };
    Q_ENUM(ConnectionState)

public:
    explicit SignalingServerManager(QObject *parent = nullptr);
    ~SignalingServerManager();
    
    static SignalingServerManager* instance();
    void init();
    static void shutdown();
    
    // WebSocket 연결 관리
    void connectToServer(const QString &serverUrl, const QString &gcsId, const QString &targetDroneId);
    void connectToServerWebSocketOnly(const QString &serverUrl);
    void disconnectFromServer();
    
    // 클라이언트 ID 관리
    void setClientId(const QString &clientId);
    QString getClientId() const { return _clientId; }
    
    // 시그널링 메시지 송수신
    void sendMessage(const QJsonObject &message);
    
    // GCS 관리
    void registerGCS(const QString &gcsId, const QString &targetDroneId);
    void unregisterGCS(const QString &gcsId);
    
    // 상태 확인
    bool isConnected() const { return _connectionState == ConnectionState::Connected; }
    bool isWebSocketOnlyConnected() const { return isConnected() && _webSocketOnlyMode; }
    bool isReadyForGCS() const { return isConnected() && !_gcsId.isEmpty(); }
    
    // 기본 상태 정보
    ConnectionState connectionState() const { return _connectionState; }
    QString connectionStatus() const { return _connectionStatusMessage; }

public slots:
    void retryConnection();
    void sendPing(); // 클라이언트에서 ping을 보내는 public 메서드

signals:
    // 연결 상태 시그널
    void connectionStateChanged(ConnectionState state);
    void connectionStatusChanged(const QString &status);
    void connected();
    void disconnected();
    void connectionError(const QString &errorMessage);
    
    // 메시지 시그널
    void messageReceived(const QJsonObject &message);
    void messageSent(const QJsonObject &message);
    
    // 등록 시그널
    void registrationSuccessful();
    void registrationFailed(const QString &reason);
    void gcsUnregisteredSuccessfully(const QString &gcsId);
    void gcsUnregisterFailed(const QString &gcsId, const QString &reason);

private slots:
    void _onWebSocketConnected();
    void _onWebSocketDisconnected();
    void _onWebSocketError(QAbstractSocket::SocketError error);
    void _onWebSocketMessageReceived(const QString &message);
    void _onReconnectTimer();
    void _onConnectionHealthTimer();
    void _onPingTimer();

private:
    // WebSocket 관리
    void _setupWebSocket();
    void _cleanupWebSocket();
    
    // 상태 관리
    void _updateConnectionState(ConnectionState newState);
    void _updateConnectionStatus(const QString &status);
    
    // 재연결 관리 (강화됨)
    void _startReconnectTimer();
    void _stopReconnectTimer();
    int _calculateReconnectDelay() const;
    void _resetReconnectAttempts();
    
    // 연결 모니터링 (클라이언트 ping/pong 기반)
    void _startConnectionMonitoring();
    void _stopConnectionMonitoring();
    void _checkConnectionHealth();
    void _forceReconnection();
    void _sendPing();
    
    // 메시지 처리
    void _handleRegistrationResponse(const QJsonObject &message);
    void _handleUnregisterResponse(const QJsonObject &message);
    void _handlePongResponse(const QJsonObject &message);
    
    // 자동 재등록
    void _autoReRegister();
    
    // 유틸리티
    QString _formatWebSocketUrl(const QString &baseUrl) const;
    bool _isValidUrl(const QString &url) const;
    void _generateClientId();

    // === 핵심 멤버 변수 ===
    
    // WebSocket 연결
    QWebSocket *_webSocket = nullptr;
    QString _serverUrl;
    QString _gcsId;
    QString _targetDroneId;
    QString _clientId; // 클라이언트 고유 ID
    
    // 연결 상태
    ConnectionState _connectionState = ConnectionState::Disconnected;
    QString _connectionStatusMessage;
    bool _webSocketOnlyMode = false;
    
    // 재연결 관리 (강화됨)
    QTimer *_reconnectTimer = nullptr;
    int _reconnectAttempts = 0;
    bool _userDisconnected = false;
    qint64 _lastSuccessfulConnection = 0;
    
    // 연결 모니터링 (클라이언트 ping/pong 기반)
    QTimer *_connectionHealthTimer = nullptr;
    QTimer *_pingTimer = nullptr;
    qint64 _lastPingSent = 0;
    qint64 _lastPongReceived = 0;
    bool _waitingForPong = false;
    int _consecutivePingFailures = 0;
    
    // 상수 (개선됨)
    static const int DEFAULT_RECONNECT_INTERVAL_MS = 5000; // 5초로 증가
    static const int MAX_RECONNECT_ATTEMPTS = 10; // 무한 재시도 방지
    static const int MAX_RECONNECT_DELAY_MS = 30000; // 30초로 증가
    static const int PING_INTERVAL_MS = 10000; // 10초마다 ping 전송
    static const int PING_TIMEOUT_MS = 5000; // ping 응답 5초 타임아웃
    static const int CONNECTION_HEALTH_CHECK_MS = 10000; // 10초마다 상태 체크
    static const int MAX_CONSECUTIVE_PING_FAILURES = 3;
};
