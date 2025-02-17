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

    property var _roll:  vehicle ? vehicle.roll.rawValue : 0
    property var _pitch: vehicle ? vehicle.pitch.rawValue : 0
    property var _distance: vehicle ? vehicle.distanceSensors.rotationPitch270.rawValue : 0

    // 필터링된 값 (초기값은 원시값과 동일)
    property real filteredRoll: _roll
    property real filteredPitch: _pitch

    // 필터 계수 (0 < alpha <= 1)
    property real alpha: 0.1

    property real _hFov: 66 //degree
    property real _vFov: 50 //degree
    property real _screenWidth: ScreenTools.screenWidth
    property real _screenHeight: ScreenTools.screenHeight

    // _roll 값 변경 시 저역통과 필터 적용
    on_RollChanged: {
        filteredRoll = filteredRoll + alpha * (_roll - filteredRoll);
        crossCanvas.requestPaint();
    }

    // _pitch 값 변경 시 저역통과 필터 적용
    on_PitchChanged: {
        filteredPitch = filteredPitch + alpha * (_pitch - filteredPitch);
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

            // 십자선의 이동 범위를 제한 (화면 중앙에서 최대 ±100px 이동)
            var maxOffset = 100;
            var xOffset = filteredRoll * _screenWidth / _hFov;  // Roll에 따라 좌우 이동
            var yOffset = filteredPitch * _screenHeight / _vFov; // Pitch에 따라 상하 이동

            var centerX = width / 2 + xOffset;
            var centerY = height / 2 + yOffset;

            // 초점 거리 (focal length) 산출
            // focal = (화면 반폭) / tan(화각/2)
            var focal = (_screenWidth / 2) / Math.tan((_hFov / 2) * Math.PI / 180);

            // 피사체의 실제 크기를 가정 (예: 2.5미터)
            var objectPhysicalSize = 3;

            // 투영 기하학에 의한 계산:
            // 화면상의 사각형 크기 = (피사체 실제 크기 * focal length) / 거리
            // 단, _distance가 0인 경우를 방지하기 위해 최소값 적용
            var effectiveDistance = Math.max(_distance, 0.001);
            var rectSize = (objectPhysicalSize * focal) / effectiveDistance;

            // 최소/최대 크기 제한 (필요에 따라 조정)
            var minSize = _screenHeight * 0.05;
            var maxSize = _screenHeight * 0.85;
            rectSize = Math.max(minSize, Math.min(maxSize, rectSize));

            // 사각형 그리기 (중심을 기준으로 크기 조절)
            ctx.lineWidth = 5;
            ctx.strokeStyle = "rgba(255, 0, 0, 0.2)";
            ctx.beginPath();
            ctx.rect(centerX - rectSize / 2, centerY - rectSize / 2, rectSize, rectSize);
            ctx.stroke();

            // 세로선 (Roll 적용)
            ctx.lineWidth = 1;
            ctx.strokeStyle = "lime";
            ctx.beginPath();
            ctx.moveTo(centerX, 0);
            ctx.lineTo(centerX, height);
            ctx.stroke();

            // 가로선 (Pitch 적용)
            ctx.beginPath();
            ctx.moveTo(0, centerY);
            ctx.lineTo(width, centerY);
            ctx.stroke();
        }
    }
}
