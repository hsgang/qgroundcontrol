/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QThread>
#include <QTcpSocket>
#include <QGeoCoordinate>
#include <QUrl>

#include "Drivers/src/rtcm.h"
#include "RTCM/RTCMMavlink.h"

class NTRIPSettings;

class NTRIPTCPLink : public QThread
{
    Q_OBJECT

public:
    NTRIPTCPLink(const QString& hostAddress,
                 int port,
                 const QString& username,
                 const QString& password,
                 const QString& mountpoint,
                 const QString& whitelist,
                 const bool&    enableVRS);
    ~NTRIPTCPLink();

public slots:
    void startConnection();
    void stopConnection();
    void reconnect();

signals:
    void error(const QString errorMsg);
    void RTCMDataUpdate(QByteArray message);
    void connectStatus(bool isConnected);
    void receivedCount(qint64 recevied);

protected:
    void run() final;

private slots:
    void _readBytes();

private:
    enum class NTRIPState {
        uninitialised,
        waiting_for_http_response,
        waiting_for_rtcm_header,
        accumulating_rtcm_packet,
    };

    void _hardwareConnect(void);
    void _parse(const QByteArray &buffer);

    QTcpSocket*     _socket =   nullptr;

    QString         _hostAddress;
    int             _port;
    QString         _username;
    QString         _password;
    QString         _mountpoint;
    QSet<int>       _whitelist;
    bool            _isVRSEnable;

    // QUrl
    QUrl            _ntripURL;

    // Send NMEA
    void    _sendNMEA();
    QString _getCheckSum(QString line);

    // VRS Timer
    QTimer*          _vrsSendTimer;
    static const int _vrsSendRateMSecs = 3000;

    RTCMParsing *_rtcm_parsing{nullptr};
    NTRIPState _state;

    QGCToolbox*  _toolbox = nullptr;

    qint64        _receivedCount = 0;
};

class NTRIP : public QGCTool {
    Q_OBJECT

public:
    NTRIP(QGCApplication* app, QGCToolbox* toolbox);

    // QGCTool overrides
    void setToolbox(QGCToolbox* toolbox) final;

    Q_INVOKABLE void stopNTRIP();
    Q_INVOKABLE void reconnectNTRIP();

    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged);
    Q_PROPERTY(quint64 ntripReceivedCount READ ntripReceivedCount NOTIFY ntripReceivedCountChanged);
    Q_PROPERTY(float bandWidth READ bandWidth NOTIFY ntripReceivedCountChanged);

    bool connected () { return _connectedStatus; }
    void connectStatus (bool isConnected);
    qint64 ntripReceivedCount() { return _ntripReceivedCount; }
    void ntripReceivedUpdate(qint64 count);
    float bandWidth() { return _bandWidth; }

signals:
    void connectedChanged ();
    void ntripReceivedCountChanged ();

public slots:
    void _tcpError          (const QString errorMsg);

private slots:

private:
    NTRIPTCPLink*                    _tcpLink = nullptr;
    RTCMMavlink*                     _rtcmMavlink = nullptr;
    QElapsedTimer   _bandwidthTimer;
    int             _bandwidthByteCounter = 0;
    float           _bandWidth = 0;
    bool            _connectedStatus = false;
    qint64          _ntripReceivedCount = 0;
};
