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
import QGroundControl.FlightDisplay

Item {
    id: _root
    anchors.fill: parent

    property var vehicle

    // 짐벌 컨트롤러 속성
    property var gimbalController: vehicle ? vehicle.gimbalController : null
    property var activeGimbal: gimbalController ? gimbalController.activeGimbal : null

    property real fontSize: ScreenTools.defaultFontPointSize * 3

    property var _roll:  vehicle ? vehicle.roll.rawValue : 0
    property var _pitch: vehicle ? vehicle.pitch.rawValue : 0
    property real _rawDistance: vehicle ? vehicle.distanceSensors.rotationPitch270.rawValue : 0
    property real _distance: vehicle ? (_rawDistance ? _rawDistance - 0.4 : 0) : 0
    property real _minDistance: vehicle ? vehicle.distanceSensors.minDistance.rawValue : 0
    property real _maxDistance: vehicle ? vehicle.distanceSensors.maxDistance.rawValue : 10
    property real _verticalSpeed: vehicle ? vehicle.climbRate.rawValue : 0

    // 짐벌 각도 (절대 각도)
    property real _gimbalPitch: activeGimbal ? activeGimbal.absolutePitch.rawValue : 0
    property real _gimbalYaw: activeGimbal ? activeGimbal.absoluteYaw.rawValue : 0

    // 짐벌 방위각 (절대 yaw 값 사용)
    property real _gimbalAzimuth: activeGimbal ? activeGimbal.absoluteYaw.rawValue : 0

    // 필터링된 값 (초기값은 원시값과 동일)
    property real filteredRoll: _roll
    property real filteredPitch: _pitch

    // 필터 계수 (0 < alpha <= 1)
    property real alpha: 0.1

    property real _hFov: 81 //75 //degree
    property real _vFov: 63 //46 //degree
    property real screenWidth //: ScreenTools.screenWidth
    property real screenHeight //: ScreenTools.screenHeight

    // 라운드 사각형의 모서리 반경
    property real cornerRadius: 10

    // 짐벌 각도 변경 시 다시 그리기 (기체 자세는 짐벌이 보정)
    on_GimbalPitchChanged: {
        crossCanvas.requestPaint();
    }

    on_GimbalYawChanged: {
        crossCanvas.requestPaint();
    }

    on_GimbalAzimuthChanged: {
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

            // === 짐벌 카메라 중심점 계산 ===
            // 짐벌 피치만 반영하고 yaw는 오버레이 위치에 영향 없음
            var gimbalPitchOffset = ((-90) - _gimbalPitch) * screenHeight / _vFov; // -90도 기준으로 오프셋 계산 (방향 수정)

            var centerX = width / 2; // yaw 오프셋 제거
            var centerY = height / 2 - gimbalPitchOffset;

            // === 십자선은 항상 ===
            const verticalLineLength = screenHeight * 0.1;
            const horizontalLineLength = screenHeight * 0.1;

            ctx.lineWidth = 1;
            ctx.strokeStyle = '#ffffff';

            ctx.beginPath();
            ctx.moveTo(centerX, centerY - verticalLineLength / 2);
            ctx.lineTo(centerX, centerY + verticalLineLength / 2);
            ctx.stroke();

            ctx.beginPath();
            ctx.moveTo(centerX - horizontalLineLength / 2, centerY);
            ctx.lineTo(centerX + horizontalLineLength / 2, centerY);
            ctx.stroke();

            // === 사각형과 원은 distance 범위 조건 ===
            if (_distance > _minDistance && _distance < _maxDistance) {
                var focal = (screenWidth / 2) / Math.tan((_hFov / 2) * Math.PI / 180);
                var objectPhysicalSize = 3;
                var cameraPhysicalOffset = 0.3;

                var effectiveDistance = Math.max(_distance, 0.001);
                var rectSize = (objectPhysicalSize * focal) / effectiveDistance;
                var cameraYOffset = (cameraPhysicalOffset * focal) / effectiveDistance;

                var minSize = screenHeight * 0.05;
                var maxSize = screenHeight * 1.50;
                rectSize = Math.max(minSize, Math.min(maxSize, rectSize));

                // === 레인지파인더 텍스트 ===
                ctx.font = "bold " + fontSize + "px sans-serif"; // 폰트 스타일
                ctx.fillStyle = '#ffffff';           // 텍스트 색상
                ctx.textAlign = "left";              // 정렬
                ctx.textBaseline = "top";            // 기준선

                var distanceText = "RNG " + _distance.toFixed(1) + " m";
                var textX = centerX + 10;
                var textY = centerY + 10;

                ctx.fillText(distanceText, textX, textY);

                // === 수직속도 텍스트 ===
                ctx.font = "bold " + fontSize/2 + "px sans-serif"; // 폰트 스타일
                ctx.fillStyle = "#ffffff";           // 텍스트 색상
                ctx.textAlign = "left";              // 정렬
                ctx.textBaseline = "bottom";            // 기준선

                var verticalSpeedText = "V.Spd " + _verticalSpeed.toFixed(1) + " m/s";
                var text2X = centerX + 10;
                var text2Y = centerY - 10;

                ctx.fillText(verticalSpeedText, text2X, text2Y);

                // === 방위 표시 원 ===
                var compassRadius = rectSize * 0.5;
                var compassCenterY = centerY + cameraYOffset;

                // 외곽 원
                ctx.beginPath();
                ctx.arc(centerX, compassCenterY, compassRadius, 0, 2 * Math.PI);
                ctx.stroke();

                // 내부 원 (랜딩 존)
                // ctx.beginPath();
                // ctx.arc(centerX, compassCenterY, compassRadius * 0.3, 0, 2 * Math.PI);
                // ctx.stroke();

                // 방위각 계산 (North = 0도, 시계방향)
                var azimuthRad = (_gimbalAzimuth * Math.PI) / 180;

                // 방위 표시선과 텍스트
                ctx.font = "bold " + (fontSize * 0.6) + "px sans-serif";
                ctx.fillStyle = "#ffffff";
                ctx.textAlign = "center";
                ctx.textBaseline = "middle";

                // 북쪽 (N) - 짐벌 방위각에 따라 회전
                var northAngle = -azimuthRad; // 북쪽 방향
                var northX = centerX + compassRadius * 1.2 * Math.sin(northAngle);
                var northY = compassCenterY - compassRadius * 1.2 * Math.cos(northAngle);
                ctx.fillText("N", northX, northY);

                // 북쪽 방향 표시선
                ctx.beginPath();
                ctx.moveTo(centerX + compassRadius * 0.9 * Math.sin(northAngle),
                          compassCenterY - compassRadius * 0.9 * Math.cos(northAngle));
                ctx.lineTo(centerX + compassRadius * 1.1 * Math.sin(northAngle),
                          compassCenterY - compassRadius * 1.1 * Math.cos(northAngle));
                ctx.stroke();

                // 동쪽 (E)
                var eastAngle = -azimuthRad + Math.PI / 2;
                var eastX = centerX + compassRadius * 1.2 * Math.sin(eastAngle);
                var eastY = compassCenterY - compassRadius * 1.2 * Math.cos(eastAngle);
                ctx.fillText("E", eastX, eastY);

                // 동쪽 방향 표시선
                ctx.beginPath();
                ctx.moveTo(centerX + compassRadius * 0.9 * Math.sin(eastAngle),
                          compassCenterY - compassRadius * 0.9 * Math.cos(eastAngle));
                ctx.lineTo(centerX + compassRadius * 1.1 * Math.sin(eastAngle),
                          compassCenterY - compassRadius * 1.1 * Math.cos(eastAngle));
                ctx.stroke();

                // 남쪽 (S)
                var southAngle = -azimuthRad + Math.PI;
                var southX = centerX + compassRadius * 1.2 * Math.sin(southAngle);
                var southY = compassCenterY - compassRadius * 1.2 * Math.cos(southAngle);
                ctx.fillText("S", southX, southY);

                // 남쪽 방향 표시선
                ctx.beginPath();
                ctx.moveTo(centerX + compassRadius * 0.9 * Math.sin(southAngle),
                          compassCenterY - compassRadius * 0.9 * Math.cos(southAngle));
                ctx.lineTo(centerX + compassRadius * 1.1 * Math.sin(southAngle),
                          compassCenterY - compassRadius * 1.1 * Math.cos(southAngle));
                ctx.stroke();

                // 서쪽 (W)
                var westAngle = -azimuthRad + 3 * Math.PI / 2;
                var westX = centerX + compassRadius * 1.2 * Math.sin(westAngle);
                var westY = compassCenterY - compassRadius * 1.2 * Math.cos(westAngle);
                ctx.fillText("W", westX, westY);

                // 서쪽 방향 표시선
                ctx.beginPath();
                ctx.moveTo(centerX + compassRadius * 0.9 * Math.sin(westAngle),
                          compassCenterY - compassRadius * 0.9 * Math.cos(westAngle));
                ctx.lineTo(centerX + compassRadius * 1.1 * Math.sin(westAngle),
                          compassCenterY - compassRadius * 1.1 * Math.cos(westAngle));
                ctx.stroke();

                // === 방위각 표시 ===
                // ctx.font = "bold " + (fontSize * 0.5) + "px sans-serif";
                // ctx.fillStyle = "#A0FF32";
                // ctx.textAlign = "center";
                // ctx.textBaseline = "top";
                // var azimuthText = "AZ " + _gimbalAzimuth.toFixed(0) + "°";
                // ctx.fillText(azimuthText, centerX, compassCenterY + compassRadius + 5);

                // === 원(1m)반경 ===
                ctx.beginPath();
                var circle1Radius = rectSize * 0.333;
                ctx.arc(centerX, centerY + cameraYOffset, circle1Radius, 0, 2 * Math.PI);
                ctx.stroke();

                // 반지름 표시 텍스트
                ctx.font = "bold " + (fontSize * 0.6) + "px sans-serif";
                ctx.fillStyle = "#ffffff";
                ctx.textAlign = "right";
                ctx.textBaseline = "middle";

                // 1m 원 반지름 표시
                ctx.fillText("D-2m", centerX + circle1Radius + 5, centerY + cameraYOffset);

                // 1.5m 원 반지름 표시
                ctx.fillText("D-3m", centerX + compassRadius + 5, compassCenterY);
            }
        }
    }
}
