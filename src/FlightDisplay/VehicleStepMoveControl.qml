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
import QGroundControl.Controls

Rectangle {
    id:         gimbalControlPannel
    width:      _isCustomCommandEnabled ? (mainGridLayout.width + _margins + sequenceIndicator.width) : mainGridLayout.width + _margins
    height:     mainGridLayout.height + _margins
    color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, backgroundOpacity)
    radius:     _margins
    //visible:    _showGimbalControl && multiVehiclePanelSelector.showSingleVehiclePanel

    property real   _margins:           ScreenTools.defaultFontPixelHeight / 2
    property real   _idealWidth:        ScreenTools.defaultFontPixelWidth * 7
    property real   anchorsMargins:     _margins
    property real   _fontSize:          ScreenTools.isMobile ? ScreenTools.defaultFontPointSize * 0.8 : ScreenTools.defaultFontPointSize
    property real   backgroundOpacity:  QGroundControl.settingsManager.flyViewSettings.flyviewWidgetOpacity.rawValue

    // The following properties relate to a simple camera
    property var    _flyViewSettings:       QGroundControl.settingsManager.flyViewSettings

    // The following settings and functions unify between a mavlink camera and a simple video stream for simple access

    property var    _activeVehicle:          QGroundControl.multiVehicleManager.activeVehicle
    property real   _yaw:                   _activeVehicle ? _activeVehicle.heading.rawValue : 0
    property real   _yawRad:                _yaw * Math.PI / 180
    property real   _yawStep:               5 //degree
    property Fact   _moveStepFact:          _flyViewSettings.vehicleMoveStep
    property real   _moveStep:              _moveStepFact.rawValue
    property real   _altLimit:              QGroundControl.settingsManager.flyViewSettings.guidedMinimumAltitude.rawValue
    property bool   _isMoving:              false
    property real   _distance:              _activeVehicle ? _activeVehicle.distanceSensors.rotationPitch270.rawValue : NaN
    property real   _velocityStep:          0 // m/s // posvel 제어는 나중에 해보는걸로
    property real   _distanceMin:           _activeVehicle ? _activeVehicle.distanceSensors.minDistance.rawValue : NaN
    property real   _distanceMax:           _activeVehicle ? _activeVehicle.distanceSensors.maxDistance.rawValue : NaN
    property bool   _distanceAvailable:     _distance && (_distance > _distanceMin) && (_distance < _distanceMax)
    property real   _relAltitude:           _activeVehicle ? _activeVehicle.altitudeRelative.rawValue : NaN
    property bool   _isCustomCommandEnabled: _activeVehicle ? _activeVehicle.isCustomCommandEnabled : false

    property bool   _isGuidedEnable:        _activeVehicle && _activeVehicle.flying

    property real   _treshHoldAlt : 10.0
    property var    stepValues:             [0.2, 0.5, 1.0, 2.0, 3.0]
    property int    receivedTagId: 0
    property int    autoSequenceIndex: 0

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    Connections {
        target: _activeVehicle
        onRequestConfirmationReceived: (customCmd, show, tagId, enableAutoSequence, sequenceIndex) => {
            if (customCmd === 1) {
                autoSequenceIndex = sequenceIndex
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: false
    }

    Rectangle {
        id: sequenceIndicator
        width: ScreenTools.defaultFontPixelHeight * 5.5
        height:parent.height
        color: "transparent"
        visible: _isCustomCommandEnabled

        anchors.right: mainGridLayout.left
        anchors.verticalCenter: mainGridLayout.verticalCenter
        Column {
            spacing: ScreenTools.defaultFontPixelHeight / 4
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter

            // 시퀀스 모델: sequenceIndex 값과 표시할 텍스트를 정의
            ListModel {
                id: sequenceModel
                ListElement { sequenceIndex: 1; labelText: "S1 시퀀스 시작" }
                ListElement { sequenceIndex: 2; labelText: "S2 하강 접근" }
                ListElement { sequenceIndex: 3; labelText: "S3 화물칸 개방" }
                ListElement { sequenceIndex: 4; labelText: "S4 화물 투하" }
                ListElement { sequenceIndex: 5; labelText: "S5 화물칸 닫기" }
                ListElement { sequenceIndex: 6; labelText: "S6 고도 상승" }
                ListElement { sequenceIndex: 7; labelText: "S7 모드 변경" }
                ListElement { sequenceIndex: 99; labelText: "S6 시퀀스 종료" }
            }

            Repeater {
                model: sequenceModel
                delegate:   Rectangle {
                    readonly property bool selected: autoSequenceIndex === model.sequenceIndex

                    color: selected ? qgcPal.buttonHighlight : qgcPal.window
                    radius: ScreenTools.defaultFontPixelHeight / 4
                    width: ScreenTools.defaultFontPixelHeight * 5
                    height: ScreenTools.defaultFontPixelHeight * 1.5
                    opacity: 0.6

                    QGCLabel {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: _margins / 2
                        text: model.labelText
                    }

                    Timer {
                        interval: 500
                        repeat: true
                        running: parent.selected
                        onTriggered: parent.opacity = (parent.opacity === 1.0) ? 0.6 : 1.0
                    }

                    onSelectedChanged: {
                        opacity = selected ? 0.6 : 1.0
                    }
                }
            }
        }
    }

    GridLayout {
        id:                         mainGridLayout
        anchors.verticalCenter:     parent.verticalCenter
        anchors.right:              parent.right
        anchors.margins:            _margins / 2
        columnSpacing:              _margins
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
            enabled:            _isGuidedEnable && !_isCustomCommandEnabled
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/arrow-thin-up.svg"
            text:               "UP"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                _activeVehicle.setPositionAndVelocityTargetLocalNed(0,0,_moveStep,0,0,0,0,false)
            }
        }

        QGCColumnButton{
            id:                 stepTurnLeft
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable && !_isCustomCommandEnabled
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/cheveron-left.svg"
            text:               "T.LFT"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                var targetYaw = -_yawStep * Math.PI / 180
                _activeVehicle.setPositionAndVelocityTargetLocalNed(0,0,0,0,0,0,targetYaw,false)
            }
        }

        QGCColumnButton{
            id:                 stepForward
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable && !_isCustomCommandEnabled
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/arrow-thick-up.svg"
            text:               "FWD"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                _activeVehicle.setPositionAndVelocityTargetLocalNed(_moveStep,0,0,_velocityStep,0,0,0,false)
            }
        }

        QGCColumnButton{
            id:                 stepTurnRight
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable && !_isCustomCommandEnabled
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/cheveron-right.svg"
            text:               "T.RGHT"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                var targetYaw = _yawStep * Math.PI / 180
                _activeVehicle.setPositionAndVelocityTargetLocalNed(0,0,0,0,0,0,targetYaw,false)
            }
        }

        QGCColumnButton{
            id:                 stepTargetAlt
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable && _distanceAvailable && !_isCustomCommandEnabled
            opacity:            enabled ? 1 : 0.4

            iconSource:          _distanceAvailable ? (_distance >= _treshHoldAlt ? "/InstrumentValueIcons/arrow-thin-down.svg" : "/InstrumentValueIcons/arrow-thin-up.svg") : "/InstrumentValueIcons/pause.svg"
            text:               _distanceAvailable ? (_distance >= _treshHoldAlt ? targetAltMin+"M" : targetAltMax+"M") : "NONE"
            font.pointSize:     _fontSize * 0.7

            property real targetAltMin: 3.5
            property real targetAltMax: 15.0

            onClicked: {
                if(_activeVehicle && _distanceAvailable) {
                    var altTarget = 0
                    if( _distance >= _treshHoldAlt ) { // down
                        altTarget = -(_distance - targetAltMin)
                        _activeVehicle.sendCommand(1, 178, 1, 3, 0.7, -1, 0, 0, 0, 0)
                        _activeVehicle.setPositionAndVelocityTargetLocalNed(0,0,altTarget,0,0,-_velocityStep,0,false)
                    } else { // up
                        altTarget = (targetAltMax - _relAltitude )
                        _activeVehicle.setPositionAndVelocityTargetLocalNed(0,0,altTarget,0,0,_velocityStep,0,false)
                    }
                }
            }
        }

        QGCColumnButton{
            id:                 stepLeft
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable && !_isCustomCommandEnabled
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/arrow-thick-left.svg"
            text:               "LEFT"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                _activeVehicle.setPositionAndVelocityTargetLocalNed(0,-_moveStep,0,0,-_velocityStep,0,0,false)
            }
        }

        QGCColumnButton{
            id:                 stepStop
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable && !_isCustomCommandEnabled
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/pause.svg"
            text:               "STOP"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                //_activeVehicle.setPositionAndVelocityTargetLocalNed(0,0,0,0,0,0,0,false)
                _activeVehicle.pauseVehicle()
            }
        }

        QGCColumnButton{
            id:                 stepRight
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable && !_isCustomCommandEnabled
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/arrow-thick-right.svg"
            text:               "RIGHT"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                _activeVehicle.setPositionAndVelocityTargetLocalNed(0,_moveStep,0,0,_velocityStep,0,0,false)
            }
        }

        QGCColumnButton{
            id:                 stepDown
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable && (_distanceAvailable || ((_distance - _moveStep) > _altLimit)) && !_isCustomCommandEnabled
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/arrow-thin-down.svg"
            text:               "DOWN"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                if (isNaN(_distance) || _distance === 0 || (_distance !== 0 && (_distance - _moveStep) > _altLimit)) {
                    _activeVehicle.setPositionAndVelocityTargetLocalNed(0,0,-_moveStep,0,0,0,0,false)
                }
            }
        }

        QGCColumnButton{
            id:                 stepHalf
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable && !_isCustomCommandEnabled
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
            enabled:            _isGuidedEnable && !_isCustomCommandEnabled
            opacity:            enabled ? 1 : 0.4

            iconSource:         "/InstrumentValueIcons/arrow-thick-down.svg"
            text:               "BACK"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                _activeVehicle.setPositionAndVelocityTargetLocalNed(-_moveStep,0,0,-_velocityStep,0,0,0,false)
            }
        }

        QGCColumnButton{
            id:                 stepOne
            implicitWidth:      _idealWidth
            implicitHeight:     width
            enabled:            _isGuidedEnable && !_isCustomCommandEnabled
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
            enabled:            _activeVehicle && (_distanceAvailable && _distance < _treshHoldAlt) && !_isCustomCommandEnabled

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
            enabled:            _activeVehicle && !_isCustomCommandEnabled
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
            Layout.fillHeight:  true
            Layout.fillWidth:   true
            implicitWidth:      _idealWidth
            enabled:            _isGuidedEnable && _activeVehicle.flying && _distanceAvailable
            opacity:            enabled ? 1 : 0.4

            Layout.columnSpan:  2

            iconSource:         ""//"/InstrumentValueIcons/play.svg"
            text:               _isCustomCommandEnabled ? "Stop.Seq" : "Auto.Seq"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                var autoAction = _isCustomCommandEnabled ? 2 : 1
                _activeVehicle.sendCommand(191, 31010, 1, 1, 0, receivedTagId, autoAction, 0, 0, 0)
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
                labelText:          _activeVehicle ? _moveStep.toFixed(1) + " m" : "no value"
            }
            LabelledLabel {
                Layout.fillWidth:   true
                label:              "상대 고도"
                labelText:          _activeVehicle ? _activeVehicle.altitudeRelative.valueString + " m" : "no value"
            }
            LabelledLabel {
                Layout.fillWidth:   true
                label:              "라이다 고도계"
                labelText:          _activeVehicle ? _distance.toFixed(1) + " m" : "no value"
            }
            // LabelledLabel {
            //     Layout.fillWidth:   true
            //     label:              "시퀀스 인덱스"
            //     labelText:          activeVehicle ? autoSequenceIndex : "no value"
            // }
            // LabelledLabel {
            //     Layout.fillWidth:   true
            //     label:              "커맨드 가능"
            //     labelText:          activeVehicle ? _isCustomCommandEnabled : "no value"
            // }
        }
    }
}
