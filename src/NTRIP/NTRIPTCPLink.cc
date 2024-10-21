/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "NTRIPTCPLink.h"
#include "QGCLoggingCategory.h"

#include <QDebug>
#include <QHostInfo>

QGC_LOGGING_CATEGORY(NTRIPTCPLinkLog, "qgc.ntrip.ntriptcplink")

NTRIPTCPLink::NTRIPTCPLink(const QString& hostAddress,
                           int port,
                           const QString &username,
                           const QString &password,
                           const QString &mountpoint,
                           const QString &whitelist,
                           const bool    &enableVRS,
                           QObject *parent)
    : QObject(parent)
    , _hostAddress(hostAddress)
    , _port(port)
    , _username(username)
    , _password(password)
    , _mountpoint(mountpoint)
    //, _whitelist(whitelist)
    , _enableVRS(enableVRS)
    , _socket(new QTcpSocket(this))
    , _connectionTimer(new QTimer(this))
    , _rtcm_parsing(new RTCMParsing())
    , _responseTimer(new QTimer(this))
    , _retryCount(0)
{
    for(const auto& msg: whitelist.split(',')) {
        int msg_int = msg.toInt();
        if(msg_int) {
            _whitelist.insert(msg_int);
        }
    }
    qCDebug(NTRIPTCPLinkLog) << "whitelist: " << _whitelist;
    qCDebug(NTRIPTCPLinkLog) << "_hostAddress" << _hostAddress;

    connect(_socket, &QTcpSocket::stateChanged, this, [this](QTcpSocket::SocketState state) {
        switch (state) {
        case QTcpSocket::UnconnectedState:
            qCDebug(NTRIPTCPLinkLog) << "NTRIP Socket disconnected";
            break;
        case QTcpSocket::SocketState::ConnectingState:
            qCDebug(NTRIPTCPLinkLog) << "NTRIP Socket connecting...";
            break;
        case QTcpSocket::SocketState::ConnectedState:
            qCDebug(NTRIPTCPLinkLog) << "NTRIP Socket connected";
            break;
        case QTcpSocket::SocketState::ClosingState:
            qCDebug(NTRIPTCPLinkLog) << "NTRIP Socket closing...";
            break;
        default:
            break;
        }
    }, Qt::AutoConnection);

    connect(_socket, &QTcpSocket::connected, this, [this]() {
        emit networkStatus(NetworkState::SocketConnected);
    });

    connect(_socket, &QTcpSocket::errorOccurred, this, [this](QTcpSocket::SocketError error) {
        qCDebug(NTRIPTCPLinkLog) << "socketError" << error << _socket->errorString();
        // TODO: Check if it is a critical error or not and send if the socket is stopped/recoverable
        emit errorOccurred(_socket->errorString(), false);
    }, Qt::AutoConnection);
    connect(_socket, &QTcpSocket::errorOccurred, this, &NTRIPTCPLink::_handleSocketError);

    connect(_socket, &QTcpSocket::readyRead, this, &NTRIPTCPLink::_readBytes);

    connect(_connectionTimer, &QTimer::timeout, this, &NTRIPTCPLink::_checkConnection);
    _connectionTimer->start(_connectionCheckInterval);

    connect(_responseTimer, &QTimer::timeout, this, &NTRIPTCPLink::_handleResponseTimeout);
    _responseTimer->setSingleShot(true);

    // if (!_rtcm_parsing) {
    //     _rtcm_parsing = new RTCMParsing();
    // }
    // _rtcm_parsing->reset();

    init();
}

NTRIPTCPLink::~NTRIPTCPLink()
{

}

bool NTRIPTCPLink::init()
{
    if (_hostAddress.isNull()) {
        return false;
    }

    _socket->connectToHost(_hostAddress, static_cast<quint16>(_port));

    connect(_socket, &QTcpSocket::readyRead, this, &NTRIPTCPLink::_readBytes);

    emit networkStatus(NetworkState::ServerResponseWaiting);

    if (!_socket->waitForConnected(5000)) {
        qCDebug(NTRIPTCPLinkLog) << "NTRIP Socket failed to connect";
        emit errorOccurred(_socket->errorString());
        delete _socket;
        _socket = nullptr;

        emit connectStatus(false);

        return false;
    }

    if ( !_mountpoint.isEmpty()) {
        _sendHttpRequest();
    } else {
        _state = NTRIPState::waiting_for_rtcm_header;
    }

    return true;
}

void NTRIPTCPLink::_sendHttpRequest()
{
    qCDebug(NTRIPTCPLinkLog) << "Sending HTTP request" << _hostAddress << _port << _username << _password << _mountpoint;
    QString auth = _username + ":" + _password;
    QByteArray authHeader = "Authorization: Basic " + auth.toUtf8().toBase64() + "\r\n";
    QString request = "GET /" + _mountpoint + " HTTP/1.0\r\n"
                        "Host: " + _hostAddress + "\r\n"
                        "User-Agent: NTRIP Client/1.0\r\n" +
                        authHeader +
                        "Accept: */*\r\n"
                        "Connection: keep-alive\r\n"
                        "\r\n";
    _socket->write(request.toUtf8());
    _state = NTRIPState::waiting_for_http_response;

    // Start the response timer
    _responseTimer->start(5000); // 5 seconds timeout
}

void NTRIPTCPLink::_handleResponseTimeout()
{
    if (_state == NTRIPState::waiting_for_http_response) {
        if (_retryCount < 3) {
            qCDebug(NTRIPTCPLinkLog) << "No response received, retrying HTTP request...";
            _retryCount++;
            _sendHttpRequest();
        } else {
            qCDebug(NTRIPTCPLinkLog) << "Max retries reached. Unable to establish connection.";
            emit errorOccurred("No response from server after multiple attempts", true);
            _state = NTRIPState::waiting_for_rtcm_header;
            _retryCount = 0;
        }
    }
}

void NTRIPTCPLink::_readBytes()
{
    if (!_socket) {
        qCDebug(NTRIPTCPLinkLog) << "NTRIP Socket is null";
        return;
    }

    while (_socket->bytesAvailable() > 0) {
        QByteArray data = _socket->readAll();
        qCDebug(NTRIPTCPLinkLog) << "Data received, size:" << data.size();

        if (_state == NTRIPState::waiting_for_http_response) {
            _responseTimer->stop();
            _retryCount = 0;
            if (data.contains("200 OK")) {
                qCDebug(NTRIPTCPLinkLog) << "Received HTTP 200 OK";
                _state = NTRIPState::waiting_for_rtcm_header;
                emit networkStatus(NetworkState::NtripConnected);
            } else {
                qCDebug(NTRIPTCPLinkLog) << "Unexpected server response";
                _state = NTRIPState::waiting_for_rtcm_header;
                emit errorOccurred("Invalid server response", true);
            }
        } else {
            //qCDebug(NTRIPTCPLinkLog) << "parse data:" << data.toHex(' ');
            emit connectStatus(true);
            emit receivedCount(data.size());
            _parse(data);
        }
    }
}

void NTRIPTCPLink::_parse(const QByteArray &buffer)
{
    //qCDebug(NTRIPTCPLinkLog) << "buffer data:" << buffer;
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
                emit rtcmDataUpdate(message);
                //qCDebug(NTRIPTCPLinkLog) << "Received" << id << "of size" << message.length();
            } else {
                qCDebug(NTRIPTCPLinkLog) << "Ignoring " << id;
            }
            _rtcm_parsing->reset();
        }
    }
}

void NTRIPTCPLink::_checkConnection()
{
    if (!_socket) {
        qCDebug(NTRIPTCPLinkLog) << "Socket is not initialized";
        return;
    }

    // // 연결 상태 확인 및 디버그 메시지 출력
    // switch (_socket->state()) {
    // case QTcpSocket::UnconnectedState:
    //     qCDebug(NTRIPTCPLinkLog) << "Socket is currently disconnected.";
    //     break;
    // case QTcpSocket::HostLookupState:
    //     qCDebug(NTRIPTCPLinkLog) << "Looking up host...";
    //     break;
    // case QTcpSocket::ConnectingState:
    //     qCDebug(NTRIPTCPLinkLog) << "Socket is currently connecting...";
    //     break;
    // case QTcpSocket::ConnectedState:
    //     qCDebug(NTRIPTCPLinkLog) << "Socket is connected.";
    //     break;
    // case QTcpSocket::BoundState:
    //     qCDebug(NTRIPTCPLinkLog) << "Socket is bound to an address.";
    //     break;
    // case QTcpSocket::ClosingState:
    //     qCDebug(NTRIPTCPLinkLog) << "Socket is closing...";
    //     break;
    // case QTcpSocket::ListeningState:
    //     qCDebug(NTRIPTCPLinkLog) << "Socket is listening...";
    //     break;
    // default:
    //     qCDebug(NTRIPTCPLinkLog) << "Unknown socket state.";
    //     break;
    // }

    // 소켓이 연결되어 있지 않으면 재연결 시도
    if (_socket->state() != QTcpSocket::ConnectedState) {
        qCDebug(NTRIPTCPLinkLog) << "Connection lost, attempting to reconnect...";
        init();
    }
}

void NTRIPTCPLink::_handleSocketError(QAbstractSocket::SocketError socketError)
{
    qCDebug(NTRIPTCPLinkLog) << "Socket error occurred:" << _socket->errorString();

    switch (socketError) {
    case QAbstractSocket::HostNotFoundError:
        qCDebug(NTRIPTCPLinkLog) << "Error: Host not found.";
        break;
    case QAbstractSocket::ConnectionRefusedError:
        qCDebug(NTRIPTCPLinkLog) << "Error: Connection refused by the server.";
        break;
    case QAbstractSocket::RemoteHostClosedError:
        qCDebug(NTRIPTCPLinkLog) << "Error: Remote host closed the connection.";
        break;
    case QAbstractSocket::NetworkError:
        qCDebug(NTRIPTCPLinkLog) << "Error: Network error occurred.";
        break;
    default:
        qCDebug(NTRIPTCPLinkLog) << "Unhandled socket error:" << socketError;
        break;
    }

    // 오류 발생 시 소켓을 재연결
    if (socketError != QAbstractSocket::HostNotFoundError &&
        socketError != QAbstractSocket::ConnectionRefusedError) {
        qCDebug(NTRIPTCPLinkLog) << "Attempting to reconnect after error...";
        _socket->abort();  // 기존 연결 중단
        init();            // 다시 연결 시도
    }
}
