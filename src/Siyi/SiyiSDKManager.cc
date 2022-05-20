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
#include "UASInterface.h"
#include "UASInterface.h"
#include "UAS.h"
#include "LinkManager.h"
#include "QGC.h"
#include "QGCApplication.h"
#include "SettingsManager.h"

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
}

void SiyiSDKManager::receivedLinkStatus(LinkInterface* link, QByteArray ba){

    QByteArray b = ba;

    uint16_t stx = (static_cast<uint8_t>(b[1]) << 8) + static_cast<uint8_t>(b[0]);
    uint16_t len = 0;

    //if (static_cast<char>(b[0]) == 0x55 && static_cast<char>(b[1]) == 0x66 && static_cast<char>(b[2]) == 0x02){
    if (stx == 26197 && static_cast<uint8_t>(b[2]) == 0x02){
        len = (static_cast<uint8_t>(b[4]) << 8) + static_cast<uint8_t>(b[3]) + 10;
        if (len == b.size()){
            uint16_t recvCRC = (static_cast<uint8_t>(b[len-1]) << 8) + static_cast<uint8_t>(b[len-2]);
            uint16_t calcCRC = crcSiyiSDK(b, b.size()-2);
//            qDebug() << "recieved siyi SDK:" << b.toHex();
//            qDebug() << "stx:" << stx;
//            qDebug() << "recv CRC:" << recvCRC;
//            qDebug() << "calc CRC:" << calcCRC;

            if(recvCRC == calcCRC){

                b.insert(3, 1, (uint8_t)0x00);
                b.insert(9, 3, (uint8_t)0x00);
//                _linkStatus = {};

                memcpy(&_linkStatus, b, b.size());

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

                b.clear();
            }
        }
    }
}

uint16_t SiyiSDKManager::crcSiyiSDK(const char *buf, int len){
    uint16_t crc = 0;
    while(len--){
        int i ;
        crc = crc ^ (*(uint16_t*)buf++ << 8);
        for( i = 0; i < 8; i++){
            if(crc & 0x8000)
                crc = (crc << 1) ^ 0x1021;
            else
                crc = crc << 1;
        }
    }
    return crc;
}

void SiyiSDKManager::requestLinkStatus()
{
    QList<SharedLinkInterfacePtr> links = _linkMgr->links();
    if (links.size() <= 0) {
        //qDebug()<< "sendCustomMessage: link gone!";
        return;
    }
    uint8_t buffer[10] = {0x55,0x66,0x01,0x00,0x00,0x00,0x00,0x44,0x05,0xdc};
    int len = sizeof(buffer);
    for(int i = 0; i < links.size(); i++){
        links[i] -> writeBytesThreadSafe((const char*)buffer, len);
    }
    //qDebug()<< "requestLinkStatus to SiyiSDK";

    _sendCustomMessageTimer.stop();
    _sendCustomMessageTimer.start(500);
}
