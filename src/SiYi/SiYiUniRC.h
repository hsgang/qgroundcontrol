#ifndef SIYIUNIRC_H
#define SIYIUNIRC_H

#include <QtCore/QByteArray>
#include <QtCore/QLoggingCategory>
#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtNetwork/QHostAddress>
#include <QtQmlIntegration/QtQmlIntegration>

class QTimer;
class QUdpSocket;

Q_DECLARE_LOGGING_CATEGORY(SiYiUniRCLog)

// SIYI UniRC 7 Datalink SDK client (UDP 192.168.144.20:19856, CRC16 0x5566 framing).
// Exposes the same Q_PROPERTY names as SiYiTransmitter so SiyiRSSIIndicator can show either source.
class SiYiUniRC : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Reference only")
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY isConnectedChanged)
    Q_PROPERTY(QString ip READ ip WRITE setIp NOTIFY ipChanged)
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

public:
    explicit SiYiUniRC(QObject *parent = nullptr);
    ~SiYiUniRC() override;

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();

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

private slots:
    void onReadyRead();
    void onPollTick();
    void onWatchdogTick();

private:
    QByteArray packMessage(quint8 cmdId, const QByteArray &payload = QByteArray());
    void sendMessage(const QByteArray &msg);
    void parseRxBuffer();
    void handlePacket(quint8 cmdId, const QByteArray &data);

    bool isConnected() const { return isConnected_; }
    QString ip() const { return ip_; }
    void setIp(const QString &ip);
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

    void setConnected(bool connected);

    QUdpSocket *socket_ = nullptr;
    QTimer *pollTimer_ = nullptr;
    QTimer *watchdogTimer_ = nullptr;
    QByteArray rxBuffer_;
    QHostAddress serverAddress_;

    QString ip_{QStringLiteral("192.168.144.20")};
    quint16 port_{19856};
    quint16 sequence_{0};

    bool isConnected_{false};
    bool versionRequested_{false};

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
};

#endif // SIYIUNIRC_H