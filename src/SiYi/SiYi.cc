#include "SiYi.h"
#include "QGCApplication.h"
#include "QGCLoggingCategory.h"

#include <QtCore/QApplicationStatic>
#include <QtCore/QCoreApplication>

QGC_LOGGING_CATEGORY(SiYiLog, "SiYi.SiYi")

Q_APPLICATION_STATIC(SiYi, _siyiInstance);

SiYi::SiYi(QObject *parent)
    : QObject(parent)
{
    qCDebug(SiYiLog) << this;

#ifdef Q_OS_ANDROID
    isAndroid_ = true;
#else
    isAndroid_ = false;
#endif
}

SiYi::~SiYi()
{
    qCDebug(SiYiLog) << this;
}

SiYi *SiYi::instance()
{
    return _siyiInstance();
}

void SiYi::init()
{
    if (initialized_) {
        qCDebug(SiYiLog) << "SiYi already initialized";
        return;
    }

    qCDebug(SiYiLog) << "Initializing SiYi";

    camera_ = new SiYiCamera(this);
    transmitter_ = new SiYiTransmitter(this);

    connect(transmitter_, &SiYiCamera::connected, this, [this](){
        isTransmitterConnected_ = true;
        camera_->start();
    });

    connect(transmitter_, &SiYiCamera::disconnected, this, [this](){
        isTransmitterConnected_ = false;
        transmitter_->exit();
    });

    connect(transmitter_, &SiYiTransmitter::ipChanged, this, [this](){
        if (transmitter_->isRunning()) {
            transmitter_->exit();
            transmitter_->wait();
        }
        transmitter_->start();
    });

    connect(camera_, &SiYiCamera::ipChanged, this, [this](){
        if (camera_->isRunning()) {
            camera_->exit();
            camera_->wait();
        }
        camera_->start();
    });

    transmitter_->start();
#if 1   // 为1时，云台控制无需先连接
    camera_->start();
#endif

    initialized_ = true;
}

SiYiCamera *SiYi::cameraInstance()
{
    return camera_;
}

SiYiTransmitter *SiYi::transmitterInstance()
{
    return transmitter_;
}
