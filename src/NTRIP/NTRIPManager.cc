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
#include "QGCApplication.h"
#include "SettingsManager.h"
#include "NTRIPSettings.h"
#include "AppSettings.h"

#include <QtCore/qapplicationstatic.h>
#include <QtQml/qqml.h>
#include <QDebug>

QGC_LOGGING_CATEGORY(NTRIPManagerLog, "NTRIP.NTRIPManager")

Q_APPLICATION_STATIC(NTRIPManager, _ntripManagerInstance);

NTRIPManager::NTRIPManager(QObject *parent)
    : QObject(parent)
{
    qCDebug(NTRIPManagerLog) << "ntripmanager start";
}

NTRIPManager::~NTRIPManager()
{

}

NTRIPManager *NTRIPManager::instance()
{
    return _ntripManagerInstance();
}

void NTRIPManager::init()
{
    _ntripSettings = SettingsManager::instance()->ntripSettings();

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
            _connected = false;
            emit connectedChanged();
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
    connect(_ntripTcpLink, &NTRIPTCPLink::receivedCount, this, &NTRIPManager::ntripReceivedUpdate);

    _bandwidthTimer.start();

    connect(_ntripTcpLink, &NTRIPTCPLink::connectionStateChanged, this, [this](NTRIPTCPLink::ConnectionState state) {
        switch (state) {
        case NTRIPTCPLink::ConnectionState::Disconnected:
            _connectionState = tr("Disconnected");
            _connected = false;
            break;
        case NTRIPTCPLink::ConnectionState::Connecting:
            _connectionState = tr("Socket Connecting");
            break;
        case NTRIPTCPLink::ConnectionState::Connected:
            _connectionState = tr("Socket Connected");
            break;
        case NTRIPTCPLink::ConnectionState::AuthenticationPending:
            _connectionState = tr("Server Authenticating");
            break;
        case NTRIPTCPLink::ConnectionState::Authenticated:
            _connectionState = tr("Server Authenticated");
            break;
        case NTRIPTCPLink::ConnectionState::ReceivingData:
            _connectionState = tr("Receiving Data");
            _connected = true;
            break;
        case NTRIPTCPLink::ConnectionState::Error:
            _connectionState = tr("Error");
            break;
        case NTRIPTCPLink::ConnectionState::Closing:
            _connectionState = tr("Socket Closing");
            break;
        }
        emit connectionStateChanged();
        emit connectedChanged();
        //qCDebug(NTRIPManagerLog) << "connectionStateChanged1 : " << _connectionState;
    });

    connect(_ntripTcpLink, &NTRIPTCPLink::connectionStatsUpdated, this, &NTRIPManager::_handleConnectionStats);

    connect(_ntripTcpLink, &NTRIPTCPLink::lastErrorChanged, this, [this](const QString& error) {
        _lastError = error;
        emit lastErrorChanged();
    });
}

void NTRIPManager::stop()
{
    qCDebug(NTRIPManagerLog) << "clicked NTRIP stop";
    _stop();
}

void NTRIPManager::_stop()
{
    qCDebug(NTRIPManagerLog) << "NTRIP stopped";
    if(_ntripTcpLink)
    {
        disconnect(_ntripTcpLink, &NTRIPTCPLink::rtcmDataUpdate, _rtcmMavlink, &RTCMMavlink::RTCMDataUpdate);
        disconnect(_ntripTcpLink, &NTRIPTCPLink::errorOccurred, this, &NTRIPManager::_linkError);
        disconnect(_ntripTcpLink, &NTRIPTCPLink::receivedCount, this, &NTRIPManager::ntripReceivedUpdate);

        _ntripTcpLink->deleteLater();
        _ntripTcpLink = nullptr;
        _bandwidthTimer.restart();
        _bandWidth = 0;
        _dataRate = 0;
        _connectionState = tr("Disconnected");
        _lastError = "";

        emit connectedChanged();
        emit ntripReceivedCountChanged();
        emit dataRateChanged();
        emit lastErrorChanged();
        emit connectionStateChanged();
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
    //qgcApp()->showAppMessage(tr("NTRIP Server Error: %1").arg(errorMsg));
}

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

// void NTRIPManager::connectStatus(bool isConnected)
// {
//     if(isConnected == true) {
//         _connectedStatus = true;
//     } else {
//         _connectedStatus = false;
//     }
//     emit connectedChanged();
//     //qCDebug(NTRIPManagerLog) << "connectStatus changed";
// }

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

void NTRIPManager::_handleConnectionStats(const NTRIPTCPLink::ConnectionStats& stats)
{
    static qint64 lastBytes = 0;
    static qint64 lastTime = 0;

    // Reset stats if ntripTcpLink is null
    if (!_ntripTcpLink) {
        lastBytes = 0;
        lastTime = 0;
        _dataRate = 0;
        emit dataRateChanged();
        return;
    }

    qint64 currentTime = QDateTime::currentMSecsSinceEpoch();
    qint64 timeDiff = currentTime - lastTime;

    if (timeDiff > 0) {
        qint64 bytesDiff = stats.bytesReceived - lastBytes;
        _dataRate = (bytesDiff * 1000.0) / timeDiff; // bytes per second
        emit dataRateChanged();
    }

    lastBytes = stats.bytesReceived;
    lastTime = currentTime;

    // switch (stats.state) {
    //     case NTRIPTCPLink::ConnectionState::Disconnected:
    //         _connectionState = "Disconnected";
    //         break;
    //     case NTRIPTCPLink::ConnectionState::Connecting:
    //         _connectionState = "Connecting";
    //         break;
    //     case NTRIPTCPLink::ConnectionState::Connected:
    //         _connectionState = "Connected";
    //         break;
    //     case NTRIPTCPLink::ConnectionState::AuthenticationPending:
    //         _connectionState = "Authenticating";
    //         break;
    //     case NTRIPTCPLink::ConnectionState::Authenticated:
    //         _connectionState = "Authenticated";
    //         break;
    //     case NTRIPTCPLink::ConnectionState::ReceivingData:
    //         _connectionState = "Receiving Data";
    //         _connected = true;
    //         break;
    //     case NTRIPTCPLink::ConnectionState::Error:
    //         _connectionState = "Error";
    //         break;
    // }
    // emit connectionStateChanged();
    // qCDebug(NTRIPManagerLog) << "connectionStateChanged : " << _connectionState;
}
