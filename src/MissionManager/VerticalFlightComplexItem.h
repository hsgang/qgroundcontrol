/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include "TransectStyleComplexItem.h"
#include "MissionItem.h"
#include "SettingsFact.h"
#include "QGCLoggingCategory.h"
#include "QGCMapPolyline.h"
#include "QGCMapPolygon.h"

Q_DECLARE_LOGGING_CATEGORY(VerticalFlightComplexItemLog)

class VerticalFlightComplexItem : public TransectStyleComplexItem
{
    Q_OBJECT

public:
    /// @param flyView true: Created for use in the Fly View, false: Created for use in the Plan View
    /// @param kmlFile Polyline comes from this file, empty for default polyline
    VerticalFlightComplexItem(PlanMasterController* masterController, bool flyView, const QString& kmlFile);

    Q_PROPERTY(QGCMapPolyline*  verticalPolyline    READ verticalPolyline    CONSTANT)
    Q_PROPERTY(Fact*            verticalMaxAltitude READ verticalMaxAltitude CONSTANT)
    Q_PROPERTY(Fact*            verticalInterval    READ verticalInterval    CONSTANT)
    Q_PROPERTY(Fact*            verticalHoldTime    READ verticalHoldTime    CONSTANT)

    QGCMapPolyline*             verticalPolyline    (void) { return &_verticalPolyline; }
    Fact*                       verticalMaxAltitude (void) { return &_verticalMaxAltitudeFact; }
    Fact*                       verticalInterval    (void) { return &_verticalIntervalFact; }
    Fact*                       verticalHoldTime    (void) { return &_verticalHoldTimeFact; }

    Q_INVOKABLE void rotateEntryPoint(void);

    // Overrides from TransectStyleComplexItem
    QString patternName         (void) const final { return name; }
    void    save                (QJsonArray&  planItems) final;
    bool    specifiesCoordinate (void) const final;
    double  timeBetweenShots    (void) final;

    // Overrides from ComplexMissionItem
    bool    load                (const QJsonObject& complexObject, int sequenceNumber, QString& errorString) final;
    QString mapVisualQML        (void) const final { return QStringLiteral("VerticalFlightMapVisual.qml"); }
    QString presetsSettingsGroup(void) { return settingsGroup; }
    void    savePreset          (const QString& name);
    void    loadPreset          (const QString& name);

    // Overrides from VisualMissionionItem
    QString             commandDescription  (void) const final { return tr("Vertical Flight"); }
    QString             commandName         (void) const final { return tr("Vertical Flight"); }
    QString             abbreviation        (void) const final { return tr("V"); }
    ReadyForSaveState   readyForSaveState   (void) const final;
    double              additionalTimeDelay (void) const final { return 0; }

    static const QString name;

    static const char* jsonComplexItemTypeValue;
    static const char* settingsGroup;
    static const char* verticalMaxAltitudeName;
    static const char* verticalIntervalName;
    static const char* verticalHoldTimeName;

private slots:
    void _polylineDirtyChanged          (bool dirty);
    void _rebuildVerticalFlightPolygon  (void);
    void _updateWizardMode              (void);

    // Overrides from TransectStyleComplexItem
    void _rebuildTransectsPhase1    (void) final;
    void _recalcCameraShots         (void) final;

private:
    double  _calcTransectSpacing    (void) const;
    int     _calcTransectCount      (void) const;
    void    _saveCommon             (QJsonObject& complexObject);
    bool    _loadWorker              (const QJsonObject& complexObject, int sequenceNumber, QString& errorString, bool forPresets);

    QGCMapPolyline                  _verticalPolyline;
    QList<QList<QGeoCoordinate>>    _transectSegments;      ///< Internal transect segments including grid exit, turnaround and internal camera points

    int                             _entryPoint;

    QMap<QString, FactMetaData*>    _metaDataMap;
    SettingsFact                    _verticalMaxAltitudeFact;
    SettingsFact                    _verticalIntervalFact;
    SettingsFact                    _verticalHoldTimeFact;

    static const char* _jsonEntryPointKey;
};
