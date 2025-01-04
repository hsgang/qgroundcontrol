/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "ModelProfileManager.h"
#include "Fact.h"
#include "JsonHelper.h"
#include "QGCApplication.h"
#include "SettingsManager.h"
#include "AppSettings.h"
#include "FlyViewSettings.h"
#include "SettingsGroup.h"
#include "QGCLoggingCategory.h"
#include "QmlObjectListModel.h"

#include <QtCore/QDir>
#include <QtCore/QJsonArray>
#include <QtQml/QQmlEngine>

QGC_LOGGING_CATEGORY(ModelProfileManagerLog, "qgc.qmlcontrols.modelprofilemanager")

Q_APPLICATION_STATIC(ModelProfileManager, _cloudManagerInstance);

ModelProfileManager::ModelProfileManager(QObject *parent)
    : QObject(parent)
    , _profiles(new QmlObjectListModel(this))
{
    // qCDebug(CustomActionManagerLog) << Q_FUNC_INFO << this;
}

ModelProfileManager::ModelProfileManager(Fact *profileFileNameFact, QObject *parent)
    : QObject(parent)
    , _profiles(new QmlObjectListModel(this))
{
    setProfileFileNameFact(profileFileNameFact);
}

ModelProfileManager::~ModelProfileManager()
{
    // qCDebug(CustomActionManagerLog) << Q_FUNC_INFO << this;
}

ModelProfileManager *ModelProfileManager::instance()
{
    return _cloudManagerInstance();
}

void ModelProfileManager::init(Fact *profileFileNameFact)
{
    //_loadProfilesFile("profile.json");
    setProfileFileNameFact(profileFileNameFact);
}

void ModelProfileManager::setProfileFileNameFact(Fact *profileFileNameFact)
{
    _profileFileNameFact = profileFileNameFact;
    emit profileFileNameFactChanged();
    (void) connect(_profileFileNameFact, &Fact::rawValueChanged, this, &ModelProfileManager::_loadProfilesFile);

    _loadProfilesFile();
}

void ModelProfileManager::_loadProfilesFile()
{
    _profiles->clearAndDeleteContents();
    const QString profileFileName = _profileFileNameFact->rawValue().toString();
    if (profileFileName.isEmpty()) {
        return;
    }

    // Custom actions are always loaded from the custom actions save path
    const QString savePath = SettingsManager::instance()->appSettings()->modelProfilesSavePath();
    const QDir saveDir = QDir(savePath);
    const QString fullPath = saveDir.absoluteFilePath(profileFileName);

    // It's ok for the file to not exist
    const QFileInfo fileInfo = QFileInfo(fullPath);
    if (!fileInfo.exists()) {
        qCDebug(ModelProfileManagerLog) << "model profile file can't found ";
        return;
    }

    constexpr const char *kQgcFileType = "ModelProfiles";
    constexpr const char *kProfileListKey = "profiles";

    _profiles->clearAndDeleteContents();

    QString errorString;
    int version;
    const QJsonObject jsonObject = JsonHelper::openInternalQGCJsonFile(fullPath, kQgcFileType, 1, 1, version, errorString);
    if (!errorString.isEmpty()) {
        qgcApp()->showAppMessage(tr("Failed to load model profiles file: `%1` error: `%2`").arg(fullPath, errorString));
        return;
    }

    const QList<JsonHelper::KeyValidateInfo> keyInfoList = {
        { kProfileListKey, QJsonValue::Array, /* required= */ true },
    };
    if (!JsonHelper::validateKeys(jsonObject, keyInfoList, errorString)) {
        qgcApp()->showAppMessage(tr("Model profiles file - incorrect format: %1").arg(errorString));
        return;
    }

    const QJsonArray profileList = jsonObject[kProfileListKey].toArray();
    for (const auto &profileJson: profileList) {
        if (!profileJson.isObject()) {
            qgcApp()->showAppMessage(tr("Model profiles file - incorrect format: JsonValue not an object"));
            _profiles->clearAndDeleteContents();
            return;
        }

        const QList<JsonHelper::KeyValidateInfo> profileKeyInfoList = {
            { "label",          QJsonValue::String, /* required= */ true },
            { "description",    QJsonValue::String, /* required= */ false },
            { "enable",         QJsonValue::Bool, /* required= */ true },
            { "value",          QJsonValue::Double, /* required= */ false },
        };

        const auto profileObj = profileJson.toObject();
        if (!JsonHelper::validateKeys(profileObj, profileKeyInfoList, errorString)) {
            qgcApp()->showAppMessage(tr("Model profile file - incorrect format: %1").arg(errorString));
            _profiles->clearAndDeleteContents();
            return;
        }

        const auto label = profileObj["label"].toString();
        const auto description = profileObj["description"].toString();
        const auto enable = profileObj["enable"].toBool(false);
        const auto value = profileObj["value"].toDouble(0.0);

        ModelProfile *const profile = new ModelProfile(label, description, enable, value, this);
        QQmlEngine::setObjectOwnership(profile, QQmlEngine::CppOwnership);
        (void) _profiles->append(profile);
    }
    // 모든 항목을 순회하면서 출력
    for (int i = 0; i < _profiles->count(); i++) {
        QObject* obj = _profiles->get(i);
        if (!obj) {
            qCDebug(ModelProfileManagerLog) << "Item" << i << "is null";
            continue;
        }

        // QObject의 모든 프로퍼티 출력
        const QMetaObject* metaObj = obj->metaObject();
        qCDebug(ModelProfileManagerLog) << "Item" << i << ":";

        for (int p = 0; p < metaObj->propertyCount(); p++) {
            QMetaProperty prop = metaObj->property(p);
            QString propName = prop.name();
            QVariant value = obj->property(prop.name());
            qCDebug(ModelProfileManagerLog) << "  " << propName << ":" << value.toString();
        }
    }

    SettingsManager::instance()->flyViewSettings()->showWinchControl()->setRawValue(false);
    //qCDebug(ModelProfileManagerLog) << _profiles;
}

ModelProfile::ModelProfile(QObject *parent)
    :QObject(parent)
{

}

ModelProfile::ModelProfile(
    const QString &label,
    const QString &description,
    bool enable,
    float value,
    QObject *parent
) : QObject(parent)
    , _label(label)
    , _description(description)
    , _enable(enable)
    , _value(value)
{

}

ModelProfile::~ModelProfile()
{

}
