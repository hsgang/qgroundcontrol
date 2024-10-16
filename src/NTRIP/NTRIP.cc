/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "NTRIP.h"
#include "QGCLoggingCategory.h"
#include "QGCToolbox.h"
#include "QGCApplication.h"
#include "SettingsManager.h"
#include "PositionManager.h"
#include "NTRIPSettings.h"

#include <QDebug>

NTRIP::NTRIP(QGCApplication* app, QGCToolbox* toolbox)
    : QGCTool(app, toolbox)
{
}

void NTRIP::setToolbox(QGCToolbox* toolbox)
{
    QGCTool::setToolbox(toolbox);

    NTRIPSettings* settings = qgcApp()->toolbox()->settingsManager()->ntripSettings();
    if (settings->ntripServerConnectEnabled()->rawValue().toBool()) {
        _rtcmMavlink = new RTCMMavlink(*toolbox);

        _tcpLink = new NTRIPTCPLink(settings->ntripServerHostAddress()->rawValue().toString(),
                                    settings->ntripServerPort()->rawValue().toInt(),
                                    settings->ntripUsername()->rawValue().toString(),
                                    settings->ntripPassword()->rawValue().toString(),
                                    settings->ntripMountpoint()->rawValue().toString(),
                                    settings->ntripWhitelist()->rawValue().toString(),
                                    settings->ntripEnableVRS()->rawValue().toBool());
        connect(_tcpLink, &NTRIPTCPLink::error,              this, &NTRIP::_tcpError,           Qt::QueuedConnection);
        connect(_tcpLink, &NTRIPTCPLink::RTCMDataUpdate,   _rtcmMavlink, &RTCMMavlink::RTCMDataUpdate);
        connect(_tcpLink, &NTRIPTCPLink::connectStatus,      this, &NTRIP::connectStatus);
        connect(_tcpLink, &NTRIPTCPLink::receivedCount,      this, &NTRIP::ntripReceivedUpdate);

        _bandwidthTimer.start();
    }
}

void NTRIP::_tcpError(const QString errorMsg)
{
    qgcApp()->showAppMessage(tr("NTRIP Server Error: %1").arg(errorMsg));
}

void NTRIP::stopNTRIP(){
    if(_tcpLink){
        //_tcpLink->stopConnection();
        QMetaObject::invokeMethod(_tcpLink, "stopConnection", Qt::QueuedConnection);
    }
    _bandwidthTimer.restart();
    _bandWidth = 0;
    emit ntripReceivedCountChanged();
    qCDebug(NTRIPLog) << "clicked NTRIP stop";
}

void NTRIP::reconnectNTRIP(){
    if(_tcpLink){
        //_tcpLink->reconnect();
        QMetaObject::invokeMethod(_tcpLink, "reconnect", Qt::QueuedConnection);
    }
    _bandwidthTimer.restart();
    _bandWidth = 0;
    emit ntripReceivedCountChanged();
    qCDebug(NTRIPLog) << "clicked NTRIP reconnect";
}

void NTRIP::connectStatus(bool isConnected){
    if(isConnected == true) {
        _connectedStatus = true;
    } else {
        _connectedStatus = false;
    }
    emit connectedChanged();
    qCDebug(NTRIPLog) << "connectStatus changed";
}

void NTRIP::ntripReceivedUpdate(qint64 count){
    _ntripReceivedCount += count;

    _bandwidthByteCounter += count;
    qint64 elapsed = _bandwidthTimer.elapsed();
    if (elapsed > 1000) {
        _bandWidth = (float) _bandwidthByteCounter / elapsed * 1000.f / 1024.f;
        _bandwidthTimer.restart();
        _bandwidthByteCounter = 0;
    }

    emit ntripReceivedCountChanged();
}

NTRIPTCPLink::NTRIPTCPLink(const QString& hostAddress,
                           int port,
                           const QString &username,
                           const QString &password,
                           const QString &mountpoint,
                           const QString &whitelist,
                           const bool    &enableVRS)
    : QThread       ()
    , _hostAddress  (hostAddress)
    , _port         (port)
    , _username     (username)
    , _password     (password)
    , _mountpoint   (mountpoint)
    , _isVRSEnable  (enableVRS)
    , _toolbox      (qgcApp()->toolbox())
{
    for(const auto& msg: whitelist.split(',')) {
        int msg_int = msg.toInt();
        if(msg_int) {
            _whitelist.insert(msg_int);
        }
    }
    qCDebug(NTRIPLog) << "whitelist: " << _whitelist;
    if (!_rtcm_parsing) {
        _rtcm_parsing = new RTCMParsing();
    }
    _rtcm_parsing->reset();
    _state = NTRIPState::uninitialised;

    // Start TCP Socket
    moveToThread(this);
    start();
    qCDebug(NTRIPLog) << "NTRIPTCPLink start";
}

NTRIPTCPLink::~NTRIPTCPLink(void)
{
    if (_socket) {
        QObject::disconnect(_socket, &QTcpSocket::readyRead, this, &NTRIPTCPLink::_readBytes);
        _socket->disconnectFromHost();
        _socket->deleteLater();
        _socket = nullptr;

        // Delete Rtcm Parsing instance
        delete(_rtcm_parsing);
        _rtcm_parsing = nullptr;
    }
    quit();
    wait();
    qCDebug(NTRIPLog) << "NTRIPTCPLink quit";
}

void NTRIPTCPLink::run(void)
{
    _hardwareConnect();
    exec();
}

void NTRIPTCPLink::startConnection()
{
    qCDebug(NTRIPLog) << "NTRIPTCPLink::startConnection()";

    if (_socket) {
        qCDebug(NTRIPLog) << "NTRIPTCPLink::startConnection() has _socket";

        delete _socket;
        _socket = nullptr;
    }

    _hardwareConnect();
}

void NTRIPTCPLink::stopConnection()
{
    qCDebug(NTRIPLog) << "NTRIPTCPLink::stopConnection()";

    if (_socket) {
        qCDebug(NTRIPLog) << "NTRIPTCPLink::stopConnection()has _socket" << _socket;

        QObject::disconnect(_socket, &QTcpSocket::readyRead, this, &NTRIPTCPLink::_readBytes);
        _socket->disconnectFromHost();
        _socket->deleteLater();
        _socket = nullptr;

        emit connectStatus(false);
        _receivedCount = 0;

        _rtcm_parsing->reset();
        _state = NTRIPState::uninitialised;

        qCDebug(NTRIPLog) << "NTRIPTCPLink::stopConnection() make _socket to" << _socket;
    } else if (!_socket) {
        qCDebug(NTRIPLog) << "NTRIPTCPLink::stopConnection() has no _socket";
    }
}

void NTRIPTCPLink::reconnect()
{
    qCDebug(NTRIPLog) << "NTRIPTCPLink::reconnect()";
    if(_socket){
        stopConnection();
    }
    startConnection();
}

void NTRIPTCPLink::_hardwareConnect()
{
    _socket = new QTcpSocket();
    QObject::connect(_socket, &QTcpSocket::readyRead, this, &NTRIPTCPLink::_readBytes);
    _socket->connectToHost(_hostAddress, static_cast<quint16>(_port));

    // Give the socket a second to connect to the other side otherwise error out
    if (!_socket->waitForConnected(5000)) {
        qCDebug(NTRIPLog) << "NTRIP Socket failed to connect";
        emit error(_socket->errorString());
        delete _socket;
        _socket = nullptr;

        emit connectStatus(false);

        return;
    }

    // If mountpoint is specified, send an http get request for data
    if ( !_mountpoint.isEmpty()) {
        qCDebug(NTRIPLog) << "Sending HTTP request";
        QString auth = QString(_username + ":"  + _password).toUtf8().toBase64();
        QString query = "GET /%1 HTTP/1.0\r\nUser-Agent: NTRIP\r\nAuthorization: Basic %2\r\n\r\n";
        _socket->write(query.arg(_mountpoint).arg(auth).toUtf8());
        _state = NTRIPState::waiting_for_http_response;
    } else {
        // If no mountpoint is set, assume we will just get data from the tcp stream
        _state = NTRIPState::waiting_for_rtcm_header;
    }

    emit connectStatus(true);

    qCDebug(NTRIPLog) << "NTRIP Socket connected to" << _socket;
}

void NTRIPTCPLink::_parse(const QByteArray &buffer)
{
    for(const uint8_t byte : buffer) {
        if(_state == NTRIPState::waiting_for_rtcm_header) {
            if(byte != RTCM3_PREAMBLE)
                continue;
            _state = NTRIPState::accumulating_rtcm_packet;
        }
        if(_rtcm_parsing->addByte(byte)) {
            _state = NTRIPState::waiting_for_rtcm_header;
            QByteArray message((char*)_rtcm_parsing->message(), static_cast<int>(_rtcm_parsing->messageLength()));
            //TODO: Restore the following when upstreamed in Driver repo
            //uint16_t id = _rtcm_parsing->messageId();
            uint16_t id = ((uint8_t)message[3] << 4) | ((uint8_t)message[4] >> 4);
            if(_whitelist.empty() || _whitelist.contains(id)) {
                emit RTCMDataUpdate(message);
                emit receivedCount(message.size());
                qCDebug(NTRIPLog) << "Sending" << id << "of size" << message.length();
            } else {
                qCDebug(NTRIPLog) << "Ignoring " << id;
            }
            _rtcm_parsing->reset();
        }
    }
}

void NTRIPTCPLink::_readBytes(void)
{
    if (!_socket) {
        return;
    }
    if(_state == NTRIPState::waiting_for_http_response) {
        QString line = _socket->readLine();
        if (line.contains("200")){
            _state = NTRIPState::waiting_for_rtcm_header;
        } else {
            qCWarning(NTRIPLog) << "Server responded with " << line;
            // TODO: Handle failure. Reconnect?
            // Just move into parsing mode and hope for now.
            _state = NTRIPState::waiting_for_rtcm_header;
        }
    }
    QByteArray bytes = _socket->readAll();
    _parse(bytes);
}

void NTRIPTCPLink::_sendNMEA() {
    QGeoCoordinate gcsPosition = _toolbox->qgcPositionManager()->gcsPosition();

    if(!gcsPosition.isValid()) {
        return;
    }

    double lat = gcsPosition.latitude();
    double lng = gcsPosition.longitude();
    double alt = gcsPosition.altitude();

    qCDebug(NTRIPLog) << "lat : " << lat << " lon : " << lng << " alt : " << alt;

    QString time = QDateTime::currentDateTimeUtc().toString("hhmmss.zzz");

    if(lat != 0 || lng != 0) {
        double latdms = (int) lat + (lat - (int) lat) * .6f;
        double lngdms = (int) lng + (lng - (int) lng) * .6f;
        if(isnan(alt)) alt = 0.0;

        QString line = QString("$GP%1,%2,%3,%4,%5,%6,%7,%8,%9,%10,%11,%12,%13,%14,%15")
                .arg("GGA", time,
                     QString::number(qFabs(latdms * 100), 'f', 2), lat < 0 ? "S" : "N",
                     QString::number(qFabs(lngdms * 100), 'f', 2), lng < 0 ? "W" : "E",
                     "1", "10", "1",
                     QString::number(alt, 'f', 2),
                     "M", "0", "M", "0.0", "0");

        // Calculrate checksum and send message
        QString checkSum = _getCheckSum(line);
        //QString* nmeaMessage = new QString(line + "*" + checkSum + "\r\n");
        QString nmeaMessage = line + "*" + checkSum + "\r\n";

        // Write nmea message
        if(_socket) {
            _socket->write(nmeaMessage.toUtf8());
        }

        qCDebug(NTRIPLog) << "NMEA Message : " << nmeaMessage.toUtf8();
    }
}

QString NTRIPTCPLink::_getCheckSum(QString line) {
    QByteArray temp_Byte = line.toUtf8();
    const char* buf = temp_Byte.constData();

    char character;
    int checksum = 0;

    for(int i = 0; i < line.length(); i++) {
        character = buf[i];
        switch(character) {
        case '$':
            // Ignore the dollar sign
            break;
        case '*':
            // Stop processing before the asterisk
            i = line.length();
            continue;
        default:
            // First value for the checksum
            if(checksum == 0) {
                // Set the checksum to the value
                checksum = character;
            }
            else {
                // XOR the checksum with this character's value
                checksum = checksum ^ character;
            }
        }
    }

    return QString("%1").arg(checksum, 0, 16);
}
