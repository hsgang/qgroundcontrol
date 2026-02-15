import QtQuick
import QtQuick.Controls
import QtLocation
import QtPositioning
import QtQuick.Dialogs
import Qt.labs.animation

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightMap

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

    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property var    _activeVehicleCoordinate:   _activeVehicle ? _activeVehicle.coordinate : QtPositioning.coordinate()
    property var    _settingsManager:           QGroundControl.settingsManager
    property var    _flyViewSettings:           _settingsManager.flyViewSettings
    property var    _flightMapSettings:         _settingsManager.flightMapSettings
    property Fact   _showGridOnMap:             _flyViewSettings.showGridOnMap
    property bool   _isDragging:                false

    function setVisibleRegion(region) {
        // TODO: Is this still necessary with Qt 5.11?
        // This works around a bug on Qt where if you set a visibleRegion and then the user moves or zooms the map
        // and then you set the same visibleRegion the map will not move/scale appropriately since it thinks there
        // is nothing to do.
        let maxZoomLevel = 20
        _map.visibleRegion = QtPositioning.rectangle(QtPositioning.coordinate(0, 0), QtPositioning.coordinate(0, 0))
        _map.visibleRegion = region
        if (_map.zoomLevel > maxZoomLevel) {
            _map.zoomLevel = maxZoomLevel
        }
    }

    function _possiblyCenterToVehiclePosition() {
        if (!firstVehiclePositionReceived && allowVehicleLocationCenter && _activeVehicleCoordinate.isValid) {
            firstVehiclePositionReceived = true
            center = _activeVehicleCoordinate
            zoomLevel = QGroundControl.flightMapInitialZoom
        }
    }

    function centerToSpecifiedLocation() {
        specifyMapPositionDialogFactory.open()
    }

    QGCPopupDialogFactory {
        id: specifyMapPositionDialogFactory

        dialogComponent: specifyMapPositionDialog
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
    signal mapRightClicked(var position)
    signal mapPressAndHold(var position)

    PinchHandler {
        id:     pinchHandler
        target: null
        //grabPermissions:    PointerHandler.TakeOverForbidden

        property var pinchStartCentroid

        onActiveChanged: {
            if (active) {
                pinchStartCentroid = _map.toCoordinate(pinchHandler.centroid.position, false)
            }
        }
        onScaleChanged: (delta) => {
            let newZoomLevel = Math.max(_map.zoomLevel + Math.log2(delta), 0)
            _map.zoomLevel = newZoomLevel
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
        id: multiTouchArea
        anchors.fill: parent
        maximumTouchPoints: 1
        mouseEnabled: true

        property bool dragActive: false
        property real lastMouseX
        property real lastMouseY
        property bool isPressed: false
        property bool pressAndHold: false

        onPressed: (touchPoints) => {
            lastMouseX = touchPoints[0].x
            lastMouseY = touchPoints[0].y
            isPressed = true
            pressAndHold = false
            pressAndHoldTimer.start()
        }

        onGestureStarted: (gesture) => {
            dragActive = true
            gesture.grab()
            _isDragging = true
            mapPanStart()
        }

        onUpdated: (touchPoints) => {
            if (dragActive) {
                let deltaX = touchPoints[0].x - lastMouseX
                let deltaY = touchPoints[0].y - lastMouseY
                if (Math.abs(deltaX) >= 2.0 || Math.abs(deltaY) >= 2.0) {
                    _map.pan(lastMouseX - touchPoints[0].x, lastMouseY - touchPoints[0].y)
                    lastMouseX = touchPoints[0].x
                    lastMouseY = touchPoints[0].y
                }
            }
        }

        onReleased: (touchPoints) => {
            isPressed = false
            pressAndHoldTimer.stop()
            if (dragActive) {
                _map.pan(lastMouseX - touchPoints[0].x, lastMouseY - touchPoints[0].y)
                dragActive = false
                _isDragging = false
                mapPanStop()
            } else if (!pressAndHold) {
                mapClicked(Qt.point(touchPoints[0].x, touchPoints[0].y))
            }
            pressAndHold = false
        }

        Timer {
            id: pressAndHoldTimer
            interval: 600        // hold duration in ms
            repeat: false

            onTriggered: {
                if (multiTouchArea.isPressed && !multiTouchArea.dragActive) {
                    multiTouchArea.pressAndHold = true
                    mapPressAndHold(Qt.point(multiTouchArea.lastMouseX, multiTouchArea.lastMouseY))
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        propagateComposedEvents: true

        onPressed: (mouseEvent) => {
            if (mouseEvent.button === Qt.RightButton) {
                mapRightClicked(Qt.point(mouseEvent.x, mouseEvent.y))
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

    Timer {
        id: gridRepaintTimer
        interval: 100
        repeat: false
        onTriggered: gridCanvas.requestPaint()
    }

    Canvas {
        id: gridCanvas
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Threaded
        anchors.fill: parent
        visible: (_showGridOnMap.rawValue === true) && _map.zoomLevel > 16 && !_isDragging

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
            function onCenterChanged() {
                if (!_isDragging) {
                    gridRepaintTimer.restart()
                }
            }
            function onZoomLevelChanged() { gridRepaintTimer.restart() }
        }

        onVisibleChanged: {
            if (visible) {
                gridRepaintTimer.restart()
            }
        }
    }

    // KML Overlay initialization
    Component.onCompleted: {
        if (_flightMapSettings.kmlOverlayFile.rawValue !== "") {
            QGroundControl.kmlOverlayManager.loadKML(_flightMapSettings.kmlOverlayFile.rawValue)
        }
    }

    Connections {
        target: _flightMapSettings.kmlOverlayFile
        function onRawValueChanged() {
            if (_flightMapSettings.kmlOverlayFile.rawValue !== "") {
                QGroundControl.kmlOverlayManager.loadKML(_flightMapSettings.kmlOverlayFile.rawValue)
            } else {
                QGroundControl.kmlOverlayManager.clearAll()
            }
        }
    }

    // KML Overlay Polylines
    MapItemView {
        model: QGroundControl.kmlOverlayManager.polylines

        delegate: MapPolyline {
            path: modelData.path
            line.width: {
                var zoom = _map.zoomLevel
                if (zoom >= 18) return 5
                if (zoom >= 16) return 4
                if (zoom >= 14) return 3
                if (zoom >= 12) return 2
                return 1
            }
            line.color: "white"
            z: QGroundControl.zOrderMapItems
            opacity: 0.5
        }
    }

    // KML Overlay Polygons
    MapItemView {
        model: QGroundControl.kmlOverlayManager.polygons

        delegate: MapPolygon {
            path: modelData.path
            color: "transparent"
            border.color: Qt.rgba(0, 1, 0, 0.5)
            border.width: 2
            z: QGroundControl.zOrderMapItems
        }
    }

    // KML Labels
    MapItemView {
        model: QGroundControl.kmlOverlayManager.labels

        delegate: MapQuickItem {
            coordinate: modelData.coordinate
            anchorPoint.x: labelBackground.width / 2
            anchorPoint.y: labelBackground.height / 2
            z: QGroundControl.zOrderMapItems + 20

            sourceItem: Rectangle {
                id: labelBackground
                width: labelText.width + (ScreenTools.defaultFontPixelHeight / 4)
                height: labelText.height + (ScreenTools.defaultFontPixelHeight / 4)
                color: Qt.rgba(0, 0, 0, 0.5)
                border.width: 1
                border.color: "white"
                radius: ScreenTools.defaultFontPixelHeight / 4

                QGCLabel {
                    id: labelText
                    anchors.centerIn: parent
                    text: modelData.text
                    color: "white"
                }
            }
        }
    }
} // Map
