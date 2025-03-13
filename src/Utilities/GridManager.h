#ifndef GRIDMANAGER_H
#define GRIDMANAGER_H

#include <QObject>
#include <QtCore/QLoggingCategory>
#include <QVariant>
#include <QtPositioning/QGeoCoordinate>

#include "QmlObjectListModel.h"

Q_DECLARE_LOGGING_CATEGORY(GridManagerLog)

class GridManager : public QObject
{
    Q_OBJECT

public:
    GridManager     (QObject *parent = nullptr);
    ~GridManager    ();

    static GridManager *instance();
    static void registerQmlTypes();

    void init();

    Q_PROPERTY(QmlObjectListModel* gridData READ gridData NOTIFY gridDataChanged)
    Q_PROPERTY(bool showAdjustMarker READ showAdjustMarker NOTIFY showAdjustMarkerChanged)

    Q_INVOKABLE void generateGrid(const QGeoCoordinate &baseCoordinate, int rowCount, int colCount, double gridSizeMeters);
    Q_INVOKABLE void deleteGrid();
    Q_INVOKABLE void toggleAdjustMarker();  // 상태 전환 메소드 추가

    QmlObjectListModel* gridData () { return &m_gridData; }
    bool showAdjustMarker() const { return m_showAdjustMarker; }

signals:
    void gridDataChanged();
    void showAdjustMarkerChanged(); // 상태 변경 시 알림

private:
    QmlObjectListModel m_gridData;
    bool m_showAdjustMarker { false }; // 초기 상태 설정
};

#endif // GRIDMANAGER_H
