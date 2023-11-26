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
    property real _distanceToHome:      vehicle ? vehicle.distanceToHome.rawValue : 0
    property real _distanceToNextWP:    vehicle ? vehicle.distanceToNextWP.rawValue : 0
    property real _groundSpeed:         vehicle ? vehicle.groundSpeed.rawValue : 0
    property real _headingToNextWP:     vehicle ? vehicle.headingToNextWP.rawValue : 0
    property real _courseOverGround:    vehicle ? vehicle.gps.courseOverGround.rawValue : 0
    property real _windDir:             vehicle ? vehicle.wind.direction.rawValue : 0
    property real _windSpd:             vehicle ? vehicle.wind.speed.rawValue : 0

    property real _defaultSize: ScreenTools.defaultFontPixelHeight * (10)
    property real _sizeRatio:   ScreenTools.isTinyScreen ? (size / _defaultSize) * 0.5 : size / _defaultSize
    property int  _fontSize:    ScreenTools.defaultFontPointSize * _sizeRatio

    property bool _haveGimbal:  vehicle ? vehicle.gimbalData : false
    property real _gimbalYaw:   vehicle ? vehicle.gimbalYaw.toFixed(1) : 0
    property real _gimbalPitch: vehicle ? vehicle.gimbalPitch.toFixed(1) : 0

    property string _distanceToHomeText:    vehicle ? _distanceToHome.toFixed(0) : "--"
    property string _distanceToNextWPText:  vehicle ? _distanceToNextWP.toFixed(0) : "--"
    property string _windSpdText:           vehicle ? _windSpd.toFixed(1) : "0.0"

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

    function isDistanceToNextWPOK(){
        return vehicle && _showAdditionalIndicatorsCompass && !isNaN(_distanceToNextWP)
    }

    function isWindVaneOK(){
        return vehicle && _showAdditionalIndicatorsCompass && !isNaN(_windDir)
    }

    function isNoseUpLocked(){
        return _lockNoseUpCompass
    }

    function isHeadingHomeOK(){
        return vehicle && _showAdditionalIndicatorsCompass && !isNaN(_headingToHome)
    }

    readonly property bool _showAdditionalIndicatorsCompass:     QGroundControl.settingsManager.flyViewSettings.showAdditionalIndicatorsCompass.value && !usedByMultipleVehicleList
    readonly property bool _showAttitudeHUD:            QGroundControl.settingsManager.flyViewSettings.showAttitudeHUD.value && !usedByMultipleVehicleList
    readonly property bool _lockNoseUpCompass:        QGroundControl.settingsManager.flyViewSettings.lockNoseUpCompass.value

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

//    Image {
//        id:                     homePointer
//        width:                  size * 0.1
//        source:                 isHeadingHomeOK() ? "/qmlimages/Home.svg" : ""
//        mipmap:                 true
//        fillMode:               Image.PreserveAspectFit
//        anchors.centerIn:   	parent
//        sourceSize.width:       width
//        layer {
//            enabled: true
//            effect: ColorOverlay {
//                color: qgcPal.alertBackground
//            }
//        }

    Rectangle {
        id:                 homePointer
        visible:            isHeadingHomeOK()
        width:              size * 0.11
        height:             width
        radius:             width * 0.5
        anchors.centerIn:   parent
        color:              qgcPal.text //"transparent"
        border.color:       qgcPal.alertBackground

        QGCLabel {
            text:               "H"
            font.pointSize:     _fontSize < 10 ? 10 : _fontSize;
            font.family:        ScreenTools.demiboldFontFamily
            font.bold:          true
            color:              qgcPal.alertBackground
            anchors.centerIn:   parent
        }

        transform: Translate {
            property double _angle: isNoseUpLocked()?-_heading+_headingToHome:_headingToHome
            x: size/2.1 * Math.sin((_angle)*(3.14/180))
            y: - size/2.1 * Math.cos((_angle)*(3.14/180))
        }
    }

    Rectangle {
        width:                      distanceToHomeText.width + (size * 0.05)
        height:                     size * 0.12
        border.color:               qgcPal.alertBackground
        color:                      "transparent"
        radius:                     height * 0.1
        visible:                    isHeadingHomeOK()
        anchors.centerIn:           parent

        QGCLabel {
            id:                 distanceToHomeText
            text:               _distanceToHomeText
            font.pointSize:     _fontSize < 8 ? 8 : _fontSize;
            font.family:        ScreenTools.demiboldFontFamily
            color:              qgcPal.text
            anchors.centerIn:   parent
        }

        transform: Translate {
            property double _angle: isNoseUpLocked() ? -_heading + _headingToHome : _headingToHome
            x: size/3.1 * Math.sin((_angle)*(3.14/180))
            y: - size/3.1 * Math.cos((_angle)*(3.14/180))
        }
    }


//    Image {
//            id:                 gimbalSight
//            visible:            true //_haveGimbal & _gimbalPitch >= -85
//            anchors { verticalCenter: root.verticalCenter; horizontalCenter: parent.horizontalCenter }
//            source:             "/qmlimages/gimbalSight.svg"
//            mipmap:             true
//            width:              parent.width * 0.6
//            sourceSize.width:   width
//            antialiasing:       true
//            fillMode:           Image.PreserveAspectFit

    Rectangle {
        id:             gimbalSight
        visible:        _haveGimbal & _gimbalPitch >= -85
        anchors { verticalCenter: parent.verticalCenter; horizontalCenter: parent.horizontalCenter }
        width:          parent.width * 0.6
        height:         width
        color:          "transparent"
        //border.color:   qgcPal.text

        Canvas {
            id: triangleCanvas
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d");

                // 그라데이션 생성
                var gradient = ctx.createLinearGradient(triangleCanvas.width / 2, 0, triangleCanvas.width / 2, triangleCanvas.height);
                gradient.addColorStop(0, "transparent");
                gradient.addColorStop(0.5, qgcPal.colorGreen);

                // 삼각형 그리기
                ctx.beginPath();
                ctx.moveTo(triangleCanvas.width / 4, 0);
                ctx.lineTo((triangleCanvas.width / 4) * 3, 0);
                ctx.lineTo(triangleCanvas.width / 2, triangleCanvas.height / 2);
                ctx.closePath();

                // 그라데이션 적용
                ctx.fillStyle = gradient;
                ctx.fill();
            }
        }

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

        layer {
            enabled: true
            effect: ColorOverlay {
                color: qgcPal.text
            }
        }

        transform: Rotation {
            origin.x:       vehicleHeadingDial.width / 2
            origin.y:       vehicleHeadingDial.height / 2
            angle:          isNoseUpLocked() ? 0 : _heading
        }
    }

    Image {
        id:                 rollDial
        anchors { bottom: root.verticalCenter; horizontalCenter: parent.horizontalCenter }
        visible:            _showAttitudeHUD
        source:             "/qmlimages/rollDialWhite.svg"
        mipmap:             true
        width:              parent.width * 0.7
        sourceSize.width:   width
        fillMode:           Image.PreserveAspectFit

        layer {
            enabled: true
            effect: ColorOverlay {
                color: qgcPal.textHighlight
            }
        }

        transform: Rotation {
            origin.x:       rollDial.width / 2
            origin.y:       rollDial.height
            angle:          -_rollAngle
        }
    }

//    ColorOverlay {
//        anchors.fill:       rollDial
//        source:             rollDial
//        color:              qgcPal.textHighlight
//        visible:            rollDial.visible
//    }

//    Image {
//        id:                 pointer
//        visible:            _lockNoseUpCompass
//        anchors { bottom: root.verticalCenter; horizontalCenter: parent.horizontalCenter }
//        source:             "/qmlimages/rollPointerWhite.svg"
//        mipmap:             true
//        width:              rollDial.width
//        sourceSize.width:   width
//        fillMode:           Image.PreserveAspectFit
//    }


    Image {
        id:                 crossHair
        visible:            _showAttitudeHUD
        anchors.centerIn:   parent
        source:             "/qmlimages/crossHair.svg"
        mipmap:             true
        width:              parent.width * 0.8
        sourceSize.width:   width
        //color:              qgcPal.text
        fillMode:           Image.PreserveAspectFit
    }

    ColorOverlay {
        anchors.fill:       crossHair
        source:             crossHair
        color:              qgcPal.textHighlight
        visible:            crossHair.visible
    }

    QGCPitchIndicator {
        id:                 pitchIndicator
        anchors.verticalCenter: parent.verticalCenter
        visible:            _showAttitudeHUD //showPitch
        pitchAngle:         _pitchAngle
        rollAngle:          _rollAngle
        color:              Qt.rgba(0,0,0,0)
        size:               ScreenTools.defaultFontPixelHeight * (5)
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

    Rectangle {
        id:                 nextWPPointer
        visible:            isHeadingToNextWPOK()
        width:              wpText.width + (size * 0.02)
        height:             size * 0.11
        radius:             height * 0.1
        anchors.centerIn:   parent
        color:              qgcPal.text //"transparent"
        border.color:       qgcPal.buttonHighlight

        QGCLabel {
            id:                 wpText
            text:               "WP"
            font.pointSize:     _fontSize < 10 ? 10 : _fontSize;
            font.family:        ScreenTools.demiboldFontFamily
            font.bold:          true
            color:              qgcPal.buttonHighlight
            anchors.centerIn:   parent
        }

        transform: Translate {
            property double _angle: isNoseUpLocked() ? _headingToNextWP-_heading : _headingToNextWP
            x: size/2.1 * Math.sin((_angle)*(3.14/180))
            y: - size/2.1 * Math.cos((_angle)*(3.14/180))
        }
    }

    Rectangle {
        width:                      distanceToNextWPText.width + (size * 0.05)
        height:                     size * 0.12
        border.color:               qgcPal.buttonHighlight
        color:                      "transparent"
        radius:                     height * 0.1
        visible:                    isDistanceToNextWPOK()
        anchors.centerIn:           parent

        QGCLabel {
            id:                 distanceToNextWPText
            text:               _distanceToNextWPText
            font.pointSize:     _fontSize < 8 ? 8 : _fontSize;
            font.family:        ScreenTools.demiboldFontFamily
            color:              qgcPal.text
            anchors.centerIn:   parent
        }

        transform: Translate {
            property double _angle: isNoseUpLocked() ? _headingToNextWP-_heading : _headingToNextWP
            x: size/3.1 * Math.sin((_angle)*(3.14/180))
            y: - size/3.1 * Math.cos((_angle)*(3.14/180))
        }
    }

    Image {
        id:                 windVane
        source:             isWindVaneOK() ? "/qmlimages/windVaneArrow.svg" : ""
        mipmap:             true
        fillMode:           Image.PreserveAspectFit
        anchors.fill:       parent
        sourceSize.height:  parent.height

        transform: Rotation {
            property var _angle: isNoseUpLocked() ? _windDir - _heading : _windDir
            origin.x:       cOGPointer.width  / 2
            origin.y:       cOGPointer.height / 2
            angle:         _angle
        }
    }

    Rectangle {
        width:                      windVaneText.width + (size * 0.05)
        height:                     size * 0.12
        border.color:               qgcPal.buttonHighlight
        color:                      "transparent"
        radius:                     height * 0.1
        visible:                    isWindVaneOK()
        anchors.centerIn:           parent

        QGCLabel {
            id:                 windVaneText
            text:               _windSpdText
            font.pointSize:     _fontSize < 8 ? 8 : _fontSize;
            font.family:        ScreenTools.demiboldFontFamily
            color:              qgcPal.text
            anchors.centerIn:   parent
        }

        transform: Translate {
            property double _angle: isNoseUpLocked() ? _windDir - _heading : _windDir
            x: size/1.85 * Math.sin((_angle)*(3.14/180))
            y: - size/1.85 * Math.cos((_angle)*(3.14/180))
        }
    }

}
