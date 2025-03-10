/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtLocation
import QtPositioning
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.Controls
import QGroundControl.FlightMap
import QGroundControl.ScreenTools
import QGroundControl.MultiVehicleManager
import QGroundControl.Vehicle
import QGroundControl.QGCPositionManager

Map {
    id: _map

    plugin:     Plugin { name: "QGroundControl" }
    opacity:    0.99 // https://bugreports.qt.io/browse/QTBUG-82185

    property string mapName:                        'defaultMap'
    property bool   isSatelliteMap:                 activeMapType.name.indexOf("Satellite") > -1 || activeMapType.name.indexOf("Hybrid") > -1
    property var    gcsPosition:                    QGroundControl.qgcPositionManger.gcsPosition
    property real   gcsHeading:                     QGroundControl.qgcPositionManger.gcsHeading
    property bool   allowGCSLocationCenter:         false   ///< true: map will center/zoom to gcs location one time
    property bool   allowVehicleLocationCenter:     false   ///< true: map will center/zoom to vehicle location one time
    property bool   firstGCSPositionReceived:       false   ///< true: first gcs position update was responded to
    property bool   firstVehiclePositionReceived:   false   ///< true: first vehicle position update was responded to
    property bool   planView:                       false   ///< true: map being using for Plan view, items should be draggable

    readonly property real  maxZoomLevel: 20

    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property var    _activeVehicleCoordinate:   _activeVehicle ? _activeVehicle.coordinate : QtPositioning.coordinate()
    property var    _settingsManager:           QGroundControl.settingsManager
    property var    _flyViewSettings:           _settingsManager.flyViewSettings
    property Fact   _showGridOnMap:             _flyViewSettings.showGridOnMap

    function setVisibleRegion(region) {
        // TODO: Is this still necessary with Qt 5.11?
        // This works around a bug on Qt where if you set a visibleRegion and then the user moves or zooms the map
        // and then you set the same visibleRegion the map will not move/scale appropriately since it thinks there
        // is nothing to do.
        _map.visibleRegion = QtPositioning.rectangle(QtPositioning.coordinate(0, 0), QtPositioning.coordinate(0, 0))
        _map.visibleRegion = region
    }

    function _possiblyCenterToVehiclePosition() {
        if (!firstVehiclePositionReceived && allowVehicleLocationCenter && _activeVehicleCoordinate.isValid) {
            firstVehiclePositionReceived = true
            center = _activeVehicleCoordinate
            zoomLevel = QGroundControl.flightMapInitialZoom
        }
    }

    function centerToSpecifiedLocation() {
        specifyMapPositionDialog.createObject(mainWindow).open()
    }

    Component {
        id: specifyMapPositionDialog
        EditPositionDialog {
            title:                  qsTr("Specify Position")
            coordinate:             center
            onCoordinateChanged:    center = coordinate
        }
    }

    // Center map to gcs location
    onGcsPositionChanged: {
        if (gcsPosition.isValid && allowGCSLocationCenter && !firstGCSPositionReceived && !firstVehiclePositionReceived) {
            firstGCSPositionReceived = true
            //-- Only center on gsc if we have no vehicle (and we are supposed to do so)
            var _activeVehicleCoordinate = _activeVehicle ? _activeVehicle.coordinate : QtPositioning.coordinate()
            if(QGroundControl.settingsManager.flyViewSettings.keepMapCenteredOnVehicle.rawValue || !_activeVehicleCoordinate.isValid)
                center = gcsPosition
        }
    }

    function updateActiveMapType() {
        var settings =  QGroundControl.settingsManager.flightMapSettings
        var fullMapName = settings.mapProvider.value + " " + settings.mapType.value

        for (var i = 0; i < _map.supportedMapTypes.length; i++) {
            if (fullMapName === _map.supportedMapTypes[i].name) {
                _map.activeMapType = _map.supportedMapTypes[i]
                return
            }
        }
    }

    on_ActiveVehicleCoordinateChanged: _possiblyCenterToVehiclePosition()

    onMapReadyChanged: {
        if (_map.mapReady) {
            updateActiveMapType()
            _possiblyCenterToVehiclePosition()
        }
    }

    Connections {
        target: QGroundControl.settingsManager.flightMapSettings.mapType
        function onRawValueChanged() { updateActiveMapType() }
    }

    Connections {
        target: QGroundControl.settingsManager.flightMapSettings.mapProvider
        function onRawValueChanged() { updateActiveMapType() }
    }

    signal mapPanStart
    signal mapPanStop
    signal mapClicked(var position)
    
    PinchHandler {
        id:     pinchHandler
        target: null
        grabPermissions:    PointerHandler.TakeOverForbidden

        property var pinchStartCentroid

        onActiveChanged: {
            if (active) {
                pinchStartCentroid = _map.toCoordinate(pinchHandler.centroid.position, false)
            }
        }
        onScaleChanged: (delta) => {
            _map.zoomLevel += Math.log2(delta)
            _map.alignCoordinateToPoint(pinchStartCentroid, pinchHandler.centroid.position)
        }
    }

    WheelHandler {
        // workaround for QTBUG-87646 / QTBUG-112394 / QTBUG-112432:
        // Magic Mouse pretends to be a trackpad but doesn't work with PinchHandler
        // and we don't yet distinguish mice and trackpads on Wayland either
        acceptedDevices:    Qt.platform.pluginName === "cocoa" || Qt.platform.pluginName === "wayland" ?
                                PointerDevice.Mouse | PointerDevice.TouchPad : PointerDevice.Mouse
        rotationScale:      1 / 120
        property:           "zoomLevel"
    }

    // We specifically do not use a DragHandler for panning. It just causes too many problems if you overlay anything else like a Flickable above it.
    // Causes all sorts of crazy problems where dragging/scrolling  no longerr works on items above in the hierarchy.
    // Since we are using a MouseArea we also can't use TapHandler for clicks. So we handle that here as well.
    MultiPointTouchArea {
        anchors.fill: parent
        maximumTouchPoints: 1
        mouseEnabled: true

        property bool dragActive: false
        property real lastMouseX
        property real lastMouseY

        onPressed: (touchPoints) => {
            //console.log("onPressed", touchPoints[0].x, touchPoints[0].y)
            lastMouseX = touchPoints[0].x
            lastMouseY = touchPoints[0].y
        }

        onGestureStarted: (gesture) => {
            dragActive = true
            gesture.grab()
            mapPanStart()
        }

        onUpdated: (touchPoints) => {
            //console.log("onUpdated", touchPoints[0].x, touchPoints[0].y, lastMouseX, lastMouseY)
            if (dragActive) {
                let deltaX = touchPoints[0].x - lastMouseX
                let deltaY = touchPoints[0].y - lastMouseY
                if (Math.abs(deltaX) >= 1.0 || Math.abs(deltaY) >= 1.0) {
                    _map.pan(lastMouseX - touchPoints[0].x, lastMouseY - touchPoints[0].y)
                    lastMouseX = touchPoints[0].x
                    lastMouseY = touchPoints[0].y
                }
            }
        }

        onReleased: (touchPoints) => {
            if (dragActive) {
                _map.pan(lastMouseX - touchPoints[0].x, lastMouseY - touchPoints[0].y)
                dragActive = false
                mapPanStop()
            } else {
                mapClicked(Qt.point(touchPoints[0].x, touchPoints[0].y))
            }
        }
    }

    /// Ground Station location
    MapQuickItem {
        anchorPoint.x:  sourceItem.width / 2
        anchorPoint.y:  sourceItem.height / 2
        visible:        gcsPosition.isValid
        coordinate:     gcsPosition

        sourceItem: Rectangle {
            id:         homeMarker
            height:     ScreenTools.defaultFontPixelHeight * 1.4
            width:      height
            radius:     width * 0.5
            color:      qgcPal.alertBackground //"transparent"
            border.color: "white" //qgcPal.alertBackground
            border.width: 1

            QGCLabel {
                text:               "GCS"
                font.pointSize:     parent.height * 0.25
                font.bold:          true
                //color:              qgcPal.alertBackground
                anchors.centerIn:   parent
            }

            transform: Rotation {
                origin.x:       homeMarker.width  / 2
                origin.y:       homeMarker.height / 2
                angle:          isNaN(gcsHeading) ? 0 : gcsHeading
            }
        }
    }

    function calculateMetersPerPixel(zoomLevel, latitude) {
        var earthCircumference = 40075017; // 지구 둘레 (m)
        var latitudeRadians = latitude * Math.PI / 180;
        var metersPerPixel = earthCircumference * Math.cos(latitudeRadians) / Math.pow(2, zoomLevel + 8);
        return metersPerPixel;
    }

    Canvas {
        id: gridCanvas
        renderTarget: Canvas.FramebufferObject
        anchors.fill: parent
        visible:      (_showGridOnMap.rawValue === true) && _map.zoomLevel > 16;

        onPaint: {
            if(_map.zoomLevel > 16) {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                var stepMeters = 100; // 500m 간격
                var centerCoord = _map.center;

                var topLeft = _map.toCoordinate(Qt.point(0, 0));
                var bottomRight = _map.toCoordinate(Qt.point(width, height));

                // 경도 및 위도를 일정 간격으로 정렬
                var stepDegreesLon = (stepMeters / (111320 * Math.cos(Math.floor(centerCoord.latitude) * Math.PI / 180))); // 경도 간격 계산
                var stepDegreesLat = (stepMeters / 111320); // 1° 위도 ≈ 111,320km

                var startLon = Math.floor(topLeft.longitude / stepDegreesLon) * stepDegreesLon;
                var startLat = Math.floor(topLeft.latitude / stepDegreesLat) * stepDegreesLat;

                // 세로선 (경도 기준)
                var lon = startLon;
                while (lon < bottomRight.longitude) {
                    var x = _map.fromCoordinate(QtPositioning.coordinate(centerCoord.latitude, lon)).x;
                    ctx.beginPath();
                    ctx.moveTo(x, 0);
                    ctx.lineTo(x, height);
                    ctx.strokeStyle = "rgba(255, 255, 255, 0.4)"; // 흰색 반투명
                    ctx.lineWidth = 1;
                    ctx.stroke();
                    lon += stepDegreesLon;
                }

                // 가로선 (위도 기준)
                var lat = startLat;
                while (lat > bottomRight.latitude) {
                    var y = _map.fromCoordinate(QtPositioning.coordinate(lat, centerCoord.longitude)).y;
                    ctx.beginPath();
                    ctx.moveTo(0, y);
                    ctx.lineTo(width, y);
                    ctx.strokeStyle = "rgba(255, 255, 255, 0.4)"; // 흰색 반투명
                    ctx.lineWidth = 1;
                    ctx.stroke();
                    lat -= stepDegreesLat;
                }
            }
        }

        Connections {
            target: _map
            onCenterChanged: gridCanvas.requestPaint();
            onZoomLevelChanged: gridCanvas.requestPaint();
        }
    }
} // Map
