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
import QGroundControl.Palette

/// The MissionLineView control is used to add lines between mission items
MapItemView {
    property bool showSpecialVisual: false
    delegate: MapPolyline {
        line.width: 1
        // Note: Special visuals for ROI are hacked out for now since they are not working correctly
        line.color: _terrainCollision ?
                        "red" :
                        (false/*showSpecialVisual*/ ? "green" : QGroundControl.globalPalette.mapMissionTrajectory)
        z:          QGroundControl.zOrderWaypointLines
        path:       object && object.coordinate1.isValid && object.coordinate2.isValid ? [ object.coordinate1, object.coordinate2 ] : []

        property bool _terrainCollision:    object && object.terrainCollision
        property bool _showSpecialVisual:   object && showSpecialVisual && object.specialVisual
    }
}
