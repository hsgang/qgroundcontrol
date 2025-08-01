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

import QGroundControl
import QGroundControl.ScreenTools

import QGroundControl.Controls
import QGroundControl.FlightMap

MapQuickItem {
    property color  arrowColor:     "white"
    property var    fromCoord:      QtPositioning.coordinate()
    property var    toCoord:        QtPositioning.coordinate()
    property int    arrowPosition:  1 ///< 1: first quarter, 2: halfway, 3: last quarter

    property var    _map:           parent
    property real   _arrowSize:     ScreenTools.defaultFontPixelHeight
    property real   _arrowHeading:  0

    function _updateArrowDetails() {
        if (fromCoord && fromCoord.isValid && toCoord && toCoord.isValid) {
            var lineDistanceQuarter = fromCoord.distanceTo(toCoord) / 4
            coordinate = fromCoord.atDistanceAndAzimuth(lineDistanceQuarter * arrowPosition, fromCoord.azimuthTo(toCoord))
            _arrowHeading = coordinate.azimuthTo(toCoord) // Account for changing bearing along great circle path
        } else {
            coordinate = QtPositioning.coordinate()
            _arrowHeading = 0
        }
    }

    onFromCoordChanged: _updateArrowDetails()
    onToCoordChanged:   _updateArrowDetails()

    sourceItem: Canvas {
        x:      -_arrowSize
        y:      0
        width:  _arrowSize * 2
        height: _arrowSize

        onPaint: {
            var ctx = getContext("2d");
            ctx.lineWidth = 3
            ctx.strokeStyle = arrowColor
            ctx.beginPath();
            ctx.moveTo(_arrowSize, 0);
            ctx.lineTo(_arrowSize * 2, _arrowSize * 1.5)
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(_arrowSize, 0);
            ctx.lineTo(0, _arrowSize * 1.5)
            ctx.stroke();
        }

        transform: Rotation {
            origin.x:   width / 2
            origin.y:   0
            angle:      _arrowHeading
        }
    }
}
