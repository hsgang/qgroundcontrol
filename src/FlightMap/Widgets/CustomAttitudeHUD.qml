import QtQuick              2.3
import QtGraphicalEffects   1.0

import QGroundControl              1.0
import QGroundControl.Controls     1.0
import QGroundControl.ScreenTools  1.0
import QGroundControl.Vehicle      1.0
import QGroundControl.Palette      1.0
import QGroundControl.FlightDisplay 1.0


// Rectangle {
//     id:     root
//     width:  size
//     height: size
//     radius: width / 2
//     color:  qgcPal.window

//     property real size:                         _defaultSize
//     property var  vehicle:                      null
//     property bool usedByMultipleVehicleList:    false

//     property real _defaultSize:                 ScreenTools.defaultFontPixelHeight * (10)
//     property real _sizeRatio:                   ScreenTools.isTinyScreen ? (size / _defaultSize) * 0.5 : size / _defaultSize
//     property int  _fontSize:                    ScreenTools.defaultFontPointSize * _sizeRatio < 8 ? 8 : ScreenTools.defaultFontPointSize * _sizeRatio
//     property real _heading:                     vehicle ? vehicle.heading.rawValue : 0
//     property real _headingToHome:               vehicle ? vehicle.headingToHome.rawValue : 0
//     property real _groundSpeed:                 vehicle ? vehicle.groundSpeed.rawValue : 0
//     property real _headingToNextWP:             vehicle ? vehicle.headingToNextWP.rawValue : 0
//     property real _courseOverGround:            vehicle ? vehicle.gps.courseOverGround.rawValue : 0
//     property real _windDir:                     vehicle ? vehicle.wind.direction.rawValue : 0
//     property real _windSpd:                     vehicle ? vehicle.wind.speed.rawValue : 0
//     property real _distanceToHome:              vehicle ? vehicle.distanceToHome.rawValue : 0
//     property string _distanceToHomeText:        vehicle ? _distanceToHome.toFixed(0) : "--"
//     property real _distanceToNextWP:            vehicle ? vehicle.distanceToNextWP.rawValue : 0
//     property string _distanceToNextWPText:      vehicle ? _distanceToNextWP.toFixed(0) : "--"
//     property string _windSpdText:               vehicle ? _windSpd.toFixed(1) : "0.0"

//     property var  _flyViewSettings:             QGroundControl.settingsManager.flyViewSettings
//     property bool _showAdditionalIndicators:    _flyViewSettings.showAdditionalIndicatorsCompass.value && !usedByMultipleVehicleList
//     property bool _lockNoseUpCompass:           _flyViewSettings.lockNoseUpCompass.value

//     function showCOG(){
//         if (_groundSpeed < 0.5) {
//             return false
//         } else{
//             return vehicle && _showAdditionalIndicators
//         }
//     }

//     function showHeadingHome() {
//         return vehicle && _showAdditionalIndicators && !isNaN(_headingToHome)
//     }

//     function showHeadingToNextWP() {
//         return vehicle && _showAdditionalIndicators && !isNaN(_headingToNextWP)
//     }

//     function showWindVane() {
//         return vehicle && _showAdditionalIndicators && !isNaN(_windSpd)
//     }

//     function translateCenterToAngleX(radius, angle) {
//         return radius * Math.sin(angle * (Math.PI / 180))
//     }

//     function translateCenterToAngleY(radius, angle) {
//         return -radius * Math.cos(angle * (Math.PI / 180))
//     }

//     QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

//     Item {
//         id:             rotationParent
//         anchors.fill:   parent

//         transform: Rotation {
//             origin.x:       rotationParent.width  / 2
//             origin.y:       rotationParent.height / 2
//             angle:         _lockNoseUpCompass ? -_heading : 0
//         }

//         CompassDial {
//             anchors.fill: parent
//         }

//         CompassHeadingIndicator {
//             compassSize:    size
//             heading:        _heading
//         }

//         Image {
//             id:                 cogPointer
//             source:             "/qmlimages/cOGPointer.svg"
//             mipmap:             true
//             fillMode:           Image.PreserveAspectFit
//             anchors.fill:       parent
//             sourceSize.height:  parent.height
//             visible:            showCOG()

//             transform: Rotation {
//                 origin.x:   cogPointer.width  / 2
//                 origin.y:   cogPointer.height / 2
//                 angle:      _courseOverGround
//             }
//         }

//         // Launch location indicator
//         Rectangle {
//             width:              Math.max(label.contentWidth, label.contentHeight)
//             height:             width
//             //color:              qgcPal.mapIndicator
//             color:              qgcPal.alertBackground
//             border.color:       "black"
//             radius:             width / 2
//             anchors.centerIn:   parent
//             visible:            showHeadingHome()

//             QGCLabel {
//                 id:                 label
//                 text:               qsTr("L")
//                 font.bold:          true
//                 color:              "black" //qgcPal.text
//                 anchors.centerIn:   parent
//             }

//             transform: Translate {
//                 property double _angle: _headingToHome

//                 x: translateCenterToAngleX(parent.width / 2, _angle)
//                 y: translateCenterToAngleY(parent.height / 2, _angle)
//             }
//         }

//         // distance to home indicator
//         Rectangle {
//             width:                      distanceToHomeText.width + (size * 0.05)
//             height:                     size * 0.12
//             border.color:               qgcPal.alertBackground
//             color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5)
//             radius:                     height * 0.2
//             visible:                    showHeadingHome()
//             anchors.centerIn:           parent

//             QGCLabel {
//                 id:                 distanceToHomeText
//                 text:               _distanceToHomeText
//                 font.pointSize:     _fontSize < 8 ? 8 : _fontSize
//                 font.family:        ScreenTools.demiboldFontFamily
//                 color:              qgcPal.text
//                 anchors.centerIn:   parent
//             }

//             transform: Translate {
//                 property double _angle: _headingToHome
//                 x: translateCenterToAngleX(parent.width / 3.1, _angle) //size/3.1 * Math.sin((_angle)*(3.14/180))
//                 y: translateCenterToAngleY(parent.height / 3.1, _angle) //- size/3.1 * Math.cos((_angle)*(3.14/180))
//             }
//         }

//         Rectangle {
//             id:                 nextWPPointer
//             visible:            showHeadingToNextWP()
//             width:              Math.max(wpText.contentWidth, wpText.contentHeight) * 1.1 //wpText.width + (size * 0.02)
//             height:             width
//             radius:             height / 2
//             anchors.centerIn:   parent
//             color:              qgcPal.text //"transparent"
//             border.color:       qgcPal.mapIndicator//qgcPal.buttonHighlight

//             QGCLabel {
//                 id:                 wpText
//                 text:               "WP"
//                 font.pointSize:     _fontSize < 8 ? 8 : _fontSize
//                 font.family:        ScreenTools.demiboldFontFamily
//                 font.bold:          true
//                 color:              qgcPal.mapIndicator//qgcPal.buttonHighlight
//                 anchors.centerIn:   parent
//             }

//             transform: Translate {
//                 property double _angle: _headingToNextWP
//                 x: translateCenterToAngleX(parent.width / 2.1, _angle)//size/2.1 * Math.sin((_angle)*(3.14/180))
//                 y: translateCenterToAngleY(parent.height / 2.1, _angle)//- size/2.1 * Math.cos((_angle)*(3.14/180))
//             }
//         }

//         // distance to next WP indicator
//         Rectangle {
//             width:                      distanceToNextWPText.width + (size * 0.05)
//             height:                     size * 0.12
//             border.color:               qgcPal.mapIndicator//qgcPal.buttonHighlight
//             color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5)
//             radius:                     height * 0.2
//             visible:                    showHeadingToNextWP()
//             anchors.centerIn:           parent

//             QGCLabel {
//                 id:                 distanceToNextWPText
//                 text:               _distanceToNextWPText
//                 font.pointSize:     _fontSize < 8 ? 8 : _fontSize;
//                 font.family:        ScreenTools.demiboldFontFamily
//                 color:              qgcPal.text
//                 anchors.centerIn:   parent
//             }

//             transform: Translate {
//                 property double _angle: _headingToNextWP
//                 x: translateCenterToAngleX(parent.width / 3.1, _angle) //size/3.1 * Math.sin((_angle)*(3.14/180))
//                 y: translateCenterToAngleY(parent.height / 3.1, _angle) //- size/3.1 * Math.cos((_angle)*(3.14/180))
//             }
//         }

//         // windvane indicator
//         Image {
//             id:                 windVane
//             source:             showWindVane() ? "/qmlimages/windVaneArrow.svg" : ""
//             mipmap:             true
//             fillMode:           Image.PreserveAspectFit
//             anchors.fill:       parent
//             sourceSize.height:  parent.height

//             transform: Rotation {
//                 property double _angle: _windDir
//                 origin.x:       windVane.width  / 1.9
//                 origin.y:       windVane.height / 1.9
//                 angle:         _angle
//             }
//         }

//         // windvane indicator
//         Rectangle {
//             width:                      windVaneText.width + (size * 0.05)
//             height:                     size * 0.12
//             border.color:               qgcPal.colorGreen
//             color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5)
//             radius:                     height * 0.2
//             visible:                    showWindVane()
//             anchors.centerIn:           parent

//             QGCLabel {
//                 id:                 windVaneText
//                 text:               _windSpdText
//                 font.pointSize:     _fontSize < 8 ? 8 : _fontSize;
//                 font.family:        ScreenTools.demiboldFontFamily
//                 color:              qgcPal.text
//                 anchors.centerIn:   parent
//             }

//             transform: Translate {
//                 property double _angle: _windDir
//                 x: translateCenterToAngleX(parent.width / 1.82, _angle) //size/1.82 * Math.sin((_angle)*(3.14/180))
//                 y: translateCenterToAngleY(parent.height / 1.82, _angle)//- size/1.82 * Math.cos((_angle)*(3.14/180))
//             }
//         }

//         Item {
//             id:             proximityItem
//             anchors.fill:   parent
//             width:          parent.width
//             height:         parent.height

//             property real   range:  20//isNaN(proximityValues.maxDistance)   ///< Default 6m view

//             property real   _minlength:    Math.min(proximityItem.width,proximityItem.height)
//             property real   _minRadius:    Math.min(proximityItem.width,proximityItem.height) / 4
//             property real   _ratio:        (_minRadius / 2) / proximityItem.range
//             property real   _warningDistance: 10
//             property real   _maxRange:        50

//             ProximityRadarValues {
//                 id:                     proximityValues
//                 vehicle:                root.vehicle
//                 onRotationValueChanged: proximitySensors.requestPaint()
//             }

//             Canvas{
//                 id:                 proximitySensors
//                 anchors.fill:       proximityItem

//                 // transform: Rotation {
//                 //     origin.x:       parent.width  / 2
//                 //     origin.y:       parent.height / 2
//                 //     angle:          isNoseUpLocked() ? 0 : _heading
//                 // }

//                 onPaint: {
//                     var ctx = getContext("2d");
//                     ctx.reset();
//                     ctx.translate(width/2, height/2)
//                     ctx.lineWidth = width/30;
//                     ctx.rotate(-Math.PI/2 - Math.PI/8);
//                     for (var i=0; i<proximityValues.rgRotationValues.length; i++) {
//                         var rotationValue = proximityValues.rgRotationValues[i]
//                         if (rotationValue < proximityItem._maxRange) {
//                             var warningColor;
//                             if (rotationValue < proximityItem._warningDistance) { warningColor = Qt.rgba(1, 0, 0, 0.4) }
//                             else if (rotationValue >= proximityItem._warningDistance) { warningColor = Qt.rgba(1, 1, 0, 0.4) }
//                             if (rotationValue > proximityItem.range) { rotationValue = proximityItem.range; }
//                             if (!isNaN(rotationValue)) {
//                                 var a=Math.PI/4 * i;
//                                 var gradient = ctx.createRadialGradient(0, 0, proximityItem._minRadius + (rotationValue * proximityItem._ratio), 0, 0, (proximityItem.width / 2));
//                                 gradient.addColorStop(0, warningColor); // 내부부터 시작하는 색상
//                                 gradient.addColorStop(0.3, "transparent");
//                                 gradient.addColorStop(1, "transparent"); // 외부로 퍼지는 색상
//                                 ctx.beginPath();
//                                 //ctx.arc(0, 0, proximityItem._minRadius + (rotationValue * proximityItem._ratio), 0 + a + Math.PI/50, Math.PI/4 + a - Math.PI/50, false);
//                                 //ctx.stroke();
//                                 ctx.moveTo(0,0);
//                                 ctx.arc(0,0, proximityItem._minRadius + (rotationValue * proximityItem._ratio), a + Math.PI/50, Math.PI/4 + a - Math.PI/50);
//                                 ctx.lineTo((proximityItem.width / 2) * Math.cos(Math.PI/4 + a - Math.PI/50), (proximityItem.width / 2) * Math.sin(Math.PI/4 + a - Math.PI/50));
//                                 ctx.arc(0,0, (proximityItem.width / 2), Math.PI/4 + a - Math.PI/50, a + Math.PI/50, true);
//                                 //ctx.lineTo(proximityItem.range * Math.cos(Math.PI/4 + a - Math.PI/50), proximityItem.range * Math.sin(Math.PI/4 + a - Math.PI/50));
//                                 ctx.closePath();
//                                 ctx.fillStyle = gradient;
//                                 ctx.fill();
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }

//     QGCLabel {
//         anchors.horizontalCenter:   parent.horizontalCenter
//         y:                          size * 0.74
//         text:                       vehicle ? _heading.toFixed(0) + "°" : ""
//         horizontalAlignment:        Text.AlignHCenter
//     }
// }

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

    property var  _gimbalController:        vehicle ? vehicle.gimbalController : undefined
    property var  _activeGimbal:            _gimbalController ? _gimbalController.activeGimbal : undefined
    property bool _gimbalAvailable:         _activeGimbal ? true : false
    property bool _gimbalPitchAvailable:    _activeGimbal && _activeGimbal.curPitch ? true : false
    property bool _gimbalYawAvailable:      _activeGimbal && _activeGimbal.curYaw ? true : false
    property real _gimbalPitch:             _gimbalAvailable && _gimbalPitchAvailable ? _activeGimbal.curPitch : 0
    property real _gimbalYaw:               _gimbalAvailable && _gimbalYawAvailable ? _activeGimbal.curYaw : 0

    property string _distanceToHomeText:    vehicle ? _distanceToHome.toFixed(0) : "--"
    property string _distanceToNextWPText:  vehicle ? _distanceToNextWP.toFixed(0) : "--"
    property string _windSpdText:           vehicle ? _windSpd.toFixed(1) : "0.0"

    property string _flightMode:            vehicle ? vehicle.flightMode : ""
    property bool   _vehicleInMissionMode:  vehicle ? _flightMode === vehicle.missionFlightMode : false

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
        return vehicle && _vehicleInMissionMode && _showAdditionalIndicatorsCompass && !isNaN(_headingToNextWP)
    }

    function isDistanceToNextWPOK(){
        return vehicle && _vehicleInMissionMode && _showAdditionalIndicatorsCompass && !isNaN(_distanceToNextWP)
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


    CompassDial {
        id: compassDial
        anchors.fill: parent

        transform: Rotation {
            origin.x:       compassDial.width  / 2
            origin.y:       compassDial.height / 2
            angle:          isNoseUpLocked()?-_heading:0
        }
    }

    CompassHeadingIndicator {
        id: vehicleHeadingDial
        compassSize:    size
        heading:        isNoseUpLocked() ? 0 : _heading

        // transform: Rotation {
        //     origin.x:       vehicleHeadingDial.width / 2
        //     origin.y:       vehicleHeadingDial.height / 2
        //     angle:          isNoseUpLocked() ? 0 : _heading
        // }
    }

    // QGCColoredImage {
    //     id:                 compassDial
    //     source:             "/qmlimages/compassInstrumentDial.svg"
    //     mipmap:             true
    //     fillMode:           Image.PreserveAspectFit
    //     anchors.fill:       parent
    //     sourceSize.height:  parent.height
    //     color:              qgcPal.text
    //     transform: Rotation {
    //         origin.x:       compassDial.width  / 2
    //         origin.y:       compassDial.height / 2
    //         angle:          isNoseUpLocked()?-_heading:0
    //     }
    // }

    // Image {
    //     id:                 vehicleHeadingDial
    //     anchors { verticalCenter: root.verticalCenter; horizontalCenter: parent.horizontalCenter }
    //     source:             "/qmlimages/vehicleArrowOpaque.svg"
    //     mipmap:             true
    //     width:              parent.width * 0.2
    //     sourceSize.width:   width
    //     antialiasing:       true
    //     fillMode:           Image.PreserveAspectFit

    //     layer {
    //         enabled: true
    //         effect: ColorOverlay {
    //             color: qgcPal.text
    //         }
    //     }

    //     transform: Rotation {
    //         origin.x:       vehicleHeadingDial.width / 2
    //         origin.y:       vehicleHeadingDial.height / 2
    //         angle:          isNoseUpLocked() ? 0 : _heading
    //     }
    // }

    Item {
        id:             proximityItem
        anchors.fill:   parent
        width:          parent.width
        height:         parent.height

        property real   range:  20//isNaN(proximityValues.maxDistance)   ///< Default 6m view

        property real   _minlength:    Math.min(proximityItem.width,proximityItem.height)
        property real   _minRadius:    Math.min(proximityItem.width,proximityItem.height) / 4
        property real   _ratio:        (_minRadius / 2) / proximityItem.range
        property real   _warningDistance: 10
        property real   _maxRange:        50

        ProximityRadarValues {
            id:                     proximityValues
            vehicle:                root.vehicle
            onRotationValueChanged: proximitySensors.requestPaint()
        }

        Canvas{
            id:                 proximitySensors
            anchors.fill:       proximityItem

            transform: Rotation {
                origin.x:       parent.width  / 2
                origin.y:       parent.height / 2
                angle:          isNoseUpLocked() ? 0 : _heading
            }

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.translate(width/2, height/2)
                ctx.lineWidth = width/30;
                ctx.rotate(-Math.PI/2 - Math.PI/8);
                for (var i=0; i<proximityValues.rgRotationValues.length; i++) {
                    var rotationValue = proximityValues.rgRotationValues[i]
                    if (rotationValue < proximityItem._maxRange) {
                        var warningColor;
                        if (rotationValue < proximityItem._warningDistance) { warningColor = Qt.rgba(1, 0, 0, 0.4) }
                        else if (rotationValue >= proximityItem._warningDistance) { warningColor = Qt.rgba(1, 1, 0, 0.4) }
                        if (rotationValue > proximityItem.range) { rotationValue = proximityItem.range; }
                        if (!isNaN(rotationValue)) {
                            var a=Math.PI/4 * i;
                            var gradient = ctx.createRadialGradient(0, 0, proximityItem._minRadius + (rotationValue * proximityItem._ratio), 0, 0, (proximityItem.width / 2));
                            gradient.addColorStop(0, warningColor); // 내부부터 시작하는 색상
                            gradient.addColorStop(0.3, "transparent");
                            gradient.addColorStop(1, "transparent"); // 외부로 퍼지는 색상
                            ctx.beginPath();
                            //ctx.arc(0, 0, proximityItem._minRadius + (rotationValue * proximityItem._ratio), 0 + a + Math.PI/50, Math.PI/4 + a - Math.PI/50, false);
                            //ctx.stroke();
                            ctx.moveTo(0,0);
                            ctx.arc(0,0, proximityItem._minRadius + (rotationValue * proximityItem._ratio), a + Math.PI/50, Math.PI/4 + a - Math.PI/50);
                            ctx.lineTo((proximityItem.width / 2) * Math.cos(Math.PI/4 + a - Math.PI/50), (proximityItem.width / 2) * Math.sin(Math.PI/4 + a - Math.PI/50));
                            ctx.arc(0,0, (proximityItem.width / 2), Math.PI/4 + a - Math.PI/50, a + Math.PI/50, true);
                            //ctx.lineTo(proximityItem.range * Math.cos(Math.PI/4 + a - Math.PI/50), proximityItem.range * Math.sin(Math.PI/4 + a - Math.PI/50));
                            ctx.closePath();
                            ctx.fillStyle = gradient;
                            ctx.fill();
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.horizontalCenter: vehicleHeadingDial.horizontalCenter
        anchors.top:   vehicleHeadingDial.bottom
        anchors.topMargin:  size * 0.05
        width:              size * 0.20
        height:             size * 0.12
        //border.color:       qgcPal.text
        color:              "transparent"
        //opacity:            0.65
        radius:             height * 0.1

        QGCLabel {
            anchors.horizontalCenter:   parent.horizontalCenter
            //y:                          size * 0.74
            text:                       vehicle ? _heading.toFixed(0) + "°" : ""
            horizontalAlignment:        Text.AlignHCenter
        }

        // QGCLabel {
        //     text:               _headingString3
        //     font.family:        vehicle ? ScreenTools.demiboldFontFamily : ScreenTools.normalFontFamily
        //     font.pointSize:     _fontSize < 8 ? 8 : _fontSize;
        //     color:              qgcPal.text
        //     anchors.centerIn:   parent

        //     property string _headingString: vehicle ? _heading.toFixed(0) : "OFF"
        //     property string _headingString2: _headingString.length === 1 ? "0" + _headingString : _headingString
        //     property string _headingString3: _headingString2.length === 2 ? "0" + _headingString2 : _headingString2
        // }
    }

    Rectangle {
        id:                 homePointer
        visible:            isHeadingHomeOK()
        width:              size * 0.11
        height:             width
        radius:             width * 0.5
        anchors.centerIn:   parent
        color:              qgcPal.alertBackground //qgcPal.text
        border.color:       "black" //qgcPal.alertBackground

        QGCLabel {
            text:               "H"
            font.pointSize:     _fontSize < 10 ? 10 : _fontSize;
            font.family:        ScreenTools.demiboldFontFamily
            font.bold:          true
            color:              "black" //qgcPal.alertBackground
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
        color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5)
        radius:                     height * 0.2
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

    Rectangle {
        id:             gimbalSight
        visible:        _gimbalAvailable & _gimbalPitch >= -85
        anchors { verticalCenter: parent.verticalCenter; horizontalCenter: parent.horizontalCenter }
        width:          parent.width * 0.6
        height:         width
        color:          "transparent"

        Canvas {
            id: triangleCanvas
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d");

                // 그라데이션 생성
                var gradient = ctx.createLinearGradient(triangleCanvas.width / 2, 0, triangleCanvas.width / 2, triangleCanvas.height);
                gradient.addColorStop(0, "transparent");
                gradient.addColorStop(0.5, qgcPal.brandingBlue);

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
            angle:          isNoseUpLocked() ? _gimbalYaw - _heading : _gimbalYaw//isNoseUpLocked() ? _gimbalYaw : _heading + _gimbalYaw
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
        color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5)
        radius:                     height * 0.2
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
        id:                 windvane
        source:             isWindVaneOK() ? "/qmlimages/windVaneArrow.svg" : ""
        mipmap:             true
        fillMode:           Image.PreserveAspectFit
        anchors.fill:       parent
        sourceSize.height:  parent.height

        transform: Rotation {
            property var _angle: isNoseUpLocked() ? _windDir - _heading : _windDir
            origin.x:       windvane.width  / 2
            origin.y:       windvane.height / 2
            angle:         _angle
        }
    }

    Rectangle {
        width:                      windVaneText.width + (size * 0.05)
        height:                     size * 0.12
        border.color:               qgcPal.colorGreen
        color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5)
        radius:                     height * 0.2
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
            x: size/1.82 * Math.sin((_angle)*(3.14/180))
            y: - size/1.82 * Math.cos((_angle)*(3.14/180))
        }
    }
}
