#ifndef SIYI_H
#define SIYI_H

#include <QtCore/QLoggingCategory>
#include <QtCore/QObject>
#include <QtCore/QVariant>
#include <QtQmlIntegration/QtQmlIntegration>

#include "SiYiCamera.h"
#include "SiYiTransmitter.h"

Q_DECLARE_LOGGING_CATEGORY(SiYiLog)

class SiYi : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
    Q_MOC_INCLUDE("SiYiCamera.h")
    Q_MOC_INCLUDE("SiYiTransmitter.h")
    Q_PROPERTY(QVariant camera READ camera CONSTANT)
    Q_PROPERTY(QVariant transmitter READ transmitter CONSTANT)
    Q_PROPERTY(bool isAndroid READ isAndroid CONSTANT)
    Q_PROPERTY(bool hideWidgets READ hideWidgets WRITE setHideWidgets NOTIFY hideWidgetsChanged FINAL)
    Q_PROPERTY(int iconsHeight READ iconsHeight WRITE setIconsHeight NOTIFY iconsHeightChanged FINAL)

public:
    explicit SiYi(QObject *parent = nullptr);
    ~SiYi();

    static SiYi *instance();
    void init();

    SiYiCamera *cameraInstance();
    SiYiTransmitter *transmitterInstance();

private:
    SiYiCamera *camera_ = nullptr;
    SiYiTransmitter *transmitter_ = nullptr;
    bool isTransmitterConnected_ = false;
    bool initialized_ = false;
    QVariant camera() { return QVariant::fromValue(camera_); }
    QVariant transmitter() { return QVariant::fromValue(transmitter_); }

    bool isAndroid_ = false;
    bool isAndroid() { return isAndroid_; }

    bool hideWidgets_ = false;
    bool hideWidgets() { return hideWidgets_; }
    void setHideWidgets(bool value)
    {
        hideWidgets_ = value;
        emit hideWidgetsChanged();
    }

    int iconsHeight_ = 54;
    int iconsHeight() { return iconsHeight_; }
    void setIconsHeight(int value)
    {
        iconsHeight_ = value;
        emit iconsHeightChanged();
    }

signals:
    void hideWidgetsChanged();
    void iconsHeightChanged();
};

#endif // SIYI_H
