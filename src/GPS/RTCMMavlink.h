/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


#pragma once

#include "QGCToolbox.h"
#include "MAVLinkLib.h"

#include <QtCore/QObject>
#include <QtCore/QElapsedTimer>

/**
 ** class RTCMMavlink
 * Receives RTCM updates and sends them via MAVLINK to the device
 */
class RTCMMavlink : public QObject
{
    Q_OBJECT
public:
    RTCMMavlink(QGCToolbox& toolbox);
    //TODO: API to select device(s)?

public slots:
    void RTCMDataUpdate(QByteArray message);

private:
    void sendMessageToVehicle(const mavlink_gps_rtcm_data_t& msg);

    QGCToolbox& _toolbox;
    QElapsedTimer _bandwidthTimer;
    int _bandwidthByteCounter = 0;
    uint8_t _sequenceId = 0;
};
