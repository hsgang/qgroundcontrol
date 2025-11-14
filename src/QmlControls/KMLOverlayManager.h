/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QtCore/QObject>
#include <QtCore/QVariantList>
#include <QtCore/QVariantMap>
#include <QtPositioning/QGeoCoordinate>
#include <QtQml/QQmlEngine>

/// KML/SHP overlay manager for FlightMap
/// Manages loading and displaying KML/SHP files on the map
class KMLOverlayManager : public QObject
{
    Q_OBJECT
    QML_UNCREATABLE("")

    Q_PROPERTY(QVariantList polylines READ polylines NOTIFY polylinesChanged)
    Q_PROPERTY(QVariantList polygons READ polygons NOTIFY polygonsChanged)
    Q_PROPERTY(QVariantList labels READ labels NOTIFY labelsChanged)

public:
    explicit KMLOverlayManager(QObject* parent = nullptr);
    ~KMLOverlayManager() override;

    // Property getters
    QVariantList polylines() const { return _polylines; }
    QVariantList polygons() const { return _polygons; }
    QVariantList labels() const { return _labels; }

    /// Load KML/SHP file and display on map
    /// @param filePath Path to KML or SHP file
    /// @return true if loaded successfully
    Q_INVOKABLE bool loadKML(const QString& filePath);

    /// Clear all overlay items from map
    Q_INVOKABLE void clearAll();

    /// Reload current file (useful after settings change)
    Q_INVOKABLE void reload();

signals:
    void polylinesChanged();
    void polygonsChanged();
    void labelsChanged();

private:
    bool loadPolygons(const QString& filePath);
    bool loadPolylines(const QString& filePath);
    bool loadLabels(const QString& filePath);

    QVariantList _polylines;   // List of polyline objects, each with {path: [...]}
    QVariantList _polygons;    // List of polygon objects, each with {path: [...]}
    QVariantList _labels;      // List of label objects, each with {coordinate: ..., text: "..."}
    QString _currentFilePath;
};
