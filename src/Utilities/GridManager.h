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

    Q_INVOKABLE void generateGrid(const QGeoCoordinate &baseCoordinate, int rowCount, int colCount, double gridSizeMeters);
    Q_INVOKABLE void deleteGrid();

    QmlObjectListModel* gridData () { return &m_gridData; }

signals:
    void gridDataChanged();

private:
    QmlObjectListModel m_gridData;
};

#endif // GRIDMANAGER_H
