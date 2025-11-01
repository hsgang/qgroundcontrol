#pragma once

#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QSettings>
#include <QRandomGenerator>

#include "LinkConfiguration.h"

class WebRTCConfiguration : public LinkConfiguration
{
    Q_OBJECT

    Q_PROPERTY(QString gcsId READ gcsId WRITE setGcsId NOTIFY gcsIdChanged)
    Q_PROPERTY(QString targetDroneId READ targetDroneId WRITE setTargetDroneId NOTIFY targetDroneIdChanged)

   public:
    explicit WebRTCConfiguration(const QString &name, QObject *parent = nullptr);
    explicit WebRTCConfiguration(const WebRTCConfiguration *copy, QObject *parent = nullptr);
    ~WebRTCConfiguration();

    LinkType type() const override { return LinkConfiguration::TypeWebRTC; }
    void copyFrom(const LinkConfiguration *source) override;
    void loadSettings(QSettings &settings, const QString &root) override;
    void saveSettings(QSettings &settings, const QString &root) const override;
    QString settingsURL() const override { return QStringLiteral("WebRTCSettings.qml"); }
    QString settingsTitle() const override { return tr("WebRTC Link Settings"); }

    // Getters and Setters
    QString gcsId() const { return _gcsId; }
    void setGcsId(const QString &id);

    QString targetDroneId() const { return _targetDroneId; }
    void setTargetDroneId(const QString &id);

    // CloudSettings에서 WebRTC 설정을 가져오는 getter 메서드들
    QString stunServer() const;
    QString turnServer() const;
    QString turnUsername() const;
    QString turnPassword() const;

   signals:
    void gcsIdChanged();
    void targetDroneIdChanged();

   private:
    QString _gcsId;
    QString _targetDroneId;

    QString _generateRandomId(int length = 8) const;
};
