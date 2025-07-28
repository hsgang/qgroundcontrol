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
#include <QtNetwork/QUdpSocket>
#include <QtCore/QByteArray>

#include "LinkConfiguration.h"
#include "LinkInterface.h"
#include "VideoManager.h"

class QThread;
class WebRTCLink;

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
    Q_PROPERTY(QString signalingServer READ signalingServer WRITE setSignalingServer NOTIFY signalingServerChanged)
    Q_PROPERTY(QString stunServer READ stunServer WRITE setStunServer NOTIFY stunServerChanged)
    Q_PROPERTY(QString turnServer READ turnServer WRITE setTurnServer NOTIFY turnServerChanged)
    Q_PROPERTY(QString turnUsername READ turnUsername WRITE setTurnUsername NOTIFY turnUsernameChanged)
    Q_PROPERTY(QString turnPassword READ turnPassword WRITE setTurnPassword NOTIFY turnPasswordChanged)
    Q_PROPERTY(bool udpMuxEnabled READ udpMuxEnabled WRITE setUdpMuxEnabled NOTIFY udpMuxEnabledChanged)

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

    QString signalingServer() const { return _signalingServer; }
    void setSignalingServer(const QString &url);

    QString stunServer() const { return _stunServer; }
    void setStunServer(const QString &url);

    QString turnServer() const { return _turnServer; }
    void setTurnServer(const QString &url);

    QString turnUsername() const { return _turnUsername; }
    void setTurnUsername(const QString &username);

    QString turnPassword() const { return _turnPassword; }
    void setTurnPassword(const QString &password);

    bool udpMuxEnabled() const { return _udpMuxEnabled; }
    void setUdpMuxEnabled(bool enabled);

   signals:
    void roomIdChanged();
    void peerIdChanged();
    void targetPeerIdChanged();
    void signalingServerChanged();
    void signalingPortChanged();
    void stunServerChanged();
    void stunPortChanged();
    void turnServerChanged();
    void turnUsernameChanged();
    void turnPasswordChanged();
    void udpMuxEnabledChanged();

   private:
    QString _roomId;
    QString _peerId;
    QString _targetPeerId;
    QString _signalingServer;
    QString _stunServer = "stun.l.google.com:19302";
    QString _turnServer;
    QString _turnUsername;
    QString _turnPassword;
    bool _udpMuxEnabled = false;

    QString _generateRandomId(int length = 8) const;
};

/*===========================================================================*/

class WebRTCVideoBridge : public QObject
{
    Q_OBJECT

   public:
    explicit WebRTCVideoBridge(QObject* parent = nullptr);
    ~WebRTCVideoBridge();

            // 브리지 시작/중지
    bool startBridge(quint16 localPort = 0);  // 0이면 자동 할당
    void stopBridge();

    // 포트 정보
    quint16 localPort() const { return _localPort; }
    QString localAddress() const { return "127.0.0.1"; }

    // WebRTC에서 받은 RTP 데이터 전달
    void forwardRTPData(const rtc::binary& rtpData);

   signals:
    void bridgeStarted(quint16 port);
    void bridgeStopped();
    void errorOccurred(const QString& error);
    void retryBridgeRequested();  // 브리지 재시도 요청 시그널

   private slots:
    void _startDecodingCheckTimer();
    void _checkDecodingStatus();

   private:
    QUdpSocket* _udpSocket = nullptr;
    quint16 _localPort = 0;
    bool _isRunning = false;

    QTimer* _decodingCheckTimer;  // 디코딩 상태 체크 타이머
    bool _firstPacketSent = false;  // 첫 패킷 전송 플래그
    int _retryCount = 0;  // 재시도 횟수

    // 통계
    qint64 _totalPackets = 0;
    qint64 _totalBytes = 0;
};

/*===========================================================================*/

class WebRTCWorker : public QObject
{
    Q_OBJECT

   public:
    explicit WebRTCWorker(const WebRTCConfiguration *config, QObject *parent = nullptr);
    ~WebRTCWorker();

    void initializeLogger();
    bool isVideoStreamActive() const { return _videoStreamActive; }
    QString currentVideoUri() const { return _currentVideoURI; }
    bool isDataChannelOpen() const;

   public slots:
    void start();
    void writeData(const QByteArray &data);
    void disconnectLink();
    void handlePeerStateChange(int stateValue);
    void handleLocalDescription(const QString& descType, const QString& sdpContent);
    void handleLocalCandidate(const QString& candidateStr, const QString& mid);

   signals:
    void connected();
    void disconnected();
    void bytesReceived(const QByteArray &data);
    void bytesSent(const QByteArray &data);
    void errorOccurred(const QString &errorString);
    void rttUpdated(int rtt);  // RTT 측정 signal
    void rtcStatusMessageChanged(QString message);
    void decodingStatsChanged(int total, int decoded, int dropped);

    void videoTrackReceived();                          // 비디오 트랙 수신 시그널
    void videoConfigurationChanged(const QString& codec, int width, int height);
    void videoBridgeError(const QString& error);
    void videoRateChanged(double KBps);
    void videoStatsChanged(int packets, double avgSize, double rate);
    void statisticsUpdated();
    void dataChannelStatsChanged(qint64 bytesSent, qint64 bytesReceived,
                                 double sendRate, double receiveRate);

    void dataChannelStatsUpdated(double sendRate, double receiveRate);
    void videoStatsUpdated(double rate, qint64 packets, qint64 bytes);

   private slots:
    void _onWebSocketConnected();
    void _onWebSocketDisconnected();
    void _onWebSocketError(QAbstractSocket::SocketError error);
    void _onWebSocketMessageReceived(const QString& message);
    void _onPeerStateChanged(rtc::PeerConnection::State state);
    void _onGatheringStateChanged(rtc::PeerConnection::GatheringState state);
    void _updateRtt();  // RTT 측정용 slot

   private:
    // WebSocket signaling
    void _setupWebSocket();
    void _connectToSignalingServer();
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
    void _startQtTimers();
    QString _stateToString(rtc::PeerConnection::State state) const;
    QString _gatheringStateToString(rtc::PeerConnection::GatheringState state) const;

            // Cleanup
    void _cleanup();
    void _cleanupComplete();

            // Configuration
    const WebRTCConfiguration *_config = nullptr;
    rtc::Configuration _rtcConfig;

            // WebSocket for signaling
    QWebSocket *_webSocket = nullptr;
    bool _signalingConnected = false;
    QTimer *_rttTimer = nullptr;

            // WebRTC components
    std::shared_ptr<rtc::PeerConnection> _peerConnection;
    std::shared_ptr<rtc::DataChannel> _mavlinkDataChannel;
    std::shared_ptr<rtc::DataChannel> _customDataChannel;
    std::shared_ptr<rtc::Track> _videoTrack;

    // State management
    std::vector<rtc::Candidate> _pendingCandidates;
    std::set<std::string> _addedCandidates;
    std::atomic_bool _remoteDescriptionSet {false};
    QMutex _candidateMutex;
    bool _isOfferer = false;
    bool _isDisconnecting = false;
    std::atomic<bool> _dataChannelOpened{false};

            // Constants
    static const QString kDataChannelLabel;
    static const int kReconnectInterval = 5000; // 5 seconds

    bool _videoTrackReceived = false;
    int _totalFramesReceived = 0;
    int _decodedFrames = 0;
    int _droppedFrames = 0;

    std::atomic<bool> _isShuttingDown{false};
    QMutex _videoStatsMutex;
    QRecursiveMutex _videoBridgeMutex;
    QAtomicPointer<WebRTCVideoBridge> _videoBridgeAtomic;
    WebRTCVideoBridge *_videoBridge = nullptr;
    bool _videoStreamActive = false;
    QString _currentVideoURI;

    void _createVideoBridge();
    void _cleanupVideoBridge();
    void _handleVideoTrackData(const rtc::binary &data);
    void _restartVideoBridge();

    enum BridgeState {
        BRIDGE_NOT_READY,
        BRIDGE_STARTING,
        BRIDGE_READY,
        BRIDGE_STREAMING
    };

    BridgeState _bridgeState = BRIDGE_NOT_READY;

    void _updateAllStatistics();
    void _calculateDataChannelRates(qint64 currentTime);

    void _handlePeerDisconnection();
    void _cleanupForReconnection();
    QTimer* _reconnectionTimer = nullptr;
    std::atomic<bool> _waitingForReconnection{false};

    TransferRateCalculator _dataChannelSentCalc;
    TransferRateCalculator _dataChannelReceivedCalc;
    TransferRateCalculator _videoReceivedCalc;

    QTimer* _statsTimer = nullptr;

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

   public:
    explicit WebRTCLink(SharedLinkConfigurationPtr &config, QObject *parent = nullptr);
    ~WebRTCLink();

    bool isConnected() const override;
    void connectLink();

    int rttMs() const { return _rttMs; }
    QString rtcStatusMessage() const { return _rtcStatusMessage; }

    // 비디오 스트림 상태 확인
    bool isVideoStreamActive() const;
    QString videoStreamUri() const;

    double videoRateKBps() const { return _videoRateKBps; }
    int videoPacketCount() const { return _videoPacketCount; }
    qint64 videoBytesReceived() const { return _videoBytesReceived; }

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
    void _onRttUpdated(int rtt);   // RTT 업데이트 슬롯
    void _onRtcStatusMessageChanged(QString message);
    void _onVideoBridgeError(const QString& error);
    void _onVideoRateChanged(double KBps);

   signals:
    void rttMsChanged();
    void rtcStatusMessageChanged();
    void videoStreamReady(const QString& uri);
    void videoBridgeError(const QString& error);
    void videoRateKBpsChanged();
    void videoPacketCountChanged();
    void videoBytesReceivedChanged();
    void videoStatsUpdated(double KBps, int packets, qint64 totalBytes);

   private:
    const WebRTCConfiguration *_rtcConfig = nullptr;
    WebRTCWorker *_worker = nullptr;
    QThread *_workerThread = nullptr;
    int _rttMs = -1;
    int _videoRate = -1;
    double _videoRateKBps = 0.0;
    int _videoPacketCount = 0;
    qint64 _videoBytesReceived = 0;
    QString _rtcStatusMessage = "";
};
