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



Rectangle {
    id:     root
    width:  size
    height: size
    radius: width / 2
    color:  qgcPal.window
    border.color:   qgcPal.text
    border.width:   usedByMultipleVehicleList ? 1 : 0
    opacity:        vehicle && usedByMultipleVehicleList && !vehicle.armed ? 0.5 : 1

    property real size:                         _defaultSize
    property var  vehicle:                      null
    property bool usedByMultipleVehicleList:    false

    property real _defaultSize:                 usedByMultipleVehicleList ? ScreenTools.defaultFontPixelHeight * 3 : ScreenTools.defaultFontPixelHeight * 10
    property real _sizeRatio:                   (usedByMultipleVehicleList || ScreenTools.isTinyScreen) ? (size / _defaultSize) * 0.5 : size / _defaultSize
    property int  _fontSize:                    ScreenTools.defaultFontPointSize * _sizeRatio < 8 ? 8 : ScreenTools.defaultFontPointSize * _sizeRatio
    property real _heading:                     vehicle ? vehicle.heading.rawValue : 0
    property real _headingToHome:               vehicle ? vehicle.headingToHome.rawValue : 0
    property real _groundSpeed:                 vehicle ? vehicle.groundSpeed.rawValue : 0
    property real _headingToNextWP:             vehicle ? vehicle.headingToNextWP.rawValue : 0
    property real _distanceToNextWP:            vehicle ? vehicle.distanceToNextWP.rawValue : 0
    property real _courseOverGround:            vehicle ? vehicle.gps.courseOverGround.rawValue : 0
    property var  _flyViewSettings:             QGroundControl.settingsManager.flyViewSettings
    property bool _showAdditionalIndicators:    _flyViewSettings.showAdditionalIndicatorsCompass.value && !usedByMultipleVehicleList
    property bool _lockNoseUpCompass:           _flyViewSettings.lockNoseUpCompass.value && !usedByMultipleVehicleList

    property string _flightMode:                vehicle ? vehicle.flightMode : ""
    property bool   _vehicleInMissionMode:      vehicle ? _flightMode === vehicle.missionFlightMode : false

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

    function showDistanceToNextWP(){
        return vehicle && _vehicleInMissionMode && _showAdditionalIndicators && !isNaN(_distanceToNextWP)
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
            anchors.fill:   parent
            visible:        !usedByMultipleVehicleList
        }

        CompassHeadingIndicator {
            compassSize:    size
            heading:        _heading
            simplified:     usedByMultipleVehicleList
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

        Rectangle {
            width:                      distanceToNextWPText.width + (size * 0.05)
            height:                     size * 0.12
            border.color:               qgcPal.buttonHighlight
            color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5)
            radius:                     height * 0.2
            visible:                    showDistanceToNextWP()
            anchors.centerIn:           parent

            QGCLabel {
                id:                 distanceToNextWPText
                text:               _distanceToNextWP.toFixed(0)
                font.pointSize:     _fontSize < 8 ? 8 : _fontSize;
                font.bold:          true
                color:              qgcPal.text
                anchors.centerIn:   parent
            }

            transform: Translate {
                property double _angle: _headingToNextWP

                x: translateCenterToAngleX(parent.width / 4, _angle)
                y: translateCenterToAngleY(parent.height / 4, _angle)
            }
        }

        // Launch location indicator
        Rectangle {
            width:              Math.max(label.contentWidth, label.contentHeight)
            height:             width
            radius:             width / 2
            anchors.centerIn:   parent
            visible:            showHeadingHome()
            //color:              qgcPal.mapIndicator
            color:              qgcPal.alertBackground //qgcPal.text
            border.color:       "black" //qgcPal.alertBackground

            QGCLabel {
                id:                 label
                text:               "H"
                font.bold:          true
                color:              "black"
                anchors.centerIn:   parent
            }

            transform: Translate {
                property double _angle: _headingToHome

                x: translateCenterToAngleX(parent.width / 2.2, _angle)
                y: translateCenterToAngleY(parent.height / 2.2, _angle)
            }
        }
    }

    QGCLabel {
        anchors.horizontalCenter:   parent.horizontalCenter
        y:                          size * 0.74
        text:                       vehicle && !usedByMultipleVehicleList ? _heading.toFixed(0) + "°" : ""
        horizontalAlignment:        Text.AlignHCenter
    }
}
