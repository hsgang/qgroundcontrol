/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


/**
 * @file
 *   @brief QGC Attitude Widget
 *   @author Gus Grubba <gus@auterion.com>
 */

import QtQuick              2.3
import QtGraphicalEffects   1.0

import QGroundControl              1.0
import QGroundControl.Controls     1.0
import QGroundControl.ScreenTools  1.0
import QGroundControl.Vehicle      1.0
import QGroundControl.Palette      1.0

Item {
    id: root

//    property bool active:       false  ///< true: actively connected to data provider, false: show inactive control
//    property real rollAngle :   _defaultRollAngle
//    property real pitchAngle:   _defaultPitchAngle

//    readonly property real _defaultRollAngle:   0
//    readonly property real _defaultPitchAngle:  0

//    property real _rollAngle:   active ? rollAngle : _defaultRollAngle
//    property real _pitchAngle:  active ? pitchAngle : _defaultPitchAngle

    //
    property bool showPitch:    true
    property var  vehicle:      null
    property real size
    property bool showHeading:  false

    property real _rollAngle:   vehicle ? vehicle.roll.rawValue  : 0
    property real _pitchAngle:  vehicle ? vehicle.pitch.rawValue : 0

    width:  size
    height: size

    anchors.centerIn: parent

    function isNoseUpLocked(){
        return _lockNoseUpCompass
    }

    readonly property bool _lockNoseUpCompass:        QGroundControl.settingsManager.flyViewSettings.lockNoseUpCompass.value

    Image {
        id: rollDial
        anchors { bottom: root.verticalCenter; horizontalCenter: parent.horizontalCenter }
        source:             "/qmlimages/rollDialWhite.svg"
        mipmap:             true
        width:              parent.width
        sourceSize.width:   width
        fillMode:           Image.PreserveAspectFit
        transform: Rotation {
            origin.x:       rollDial.width / 2
            origin.y:       rollDial.height
            angle:          -_rollAngle
        }
    }

    Image {
        id: pointer
        anchors { bottom: root.verticalCenter; horizontalCenter: parent.horizontalCenter }
        source:             "/qmlimages/rollPointerWhite.svg"
        mipmap:             true
        width:              rollDial.width
        sourceSize.width:   width
        fillMode:           Image.PreserveAspectFit
    }

    Image {
        id:                 crossHair
        anchors.centerIn:   parent
        source:             "/qmlimages/crossHair.svg"
        mipmap:             true
        width:              parent.width
        sourceSize.width:   width
        //color:              qgcPal.text
        fillMode:           Image.PreserveAspectFit
    }

    QGCPitchIndicator {
        id:                 pitchIndicator
        anchors.verticalCenter: parent.verticalCenter
        visible:            showPitch
        pitchAngle:         _pitchAngle
        rollAngle:          _rollAngle
        color:              Qt.rgba(0,0,0,0)
        size:               ScreenTools.defaultFontPixelHeight * (5)
    }

    QGCColoredImage {
        id:                 compassDial
        source:             "/qmlimages/compassInstrumentDial.svg"
        mipmap:             true
        fillMode:           Image.PreserveAspectFit
        anchors.fill:       parent
        sourceSize.height:  parent.height
        color:              qgcPal.text
        transform: Rotation {
            origin.x:       compassDial.width  / 2
            origin.y:       compassDial.height / 2
            angle:          isNoseUpLocked()?-_heading:0
        }
    }

}
