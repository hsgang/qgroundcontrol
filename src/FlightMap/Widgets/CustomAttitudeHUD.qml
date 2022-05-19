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
    property real _groundSpeed:         vehicle ? vehicle.groundSpeed.rawValue : 0
    property real _headingToNextWP:     vehicle ? vehicle.headingToNextWP.rawValue : 0
    property real _courseOverGround:    _activeVehicle ? _activeVehicle.gps.courseOverGround.rawValue : 0

    width:  size
    height: size

    property bool usedByMultipleVehicleList:  false

    anchors.centerIn: parent

    function isCOGAngleOK(){
        if(_groundSpeed < 0.3){
            return false
        }
        else{
            return vehicle && _showAdditionalIndicatorsCompass
        }
    }

    function isHeadingToNextWPOK(){
        return vehicle && _showAdditionalIndicatorsCompass && !isNaN(_headingToNextWP)
    }

    function isNoseUpLocked(){
        return _lockNoseUpCompass
    }

    function isHeadingHomeOK(){
        return vehicle && _showAdditionalIndicatorsCompass && !isNaN(_headingToHome)
    }

    readonly property bool _showAdditionalIndicatorsCompass:     QGroundControl.settingsManager.flyViewSettings.showAdditionalIndicatorsCompass.value && !usedByMultipleVehicleList
    readonly property bool _lockNoseUpCompass:        QGroundControl.settingsManager.flyViewSettings.lockNoseUpCompass.value

//    Image {
//        id: rollDial
//        anchors { bottom: root.verticalCenter; horizontalCenter: parent.horizontalCenter }
//        source:             "/qmlimages/rollDialWhite.svg"
//        mipmap:             true
//        width:              parent.width * 0.7
//        sourceSize.width:   width
//        fillMode:           Image.PreserveAspectFit

//        ColorOverlay {
//            anchors.fill:       rollDial
//            source:             rollDial
//            color:              qgcPal.colorGreen
//        }

//        transform: Rotation {
//            origin.x:       rollDial.width / 2
//            origin.y:       rollDial.height
//            angle:          -_rollAngle
//        }
//    }

//    Image {
//        id: pointer
//        visible: _lockNoseUpCompass
//        anchors { bottom: root.verticalCenter; horizontalCenter: parent.horizontalCenter }
//        source:             "/qmlimages/rollPointerWhite.svg"
//        mipmap:             true
//        width:              rollDial.width
//        sourceSize.width:   width
//        fillMode:           Image.PreserveAspectFit
//    }


//    Image {
//        id:                 crossHair
//        anchors.centerIn:   parent
//        source:             "/qmlimages/crossHair.svg"
//        mipmap:             true
//        width:              parent.width * 0.8
//        sourceSize.width:   width
//        //color:              qgcPal.text
//        fillMode:           Image.PreserveAspectFit

//        ColorOverlay {
//            anchors.fill:       crossHair
//            source:             crossHair
//            color:              qgcPal.colorGreen
//        }
//    }

    Image {
        id:                     homePointer
        width:                  size * 0.1
        source:                 isHeadingHomeOK()  ? "/qmlimages/Home.svg" : ""
        mipmap:                 true
        fillMode:               Image.PreserveAspectFit
        anchors.centerIn:   	parent
        sourceSize.width:       width

        ColorOverlay {
            anchors.fill:       homePointer
            source:             homePointer
            color:              qgcPal.alertBackground
        }

        transform: Translate {
            property double _angle: isNoseUpLocked()?-_heading+_headingToHome:_headingToHome
            x: size/1.9 * Math.sin((_angle)*(3.14/180))
            y: - size/1.9 * Math.cos((_angle)*(3.14/180))
        }
    }

    Image {
        id:                 vehicleHeadingDial
        anchors { verticalCenter: root.verticalCenter; horizontalCenter: parent.horizontalCenter }
        source:             "/qmlimages/vehicleArrowOpaque.svg"
        mipmap:             true
        width:              parent.width * 0.2
        sourceSize.width:   width
        //fillMode:           Image.PreserveAspectFit

        ColorOverlay {
            anchors.fill:       vehicleHeadingDial
            source:             vehicleHeadingDial
            color:              qgcPal.text
        }

        transform: Rotation {
            origin.x:       vehicleHeadingDial.width / 2
            origin.y:       vehicleHeadingDial.height / 2
            angle:          isNoseUpLocked() ? 0 : _heading
        }
    }

//    QGCPitchIndicator {
//        id:                 pitchIndicator
//        anchors.verticalCenter: parent.verticalCenter
//        visible:            showPitch
//        pitchAngle:         _pitchAngle
//        rollAngle:          _rollAngle
//        color:              Qt.rgba(0,0,0,0)
//        size:               ScreenTools.defaultFontPixelHeight * (5)
//    }

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

    Image {
        id:                 cOGPointer
        source:             isCOGAngleOK() ? "/qmlimages/cOGPointer.svg" : ""
        mipmap:             true
        fillMode:           Image.PreserveAspectFit
        anchors.fill:       parent
        sourceSize.height:  parent.height

        transform: Rotation {
            property var _angle:isNoseUpLocked() ? _courseOverGround-_heading : _courseOverGround
            origin.x:       cOGPointer.width  / 2
            origin.y:       cOGPointer.height / 2
            angle:         _angle
        }
    }

    Image {
        id:                 nextWPPointer
        source:             isHeadingToNextWPOK() ? "/qmlimages/compassDottedLine.svg":""
        mipmap:             true
        fillMode:           Image.PreserveAspectFit
        anchors.fill:       parent
        sourceSize.height:  parent.height

        transform: Rotation {
            property var _angle: isNoseUpLocked()?_headingToNextWP-_heading:_headingToNextWP
            origin.x:       cOGPointer.width  / 2
            origin.y:       cOGPointer.height / 2
            angle:         _angle
        }
    }
}
