/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QtCore/QLoggingCategory>
#include <QtCore/QObject>
#include <QtQmlIntegration/QtQmlIntegration>

Q_DECLARE_LOGGING_CATEGORY(ModelProfileManagerLog)

class Fact;
class QmlObjectListModel;
class ModelProfile;

/// Loads the specified action file and provides access to the actions it contains.
/// Action files are loaded from the default CustomActions directory.
/// The actions file name is filename only, no path.
class ModelProfileManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_MOC_INCLUDE("Fact.h")
    Q_MOC_INCLUDE("QmlObjectListModel.h")
    Q_PROPERTY(Fact* profileFileNameFact READ profileFileNameFact WRITE setProfileFileNameFact NOTIFY profileFileNameFactChanged)
    Q_PROPERTY(QmlObjectListModel* profiles READ profiles CONSTANT)

public:
    explicit ModelProfileManager(QObject *parent = nullptr);
    explicit ModelProfileManager(Fact *profileFileNameFact, QObject *parent = nullptr);
    ~ModelProfileManager();

    static ModelProfileManager *instance();

    void init(Fact *profileFileNameFact);

    Fact *profileFileNameFact() { return _profileFileNameFact; }
    void setProfileFileNameFact(Fact *profileFileNameFact);
    QmlObjectListModel *profiles() { return _profiles; }

signals:
    void profileFileNameFactChanged();

private slots:
    void _loadProfilesFile();

private:
    Fact *_profileFileNameFact = nullptr;
    QmlObjectListModel *_profiles = nullptr;
};

class ModelProfile: public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString label READ label CONSTANT)
    Q_PROPERTY(QString description READ description CONSTANT)

public:
    explicit ModelProfile(QObject *parent = nullptr);
    ModelProfile(
        const QString &label,
        const QString &description,
        bool enable,
        float value,
        QObject *parent = nullptr
    );
    ~ModelProfile();

    const QString &label() const { return _label; }
    const QString &description() const { return _description; }

private:
    const QString _label;
    const QString _description;
    bool _enable;
    float _value;
};
