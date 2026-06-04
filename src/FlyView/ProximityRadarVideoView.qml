import QtQuick
import QtLocation
import QtPositioning

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView

Item {
    id:             _root
    anchors.fill:   parent
    visible:        proximityValues.telemetryAvailable

    property var    vehicle     ///< Vehicle object, undefined for ADSB vehicle
    property real   range:  20   ///< Default 6m view

    property real   _minlength:    Math.min(_root.width,_root.height)
    property real   _minRadius:    Math.min(_root.width,_root.height) / 4
    property real   _ratio:        (_minRadius / 2) / _root.range
    property real   _warningDistance: 10
    property real   _maxRange:        50

    ProximityRadarValues {
        id:                     proximityValues
        vehicle:                _root.vehicle
        onRotationValueChanged: _sectorViewEllipsoid.requestPaint()
    }

    Canvas{
        id:             _sectorViewEllipsoid
        anchors.fill:   _root
        opacity:        0.4

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.translate(width/2, height/2)
            //ctx.strokeStyle = Qt.rgba(1, 1, 0, 1);
            ctx.lineWidth = width/50;
            ctx.scale(_root.width  / _minlength, (_root.height / 3) / _minlength);
            ctx.rotate(-Math.PI/2 - Math.PI/8);
            for (var i=0; i<proximityValues.rgRotationValues.length; i++) {
                var rotationValue = proximityValues.rgRotationValues[i]
                if (rotationValue < _maxRange) {
                    var warningColor;
                    if (rotationValue < _warningDistance) { warningColor = Qt.rgba(1, 0, 0, 1) }
                    else if (rotationValue >= _warningDistance) {warningColor = Qt.rgba(1, 1, 0, 1) }
                    if (rotationValue > range) { rotationValue = range; }
                    // if (!isNaN(rotationValue)) {
                    //     var a=Math.PI/4 * i;
                    //     ctx.beginPath();
                    //     ctx.arc(0, 0, _minRadius + (rotationValue * _ratio), 0 + a + Math.PI/50, Math.PI/4 + a - Math.PI/50, false);
                    //     ctx.stroke();
                    // }
                    if (!isNaN(rotationValue)) {
                        var a=Math.PI/4 * i;
                        // 바깥쪽(장애물 쪽) 모서리가 가장 짙고 중심으로 갈수록 투명해지도록 구성.
                        // 끝 반지름을 부채꼴 바깥 경계(장애물 반지름)에 맞춰, 그 지점에 색이 몰린다.
                        var gradient = ctx.createRadialGradient(0, 0, 0, 0, 0, _minRadius + (rotationValue * _ratio));
                        gradient.addColorStop(0, "transparent");    // 중심(안쪽) = 투명
                        gradient.addColorStop(0.85, "transparent");
                        gradient.addColorStop(1, warningColor);     // 바깥쪽 = 짙게
                        ctx.beginPath();
                        //ctx.arc(0, 0, proximityItem._minRadius + (rotationValue * proximityItem._ratio), 0 + a + Math.PI/50, Math.PI/4 + a - Math.PI/50, false);
                        //ctx.stroke();
                        ctx.moveTo(0,0);
                        ctx.arc(0,0, _minRadius + (rotationValue * _ratio), a + Math.PI/50, Math.PI/4 + a - Math.PI/50);
                        ctx.lineTo((_root.width / 4) * Math.cos(Math.PI/4 + a - Math.PI/50), (_root.width / 4) * Math.sin(Math.PI/4 + a - Math.PI/50));
                        ctx.arc(0,0, (_root.width / 4), Math.PI/4 + a - Math.PI/50, a + Math.PI/50, true);
                        //ctx.lineTo(proximityItem.range * Math.cos(Math.PI/4 + a - Math.PI/50), proximityItem.range * Math.sin(Math.PI/4 + a - Math.PI/50));
                        ctx.closePath();
                        ctx.fillStyle = gradient;
                        ctx.fill();
                    }
                }
            }
        }
    }

    Item {
        anchors.fill: parent

        Repeater{
            model: proximityValues.rgRotationValues.length

            Rectangle {
                x:          (_sectorViewEllipsoid.width / 2) - (width / 2)
                y:          (_sectorViewEllipsoid.height / 2) - (height / 2)
                visible:    !isNaN(proximityValues.rgRotationValues[index]) && (proximityValues.rgRotationValues[index] < _root.range + 1)
                color:      "transparent"
                width:      proximityValueLabel.width * 1.4
                height:     proximityValueLabel.height * 3

                QGCLabel{
                    id:                 proximityValueLabel
                    text:               proximityValues.rgRotationValueStrings[index]
                    font.bold:          true

                    transform: Scale {
                        origin.y:       proximityValueLabel.height / 2
                        yScale:         _minlength / (_root.height / 3)
                    }
                }
                transform: Translate {
                    property real prxValues: proximityValues.rgRotationValues[index] > range ? range : proximityValues.rgRotationValues[index]
                    x: Math.cos(-Math.PI/2 + Math.PI/4 * index) * ((_minRadius * 1.1) + (prxValues * _ratio))
                    y: Math.sin(-Math.PI/2 + Math.PI/4 * index) * ((_minRadius * 1.1) + (prxValues * _ratio))
                }
            }
        }

        transform: Scale {
            origin.x:       _sectorViewEllipsoid.width / 2
            origin.y:       _sectorViewEllipsoid.height / 2
            xScale:         _root.width  / _minlength
            yScale:         _root.height / 3 / _minlength
        }
    }
}
