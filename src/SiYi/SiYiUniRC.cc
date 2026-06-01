#include "SiYiUniRC.h"

#include <QtCore/QDateTime>
#include <QtCore/QTimer>
#include <QtCore/QVariantMap>
#include <QtCore/QtEndian>
#include <QtNetwork/QNetworkDatagram>
#include <QtNetwork/QUdpSocket>

#ifdef Q_OS_ANDROID
#include <qserialport.h>
#endif

#include "QGCLoggingCategory.h"
#include "SiYiCrcApi.h"

QGC_LOGGING_CATEGORY(SiYiUniRCLog, "SiYi.SiYiUniRC")

namespace {
constexpr quint16 kStx = 0x5566;
constexpr int kHeaderSize = 8;
constexpr int kPollIntervalMs = 1000;
constexpr int kWatchdogIntervalMs = 3500;
constexpr int kSystemSettingsPollSec = 5;
constexpr int kRcChannelCount = 16;

constexpr quint8 kCmdHardwareId      = 0x40;
constexpr quint8 kCmdGetSettings     = 0x16;
constexpr quint8 kCmdSetSettings     = 0x17;
constexpr quint8 kCmdRcChannels      = 0x42;
constexpr quint8 kCmdLinkInfo        = 0x43;
constexpr quint8 kCmdImageLinkInfo   = 0x44;
constexpr quint8 kCmdFirmwareVersion = 0x47;
constexpr quint8 kCmdGetAllMappings  = 0x48;
constexpr quint8 kCmdGetMapping      = 0x49;
constexpr quint8 kCmdSetMapping      = 0x4A;
constexpr quint8 kCmdGetAllReverses  = 0x4B;
constexpr quint8 kCmdGetReverse      = 0x4C;
constexpr quint8 kCmdSetReverse      = 0x4D;

template <typename T>
T readLE(const char *src)
{
    T value;
    std::memcpy(&value, src, sizeof(T));
    return qFromLittleEndian(value);
}

template <typename T>
void appendLE(QByteArray &dst, T value)
{
    const T le = qToLittleEndian(value);
    dst.append(reinterpret_cast<const char *>(&le), sizeof(T));
}
} // namespace

SiYiUniRC::SiYiUniRC(QObject *parent)
    : QObject(parent)
{
    sequence_ = quint16(QDateTime::currentMSecsSinceEpoch());
    channelMappings_.reserve(kRcChannelCount);
    channelReverses_.reserve(kRcChannelCount);
    rcChannels_.reserve(kRcChannelCount);
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
#ifdef Q_OS_ANDROID
    if (serialPort_) {
        return;
    }
#endif

    if (transportMode_ == TransportSerial) {
#ifdef Q_OS_ANDROID
        if (serialPortName_.isEmpty()) {
            qCWarning(SiYiUniRCLog) << "Serial port name is empty";
            return;
        }
        serialPort_ = new QSerialPort(this);
        serialPort_->setPortName(serialPortName_);
        connect(serialPort_, &QSerialPort::readyRead, this, &SiYiUniRC::onSerialReadyRead);
        if (!serialPort_->open(QIODevice::ReadWrite)) {
            qCWarning(SiYiUniRCLog) << "Serial open failed:" << serialPort_->errorString();
            serialPort_->deleteLater();
            serialPort_ = nullptr;
            return;
        }
        serialPort_->setBaudRate(serialBaud_);
        serialPort_->setDataBits(QSerialPort::Data8);
        serialPort_->setParity(QSerialPort::NoParity);
        serialPort_->setStopBits(QSerialPort::OneStop);
        serialPort_->setFlowControl(QSerialPort::NoFlowControl);
#else
        qCWarning(SiYiUniRCLog) << "Serial transport is only supported on Android";
        return;
#endif
    } else {
        serverAddress_ = QHostAddress(ip_);
        if (serverAddress_.isNull()) {
            qCWarning(SiYiUniRCLog) << "Invalid IP:" << ip_;
            return;
        }

        socket_ = new QUdpSocket(this);
        // Relay mode owns the datalink port so it can demux MAVLink + SDK on a
        // single socket; SDK-only mode keeps an ephemeral source port as before.
        const quint16 bindPort = (relayPort_ > 0) ? port_ : quint16(0);
        if (!socket_->bind(QHostAddress::AnyIPv4, bindPort,
                           QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint)) {
            qCWarning(SiYiUniRCLog) << "UDP bind failed:" << socket_->errorString();
            socket_->deleteLater();
            socket_ = nullptr;
            return;
        }
        connect(socket_, &QUdpSocket::readyRead, this, &SiYiUniRC::onReadyRead);
    }

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
#ifdef Q_OS_ANDROID
    if (serialPort_) {
        serialPort_->close();
        serialPort_->deleteLater();
        serialPort_ = nullptr;
    }
#endif
    rxBuffer_.clear();
    initialQueriesSent_ = false;
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

void SiYiUniRC::setTransport(int mode, const QString &port, qint32 baud)
{
    transportMode_ = mode;
    serialPortName_ = port;
    serialBaud_ = baud;
}

void SiYiUniRC::setRelayPort(quint16 port)
{
    relayPort_ = port;
}

void SiYiUniRC::setConnected(bool connected)
{
    if (isConnected_ == connected) {
        return;
    }
    isConnected_ = connected;
    if (!connected) {
        initialQueriesSent_ = false;
    }
    emit isConnectedChanged();
}

QByteArray SiYiUniRC::packMessage(quint8 cmdId, const QByteArray &payload, bool needAck)
{
    QByteArray msg;
    msg.reserve(kHeaderSize + payload.size() + 2);
    appendLE<quint16>(msg, kStx);
    msg.append(char(needAck ? 0x01 : 0x00));
    appendLE<quint16>(msg, quint16(payload.size()));
    appendLE<quint16>(msg, sequence_++);
    msg.append(char(cmdId));
    msg.append(payload);
    appendLE<quint16>(msg, SiYiCrcApi::calculateCrc16(msg));
    return msg;
}

void SiYiUniRC::sendMessage(const QByteArray &msg)
{
    if (msg.isEmpty()) {
        return;
    }
#ifdef Q_OS_ANDROID
    if (transportMode_ == TransportSerial) {
        if (!serialPort_ || !serialPort_->isOpen()) {
            return;
        }
        const qint64 written = serialPort_->write(msg);
        if (written != msg.size()) {
            qCDebug(SiYiUniRCLog) << "serial write failed:" << serialPort_->errorString();
        }
        return;
    }
#endif
    if (!socket_) {
        return;
    }
    const qint64 written = socket_->writeDatagram(msg, serverAddress_, port_);
    if (written != msg.size()) {
        qCDebug(SiYiUniRCLog) << "writeDatagram failed:" << socket_->errorString();
    }
}

void SiYiUniRC::sendCommand(quint8 cmdId, const QByteArray &payload, int repeatCount)
{
    for (int i = 0; i < std::max(1, repeatCount); ++i) {
        sendMessage(packMessage(cmdId, payload));
    }
}

void SiYiUniRC::requestInitialQueries()
{
    sendCommand(kCmdHardwareId);
    sendCommand(kCmdFirmwareVersion);
    sendCommand(kCmdGetAllMappings);
    sendCommand(kCmdGetAllReverses);
    initialQueriesSent_ = true;
}

void SiYiUniRC::onPollTick()
{
    if (!initialQueriesSent_) {
        requestInitialQueries();
    }
    sendCommand(kCmdLinkInfo);
    sendCommand(kCmdImageLinkInfo);

    ++pollCounter_;
    if ((pollCounter_ % kSystemSettingsPollSec) == 0) {
        sendCommand(kCmdGetSettings);
    }
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
        const QNetworkDatagram dg = socket_->receiveDatagram();
        const QByteArray data = dg.data();
        if (data.isEmpty()) {
            continue;
        }

        // SDK-only mode (relay disabled): every datagram is a SiYi SDK reply.
        if (relayPort_ == 0) {
            rxBuffer_.append(data);
            continue;
        }

        // Relay mode: route by direction and protocol on the shared socket.
        // Uplink MAVLink arrives from the loopback link -> forward to the datalink.
        if (dg.senderAddress().isLoopback()) {
            socket_->writeDatagram(data, serverAddress_, port_);
            continue;
        }

        // Downlink from the datalink: SiYi SDK frames (STX 0x55 0x66) stay local,
        // MAVLink frames (0xFD/0xFE) are relayed to the loopback telemetry link.
        const bool isSiYiFrame = (data.size() >= 2)
            && (quint8(data.at(0)) == 0x55) && (quint8(data.at(1)) == 0x66);
        if (isSiYiFrame) {
            rxBuffer_.append(data);
        } else {
            socket_->writeDatagram(data, QHostAddress::LocalHost, relayPort_);
        }
    }
    parseRxBuffer();
}

void SiYiUniRC::onSerialReadyRead()
{
#ifdef Q_OS_ANDROID
    if (!serialPort_) {
        return;
    }
    rxBuffer_.append(serialPort_->readAll());
    parseRxBuffer();
#endif
}

void SiYiUniRC::parseRxBuffer()
{
    while (rxBuffer_.size() >= kHeaderSize + 2) {
        if (quint8(rxBuffer_.at(0)) != 0x55 || quint8(rxBuffer_.at(1)) != 0x66) {
            rxBuffer_.remove(0, 1);
            continue;
        }
        const quint16 dataLen = readLE<quint16>(rxBuffer_.constData() + 3);
        const int packetSize = kHeaderSize + int(dataLen) + 2;
        if (rxBuffer_.size() < packetSize) {
            return;
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
        watchdogTimer_->start();
    }

    switch (cmdId) {
    case kCmdHardwareId: {
        // 12-byte buffer; 10 ASCII digits + null
        if (data.size() < 10) return;
        const QString hid = QString::fromLatin1(data.constData(), 10).trimmed();
        if (hid != hardwareId_) {
            hardwareId_ = hid;
            emit hardwareIdChanged();
        }
        break;
    }
    case kCmdGetSettings: {
        // UniRC 7: 5 x uint8: match, com1_baud, joy_type, rc_bat, com2_baud
        if (data.size() < 5) return;
        const quint8 match    = quint8(data.at(0));
        const quint8 com1Baud = quint8(data.at(1));
        const quint8 joyType  = quint8(data.at(2));
        const quint8 rcBat    = quint8(data.at(3));
        const quint8 com2Baud = quint8(data.at(4));
        const qreal volts = rcBat / 10.0;

        if (int(match) != pairingState_)       { pairingState_ = match;       emit pairingStateChanged(); }
        if (int(com1Baud) != com1BaudType_)    { com1BaudType_ = com1Baud;    emit com1BaudTypeChanged(); }
        if (int(joyType) != joystickType_)     { joystickType_ = joyType;     emit joystickTypeChanged(); }
        if (int(com2Baud) != com2BaudType_)    { com2BaudType_ = com2Baud;    emit com2BaudTypeChanged(); }
        if (!qFuzzyCompare(volts + 1.0, batteryVoltage_ + 1.0)) {
            batteryVoltage_ = volts;
            emit batteryVoltageChanged();
        }
        break;
    }
    case kCmdSetSettings: {
        if (data.size() < 1) return;
        const qint8 sta = qint8(data.at(0));
        emit commandAckReceived(kCmdSetSettings, sta);
        break;
    }
    case kCmdRcChannels: {
        // 16 x int16, little-endian
        const int needed = kRcChannelCount * 2;
        if (data.size() < needed) return;
        QVariantList ch;
        ch.reserve(kRcChannelCount);
        for (int i = 0; i < kRcChannelCount; ++i) {
            ch.append(int(readLE<qint16>(data.constData() + i * 2)));
        }
        rcChannels_ = ch;
        emit rcChannelsChanged();
        break;
    }
    case kCmdLinkInfo: {
        if (data.size() < 7) return;
        const quint16 freqValue = readLE<quint16>(data.constData() + 0);
        if (data.size() >= 15) {
            const quint32 dataUp   = readLE<quint32>(data.constData() + 7);
            const quint32 dataDown = readLE<quint32>(data.constData() + 11);
            if (int(dataUp) != upStream_)     { upStream_   = int(dataUp);   emit upStreamChanged(); }
            if (int(dataDown) != downStream_) { downStream_ = int(dataDown); emit downStreamChanged(); }
        }
        if (int(freqValue) != freq_) { freq_ = int(freqValue); emit freqChanged(); }
        break;
    }
    case kCmdImageLinkInfo: {
        if (data.size() < 8) return;
        const quint16 videoUp     = readLE<quint16>(data.constData() + 0);
        const quint16 videoDown   = readLE<quint16>(data.constData() + 2);
        const quint8  ch          = quint8(data.at(4));
        const qint16  sigStrength = readLE<qint16>(data.constData() + 5);
        const quint8  sigQuality  = quint8(data.at(7));
        if (int(videoUp) != txBanWidth_)     { txBanWidth_   = int(videoUp);     emit txBanWidthChanged(); }
        if (int(videoDown) != rxBanWidth_)   { rxBanWidth_   = int(videoDown);   emit rxBanWidthChanged(); }
        if (int(ch) != channel_)             { channel_      = int(ch);          emit channelChanged(); }
        if (int(sigStrength) != rssi_)       { rssi_         = int(sigStrength); emit rssiChanged(); }
        if (int(sigQuality) != signalQuality_) { signalQuality_ = int(sigQuality); emit signalQualityChanged(); }
        break;
    }
    case kCmdFirmwareVersion: {
        if (data.size() < 4) return;
        const quint8 major = quint8(data.at(3));
        const quint8 minor = quint8(data.at(2));
        const quint8 patch = quint8(data.at(1));
        const QString v = QStringLiteral("%1.%2.%3").arg(major).arg(minor).arg(patch);
        if (v != version_) { version_ = v; emit versionChanged(); }
        break;
    }
    case kCmdGetAllMappings: {
        // 16 entries × (type:uint8, entity_id:uint8) = 32 bytes
        const int needed = kRcChannelCount * 2;
        if (data.size() < needed) return;
        QVariantList mappings;
        mappings.reserve(kRcChannelCount);
        for (int i = 0; i < kRcChannelCount; ++i) {
            QVariantMap m;
            m["type"]     = int(quint8(data.at(i * 2)));
            m["entityId"] = int(quint8(data.at(i * 2 + 1)));
            mappings.append(m);
        }
        channelMappings_ = mappings;
        emit channelMappingsChanged();
        break;
    }
    case kCmdGetMapping: {
        // rc_ch, type, entity_id (3 bytes)
        if (data.size() < 3) return;
        const int rcCh    = int(quint8(data.at(0)));
        const int type    = int(quint8(data.at(1)));
        const int entId   = int(quint8(data.at(2)));
        if (rcCh >= 1 && rcCh <= kRcChannelCount && channelMappings_.size() == kRcChannelCount) {
            QVariantMap m;
            m["type"]     = type;
            m["entityId"] = entId;
            channelMappings_[rcCh - 1] = m;
            emit channelMappingsChanged();
        }
        break;
    }
    case kCmdSetMapping: {
        // rc_ch, sta
        if (data.size() < 2) return;
        emit commandAckReceived(kCmdSetMapping, qint8(data.at(1)));
        break;
    }
    case kCmdGetAllReverses: {
        if (data.size() < kRcChannelCount) return;
        QVariantList reverses;
        reverses.reserve(kRcChannelCount);
        for (int i = 0; i < kRcChannelCount; ++i) {
            reverses.append(int(qint8(data.at(i))));
        }
        channelReverses_ = reverses;
        emit channelReversesChanged();
        break;
    }
    case kCmdGetReverse: {
        if (data.size() < 2) return;
        const int rcCh    = int(quint8(data.at(0)));
        const int reverse = int(qint8(data.at(1)));
        if (rcCh >= 1 && rcCh <= kRcChannelCount && channelReverses_.size() == kRcChannelCount) {
            channelReverses_[rcCh - 1] = reverse;
            emit channelReversesChanged();
        }
        break;
    }
    case kCmdSetReverse: {
        if (data.size() < 2) return;
        emit commandAckReceived(kCmdSetReverse, qint8(data.at(1)));
        break;
    }
    default:
        qCDebug(SiYiUniRCLog) << "Unhandled CMD" << Qt::hex << cmdId;
        break;
    }
}

// ---------- Q_INVOKABLE writers / one-shot queries ----------

void SiYiUniRC::requestHardwareId()      { sendCommand(kCmdHardwareId); }
void SiYiUniRC::requestSystemSettings()  { sendCommand(kCmdGetSettings); }
void SiYiUniRC::requestChannelMappings() { sendCommand(kCmdGetAllMappings); }
void SiYiUniRC::requestChannelReverses() { sendCommand(kCmdGetAllReverses); }
void SiYiUniRC::requestFirmwareVersion() { sendCommand(kCmdFirmwareVersion); }

void SiYiUniRC::startPairing()
{
    // match=1 enables pairing per UniRC SDK; com/joy fields kept neutral.
    QByteArray p;
    p.append(char(0x01));
    p.append(char(qMax(0, com1BaudType_)));
    p.append(char(qMax(0, joystickType_)));
    p.append(char(0x00)); // reserved
    p.append(char(qMax(0, com2BaudType_)));
    sendCommand(kCmdSetSettings, p);
}

void SiYiUniRC::stopPairing()
{
    QByteArray p;
    p.append(char(0x00));
    p.append(char(qMax(0, com1BaudType_)));
    p.append(char(qMax(0, joystickType_)));
    p.append(char(0x00));
    p.append(char(qMax(0, com2BaudType_)));
    sendCommand(kCmdSetSettings, p);
}

void SiYiUniRC::setSystemSettings(int com1Baud, int joyType, int com2Baud)
{
    QByteArray p;
    p.append(char(0x00)); // match=0 (do not toggle pairing)
    p.append(char(com1Baud));
    p.append(char(joyType));
    p.append(char(0x00)); // reserved
    p.append(char(com2Baud));
    sendCommand(kCmdSetSettings, p);
}

void SiYiUniRC::setChannelMapping(int rcChannel, int type, int entityId)
{
    if (rcChannel < 1 || rcChannel > kRcChannelCount) return;
    QByteArray p;
    p.append(char(rcChannel));
    p.append(char(type));
    p.append(char(entityId));
    sendCommand(kCmdSetMapping, p);
}

void SiYiUniRC::setChannelReverse(int rcChannel, bool reverse)
{
    if (rcChannel < 1 || rcChannel > kRcChannelCount) return;
    QByteArray p;
    p.append(char(rcChannel));
    p.append(char(reverse ? 0xFF : 0x01)); // 1 forward, -1 reverse (0xFF in two's complement)
    sendCommand(kCmdSetReverse, p);
}

void SiYiUniRC::setRcOutputFreq(int freq)
{
    if (freq < 0 || freq > 7) return;
    QByteArray p;
    p.append(char(freq));
    // Manual recommends sending 3 times consecutively.
    sendCommand(kCmdRcChannels, p, 3);
    if (freq != rcOutputFreq_) {
        rcOutputFreq_ = freq;
        emit rcOutputFreqChanged();
    }
}
