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

    property real _defaultSize: ScreenTools.defaultFontPixelHeight * (10)
    property real _sizeRatio:   ScreenTools.isTinyScreen ? (size / _defaultSize) * 0.5 : size / _defaultSize
    property int  _fontSize:    ScreenTools.defaultFontPointSize * _sizeRatio

    property bool _haveGimbal:  vehicle.gimbalData
    property real _gimbalYaw:   vehicle ? vehicle.gimbalYaw.toFixed(1) : 0
    property real _gimbalPitch: vehicle ? vehicle.gimbalPitch.toFixed(1) : 0

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

    Image {
        id:                     homePointer
        width:                  size * 0.1
        source:                 isHeadingHomeOK()  ? "/qmlimages/Home.svg" : ""
        mipmap:                 true
        fillMode:               Image.PreserveAspectFit
        anchors.centerIn:   	parent
        sourceSize.width:       width
        layer {
            enabled: true
            effect: ColorOverlay {
                color: qgcPal.alertBackground
            }
        }

        transform: Translate {
            property double _angle: isNoseUpLocked()?-_heading+_headingToHome:_headingToHome
            x: size/2.2 * Math.sin((_angle)*(3.14/180))
            y: - size/2.2 * Math.cos((_angle)*(3.14/180))
        }
    }

    Image {
            id:                 gimbalSight
            visible:            _haveGimbal & _gimbalPitch >= -85
            anchors { verticalCenter: root.verticalCenter; horizontalCenter: parent.horizontalCenter }
            source:             "/qmlimages/gimbalSight.svg"
            mipmap:             true
            width:              parent.width * 0.6
            sourceSize.width:   width
            antialiasing:       true
            fillMode:           Image.PreserveAspectFit

            transform: Rotation {
                origin.x:       gimbalSight.width / 2
                origin.y:       gimbalSight.height / 2
                angle:          isNoseUpLocked() ? _gimbalYaw : _heading + _gimbalYaw
            }
    }

    Image {
            id:                 vehicleHeadingDial
            anchors { verticalCenter: root.verticalCenter; horizontalCenter: parent.horizontalCenter }
            source:             "/qmlimages/vehicleArrowOpaque.svg"
            mipmap:             true
            width:              parent.width * 0.2
            sourceSize.width:   width
            antialiasing:       true
            fillMode:           Image.PreserveAspectFit
//            layer {
//                enabled: true
//                effect: ColorOverlay {
//                    color: qgcPal.text
//                }
//            }

            transform: Rotation {
                origin.x:       vehicleHeadingDial.width / 2
                origin.y:       vehicleHeadingDial.height / 2
                angle:          isNoseUpLocked() ? 0 : _heading
            }
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

    Rectangle {
        anchors.horizontalCenter: vehicleHeadingDial.horizontalCenter
        anchors.top:   vehicleHeadingDial.bottom
        anchors.topMargin:  size * 0.05
        width:              size * 0.20
        height:             size * 0.12
        border.color:       qgcPal.text
        color:              "transparent"
        opacity:            0.65
        radius:             height * 0.1

        QGCLabel {
            text:               _headingString3
            font.family:        vehicle ? ScreenTools.demiboldFontFamily : ScreenTools.normalFontFamily
            font.pointSize:     _fontSize < 8 ? 8 : _fontSize;
            color:              qgcPal.text
            anchors.centerIn:   parent

            property string _headingString: vehicle ? _heading.toFixed(0) : "OFF"
            property string _headingString2: _headingString.length === 1 ? "0" + _headingString : _headingString
            property string _headingString3: _headingString2.length === 2 ? "0" + _headingString2 : _headingString2
        }
    }



    Image {
        id: rollDial
        anchors { bottom: root.verticalCenter; horizontalCenter: parent.horizontalCenter }
        source:             "/qmlimages/rollDialWhite.svg"
        mipmap:             true
        width:              parent.width * 0.7
        sourceSize.width:   width
        fillMode:           Image.PreserveAspectFit

        ColorOverlay {
            anchors.fill:       rollDial
            source:             rollDial
            color:              qgcPal.colorGreen
        }

        transform: Rotation {
            origin.x:       rollDial.width / 2
            origin.y:       rollDial.height
            angle:          -_rollAngle
        }
    }

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

    QGCPitchIndicator {
        id:                 pitchIndicator
        anchors.verticalCenter: parent.verticalCenter
        visible:            showPitch
        pitchAngle:         _pitchAngle
        rollAngle:          _rollAngle
        color:              Qt.rgba(0,0,0,0)
        size:               ScreenTools.defaultFontPixelHeight * (5)
    }

//    Image {
//        id:                 cOGPointer
//        source:             isCOGAngleOK() ? "/qmlimages/cOGPointer.svg" : ""
//        mipmap:             true
//        fillMode:           Image.PreserveAspectFit
//        anchors.fill:       parent
//        sourceSize.height:  parent.height

//        transform: Rotation {
//            property var _angle:isNoseUpLocked() ? _courseOverGround-_heading : _courseOverGround
//            origin.x:       cOGPointer.width  / 2
//            origin.y:       cOGPointer.height / 2
//            angle:         _angle
//        }
//    }

//    Image {
//        id:                 nextWPPointer
//        source:             isHeadingToNextWPOK() ? "/qmlimages/compassDottedLine.svg":""
//        mipmap:             true
//        fillMode:           Image.PreserveAspectFit
//        anchors.fill:       parent
//        sourceSize.height:  parent.height

//        transform: Rotation {
//            property var _angle: isNoseUpLocked()?_headingToNextWP-_heading:_headingToNextWP
//            origin.x:       cOGPointer.width  / 2
//            origin.y:       cOGPointer.height / 2
//            angle:         _angle
//        }
//    }

}
