/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "NTRIPManager.h"
#include "QGCLoggingCategory.h"
#include "QGCToolbox.h"
#include "QGCApplication.h"
#include "SettingsManager.h"
#include "NTRIPSettings.h"

#include <QDebug>

QGC_LOGGING_CATEGORY(NTRIPManagerLog, "qgc.ntrip.ntripmanager")

//Q_APPLICATION_STATIC(NTRIPManager, _ntripManager, qgcApp()->toolbox()->settingsManager()->ntripSettings());

NTRIPManager::NTRIPManager(QGCApplication *app, QGCToolbox *toolbox)
    : QGCTool(app, toolbox)
{    
    //qCDebug(NTRIPManagerLog) << "ntripmanager start" << ntripEnabled->rawValue().toBool();
}

NTRIPManager::~NTRIPManager()
{

}

void NTRIPManager::setToolbox(QGCToolbox* toolbox)
{
    QGCTool::setToolbox(toolbox);

    //_ntripSettings = qgcApp()->toolbox()->settingsManager()->ntripSettings();
    _ntripSettings = toolbox->settingsManager()->ntripSettings();

    Fact* const ntripEnabled = _ntripSettings->ntripEnabled();
    Fact* const hostAddress = _ntripSettings->ntripServerHostAddress();
    Fact* const port = _ntripSettings->ntripServerPort();
    Fact* const userName = _ntripSettings->ntripUsername();
    Fact* const password = _ntripSettings->ntripPassword();
    Fact* const mountPoint = _ntripSettings->ntripMountpoint();
    Fact* const whiteList = _ntripSettings->ntripWhitelist();
    Fact* const enableVRS = _ntripSettings->ntripEnableVRS();

    connect(ntripEnabled, &Fact::rawValueChanged, this, [this, hostAddress, port, userName, password, mountPoint, whiteList, enableVRS](QVariant value) {
        if (value.toBool()) {
            _start(hostAddress->rawValue().toString(),
                   port->rawValue().toUInt(),
                   userName->rawValue().toString(),
                   password->rawValue().toString(),
                   mountPoint->rawValue().toString(),
                   whiteList->rawValue().toString(),
                   enableVRS->rawValue().toBool());
        } else {
            qCDebug(NTRIPManagerLog) << "NTRIPManager is disabled";
            _stop();
        }
    });

    if (ntripEnabled->rawValue().toBool()) {
        _start(hostAddress->rawValue().toString(),
               port->rawValue().toUInt(),
               userName->rawValue().toString(),
               password->rawValue().toString(),
               mountPoint->rawValue().toString(),
               whiteList->rawValue().toString(),
               enableVRS->rawValue().toBool());
    }

    // connect(_tcpLink, &NTRIPTCPLink::error,             this, &NTRIP::_tcpError,           Qt::QueuedConnection);
    // connect(_tcpLink, &NTRIPTCPLink::RTCMDataUpdate,    _rtcmMavlink, &RTCMMavlink::RTCMDataUpdate);
    //connect(_tcpLink, &NTRIPTCPLink::connectStatus,     this, &NTRIP::connectStatus);


    // updateSettings();
}

void NTRIPManager::_start(const QString& hostAddress,
                int port,
                const QString &username,
                const QString &password,
                const QString &mountpoint,
                const QString &whitelist,
                const bool    &enableVRS)
{
    if (_ntripTcpLink) {
        qCWarning(NTRIPManagerLog) << "NTRIP TCP Link already exists. Stopping existing connection.";
        _stop();
    }
    _rtcmMavlink = new RTCMMavlink(this);
    _ntripTcpLink = new NTRIPTCPLink(hostAddress,
                                     port,
                                     username,
                                     password,
                                     mountpoint,
                                     whitelist,
                                     enableVRS,
                                     this);

    if (!_ntripTcpLink) {
        qCCritical(NTRIPManagerLog) << "Failed to create NTRIP TCP Link";
        return;
    }

    if (!_rtcmMavlink) {
        qCCritical(NTRIPManagerLog) << "RTCM Mavlink object is null";
        return;
    }

    connect(_ntripTcpLink, &NTRIPTCPLink::rtcmDataUpdate, _rtcmMavlink, &RTCMMavlink::RTCMDataUpdate, Qt::AutoConnection);
    connect(_ntripTcpLink, &NTRIPTCPLink::errorOccurred, this, &NTRIPManager::_linkError, Qt::AutoConnection);
    connect(_ntripTcpLink, &NTRIPTCPLink::connectStatus, this, &NTRIPManager::connectStatus);
    connect(_ntripTcpLink, &NTRIPTCPLink::receivedCount, this, &NTRIPManager::ntripReceivedUpdate);
    connect(_ntripTcpLink, &NTRIPTCPLink::networkStatus, this, &NTRIPManager::networkStatus);

    _bandwidthTimer.start();
}

void NTRIPManager::stop()
{
    qCDebug(NTRIPManagerLog) << "clicked NTRIP stop";
    _stop();
}

void NTRIPManager::_stop()
{
    if(_ntripTcpLink)
    {
        disconnect(_ntripTcpLink, &NTRIPTCPLink::rtcmDataUpdate, _rtcmMavlink, &RTCMMavlink::RTCMDataUpdate);
        disconnect(_ntripTcpLink, &NTRIPTCPLink::errorOccurred, this, &NTRIPManager::_linkError);
        disconnect(_ntripTcpLink, &NTRIPTCPLink::connectStatus, this, &NTRIPManager::connectStatus);
        disconnect(_ntripTcpLink, &NTRIPTCPLink::receivedCount, this, &NTRIPManager::ntripReceivedUpdate);
        disconnect(_ntripTcpLink, &NTRIPTCPLink::networkStatus, this, &NTRIPManager::networkStatus);

        _ntripTcpLink->deleteLater();
        _ntripTcpLink = nullptr;
        _bandwidthTimer.restart();
        _bandWidth = 0;
        _connectedStatus = false;
        _networkStatus = 0;
        emit connectedChanged();
        emit ntripReceivedCountChanged();
        emit networkStateChanged();
    }
    if(_rtcmMavlink) {
        _rtcmMavlink->deleteLater();
        _rtcmMavlink = nullptr;
    }
}

void NTRIPManager::_linkError(const QString &errorMsg, bool stopped)
{
    qCDebug(NTRIPManagerLog) << errorMsg;

    QString msg = QStringLiteral("NTRIP Server Error: %1").arg(errorMsg);

    if (stopped) {
        (void) msg.append("\nNTRIP has been disabled");
        _ntripSettings->ntripEnabled()->setRawValue(false);
    }
    qgcApp()->showAppMessage(tr("NTRIP Server Error: %1").arg(errorMsg));
}

// void NTRIPManager::stopNTRIP(){
//     if(_tcpLink){
//         //_tcpLink->stopConnection();
//         QMetaObject::invokeMethod(_tcpLink, "stopConnection", Qt::QueuedConnection);
//     }
//     _bandwidthTimer.restart();
//     _bandWidth = 0;
//     emit ntripReceivedCountChanged();
//     qCDebug(NTRIPManagerLog) << "clicked NTRIP stop";
// }

void NTRIPManager::reconnect()
{
    // if(_tcpLink){
    //     //_tcpLink->reconnect();
    //     QMetaObject::invokeMethod(_tcpLink, "reconnect", Qt::QueuedConnection);
    // }
    // _bandwidthTimer.restart();
    // _bandWidth = 0;
    // emit ntripReceivedCountChanged();

    qCDebug(NTRIPManagerLog) << "clicked NTRIP reconnect";
}

void NTRIPManager::connectStatus(bool isConnected)
{
    if(isConnected == true) {
        _connectedStatus = true;
    } else {
        _connectedStatus = false;
    }
    emit connectedChanged();
    //qCDebug(NTRIPManagerLog) << "connectStatus changed";
}

void NTRIPManager::ntripReceivedUpdate(qint64 count)
{
    _ntripReceivedCount += count;

    _bandwidthByteCounter += count;
    qint64 elapsed = _bandwidthTimer.elapsed();
    if (elapsed > 1000) {
        _bandWidth = (float) _bandwidthByteCounter / elapsed * 1000.f / 1024.f;
        _bandwidthTimer.restart();
        _bandwidthByteCounter = 0;
    }
    qCDebug(NTRIPManagerLog) << "bandwidth : " << _bandWidth;
    emit ntripReceivedCountChanged();
}

void NTRIPManager::networkStatus(NTRIPTCPLink::NetworkState status)
{
    switch(status) {
    case NTRIPTCPLink::NetworkState::SocketConnecting :
        _networkStatus = 0;
        break;
    case NTRIPTCPLink::NetworkState::SocketConnected :
        _networkStatus = 1;
        break;
    case NTRIPTCPLink::NetworkState::ServerResponseWaiting :
        _networkStatus = 2;
        break;
    case NTRIPTCPLink::NetworkState::NtripConnected :
        _networkStatus = 3;
        break;
    default:
        _networkStatus = 0;
        break;
    }
    emit networkStateChanged();
    qCDebug(NTRIPManagerLog) << "networkState : " << _networkStatus;
}
