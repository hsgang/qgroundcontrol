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
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controllers
import QGroundControl.Controls
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.Vehicle

FlightMap {
    id:                         _root
    allowGCSLocationCenter:     true
    allowVehicleLocationCenter: !_keepVehicleCentered
    planView:                   false
    zoomLevel:                  QGroundControl.flightMapZoom
    center:                     QGroundControl.flightMapPosition

    property Item   pipView
    property Item   pipState:                   _pipState
    property var    rightPanelWidth
    property var    planMasterController
    property bool   pipMode:                    false   // true: map is shown in a small pip mode
    property var    toolInsets                          // Insets for the center viewport area

    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property var    _planMasterController:      planMasterController
    property var    _geoFenceController:        planMasterController.geoFenceController
    property var    _rallyPointController:      planMasterController.rallyPointController
    property var    _activeVehicleCoordinate:   _activeVehicle ? _activeVehicle.coordinate : QtPositioning.coordinate()
    property real   _toolButtonTopMargin:       parent.height - mainWindow.height + (ScreenTools.defaultFontPixelHeight / 2)
    property real   _toolsMargin:               ScreenTools.defaultFontPixelWidth * 0.75
    property var    _flyViewSettings:           QGroundControl.settingsManager.flyViewSettings
    property bool   _keepMapCenteredOnVehicle:  _flyViewSettings.keepMapCenteredOnVehicle.rawValue

    property bool   _disableVehicleTracking:    false
    property bool   _keepVehicleCentered:       pipMode ? true : false
    property bool   _saveZoomLevelSetting:      true

    property bool   _vehicleArmed:              _activeVehicle ? _activeVehicle.armed  : false
    property bool   _vehicleFlying:             _activeVehicle ? _activeVehicle.flying  : false

    property var    _gridManager:               QGroundControl.gridManager
    property var    gridData:                   _gridManager.gridData

    function _adjustMapZoomForPipMode() {
        _saveZoomLevelSetting = false
        if (pipMode) {
            if (QGroundControl.flightMapZoom > 3) {
                zoomLevel = QGroundControl.flightMapZoom - 1
            }
        } else {
            zoomLevel = QGroundControl.flightMapZoom
        }
        _saveZoomLevelSetting = true
    }

    onPipModeChanged: _adjustMapZoomForPipMode()

    onVisibleChanged: {
        if (visible) {
            // Synchronize center position with Plan View
            center = QGroundControl.flightMapPosition
        }
    }

    onZoomLevelChanged: {
        if (_saveZoomLevelSetting) {
            QGroundControl.flightMapZoom = _root.zoomLevel
        }
    }
    onCenterChanged: {
        QGroundControl.flightMapPosition = _root.center
    }

    // We track whether the user has panned or not to correctly handle automatic map positioning
    onMapPanStart:  _disableVehicleTracking = true
    onMapPanStop:   panRecenterTimer.restart()

    function pointInRect(point, rect) {
        return point.x > rect.x &&
                point.x < rect.x + rect.width &&
                point.y > rect.y &&
                point.y < rect.y + rect.height;
    }

    property real _animatedLatitudeStart
    property real _animatedLatitudeStop
    property real _animatedLongitudeStart
    property real _animatedLongitudeStop
    property real animatedLatitude
    property real animatedLongitude

    onAnimatedLatitudeChanged: _root.center = QtPositioning.coordinate(animatedLatitude, animatedLongitude)
    onAnimatedLongitudeChanged: _root.center = QtPositioning.coordinate(animatedLatitude, animatedLongitude)

    NumberAnimation on animatedLatitude { id: animateLat; from: _animatedLatitudeStart; to: _animatedLatitudeStop; duration: 1000 }
    NumberAnimation on animatedLongitude { id: animateLong; from: _animatedLongitudeStart; to: _animatedLongitudeStop; duration: 1000 }

    function animatedMapRecenter(fromCoord, toCoord) {
        _animatedLatitudeStart = fromCoord.latitude
        _animatedLongitudeStart = fromCoord.longitude
        _animatedLatitudeStop = toCoord.latitude
        _animatedLongitudeStop = toCoord.longitude
        animateLat.start()
        animateLong.start()
    }

    // returns the rectangle formed by the four center insets
    // used for checking if vehicle is under ui, and as a target for recentering the view
    function _insetCenterRect() {
        return Qt.rect(toolInsets.leftEdgeCenterInset,
                       toolInsets.topEdgeCenterInset,
                       _root.width - toolInsets.leftEdgeCenterInset - toolInsets.rightEdgeCenterInset,
                       _root.height - toolInsets.topEdgeCenterInset - toolInsets.bottomEdgeCenterInset)
    }

    // returns the four rectangles formed by the 8 corner insets
    // used for detecting if the vehicle has flown under the instrument panel, virtual joystick etc
    function _insetCornerRects() {
        var rects = {
        "topleft":      Qt.rect(0,0,
                               toolInsets.leftEdgeTopInset,
                               toolInsets.topEdgeLeftInset),
        "topright":     Qt.rect(_root.width-toolInsets.rightEdgeTopInset,0,
                               toolInsets.rightEdgeTopInset,
                               toolInsets.topEdgeRightInset),
        "bottomleft":   Qt.rect(0,_root.height-toolInsets.bottomEdgeLeftInset,
                               toolInsets.leftEdgeBottomInset,
                               toolInsets.bottomEdgeLeftInset),
        "bottomright":  Qt.rect(_root.width-toolInsets.rightEdgeBottomInset,_root.height-toolInsets.bottomEdgeRightInset,
                               toolInsets.rightEdgeBottomInset,
                               toolInsets.bottomEdgeRightInset)}
        return rects
    }

    function recenterNeeded() {
        var vehiclePoint = _root.fromCoordinate(_activeVehicleCoordinate, false /* clipToViewport */)
        var centerRect = _insetCenterRect()
        //return !pointInRect(vehiclePoint,insetRect)

        // If we are outside the center inset rectangle, recenter
        if(!pointInRect(vehiclePoint, centerRect)){
            return true
        }

        // if we are inside the center inset rectangle
        // then additionally check if we are underneath one of the corner inset rectangles
        var cornerRects = _insetCornerRects()
        if(pointInRect(vehiclePoint, cornerRects["topleft"])){
            return true
        } else if(pointInRect(vehiclePoint, cornerRects["topright"])){
            return true
        } else if(pointInRect(vehiclePoint, cornerRects["bottomleft"])){
            return true
        } else if(pointInRect(vehiclePoint, cornerRects["bottomright"])){
            return true
        }

        // if we are inside the center inset rectangle, and not under any corner elements
        return false
    }

    function updateMapToVehiclePosition() {
        if (animateLat.running || animateLong.running) {
            return
        }
        // We let FlightMap handle first vehicle position
        if (!_keepMapCenteredOnVehicle && firstVehiclePositionReceived && _activeVehicleCoordinate.isValid && !_disableVehicleTracking) {
            if (_keepVehicleCentered) {
                _root.center = _activeVehicleCoordinate
            } else {
                if (firstVehiclePositionReceived && recenterNeeded()) {
                    // Move the map such that the vehicle is centered within the inset area
                    var vehiclePoint = _root.fromCoordinate(_activeVehicleCoordinate, false /* clipToViewport */)
                    var centerInsetRect = _insetCenterRect()
                    var centerInsetPoint = Qt.point(centerInsetRect.x + centerInsetRect.width / 2, centerInsetRect.y + centerInsetRect.height / 2)
                    var centerOffset = Qt.point((_root.width / 2) - centerInsetPoint.x, (_root.height / 2) - centerInsetPoint.y)
                    var vehicleOffsetPoint = Qt.point(vehiclePoint.x + centerOffset.x, vehiclePoint.y + centerOffset.y)
                    var vehicleOffsetCoord = _root.toCoordinate(vehicleOffsetPoint, false /* clipToViewport */)
                    animatedMapRecenter(_root.center, vehicleOffsetCoord)
                }
            }
        }
    }

    on_ActiveVehicleCoordinateChanged: {
        if (_keepMapCenteredOnVehicle && _activeVehicleCoordinate.isValid && !_disableVehicleTracking) {
            _root.center = _activeVehicleCoordinate
        }
    }

    PipState {
        id:         _pipState
        pipView:    _root.pipView
        isDark:     _isFullWindowItemDark
    }

    Timer {
        id:         panRecenterTimer
        interval:   10000
        running:    false
        onTriggered: {
            _disableVehicleTracking = false
            updateMapToVehiclePosition()
        }
    }

    Timer {
        interval:       500
        running:        true
        repeat:         true
        onTriggered:    updateMapToVehiclePosition()
    }

    QGCMapPalette { id: mapPal; lightColors: isSatelliteMap }

    Connections {
        target:                 _missionController
        ignoreUnknownSignals:   true
        function onNewItemsFromVehicle() {
            var visualItems = _missionController.visualItems
            if (visualItems && visualItems.count !== 1) {
                mapFitFunctions.fitMapViewportToMissionItems()
                firstVehiclePositionReceived = true
            }
        }
    }

    MapFitFunctions {
        id:                         mapFitFunctions // The name for this id cannot be changed without breaking references outside of this code. Beware!
        map:                        _root
        usePlannedHomePosition:     false
        planMasterController:       _planMasterController
    }

    // ObstacleDistanceOverlayMap {
    //     id: obstacleDistance
    //     showText: !pipMode
    // }

    // Add the items associated with each vehicles flight plan to the map
    Repeater {
        model: QGroundControl.multiVehicleManager.vehicles

        PlanMapItems {
            map:                    _root
            largeMapView:           !pipMode
            planMasterController:   masterController
            vehicle:                _vehicle

            property var _vehicle: object

            PlanMasterController {
                id: masterController
                Component.onCompleted: startStaticActiveVehicle(object)
            }
        }
    }

    // Add trajectory lines to the map
    MapPolyline {
        id:         trajectoryPolyline
        line.width: 3
        line.color: "#9c1bff"
        z:          QGroundControl.zOrderTrajectoryLines
        visible:    !pipMode

        Connections {
            target:                 QGroundControl.multiVehicleManager
            function onActiveVehicleChanged(activeVehicle) {
                trajectoryPolyline.path = _activeVehicle ? _activeVehicle.trajectoryPoints.list() : []
            }
        }

        Connections {
            target:                             _activeVehicle ? _activeVehicle.trajectoryPoints : null
            function onPointAdded(coordinate) { trajectoryPolyline.addCoordinate(coordinate) }
            function onUpdateLastPoint(coordinate) { trajectoryPolyline.replaceCoordinate(trajectoryPolyline.pathLength() - 1, coordinate) }
            function onPointsCleared() { trajectoryPolyline.path = [] }
        }
    }

    // Add the vehicles to the map
    MapItemView {
        model: QGroundControl.multiVehicleManager.vehicles
        delegate: VehicleMapItem {
            vehicle:        object
            coordinate:     object.coordinate
            map:            _root
            size:           pipMode ? ScreenTools.defaultFontPixelHeight * 2 : ScreenTools.defaultFontPixelHeight * 3
            z:              QGroundControl.zOrderVehicles

            // 좌표 변경 시 처리
            onCoordinateChanged: {
                //console.log("Vehicle 좌표 변경됨:", coordinate.latitude, coordinate.longitude);
                updateGridColor(coordinate.latitude, coordinate.longitude);
            }
        }
    }

    // Add distance sensor view
    MapItemView{
        model: QGroundControl.multiVehicleManager.vehicles
        delegate: ProximityRadarMapView {
            vehicle:        object
            coordinate:     object.coordinate
            map:            _root
            z:              QGroundControl.zOrderVehicles
        }
    }

    // Add ADSB vehicles to the map
    MapItemView {
        model: QGroundControl.adsbVehicleManager.adsbVehicles
        delegate: VehicleMapItem {
            coordinate:     object.coordinate
            altitude:       object.altitude
            callsign:       object.callsign
            heading:        object.heading
            alert:          object.alert
            map:            _root
            size:           pipMode ? ScreenTools.defaultFontPixelHeight : ScreenTools.defaultFontPixelHeight * 2.5
            z:              QGroundControl.zOrderVehicles
        }
    }

    // // CameraProjection to the map
    // MapItemView {
    //     model: QGroundControl.multiVehicleManager.vehicles
    //     delegate: CameraProjectionMapItem {
    //         coordinate:     object.coordinate
    //         map:            _root
    //         visible:        QGroundControl.settingsManager.flyViewSettings.showCameraProjectionOnMap.rawValue && !pipMode
    //         z:              QGroundControl.zOrderWidgets
    //     }
    // }

    // AtmosphericValue to the map
    MapItemView {
        model: QGroundControl.multiVehicleManager.vehicles
        delegate: AtmosphericValueMapItem {
            coordinate:     object.coordinate
            map:            _root
            visible:        QGroundControl.settingsManager.flyViewSettings.showAtmosphericValueBar.rawValue && !pipMode
            z:              QGroundControl.zOrderWidgets
        }
    }

    // VehicleInfo to the map
    MapItemView {
        model: QGroundControl.multiVehicleManager.vehicles
        delegate: VehicleInfoMapItem {
            coordinate:     object.coordinate
            map:            _root
            visible:        QGroundControl.settingsManager.flyViewSettings.showVehicleInfoOnMap.rawValue && !pipMode
            z:              QGroundControl.zOrderWidgets
        }
    }

    // Allow custom builds to add map items
    CustomMapItems {
        map:            _root
        largeMapView:   !pipMode
    }

    GeoFenceMapVisuals {
        map:                    _root
        myGeoFenceController:   _geoFenceController
        interactive:            false
        planView:               false
        homePosition:           _activeVehicle && _activeVehicle.homePosition.isValid ? _activeVehicle.homePosition :  QtPositioning.coordinate()
    }

    // Rally points on map
    MapItemView {
        model: _rallyPointController.points

        delegate: MapQuickItem {
            id:             itemIndicator
            anchorPoint.x:  sourceItem.anchorPointX
            anchorPoint.y:  sourceItem.anchorPointY
            coordinate:     object.coordinate
            z:              QGroundControl.zOrderMapItems

            sourceItem: MissionItemIndexLabel {
                id:         itemIndexLabel
                label:      qsTr("R", "rally point map item label")
            }
        }
    }

    // Camera trigger points
    MapItemView {
        model: _activeVehicle ? _activeVehicle.cameraTriggerPoints : 0

        delegate: CameraTriggerIndicator {
            coordinate:     object.coordinate
            z:              QGroundControl.zOrderTopMost
        }
    }

    // GridManager Viewer

    property int valueSource: QGroundControl.settingsManager.gridSettings.valueSource.rawValue
    property int gridSizeMeters: QGroundControl.settingsManager.gridSettings.gridSize.rawValue // 격자의 크기 (미터 단위)
    property real mapZoomLevel: _root.zoomLevel // Map의 줌 레벨
    property var baseCoordinate: QtPositioning.coordinate(35.1704328, 129.1312456)
    property var selectedGrid: null // 현재 선택된 격자
    property real value1: QGroundControl.settingsManager.gridSettings.value1.rawValue
    property real value2: QGroundControl.settingsManager.gridSettings.value2.rawValue
    property real value3: QGroundControl.settingsManager.gridSettings.value3.rawValue
    property int _rows: QGroundControl.settingsManager.gridSettings.rows.rawValue
    property int _columns: QGroundControl.settingsManager.gridSettings.columns.rawValue

    function valueSouceData() {
        switch ( valueSource ) {
            case 0 : return _activeVehicle.altitudeRelative.rawValue
            case 1 : return _activeVehicle.atmosphericSensor.extValue1.rawValue
            case 2 : return _activeVehicle.atmosphericSensor.extValue2.rawValue
            case 3 : return _activeVehicle.atmosphericSensor.extValue3.rawValue
            case 4 : return _activeVehicle.atmosphericSensor.extValue4.rawValue
            default : return _activeVehicle.altitudeRelative.rawValue
        }
    }

    function calculateGridSize() {
        let scale = Math.pow(2, mapZoomLevel)
        return {
            width: gridSizeMeters * scale / 111320 / 1.2, // 1km 기준으로 축척 계산
            height: gridSizeMeters * scale / 111320 / 1.2
        }
    }

    // 격자 크기 계산 함수
    function gridSizeForLatLng() {
        var latSize = gridSizeMeters / 111320; // 위도 1도에 해당하는 미터 거리
        var lonSize = gridSizeMeters / (111320 * Math.cos(Math.round(Math.PI * baseCoordinate.latitude) / 180)); // 경도는 위도에 따라 달라짐
        return {latSize: latSize, lonSize: lonSize};
    }

    // 마커의 좌표가 변경되었을 때 격자 색상 업데이트
    function updateGridColor(latitude, longitude) {
        //console.log(gridMapItemView.children.length)
        for (let i = 0; i < gridMapItemView.children.length; i++) {
            let grid = gridMapItemView.children[i] //gridMapItemView.itemAt(i)
            if (grid.isInside(latitude, longitude)) {
                if (selectedGrid !== grid) {
                    // // 이전 선택된 격자 색상 초기화
                    // if (selectedGrid !== null) {
                    //     selectedGrid.resetColor()
                    // }
                    // 새로운 격자 선택 및 색상 변경
                    selectedGrid = grid
                    selectedGrid.selectColor()
                }
                return
            }
        }
    }
    
    // GoTo Location forward flight circle visuals
    QGCMapCircleVisuals {
        id:                 fwdFlightGotoMapCircle
        mapControl:         parent
        mapCircle:          _fwdFlightGotoMapCircle
        radiusLabelVisible: true
        visible:            gotoLocationItem.visible && _activeVehicle &&
                            _activeVehicle.inFwdFlight &&
                            !_activeVehicle.orbitActive

        property alias coordinate: _fwdFlightGotoMapCircle.center
        property alias radius: _fwdFlightGotoMapCircle.radius

        Component.onCompleted: {
            // Only allow editing the radius, not the position
            centerDragHandleVisible = false

            globals.guidedControllerFlyView.fwdFlightGotoMapCircle = this
        }

        Binding {
            target: _fwdFlightGotoMapCircle
            property: "center"
            value: gotoLocationItem.coordinate
        }

        function startLoiterRadiusEdit() {
            _fwdFlightGotoMapCircle.interactive = true
        }

        // Called when loiter edit is confirmed
        function actionConfirmed() {
            _fwdFlightGotoMapCircle.interactive = false
            _fwdFlightGotoMapCircle._commitRadius()
        }

        // Called when loiter edit is cancelled
        function actionCancelled() {
            _fwdFlightGotoMapCircle.interactive = false
            _fwdFlightGotoMapCircle._restoreRadius()
        }

        QGCMapCircle {
            id:                 _fwdFlightGotoMapCircle
            interactive:        false
            showRotation:       true
            clockwiseRotation:  true

            property real _defaultLoiterRadius: _flyViewSettings.forwardFlightGoToLocationLoiterRad.value
            property real _committedRadius;

            onCenterChanged: {
                radius.rawValue = _defaultLoiterRadius
                // Don't commit the radius in case this operation is undone
            }

            Component.onCompleted: {
                radius.rawValue = _defaultLoiterRadius
                _commitRadius()
            }

            function _commitRadius() {
                _committedRadius = radius.rawValue
            }

            function _restoreRadius() {
                radius.rawValue = _committedRadius
            }
        }
    }

    MapQuickItem {
        id: gridAdjMarker
        // 아이템의 anchorPoint는 이미지 하단 중앙에 위치시킵니다.
        anchorPoint.x: markerRect.width / 2
        anchorPoint.y: markerRect.height / 2
        coordinate: QtPositioning.coordinate(initLat, initLon)

        visible : QGroundControl.gridManager.showAdjustMarker

        property real initLat: QGroundControl.settingsManager.gridSettings.latitude.rawValue
        property real initLon: QGroundControl.settingsManager.gridSettings.longitude.rawValue

        sourceItem: Rectangle {
            id: markerRect
            width:      calculateGridSize().width
            height:     calculateGridSize().height
            color:      "transparent"
            border.color: qgcPal.colorGreen
            border.width: 3

            MouseArea {
                anchors.fill: parent
                // MapQuickItem 자체를 드래그 대상으로 지정
                drag.target: gridAdjMarker
                drag.axis: Drag.XAndYAxis

                // 드래그 중에는 별도 추가 처리 가능
                onPressed: {
                    // 예: 아이템 강조 효과 등
                }

                onReleased: {
                    // 드래그가 종료된 후, 현재 화면상의 좌표를 지도 좌표로 변환
                    var newCoordinate = _root.toCoordinate(
                        Qt.point(gridAdjMarker.x + gridAdjMarker.anchorPoint.x, gridAdjMarker.y + gridAdjMarker.anchorPoint.y)
                    )
                    // MapQuickItem의 좌표를 갱신
                    gridAdjMarker.coordinate = newCoordinate

                    var _rows = QGroundControl.settingsManager.gridSettings.rows.rawValue
                    var _columns = QGroundControl.settingsManager.gridSettings.columns.rawValue
                    var _gridSize = QGroundControl.settingsManager.gridSettings.gridSize.rawValue

                    QGroundControl.gridManager.generateGrid(QtPositioning.coordinate(newCoordinate.latitude, newCoordinate.longitude),
                                                                _rows,
                                                                _columns,
                                                                _gridSize)

                    QGroundControl.settingsManager.gridSettings.latitude.rawValue = newCoordinate.latitude
                    QGroundControl.settingsManager.gridSettings.longitude.rawValue = newCoordinate.longitude

                    console.log("새로운 좌표:", newCoordinate.latitude, newCoordinate.longitude)
                }
            }
        }
    }

    MapItemView {
        id: gridMapItemView
        model: _gridManager.gridData

        delegate: MapQuickItem {
            coordinate: object.coordinate
            anchorPoint.x:  sourceItem.anchorPointX
            anchorPoint.y:  sourceItem.anchorPointY
            z:          QGroundControl.zOrderMapItems

            property real latMin: coordinate.latitude - ((gridSizeForLatLng().latSize)/2)
            property real latMax: coordinate.latitude + ((gridSizeForLatLng().latSize)/2)
            property real lonMin: coordinate.longitude - ((gridSizeForLatLng().lonSize)/2)
            property real lonMax: coordinate.longitude + ((gridSizeForLatLng().lonSize)/2)

            sourceItem: Rectangle {
                id: gridRect
                width: calculateGridSize().width
                height: calculateGridSize().height
                color: "transparent"
                border.color: Qt.rgba(255, 255, 255, 0.4)
                border.width: 1
                property real anchorPointX: width / 2
                property real anchorPointY: height / 2

                QGCLabel{
                    id: gridLabel
                    anchors.centerIn: parent
                    text: ""
                }
            }

            function selectColor() {
                if(_activeVehicle) {
                    // rawValue 값에 따라 색상을 변경
                    let rawValue = valueSouceData()//_activeVehicle.altitudeRelative.rawValue;

                    if (rawValue <= value1) {
                        gridRect.color = Qt.rgba(0, 255, 0, 0.4);  // Green
                    } else if (rawValue <= value2) {
                        gridRect.color = Qt.rgba(255, 255, 0, 0.4);  // Yellow
                    } else if (rawValue <= value3) {
                        gridRect.color = Qt.rgba(255, 0, 0, 0.4);  // Red
                    } else {
                        gridRect.color = Qt.rgba(128, 0, 128, 0.4);  // Purple for out of range
                    }

                    // 레이블에 rawValue 표시
                    gridLabel.text = valueSouceData().toFixed(2)//_activeVehicle.altitudeRelative.rawValue.toFixed(2)
                }
            }

            // 특정 좌표가 격자 내부에 있는지 확인
            function isInside(latitude, longitude) {
                return latitude >= latMin && latitude <= latMax &&
                       longitude >= lonMin && longitude <= lonMax
            }
        }
    }

    // Camera fov point

    MapQuickItem {
        id:             cameraFovIndicator
        anchorPoint.x:  sourceItem.anchorPointX
        anchorPoint.y:  sourceItem.anchorPointY
        coordinate:     _activeVehicle ? _activeVehicle.cameraFovPosition : QtPositioning.coordinate()
        visible:        _activeVehicle ? _activeVehicle.cameraFovPosition : false

        sourceItem: CameraPOIIndicator {
        }
    }

    // GoTo Location visuals
    MapQuickItem {
        id:             gotoLocationItem
        visible:        false
        z:              QGroundControl.zOrderMapItems
        anchorPoint.x:  sourceItem.anchorPointX
        anchorPoint.y:  sourceItem.anchorPointY
        sourceItem: MissionItemIndexLabel {
            checked:    true
            index:      -1
            label:      qsTr("Go here", "Go to location waypoint")
        }

        property bool inGotoFlightMode: _activeVehicle ? _activeVehicle.flightMode === _activeVehicle.gotoFlightMode : false

        property var _committedCoordinate: null

        onInGotoFlightModeChanged: {
            if (!inGotoFlightMode && gotoLocationItem.visible) {
                // Hide goto indicator when vehicle falls out of guided mode
                hide()
            }
        }

        function show(coord) {
            gotoLocationItem.coordinate = coord
            gotoLocationItem.visible = true
        }

        function hide() {
            gotoLocationItem.visible = false
        }

        function actionConfirmed() {
            _commitCoordinate()

            // Commit the new radius which possibly changed
            fwdFlightGotoMapCircle.actionConfirmed()

            // We leave the indicator visible. The handling for onInGuidedModeChanged will hide it.
        }

        function actionCancelled() {
            _restoreCoordinate()

            // Also restore the loiter radius
            fwdFlightGotoMapCircle.actionCancelled()
        }

        function _commitCoordinate() {
            // Must deep copy
            _committedCoordinate = QtPositioning.coordinate(
                coordinate.latitude,
                coordinate.longitude
            );
        }

        function _restoreCoordinate() {
            if (_committedCoordinate) {
                coordinate = _committedCoordinate
            } else {
                hide()
            }
        }
    }

    // Orbit editing visuals
    QGCMapCircleVisuals {
        id:             orbitMapCircle
        mapControl:     parent
        mapCircle:      _mapCircle
        visible:        false

        property alias center:              _mapCircle.center
        property alias clockwiseRotation:   _mapCircle.clockwiseRotation
        readonly property real defaultRadius: 30

        Connections {
            target: QGroundControl.multiVehicleManager
            function onActiveVehicleChanged(activeVehicle) {
                if (!activeVehicle) {
                    orbitMapCircle.visible = false
                }
            }
        }

        function show(coord) {
            _mapCircle.radius.rawValue = defaultRadius
            orbitMapCircle.center = coord
            orbitMapCircle.visible = true
        }

        function hide() {
            orbitMapCircle.visible = false
        }

        function actionConfirmed() {
            // Live orbit status is handled by telemetry so we hide here and telemetry will show again.
            hide()
        }

        function actionCancelled() {
            hide()
        }

        function radius() {
            return _mapCircle.radius.rawValue
        }

        Component.onCompleted: globals.guidedControllerFlyView.orbitMapCircle = orbitMapCircle

        QGCMapCircle {
            id:                 _mapCircle
            interactive:        true
            radius.rawValue:    30
            showRotation:       true
            clockwiseRotation:  true
        }
    }

    // ROI Location visuals
    MapQuickItem {
        id:             roiLocationItem
        visible:        _activeVehicle && _activeVehicle.isROIEnabled
        z:              QGroundControl.zOrderMapItems
        anchorPoint.x:  sourceItem.anchorPointX
        anchorPoint.y:  sourceItem.anchorPointY

        Connections {
            target: _activeVehicle
            function onRoiCoordChanged(centerCoord) {
                roiLocationItem.show(centerCoord)
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: (position) => {
                position = Qt.point(position.x, position.y)
                var clickCoord = _root.toCoordinate(position, false /* clipToViewPort */)
                // For some strange reason using mainWindow in mapToItem doesn't work, so we use globals.parent instead which also gets us mainWindow
                position = mapToItem(globals.parent, position)
                var dropPanel = roiEditDropPanelComponent.createObject(mainWindow, { clickRect: Qt.rect(position.x, position.y, 0, 0) })
                dropPanel.open()
            }
        }

        sourceItem: MissionItemIndexLabel {
            checked:    true
            index:      -1
            label:      qsTr("ROI here", "Make this a Region Of Interest")
        }

        //-- Visibilty controlled by actual state
        function show(coord) {
            roiLocationItem.coordinate = coord
        }
    }

    // Change Heading visuals
    MapQuickItem {
        id:             changeHeadingItem
        visible:        false
        z:              QGroundControl.zOrderMapItems
        anchorPoint.x:  sourceItem.anchorPointX
        anchorPoint.y:  sourceItem.anchorPointY
        sourceItem: MissionItemIndexLabel {
            checked:    true
            index:      -1
            label:      qsTr("Yaw towards here", "Turn towards location waypoint")
        }

        Connections {
            target: QGroundControl.multiVehicleManager
            function onActiveVehicleChanged(activeVehicle) {
                if (!activeVehicle) {
                    changeHeadingItem.visible = false
                }
            }
        }

        function show(coord) {
            changeHeadingItem.coordinate = coord
            changeHeadingItem.visible = true
        }

        function hide() {
            changeHeadingItem.visible = false
        }

        function actionConfirmed() {
            hide()
        }

        function actionCancelled() {
            hide()
        }
    }


    // Orbit telemetry visuals
    QGCMapCircleVisuals {
        id:             orbitTelemetryCircle
        mapControl:     parent
        mapCircle:      _activeVehicle ? _activeVehicle.orbitMapCircle : null
        visible:        _activeVehicle ? _activeVehicle.orbitActive : false
    }

    MapQuickItem {
        id:             orbitCenterIndicator
        anchorPoint.x:  sourceItem.anchorPointX
        anchorPoint.y:  sourceItem.anchorPointY
        coordinate:     _activeVehicle ? _activeVehicle.orbitMapCircle.center : QtPositioning.coordinate()
        visible:        orbitTelemetryCircle.visible && !gotoLocationItem.visible

        sourceItem: MissionItemIndexLabel {
            checked:    true
            index:      -1
            label:      qsTr("Orbit", "Orbit waypoint")
        }
    }

    Component {
        id: roiEditPositionDialogComponent

        EditPositionDialog {
            title:                  qsTr("Edit ROI Position")
            coordinate:             roiLocationItem.coordinate
            onCoordinateChanged: {
                roiLocationItem.coordinate = coordinate
                _activeVehicle.guidedModeROI(coordinate)
            }
        }
    }

    Component {
        id: roiEditDropPanelComponent

        DropPanel {
            id: roiEditDropPanel

            sourceComponent: Component {
                ColumnLayout {
                    spacing: ScreenTools.defaultFontPixelWidth / 2

                    QGCButton {
                        Layout.fillWidth:   true
                        text:               qsTr("Cancel ROI")
                        onClicked: {
                            _activeVehicle.stopGuidedModeROI()
                            roiEditDropPanel.close()
                        }
                    }

                    QGCButton {
                        Layout.fillWidth:   true
                        text:               qsTr("Edit Position")
                        onClicked: {         
                            roiEditPositionDialogComponent.createObject(mainWindow, { showSetPositionFromVehicle: false }).open()
                            roiEditDropPanel.close()
                        }
                    }
                }
            }
        }
    }

    Component {
        id: mapClickDropPanelComponent

        DropPanel {
            id: mapClickDropPanel

            property var mapClickCoord

            sourceComponent: Component {
                ColumnLayout {
                    spacing: ScreenTools.defaultFontPixelWidth / 2

                    QGCButton {
                        Layout.fillWidth:   true
                        text:               qsTr("Go to location")
                        visible:            globals.guidedControllerFlyView.showGotoLocation
                        onClicked: {
                            mapClickDropPanel.close()
                            gotoLocationItem.show(mapClickCoord)

                            if ((_activeVehicle.flightMode == _activeVehicle.gotoFlightMode) && !_flyViewSettings.goToLocationRequiresConfirmInGuided.value) {
                                globals.guidedControllerFlyView.executeAction(globals.guidedControllerFlyView.actionGoto, mapClickCoord, gotoLocationItem)
                                gotoLocationItem.actionConfirmed() // Still need to call this to commit the new coordinate and radius
                            } else {
                                globals.guidedControllerFlyView.confirmAction(globals.guidedControllerFlyView.actionGoto, mapClickCoord, gotoLocationItem)
                            }
                        }
                    }

                    QGCButton {
                        Layout.fillWidth:   true
                        text:               qsTr("Orbit at location")
                        visible:            globals.guidedControllerFlyView.showOrbit
                        onClicked: {
                            mapClickDropPanel.close()
                            orbitMapCircle.show(mapClickCoord)
                            globals.guidedControllerFlyView.confirmAction(globals.guidedControllerFlyView.actionOrbit, mapClickCoord, orbitMapCircle)
                        }
                    }

                    QGCButton {
                        Layout.fillWidth:   true
                        text:               qsTr("ROI at location")
                        visible:            globals.guidedControllerFlyView.showROI
                        onClicked: {
                            mapClickDropPanel.close()
                            globals.guidedControllerFlyView.executeAction(globals.guidedControllerFlyView.actionROI, mapClickCoord, 0, false)
                        }
                    }

                    QGCButton {
                        Layout.fillWidth:   true
                        text:               qsTr("Set home here")
                        visible:            globals.guidedControllerFlyView.showSetHome
                        onClicked: {
                            mapClickDropPanel.close()
                            globals.guidedControllerFlyView.confirmAction(globals.guidedControllerFlyView.actionSetHome, mapClickCoord)
                        }
                    }

                    // QGCButton {
                    //     Layout.fillWidth:   true
                    //     text:               qsTr("Set Estimator Origin")
                    //     visible:            globals.guidedControllerFlyView.showSetEstimatorOrigin
                    //     onClicked: {
                    //         mapClickDropPanel.close()
                    //         globals.guidedControllerFlyView.confirmAction(globals.guidedControllerFlyView.actionSetEstimatorOrigin, mapClickCoord)
                    //     }
                    // }

                    QGCButton {
                        Layout.fillWidth:   true
                        text:               qsTr("Set Heading")
                        visible:            globals.guidedControllerFlyView.showChangeHeading
                        onClicked: {
                            mapClickDropPanel.close()
                            globals.guidedControllerFlyView.confirmAction(globals.guidedControllerFlyView.actionChangeHeading, mapClickCoord)
                        }
                    }

                    ColumnLayout {
                        spacing: 0
                        QGCLabel { text: qsTr("Lat: %1").arg(mapClickCoord.latitude.toFixed(6)) }
                        QGCLabel { text: qsTr("Lon: %1").arg(mapClickCoord.longitude.toFixed(6)) }
                        QGCLabel { text: qsTr("Az: %1").arg(_activeVehicleCoordinate.azimuthTo(mapClickCoord).toFixed(1)) }
                    }
                }
            }
        }
    }

    onMapClicked: (position) => {
        if (!globals.guidedControllerFlyView.guidedUIVisible && 
            (globals.guidedControllerFlyView.showGotoLocation || globals.guidedControllerFlyView.showOrbit ||
             globals.guidedControllerFlyView.showROI || globals.guidedControllerFlyView.showSetHome ||
             globals.guidedControllerFlyView.showSetEstimatorOrigin)) {

            position = Qt.point(position.x, position.y)
            var clickCoord = _root.toCoordinate(position, false /* clipToViewPort */)
            // For some strange reason using mainWindow in mapToItem doesn't work, so we use globals.parent instead which also gets us mainWindow
            position = _root.mapToItem(globals.parent, position)
            var dropPanel = mapClickDropPanelComponent.createObject(mainWindow, { mapClickCoord: clickCoord, clickRect: Qt.rect(position.x, position.y, 0, 0) })
            dropPanel.open()
        }
    }

    // Rectangle {
    //    id: clickIndicator
    //    visible:    mapClickMenu.visible
    //    x: mapClickMenu.x - (height / 2) - (_toolsMargin * 2)
    //    y: mapClickMenu.y - (height / 2) - (_toolsMargin * 2)
    //    height: _toolsMargin * 5
    //    width:  height
    //    radius: height / 2
    //    color: "transparent"
    //    border.color: qgcPal.text
    //    border.width: 3

    //    Rectangle {
    //        height: 1
    //        width:  _toolsMargin * 7
    //        anchors.verticalCenter: parent.verticalCenter
    //        anchors.horizontalCenter: parent.horizontalCenter
    //    }

    //    Rectangle {
    //        height: _toolsMargin * 7
    //        width:  1
    //        anchors.verticalCenter: parent.verticalCenter
    //        anchors.horizontalCenter: parent.horizontalCenter
    //    }
    // }

    //*******************************************************************************************   

    //*******************************************************************************************
}
