#include "QGCApplication.h"
#include "GridManager.h"
#include "GridSettings.h"
#include "SettingsManager.h"
#include "QGCLoggingCategory.h"
#include "QGCQGeoCoordinate.h"

#include <QtQml/qqml.h>
#include <QtMath>

QGC_LOGGING_CATEGORY(GridManagerLog, "GridManagerLog")

Q_APPLICATION_STATIC(GridManager, _gridManagerInstance);

GridManager::GridManager(QObject *parent)
    : QObject(parent)
{
}

GridManager::~GridManager()
{
}

GridManager *GridManager::instance()
{
    return _gridManagerInstance();
}

void GridManager::registerQmlTypes()
{
    (void) qmlRegisterUncreatableType<GridManager>("QGroundControl", 1, 0, "GridManager", "Reference only");
}

void GridManager::init()
{
    // QString apiKey = CloudSettings().firebaseAPIKey()->rawValueString();
    // this->setAPIKey(apiKey);
    // qDebug() << "gridManager init";
}

void GridManager::generateGrid(const QGeoCoordinate &baseCoordinate, int rowCount, int colCount, double gridSizeMeters) {

    //qDebug() << baseCoordinate << rowCount << colCount << gridSizeMeters;

    m_gridData.clear();

    double latOffset = gridSizeMeters / 111320.0; // 위도 1도 ≈ 111.32km
    double lonOffset = gridSizeMeters / (111320.0 * qCos(qDegreesToRadians(baseCoordinate.latitude())));

    for (int row = 0; row < rowCount; ++row) {
        for (int col = 0; col < colCount; ++col) {
            QGeoCoordinate gridCoord(
                baseCoordinate.latitude() - row * latOffset,
                baseCoordinate.longitude() + col * lonOffset
                );
            // QVariantMap gridItem;
            // gridItem["latitude"] = gridCoord.latitude();
            // gridItem["longitude"] = gridCoord.longitude();
            //qDebug() << gridItem;
            m_gridData.append(new QGCQGeoCoordinate(gridCoord, this));
        }
    }

    emit gridDataChanged();
}

void GridManager::deleteGrid() {
    m_gridData.clearAndDeleteContents();

    emit gridDataChanged();

    //qDebug() << "gridData Cleared";
}


