#include "SiYi.h"
#include "QGCApplication.h"
#include "QGCLoggingCategory.h"
#include "SIYISettings.h"
#include "SettingsManager.h"

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

    SIYISettings *settings = SettingsManager::instance()->siyiSettings();
    const bool cameraEnabled      = settings->siyiCameraEnabled()->rawValue().toBool();
    const bool transmitterEnabled = settings->siyiTransmitterEnabled()->rawValue().toBool();
    const bool uniRCEnabled       = settings->siyiUniRCEnabled()->rawValue().toBool();

    camera_ = new SiYiCamera(this);
    transmitter_ = new SiYiTransmitter(this);
    uniRC_ = new SiYiUniRC(this);

    camera_->setIp(settings->siyiCameraIp()->rawValue().toString());
    transmitter_->setIp(settings->siyiTransmitterIp()->rawValue().toString());
    uniRC_->setIp(settings->siyiUniRCIp()->rawValue().toString());

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

    if (transmitterEnabled) {
        transmitter_->start();
    }
    if (cameraEnabled) {
        camera_->start();
    }
    if (uniRCEnabled) {
        uniRC_->start();
    }

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

SiYiUniRC *SiYi::uniRCInstance()
{
    return uniRC_;
}
