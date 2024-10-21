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
#include <QMutex>
#include <QTcpSocket>
#include <QGeoCoordinate>
#include <QUrl>
#include <QTimer>

#include "Drivers/src/rtcm.h"
#include "RTCMMavlink.h"
#include "NTRIPTCPLink.h"
#include "NTRIPSettings.h"
#include "QGCToolbox.h"

class NTRIPTCPLink;
class NTRIPSettings;

class NTRIPManager : public QGCTool
{
    Q_OBJECT

public:
    NTRIPManager(QGCApplication *app, QGCToolbox *toolbox);
    ~NTRIPManager();

    //static NTRIPManager *instance();

    void setToolbox(QGCToolbox *toolbox) override;

    //Q_INVOKABLE void updateSettings();
    Q_INVOKABLE void stop ();
    Q_INVOKABLE void reconnect();

    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged);
    Q_PROPERTY(quint64 ntripReceivedCount READ ntripReceivedCount NOTIFY ntripReceivedCountChanged);
    Q_PROPERTY(float bandWidth READ bandWidth NOTIFY ntripReceivedCountChanged);
    Q_PROPERTY(int networkState READ networkState NOTIFY networkStateChanged)

    bool connected () { return _connectedStatus; }
    qint64 ntripReceivedCount() { return _ntripReceivedCount; }
    void ntripReceivedUpdate(qint64 count);
    float bandWidth() { return _bandWidth; }
    int networkState () { return _networkStatus; }

signals:
    void connectedChanged ();
    void ntripReceivedCountChanged ();
    void networkStateChanged ();

public slots:
    //void ntripUpdate();

private slots:
    void _linkError(const QString &errorMsg, bool stopped = false);
    void connectStatus (bool isConnected);
    void networkStatus (NTRIPTCPLink::NetworkState status);

    //void _settingsChanged ();

private:
    void _start(const QString& hostAddress,
                int port,
                const QString &username,
                const QString &password,
                const QString &mountpoint,
                const QString &whitelist,
                const bool    &enableVRS);
    void _stop();

    // QGCToolbox      *_toolbox;
    NTRIPSettings   *_ntripSettings = nullptr;
    NTRIPTCPLink    *_ntripTcpLink = nullptr;
    RTCMMavlink     *_rtcmMavlink;
    QElapsedTimer   _bandwidthTimer;
    int             _bandwidthByteCounter = 0;
    float           _bandWidth = 0;
    bool            _connectedStatus = false;
    qint64          _ntripReceivedCount = 0;
    int             _networkStatus = 0;

    Fact* _ntripEnabled;
    Fact* _hostAddress;
    Fact* _port;
    Fact* _userName;
    Fact* _password;
    Fact* _mountPoint;
    Fact* _whiteList;
    Fact* _enableVRS;
};
