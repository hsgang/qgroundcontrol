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
#include <qdatetime.h>

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
    , _rtcm_parsing(new RTCMParsing())
    , _responseTimer(new QTimer(this))
    , _statsTimer(new QTimer(this))
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

    _statsTimer->start(1000);

    init();
}

NTRIPTCPLink::~NTRIPTCPLink()
{
    cleanupSocket();
}

bool NTRIPTCPLink::init()
{
    if (_hostAddress.isNull()) {
        qCDebug(NTRIPTCPLinkLog) << "Invalid host address";
        return false;
    }

    cleanupSocket();

    try {

        _socket = new QTcpSocket(this);

        connect(_socket, &QTcpSocket::readyRead, this, &NTRIPTCPLink::_readBytes);

        connect(_socket, &QTcpSocket::stateChanged, this, &NTRIPTCPLink::handleSocketStateChange);

        // connect(_socket, &QTcpSocket::stateChanged, this, [this](QTcpSocket::SocketState state) {
        //     switch (state) {
        //     case QTcpSocket::UnconnectedState:
        //         qCDebug(NTRIPTCPLinkLog) << "NTRIP Socket disconnected";
        //         _updateConnectionState(ConnectionState::Disconnected);
        //         break;
        //     case QTcpSocket::SocketState::ConnectingState:
        //         qCDebug(NTRIPTCPLinkLog) << "NTRIP Socket connecting";
        //         _updateConnectionState(ConnectionState::Connecting);
        //         break;
        //     case QTcpSocket::SocketState::ConnectedState:
        //         qCDebug(NTRIPTCPLinkLog) << "NTRIP Socket connected";
        //         _updateConnectionState(ConnectionState::Connected);
        //         break;
        //     case QTcpSocket::SocketState::ClosingState:
        //         qCDebug(NTRIPTCPLinkLog) << "NTRIP Socket closing...";
        //         _updateConnectionState(ConnectionState::Closing);
        //         break;
        //     default:
        //         break;
        //     }
        // }, Qt::QueuedConnection);

        connect(_socket, &QTcpSocket::errorOccurred, this, [this](QTcpSocket::SocketError error) {
            qCDebug(NTRIPTCPLinkLog) << "socketError" << error << _socket->errorString();
            // TODO: Check if it is a critical error or not and send if the socket is stopped/recoverable
            emit errorOccurred(_socket->errorString(), false);
        }, Qt::QueuedConnection);

        connect(_socket, &QTcpSocket::errorOccurred, this, &NTRIPTCPLink::_handleSocketError, Qt::QueuedConnection);

        // connect(_reconnectionTimer, &QTimer::timeout, this, &NTRIPTCPLink::_checkConnection);
        // _reconnectionTimer->start(_connectionCheckInterval);

        connect(_responseTimer, &QTimer::timeout, this, &NTRIPTCPLink::_handleResponseTimeout, Qt::QueuedConnection);
        _responseTimer->setSingleShot(true);

        _socket->connectToHost(_hostAddress, static_cast<quint16>(_port));

        // 비동기 연결 타임아웃 설정
        QTimer::singleShot(5000, this, [this]() {
            if (_socket && _socket->state() != QTcpSocket::ConnectedState) {
                qCDebug(NTRIPTCPLinkLog) << "Connection timeout";
                _handleSocketError(QAbstractSocket::SocketTimeoutError);
            }
        });

        // if (!_socket->waitForConnected(5000)) {
        //     qCDebug(NTRIPTCPLinkLog) << "NTRIP Socket failed to connect";
        //     emit errorOccurred(_socket->errorString());

        //     // 소켓 정리
        //     disconnect(_socket, &QTcpSocket::readyRead, this, &NTRIPTCPLink::_readBytes);
        //     _socket->abort();
        //     _socket->deleteLater();  // Qt에서는 직접 delete 대신 deleteLater 사용
        //     _socket = nullptr;
        //     return false;
        // }

        if ( _socket->isOpen() && !_mountpoint.isEmpty()) {
            _sendHttpRequest();
        } else {
            _state = NTRIPState::waiting_for_rtcm_header;
        }

        return true;
    } catch (const std::exception& e) {
        qCDebug(NTRIPTCPLinkLog) << "Exception during initialization:" << e.what();
        cleanupSocket();
        return false;
    }
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
    _updateConnectionState(ConnectionState::AuthenticationPending);

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
        _updateConnectionState(ConnectionState::Error);
        return;
    }

    while (_socket->bytesAvailable() > 0) {
        QByteArray data = _socket->readAll();

        _stats.bytesReceived += data.size();
        _stats.packetsReceived++;

        qCDebug(NTRIPTCPLinkLog) << "Data received, size:" << data.size();

        if (_state == NTRIPState::waiting_for_http_response) {
            _responseTimer->stop();
            _retryCount = 0;
            if (data.contains("200 OK")) {
                _updateConnectionState(ConnectionState::Authenticated);
                qCDebug(NTRIPTCPLinkLog) << "Received HTTP 200 OK";
                _state = NTRIPState::waiting_for_rtcm_header;
            } else {
                _updateConnectionState(ConnectionState::Error);
                qCDebug(NTRIPTCPLinkLog) << "Unexpected server response";
                _state = NTRIPState::waiting_for_rtcm_header;
                emit errorOccurred("Invalid server response", true);
            }
        } else {
            _updateConnectionState(ConnectionState::ReceivingData);
            emit receivedCount(data.size());
            _parse(data);
        }

        _updateStats();
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

// void NTRIPTCPLink::_checkConnection()
// {
//     if (!_socket) {
//         qCDebug(NTRIPTCPLinkLog) << "Socket is not initialized";
//         return;
//     }

//     // // 연결 상태 확인 및 디버그 메시지 출력
//     // switch (_socket->state()) {
//     // case QTcpSocket::UnconnectedState:
//     //     qCDebug(NTRIPTCPLinkLog) << "Socket is currently disconnected.";
//     //     break;
//     // case QTcpSocket::HostLookupState:
//     //     qCDebug(NTRIPTCPLinkLog) << "Looking up host...";
//     //     break;
//     // case QTcpSocket::ConnectingState:
//     //     qCDebug(NTRIPTCPLinkLog) << "Socket is currently connecting...";
//     //     break;
//     // case QTcpSocket::ConnectedState:
//     //     qCDebug(NTRIPTCPLinkLog) << "Socket is connected.";
//     //     break;
//     // case QTcpSocket::BoundState:
//     //     qCDebug(NTRIPTCPLinkLog) << "Socket is bound to an address.";
//     //     break;
//     // case QTcpSocket::ClosingState:
//     //     qCDebug(NTRIPTCPLinkLog) << "Socket is closing...";
//     //     break;
//     // case QTcpSocket::ListeningState:
//     //     qCDebug(NTRIPTCPLinkLog) << "Socket is listening...";
//     //     break;
//     // default:
//     //     qCDebug(NTRIPTCPLinkLog) << "Unknown socket state.";
//     //     break;
//     // }

//     // 소켓이 연결되어 있지 않으면 재연결 시도
//     if (_socket->state() != QTcpSocket::ConnectedState) {
//         qCDebug(NTRIPTCPLinkLog) << "Connection lost, attempting to reconnect...";
//         init();
//     }
// }

void NTRIPTCPLink::_handleSocketError(QAbstractSocket::SocketError socketError)
{
    if(!_socket) {
        return;
    }

    _stats.lastError = _socket->errorString();
    qCDebug(NTRIPTCPLinkLog) << "Socket error occurred:" << _socket->errorString();

    _updateConnectionState(ConnectionState::Error);
    emit lastErrorChanged(_stats.lastError);
    _updateStats();

    switch (socketError) {
    case QAbstractSocket::HostNotFoundError:
        qCDebug(NTRIPTCPLinkLog) << "Error: Host not found.";
    case QAbstractSocket::ConnectionRefusedError:
        qCDebug(NTRIPTCPLinkLog) << "Error: Connection refused by the server.";
        // 심각한 오류의 경우 재시도 제한
        if (_reconnectAttempts >= _maxReconnectAttempts) {
            qCDebug(NTRIPTCPLinkLog) << "Max reconnection attempts reached";
            cleanupSocket();
            return;
        }
        break;
    case QAbstractSocket::RemoteHostClosedError:
        qCDebug(NTRIPTCPLinkLog) << "Error: Remote host closed the connection.";
    case QAbstractSocket::NetworkError:
        qCDebug(NTRIPTCPLinkLog) << "Error: Network error occurred.";
        // 일시적인 오류는 즉시 재연결 시도
        _scheduleReconnection();
        break;
    default:
        if (_reconnectAttempts < _maxReconnectAttempts) {
            _scheduleReconnection();
        }
        break;
    }
}

void NTRIPTCPLink::_updateConnectionState(ConnectionState newState)
{
    qCDebug(NTRIPTCPLinkLog) << "connectionStateChanged" << newState;
    emit connectionStateChanged(newState);
}

void NTRIPTCPLink::_updateStats()
{
    _stats.lastPacketTime = QDateTime::currentMSecsSinceEpoch();
    emit connectionStatsUpdated(_stats);
}

void NTRIPTCPLink::cleanupSocket()
{
    if (_socket) {
        _socket->disconnect(); // 모든 시그널 연결 해제
        _socket->abort();
        _socket->deleteLater();
        _socket = nullptr;
    }

    // 타이머 정리
    if (_reconnectionTimer) {
        _reconnectionTimer->stop();
        _reconnectionTimer->deleteLater();
        _reconnectionTimer = nullptr;
    }

    _state = NTRIPState::waiting_for_rtcm_header;
    _retryCount = 0;
}


void NTRIPTCPLink::_scheduleReconnection()
{
    if (!_reconnectionTimer) {
        _reconnectionTimer = new QTimer(this);
        _reconnectionTimer->setSingleShot(true);
        connect(_reconnectionTimer, &QTimer::timeout, this, [this]() {
            if (_reconnectAttempts < _maxReconnectAttempts) {
                _reconnectAttempts++;
                qCDebug(NTRIPTCPLinkLog) << "Attempting reconnection" << _reconnectAttempts << "of" << _maxReconnectAttempts;
                init();
            }
        });
    }

    // 백오프 시간 계산 (지수 백오프)
    int delay = std::min(1000 * (1 << _reconnectAttempts), 30000); // 최대 30초
    _reconnectionTimer->start(delay);
}

void NTRIPTCPLink::_resetReconnectAttempts()
{
    _reconnectAttempts = 0;
    if (_reconnectionTimer) {
        _reconnectionTimer->stop();
    }
}

void NTRIPTCPLink::handleSocketStateChange(QAbstractSocket::SocketState socketState) {
    QDateTime currentTime = QDateTime::currentDateTime();
    QString timeInState;

    if (_lastStateChangeTime.isValid()) {
        qint64 msecsSinceLastState = _lastStateChangeTime.msecsTo(currentTime);
        timeInState = QString(" (Previous state lasted: %1 ms)").arg(msecsSinceLastState);
    }

    _lastStateChangeTime = currentTime;

    QString stateStr = getSocketStateString(socketState);
    qCDebug(NTRIPTCPLinkLog) << "Socket state changed to:" << stateStr << timeInState;

    switch (socketState) {
    case QAbstractSocket::UnconnectedState:
        _updateConnectionState(ConnectionState::Disconnected);
        // 연결이 끊어진 경우 재연결 시도
        if (_reconnectAttempts < _maxReconnectAttempts) {
            _scheduleReconnection();
        }
        break;

    case QAbstractSocket::HostLookupState:
        _updateConnectionState(ConnectionState::Connecting);
        qCDebug(NTRIPTCPLinkLog) << "Looking up host:" << _hostAddress;
        break;

    case QAbstractSocket::ConnectingState:
        _updateConnectionState(ConnectionState::Connecting);
        qCDebug(NTRIPTCPLinkLog) << "Attempting to connect to:" << _hostAddress << ":" << _port;
        break;

    case QAbstractSocket::ConnectedState:
        _updateConnectionState(ConnectionState::Connected);
        _resetReconnectAttempts();
        // 연결 성공 시 마운트포인트가 설정되어 있다면 HTTP 요청 전송
        if (!_mountpoint.isEmpty()) {
            _sendHttpRequest();
        }
        break;

    case QAbstractSocket::BoundState:
        qCDebug(NTRIPTCPLinkLog) << "Socket bound to address";
        break;

    case QAbstractSocket::ClosingState:
        _updateConnectionState(ConnectionState::Closing);
        qCDebug(NTRIPTCPLinkLog) << "Connection is closing";
        break;

    default:
        qCDebug(NTRIPTCPLinkLog) << "Unhandled socket state:" << socketState;
        break;
    }

    emit socketStateChanged(stateStr);
    _updateStats();
}

QString NTRIPTCPLink::getSocketStateString(QAbstractSocket::SocketState state) {
    switch (state) {
    case QAbstractSocket::UnconnectedState: return "Unconnected";
    case QAbstractSocket::HostLookupState: return "HostLookup";
    case QAbstractSocket::ConnectingState: return "Connecting";
    case QAbstractSocket::ConnectedState: return "Connected";
    case QAbstractSocket::BoundState: return "Bound";
    case QAbstractSocket::ClosingState: return "Closing";
    case QAbstractSocket::ListeningState: return "Listening";
    default: return "Unknown";
    }
}
