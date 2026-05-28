#include "SiYiUniRC.h"

#include <QtCore/QDateTime>
#include <QtCore/QTimer>
#include <QtCore/QtEndian>
#include <QtNetwork/QNetworkDatagram>
#include <QtNetwork/QUdpSocket>

#include "QGCLoggingCategory.h"
#include "SiYiCrcApi.h"

QGC_LOGGING_CATEGORY(SiYiUniRCLog, "SiYi.SiYiUniRC")

namespace {
constexpr quint16 kStx = 0x5566;
constexpr int kHeaderSize = 8;          // STX(2)+CTRL(1)+Data_len(2)+SEQ(2)+CMD_ID(1)
constexpr int kPollIntervalMs = 1000;
constexpr int kWatchdogIntervalMs = 3500;

constexpr quint8 kCmdHardwareId      = 0x40;
constexpr quint8 kCmdGetSettings     = 0x16;
constexpr quint8 kCmdRcChannels      = 0x42;
constexpr quint8 kCmdLinkInfo        = 0x43;
constexpr quint8 kCmdImageLinkInfo   = 0x44;
constexpr quint8 kCmdFirmwareVersion = 0x47;

template <typename T>
T readLE(const char *src)
{
    T value;
    std::memcpy(&value, src, sizeof(T));
    return qFromLittleEndian(value);
}
} // namespace

SiYiUniRC::SiYiUniRC(QObject *parent)
    : QObject(parent)
{
    sequence_ = quint16(QDateTime::currentMSecsSinceEpoch());
}

SiYiUniRC::~SiYiUniRC()
{
    stop();
}

void SiYiUniRC::start()
{
    if (socket_) {
        return;
    }

    serverAddress_ = QHostAddress(ip_);
    if (serverAddress_.isNull()) {
        qCWarning(SiYiUniRCLog) << "Invalid IP:" << ip_;
        return;
    }

    socket_ = new QUdpSocket(this);
    if (!socket_->bind(QHostAddress::AnyIPv4, 0, QUdpSocket::ShareAddress)) {
        qCWarning(SiYiUniRCLog) << "UDP bind failed:" << socket_->errorString();
        socket_->deleteLater();
        socket_ = nullptr;
        return;
    }
    connect(socket_, &QUdpSocket::readyRead, this, &SiYiUniRC::onReadyRead);

    pollTimer_ = new QTimer(this);
    pollTimer_->setInterval(kPollIntervalMs);
    connect(pollTimer_, &QTimer::timeout, this, &SiYiUniRC::onPollTick);
    pollTimer_->start();

    watchdogTimer_ = new QTimer(this);
    watchdogTimer_->setInterval(kWatchdogIntervalMs);
    connect(watchdogTimer_, &QTimer::timeout, this, &SiYiUniRC::onWatchdogTick);
    watchdogTimer_->start();

    onPollTick();
}

void SiYiUniRC::stop()
{
    if (pollTimer_) {
        pollTimer_->stop();
        pollTimer_->deleteLater();
        pollTimer_ = nullptr;
    }
    if (watchdogTimer_) {
        watchdogTimer_->stop();
        watchdogTimer_->deleteLater();
        watchdogTimer_ = nullptr;
    }
    if (socket_) {
        socket_->close();
        socket_->deleteLater();
        socket_ = nullptr;
    }
    rxBuffer_.clear();
    versionRequested_ = false;
    setConnected(false);
}

void SiYiUniRC::setIp(const QString &ip)
{
    if (ip_ == ip) {
        return;
    }
    ip_ = ip;
    emit ipChanged();

    if (socket_) {
        stop();
        start();
    }
}

void SiYiUniRC::setConnected(bool connected)
{
    if (isConnected_ == connected) {
        return;
    }
    isConnected_ = connected;
    emit isConnectedChanged();
}

QByteArray SiYiUniRC::packMessage(quint8 cmdId, const QByteArray &payload)
{
    QByteArray msg;
    msg.reserve(kHeaderSize + payload.size() + 2);

    const quint16 stx = qToLittleEndian<quint16>(kStx);
    msg.append(reinterpret_cast<const char *>(&stx), 2);
    msg.append(char(0x00));                                  // CTRL: no ack
    const quint16 dataLen = qToLittleEndian<quint16>(quint16(payload.size()));
    msg.append(reinterpret_cast<const char *>(&dataLen), 2);
    const quint16 seq = qToLittleEndian<quint16>(sequence_++);
    msg.append(reinterpret_cast<const char *>(&seq), 2);
    msg.append(char(cmdId));
    msg.append(payload);

    const quint16 crc = qToLittleEndian<quint16>(SiYiCrcApi::calculateCrc16(msg));
    msg.append(reinterpret_cast<const char *>(&crc), 2);
    return msg;
}

void SiYiUniRC::sendMessage(const QByteArray &msg)
{
    if (!socket_ || msg.isEmpty()) {
        return;
    }
    const qint64 written = socket_->writeDatagram(msg, serverAddress_, port_);
    if (written != msg.size()) {
        qCDebug(SiYiUniRCLog) << "writeDatagram failed:" << socket_->errorString();
    }
}

void SiYiUniRC::onPollTick()
{
    if (!versionRequested_) {
        sendMessage(packMessage(kCmdFirmwareVersion));
        versionRequested_ = true;
    }
    sendMessage(packMessage(kCmdLinkInfo));
    sendMessage(packMessage(kCmdImageLinkInfo));
}

void SiYiUniRC::onWatchdogTick()
{
    if (isConnected_) {
        qCDebug(SiYiUniRCLog) << "Watchdog timeout, marking disconnected";
        setConnected(false);
    }
}

void SiYiUniRC::onReadyRead()
{
    while (socket_ && socket_->hasPendingDatagrams()) {
        QNetworkDatagram dg = socket_->receiveDatagram();
        rxBuffer_.append(dg.data());
    }
    parseRxBuffer();
}

void SiYiUniRC::parseRxBuffer()
{
    while (rxBuffer_.size() >= kHeaderSize + 2) {
        // Resync on STX 55 66
        if (quint8(rxBuffer_.at(0)) != 0x55 || quint8(rxBuffer_.at(1)) != 0x66) {
            rxBuffer_.remove(0, 1);
            continue;
        }

        const quint16 dataLen = readLE<quint16>(rxBuffer_.constData() + 3);
        const int packetSize = kHeaderSize + int(dataLen) + 2;
        if (rxBuffer_.size() < packetSize) {
            return; // wait for more bytes
        }

        const QByteArray packet = rxBuffer_.left(packetSize);
        const quint16 receivedCrc = readLE<quint16>(packet.constData() + kHeaderSize + dataLen);
        const quint16 expectedCrc = SiYiCrcApi::calculateCrc16(packet.left(kHeaderSize + dataLen));

        if (receivedCrc != expectedCrc) {
            qCDebug(SiYiUniRCLog) << "CRC mismatch, dropping byte";
            rxBuffer_.remove(0, 1);
            continue;
        }

        const quint8 cmdId = quint8(packet.at(7));
        handlePacket(cmdId, packet.mid(kHeaderSize, dataLen));
        rxBuffer_.remove(0, packetSize);
    }
}

void SiYiUniRC::handlePacket(quint8 cmdId, const QByteArray &data)
{
    setConnected(true);
    if (watchdogTimer_) {
        watchdogTimer_->start(); // reset
    }

    switch (cmdId) {
    case kCmdLinkInfo: {
        // UniRC 7: uint16 freq, uint8 pack_loss, uint16 real_pack, uint16 real_pack_rate,
        //         uint32 data_up, uint32 data_down, uint32 data_up_2, uint32 data_down_2
        if (data.size() < 7) {
            return;
        }
        const quint16 freqValue = readLE<quint16>(data.constData() + 0);
        // pack_loss_rate at +2 (uint8), real_pack at +3 (uint16), real_pack_rate at +5 (uint16)
        if (data.size() >= 15) {
            const quint32 dataUp   = readLE<quint32>(data.constData() + 7);
            const quint32 dataDown = readLE<quint32>(data.constData() + 11);
            if (int(dataUp) != upStream_) {
                upStream_ = int(dataUp);
                emit upStreamChanged();
            }
            if (int(dataDown) != downStream_) {
                downStream_ = int(dataDown);
                emit downStreamChanged();
            }
        }
        if (int(freqValue) != freq_) {
            freq_ = int(freqValue);
            emit freqChanged();
        }
        break;
    }
    case kCmdImageLinkInfo: {
        // UniRC 7: uint16 video_up (/10 Kbps), uint16 video_down (Mbps),
        //         uint8 channel, int16 signal_strength (dBm, max -44),
        //         uint8 signal_quality (0~100%)
        if (data.size() < 8) {
            return;
        }
        const quint16 videoUp     = readLE<quint16>(data.constData() + 0);
        const quint16 videoDown   = readLE<quint16>(data.constData() + 2);
        const quint8  ch          = quint8(data.at(4));
        const qint16  sigStrength = readLE<qint16>(data.constData() + 5);
        const quint8  sigQuality  = quint8(data.at(7));

        // txBanWidth/rxBanWidth are displayed as "value / 1024 Mb/s" in the QML,
        // but UniRC reports Kbps (video_up/10) and Mbps directly. Store raw values;
        // indicator formula will divide by 1024 — close enough for relative display.
        if (int(videoUp) != txBanWidth_) {
            txBanWidth_ = int(videoUp);
            emit txBanWidthChanged();
        }
        if (int(videoDown) != rxBanWidth_) {
            rxBanWidth_ = int(videoDown);
            emit rxBanWidthChanged();
        }
        if (int(ch) != channel_) {
            channel_ = int(ch);
            emit channelChanged();
        }
        if (int(sigStrength) != rssi_) {
            rssi_ = int(sigStrength);
            emit rssiChanged();
        }
        if (int(sigQuality) != signalQuality_) {
            signalQuality_ = int(sigQuality);
            emit signalQualityChanged();
        }
        break;
    }
    case kCmdFirmwareVersion: {
        // 4 x uint32: rc_version, rf_version, ground_version, sky_version.
        // First byte ignored (product id); remaining 3 bytes are major.minor.patch.
        if (data.size() < 4) {
            return;
        }
        const quint8 major = quint8(data.at(3));
        const quint8 minor = quint8(data.at(2));
        const quint8 patch = quint8(data.at(1));
        const QString v = QStringLiteral("%1.%2.%3").arg(major).arg(minor).arg(patch);
        if (v != version_) {
            version_ = v;
            emit versionChanged();
        }
        break;
    }
    default:
        qCDebug(SiYiUniRCLog) << "Unhandled CMD" << Qt::hex << cmdId;
        break;
    }
}