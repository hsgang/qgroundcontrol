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
    // border.color:   Qt.rgba(qgcPal.text.r, qgcPal.text.g, qgcPal.text.b, 0.5)
    // border.width:   1
    radius:     _margins / 2
    //visible:    _showGimbalControl && multiVehiclePanelSelector.showSingleVehiclePanel

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
    property real   _altLimit:              QGroundControl.settingsManager.flyViewSettings.guidedMinimumAltitude.rawValue
    property real   _vx:                    activeVehicle ? activeVehicle.localPosition.vx.rawValue : 0
    property real   _vy:                    activeVehicle ? activeVehicle.localPosition.vy.rawValue : 0
    property real   _vz:                    activeVehicle ? activeVehicle.localPosition.vz.rawValue : 0
    property bool   _isMoving:              Math.sqrt(Math.pow(_vx,2) + Math.pow(_vy,2) + Math.pow(_vz,2)) > 0.5
    property real   _distance:              activeVehicle ? activeVehicle.distanceSensors.rotationPitch270.rawValue : NaN
    property real   _relAltitude:           activeVehicle ? activeVehicle.altitudeRelative.rawValue : NaN
    property bool   _isCustomCommandEnabled: activeVehicle ? activeVehicle.isCustomCommandEnabled : false

    property bool   _isGuidedEnable:        activeVehicle && activeVehicle.flying

    property real   _treshHoldAlt : 10.0
    property var    stepValues:             [0.2, 0.5, 1.0, 2.0, 3.0]
    property int    receivedTagId: 0

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    Connections {
        target: activeVehicle
        onRequestConfirmationReceived: (customCmd, show, tagId) => {
            if (customCmd !== 1) {
                return
            }
            receivedTagId = tagId
            // if(show > 0) {
            //     control.visible = true
            // } else if (show === 0) {
            //     control.visible = false
            // }
        }
    }

    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: false
    }

    GridLayout {
        id:                         mainGridLayout
        anchors.verticalCenter:     parent.verticalCenter
        anchors.horizontalCenter:   parent.horizontalCenter
        columnSpacing:              ScreenTools.defaultFontPixelHeight / 2
        rowSpacing:                 columnSpacing
        columns:                    4

        QGCLabel{
            Layout.columnSpan: 4
            Layout.fillWidth: true
            text: "기체 배송 제어"
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            Layout.columnSpan: 4
            Layout.fillWidth: true
            height : 1
            color : qgcPal.groupBorder
        }

        QGCColumnButton{
            id:                 stepUp
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable && !_isMoving
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
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable && !_isMoving
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
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable && !_isMoving
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
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable && !_isMoving
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
            id:                 stepTargetAlt
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable && !_isMoving && _distance
            opacity:            enabled ? 1 : 0.4

            iconSource:          _distance ? (_distance >= _treshHoldAlt ? "/InstrumentValueIcons/arrow-thin-down.svg" : "/InstrumentValueIcons/arrow-thin-up.svg") : "/InstrumentValueIcons/pause.svg"
            text:               _distance ? (_distance >= _treshHoldAlt ? targetAltMin+"M" : targetAltMax+"M") : "NONE"
            font.pointSize:     _fontSize * 0.7

            property real targetAltMin: 3.5
            property real targetAltMax: 15.0

            onClicked: {
                if(activeVehicle && _distance) {
                    // var targetMin = 4.5
                    // var targetMax = 15.0
                    var altTarget = 0
                    if( _distance >= _treshHoldAlt ) { // down
                        altTarget = -(_distance - targetAltMin)
                        activeVehicle.sendCommand(1, 178, 1, 3, 0.7, -1, 0, 0, 0, 0)
                        activeVehicle.setPositionTargetLocalNed(0,0,altTarget,0,false)
                    }
                    else if( _distance < _treshHoldAlt ) { // up
                        altTarget = (targetAltMax - _relAltitude )
                        activeVehicle.setPositionTargetLocalNed(0,0,altTarget,0,false)
                    }
                    console.log(altTarget, _distance, _relAltitude)
                }
            }
        }

        QGCColumnButton{
            id:                 stepLeft
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable && !_isMoving
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
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable
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
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable && !_isMoving
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
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable && !_isMoving && (isNaN(_distance) || ((_distance - _moveStep) > _altLimit))
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/arrow-thin-down.svg"
            text:               "DOWN"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                // _distance가 NaN이면 기능 수행
                if (isNaN(_distance) || _distance === 0) {
                    activeVehicle.setPositionTargetLocalNed(0, 0, -_moveStep, 0, false)
                }
                // _distance 값이 유효하면 (_distance - _moveStep)가 _altLimit보다 클 때 기능 수행
                else if (_distance !== 0 && (_distance - _moveStep) > _altLimit) {
                    activeVehicle.setPositionTargetLocalNed(0, 0, -_moveStep, 0, false)
                }
            }
        }

        QGCColumnButton{
            id:                 stepHalf
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/dots-horizontal-double.svg"
            text:               "STEP"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                var index = stepValues.indexOf(_moveStepFact.value);
                if (index > 0) {
                    _moveStepFact.value = stepValues[index - 1];
                }
            }
        }

        QGCColumnButton{
            id:                 stepBack
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable && !_isMoving
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
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/dots-horizontal-triple.svg"
            text:               "STEP"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                var index = stepValues.indexOf(_moveStepFact.value);
                if (index !== -1 && index < stepValues.length - 1) {
                    _moveStepFact.value = stepValues[index + 1];
                }
            }
        }

        QGCColumnButton{
            id:                 gripperRelease
            implicitWidth:      _idealWidth
            implicitHeight:     width
            opacity:            enabled ? 1 : 0.4
            enabled:            activeVehicle && (_distance && _distance < _treshHoldAlt)

            iconSource:         "/res/GripperRelease.svg"
            text:               "Open"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                _activeVehicle.sendGripperAction(0)
            }
        }

        QGCColumnButton{
            id:                 gripperGrab
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            activeVehicle
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/res/GripperGrab.svg"
            text:               "Grab"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                _activeVehicle.sendGripperAction(1)
            }
        }

        QGCButton{
            id:                 autoSequence
            //implicitWidth:      _idealWidth
            Layout.fillWidth:   true
            implicitWidth:      _idealWidth
            enabled:            _isGuidedEnable && activeVehicle.flying && _distance
            opacity:            enabled ? 1 : 0.4

            Layout.columnSpan:  2

            iconSource:         ""//"/InstrumentValueIcons/play.svg"
            text:               _isCustomCommandEnabled ? "Stop.Seq" : "Auto.Seq"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                if(_isCustomCommandEnabled) {
                    _activeVehicle.sendCommand(192, 31010, 1, 1, 0, receivedTagId, 2, 0, 0, 0)
                }
                else if (!_isCustomCommandEnabled){
                    _activeVehicle.sendCommand(192, 31010, 1, 1, 0, receivedTagId, 1, 0, 0, 0)
                }
            }
        }

        Rectangle {
            Layout.columnSpan: 4
            Layout.fillWidth: true
            height : 1
            color : qgcPal.groupBorder
        }

        ColumnLayout {
            Layout.columnSpan: 4
            Layout.fillWidth: true

            LabelledLabel {
                Layout.fillWidth:   true
                label:              "스텝 단위"
                labelText:          activeVehicle ? _moveStep.toFixed(1) + " m" : "no value"
            }
            LabelledLabel {
                Layout.fillWidth:   true
                label:              "상대 고도"
                labelText:          activeVehicle ? activeVehicle.altitudeRelative.valueString + " m" : "no value"
            }
            LabelledLabel {
                Layout.fillWidth:   true
                label:              "라이다 고도계"
                labelText:          activeVehicle ? _distance.toFixed(1) + " m" : "no value"
            }
        }
    }
}
