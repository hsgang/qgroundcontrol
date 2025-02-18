/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtPositioning
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.Controllers
import QGroundControl.Palette
import QGroundControl.Vehicle
import QGroundControl.MultiVehicleManager
import QGroundControl.FactSystem
import QGroundControl.FactControls

Rectangle {
    id:         gimbalControlPannel
    width:      mainGridLayout.width + _margins
    height:     mainGridLayout.height + _margins
    color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, backgroundOpacity)
    border.color:   Qt.rgba(qgcPal.text.r, qgcPal.text.g, qgcPal.text.b, 0.5)
    border.width:   1
    radius:     _margins / 2
    visible:    _showGimbalControl && multiVehiclePanelSelector.showSingleVehiclePanel

    property real   _margins:           ScreenTools.defaultFontPixelHeight / 2
    property real   _idealWidth:        ScreenTools.defaultFontPixelWidth * 7
    property real   anchorsMargins:     _margins
    property real   _fontSize:          ScreenTools.isMobile ? ScreenTools.defaultFontPointSize * 0.8 : ScreenTools.defaultFontPointSize
    property real   backgroundOpacity:  QGroundControl.settingsManager.flyViewSettings.flyviewWidgetOpacity.rawValue

    // The following properties relate to a simple camera
    property var    _flyViewSettings:       QGroundControl.settingsManager.flyViewSettings

    // The following settings and functions unify between a mavlink camera and a simple video stream for simple access

    property var    activeVehicle:          QGroundControl.multiVehicleManager.activeVehicle
    property real   _yaw:                   activeVehicle ? activeVehicle.heading.rawValue : 0
    property real   _yawRad:                _yaw * Math.PI / 180
    property real   _yawStep:               5 //degree
    property Fact   _moveStepFact:          _flyViewSettings.vehicleMoveStep
    property real   _moveStep:              _moveStepFact.rawValue
    property real   _altLimit:              9.9 // m
    property real   _vx:                    activeVehicle ? activeVehicle.localPosition.vx.rawValue : 0
    property real   _vy:                    activeVehicle ? activeVehicle.localPosition.vy.rawValue : 0
    property real   _vz:                    activeVehicle ? activeVehicle.localPosition.vz.rawValue : 0
    property bool   _isMoving:              Math.sqrt(Math.pow(_vx,2) + Math.pow(_vy,2) + Math.pow(_vz,2)) > 0.2
    property real   _distance:              activeVehicle ? activeVehicle.distanceSensors.rotationPitch270.rawValue : NaN

    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: false
    }

    Rectangle{
        anchors.bottom: parent.top
        anchors.bottomMargin: _margins / 2
        anchors.right: parent.right
        anchors.horizontalCenter: parent.horizontalCenter
        width:          valueRowLayout.width
        height:         titleLabel.height + _margins
        color:          Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, backgroundOpacity)
        radius:         _margins / 2

        QGCLabel{
            id:   titleLabel
            text: "기체 스텝 제어"
            anchors.horizontalCenter:   parent.horizontalCenter
            anchors.verticalCenter:     parent.verticalCenter
        }
    }

    Rectangle{
        anchors.top: parent.bottom
        anchors.topMargin: _margins / 2
        anchors.right: parent.right
        anchors.horizontalCenter: parent.horizontalCenter
        width:          valueRowLayout.width
        height:         valueRowLayout.height + _margins
        color:          Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, backgroundOpacity)
        radius:         _margins / 2

        RowLayout {
            id: valueRowLayout
            //anchors.horizontalCenter: parent.horizontalCenter
            anchors.left:           parent.left
            anchors.leftMargin:     ScreenTools.defaultFontPixelWidth
            anchors.verticalCenter: parent.verticalCenter

            ColumnLayout{

                QGCLabel{
                    text: "스텝 단위"
                    font.pointSize: _fontSize
                    leftPadding:    ScreenTools.defaultFontPixelWidth
                }
                // QGCLabel{
                //     text: "상대좌표"
                //     font.pointSize: _fontSize
                //     leftPadding:    ScreenTools.defaultFontPixelWidth
                // }
                // QGCLabel{
                //     text: "이동속도"
                //     font.pointSize: _fontSize
                //     leftPadding:    ScreenTools.defaultFontPixelWidth
                // }
                QGCLabel{
                    text: "상대고도"
                    font.pointSize: _fontSize
                    leftPadding:    ScreenTools.defaultFontPixelWidth
                }
                QGCLabel{
                    text: "하방라이다"
                    font.pointSize: _fontSize
                    leftPadding:    ScreenTools.defaultFontPixelWidth
                }
            }

            ColumnLayout{
                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 14

                QGCLabel{
                    text: activeVehicle ? _moveStep + " m" : "no value"
                    font.pointSize: _fontSize
                    Layout.alignment: Qt.AlignRight
                }
                // QGCLabel{
                //     text: activeVehicle ? activeVehicle.localPosition.x.valueString + "x / " + activeVehicle.localPosition.y.valueString + "y" : "no value"
                //     font.pointSize: _fontSize
                //     Layout.alignment: Qt.AlignRight
                // }
                // QGCLabel{
                //     text: activeVehicle ? _vx.toFixed(1) + " / " + _vy.toFixed(1) + " / " + _vz.toFixed(1) : "no value"
                //     font.pointSize: _fontSize
                //     Layout.alignment: Qt.AlignRight
                // }
                QGCLabel{
                    text: activeVehicle ? activeVehicle.altitudeRelative.valueString + " m" : "no value"
                    font.pointSize: _fontSize
                    Layout.alignment: Qt.AlignRight
                }
                QGCLabel{
                    text: activeVehicle ? _distance.toFixed(1) + " m" : "no value"
                    font.pointSize: _fontSize
                    Layout.alignment: Qt.AlignRight
                }
            }
        }
    }

    GridLayout {
        id:                         mainGridLayout
        anchors.verticalCenter:     parent.verticalCenter
        anchors.horizontalCenter:   parent.horizontalCenter
        columnSpacing:              ScreenTools.defaultFontPixelHeight / 2
        rowSpacing:                 columnSpacing
        columns:                    4

        QGCColumnButton{
            id:                 stepUp
            implicitWidth:      _idealWidth // - anchorsMargins
            implicitHeight:     width
            enabled:            activeVehicle && !_isMoving
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/arrow-thin-up.svg"
            text:               "UP"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                activeVehicle.setPositionTargetLocalNed(0,0,_moveStep,0,false)
            }
        }

        QGCColumnButton{
            id:                 stepTurnLeft
            implicitWidth:      _idealWidth // - anchorsMargins
            implicitHeight:     width
            enabled:            activeVehicle && !_isMoving
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/cheveron-left.svg"
            text:               "T.LFT"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                var targetYaw = -_yawStep * Math.PI / 180
                activeVehicle.setPositionTargetLocalNed(0,0,0,targetYaw,false)
            }
        }

        QGCColumnButton{
            id:                 stepForward
            implicitWidth:      _idealWidth // - anchorsMargins
            implicitHeight:     width
            enabled:            activeVehicle && !_isMoving
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/arrow-thick-up.svg"
            text:               "FWD"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                activeVehicle.setPositionTargetLocalNed(_moveStep,0,0,0,false)
            }
        }

        QGCColumnButton{
            id:                 stepTurnRight
            implicitWidth:      _idealWidth // - anchorsMargins
            implicitHeight:     width
            enabled:            activeVehicle && !_isMoving
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/cheveron-right.svg"
            text:               "T.RGHT"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                var targetYaw = _yawStep * Math.PI / 180
                activeVehicle.setPositionTargetLocalNed(0,0,0,targetYaw,false)
            }
        }

        QGCColumnButton{
            id:                 stepAltStop
            implicitWidth:      _idealWidth // - anchorsMargins
            implicitHeight:     width
            enabled:            activeVehicle
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/pause.svg"
            text:               "STOP"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                activeVehicle.setPositionTargetLocalNed(0,0,0,0,false)
            }
        }

        QGCColumnButton{
            id:                 stepLeft
            implicitWidth:      _idealWidth // - anchorsMargins
            implicitHeight:     width
            enabled:            activeVehicle && !_isMoving
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/arrow-thick-left.svg"
            text:               "LEFT"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                activeVehicle.setPositionTargetLocalNed(0,-_moveStep,0,0,false)
            }
        }

        QGCColumnButton{
            id:                 stepStop
            implicitWidth:      _idealWidth // - anchorsMargins
            implicitHeight:     width
            enabled:            activeVehicle
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/pause.svg"
            text:               "STOP"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                activeVehicle.setPositionTargetLocalNed(0,0,0,0,false)
            }
        }

        QGCColumnButton{
            id:                 stepRight
            implicitWidth:      _idealWidth // - anchorsMargins
            implicitHeight:     width
            enabled:            activeVehicle && !_isMoving
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/arrow-thick-right.svg"
            text:               "RIGHT"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                activeVehicle.setPositionTargetLocalNed(0,_moveStep,0,0,false)
            }
        }

        QGCColumnButton{
            id:                 stepDown
            implicitWidth:      _idealWidth // - anchorsMargins
            implicitHeight:     width
            enabled:            activeVehicle && !_isMoving && (isNaN(_distance) || ((_distance - _moveStep) > _altLimit))
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/arrow-thin-down.svg"
            text:               "DOWN"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                // _distance가 NaN이면 기능 수행
                if (isNaN(_distance)) {
                    activeVehicle.setPositionTargetLocalNed(0, 0, -_moveStep, 0, false)
                }
                // _distance 값이 유효하면 (_distance - _moveStep)가 _altLimit보다 클 때 기능 수행
                else if ((_distance - _moveStep) > _altLimit) {
                    activeVehicle.setPositionTargetLocalNed(0, 0, -_moveStep, 0, false)
                }
            }
        }

        QGCColumnButton{
            id:                 stepHalf
            implicitWidth:      _idealWidth // - anchorsMargins
            implicitHeight:     width
            enabled:            activeVehicle
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/dots-horizontal-double.svg"
            text:               "0.5"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                activeVehicle.setPositionTargetLocalNed(0,0,0,0,false)
                _moveStepFact.value = 0.5
            }
        }

        QGCColumnButton{
            id:                 stepBack
            implicitWidth:      _idealWidth // - anchorsMargins
            implicitHeight:     width
            enabled:            activeVehicle && !_isMoving
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/arrow-thick-down.svg"
            text:               "BACK"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                activeVehicle.setPositionTargetLocalNed(-_moveStep,0,0,0,false)
            }
        }

        QGCColumnButton{
            id:                 stepOne
            implicitWidth:      _idealWidth // - anchorsMargins
            implicitHeight:     width
            enabled:            activeVehicle
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/dots-horizontal-triple.svg"
            text:               "1.0"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                activeVehicle.setPositionTargetLocalNed(0,0,0,0,false)
                _moveStepFact.value = 1
            }
        }
    }
}
