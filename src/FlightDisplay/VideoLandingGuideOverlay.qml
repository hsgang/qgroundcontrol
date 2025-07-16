/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Controllers
import QGroundControl.ScreenTools
import QGroundControl.Vehicle
import QGroundControl.FlightDisplay

Item {
    id: _root
    anchors.fill: parent

    property var vehicle

    property real fontSize: ScreenTools.defaultFontPointSize * 3

    property var _roll:  vehicle ? vehicle.roll.rawValue : 0
    property var _pitch: vehicle ? vehicle.pitch.rawValue : 0
    property real _rawDistance: vehicle ? vehicle.distanceSensors.rotationPitch270.rawValue : 0
    property real _distance: vehicle ? (_rawDistance ? _rawDistance - 0.4 : 0) : 0

    // 필터링된 값 (초기값은 원시값과 동일)
    property real filteredRoll: _roll
    property real filteredPitch: _pitch

    // 필터 계수 (0 < alpha <= 1)
    property real alpha: 0.1

    property real _hFov: 75 //degree
    property real _vFov: 46 //degree
    property real _screenWidth: ScreenTools.screenWidth
    property real _screenHeight: ScreenTools.screenHeight

    // 라운드 사각형의 모서리 반경
    property real cornerRadius: 10

    // _roll 값 변경 시 저역통과 필터 적용
    on_RollChanged: {
        //filteredRoll = filteredRoll + alpha * (_roll - filteredRoll);
        crossCanvas.requestPaint();
    }

    // _pitch 값 변경 시 저역통과 필터 적용
    on_PitchChanged: {
        //filteredPitch = filteredPitch + alpha * (_pitch - filteredPitch);
        crossCanvas.requestPaint();
    }

    on_DistanceChanged: {
        crossCanvas.requestPaint();  // 값 변경 시 다시 그리기
    }

    Canvas {
        id: crossCanvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            // === 오프셋 계산 ===
            var xOffset = filteredRoll * _screenWidth / _hFov;
            var yOffset = filteredPitch * _screenHeight / _vFov;

            var centerX = width / 2 + xOffset;
            var centerY = height / 2 + yOffset;

            // === 십자선은 항상 ===
            const verticalLineLength = _screenHeight * 0.2;
            const horizontalLineLength = _screenHeight * 0.2;

            ctx.lineWidth = 1;
            ctx.strokeStyle = "#A0FF32";

            ctx.beginPath();
            ctx.moveTo(centerX, centerY - verticalLineLength / 2);
            ctx.lineTo(centerX, centerY + verticalLineLength / 2);
            ctx.stroke();

            ctx.beginPath();
            ctx.moveTo(centerX - horizontalLineLength / 2, centerY);
            ctx.lineTo(centerX + horizontalLineLength / 2, centerY);
            ctx.stroke();

            // === 사각형과 원은 distance 범위 조건 ===
            if (_distance >= 0.3 && _distance <= 20) {
                var focal = (_screenWidth / 2) / Math.tan((_hFov / 2) * Math.PI / 180);
                var objectPhysicalSize = 3;
                var cameraPhysicalOffset = 0.3;

                var effectiveDistance = Math.max(_distance, 0.001);
                var rectSize = (objectPhysicalSize * focal) / effectiveDistance;
                var cameraYOffset = (cameraPhysicalOffset * focal) / effectiveDistance;

                var minSize = _screenHeight * 0.05;
                var maxSize = _screenHeight * 1.20;
                rectSize = Math.max(minSize, Math.min(maxSize, rectSize));

                // === 거리값 텍스트 ===
                ctx.font = "bold " + fontSize + "px sans-serif"; // 폰트 스타일
                ctx.fillStyle = "#A0FF32";           // 텍스트 색상
                ctx.textAlign = "left";              // 정렬
                ctx.textBaseline = "top";            // 기준선

                var distanceText = "RNG " + _distance.toFixed(1) + " m";
                var textX = centerX + 10;
                var textY = centerY + 10;

                ctx.fillText(distanceText, textX, textY);

                // === 사각형 ===
                function drawRoundedRect(ctx, x, y, width, height, radius) {
                    ctx.beginPath();
                    ctx.moveTo(x + radius, y);
                    ctx.lineTo(x + width - radius, y);
                    ctx.quadraticCurveTo(x + width, y, x + width, y + radius);
                    ctx.lineTo(x + width, y + height - radius);
                    ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
                    ctx.lineTo(x + radius, y + height);
                    ctx.quadraticCurveTo(x, y + height, x, y + height - radius);
                    ctx.lineTo(x, y + radius);
                    ctx.quadraticCurveTo(x, y, x + radius, y);
                    ctx.closePath();
                }

                var rectX = centerX - rectSize / 2;
                var rectY = centerY - rectSize / 2 + cameraYOffset;

                drawRoundedRect(ctx, rectX, rectY, rectSize, rectSize, rectSize / 4);
                ctx.stroke();

                // === 원 ===
                ctx.beginPath();
                var circleRadius = rectSize * 0.05;
                ctx.arc(centerX, centerY + cameraYOffset, circleRadius, 0, 2 * Math.PI);
                ctx.stroke();
            }
        }
    }
}
