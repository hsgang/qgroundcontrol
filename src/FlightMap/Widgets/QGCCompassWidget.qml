/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Vehicle
import QGroundControl.Palette

Rectangle {
    id:     root
    width:  size
    height: size
    radius: width / 2
    color:  qgcPal.window

    property real size:                         _defaultSize
    property var  vehicle:                      null
    property bool usedByMultipleVehicleList:    false

    property real _defaultSize:                 ScreenTools.defaultFontPixelHeight * (10)
    property real _sizeRatio:                   ScreenTools.isTinyScreen ? (size / _defaultSize) * 0.5 : size / _defaultSize
    property int  _fontSize:                    ScreenTools.defaultFontPointSize * _sizeRatio < 8 ? 8 : ScreenTools.defaultFontPointSize * _sizeRatio
    property real _heading:                     vehicle ? vehicle.heading.rawValue : 0
    property real _headingToHome:               vehicle ? vehicle.headingToHome.rawValue : 0
    property real _groundSpeed:                 vehicle ? vehicle.groundSpeed.rawValue : 0
    property real _headingToNextWP:             vehicle ? vehicle.headingToNextWP.rawValue : 0
    property real _courseOverGround:            vehicle ? vehicle.gps.courseOverGround.rawValue : 0
    property var  _flyViewSettings:             QGroundControl.settingsManager.flyViewSettings
    property bool _showAdditionalIndicators:    _flyViewSettings.showAdditionalIndicatorsCompass.value && !usedByMultipleVehicleList
    property bool _lockNoseUpCompass:           _flyViewSettings.lockNoseUpCompass.value

    function showCOG(){
        if (_groundSpeed < 0.5) {
            return false
        } else{
            return vehicle && _showAdditionalIndicators
        }
    }

    function showHeadingHome() {
        return vehicle && _showAdditionalIndicators && !isNaN(_headingToHome)
    }

    function showHeadingToNextWP() {
        return vehicle && _showAdditionalIndicators && !isNaN(_headingToNextWP)
    }

    function isWindVaneOK(){
        return vehicle && _showAdditionalIndicatorsCompass && !isNaN(_windDir)
    }

    function isNoseUpLocked(){
        return _lockNoseUpCompass
    }
    function translateCenterToAngleX(radius, angle) {
        return radius * Math.sin(angle * (Math.PI / 180))
    } 

    function translateCenterToAngleY(radius, angle) {
        return -radius * Math.cos(angle * (Math.PI / 180))
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    Item {
        id:             rotationParent
        anchors.fill:   parent

        transform: Rotation {
            origin.x:       rotationParent.width  / 2
            origin.y:       rotationParent.height / 2
            angle:         _lockNoseUpCompass ? -_heading : 0
        }

        CompassDial {
            anchors.fill: parent
        }

        CompassHeadingIndicator {
            compassSize:    size
            heading:        _heading
        }

        Image {
            id:                 cogPointer
            source:             "/qmlimages/cOGPointer.svg"
            mipmap:             true
            fillMode:           Image.PreserveAspectFit
            anchors.fill:       parent
            sourceSize.height:  parent.height
            visible:            showCOG()

            transform: Rotation {
                origin.x:   cogPointer.width  / 2
                origin.y:   cogPointer.height / 2
                angle:      _courseOverGround
            }
        }

        Image {
            id:                 nextWPPointer
            source:             "/qmlimages/compassDottedLine.svg"
            mipmap:             true
            fillMode:           Image.PreserveAspectFit
            anchors.fill:       parent
            sourceSize.height:  parent.height
            visible:            showHeadingToNextWP()

            transform: Rotation {
                origin.x:   nextWPPointer.width  / 2
                origin.y:   nextWPPointer.height / 2
                angle:      _headingToNextWP
            }
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

        Image {
            id:                 windVane
            source:             isWindVaneOK() ? "/qmlimages/windVaneArrow.svg" : ""
            mipmap:             true
            fillMode:           Image.PreserveAspectFit
            anchors.fill:       parent
            sourceSize.height:  parent.height

            transform: Rotation {
                property var _angle:isNoseUpLocked()?_windDir-_heading:_windDir
                origin.x:       cOGPointer.width  / 2
                origin.y:       cOGPointer.height / 2
                angle:         _angle
            }
        }

        Image {
            id:                 pointer
            width:              size * 0.65
            source:             vehicle ? vehicle.vehicleImageCompass : ""
            mipmap:             true
            sourceSize.width:   width
            fillMode:           Image.PreserveAspectFit
            anchors.centerIn:   parent
            transform: Rotation {
                origin.x:       pointer.width  / 2
                origin.y:       pointer.height / 2
                angle:          isNoseUpLocked()?0:_heading
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


        // Launch location indicator
        Rectangle {
            width:              Math.max(label.contentWidth, label.contentHeight)
            height:             width
            color:              qgcPal.mapIndicator
            radius:             width / 2
            anchors.centerIn:   parent
            visible:            showHeadingHome()

            QGCLabel {
                id:                 label
                text:               qsTr("L")
                font.bold:          true
                color:              qgcPal.text
                anchors.centerIn:   parent
            }

            transform: Translate {
                property double _angle: _headingToHome

                x: translateCenterToAngleX(parent.width / 2, _angle)
                y: translateCenterToAngleY(parent.height / 2, _angle)
            }
        }
    }

    QGCLabel {
        anchors.horizontalCenter:   parent.horizontalCenter
        y:                          size * 0.74
        text:                       vehicle ? _heading.toFixed(0) + "°" : ""
        horizontalAlignment:        Text.AlignHCenter
    }
}
