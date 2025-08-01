/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtLocation
import QtPositioning

import QGroundControl
import QGroundControl.ScreenTools

import QGroundControl.Controls
import QGroundControl.FlightDisplay

MapQuickItem {
    id:             _root
    visible:        proximityValues.telemetryAvailable && coordinate.isValid

    property var    vehicle                                                         /// Vehicle object, undefined for ADSB vehicle
    property var    map
    property double heading:    vehicle ? vehicle.heading.value : Number.NaN    ///< Vehicle heading, NAN for none

    anchorPoint.x:  vehicleItem.width  / 2
    anchorPoint.y:  vehicleItem.height / 2

    property real   _ratio: 1
    property real   _maxDistance:   isNaN(proximityValues.maxDistance)

    function calcSize() {
        var scaleLinePixelLength    = 100
        var leftCoord               = map.toCoordinate(Qt.point(0, 0), false /* clipToViewPort */)
        var rightCoord              = map.toCoordinate(Qt.point(scaleLinePixelLength, 0), false /* clipToViewPort */)
        var scaleLineMeters         = Math.round(leftCoord.distanceTo(rightCoord))
        _ratio = scaleLinePixelLength / scaleLineMeters;
    }

    ProximityRadarValues {
        id:                     proximityValues
        vehicle:                _root.vehicle
        onRotationValueChanged: vehicleSensors.requestPaint()
    }

    Connections {
        target:             map
        function onWidthChanged() { scaleTimer.restart() }
        function onHeightChanged() { scaleTimer.restart() }
        function onZoomLevelChanged() { scaleTimer.restart() }
    }

    Timer {
        id:                 scaleTimer
        interval:           100
        running:            false
        repeat:             false
        onTriggered:        calcSize()
    }

    sourceItem: Item {
        id:         vehicleItem
        width:      detectionLimitCircle.width
        height:     detectionLimitCircle.height
        opacity:    0.5

        Component.onCompleted: calcSize()

        Canvas{
            id:                 vehicleSensors
            anchors.fill:       detectionLimitCircle

            transform: Rotation {
                origin.x:       detectionLimitCircle.width  / 2
                origin.y:       detectionLimitCircle.height / 2
                angle:          isNaN(heading) ? 0 : heading
            }

            function deg2rad(degrees) {
                var pi = Math.PI;
                return degrees * (pi/180);
            }

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.translate(width/2, height/2)
                ctx.rotate(-Math.PI/2);
                ctx.lineWidth = 5;
                ctx.strokeStyle = Qt.rgba(1, 0, 0, 1);
                for(var i=0; i<proximityValues.rgRotationValues.length; i++){
                    var rotationValue = proximityValues.rgRotationValues[i]
                    if (!isNaN(rotationValue) && (rotationValue < proximityValues.maxDistance)) {
                        var a=deg2rad(360-22.5)+Math.PI/4*i;
                        ctx.beginPath();
                        ctx.arc(0, 0, rotationValue * _ratio, a, a + Math.PI/4,false);
                        ctx.stroke();
                    }
                }
            }
        }

        Rectangle {
            id:                 detectionLimitCircle
            width:              proximityValues.maxDistance * 2 *_ratio
            height:             proximityValues.maxDistance * 2 *_ratio
            anchors.fill:       detectionLimitCircle
            color:              Qt.rgba(1,1,1,0)
            border.color:       Qt.rgba(1,1,1,1)
            border.width:       5
            radius:             width * 0.5

            transform: Rotation {
                origin.x:       detectionLimitCircle.width  / 2
                origin.y:       detectionLimitCircle.height / 2
                angle:          isNaN(heading) ? 0 : heading
            }
        }

    }
}

