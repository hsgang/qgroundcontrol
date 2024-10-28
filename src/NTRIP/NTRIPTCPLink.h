/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QtCore/QLoggingCategory>
#include <QtCore/QObject>
#include <QtNetwork/QHostAddress>

#include <QTcpSocket>
#include <QGeoCoordinate>
#include <QUrl>
#include <QTimer>

#include "rtcm.h"
#include "QGCToolbox.h"

Q_DECLARE_LOGGING_CATEGORY(NTRIPTCPLinkLog)

class QTcpSocket;
class QTimer;

class NTRIPTCPLink : public QObject
{
    Q_OBJECT

public:
    NTRIPTCPLink(const QString& hostAddress,
                 int port,
                 const QString &username,
                 const QString &password,
                 const QString &mountpoint,
                 const QString &whitelist,
                 const bool    &enableVRS,
                 QObject *parent = nullptr);
    ~NTRIPTCPLink();

    bool init();

    enum class NetworkState {
        NetworkDisconnected,
        SocketConnecting,
        SocketConnected,
        ServerResponseWaiting,
        NtripConnected,
    };

public slots:
    //void reconnect();

signals:
    void rtcmDataUpdate(QByteArray message);
    void connectStatus(bool isConnected);
    void receivedCount(qint64 recevied);
    void errorOccurred(const QString &errorMsg, bool stopped = false);
    void networkStatus(NetworkState status);

private slots:
    void _readBytes();
    void _checkConnection();
    void _handleSocketError(QAbstractSocket::SocketError socketError);

private:
    enum class NTRIPState {
        uninitialised,
        waiting_for_http_response,
        waiting_for_rtcm_header,
        accumulating_rtcm_packet,
    };

    //void _hardwareConnect(void);
    void _updateConnection();
    void _parse(const QByteArray &buffer);
    void _sendHttpRequest();
    void _handleResponseTimeout();

    QTcpSocket      *_socket =   nullptr;
    QTimer          *_connectionTimer = nullptr;
    const int       _connectionCheckInterval = 5000;
    QStringList     _lineBuffer;

    static constexpr int _processInterval = 50;
    static constexpr int _maxLinesToProcess = 100;

    QString         _hostAddress;
    int             _port;
    QString         _username;
    QString         _password;
    QString         _mountpoint;
    QSet<int>       _whitelist;
    bool            _enableVRS;

    // Send NMEA
    void            _sendNMEA();
    QString         _getCheckSum(QString line);

    // VRS Timer
    QTimer*          _vrsSendTimer;
    static const int _vrsSendRateMSecs = 3000;

    QTimer*         _responseTimer;
    int             _retryCount;
    RTCMParsing*    _rtcm_parsing{nullptr};
    NTRIPState      _state;
    NetworkState    _networkState;
    QGCToolbox      *_toolbox = nullptr;
    qint64          _receivedCount = 0;
};
