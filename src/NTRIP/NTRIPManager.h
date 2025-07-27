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
#include <QtQmlIntegration/QtQmlIntegration>

#include "RTCMMavlink.h"
#include "NTRIPTCPLink.h"
#include "NTRIPSettings.h"

class NTRIPTCPLink;
class NTRIPSettings;

class NTRIPManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")

public:
    NTRIPManager(QObject *parent = nullptr);
    ~NTRIPManager();

    static NTRIPManager *instance();

    void init();

    //Q_INVOKABLE void updateSettings();
    Q_INVOKABLE void stop ();
    Q_INVOKABLE void reconnect();

    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged);
    Q_PROPERTY(quint64 ntripReceivedCount READ ntripReceivedCount NOTIFY ntripReceivedCountChanged);
    Q_PROPERTY(float bandWidth READ bandWidth NOTIFY ntripReceivedCountChanged);
    Q_PROPERTY(QString connectionState READ connectionState NOTIFY connectionStateChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(double dataRate READ dataRate NOTIFY dataRateChanged)

    bool connected () { return _connected; }
    qint64 ntripReceivedCount() { return _ntripReceivedCount; }
    void ntripReceivedUpdate(qint64 count);
    float bandWidth() { return _bandWidth; }
    QString connectionState() { return _connectionState; }
    QString lastError() { return _lastError; }
    double dataRate() { return _dataRate; }

signals:
    void connectedChanged ();
    void ntripReceivedCountChanged ();
    void connectionStateChanged();
    void lastErrorChanged();
    void dataRateChanged();

public slots:
    //void ntripUpdate();

private slots:
    void _linkError(const QString &errorMsg, bool stopped = false);

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
    bool            _connected = false;
    qint64          _ntripReceivedCount = 0;

    QString _connectionState;
    QString _lastError;
    double _dataRate = 0;
    void _handleConnectionStats(const NTRIPTCPLink::ConnectionStats& stats);

    Fact* _ntripEnabled;
    Fact* _hostAddress;
    Fact* _port;
    Fact* _userName;
    Fact* _password;
    Fact* _mountPoint;
    Fact* _whiteList;
    Fact* _enableVRS;
};
