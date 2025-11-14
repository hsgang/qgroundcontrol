/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "KMLOverlayManager.h"
#include "QGCMapPolygon.h"
#include "QGCMapPolyline.h"
#include "ShapeFileHelper.h"

#include <QtCore/QDebug>
#include <QtCore/QFile>
#include <QtCore/QRegularExpression>
#include <QtXml/QDomDocument>

KMLOverlayManager::KMLOverlayManager(QObject* parent)
    : QObject(parent)
{
}

KMLOverlayManager::~KMLOverlayManager()
{
}

bool KMLOverlayManager::loadKML(const QString& filePath)
{
    if (filePath.isEmpty()) {
        return false;
    }

    _currentFilePath = filePath;

    // Clear existing overlays
    clearAll();

    // Load all geometry types from KML/SHP file
    bool hasGeometry = false;

    if (filePath.endsWith(".kml", Qt::CaseInsensitive)) {
        // For KML files, load all geometry types
        hasGeometry |= loadPolylines(filePath);
        hasGeometry |= loadPolygons(filePath);
        hasGeometry |= loadLabels(filePath);
    } else {
        // For SHP files, use ShapeFileHelper to determine type
        QString errorString;
        ShapeFileHelper::ShapeType shapeType = ShapeFileHelper::determineShapeType(filePath, errorString);

        if (!errorString.isEmpty()) {
            qDebug() << "KMLOverlay: Error determining shape type:" << errorString;
            return false;
        }

        switch (shapeType) {
        case ShapeFileHelper::ShapeType::Polygon:
            hasGeometry = loadPolygons(filePath);
            break;
        case ShapeFileHelper::ShapeType::Polyline:
            hasGeometry = loadPolylines(filePath);
            break;
        case ShapeFileHelper::ShapeType::Error:
        default:
            qDebug() << "KMLOverlay: Unable to determine shape type";
            break;
        }
    }

    return hasGeometry;
}

bool KMLOverlayManager::loadPolygons(const QString& filePath)
{
    if (filePath.endsWith(".kml", Qt::CaseInsensitive)) {
        // Parse KML file to find all Polygon elements
        QFile file(filePath);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            qDebug() << "KMLOverlayManager: Failed to open file:" << filePath;
            return false;
        }

        QDomDocument doc;
        QByteArray xmlData = file.readAll();
        file.close();

        auto parseResult = doc.setContent(xmlData);
        if (!parseResult) {
            qDebug() << "KMLOverlayManager: XML parsing error:" << parseResult.errorMessage;
            return false;
        }

        _polygons.clear();
        int polygonCount = 0;

        // Find all Polygon elements
        QDomNodeList placemarks = doc.elementsByTagName("Placemark");
        for (int i = 0; i < placemarks.count(); i++) {
            QDomElement placemark = placemarks.item(i).toElement();
            QDomElement polygon = placemark.firstChildElement("Polygon");

            if (polygon.isNull()) {
                continue;
            }

            // Parse outer boundary
            QDomElement outerBoundary = polygon.firstChildElement("outerBoundaryIs");
            if (outerBoundary.isNull()) {
                continue;
            }

            QDomElement linearRing = outerBoundary.firstChildElement("LinearRing");
            if (linearRing.isNull()) {
                continue;
            }

            QDomElement coordinates = linearRing.firstChildElement("coordinates");
            if (coordinates.isNull()) {
                continue;
            }

            // Parse coordinates
            QVariantList path;
            QString coordText = coordinates.text().simplified();
            QStringList coordPairs = coordText.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);

            for (const QString& pair : coordPairs) {
                QStringList parts = pair.split(",");
                if (parts.count() >= 2) {
                    bool lonOk, latOk;
                    double longitude = parts[0].toDouble(&lonOk);
                    double latitude = parts[1].toDouble(&latOk);

                    if (lonOk && latOk) {
                        QGeoCoordinate coord(latitude, longitude);
                        if (coord.isValid()) {
                            path.append(QVariant::fromValue(coord));
                        }
                    }
                }
            }

            if (!path.isEmpty()) {
                QVariantMap polygonData;
                polygonData["path"] = path;
                _polygons.append(polygonData);
                polygonCount++;
            }
        }

        if (polygonCount > 0) {
            qDebug() << "KMLOverlayManager: Successfully loaded" << polygonCount << "polygons";
            emit polygonsChanged();
            return true;
        }

        return false;
    } else {
        // For SHP files, use existing QGCMapPolygon loader
        QGCMapPolygon polygon(this);
        if (!polygon.loadKMLOrSHPFile(filePath)) {
            return false;
        }

        if (polygon.count() > 0) {
            QVariantMap polygonData;
            polygonData["path"] = polygon.path();
            _polygons.append(polygonData);
            qDebug() << "KMLOverlayManager: Successfully loaded polygon with" << polygon.count() << "vertices";
            emit polygonsChanged();
            return true;
        }
    }

    return false;
}

bool KMLOverlayManager::loadPolylines(const QString& filePath)
{
    if (filePath.endsWith(".kml", Qt::CaseInsensitive)) {
        // Parse KML file to find all LineString elements
        QFile file(filePath);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            qDebug() << "KMLOverlayManager: Failed to open file:" << filePath;
            return false;
        }

        QDomDocument doc;
        QByteArray xmlData = file.readAll();
        file.close();

        auto parseResult = doc.setContent(xmlData);
        if (!parseResult) {
            qDebug() << "KMLOverlayManager: XML parsing error:" << parseResult.errorMessage;
            return false;
        }

        _polylines.clear();
        int polylineCount = 0;

        // Find all LineString elements
        QDomNodeList placemarks = doc.elementsByTagName("Placemark");
        for (int i = 0; i < placemarks.count(); i++) {
            QDomElement placemark = placemarks.item(i).toElement();
            QDomElement lineString = placemark.firstChildElement("LineString");

            if (lineString.isNull()) {
                continue;
            }

            QDomElement coordinates = lineString.firstChildElement("coordinates");
            if (coordinates.isNull()) {
                continue;
            }

            // Parse coordinates
            QVariantList path;
            QString coordText = coordinates.text().simplified();
            QStringList coordPairs = coordText.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);

            for (const QString& pair : coordPairs) {
                QStringList parts = pair.split(",");
                if (parts.count() >= 2) {
                    bool lonOk, latOk;
                    double longitude = parts[0].toDouble(&lonOk);
                    double latitude = parts[1].toDouble(&latOk);

                    if (lonOk && latOk) {
                        QGeoCoordinate coord(latitude, longitude);
                        if (coord.isValid()) {
                            path.append(QVariant::fromValue(coord));
                        }
                    }
                }
            }

            if (!path.isEmpty()) {
                QVariantMap polylineData;
                polylineData["path"] = path;
                _polylines.append(polylineData);
                polylineCount++;
            }
        }

        if (polylineCount > 0) {
            qDebug() << "KMLOverlayManager: Successfully loaded" << polylineCount << "polylines";
            emit polylinesChanged();
            return true;
        }

        return false;
    } else {
        // For SHP files, use existing QGCMapPolyline loader
        QGCMapPolyline polyline(this);
        if (!polyline.loadKMLOrSHPFile(filePath)) {
            return false;
        }

        if (polyline.count() > 0) {
            QVariantMap polylineData;
            polylineData["path"] = polyline.path();
            _polylines.append(polylineData);
            qDebug() << "KMLOverlayManager: Successfully loaded polyline with" << polyline.count() << "vertices";
            emit polylinesChanged();
            return true;
        }
    }

    return false;
}

bool KMLOverlayManager::loadLabels(const QString& filePath)
{
    // Only support KML files for labels
    if (!filePath.endsWith(".kml", Qt::CaseInsensitive)) {
        return false;
    }

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qDebug() << "KMLOverlayManager: Failed to open file for label loading:" << filePath;
        return false;
    }

    QDomDocument doc;
    QByteArray xmlData = file.readAll();
    file.close();

    auto parseResult = doc.setContent(xmlData);
    if (!parseResult) {
        qDebug() << "KMLOverlayManager: XML parsing error:" << parseResult.errorMessage
                 << "at line" << parseResult.errorLine << "column" << parseResult.errorColumn;
        return false;
    }

    _labels.clear();
    int labelCount = 0;

    // Find all Placemark elements with Point geometry
    QDomNodeList placemarks = doc.elementsByTagName("Placemark");

    for (int i = 0; i < placemarks.count(); i++) {
        QDomElement placemark = placemarks.item(i).toElement();

        // Check if this Placemark has a Point (not LineString or Polygon)
        QDomElement point = placemark.firstChildElement("Point");
        if (point.isNull()) {
            continue;
        }

        // Get the name
        QDomElement nameElement = placemark.firstChildElement("name");
        if (nameElement.isNull()) {
            continue;
        }
        QString name = nameElement.text().trimmed();
        if (name.isEmpty()) {
            continue;
        }

        // Get coordinates
        QDomElement coordinatesElement = point.firstChildElement("coordinates");
        if (coordinatesElement.isNull()) {
            continue;
        }

        QString coordText = coordinatesElement.text().simplified();
        QStringList coordParts = coordText.split(",");
        if (coordParts.count() < 2) {
            continue;
        }

        bool lonOk, latOk;
        double longitude = coordParts[0].toDouble(&lonOk);
        double latitude = coordParts[1].toDouble(&latOk);

        if (!lonOk || !latOk) {
            continue;
        }

        QGeoCoordinate coord(latitude, longitude);
        if (!coord.isValid()) {
            continue;
        }

        // Create label data as QVariantMap
        QVariantMap label;
        label["coordinate"] = QVariant::fromValue(coord);
        label["text"] = name;

        _labels.append(label);
        labelCount++;
    }

    if (labelCount > 0) {
        qDebug() << "KMLOverlayManager: Successfully loaded" << labelCount << "labels";
        emit labelsChanged();
        return true;
    }

    return false;
}

void KMLOverlayManager::clearAll()
{
    _polylines.clear();
    _polygons.clear();
    _labels.clear();
    _currentFilePath.clear();

    emit polylinesChanged();
    emit polygonsChanged();
    emit labelsChanged();
}

void KMLOverlayManager::reload()
{
    if (!_currentFilePath.isEmpty()) {
        loadKML(_currentFilePath);
    }
}
