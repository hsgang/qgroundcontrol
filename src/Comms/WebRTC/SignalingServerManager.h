#pragma once

#include <QtCore/QObject>
#include <QtCore/QTimer>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtCore/QLoggingCategory>
#include <QtWebSockets/QWebSocket>
#include <QtNetwork/QAbstractSocket>

Q_DECLARE_LOGGING_CATEGORY(SignalingServerManagerLog)

/**
 * @brief SignalingServerManager - WebRTC 시그널링 서버 연결 관리 (최적화 버전)
 * 
 * 핵심 기능만 포함한 단순화된 버전:
 * - WebSocket 연결 관리
 * - 시그널링 메시지 송수신
 * - Peer 등록/해제
 * - 기본 재연결 기능
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
    void connectToServer(const QString &serverUrl, const QString &peerId, const QString &roomId);
    void connectToServerWebSocketOnly(const QString &serverUrl);
    void disconnectFromServer();
    
    // 시그널링 메시지 송수신
    void sendMessage(const QJsonObject &message);
    
    // Peer 관리
    void registerPeer(const QString &peerId, const QString &roomId);
    void leavePeer(const QString &peerId, const QString &roomId);
    
    // 상태 확인
    bool isConnected() const { return _connectionState == ConnectionState::Connected; }
    bool isWebSocketOnlyConnected() const { return isConnected() && _webSocketOnlyMode; }
    bool isReadyForPeers() const { return isConnected() && !_peerId.isEmpty() && !_roomId.isEmpty(); }
    
    // 기본 상태 정보
    ConnectionState connectionState() const { return _connectionState; }
    QString connectionStatus() const { return _connectionStatusMessage; }

public slots:
    void retryConnection();

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
    void peerLeftSuccessfully(const QString &peerId, const QString &roomId);
    void peerLeaveFailed(const QString &peerId, const QString &reason);

private slots:
    void _onWebSocketConnected();
    void _onWebSocketDisconnected();
    void _onWebSocketError(QAbstractSocket::SocketError error);
    void _onWebSocketMessageReceived(const QString &message);
    void _onReconnectTimer();

private:
    // WebSocket 관리
    void _setupWebSocket();
    void _cleanupWebSocket();
    
    // 상태 관리
    void _updateConnectionState(ConnectionState newState);
    void _updateConnectionStatus(const QString &status);
    
    // 재연결 관리
    void _startReconnectTimer();
    void _stopReconnectTimer();
    
    // 메시지 처리
    void _handleRegistrationResponse(const QJsonObject &message);
    void _handleLeaveResponse(const QJsonObject &message);
    
    // 유틸리티
    QString _formatWebSocketUrl(const QString &baseUrl) const;
    bool _isValidUrl(const QString &url) const;

    // === 핵심 멤버 변수 ===
    
    // WebSocket 연결
    QWebSocket *_webSocket = nullptr;
    QString _serverUrl = "wss://ampkorea.duckdns.org:3000";
    QString _peerId;
    QString _roomId;
    
    // 연결 상태
    ConnectionState _connectionState = ConnectionState::Disconnected;
    QString _connectionStatusMessage;
    bool _webSocketOnlyMode = false;
    
    // 재연결 관리 (단순화)
    QTimer *_reconnectTimer = nullptr;
    int _reconnectAttempts = 0;
    bool _userDisconnected = false;
    
    // 상수
    static const int DEFAULT_RECONNECT_INTERVAL_MS = 3000;
    static const int MAX_RECONNECT_ATTEMPTS = 5;
};
