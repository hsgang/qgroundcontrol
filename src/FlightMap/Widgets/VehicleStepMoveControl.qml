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
    width:      _isCustomCommandEnabled ? (mainGridLayout.width + _margins + sequenceIndicator.width) : mainGridLayout.width + _margins
    height:     mainGridLayout.height + _margins
    color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, backgroundOpacity)
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
    property int    autoSequenceIndex: 0

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    Connections {
        target: _activeVehicle
        onRequestConfirmationReceived: (customCmd, show, tagId, enableAutoSequence, sequenceIndex) => {
            if (customCmd !== 1) {
                return
            }
            autoSequenceIndex = sequenceIndex
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
            spacing: 8
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
                    property int sequenceIndex: model.sequenceIndex
                    property string labelText: model.labelText
                    // 상위 컨텍스트의 autoSequenceIndex와 비교하여 선택 상태를 결정
                    property bool selected: autoSequenceIndex === sequenceIndex

                    // 선택 상태에 따른 배경색 적용 (기본색은 qgcPal.window)
                    color: selected ? qgcPal.buttonHighlight : qgcPal.window
                    radius: ScreenTools.defaultFontPixelHeight / 4
                    width: ScreenTools.defaultFontPixelHeight * 5
                    height: ScreenTools.defaultFontPixelHeight * 1.5
                    // 초기 불투명도 값
                    opacity: 0.6

                    QGCLabel {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: _margins / 2
                        text: labelText
                    }

                    // 선택되었을 때 깜빡이는 효과를 위한 Timer
                    Timer {
                        id: blinkTimer
                        interval: 500    // 0.5초 간격
                        repeat: true
                        running: selected
                        onTriggered: {
                            // 불투명도를 1과 0.4 사이에서 토글
                            opacity = (opacity === 1.0) ? 0.6 : 1.0;
                        }
                    }

                    // selected 프로퍼티 변경 시 Timer 재시작 및 불투명도 초기화
                    onSelectedChanged: {
                        if (selected) {
                            blinkTimer.start();
                        } else {
                            blinkTimer.stop();
                            opacity = 1.0;
                        }
                    }
                }
            }
        }
    }

    // Rectangle {
    //     id: sequenceIndicator
    //     width: ScreenTools.defaultFontPixelHeight * 6
    //     height:parent.height
    //     color: "transparent"

    //     anchors.right: mainGridLayout.left
    //     anchors.verticalCenter: mainGridLayout.verticalCenter

    //     ColumnLayout {
    //         id: indicatorColumn
    //         anchors.fill: parent
    //         anchors.margins: _margins

    //         property real rectWidth : ScreenTools.defaultFontPixelHeight * 5
    //         property real rectHeight : ScreenTools.defaultFontPixelHeight * 1.5

    //         Rectangle {
    //             color: autoSequenceIndex == 1 ? qgcPal.buttonHighlight : qgcPal.window
    //             radius: ScreenTools.defaultFontPixelHeight / 4
    //             width: indicatorColumn.rectWidth
    //             height: indicatorColumn.rectHeight
    //             QGCLabel {
    //                 anchors.centerIn: parent
    //                 text: "S1 시퀀스 시작"
    //             }
    //         }
    //         Rectangle {
    //             color: autoSequenceIndex == 2 ? qgcPal.buttonHighlight : qgcPal.window
    //             radius: ScreenTools.defaultFontPixelHeight / 4
    //             width: indicatorColumn.rectWidth
    //             height: indicatorColumn.rectHeight
    //             QGCLabel {
    //                 anchors.centerIn: parent
    //                 text: "S2 하강 접근"
    //             }
    //         }
    //         Rectangle {
    //             color: autoSequenceIndex == 3 ? qgcPal.buttonHighlight : qgcPal.window
    //             radius: ScreenTools.defaultFontPixelHeight / 4
    //             width: indicatorColumn.rectWidth
    //             height: indicatorColumn.rectHeight
    //             QGCLabel {
    //                 anchors.centerIn: parent
    //                 text: "S3 화물 개방"
    //             }
    //         }
    //         Rectangle {
    //             color: autoSequenceIndex == 4 ? qgcPal.buttonHighlight : qgcPal.window
    //             radius: ScreenTools.defaultFontPixelHeight / 4
    //             width: indicatorColumn.rectWidth
    //             height: indicatorColumn.rectHeight
    //             QGCLabel {
    //                 anchors.centerIn: parent
    //                 text: "S4 고도 상승"
    //             }
    //         }
    //         Rectangle {
    //             color: autoSequenceIndex == 5 ? qgcPal.buttonHighlight : qgcPal.window
    //             radius: ScreenTools.defaultFontPixelHeight / 4
    //             width: indicatorColumn.rectWidth
    //             height: indicatorColumn.rectHeight
    //             QGCLabel {
    //                 anchors.centerIn: parent
    //                 text: "S5 모드 변경"
    //             }
    //         }
    //         Rectangle {
    //             color: autoSequenceIndex == 99 ? qgcPal.buttonHighlight : qgcPal.window
    //             radius: ScreenTools.defaultFontPixelHeight / 4
    //             width: indicatorColumn.rectWidth
    //             height: indicatorColumn.rectHeight
    //             QGCLabel {
    //                 anchors.centerIn: parent
    //                 text: "S6 시퀀스 종료"
    //             }
    //         }
    //     }
    // }

    GridLayout {
        id:                         mainGridLayout
        anchors.verticalCenter:     parent.verticalCenter
        //anchors.horizontalCenter:   parent.horizontalCenter
        anchors.right:              parent.right
        anchors.margins:            _margins / 2
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
            Layout.fillHeight:  true
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
            LabelledLabel {
                Layout.fillWidth:   true
                label:              "시퀀스 인덱스"
                labelText:          activeVehicle ? autoSequenceIndex : "no value"
            }
            LabelledLabel {
                Layout.fillWidth:   true
                label:              "커맨드 가능"
                labelText:          activeVehicle ? _isCustomCommandEnabled : "no value"
            }
        }
    }
}
