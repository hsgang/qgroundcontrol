/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QObject>
#include <QMutex>
#include <QString>
#include <QTimer>
#include <QMap>
#include <QByteArray>

#include "LinkInterface.h"
#include "QGC.h"
#include "QGCToolbox.h"

class LinkManager;
class QGCApplication;

Q_DECLARE_LOGGING_CATEGORY(SiyiSDKLog)

class SiyiSDKManager : public QGCTool
{
    Q_OBJECT

public:
    SiyiSDKManager(QGCApplication* app, QGCToolbox* toolbox);
    ~SiyiSDKManager();

    Q_PROPERTY(int isConnected  READ isConnected    NOTIFY siyiStatusChanged)
    Q_PROPERTY(int signal       READ signal         NOTIFY siyiStatusChanged)
    Q_PROPERTY(int inactiveTime READ inactiveTime   NOTIFY siyiStatusChanged)
    Q_PROPERTY(int upstream     READ upstream       NOTIFY siyiStatusChanged)
    Q_PROPERTY(int downstream   READ downstream     NOTIFY siyiStatusChanged)
    Q_PROPERTY(int txbandwidth  READ txbandwidth    NOTIFY siyiStatusChanged)
    Q_PROPERTY(int rxbandwidth  READ rxbandwidth    NOTIFY siyiStatusChanged)
    Q_PROPERTY(int rssi         READ rssi           NOTIFY siyiStatusChanged)
    Q_PROPERTY(int freq         READ freq           NOTIFY siyiStatusChanged)
    Q_PROPERTY(int channel      READ channel        NOTIFY siyiStatusChanged)

    bool isConnected () { return _isConnected; }
    int signal () { return _signal; }
    int inactiveTime () {return _inactiveTime; }
    int upstream () { return _upstream; }
    int downstream () { return _downstream; }
    int txbandwidth () { return _txbandwidth; }
    int rxbandwidth () { return _rxbandwidth; }
    int rssi () { return _rssi; }
    int freq () { return _freq; }
    int channel () { return _channel; }

    virtual void setToolbox(QGCToolbox *toolbox);

    bool isConnectedLink();

public slots:
    void receivedLinkStatus(LinkInterface* link, QByteArray b);
    void requestLinkStatus();

protected:
    uint8_t receivedByteArray[256];

signals:
    void siyiStatusChanged();

private slots:

private:
    LinkManager*            _linkMgr;

    struct LinkStatus_t{
        uint16_t stx;
        uint8_t ctrl;
        uint16_t len;
        uint16_t seq;
        uint8_t cmd_id;
        int32_t signal;
        int32_t inactive_time;
        int32_t upstream;
        int32_t downstream;
        int32_t txbandwidth;
        int32_t rxbandwidth;
        int32_t rssi;
        int32_t freq;
        int32_t channel;
        uint16_t crc;
    };
    LinkStatus_t _linkStatus;

    bool _isConnected = false;
    int _signal = 0;
    int _inactiveTime = 0;
    int _upstream = 0;
    int _downstream = 0;
    int _txbandwidth = 0;
    int _rxbandwidth = 0;
    int _rssi = 0;
    int _freq = 0;
    int _channel = 0;

    QTimer _sendCustomMessageTimer;
    uint16_t crcSiyiSDK(const char *buf, int len);
    void disconnectedLink();
};

