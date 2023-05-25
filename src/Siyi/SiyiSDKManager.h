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
#include "QGCToolbox.h"
#include "AppSettings.h"

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
    AppSettings*            _appSettings;

    bool portAvailable = false;

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

    // 0x40
    struct HardwareID_t{
        uint64_t padding;
        uint8_t hardware_id[12];
        uint16_t crc;
    };

    // 0x16
    struct SystemSettings_t{
        uint64_t padding;
        uint8_t match;
        uint8_t baud_type;
        uint8_t joy_type;
        uint8_t rc_bat;
        uint16_t crc;
    };

    // 0x43
    struct RCLinkStatus_t{
        uint64_t padding;
        uint16_t freq;
        uint8_t pack_loss_rate;
        uint16_t real_pack;
        uint16_t real_pack_rate;
        uint32_t data_up;
        uint32_t data_down;
        uint16_t crc;
    };

    // 0x44
    struct LinkStatus_t{
//        uint16_t stx;
//        uint8_t ctrl;
//        uint16_t len;
//        uint16_t seq;
//        uint8_t cmd_id;
        uint64_t padding;
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

    HardwareID_t _hardwareId;
    SystemSettings_t _systemSettings;
    RCLinkStatus_t _rcLinkStatus;
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
    uint16_t crcSiyiSDK(uint8_t *ptr, uint16_t len, uint16_t crc_init);
    void disconnectedLink();
    void process_packet();

    bool send_packet(SiyiCommandId, const uint8_t* databuff, uint8_t databuff_len);

    void request_hardware_id() {send_packet(SiyiCommandId::HARDWARE_ID, nullptr, 0);}
    void request_rc_link_status() {send_packet(SiyiCommandId::ACQUIRE_RC_LINK_STATUS, nullptr, 0);}
    void request_fpv_link_status() {send_packet(SiyiCommandId::ACQUIRE_FPV_LINK_STATUS, nullptr, 0);}

    uint8_t _msg_buff[MK15_SIYI_PACKETLEN_MAX];
    uint8_t _msg_buff_len;

    struct PACKED {
        uint8_t ctrl;
        uint16_t data_len;
        uint8_t command_id;
        uint16_t seq;
        uint16_t data_bytes_received;
        uint16_t crc16;
        ParseState state;
    } _parsed_msg;

    bool reset_parser;
    bool unexpected_len;

    const uint16_t crc16_tab[256]= {
        0x0000,0x1021,0x2042,0x3063,0x4084,0x50a5,0x60c6,0x70e7,
        0x8108,0x9129,0xa14a,0xb16b,0xc18c,0xd1ad,0xe1ce,0xf1ef,
        0x1231,0x0210,0x3273,0x2252,0x52b5,0x4294,0x72f7,0x62d6,
        0x9339,0x8318,0xb37b,0xa35a,0xd3bd,0xc39c,0xf3ff,0xe3de,
        0x2462,0x3443,0x0420,0x1401,0x64e6,0x74c7,0x44a4,0x5485,
        0xa56a,0xb54b,0x8528,0x9509,0xe5ee,0xf5cf,0xc5ac,0xd58d,
        0x3653,0x2672,0x1611,0x0630,0x76d7,0x66f6,0x5695,0x46b4,
        0xb75b,0xa77a,0x9719,0x8738,0xf7df,0xe7fe,0xd79d,0xc7bc,
        0x48c4,0x58e5,0x6886,0x78a7,0x0840,0x1861,0x2802,0x3823,
        0xc9cc,0xd9ed,0xe98e,0xf9af,0x8948,0x9969,0xa90a,0xb92b,
        0x5af5,0x4ad4,0x7ab7,0x6a96,0x1a71,0x0a50,0x3a33,0x2a12,
        0xdbfd,0xcbdc,0xfbbf,0xeb9e,0x9b79,0x8b58,0xbb3b,0xab1a,
        0x6ca6,0x7c87,0x4ce4,0x5cc5,0x2c22,0x3c03,0x0c60,0x1c41,
        0xedae,0xfd8f,0xcdec,0xddcd,0xad2a,0xbd0b,0x8d68,0x9d49,
        0x7e97,0x6eb6,0x5ed5,0x4ef4,0x3e13,0x2e32,0x1e51,0x0e70,
        0xff9f,0xefbe,0xdfdd,0xcffc,0xbf1b,0xaf3a,0x9f59,0x8f78,
        0x9188,0x81a9,0xb1ca,0xa1eb,0xd10c,0xc12d,0xf14e,0xe16f,
        0x1080,0x00a1,0x30c2,0x20e3,0x5004,0x4025,0x7046,0x6067,
        0x83b9,0x9398,0xa3fb,0xb3da,0xc33d,0xd31c,0xe37f,0xf35e,
        0x02b1,0x1290,0x22f3,0x32d2,0x4235,0x5214,0x6277,0x7256,
        0xb5ea,0xa5cb,0x95a8,0x8589,0xf56e,0xe54f,0xd52c,0xc50d,
        0x34e2,0x24c3,0x14a0,0x0481,0x7466,0x6447,0x5424,0x4405,
        0xa7db,0xb7fa,0x8799,0x97b8,0xe75f,0xf77e,0xc71d,0xd73c,
        0x26d3,0x36f2,0x0691,0x16b0,0x6657,0x7676,0x4615,0x5634,
        0xd94c,0xc96d,0xf90e,0xe92f,0x99c8,0x89e9,0xb98a,0xa9ab,
        0x5844,0x4865,0x7806,0x6827,0x18c0,0x08e1,0x3882,0x28a3,
        0xcb7d,0xdb5c,0xeb3f,0xfb1e,0x8bf9,0x9bd8,0xabbb,0xbb9a,
        0x4a75,0x5a54,0x6a37,0x7a16,0x0af1,0x1ad0,0x2ab3,0x3a92,
        0xfd2e,0xed0f,0xdd6c,0xcd4d,0xbdaa,0xad8b,0x9de8,0x8dc9,
        0x7c26,0x6c07,0x5c64,0x4c45,0x3ca2,0x2c83,0x1ce0,0x0cc1,
        0xef1f,0xff3e,0xcf5d,0xdf7c,0xaf9b,0xbfba,0x8fd9,0x9ff8,
        0x6e17,0x7e36,0x4e55,0x5e74,0x2e93,0x3eb2,0x0ed1,0x1ef0
    };
};

