#pragma once

#include <QtCore/QObject>
#include <QtCore/QTimer>
#include <QtCore/QThread>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtCore/QLoggingCategory>
#include <QtWebSockets/QWebSocket>
#include <QtNetwork/QAbstractSocket>
#include <QtCore/QMutex>
#include <QtCore/QStringList>
#include <climits>
#include <functional>

class QNetworkAccessManager;

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
    Q_PROPERTY(int connectedDronesCount READ connectedDronesCount NOTIFY connectedDronesCountChanged)
    Q_PROPERTY(QStringList connectedDronesList READ connectedDronesList NOTIFY connectedDronesListChanged)

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

    // 드론 연결 상태
    int connectedDronesCount() const { return _connectedDronesCount; }
    QStringList connectedDronesList() const { return _connectedDronesList; }
    Q_INVOKABLE bool isDroneConnected(const QString &droneId) const;
    Q_INVOKABLE void applyNewSettings();  // 설정 변경 후 재연결

    // /bundle이 시그널링 JWT와 함께 내려주는 TURN 임시자격. 워커가 별도 /turn-credentials
    // 왕복 없이 재사용할 수 있도록 공유한다.
    struct TurnCredentials {
        QStringList urls;
        QString username;
        QString credential;
        bool isValid() const { return !urls.isEmpty() && !username.isEmpty(); }
    };

    // 스레드 안전: 워커 스레드에서 호출 가능. 캐시가 비었거나 만료됐으면 빈 값을 반환한다.
    TurnCredentials cachedTurnCredentials() const;

    // 서버 주소(webrtcSignalingServer)의 호스트에서 auth-issuer 주소를 파생한다:
    //   https://{host}/auth-api  (호스트가 비어있으면 빈 문자열). 시그널링/issuer/TURN이
    //   같은 호스트를 공유하는 배포를 전제로, 입력 필드를 서버 주소 하나로 통합하기 위함.
    static QString deriveAuthIssuerUrl();

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
    void gcsUnregisteredSuccessfully(const QString &gcsId);
    void gcsUnregisterFailed(const QString &gcsId, const QString &reason);

    // 드론 상태 시그널
    void connectedDronesCountChanged();
    void connectedDronesListChanged();

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
    
    // 재연결 관리 (강화됨)
    void _startReconnectTimer();
    void _stopReconnectTimer();
    int _calculateReconnectDelay() const;
    void _resetReconnectAttempts();
    
    // 연결 모니터링
    void _startConnectionMonitoring();
    void _stopConnectionMonitoring();

    // 메시지 처리
    void _handleRegistrationResponse(const QJsonObject &message);
    void _handleUnregisterResponse(const QJsonObject &message);
    void _handleDronesListResponse(const QJsonObject &message);
    void _handleDroneConnected(const QJsonObject &message);
    void _handleDroneDisconnected(const QJsonObject &message);
    void _handleServerConnected(const QJsonObject &message);
    void _handleServerShutdown(const QJsonObject &message);
    
    // 자동 재등록
    void _autoReRegister();
    
    // 유틸리티
    QString _formatWebSocketUrl(const QString &baseUrl) const;
    bool _isValidUrl(const QString &url) const;
    void _generateClientId();
    void _openWebSocketWithAuth(const QString &wsUrl);
    // issuer 토큰 엔드포인트(client_credentials)에서 Bearer JWT를 받아 WebSocket을 연다.
    void _requestAuthTokenAndOpen(const QString &wsUrl, quint64 generation);
    void _openWebSocketWithToken(const QString &wsUrl, const QString &token);
    // POST {issuer}/bundle — JWT + TURN 임시자격을 발급받아 캐시하고 done(ok, tokenOrError) 호출.
    void _fetchBundle(std::function<void(bool, const QString &)> done);
    // 만료 임박 시 번들 재발급 — 오래 사는 WS에서도 cachedTurnCredentials()를 유효하게 유지.
    void _refreshBundleIfStale();

    // === 핵심 멤버 변수 ===
    
    // WebSocket 연결
    QWebSocket *_webSocket = nullptr;
    QString _serverUrl;
    QString _gcsId;
    QString _targetDroneId;
    QString _clientId; // 클라이언트 고유 ID

    // Bearer JWT 인증 (issuer client_credentials 그랜트로 발급, 만료 전까지 캐시)
    QNetworkAccessManager *_authNam = nullptr;
    QString _jwtToken;
    qint64 _jwtExpiresAtMs = 0;
    // 비동기 토큰 요청 도중 연결이 취소/재시작되면, 늦게 도착한 응답을 무시하기 위한 세대 카운터
    quint64 _connectGeneration = 0;

    // /bundle에서 파싱한 TURN 임시자격 캐시 (cachedTurnCredentials로 워커 스레드와 공유)
    mutable QMutex _bundleTurnMutex;
    TurnCredentials _bundleTurn;
    qint64 _bundleTurnExpiresAtMs = 0;

    // 연결 상태
    ConnectionState _connectionState = ConnectionState::Disconnected;
    QString _connectionStatusMessage;
    bool _webSocketOnlyMode = false;
    
    // 재연결 관리 (강화됨)
    QTimer *_reconnectTimer = nullptr;
    int _reconnectAttempts = 0;
    bool _userDisconnected = false;
    qint64 _lastSuccessfulConnection = 0;

    // 드론 상태 요청
    QTimer *_getDronesTimer = nullptr;
    void _sendGetDronesRequest();

    // JWT/TURN 번들 신선도 유지
    QTimer *_bundleRefreshTimer = nullptr;

    // 드론 연결 상태 추적
    int _connectedDronesCount = 0;
    QStringList _connectedDronesList;
    
    // 상수
    static const int DEFAULT_RECONNECT_INTERVAL_MS = 5000;
    static const int MAX_RECONNECT_ATTEMPTS = 10;
    static const int MAX_RECONNECT_DELAY_MS = 30000;
    static const int GET_DRONES_INTERVAL_MS = 60000;  // 푸시 이벤트(drone:connected/disconnected) 누락 안전망
    // 번들 갱신: 30초 주기로 검사, 만료 120초 전부터 재발급.
    // cachedTurnCredentials()의 무효 마진(60초)보다 커야 빈 구간이 없다.
    static const int BUNDLE_REFRESH_CHECK_MS = 30000;
    static const int BUNDLE_REFRESH_MARGIN_MS = 120000;
};
