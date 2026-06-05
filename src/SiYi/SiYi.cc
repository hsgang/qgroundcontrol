#include "SiYi.h"
#include "Fact.h"
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
    Fact *const cameraEnabledFact      = settings->siyiCameraEnabled();
    Fact *const transmitterEnabledFact = settings->siyiTransmitterEnabled();
    Fact *const uniRCEnabledFact       = settings->siyiUniRCEnabled();

    camera_ = new SiYiCamera(this);
    transmitter_ = new SiYiTransmitter(this);
    uniRC_ = new SiYiUniRC(this);

    // The QML camera/transmitter/uniRC properties are null until created here.
    // Notify so any binding that read them before init() (e.g. a panel shown at
    // startup) re-reads the now-valid instances instead of caching null.
    emit cameraChanged();
    emit transmitterChanged();
    emit uniRCChanged();

    camera_->setIp(settings->siyiCameraIp()->rawValue().toString());
    transmitter_->setIp(settings->siyiTransmitterIp()->rawValue().toString());
    uniRC_->setIp(settings->siyiUniRCIp()->rawValue().toString());
    uniRC_->setTransport(
        settings->siyiUniRCTransportMode()->rawValue().toInt(),
        settings->siyiUniRCSerialPort()->rawValue().toString(),
        settings->siyiUniRCSerialBaud()->rawValue().toInt());
    // Variant A: relay datalink MAVLink to a loopback UDP link. The relay port is
    // the local port QGC's MAVLink UDP link listens on; 0 disables the relay and
    // keeps the legacy SDK-only ephemeral socket behavior. Bound at start(), so a
    // change requires a restart (qgcRebootRequired on the fact).
    uniRC_->setRelayPort(static_cast<quint16>(settings->siyiUniRCRelayPort()->rawValue().toUInt()));

    connect(transmitter_, &SiYiCamera::connected, this, [this, cameraEnabledFact](){
        isTransmitterConnected_ = true;
        if (cameraEnabledFact->rawValue().toBool()) {
            camera_->setEnabled(true);
        }
    });

    connect(transmitter_, &SiYiCamera::disconnected, this, [this](){
        isTransmitterConnected_ = false;
        transmitter_->exit();
    });

    connect(transmitter_, &SiYiTransmitter::ipChanged, this, [this](){
        // Apply the new IP by restarting, but only while the client is enabled.
        if (!transmitter_->isEnabled()) {
            return;
        }
        if (transmitter_->isRunning()) {
            transmitter_->exit();
            transmitter_->wait();
        }
        transmitter_->start();
    });

    connect(camera_, &SiYiCamera::ipChanged, this, [this](){
        if (!camera_->isEnabled()) {
            return;
        }
        if (camera_->isRunning()) {
            camera_->exit();
            camera_->wait();
        }
        camera_->start();
    });

    // Apply the persisted enabled state, then keep the clients in sync with
    // runtime toggles from the SiYi settings page.
    transmitter_->setEnabled(transmitterEnabledFact->rawValue().toBool());
    camera_->setEnabled(cameraEnabledFact->rawValue().toBool());
    if (uniRCEnabledFact->rawValue().toBool()) {
        uniRC_->start();
    }

    connect(transmitterEnabledFact, &Fact::rawValueChanged, this, [this](QVariant value){
        transmitter_->setEnabled(value.toBool());
    });
    connect(cameraEnabledFact, &Fact::rawValueChanged, this, [this](QVariant value){
        camera_->setEnabled(value.toBool());
    });
    connect(uniRCEnabledFact, &Fact::rawValueChanged, this, [this](QVariant value){
        if (value.toBool()) {
            uniRC_->start();
        } else {
            uniRC_->stop();
        }
    });

    // Apply IP changes live. setIp() restarts the UniRC client itself; for the
    // transmitter/camera, setIp() emits ipChanged() which the handlers above use
    // to restart the running client.
    connect(settings->siyiUniRCIp(), &Fact::rawValueChanged, this, [this](QVariant value){
        uniRC_->setIp(value.toString());
    });
    connect(settings->siyiTransmitterIp(), &Fact::rawValueChanged, this, [this](QVariant value){
        transmitter_->setIp(value.toString());
    });
    connect(settings->siyiCameraIp(), &Fact::rawValueChanged, this, [this](QVariant value){
        camera_->setIp(value.toString());
    });

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
