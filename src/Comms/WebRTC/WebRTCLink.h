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

/*===========================================================================*/

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

    Q_PROPERTY(QString roomId READ roomId WRITE setRoomId NOTIFY roomIdChanged)
    Q_PROPERTY(QString peerId READ peerId WRITE setPeerId NOTIFY peerIdChanged)
    Q_PROPERTY(QString targetPeerId READ targetPeerId WRITE setTargetPeerId NOTIFY targetPeerIdChanged)

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
    QString roomId() const { return _roomId; }
    void setRoomId(const QString &id);

    QString peerId() const { return _peerId; }
    void setPeerId(const QString &id);

    QString targetPeerId() const { return _targetPeerId; }
    void setTargetPeerId(const QString &id);

    // CloudSettings에서 WebRTC 설정을 가져오는 getter 메서드들
    QString stunServer() const;
    QString turnServer() const;
    QString turnUsername() const;
    QString turnPassword() const;

   signals:
    void roomIdChanged();
    void peerIdChanged();
    void targetPeerIdChanged();

   private:
    QString _roomId;
    QString _peerId;
    QString _targetPeerId;



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
    void rtcModuleSystemInfoUpdated(double cpuUsage, double cpuTemperature, double memoryUsage,
                                   double networkRx, double networkTx, const QString& networkInterface);

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
    
    // Room management slots
    void _onPeerLeftSuccessfully(const QString& peerId, const QString& roomId);
    void _onPeerLeaveFailed(const QString& peerId, const QString& reason);

   private:
    // Signaling management
    void _setupSignalingManager();
    void _handleSignalingMessage(const QJsonObject& message);
    void _handleCandidate(const QJsonObject& message);
    void _sendSignalingMessage(const QJsonObject& message);

    // WebRTC peer connection
    void _setupPeerConnection();
    void _handleTrackReceived(std::shared_ptr<rtc::Track> track);
    void _setupMavlinkDataChannel(std::shared_ptr<rtc::DataChannel> dc);
    void _setupCustomDataChannel(std::shared_ptr<rtc::DataChannel> dc);
    void _processDataChannelOpen();
    void _processPendingCandidates();
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
    
    // Room management
    QString _currentRoomId;
    QString _currentPeerId;
    bool _roomLeftSuccessfully = false;
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
    QTimer* _reconnectionTimer = nullptr;
    std::atomic<bool> _waitingForReconnection{false};

    TransferRateCalculator _dataChannelSentCalc;
    TransferRateCalculator _dataChannelReceivedCalc;
    TransferRateCalculator _videoReceivedCalc;

    QTimer* _statsTimer = nullptr;

   public:
    bool isOperational() const;
};

/*===========================================================================*/

class WebRTCLink : public LinkInterface
{
    Q_OBJECT
    Q_PROPERTY(int rttMs READ rttMs NOTIFY rttMsChanged)
    Q_PROPERTY(QString rtcStatusMessage READ rtcStatusMessage NOTIFY rtcStatusMessageChanged)
    Q_PROPERTY(double videoRateKBps READ videoRateKBps NOTIFY videoRateKBpsChanged)
    Q_PROPERTY(int videoPacketCount READ videoPacketCount NOTIFY videoPacketCountChanged)
    Q_PROPERTY(qint64 videoBytesReceived READ videoBytesReceived NOTIFY videoBytesReceivedChanged)
    Q_PROPERTY(double rtcModuleCpuUsage READ rtcModuleCpuUsage NOTIFY rtcModuleSystemInfoChanged)
    Q_PROPERTY(double rtcModuleCpuTemperature READ rtcModuleCpuTemperature NOTIFY rtcModuleSystemInfoChanged)
    Q_PROPERTY(double rtcModuleMemoryUsage READ rtcModuleMemoryUsage NOTIFY rtcModuleSystemInfoChanged)
    Q_PROPERTY(double rtcModuleNetworkRx READ rtcModuleNetworkRx NOTIFY rtcModuleSystemInfoChanged)
    Q_PROPERTY(double rtcModuleNetworkTx READ rtcModuleNetworkTx NOTIFY rtcModuleSystemInfoChanged)
    Q_PROPERTY(QString rtcModuleNetworkInterface READ rtcModuleNetworkInterface NOTIFY rtcModuleSystemInfoChanged)

   public:
    explicit WebRTCLink(SharedLinkConfigurationPtr &config, QObject *parent = nullptr);
    ~WebRTCLink();

    Q_INVOKABLE void sendCustomMessage(const QString& message);

    bool isConnected() const override;
    void connectLink();
    void reconnectLink();  // 재연결 메서드 추가
    bool isReconnecting() const;  // 자동 재연결 상태 확인

    int rttMs() const { return _rttMs; }
    double webRtcSent() const { return _webRtcSent; }
    double webRtcRecv() const { return _webRtcRecv; }
    QString rtcStatusMessage() const { return _rtcStatusMessage; }

    // 비디오 스트림 상태 확인
    bool isVideoStreamActive() const;

    double videoRateKBps() const { return _videoRateKBps; }
    int videoPacketCount() const { return _videoPacketCount; }
    qint64 videoBytesReceived() const { return _videoBytesReceived; }
    
    // RTC Module 시스템 정보 getter
    double rtcModuleCpuUsage() const { return _rtcModuleCpuUsage; }
    double rtcModuleCpuTemperature() const { return _rtcModuleCpuTemperature; }
    double rtcModuleMemoryUsage() const { return _rtcModuleMemoryUsage; }
    double rtcModuleNetworkRx() const { return _rtcModuleNetworkRx; }
    double rtcModuleNetworkTx() const { return _rtcModuleNetworkTx; }
    QString rtcModuleNetworkInterface() const { return _rtcModuleNetworkInterface; }

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
    void _onRttUpdated(int rtt);
    void _onDataChannelStatsChanged(double sendRate, double receiveRate);
    void _onRtcStatusMessageChanged(const QString& message);
    void _onVideoRateChanged(double KBps);
    void _onRtcModuleSystemInfoUpdated(double cpuUsage, double cpuTemperature, double memoryUsage, 
                                      double networkRx, double networkTx, const QString& networkInterface);

   signals:
    void rttMsChanged();
    void webRtcSentChanged();
    void webRtcRecvChanged();
    void rtcStatusMessageChanged();
    void videoStreamReady(const QString& uri);
    void videoRateKBpsChanged();
    void videoPacketCountChanged();
    void videoBytesReceivedChanged();
    void videoStatsUpdated(double KBps, int packets, qint64 totalBytes);
    void rtcModuleSystemInfoChanged(double cpuUsage, double cpuTemperature, double memoryUsage, 
                                   double networkRx, double networkTx, const QString& networkInterface);

   private:
    const WebRTCConfiguration *_rtcConfig = nullptr;
    WebRTCWorker *_worker = nullptr;
    QThread *_workerThread = nullptr;
    int _rttMs = -1;
    double _webRtcSent = -1;
    double _webRtcRecv = -1;
    int _videoRate = -1;
    double _videoRateKBps = 0.0;
    int _videoPacketCount = 0;
    qint64 _videoBytesReceived = 0;
    QString _rtcStatusMessage = "";
    
    // RTC Module 시스템 정보
    double _rtcModuleCpuUsage = 0.0;
    double _rtcModuleCpuTemperature = 0.0;
    double _rtcModuleMemoryUsage = 0.0;
    double _rtcModuleNetworkRx = 0.0;
    double _rtcModuleNetworkTx = 0.0;
    QString _rtcModuleNetworkInterface = "";
};
