/****************************************************************************
 *
 * (c) 2009-2023 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include <QQmlEngine>

#include "CustomActionManager.h"
#include "CustomAction.h"
#include "JsonHelper.h"
#include "QGCApplication.h"
#include "SettingsManager.h"

CustomActionManager::CustomActionManager(void) {
    QString customActionsPath = qgcApp()->toolbox()->settingsManager()->flyViewSettings()->customActionDefinitions()->rawValue().toString();
    _hasActions = _loadFromJson(customActionsPath);
}

bool CustomActionManager::_loadFromJson(const QString& path) {
    const char* kQgcFileType = "CustomActions";
    const char* kActionListKey = "actions";

    QString errorString;
    int version;
    QJsonObject jsonObject = JsonHelper::openInternalQGCJsonFile(path, kQgcFileType, 1, 1, version, errorString);
    if (!errorString.isEmpty()) {
        qWarning() << "Custom Actions Internal Error: " << errorString;
        return false;
    }

    QList<JsonHelper::KeyValidateInfo> keyInfoList = {
        { kActionListKey, QJsonValue::Array, /* required= */ true },
    };
    if (!JsonHelper::validateKeys(jsonObject, keyInfoList, errorString)) {
        qWarning() << "Custom Actions JSON document incorrect format:" << errorString;
        return false;
    }

    // at this point we have a valid JSON document, so clear out previously defined actions
    _actions.clearAndDeleteContents();

    QJsonArray actionList = jsonObject[kActionListKey].toArray();
    for (auto actionJson: actionList) {
        if (!actionJson.isObject()) {
            qWarning() << "Custom Actions JsonValue not an object: " << actionJson;
            continue;
        }

        auto actionObj = actionJson.toObject();

        QList<JsonHelper::KeyValidateInfo> actionKeyInfoList = {
            { "label",  QJsonValue::String, /* required= */ true },
            { "mavCmd", QJsonValue::Double, /* required= */ true },

            { "compId", QJsonValue::Double, /* required= */ false },
            { "param1", QJsonValue::Double, /* required= */ false },
            { "param2", QJsonValue::Double, /* required= */ false },
            { "param3", QJsonValue::Double, /* required= */ false },
            { "param4", QJsonValue::Double, /* required= */ false },
            { "param5", QJsonValue::Double, /* required= */ false },
            { "param6", QJsonValue::Double, /* required= */ false },
            { "param7", QJsonValue::Double, /* required= */ false },
        };
        if (!JsonHelper::validateKeys(actionObj, actionKeyInfoList, errorString)) {
            qWarning() << "Custom Actions JSON document incorrect format:" << errorString;
            continue;
        }

        auto label = actionObj["label"].toString();
        auto mavCmd = (MAV_CMD)actionObj["mavCmd"].toInt();
        auto compId = (MAV_COMPONENT)actionObj["compId"].toInt(MAV_COMP_ID_AUTOPILOT1);
        auto param1 = actionObj["param1"].toDouble(0.0);
        auto param2 = actionObj["param2"].toDouble(0.0);
        auto param3 = actionObj["param3"].toDouble(0.0);
        auto param4 = actionObj["param4"].toDouble(0.0);
        auto param5 = actionObj["param5"].toDouble(0.0);
        auto param6 = actionObj["param6"].toDouble(0.0);
        auto param7 = actionObj["param7"].toDouble(0.0);

        CustomAction* action = new CustomAction(label, mavCmd, compId, param1, param2, param3, param4, param5, param6, param7);
        QQmlEngine::setObjectOwnership(action, QQmlEngine::CppOwnership);
        _actions.append(action);
    }

    return _actions.count() > 0;
}
