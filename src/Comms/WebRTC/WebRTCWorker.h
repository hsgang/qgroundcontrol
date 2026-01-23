#pragma once

#include <rtc/rtc.hpp>
#include <memory>
#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QMutex>
#include <QtCore/QMutexLocker>
#include <QtCore/QTimer>
#include <QtCore/QJsonObject>
#include <QtCore/QLoggingCategory>
#include <QtCore/QDateTime>
#include <QRandomGenerator>
#include <atomic>
#include <vector>
#include <array>

#include "WebRTCConfiguration.h"
#include "WebRTCStats.h"

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

// 비디오 메트릭 정보를 효율적으로 묶어서 전달하기 위한 구조체
struct VideoMetrics {
    double rtspPacketsPerSec = 0.0;
    double decodedFramesPerSec = 0.0;
    double encodedFramesPerSec = 0.0;
    double teeFramesPerSec = 0.0;
    double srtFramesPerSec = 0.0;
    double rtpFramesPerSec = 0.0;
    qint64 timestamp = 0;

    // JSON에서 파싱하는 생성자
    VideoMetrics(const QJsonObject& json) {
        timestamp = json["timestamp"].toVariant().toLongLong();

        QJsonObject perSecond = json["per_second"].toObject();
        rtspPacketsPerSec = perSecond["rtsp_packets_ps"].toDouble();
        decodedFramesPerSec = perSecond["decoded_frames_ps"].toDouble();
        encodedFramesPerSec = perSecond["encoded_frames_ps"].toDouble();
        teeFramesPerSec = perSecond["tee_frames_ps"].toDouble();
        srtFramesPerSec = perSecond["srt_frames_ps"].toDouble();
        rtpFramesPerSec = perSecond["rtp_frames_ps"].toDouble();
    }

    // 기본 생성자
    VideoMetrics() = default;

    // 비교 연산자 (변경 감지용)
    bool operator==(const VideoMetrics& other) const {
        return qFuzzyCompare(rtspPacketsPerSec, other.rtspPacketsPerSec) &&
               qFuzzyCompare(decodedFramesPerSec, other.decodedFramesPerSec) &&
               qFuzzyCompare(encodedFramesPerSec, other.encodedFramesPerSec) &&
               qFuzzyCompare(teeFramesPerSec, other.teeFramesPerSec) &&
               qFuzzyCompare(srtFramesPerSec, other.srtFramesPerSec) &&
               qFuzzyCompare(rtpFramesPerSec, other.rtpFramesPerSec) &&
               timestamp == other.timestamp;
    }

    bool operator!=(const VideoMetrics& other) const {
        return !(*this == other);
    }

    // 유효성 검사
    bool isValid() const {
        return rtspPacketsPerSec >= 0.0 && decodedFramesPerSec >= 0.0 &&
               encodedFramesPerSec >= 0.0 && teeFramesPerSec >= 0.0 &&
               srtFramesPerSec >= 0.0 && rtpFramesPerSec >= 0.0 &&
               timestamp > 0;
    }

    // 디버그 출력용
    QString toString() const {
        return QString("RTSP: %1 pkt/s, Decoded: %2 fps, Encoded: %3 fps, RTP: %6 fps")
               .arg(rtspPacketsPerSec, 0, 'f', 1)
               .arg(decodedFramesPerSec, 0, 'f', 1)
               .arg(encodedFramesPerSec, 0, 'f', 1)
               .arg(rtpFramesPerSec, 0, 'f', 1);
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
Q_DECLARE_METATYPE(VideoMetrics)
Q_DECLARE_METATYPE(RTCModuleVersionInfo)

class TransferRateCalculator {
   public:
    struct Stats {
        qint64 totalBytes = 0;
        qint64 totalPackets = 0;
        double currentRateKBps = 0.0;
        double averagePacketSize = 0.0;
    };

    TransferRateCalculator()
        : _lastUpdateTime(QDateTime::currentMSecsSinceEpoch())
        , _smoothedRate(0.0)
    {}

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

            // 올바른 단위 변환: Bytes/ms -> KB/s
            // = (Bytes / 1024) / (ms / 1000)
            // = Bytes * 1000 / 1024 / ms
            // = Bytes * 0.9765625 / ms
            double instantRate = static_cast<double>(bytesDiff) * 1000.0 / 1024.0 / timeDiff;

            // 지수 이동 평균 (EMA)으로 급격한 변동 완화
            // alpha = 0.3: 현재 값 20%, 이전 값 80% 반영
            const double alpha = 0.2;
            _smoothedRate = (_smoothedRate == 0.0) ? instantRate : (alpha * instantRate + (1.0 - alpha) * _smoothedRate);

            _stats.currentRateKBps = std::round(_smoothedRate * 100.0) / 100.0;

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
        _smoothedRate = 0.0;
    }

   private:
    Stats _stats;
    qint64 _lastBytes = 0;
    qint64 _lastUpdateTime;
    double _smoothedRate;  // 이동 평균을 위한 상태 변수
};

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
    void disconnectFromSignalingManager();  // SignalingServerManager 연결 끊기
    void reconnectToRoom();  // 자동 재연결 슬롯 (Reconnecting 상태에서만 작동)
    void manualReconnect();  // 수동 재연결 슬롯 (어떤 상태에서든 작동)
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
    void videoMetricsUpdated(const VideoMetrics& videoMetrics);
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
    void _connectSignalingSignals();  // 시그널 연결 헬퍼 함수
    void _handleSignalingMessage(const QJsonObject& message);
    void _handleICECandidate(const QJsonObject& message);
    void _sendSignalingMessage(const QJsonObject& message);

    // New WebRTC message handlers
    void _onGCSRegistered(const QJsonObject& message);
    void _onWebRTCOfferReceived(const QJsonObject& message);
    void _sendPongResponse(const QJsonObject& pingMsg);
    void _onErrorReceived(const QJsonObject& message);

    // WebRTC peer connection
    void _setupPeerConnection();
    void _handleTrackReceived(std::shared_ptr<rtc::Track> track);
    void _setupMavlinkDataChannel(std::shared_ptr<rtc::DataChannel> dc);
    void _setupCustomDataChannel(std::shared_ptr<rtc::DataChannel> dc);
    void _processDataChannelOpen();
    void _startTimers();
    QString _stateToString(rtc::PeerConnection::State state) const;
    QString _gatheringStateToString(rtc::PeerConnection::GatheringState state) const;

    // Cleanup
    enum class CleanupMode {
        ForReconnection,  // WebRTC만 정리, 시그널링은 유지
        Complete          // 모든 리소스 정리
    };
    void _cleanup(CleanupMode mode = CleanupMode::ForReconnection);

    // Configuration - 값 객체로 복사하여 포인터 의존성 제거
    struct ConnectionConfig {
        QString gcsId;
        QString targetDroneId;
        QString stunServer;
        QString turnServer;
        QString turnUsername;
        QString turnPassword;
    } _connectionConfig;

    // Signaling and reconnection management
    SignalingServerManager *_signalingManager = nullptr;
    QTimer *_rttTimer = nullptr;
    QTimer *_cleanupTimer = nullptr;  // disconnect 후 cleanup용 타이머
    QTimer *_reconnectTimer = nullptr;  // 재연결용 타이머

    // 재연결 상태
    std::atomic<bool> _waitingForReconnect{false};
    int _reconnectAttempts = 0;
    static constexpr int MAX_RECONNECT_ATTEMPTS = 10;
    static constexpr int BASE_RECONNECT_DELAY_MS = 1000;
    static constexpr int MAX_RECONNECT_DELAY_MS = 30000;

    // PeerConnection 컨텍스트 구조체
    struct PeerConnectionContext {
        // WebRTC components
        std::shared_ptr<rtc::PeerConnection> pc;              // PeerConnection (STUN+TURN)
        std::shared_ptr<rtc::DataChannel> mavlinkDc;          // MAVLink DataChannel
        std::shared_ptr<rtc::DataChannel> customDc;           // Custom DataChannel
        std::shared_ptr<rtc::Track> videoTrack;               // Video track

        // State management
        std::vector<rtc::Candidate> pendingCandidates;        // 대기 중인 ICE candidates
        QMutex candidateMutex;                                // pendingCandidates 보호용 mutex

        // Connection state flags (atomic for thread-safety)
        std::atomic<bool> remoteDescriptionSet{false};        // Remote description 설정 여부
        std::atomic<bool> dataChannelOpened{false};           // DataChannel 오픈 여부

        // Constructor
        PeerConnectionContext() = default;

        // 리셋 메서드
        void reset() {
            // Close and reset peer connection
            if (pc) {
                try {
                    pc->close();
                } catch (const std::exception& e) {
                    qCWarning(WebRTCLinkLog) << "Exception while closing PeerConnection:" << e.what();
                } catch (...) {
                    qCWarning(WebRTCLinkLog) << "Unknown exception while closing PeerConnection";
                }
                pc.reset();
            }

            // Close and reset data channels
            if (mavlinkDc) {
                try {
                    if (mavlinkDc->isOpen()) {
                        mavlinkDc->close();
                    }
                } catch (const std::exception& e) {
                    qCWarning(WebRTCLinkLog) << "Exception while closing mavlinkDc:" << e.what();
                } catch (...) {
                    qCWarning(WebRTCLinkLog) << "Unknown exception while closing mavlinkDc";
                }
                mavlinkDc.reset();
            }

            if (customDc) {
                try {
                    if (customDc->isOpen()) {
                        customDc->close();
                    }
                } catch (const std::exception& e) {
                    qCWarning(WebRTCLinkLog) << "Exception while closing customDc:" << e.what();
                } catch (...) {
                    qCWarning(WebRTCLinkLog) << "Unknown exception while closing customDc";
                }
                customDc.reset();
            }

            // Reset video track
            if (videoTrack) {
                videoTrack.reset();
            }

            // Clear state
            remoteDescriptionSet.store(false);
            dataChannelOpened.store(false);
            {
                QMutexLocker locker(&candidateMutex);
                pendingCandidates.clear();
            }
        }

        // 연결 여부 확인
        bool isConnected() const {
            return pc && pc->state() == rtc::PeerConnection::State::Connected;
        }

        // DataChannel 열림 여부 확인
        bool hasOpenDataChannel() const {
            return (mavlinkDc && mavlinkDc->isOpen()) || (customDc && customDc->isOpen());
        }
    };

    // Single PeerConnection context with ICE auto-selection
    PeerConnectionContext _pcContext;

    // State Machine for Worker State Management
    enum class WorkerState : uint8_t {
        Idle,                  // 초기 상태 또는 완전히 정지된 상태
        Starting,              // start() 호출 후 초기화 중
        Connecting,            // 시그널링 연결 및 GCS 등록 중
        WaitingForOffer,       // 시그널링 연결됨, offer 대기 중
        EstablishingPeer,      // PeerConnection 설정 중 (offer/answer 교환)
        Connected,             // DataChannel 오픈, 통신 가능
        Disconnecting,         // 사용자 요청으로 연결 해제 중
        Reconnecting,          // 자동 재연결 대기 중
        CleaningUp,           // 리소스 정리 중
        Shutdown               // 완전 종료 (소멸자 호출)
    };

    // 상태 머신 관리
    std::atomic<WorkerState> _state{WorkerState::Idle};

    // 상태 전이 헬퍼 메서드
    bool transitionState(WorkerState expected, WorkerState desired);
    bool isInState(WorkerState state) const { return _state.load() == state; }
    bool canTransitionTo(WorkerState newState) const;
    QString stateToString() const;
    QString stateToString(WorkerState state) const;

    // 상태 체크 헬퍼 메서드
    bool isShuttingDown() const { return isInState(WorkerState::Shutdown); }
    bool isDisconnecting() const { return isInState(WorkerState::Disconnecting); }
    bool isCallbackSafe() const {
        WorkerState state = _state.load();
        return state != WorkerState::Shutdown && state != WorkerState::CleaningUp;
    }

    // Constants
    static const QString kDataChannelLabel;
    static const int kReconnectInterval = 5000; // 5 seconds

    // SCTP Configuration Constants
    static constexpr int SCTP_RECV_BUFFER_SIZE = 262144;        // 256KB
    static constexpr int SCTP_SEND_BUFFER_SIZE = 262144;        // 256KB
    static constexpr int SCTP_MAX_CHUNKS_ON_QUEUE = 1000;
    static constexpr int SCTP_INITIAL_CONGESTION_WINDOW = 10;
    static constexpr int SCTP_MAX_BURST = 5;
    static constexpr int SCTP_CONGESTION_CONTROL_MODULE = 0;    // RFC2581
    static constexpr int SCTP_DELAYED_SACK_TIME_MS = 200;
    static constexpr int SCTP_MIN_RETRANSMIT_TIMEOUT_MS = 1000;
    static constexpr int SCTP_MAX_RETRANSMIT_TIMEOUT_MS = 5000;
    static constexpr int SCTP_INITIAL_RETRANSMIT_TIMEOUT_MS = 3000;
    static constexpr int SCTP_MAX_RETRANSMIT_ATTEMPTS = 5;
    static constexpr int SCTP_HEARTBEAT_INTERVAL_MS = 10000;

    // Timer Intervals
    static constexpr int RTT_UPDATE_INTERVAL_MS = 200;
    static constexpr int STATS_UPDATE_INTERVAL_MS = 500;

    // Reconnection Constants
    static constexpr int RECONNECT_DELAY_MIN_MS = 1000;
    static constexpr int RECONNECT_JITTER_MS = 500;

    // Video stream state
    std::atomic<bool> _videoStreamActive{false};
    QString _currentVideoURI; // kept for API compatibility; unused without bridge

    // GCS connection management
    QString _currentGcsId;
    QString _currentTargetDroneId;
    bool _gcsRegistered = false;

    void _updateAllStatistics();
    WebRTCStats _collectWebRTCStats() const;  // 통합 통계 수집 메서드

    void _handlePeerDisconnection();
    void _resetPeerConnection();
    void _setupPeerConnectionCallbacks(std::shared_ptr<rtc::PeerConnection> pc);
    void _processReceivedData(const QByteArray& data);
    void _processPendingICECandidates();
    bool _validateSignalingMessage(const QJsonObject& message, const QStringList& requiredFields) const;

    // 재연결 관리
    int _calculateReconnectDelay() const;
    void _scheduleReconnect();
    void _cancelReconnect();
    void _onReconnectSuccess();

    // 타이머 관리
    void _safeDeleteTimer(QTimer*& timer, const char* name);

    // 송수신 통계
    TransferRateCalculator _dataChannelSentCalc;
    TransferRateCalculator _dataChannelReceivedCalc;
    TransferRateCalculator _videoReceivedCalc;

    QTimer* _statsTimer = nullptr;

    // RTT 값 저장
    int _rttMs = 0;

    // Cleanup 재진입성 가드
    std::atomic<bool> _cleanupInProgress{false};

    // ICE candidate 캐시
    QString _cachedCandidate;
    mutable QMutex _cachedCandidateMutex;  // _cachedCandidate 보호용 mutex (const 메서드에서도 사용 가능)

    // RTT 업데이트 로깅용 (static 변수 대체)
    QString _lastCandidateForLog;

    // 버퍼 관리
    static const size_t BUFFER_LOW_THRESHOLD = 8 * 1024;  // 8KB - DataChannel bufferedAmountLow 임계값

   public:
    bool isOperational() const;
};
