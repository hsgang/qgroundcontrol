#include <QTimer>
#include <QtEndian>
#include <QDateTime>
#include <QTcpSocket>
#include <QTimerEvent>

#include "SiYiCrcApi.h"
#include "SiYiTcpClient.h"
#include "QGCLoggingCategory.h"

QGC_LOGGING_CATEGORY(SiYiTcpClientLog, "SiYi.SiYiTcpClient")

SiYiTcpClient::SiYiTcpClient(const QString ip, quint16 port, QObject *parent)
    : QThread(parent)
    , ip_(ip)
    , port_(port)
{
    sequence_ = quint16(QDateTime::currentMSecsSinceEpoch());
    connect(this, &SiYiTcpClient::finished, this, [=, this]() { start(); });
}

SiYiTcpClient::~SiYiTcpClient()
{
    if (isRunning()) {
        exit();
        wait();
    }
}

void SiYiTcpClient::sendMessage(const QByteArray &msg)
{
    if (isRunning()) {
        txMessageVectorMutex_.lock();
        txMessageVector_.append(msg);
        txMessageVectorMutex_.unlock();
    }
}

void SiYiTcpClient::analyzeIp(QString videoUrl)
{
    qWarning() << videoUrl;
    videoUrl = videoUrl.remove(QString("rtsp://"));
    QStringList strList = videoUrl.split('/');
    if (!strList.isEmpty()) {
        // rtsp://192/168.144.25:8554/video1
        QString parsedIp = strList.first();
        if (parsedIp.contains(":")) {
            if (parsedIp.split(':').length() == 2) {
                parsedIp = parsedIp.split(':').first();
                if (parsedIp.split('.').length() == 4) {
                    resetIp(parsedIp);
                }
            }
        } else {
            // rtsp://192.168.144.60/video0
            if (parsedIp.split('.').length() == 4) {
                resetIp(parsedIp);
            } else {
                qWarning() << "rtsp url is invalid:" << videoUrl;
            }
        }
    } else {
        qWarning() << "rtsp url is invalid:" << videoUrl;
    }
}

quint16 SiYiTcpClient::sequence()
{
    quint16 seq = sequence_;
    sequence_ += 1;
    return seq;
}

void SiYiTcpClient::run()
{
    QTcpSocket *tcpClient = new QTcpSocket();
    QTimer *txTimer = new QTimer();
    QTimer *rxTimer = new QTimer();
    QTimer *heartbeatTimer = new QTimer();
    const QString info = QString("[%1:%2]:").arg(ip_, QString::number(port_));

    connect(tcpClient, &QTcpSocket::connected, tcpClient, [=, this](){
        qCDebug(SiYiTcpClientLog) << "Connect to server successfully!";

        heartbeatTimer->start();
        txTimer->start();

        this->isConnected_ = true;

        emit connected();
        emit isConnectedChanged();
    });
    connect(tcpClient, &QTcpSocket::disconnected, tcpClient, [=, this](){
        qCDebug(SiYiTcpClientLog) << "Disconnect from server:" << tcpClient->errorString();

        this->isConnected_ = false;
        this->txMessageVectorMutex_.lock();
        this->txMessageVector_.clear();
        this->txMessageVectorMutex_.unlock();

        emit isConnectedChanged();

        heartbeatTimer->stop();
        exit();
    });
    connect(tcpClient, &QTcpSocket::errorOccurred, tcpClient, [=, this](){
        heartbeatTimer->stop();
        exit();
        qCDebug(SiYiTcpClientLog) << tcpClient->errorString();
    });

    // 定时发送
    txTimer->setInterval(10);
    txTimer->setSingleShot(true);
    connect(txTimer, &QTimer::timeout, txTimer, [=, this](){
        this->txMessageVectorMutex_.lock();
        QByteArray msg = this->txMessageVector_.isEmpty()
                             ? QByteArray()
                             : this->txMessageVector_.takeFirst();
        this->txMessageVectorMutex_.unlock();

        if ((!msg.isEmpty())) {
            if ((tcpClient->state() == QTcpSocket::ConnectedState)) {
                if (tcpClient->write(msg) != -1) {
                    qCDebug(SiYiTcpClientLog) << "Tx:" << msg.toHex(' ');
                } else {
                    qCDebug(SiYiTcpClientLog) << tcpClient->errorString();
                }
            } else {
                qCDebug(SiYiTcpClientLog) << "Not connected state, the state is:" << tcpClient->state();
                qCDebug(SiYiTcpClientLog) << tcpClient->errorString();
                exit();
            }
        }

        txTimer->start();
    });

    // 定时处理接收数据
    rxTimer->setInterval(1);
    rxTimer->setSingleShot(true);
    connect(rxTimer, &QTimer::timeout, rxTimer, [=, this](){
        this->rxBytesMutex_.lock();

        QByteArray bytes = tcpClient->readAll();
        this->rxBytes_.append(bytes);

        analyzeMessage();

        this->rxBytesMutex_.unlock();

        rxTimer->start();
    });

    // 心跳
    heartbeatTimer->setInterval(1500);
    heartbeatTimer->setSingleShot(true);
    connect(heartbeatTimer, &QTimer::timeout, heartbeatTimer, [=, this](){
        // 心跳超时后退出线程
        this->timeoutCountMutex.lock();
        int count = this->timeoutCount;
        this->timeoutCountMutex.unlock();

        if (count > 3) {
            this->timeoutCountMutex.lock();
            this->timeoutCount = 0;
            this->timeoutCountMutex.unlock();

            qCDebug(SiYiTcpClientLog) << "Heartbeat timeout, the client will be restart soon!";
            this->exit();
        }

        this->timeoutCountMutex.lock();
        this->timeoutCount += 1;
        this->timeoutCountMutex.unlock();

        QByteArray msg = heartbeatMessage();
        sendMessage(msg);
        heartbeatTimer->start();
    });

    tcpClient->connectToHost(ip_, port_);

    //txTimer->start();
    rxTimer->start();
    exec();
    txTimer->deleteLater();
    tcpClient->deleteLater();
}

quint16 SiYiTcpClient::checkSum16(const QByteArray &bytes)
{
    return SiYiCrcApi::calculateCrc16(bytes);
}

quint32 SiYiTcpClient::checkSum32(const QByteArray &bytes)
{
    return SiYiCrcApi::calculateCrc32(bytes);
}

void SiYiTcpClient::resetIp(const QString &ip)
{
    if (ip_ != ip) {
        ip_ = ip;
        exit();
        wait();
        emit ipChanged();
    }
}
