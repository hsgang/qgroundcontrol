#ifndef SIYIUNIRC_H
#define SIYIUNIRC_H

#include <QtCore/QByteArray>
#include <QtCore/QLoggingCategory>
#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QVariantList>
#include <QtNetwork/QHostAddress>
#include <QtQmlIntegration/QtQmlIntegration>

class QTimer;
class QUdpSocket;

Q_DECLARE_LOGGING_CATEGORY(SiYiUniRCLog)

// SIYI UniRC 7 Datalink SDK client (UDP 192.168.144.20:19856, CRC16 0x5566 framing).
// Exposes the same Q_PROPERTY names as SiYiTransmitter for SiyiRSSIIndicator reuse,
// plus full SDK coverage (hardware id, system settings, channel mapping, reverse, RC).
class SiYiUniRC : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Reference only")
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY isConnectedChanged)
    Q_PROPERTY(QString ip READ ip NOTIFY ipChanged)

    // Transmitter-compatible link/image link properties (from 0x43 / 0x44)
    Q_PROPERTY(int signalQuality READ signalQuality NOTIFY signalQualityChanged)
    Q_PROPERTY(int inactiveTime READ inactiveTime NOTIFY inactiveTimeChanged)
    Q_PROPERTY(int upStream READ upStream NOTIFY upStreamChanged)
    Q_PROPERTY(int downStream READ downStream NOTIFY downStreamChanged)
    Q_PROPERTY(int txBanWidth READ txBanWidth NOTIFY txBanWidthChanged)
    Q_PROPERTY(int rxBanWidth READ rxBanWidth NOTIFY rxBanWidthChanged)
    Q_PROPERTY(int rssi READ rssi NOTIFY rssiChanged)
    Q_PROPERTY(int freq READ freq NOTIFY freqChanged)
    Q_PROPERTY(int channel READ channel NOTIFY channelChanged)
    Q_PROPERTY(QString version READ version NOTIFY versionChanged)

    // Hardware / system settings (from 0x40 / 0x16)
    Q_PROPERTY(QString hardwareId READ hardwareId NOTIFY hardwareIdChanged)
    Q_PROPERTY(int pairingState READ pairingState NOTIFY pairingStateChanged)
    Q_PROPERTY(int joystickType READ joystickType NOTIFY joystickTypeChanged)
    Q_PROPERTY(int com1BaudType READ com1BaudType NOTIFY com1BaudTypeChanged)
    Q_PROPERTY(int com2BaudType READ com2BaudType NOTIFY com2BaudTypeChanged)
    Q_PROPERTY(qreal batteryVoltage READ batteryVoltage NOTIFY batteryVoltageChanged)

    // Channel mapping / reverse (from 0x48 / 0x4B)
    Q_PROPERTY(QVariantList channelMappings READ channelMappings NOTIFY channelMappingsChanged)
    Q_PROPERTY(QVariantList channelReverses READ channelReverses NOTIFY channelReversesChanged)

    // RC channels (from 0x42, only populated when output freq > 0)
    Q_PROPERTY(QVariantList rcChannels READ rcChannels NOTIFY rcChannelsChanged)
    Q_PROPERTY(int rcOutputFreq READ rcOutputFreq NOTIFY rcOutputFreqChanged)

public:
    explicit SiYiUniRC(QObject *parent = nullptr);
    ~SiYiUniRC() override;

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void setIp(const QString &ip);

    // Read-only query refresh
    Q_INVOKABLE void requestHardwareId();
    Q_INVOKABLE void requestSystemSettings();
    Q_INVOKABLE void requestChannelMappings();
    Q_INVOKABLE void requestChannelReverses();
    Q_INVOKABLE void requestFirmwareVersion();

    // System / mapping / reverse writers (0x17, 0x4A, 0x4D)
    Q_INVOKABLE void startPairing();
    Q_INVOKABLE void stopPairing();
    Q_INVOKABLE void setSystemSettings(int com1Baud, int joyType, int com2Baud);
    Q_INVOKABLE void setChannelMapping(int rcChannel, int type, int entityId);
    Q_INVOKABLE void setChannelReverse(int rcChannel, bool reverse);

    // RC channel polling: freq 0=OFF, 1=2Hz, 2=4Hz, 3=5Hz, 4=10Hz, 5=20Hz, 6=50Hz, 7=100Hz.
    // WARNING: enabling RC output may interfere with telemetry sharing the same port.
    Q_INVOKABLE void setRcOutputFreq(int freq);

signals:
    void isConnectedChanged();
    void ipChanged();
    void signalQualityChanged();
    void inactiveTimeChanged();
    void upStreamChanged();
    void downStreamChanged();
    void txBanWidthChanged();
    void rxBanWidthChanged();
    void rssiChanged();
    void freqChanged();
    void channelChanged();
    void versionChanged();
    void hardwareIdChanged();
    void pairingStateChanged();
    void joystickTypeChanged();
    void com1BaudTypeChanged();
    void com2BaudTypeChanged();
    void batteryVoltageChanged();
    void channelMappingsChanged();
    void channelReversesChanged();
    void rcChannelsChanged();
    void rcOutputFreqChanged();
    void commandAckReceived(int cmdId, int status);

private slots:
    void onReadyRead();
    void onPollTick();
    void onWatchdogTick();

private:
    QByteArray packMessage(quint8 cmdId, const QByteArray &payload = QByteArray(),
                           bool needAck = false);
    void sendMessage(const QByteArray &msg);
    void sendCommand(quint8 cmdId, const QByteArray &payload = QByteArray(),
                     int repeatCount = 1);
    void parseRxBuffer();
    void handlePacket(quint8 cmdId, const QByteArray &data);

    void requestInitialQueries();
    void setConnected(bool connected);

    bool isConnected() const { return isConnected_; }
    QString ip() const { return ip_; }
    int signalQuality() const { return signalQuality_; }
    int inactiveTime() const { return inactiveTime_; }
    int upStream() const { return upStream_; }
    int downStream() const { return downStream_; }
    int txBanWidth() const { return txBanWidth_; }
    int rxBanWidth() const { return rxBanWidth_; }
    int rssi() const { return rssi_; }
    int freq() const { return freq_; }
    int channel() const { return channel_; }
    QString version() const { return version_; }
    QString hardwareId() const { return hardwareId_; }
    int pairingState() const { return pairingState_; }
    int joystickType() const { return joystickType_; }
    int com1BaudType() const { return com1BaudType_; }
    int com2BaudType() const { return com2BaudType_; }
    qreal batteryVoltage() const { return batteryVoltage_; }
    QVariantList channelMappings() const { return channelMappings_; }
    QVariantList channelReverses() const { return channelReverses_; }
    QVariantList rcChannels() const { return rcChannels_; }
    int rcOutputFreq() const { return rcOutputFreq_; }

    QUdpSocket *socket_ = nullptr;
    QTimer *pollTimer_ = nullptr;
    QTimer *watchdogTimer_ = nullptr;
    QByteArray rxBuffer_;
    QHostAddress serverAddress_;

    QString ip_{QStringLiteral("192.168.144.20")};
    quint16 port_{19856};
    quint16 sequence_{0};
    int pollCounter_{0};

    bool isConnected_{false};
    bool initialQueriesSent_{false};

    int signalQuality_{-1};
    int inactiveTime_{-1};
    int upStream_{-1};
    int downStream_{-1};
    int txBanWidth_{-1};
    int rxBanWidth_{-1};
    int rssi_{-1};
    int freq_{-1};
    int channel_{-1};
    QString version_{QStringLiteral("--")};

    QString hardwareId_;
    int pairingState_{-1};
    int joystickType_{-1};
    int com1BaudType_{-1};
    int com2BaudType_{-1};
    qreal batteryVoltage_{0.0};

    QVariantList channelMappings_;
    QVariantList channelReverses_;
    QVariantList rcChannels_;
    int rcOutputFreq_{0};
};

#endif // SIYIUNIRC_H
