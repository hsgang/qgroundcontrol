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

    property bool showPitch:    true
    property var  vehicle:      null
    property real size:         _defaultSize

    //property bool showHeading:  false

    property real _rollAngle:   vehicle ? vehicle.roll.rawValue  : 0
    property real _pitchAngle:  vehicle ? vehicle.pitch.rawValue : 0

    property real _heading:             vehicle ? vehicle.heading.rawValue : 0
    property real _headingToHome:       vehicle ? vehicle.headingToHome.rawValue : 0

    width:  size
    height: size

    property bool usedByMultipleVehicleList:  false

    anchors.centerIn: parent

    function isNoseUpLocked(){
        return _lockNoseUpCompass
    }

    function isHeadingHomeOK(){
        return vehicle && _showAdditionalIndicatorsCompass && !isNaN(_headingToHome)
    }

    readonly property bool _showAdditionalIndicatorsCompass:     QGroundControl.settingsManager.flyViewSettings.showAdditionalIndicatorsCompass.value && !usedByMultipleVehicleList
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
        visible: _lockNoseUpCompass
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

    Image {
        id:                     homePointer
        width:                  size * 0.1
        source:                 isHeadingHomeOK()  ? "/qmlimages/Home.svg" : ""
        mipmap:                 true
        fillMode:               Image.PreserveAspectFit
        anchors.centerIn:   	parent
        sourceSize.width:       width

        transform: Translate {
            property double _angle: isNoseUpLocked()?-_heading+_headingToHome:_headingToHome
            x: size/2.3 * Math.sin((_angle)*(3.14/180))
            y: - size/2.3 * Math.cos((_angle)*(3.14/180))
        }
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
