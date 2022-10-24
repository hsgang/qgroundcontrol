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

#define MK15_SIYI_HEADER1       0x55
#define MK15_SIYI_HEADER2       0x66
#define MK15_SIYI_PACKETLEN_MIN 10
#define MK15_SIYI_PACKETLEN_MAX 46
#define MK15_SIYI_DATALEN_MAX   (MK15_SIYI_PACKETLEN_MAX-MK15_SIYI_PACKETLEN_MIN)
#define MK15_SIYI_SERIAL_RESEND_MS 1000
#define MK15_SIYI_MSG_BUF_DATA_START 8

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
    void read_incoming_packets(LinkInterface* link, QByteArray b);
    void requestLinkStatus();

protected:
    uint8_t receivedByteArray[256];

signals:
    void siyiStatusChanged();

private slots:

private:
    LinkManager*            _linkMgr;

    enum class SiyiCommandId {
        HARDWARE_ID = 0x40,
        ACQUIRE_SYSTEM_SETTINGS = 0x16,
        SYSTEM_SETTINGS = 0x17,
        REMOTE_CONTROL_CHANNELS = 0x42,
        ACQUIRE_RC_LINK_STATUS = 0x43,
        ACQUIRE_FPV_LINK_STATUS = 0x44
    };

    enum class ParseState : uint8_t {
        WAITING_FOR_STX_LOW,
        WAITING_FOR_STX_HIGH,
        WAITING_FOR_CTRL,
        WAITING_FOR_DATALEN_LOW,
        WAITING_FOR_DATALEN_HIGH,
        WAITING_FOR_SEQ_LOW,
        WAITING_FOR_SEQ_HIGH,
        WAITING_FOR_CMDID,
        WAITING_FOR_DATA,
        WAITING_FOR_CRC_LOW,
        WAITING_FOR_CRC_HIGH
    };

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
    void process_packet();

    bool send_packet(SiyiCommandId, const uint8_t* databuff, uint8_t databuff_len);

    void request_hardware_id() {send_packet(SiyiCommandId::HARDWARE_ID, nullptr, 0);}
    void request_rc_link_status() {send_packet(SiyiCommandId::ACQUIRE_RC_LINK_STATUS, nullptr, 0);}
    void request_fpv_link_status() {send_packet(SiyiCommandId::ACQUIRE_FPV_LINK_STATUS, nullptr, 0);}

    uint8_t _msg_buff[MK15_SIYI_PACKETLEN_MAX];
    uint8_t _msg_buff_len;

    struct PACKED {
        uint16_t data_len;
        uint8_t command_id;
        uint16_t data_bytes_received;
        uint16_t crc16;
        ParseState state;
    } _parsed_msg;

    uint32_t _last_send_ms;
    uint16_t _last_seq;

    bool reset_parser;
    bool unexpected_len;

};

