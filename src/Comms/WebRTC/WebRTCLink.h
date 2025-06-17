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

#include "LinkConfiguration.h"
#include "LinkInterface.h"

class QThread;
class WebRTCLink;

Q_DECLARE_LOGGING_CATEGORY(WebRTCLinkLog)

/*===========================================================================*/

class WebRTCConfiguration : public LinkConfiguration
{
    Q_OBJECT

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

class WebRTCWorker : public QObject
{
    Q_OBJECT

   public:
    explicit WebRTCWorker(const WebRTCConfiguration *config, QObject *parent = nullptr);
    ~WebRTCWorker();

    void initializeLogger();

   public slots:
    void start();
    void writeData(const QByteArray &data);
    void disconnectLink();
    void createOffer();
    bool isDataChannelOpen() const;

   signals:
    void connected();
    void disconnected();
    void bytesReceived(const QByteArray &data);
    void bytesSent(const QByteArray &data);
    void errorOccurred(const QString &errorString);
    void rttUpdated(int rtt);  // RTT 측정 signal

   private slots:
    void _onWebSocketConnected();
    void _onWebSocketDisconnected();
    void _onWebSocketError(QAbstractSocket::SocketError error);
    void _onWebSocketMessageReceived(const QString& message);
    void _onDataChannelOpen();
    void _onDataChannelClosed();
    void _onPeerStateChanged(rtc::PeerConnection::State state);
    void _onGatheringStateChanged(rtc::PeerConnection::GatheringState state);
    void _updateRtt();  // RTT 측정용 slot

   private:
    // WebSocket signaling
    void _setupWebSocket();
    void _connectToSignalingServer();
    void _handleSignalingMessage(const QJsonObject& message);
    void _sendSignalingMessage(const QJsonObject& message);

            // WebRTC peer connection
    void _setupPeerConnection();
    void _setupDataChannel(std::shared_ptr<rtc::DataChannel> dc);
    void _processPendingCandidates();
    QString _stateToString(rtc::PeerConnection::State state) const;
    QString _gatheringStateToString(rtc::PeerConnection::GatheringState state) const;

            // Cleanup
    void _cleanup();

    void _startPingTimer();
    void _sendPing();
    qint64 _lastPingSent = 0;
    QTimer *_pingTimer = nullptr;

            // Configuration
    const WebRTCConfiguration *_config = nullptr;
    rtc::Configuration _rtcConfig;

            // WebSocket for signaling
    QWebSocket *_webSocket = nullptr;
    bool _signalingConnected = false;
    QTimer *_rttTimer = nullptr;

            // WebRTC components
    std::shared_ptr<rtc::PeerConnection> _peerConnection;
    std::shared_ptr<rtc::DataChannel> _dataChannel;

    // State management
    std::vector<rtc::Candidate> _pendingCandidates;
    std::set<std::string> _addedCandidates;
    bool _remoteDescriptionSet = false;
    bool _isOfferer = false;
    bool _isDisconnecting = false;

            // Constants
    static const QString kDataChannelLabel;
    static const int kReconnectInterval = 5000; // 5 seconds
};

/*===========================================================================*/

class WebRTCLink : public LinkInterface
{
    Q_OBJECT
    Q_PROPERTY(int rttMs READ rttMs NOTIFY rttMsChanged)

   public:
    explicit WebRTCLink(SharedLinkConfigurationPtr &config, QObject *parent = nullptr);
    ~WebRTCLink();

    bool isConnected() const override;
    void connectLink();

    int rttMs() const { return _rttMs; }

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

   signals:
    void rttMsChanged();

   private:
    const WebRTCConfiguration *_rtcConfig = nullptr;
    WebRTCWorker *_worker = nullptr;
    QThread *_workerThread = nullptr;
    int _rttMs = -1;
};
