#pragma once

#include <rtc/rtc.hpp>
#include <memory>
#include <QtCore/QMap>
#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QMutexLocker>
#include <QtCore/QThread>
#include <QtCore/QTimer>
#include <QtWebSockets/QWebSocket>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtCore/QLoggingCategory>
#include <QtCore/QDateTime>
#include <QRandomGenerator>
#include <set>
#include <QtCore/QByteArray>

#include "LinkConfiguration.h"
#include "LinkInterface.h"
#include "VideoManager.h"
#include "SignalingServerManager.h"

class QThread;
class WebRTCLink;
class SignalingServerManager;

Q_DECLARE_LOGGING_CATEGORY(WebRTCLinkLog)

// RTC 모듈 시스템 정보를 효율적으로 묶어서 전달하기 위한 구조체
struct RTCModuleSystemInfo {
    double cpuUsage = 0.0;
    double cpuTemperature = 0.0;
    double memoryUsage = 0.0;
    double networkRx = 0.0;
    double networkTx = 0.0;
    QString networkInterface = "";
    
    // JSON에서 파싱하는 생성자
    RTCModuleSystemInfo(const QJsonObject& json) {
        cpuUsage = json["cpu_usage"].toDouble();
        cpuTemperature = json["cpu_temperature"].toDouble();
        memoryUsage = json["memory_usage_percent"].toDouble();
        networkRx = json["network_rx_mbps"].toDouble();
        networkTx = json["network_tx_mbps"].toDouble();
        networkInterface = json["network_interface"].toString();
    }
    
    // 기본 생성자
    RTCModuleSystemInfo() = default;
    
    // 비교 연산자 (변경 감지용)
    bool operator==(const RTCModuleSystemInfo& other) const {
        return qFuzzyCompare(cpuUsage, other.cpuUsage) &&
               qFuzzyCompare(cpuTemperature, other.cpuTemperature) &&
               qFuzzyCompare(memoryUsage, other.memoryUsage) &&
               qFuzzyCompare(networkRx, other.networkRx) &&
               qFuzzyCompare(networkTx, other.networkTx) &&
               networkInterface == other.networkInterface;
    }
    
    bool operator!=(const RTCModuleSystemInfo& other) const {
        return !(*this == other);
    }
    
    // 유효성 검사
    bool isValid() const {
        return cpuUsage >= 0.0 && cpuUsage <= 100.0 &&
               cpuTemperature >= -50.0 && cpuTemperature <= 150.0 &&
               memoryUsage >= 0.0 && memoryUsage <= 100.0 &&
               networkRx >= 0.0 && networkTx >= 0.0;
    }
    
    // 디버그 출력용
    QString toString() const {
        return QString("CPU: %1%%, Temp: %2°C, Mem: %3%%, Net: %4/%5 Mbps (%6)")
               .arg(cpuUsage, 0, 'f', 1)
               .arg(cpuTemperature, 0, 'f', 1)
               .arg(memoryUsage, 0, 'f', 1)
               .arg(networkRx, 0, 'f', 2)
               .arg(networkTx, 0, 'f', 2)
               .arg(networkInterface);
    }
};

// WebRTC 통계 정보를 효율적으로 묶어서 전달하기 위한 구조체
struct WebRTCStats {
    int rttMs = -1;
    double webRtcSent = -1.0;
    double webRtcRecv = -1.0;
    double videoRateKBps = 0.0;
    int videoPacketCount = 0;
    qint64 videoBytesReceived = 0;
    
    // 기본 생성자
    WebRTCStats() = default;
    
    // 비교 연산자 (변경 감지용)
    bool operator==(const WebRTCStats& other) const {
        return rttMs == other.rttMs &&
               qFuzzyCompare(webRtcSent, other.webRtcSent) &&
               qFuzzyCompare(webRtcRecv, other.webRtcRecv) &&
               qFuzzyCompare(videoRateKBps, other.videoRateKBps) &&
               videoPacketCount == other.videoPacketCount &&
               videoBytesReceived == other.videoBytesReceived;
    }
    
    bool operator!=(const WebRTCStats& other) const {
        return !(*this == other);
    }
    
    // 유효성 검사
    bool isValid() const {
        return rttMs >= -1 && webRtcSent >= -1.0 && webRtcRecv >= -1.0 &&
               videoRateKBps >= 0.0 && videoPacketCount >= 0 && videoBytesReceived >= 0;
    }
    
    // 디버그 출력용
    QString toString() const {
        return QString("RTT: %1ms, Sent: %2 KB/s, Recv: %3 KB/s, Video: %4 KB/s (%5 packets, %6 bytes)")
               .arg(rttMs)
               .arg(webRtcSent, 0, 'f', 2)
               .arg(webRtcRecv, 0, 'f', 2)
               .arg(videoRateKBps, 0, 'f', 2)
               .arg(videoPacketCount)
               .arg(videoBytesReceived);
    }
};

// RTC 모듈 버전 정보를 저장하기 위한 구조체
struct RTCModuleVersionInfo {
    QString currentVersion = "";
    QString latestVersion = "";
    qint64 timestamp = 0;
    bool updateAvailable = false;
    
    // JSON에서 파싱하는 생성자
    RTCModuleVersionInfo(const QJsonObject& json) {
        currentVersion = json["current_version"].toString();
        latestVersion = json["latest_version"].toString();
        timestamp = json["timestamp"].toVariant().toLongLong();
        updateAvailable = _compareVersions(currentVersion, latestVersion) < 0;
    }
    
    // 기본 생성자
    RTCModuleVersionInfo() = default;
    
    // 비교 연산자 (변경 감지용)
    bool operator==(const RTCModuleVersionInfo& other) const {
        return currentVersion == other.currentVersion &&
               latestVersion == other.latestVersion &&
               timestamp == other.timestamp &&
               updateAvailable == other.updateAvailable;
    }
    
    bool operator!=(const RTCModuleVersionInfo& other) const {
        return !(*this == other);
    }
    
    // 유효성 검사
    bool isValid() const {
        return !currentVersion.isEmpty() && !latestVersion.isEmpty() && timestamp > 0;
    }
    
    // 디버그 출력용
    QString toString() const {
        return QString("Current: %1, Latest: %2, Update: %3, Time: %4")
               .arg(currentVersion)
               .arg(latestVersion)
               .arg(updateAvailable ? "Available" : "Up to date")
               .arg(QDateTime::fromMSecsSinceEpoch(timestamp).toString("yyyy-MM-dd hh:mm:ss"));
    }
    
private:
    // 버전 비교 함수 (semantic versioning 지원)
    int _compareVersions(const QString& v1, const QString& v2) const {
        QStringList parts1 = v1.split('.');
        QStringList parts2 = v2.split('.');
        
        int maxLength = qMax(parts1.size(), parts2.size());
        
        for (int i = 0; i < maxLength; ++i) {
            int num1 = (i < parts1.size()) ? parts1[i].toInt() : 0;
            int num2 = (i < parts2.size()) ? parts2[i].toInt() : 0;
            
            if (num1 < num2) return -1;
            if (num1 > num2) return 1;
        }
        
        return 0; // 동일한 버전
    }
};

Q_DECLARE_METATYPE(RTCModuleSystemInfo)
Q_DECLARE_METATYPE(RTCModuleVersionInfo)
Q_DECLARE_METATYPE(WebRTCStats)

class TransferRateCalculator {
   public:
    struct Stats {
        qint64 totalBytes = 0;
        qint64 totalPackets = 0;
        double currentRateKBps = 0.0;
        double averagePacketSize = 0.0;
    };

    TransferRateCalculator() : _lastUpdateTime(QDateTime::currentMSecsSinceEpoch()) {}

    void addData(qint64 bytes, int packets = 1) {
        _stats.totalBytes += bytes;
        _stats.totalPackets += packets;

        // 평균 패킷 크기 업데이트 (온라인 평균 계산)
        if (_stats.totalPackets > 0) {
            _stats.averagePacketSize = static_cast<double>(_stats.totalBytes) / _stats.totalPackets;
        }
    }

    void updateRate() {
        qint64 currentTime = QDateTime::currentMSecsSinceEpoch();
        qint64 timeDiff = currentTime - _lastUpdateTime;

        if (timeDiff > 0) {
            qint64 bytesDiff = _stats.totalBytes - _lastBytes;
            double rate = static_cast<double>(bytesDiff) / timeDiff; // KB/ms = KB/s
            _stats.currentRateKBps = std::round(rate * 100.0) / 100.0;

            _lastBytes = _stats.totalBytes;
            _lastUpdateTime = currentTime;
        }
    }

    const Stats& getStats() const { return _stats; }
    double getCurrentRate() const { return _stats.currentRateKBps; }

    void reset() {
        _stats = Stats{};
        _lastBytes = 0;
        _lastUpdateTime = QDateTime::currentMSecsSinceEpoch();
    }

   private:
    Stats _stats;
    qint64 _lastBytes = 0;
    qint64 _lastUpdateTime;
};


class WebRTCConfiguration : public LinkConfiguration
{
    Q_OBJECT

    Q_PROPERTY(QString gcsId READ gcsId WRITE setGcsId NOTIFY gcsIdChanged)
    Q_PROPERTY(QString targetDroneId READ targetDroneId WRITE setTargetDroneId NOTIFY targetDroneIdChanged)

   public:
    explicit WebRTCConfiguration(const QString &name, QObject *parent = nullptr);
    explicit WebRTCConfiguration(const WebRTCConfiguration *copy, QObject *parent = nullptr);
    ~WebRTCConfiguration();

    LinkType type() const override { return LinkConfiguration::TypeWebRTC; }
    void copyFrom(const LinkConfiguration *source) override;
    void loadSettings(QSettings &settings, const QString &root) override;
    void saveSettings(QSettings &settings, const QString &root) const override;
    QString settingsURL() const override { return QStringLiteral("WebRTCSettings.qml"); }
    QString settingsTitle() const override { return tr("WebRTC Link Settings"); }

            // Getters and Setters
    QString gcsId() const { return _gcsId; }
    void setGcsId(const QString &id);

    QString targetDroneId() const { return _targetDroneId; }
    void setTargetDroneId(const QString &id);

    // CloudSettings에서 WebRTC 설정을 가져오는 getter 메서드들
    QString stunServer() const;
    QString turnServer() const;
    QString turnUsername() const;
    QString turnPassword() const;

   signals:
    void gcsIdChanged();
    void targetDroneIdChanged();

   private:
    QString _gcsId;
    QString _targetDroneId;



    QString _generateRandomId(int length = 8) const;
};

/*===========================================================================*/

class WebRTCWorker : public QObject
{
    Q_OBJECT

   public:
    explicit WebRTCWorker(const WebRTCConfiguration *config, 
                         const QString &stunServer,
                         const QString &turnServer,
                         const QString &turnUsername,
                         const QString &turnPassword,
                         QObject *parent = nullptr);
    ~WebRTCWorker();

    void initializeLogger();
    bool isVideoStreamActive() const { return _videoStreamActive; }
    bool isDataChannelOpen() const;

   public slots:
    void start();
    void writeData(const QByteArray &data);
    void disconnectLink();
    void reconnectToRoom();  // 재연결 슬롯 추가
    void handlePeerStateChange(int stateValue);
    void handleLocalDescription(const QString& descType, const QString& sdpContent);
    void handleLocalCandidate(const QString& candidateStr, const QString& mid);
    void sendCustomMessage(const QString &message);
    bool isWaitingForReconnect() const;  // 자동 재연결 상태 확인

   signals:
    void connected();
    void disconnected();
    void bytesReceived(const QByteArray &data);
    void bytesSent(const QByteArray &data);
    void errorOccurred(const QString &errorString);
    void rttUpdated(int rtt);  // RTT 측정 signal
    void rtcStatusMessageChanged(const QString& message);
    void decodingStatsChanged(int total, int decoded, int dropped);

    void videoTrackReceived();                          // 비디오 트랙 수신 시그널
    void videoConfigurationChanged(const QString& codec, int width, int height);
    void videoRateChanged(double KBps);
    void videoStatsChanged(int packets, double avgSize, double rate);
    void statisticsUpdated();
    void dataChannelStatsChanged(qint64 bytesSent, qint64 bytesReceived,
                                 double sendRate, double receiveRate);

    void dataChannelStatsUpdated(double sendRate, double receiveRate);
    void videoStatsUpdated(double rate, qint64 packets, qint64 bytes);
    void rtcModuleSystemInfoUpdated(const RTCModuleSystemInfo& systemInfo);
    void webRtcStatsUpdated(const WebRTCStats& stats);
    void rtcModuleVersionInfoUpdated(const RTCModuleVersionInfo& versionInfo);

   private slots:
    void _onSignalingConnected();
    void _onSignalingDisconnected();
    void _onSignalingError(const QString& error);
    void _onSignalingMessageReceived(const QJsonObject& message);
    void _onRegistrationSuccessful();
    void _onRegistrationFailed(const QString& reason);
    void _onPeerStateChanged(rtc::PeerConnection::State state);
    void _onGatheringStateChanged(rtc::PeerConnection::GatheringState state);
    void _updateRtt();  // RTT 측정용 slot
    
    // GCS management slots
    void _onGcsUnregisteredSuccessfully(const QString& gcsId);
    void _onGcsUnregisterFailed(const QString& gcsId, const QString& reason);

   private:
    // Signaling management
    void _setupSignalingManager();
    void _handleSignalingMessage(const QJsonObject& message);
    void _handleICECandidate(const QJsonObject& message);
    void _sendSignalingMessage(const QJsonObject& message);
    
    // New WebRTC message handlers
    void _onGCSRegistered(const QJsonObject& message);
    void _prepareForWebRTCOffer();
    void _onWebRTCOfferReceived(const QJsonObject& message);
    void _sendPongResponse(const QJsonObject& pingMsg);
    void _onErrorReceived(const QJsonObject& message);

    // WebRTC peer connection
    void _setupPeerConnection();
    void _handleTrackReceived(std::shared_ptr<rtc::Track> track);
    void _setupMavlinkDataChannel(std::shared_ptr<rtc::DataChannel> dc);
    void _setupCustomDataChannel(std::shared_ptr<rtc::DataChannel> dc);
    void _processDataChannelOpen();
    void _processPendingCandidates();
    void _checkIceProcessingStatus();
    void _startTimers();
    QString _stateToString(rtc::PeerConnection::State state) const;
    QString _gatheringStateToString(rtc::PeerConnection::GatheringState state) const;

            // Cleanup
    void _cleanup();
    void _cleanupComplete();

                         // Configuration
    const WebRTCConfiguration *_config = nullptr;
    rtc::Configuration _rtcConfig;
    
    // 스레드 안전성을 위한 설정값 복사본
    QString _stunServer;
    QString _turnServer;
    QString _turnUsername;
    QString _turnPassword;

            // Signaling management
    SignalingServerManager *_signalingManager = nullptr;
    QTimer *_rttTimer = nullptr;

            // WebRTC components
    std::shared_ptr<rtc::PeerConnection> _peerConnection;
    std::shared_ptr<rtc::DataChannel> _mavlinkDataChannel;
    std::shared_ptr<rtc::DataChannel> _customDataChannel;
    std::shared_ptr<rtc::Track> _videoTrack;

    // State management
    std::vector<rtc::Candidate> _pendingCandidates;
    std::atomic_bool _remoteDescriptionSet {false};
    QMutex _candidateMutex;
    bool _isDisconnecting = false;
    std::atomic<bool> _dataChannelOpened{false};

            // Constants
    static const QString kDataChannelLabel;
    static const int kReconnectInterval = 5000; // 5 seconds

    std::atomic<bool> _isShuttingDown{false};
    bool _videoStreamActive = false;
    QString _currentVideoURI; // kept for API compatibility; unused without bridge
    
    // GCS connection management
    QString _currentGcsId;
    QString _currentTargetDroneId;
    bool _gcsRegistered = false;
    QTimer* _reconnectTimer = nullptr;  // 수동 재연결용 (자동 재연결 비활성화)
    std::atomic<bool> _waitingForReconnect{false};
    
    // 재연결 관리 (추가됨)
    int _reconnectAttempts = 0;
    static const int MAX_RECONNECT_ATTEMPTS = 10;
    static const int BASE_RECONNECT_DELAY_MS = 1000;
    static const int MAX_RECONNECT_DELAY_MS = 30000;

    void _updateAllStatistics();
    void _calculateDataChannelRates(qint64 currentTime);
    int _calculateReconnectDelay() const;  // 지수 백오프 계산
    void _resetReconnectAttempts();        // 재연결 시도 횟수 리셋

    void _handlePeerDisconnection();
    void _cleanupForReconnection();
    void _resetPeerConnection();
    void _forceReconnection();
    QTimer* _reconnectionTimer = nullptr;
    std::atomic<bool> _waitingForReconnection{false};

    TransferRateCalculator _dataChannelSentCalc;
    TransferRateCalculator _dataChannelReceivedCalc;
    TransferRateCalculator _videoReceivedCalc;

    QTimer* _statsTimer = nullptr;
    
    // RTT 값 저장
    int _rttMs = -1;

   public:
    bool isOperational() const;
};

/*===========================================================================*/

class WebRTCLink : public LinkInterface
{
    Q_OBJECT
    Q_PROPERTY(QString rtcStatusMessage READ rtcStatusMessage NOTIFY rtcStatusMessageChanged)
    Q_PROPERTY(RTCModuleSystemInfo rtcModuleSystemInfo READ rtcModuleSystemInfo NOTIFY rtcModuleSystemInfoChanged)
    Q_PROPERTY(WebRTCStats webRtcStats READ webRtcStats NOTIFY webRtcStatsChanged)
    Q_PROPERTY(RTCModuleVersionInfo rtcModuleVersionInfo READ rtcModuleVersionInfo NOTIFY rtcModuleVersionInfoChanged)

   public:
    explicit WebRTCLink(SharedLinkConfigurationPtr &config, QObject *parent = nullptr);
    ~WebRTCLink();

    Q_INVOKABLE void sendCustomMessage(const QString& message);

    bool isConnected() const override;
    void connectLink();
    void reconnectLink();  // 재연결 메서드 추가
    bool isReconnecting() const;  // 자동 재연결 상태 확인

    QString rtcStatusMessage() const { return _rtcStatusMessage; }

    // 비디오 스트림 상태 확인
    bool isVideoStreamActive() const;
    
    // RTC Module 시스템 정보 getter
    const RTCModuleSystemInfo& rtcModuleSystemInfo() const { return _rtcModuleSystemInfo; }
    
    // WebRTC 통계 정보 getter
    const WebRTCStats& webRtcStats() const { return _webRtcStats; }
    
    // RTC Module 버전 정보 getter
    const RTCModuleVersionInfo& rtcModuleVersionInfo() const { return _rtcModuleVersionInfo; }

   protected:
    bool _connect() override;
    void disconnect() override;
    void _writeBytes(const QByteArray& bytes) override;

   private slots:
    void _onConnected();
    void _onDisconnected();
    void _onErrorOccurred(const QString &errorString);
    void _onDataReceived(const QByteArray &data);
    void _onDataSent(const QByteArray &data);
    void _onRtcStatusMessageChanged(const QString& message);
    void _onRtcModuleSystemInfoUpdated(const RTCModuleSystemInfo& systemInfo);
    void _onWebRtcStatsUpdated(const WebRTCStats& stats);
    void _onRtcModuleVersionInfoUpdated(const RTCModuleVersionInfo& versionInfo);

   signals:
    void rtcStatusMessageChanged();
    void videoStreamReady(const QString& uri);
    void videoStatsUpdated(double KBps, int packets, qint64 totalBytes);
    void rtcModuleSystemInfoChanged(const RTCModuleSystemInfo& systemInfo);
    void webRtcStatsChanged(const WebRTCStats& stats);
    void rtcModuleVersionInfoChanged(const RTCModuleVersionInfo& versionInfo);

   private:
    const WebRTCConfiguration *_rtcConfig = nullptr;
    WebRTCWorker *_worker = nullptr;
    QThread *_workerThread = nullptr;
    QString _rtcStatusMessage = "";
    
    // RTC Module 시스템 정보
    RTCModuleSystemInfo _rtcModuleSystemInfo;
    
    // WebRTC 통계 정보
    WebRTCStats _webRtcStats;
    
    // RTC Module 버전 정보
    RTCModuleVersionInfo _rtcModuleVersionInfo;
};
