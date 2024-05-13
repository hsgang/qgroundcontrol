import QtQuick
import QtLocation
import QtPositioning
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Vehicle
import QGroundControl.Controls
import QGroundControl.MultiVehicleManager
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Palette
import QGroundControl.SettingsManager


/// Marker for displaying a vehicle location on the map

MapQuickItem {
    anchorPoint.x:  vehicleItem.width  / 2
    anchorPoint.y:  vehicleItem.height / 2
    visible:        coordinate.isValid

    property var    map
    property var    _map:           map

    property double heading:        object ? object.heading.value : Number.NaN    ///< Vehicle heading, NAN for none

    property real   _pitchValue:    object ? object.pitch.rawValue -90 : 0 //object ? object.atmosphericSensor.humidity.rawValue : 0//
    property real   _rollValue:     object ? object.roll.rawValue : 0 //object ? object.atmosphericSensor.pressure.rawValue : 0//
    property real   _altitudeValue: object ? object.altitudeRelative.rawValue : 0 //object ? object.atmosphericSensor.windDir.rawValue : 0
    property real   _windSpdValue:  object ? object.atmosphericSensor.windSpd.rawValue : 0
    property real   _distRatio:     0

    property real   _cameraFOV:     90

    property var    _scaleLengthsMeters:    [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 150, 250, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000, 500000, 1000000, 2000000]
    property var    _scaleLengthsFeet:      [10, 25, 50, 100, 250, 500, 1000, 2000, 3000, 4000, 5280, 5280*2, 5280*5, 5280*10, 5280*25, 5280*50, 5280*100, 5280*250, 5280*500, 5280*1000]

    function formatDistanceMeters(meters) {
        var dist = Math.round(meters)
        if (dist > 1000 ){
            if (dist > 100000){
                dist = Math.round(dist / 1000)
            } else {
                dist = Math.round(dist / 100)
                dist = dist / 10
            }
            _distRatio = dist
        } else {
            _distRatio = dist
        }
        return dist
    }

    function formatDistanceFeet(feet) {
        var dist = Math.round(feet)
        if (dist >= 5280) {
            dist = Math.round(dist / 5280)
            _distRatio = dist
        } else {
            _distRatio = dist
        }
        return dist
    }

    function calculateMetersRatio(scaleLineMeters, scaleLinePixelLength) {
        var scaleLineRatio = 0

        if (scaleLineMeters === 0) {
            // not visible
        } else {
            for (var i = 0; i < _scaleLengthsMeters.length - 1; i++) {
                if (scaleLineMeters < (_scaleLengthsMeters[i] + _scaleLengthsMeters[i+1]) / 2 ) {
                    scaleLineRatio = _scaleLengthsMeters[i] / scaleLineMeters
                    scaleLineMeters = _scaleLengthsMeters[i]
                    break;
                }
            }
            if (scaleLineRatio === 0) {
                scaleLineRatio = scaleLineMeters / _scaleLengthsMeters[i]
                scaleLineMeters = _scaleLengthsMeters[i]
            }
        }

        var text = formatDistanceMeters(scaleLineMeters)
    }

    function calculateFeetRatio(scaleLineMeters, scaleLinePixelLength) {
        var scaleLineRatio = 0
        var scaleLineFeet = scaleLineMeters * 3.2808399

        if (scaleLineFeet === 0) {
            // not visible
        } else {
            for (var i = 0; i < _scaleLengthsFeet.length - 1; i++) {
                if (scaleLineFeet < (_scaleLengthsFeet[i] + _scaleLengthsFeet[i+1]) / 2 ) {
                    scaleLineRatio = _scaleLengthsFeet[i] / scaleLineFeet
                    scaleLineFeet = _scaleLengthsFeet[i]
                    break;
                }
            }
            if (scaleLineRatio === 0) {
                scaleLineRatio = scaleLineFeet / _scaleLengthsFeet[i]
                scaleLineFeet = _scaleLengthsFeet[i]
            }
        }

        var text = formatDistanceFeet(scaleLineFeet)
    }

    function calculateScale() {
        if(_map) {
            var scaleLinePixelLength = 100
            var leftCoord  = _map.toCoordinate(Qt.point(0, parent.y), false /* clipToViewPort */)
            var rightCoord = _map.toCoordinate(Qt.point(scaleLinePixelLength, parent.y), false /* clipToViewPort */)
            var scaleLineMeters = Math.round(leftCoord.distanceTo(rightCoord))
            if (QGroundControl.settingsManager.unitsSettings.distanceUnits.value === UnitsSettings.DistanceUnitsFeet) {
                calculateFeetRatio(scaleLineMeters, scaleLinePixelLength)
            } else {
                calculateMetersRatio(scaleLineMeters, scaleLinePixelLength)
            }
        }
    }

    Connections {
        target:           _map
        function onWidthChanged() {     scaleTimer.restart() }
        function onHeightChanged() {    scaleTimer.restart() }
        function onZoomLevelChanged() { scaleTimer.restart() }
    }

    Timer {
        id:                 scaleTimer
        interval:           100
        running:            false
        repeat:             false
        onTriggered:        calculateScale()
    }

    sourceItem: Item {
        id:     vehicleItem
        width:  2000
        height: 2000

        transform: Rotation {
            origin.x:       vehicleItem.width  / 2
            origin.y:       vehicleItem.height / 2
            angle:          isNaN(heading) ? 0 : heading
        }

        Canvas {
            id: canvas
            anchors.fill: parent

            property real cameraFOV:   _cameraFOV // 카메라 fov
            property real cameraPitch: _pitchValue + 90 // 카메라의 pitch 각도 (degrees)
            property real cameraRoll:  _rollValue // 카메라의 roll 각도 (degrees)
            property real floorHeight: (_altitudeValue * 100) / _distRatio // 바닥과의 높이 (meters)

//            function toRadians(degrees: number): number {
//                return degrees * (Math.PI / 180);
//            }

            onCameraFOVChanged: {
                canvas.requestPaint();
            }

            onCameraPitchChanged: {
                canvas.requestPaint();
            }

            onCameraRollChanged: {
                canvas.requestPaint();
            }

            onFloorHeightChanged: {
                canvas.requestPaint();
            }

            onPaint: {
                var ctx = getContext("2d");

                ctx.clearRect(0, 0, canvas.width, canvas.height);

                // 카메라 및 바닥면 관련 파라미터 설정
                var fieldOfView = _cameraFOV; // 시야각 (degrees)

                // 각 모서리의 x, y 좌표 계산                
                var hFOV = (fieldOfView * 0.8) / 2 * Math.PI / 180;
                var vFOV = (fieldOfView * 0.6) / 2 * Math.PI / 180;
                var pitchRad = cameraPitch * Math.PI / 180;
                var rollRad = cameraRoll * Math.PI / 180;
                var vFOVCenter = (canvas.height/2) - (floorHeight * Math.tan(pitchRad))
                var hFOVCenter = (canvas.width /2) + (floorHeight * Math.tan(rollRad))
                var hFOVWidth = floorHeight * Math.tan(hFOV);
                var vFOVHeight = floorHeight * Math.tan(vFOV);

                var tl = [-hFOVWidth, -vFOVHeight, floorHeight];
                var tr = [ hFOVWidth, -vFOVHeight, floorHeight];
                var bl = [-hFOVWidth,  vFOVHeight, floorHeight];
                var br = [ hFOVWidth,  vFOVHeight, floorHeight];

                // 세타와 프사이 각 설정
                var theta = cameraPitch; // 세타 각도
                var phi = cameraRoll;   // 프사이 각도

                // 라디안으로 변환
                var thetaRad = phi * (Math.PI / 180);
                var phiRad = theta * (Math.PI / 180);

                // 회전 행렬 계산
                // const Rz = [
                //     [Math.cos(thetaRad), Math.sin(thetaRad), 0],
                //     [-Math.sin(thetaRad), Math.cos(thetaRad), 0],
                //     [0, 0, 1 ]
                // ];

                var Rx = [
                    [1, 0, 0],
                    [0, Math.cos(phiRad), -Math.sin(phiRad)],
                    [0, Math.sin(phiRad), Math.cos(phiRad)]
                ];

                var Ry = [
                    [Math.cos(thetaRad), 0, Math.sin(thetaRad)],
                    [0, 1, 0],
                    [-Math.sin(thetaRad), 0, Math.cos(thetaRad)]
                ];

                // 두 회전 행렬을 곱하여 전체 회전 행렬 계산
                var Rz = [
                    [
                        Rx[0][0] * Ry[0][0] + Rx[0][1] * Ry[1][0] + Rx[0][2] * Ry[2][0],
                        Rx[0][0] * Ry[0][1] + Rx[0][1] * Ry[1][1] + Rx[0][2] * Ry[2][1],
                        Rx[0][0] * Ry[0][2] + Rx[0][1] * Ry[1][2] + Rx[0][2] * Ry[2][2]
                    ],
                    [
                        Rx[1][0] * Ry[0][0] + Rx[1][1] * Ry[1][0] + Rx[1][2] * Ry[2][0],
                        Rx[1][0] * Ry[0][1] + Rx[1][1] * Ry[1][1] + Rx[1][2] * Ry[2][1],
                        Rx[1][0] * Ry[0][2] + Rx[1][1] * Ry[1][2] + Rx[1][2] * Ry[2][2]
                    ],
                    [
                        Rx[2][0] * Ry[0][0] + Rx[2][1] * Ry[1][0] + Rx[2][2] * Ry[2][0],
                        Rx[2][0] * Ry[0][1] + Rx[2][1] * Ry[1][1] + Rx[2][2] * Ry[2][1],
                        Rx[2][0] * Ry[0][2] + Rx[2][1] * Ry[1][2] + Rx[2][2] * Ry[2][2]
                    ]
                ];

                // 좌표행렬에 회전 행렬 적용
                var rotatedTL = [
                    tl[0] * Rz[0][0] + tl[1] * Rz[0][1] + tl[2] * Rz[0][2],
                    tl[0] * Rz[1][0] + tl[1] * Rz[1][1] + tl[2] * Rz[1][2],
                    tl[0] * Rz[2][0] + tl[1] * Rz[2][1] + tl[2] * Rz[2][2]
                ];

                var rotatedTR = [
                    tr[0] * Rz[0][0] + tr[1] * Rz[0][1] + tr[2] * Rz[0][2],
                    tr[0] * Rz[1][0] + tr[1] * Rz[1][1] + tr[2] * Rz[1][2],
                    tr[0] * Rz[2][0] + tr[1] * Rz[2][1] + tr[2] * Rz[2][2]
                ];

                var rotatedBL = [
                    bl[0] * Rz[0][0] + bl[1] * Rz[0][1] + bl[2] * Rz[0][2],
                    bl[0] * Rz[1][0] + bl[1] * Rz[1][1] + bl[2] * Rz[1][2],
                    bl[0] * Rz[2][0] + bl[1] * Rz[2][1] + bl[2] * Rz[2][2]
                ];

                var rotatedBR = [
                    br[0] * Rz[0][0] + br[1] * Rz[0][1] + br[2] * Rz[0][2],
                    br[0] * Rz[1][0] + br[1] * Rz[1][1] + br[2] * Rz[1][2],
                    br[0] * Rz[2][0] + br[1] * Rz[2][1] + br[2] * Rz[2][2]
                ];

                var t_tl = - floorHeight / (rotatedTL[2] - floorHeight);
                var t_tr = - floorHeight / (rotatedTR[2] - floorHeight);
                var t_bl = - floorHeight / (rotatedBL[2] - floorHeight);
                var t_br = - floorHeight / (rotatedBR[2] - floorHeight);

                var matTopLeft = { //purple
                    x:hFOVCenter + tl[0] + rotatedTL[0] / t_tl, //tl[0] + (tl[0] + (rotatedTL[0] - tl[0]) / t_tl),
                    y:vFOVCenter + tl[1] + rotatedTL[1] / t_tl, //tl[1] + (tl[1] + (rotatedTL[1] - tl[1]) / t_tl),
                    z:(tl[2] + (rotatedTL[2] - tl[2]) * t_tl)
                }
                var matTopRight = { //skyblue
                    x:hFOVCenter + tr[0] + rotatedTR[0] / t_tr, //+ (tr[0] + (rotatedTR[0] - tr[0]) / t_tr),
                    y:vFOVCenter + tr[1] + rotatedTR[1] / t_tr, //tr[1] + (tr[1] + (rotatedTR[1] - tr[1]) / t_tr),
                    z:(tr[2] + (rotatedTR[2] - tr[2]) * t_tr)
                }
                var matBottomLeft = { //pink
                    x:hFOVCenter + bl[0] + rotatedBL[0] / t_bl, //bl[0] + (bl[0] + (rotatedBL[0] - bl[0]) / t_bl),
                    y:vFOVCenter + bl[1] + rotatedBL[1] / t_bl, //bl[1] + (bl[1] + (rotatedBL[1] - bl[1]) / t_bl),
                    z:(bl[2] + (rotatedBL[2] - bl[2]) * t_bl)
                }
                var matBottomRight = { //brown
                    x:hFOVCenter + br[0] + rotatedBR[0] / t_br, //br[0] + (br[0] + (rotatedBR[0] - br[0]) / t_br),
                    y:vFOVCenter + br[1] + rotatedBR[1] / t_br, //br[1] + (br[1] + (rotatedBR[1] - br[1]) / t_br),
                    z:(br[2] + (rotatedBR[2] - br[2]) * t_br)
                }

                // console.log('hFOVWidth',hFOVWidth)
                // console.log('vFOVHeight',vFOVHeight)
                // console.log('floorHeight',floorHeight)

                // console.log("Rotated Point TL:", rotatedTL);
                // console.log("Rotated Point TR:", rotatedTR);
                // console.log("Rotated Point BL:", rotatedBL);
                // console.log("Rotated Point BR:", rotatedBR);

                // console.log("t_TL:", t_tl);
                // console.log("t_TR:", t_tr);
                // console.log("t_BL:", t_bl);
                // console.log("t_BR:", t_br);

                // console.log("Mat Point TL:", matTopLeft.x, matTopLeft.y, matTopLeft.z);
                // console.log("Mat Point TR:", matTopRight.x, matTopRight.y, matTopRight.z);
                // console.log("Mat Point BL:", matBottomLeft.x, matBottomLeft.y, matBottomLeft.z);
                // console.log("Mat Point BR:", matBottomRight.x, matBottomRight.y, matBottomRight.z);


                // 좌표를 화면에 그리기
                ctx.beginPath();
                ctx.moveTo(matTopLeft.x, matTopLeft.y);
                ctx.lineTo(matTopRight.x, matTopRight.y);
                ctx.lineTo(matBottomRight.x, matBottomRight.y);
                ctx.lineTo(matBottomLeft.x, matBottomLeft.y);
                ctx.fillStyle = Qt.rgba(qgcPal.window.r,qgcPal.window.g,qgcPal.window.b, 0.1);
                ctx.fill();
                ctx.closePath();
                ctx.strokeStyle = "dodgerblue";
                ctx.lineWidth = 2;
                ctx.stroke();

                ctx.beginPath();
                ctx.moveTo(canvas.width/2, canvas.height/2);
                ctx.lineTo(matTopLeft.x, matTopLeft.y);
                ctx.lineWidth = 1;
                ctx.closePath();
                ctx.stroke();

                ctx.beginPath();
                ctx.moveTo(canvas.width/2, canvas.height/2);
                ctx.lineTo(matTopRight.x, matTopRight.y);
                ctx.closePath();
                ctx.stroke();

                ctx.beginPath();
                ctx.moveTo(canvas.width/2, canvas.height/2);
                ctx.lineTo(matBottomRight.x, matBottomRight.y);
                ctx.closePath();
                ctx.stroke();

                ctx.beginPath();
                ctx.moveTo(canvas.width/2, canvas.height/2);
                ctx.lineTo(matBottomLeft.x, matBottomLeft.y);
                ctx.closePath();
                ctx.stroke();

                // ctx.beginPath();
                // ctx.moveTo(0, vFOVCenter);
                // ctx.lineTo(canvas.width, vFOVCenter);
                // ctx.closePath();
                // ctx.strokeStyle = "yellow";
                // ctx.lineWidth = 1;
                // ctx.stroke();

                // ctx.beginPath();
                // ctx.moveTo(hFOVCenter, 0)
                // ctx.lineTo(hFOVCenter, canvas.height)
                // ctx.closePath();
                // ctx.strokeStyle = "yellow";
                // ctx.lineWidth = 1;
                // ctx.stroke();

                // ctx.beginPath();
                // ctx.arc(matTopLeft.x, matTopLeft.y, 20, 0, 2* Math.PI);
                // ctx.strokeStyle = "red";
                // ctx.lineWidth = 5;
                // ctx.stroke();
                // ctx.beginPath();
                // ctx.arc(matTopRight.x, matTopRight.y, 20, 0, 2* Math.PI);
                // ctx.strokeStyle = "orange";
                // ctx.stroke();
                // ctx.beginPath();
                // ctx.arc(matBottomLeft.x, matBottomLeft.y, 20, 0, 2* Math.PI);
                // ctx.strokeStyle = "green";
                // ctx.stroke();
                // ctx.beginPath();
                // ctx.arc(matBottomRight.x, matBottomRight.y, 20, 0, 2* Math.PI);
                // ctx.strokeStyle = "blue";
                // ctx.stroke();
            }
        }

    }
}
