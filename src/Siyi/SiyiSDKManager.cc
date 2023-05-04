/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include <inttypes.h>
#include <iostream>

#include <QDebug>
#include <QTime>
#include <QApplication>
#include <QSettings>
#include <QStandardPaths>
#include <QtEndian>
#include <QMetaType>
#include <QDir>
#include <QFileInfo>

#include "SiyiSDKManager.h"
#include "LinkManager.h"
#include "QGCApplication.h"
#include "SettingsManager.h"
#include "AppSettings.h"

SiyiSDKManager::SiyiSDKManager(QGCApplication* app, QGCToolbox* toolbox)
    : QGCTool(app, toolbox)
    , _linkMgr(nullptr)
{
    connect(&_sendCustomMessageTimer, &QTimer::timeout, this, &SiyiSDKManager::requestLinkStatus);
    _sendCustomMessageTimer.start(5000);
    memset(&_linkStatus, 0, sizeof(_linkStatus));
}

SiyiSDKManager::~SiyiSDKManager()
{
    disconnectedLink();
}

bool SiyiSDKManager::isConnectedLink()
{
    QList<SharedLinkInterfacePtr> links = _linkMgr->links();

    if(links.count() > 0){
        qDebug()<<"links is not 0";
    }
    return links.count();
}

void SiyiSDKManager::disconnectedLink()
{
    _sendCustomMessageTimer.stop();
    disconnect(&_sendCustomMessageTimer, &QTimer::timeout, this, &SiyiSDKManager::requestLinkStatus);
}

void SiyiSDKManager::setToolbox(QGCToolbox *toolbox)
{
   QGCTool::setToolbox(toolbox);
   _linkMgr = _toolbox->linkManager();
   _appSettings = _toolbox->settingsManager()->appSettings();
}

void SiyiSDKManager::read_incoming_packets(LinkInterface* link, QByteArray b){

    uint16_t nbytes = std::min(b.size(), 1024);
    if(nbytes <= 0 || nbytes > 50) {
        return;
    }

//    if (static_cast<char>(b[0]) == 0x55 && static_cast<char>(b[1]) == 0x66 && static_cast<char>(b[2]) == 0x02){
//        qDebug() << "recieved :" << b.toHex();
//    }

    reset_parser = false;

    for(uint16_t i = 0; i < nbytes; i ++){
        uint8_t p = static_cast<uint8_t>(b[i]);

        if ((p < 0) || (p > 0xff)) {
            continue;
        }

        _msg_buff[_msg_buff_len++] = p;

        if (_msg_buff_len >= MK15_SIYI_PACKETLEN_MAX) {
            reset_parser = true;
        }

        switch (_parsed_msg.state) {

        case ParseState::WAITING_FOR_STX_LOW:
            if (p == MK15_SIYI_HEADER1) {
                _parsed_msg.state = ParseState::WAITING_FOR_STX_HIGH;
            } else {
                reset_parser = true;
            }
            break;

        case ParseState::WAITING_FOR_STX_HIGH:
            if (p == MK15_SIYI_HEADER2) {
                _parsed_msg.state = ParseState::WAITING_FOR_CTRL;
            } else {
                reset_parser = true;
            }
            break;

        case ParseState::WAITING_FOR_CTRL:
            _parsed_msg.state = ParseState::WAITING_FOR_DATALEN_LOW;
            break;

        case ParseState::WAITING_FOR_DATALEN_LOW:
            _parsed_msg.data_len = p;
            _parsed_msg.state = ParseState::WAITING_FOR_DATALEN_HIGH;
            break;

        case ParseState::WAITING_FOR_DATALEN_HIGH:
            _parsed_msg.data_len |= ((uint16_t)p << 8);
            // sanity check data length
            if (_parsed_msg.data_len == nbytes-MK15_SIYI_PACKETLEN_MIN) {
                _parsed_msg.state = ParseState::WAITING_FOR_SEQ_LOW;
                //qDebug() << "dataLen:" << _parsed_msg.data_len;
            } else {
                reset_parser = true;
                //debug("data len too large:%u (>%u)", (unsigned)_parsed_msg.data_len, (unsigned)AP_MOUNT_SIYI_DATALEN_MAX);
            }
            break;

        case ParseState::WAITING_FOR_SEQ_LOW:
            _parsed_msg.seq = p;
            _parsed_msg.state = ParseState::WAITING_FOR_SEQ_HIGH;
            break;

        case ParseState::WAITING_FOR_SEQ_HIGH:
            _parsed_msg.seq |= ((uint16_t)p << 8);
            _parsed_msg.state = ParseState::WAITING_FOR_CMDID;
            break;

        case ParseState::WAITING_FOR_CMDID:
            _parsed_msg.command_id = p;
            _parsed_msg.data_bytes_received = 0;
            if (_parsed_msg.data_len > 0) {
                _parsed_msg.state = ParseState::WAITING_FOR_DATA;
            } else {
                _parsed_msg.state = ParseState::WAITING_FOR_CRC_LOW;
            }
            break;

        case ParseState::WAITING_FOR_DATA:
            _parsed_msg.data_bytes_received++;
            if (_parsed_msg.data_bytes_received == _parsed_msg.data_len) {
                _parsed_msg.state = ParseState::WAITING_FOR_CRC_LOW;
            }
            break;

        case ParseState::WAITING_FOR_CRC_LOW:
            _parsed_msg.crc16 = p;
            _parsed_msg.state = ParseState::WAITING_FOR_CRC_HIGH;
            break;

        case ParseState::WAITING_FOR_CRC_HIGH:
            _parsed_msg.crc16 |= ((uint16_t)p << 8);
            const uint16_t expected_crc = crcSiyiSDK(_msg_buff, _msg_buff_len-2, 0);
            if (expected_crc == _parsed_msg.crc16) {
                process_packet();
            } else {
                qDebug() << "crc expected:" << QString::number((unsigned)expected_crc, 16) << "got:" << QString::number((unsigned)_parsed_msg.crc16, 16);
                qDebug() << "received:" << b.toHex();
            }
            reset_parser = true;
            break;
        }

        if (reset_parser == true) {
            _parsed_msg.state = ParseState::WAITING_FOR_STX_LOW;
            _msg_buff_len = 0;
        }
    }
}

uint16_t SiyiSDKManager::crcSiyiSDK(uint8_t *ptr, uint16_t len, uint16_t crc_init){
    {
        uint16_t crc, oldcrc16;
        uint8_t temp;
        crc = crc_init;
        while (len-- != 0)
        {
            temp = (crc >> 8) & 0xff;
            oldcrc16 = crc16_tab[*ptr ^ temp];
            crc = (crc << 8) ^ oldcrc16;
            ptr++;
        }
        // crc = ~crc; // ??
        return crc;
    }
}

void SiyiSDKManager::requestLinkStatus()
{
    QList<SharedLinkInterfacePtr> links = _linkMgr->links();
    bool enable = _appSettings->enableSiyiSDK()->rawValue().toBool();
    if (links.size() > 0 && enable) {
        uint8_t buffer[10] = {0x55,0x66,0x01,0x00,0x00,0x00,0x00,0x44,0x05,0xdc};
        //uint8_t buffer[10] = {0x55,0x66,0x01,0x00,0x00,0x00,0x00,0x40,0x81,0x9c};
        int len = sizeof(buffer);
        for(int i = 0; i < links.size(); i++){
            links[i] -> writeBytesThreadSafe((const char*)buffer, len);
        }
        //qDebug()<< "requestLinkStatus to SiyiSDK";

        _sendCustomMessageTimer.stop();
        _sendCustomMessageTimer.start(250);
    }
}

void SiyiSDKManager::process_packet()
{

    switch ((SiyiCommandId)_parsed_msg.command_id) {

        case SiyiCommandId::HARDWARE_ID:
            qDebug() << "CommandID received";
            break;

        case SiyiCommandId::ACQUIRE_SYSTEM_SETTINGS :
            break;

        case SiyiCommandId::SYSTEM_SETTINGS :
            break;

        case SiyiCommandId::REMOTE_CONTROL_CHANNELS :
            break;

        case SiyiCommandId::ACQUIRE_RC_LINK_STATUS :
            break;

        case SiyiCommandId::ACQUIRE_FPV_LINK_STATUS:{

            memcpy(&_linkStatus, _msg_buff, _msg_buff_len);

            _isConnected = true;
            _signal = _linkStatus.signal;
            _inactiveTime = _linkStatus.inactive_time;
            _upstream = _linkStatus.upstream;
            _downstream = _linkStatus.downstream;
            _txbandwidth = _linkStatus.txbandwidth;
            _rxbandwidth = _linkStatus.rxbandwidth;
            _rssi = _linkStatus.rssi;
            _freq = _linkStatus.freq;
            _channel = _linkStatus.channel;

            emit siyiStatusChanged();

//            qDebug() << "ACQUIRE_FPV_LINK_STATUS received";

//            qDebug() << "signal:" << _linkStatus.signal;
//            qDebug() << "inactive:" << _linkStatus.inactive_time;
//            qDebug() << "upstream:" << _linkStatus.upstream;
//            qDebug() << "dnstream:" << _linkStatus.downstream;
//            qDebug() << "txband:" << _linkStatus.txbandwidth;
//            qDebug() << "rxband:" << _linkStatus.rxbandwidth;
//            qDebug() << "rssi:" << _linkStatus.rssi;
//            qDebug() << "freq:" << _linkStatus.freq;
//            qDebug() << "ch:" << _linkStatus.channel;
//            qDebug() << "crc:" << _linkStatus.crc;
            }
            break;
    }
}
