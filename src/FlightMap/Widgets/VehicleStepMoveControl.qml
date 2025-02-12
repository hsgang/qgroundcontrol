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
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            ColumnLayout{

                QGCLabel{
                    text: "스텝 단위"
                    font.pointSize: _fontSize
                    leftPadding:    ScreenTools.defaultFontPixelWidth
                }
                QGCLabel{
                    text: "상대좌표X"
                    font.pointSize: _fontSize
                    leftPadding:    ScreenTools.defaultFontPixelWidth
                }
                QGCLabel{
                    text: "상대좌표Y"
                    font.pointSize: _fontSize
                    leftPadding:    ScreenTools.defaultFontPixelWidth
                }
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
                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 10

                QGCLabel{
                    text: activeVehicle ? _moveStep + " m" : "no value"
                    font.pointSize: _fontSize
                    Layout.alignment: Qt.AlignRight
                }
                QGCLabel{
                    text: activeVehicle ? activeVehicle.localPosition.x.valueString + " m" : "no value"
                    font.pointSize: _fontSize
                    Layout.alignment: Qt.AlignRight
                }
                QGCLabel{
                    text: activeVehicle ? activeVehicle.localPosition.y.valueString + " m" : "no value"
                    font.pointSize: _fontSize
                    Layout.alignment: Qt.AlignRight
                }
                QGCLabel{
                    text: activeVehicle ? activeVehicle.altitudeRelative.valueString + " m" : "no value"
                    font.pointSize: _fontSize
                    Layout.alignment: Qt.AlignRight
                }
                QGCLabel{
                    text: activeVehicle ? activeVehicle.distanceSensors.rotationPitch270.valueString + " m" : "no value"
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

        Rectangle {
            id:                 stepUp
            width:              _idealWidth // - anchorsMargins
            height:             width
            radius:             _margins
            color:              "transparent"
            border.color:       qgcPal.text
            border.width:       1
            scale:              stepUpPress.pressedButtons ? 0.95 : 1

            QGCLabel {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                text:       "▲상승"
            }

            // QGCColoredImage {
            //     anchors.verticalCenter: parent.verticalCenter
            //     anchors.horizontalCenter: parent.horizontalCenter
            //     height:             parent.height * 0.6
            //     width:              height
            //     source:             "/InstrumentValueIcons/zoom-in.svg"
            //     sourceSize.height:  height
            //     fillMode:           Image.PreserveAspectFit
            //     mipmap:             true
            //     smooth:             true
            //     color:              enabled ? qgcPal.text : qgcPalDisabled.text
            //     enabled:            true
            // }

            MouseArea {
                id:             stepUpPress
                anchors.fill:   parent
                onClicked: {
                    activeVehicle.setPositionTargetLocalNed(0,0,_moveStep,0,false)
                }
            }
        }

        Rectangle {
            id:                 stepTurnLeft
            width:              _idealWidth
            height:             width
            radius:             _margins
            color:              "transparent"
            border.color:       qgcPal.text
            border.width:       1
            scale:              stepTurnLeftPress.pressedButtons ? 0.95 : 1

            QGCLabel {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                text:       "<<"
            }

            // QGCColoredImage {
            //     anchors.verticalCenter: parent.verticalCenter
            //     anchors.horizontalCenter: parent.horizontalCenter
            //     height:             parent.height * 0.6
            //     width:              height
            //     source:             "/InstrumentValueIcons/zoom-in.svg"
            //     sourceSize.height:  height
            //     fillMode:           Image.PreserveAspectFit
            //     mipmap:             true
            //     smooth:             true
            //     color:              enabled ? qgcPal.text : qgcPalDisabled.text
            //     enabled:            true
            // }

            MouseArea {
                id:             stepTurnLeftPress
                anchors.fill:   parent
                onClicked: {
                    //var targetYaw = (_yaw + 10) % 360 * Math.PI / 180
                    var targetYaw = -_yawStep * Math.PI / 180
                    activeVehicle.setPositionTargetLocalNed(0,0,0,targetYaw,false)                }
            }
        }

        Rectangle {
            id:                 stepForward
            Layout.alignment:   Qt.AlignHCenter
            width:              _idealWidth
            height:             width
            radius:             _margins
            color:      "transparent"
            border.color:       qgcPal.text
            border.width:       1
            scale:              stepForwardPress.pressedButtons ? 0.95 : 1

            QGCColoredImage {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                height:             parent.height * 0.6
                width:              height
                source:             "/InstrumentValueIcons/arrow-thick-up.svg"
                sourceSize.height:  height
                fillMode:           Image.PreserveAspectFit
                mipmap:             true
                smooth:             true
                color:              enabled ? qgcPal.text : qgcPalDisabled.text
                enabled:            true
            }

            MouseArea {
                id: stepForwardPress
                anchors.fill:   parent
                onClicked: {
                    activeVehicle.setPositionTargetLocalNed(_moveStep,0,0,0,false)
                }
            }
        }

        Rectangle {
            id:                 stepTurnRight
            Layout.alignment:   Qt.AlignHCenter
            width:              _idealWidth
            height:             width
            radius:             _margins
            color:      "transparent"
            border.color:       qgcPal.text
            border.width:       1
            scale:              stepTurnRightPress.pressedButtons ? 0.95 : 1

            QGCLabel {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                text:       ">>"
            }

            // QGCColoredImage {
            //     anchors.verticalCenter: parent.verticalCenter
            //     anchors.horizontalCenter: parent.horizontalCenter
            //     height:             parent.height * 0.6
            //     width:              height
            //     source:             "/InstrumentValueIcons/arrow-base-down.svg"
            //     sourceSize.height:  height
            //     fillMode:           Image.PreserveAspectFit
            //     mipmap:             true
            //     smooth:             true
            //     color:              enabled ? qgcPal.text : qgcPalDisabled.text
            //     enabled:            true
            // }

            MouseArea {
                id:             stepTurnRightPress
                anchors.fill:   parent
                onClicked: {
                    //var targetYaw = (_yaw + 10) % 360 * Math.PI / 180
                    var targetYaw = _yawStep * Math.PI / 180
                    activeVehicle.setPositionTargetLocalNed(0,0,0,targetYaw,false)
                }
            }
        }

        Rectangle {
            id:                 stepAltStop
            Layout.alignment:   Qt.AlignHCenter
            width:              _idealWidth
            height:             width
            radius:             _margins
            color:      "transparent"
            border.color:       qgcPal.text
            border.width:       1
            scale:              stepAltStopPress.pressedButtons ? 0.95 : 1

            QGCLabel {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                text:       "정지"
            }

            // QGCColoredImage {
            //     anchors.verticalCenter: parent.verticalCenter
            //     anchors.horizontalCenter: parent.horizontalCenter
            //     height:             parent.height * 0.6
            //     width:              height
            //     source:             "/InstrumentValueIcons/target.svg"
            //     sourceSize.height:  height
            //     fillMode:           Image.PreserveAspectFit
            //     mipmap:             true
            //     smooth:             true
            //     color:              enabled ? qgcPal.text : qgcPalDisabled.text
            //     enabled:            true
            // }

            MouseArea {
                id:             stepAltStopPress
                anchors.fill:   parent
                onClicked: {
                    activeVehicle.setPositionTargetLocalNed(0,0,0,0,false)
                }
            }
        }

        Rectangle {
            id:                 stepLeft
            Layout.alignment:   Qt.AlignHCenter
            width:              _idealWidth
            height:             width
            radius:             _margins
            color:      "transparent"
            border.color:       qgcPal.text
            border.width:       1
            scale:              stepLeftPress.pressedButtons ? 0.95 : 1

            QGCColoredImage {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                height:             parent.height * 0.6
                width:              height
                source:             "/InstrumentValueIcons/arrow-thick-left.svg"
                sourceSize.height:  height
                fillMode:           Image.PreserveAspectFit
                mipmap:             true
                smooth:             true
                color:              enabled ? qgcPal.text : qgcPalDisabled.text
                enabled:            true
            }

            MouseArea {
                id:             stepLeftPress
                anchors.fill:   parent
                onClicked: {
                    activeVehicle.setPositionTargetLocalNed(0,-_moveStep,0,0,false)
                }
            }
        }

        Rectangle {
            id:                 stepStop
            Layout.alignment:   Qt.AlignHCenter
            width:              _idealWidth
            height:             width
            radius:             _margins
            color:      "transparent"
            border.color:       qgcPal.text
            border.width:       1
            scale:              stepStopPress.pressedButtons ? 0.95 : 1

            QGCLabel {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                text:       "정지"
            }

            // QGCColoredImage {
            //     anchors.verticalCenter: parent.verticalCenter
            //     anchors.horizontalCenter: parent.horizontalCenter
            //     height:             parent.height * 0.6
            //     width:              height
            //     source:             "/InstrumentValueIcons/target.svg"
            //     sourceSize.height:  height
            //     fillMode:           Image.PreserveAspectFit
            //     mipmap:             true
            //     smooth:             true
            //     color:              enabled ? qgcPal.text : qgcPalDisabled.text
            //     enabled:            true
            // }

            MouseArea {
                id:             stepStopPress
                anchors.fill:   parent
                onClicked: {
                    activeVehicle.setPositionTargetLocalNed(0,0,0,0,false)
                }
            }
        }

        Rectangle {
            id:                 stepRight
            Layout.alignment:   Qt.AlignHCenter
            width:              _idealWidth
            height:             width
            radius:             _margins
            color:      "transparent"
            border.color:       qgcPal.text
            border.width:       1
            scale:              stepRightPress.pressedButtons ? 0.95 : 1

            QGCColoredImage {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                height:             parent.height * 0.6
                width:              height
                source:             "/InstrumentValueIcons/arrow-thick-right.svg"
                sourceSize.height:  height
                fillMode:           Image.PreserveAspectFit
                mipmap:             true
                smooth:             true
                color:              enabled ? qgcPal.text : qgcPalDisabled.text
                enabled:            true
            }

            MouseArea {
                id:             stepRightPress
                anchors.fill:   parent
                onClicked: {
                    activeVehicle.setPositionTargetLocalNed(0,_moveStep,0,0,false)
                }
            }
        }

        Rectangle {
            id:                 stepDown
            Layout.alignment:   Qt.AlignHCenter
            width:              _idealWidth
            height:             width
            radius:             _margins
            color:      "transparent"
            border.color:       qgcPal.text
            border.width:       1
            scale:              stepDownPress.pressedButtons ? 0.95 : 1

            QGCLabel {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                text:       "▼하강"
            }

            // QGCColoredImage {
            //     anchors.verticalCenter: parent.verticalCenter
            //     anchors.horizontalCenter: parent.horizontalCenter
            //     height:             parent.height * 0.6
            //     width:              height
            //     source:             "/InstrumentValueIcons/zoom-out.svg"
            //     sourceSize.height:  height
            //     fillMode:           Image.PreserveAspectFit
            //     mipmap:             true
            //     smooth:             true
            //     color:              enabled ? qgcPal.text : qgcPalDisabled.text
            //     enabled:            true
            // }

            MouseArea {
                id:             stepDownPress
                anchors.fill:   parent
                onClicked: {
                    activeVehicle.setPositionTargetLocalNed(0,0,-_moveStep,0,false)
                }
            }
        }

        Rectangle {
            id:                 stepDummy1
            Layout.alignment:   Qt.AlignHCenter
            width:              _idealWidth
            height:             width
            radius:             _margins
            color:      "transparent"
            border.color:       qgcPal.text
            border.width:       1
            scale:              stepDummy1Press.pressedButtons ? 0.95 : 1

            QGCLabel {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                text:       "0.5"
            }

            // QGCColoredImage {
            //     anchors.verticalCenter: parent.verticalCenter
            //     anchors.horizontalCenter: parent.horizontalCenter
            //     height:             parent.height * 0.6
            //     width:              height
            //     source:             "/InstrumentValueIcons/zoom-out.svg"
            //     sourceSize.height:  height
            //     fillMode:           Image.PreserveAspectFit
            //     mipmap:             true
            //     smooth:             true
            //     color:              enabled ? qgcPal.text : qgcPalDisabled.text
            //     enabled:            true
            // }

            MouseArea {
                id:             stepDummy1Press
                anchors.fill:   parent
                onClicked: {
                    activeVehicle.setPositionTargetLocalNed(0,0,0,0,false)
                    _moveStepFact.value = 0.5
                }
            }
        }

        Rectangle {
            id:                 stepBack
            Layout.alignment:   Qt.AlignHCenter
            width:              _idealWidth
            height:             width
            radius:             _margins
            color:      "transparent"
            border.color:       qgcPal.text
            border.width:       1
            scale:              stepBackPress.pressedButtons ? 0.95 : 1

            QGCColoredImage {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                height:             parent.height * 0.6
                width:              height
                source:             "/InstrumentValueIcons/arrow-thick-down.svg"
                sourceSize.height:  height
                fillMode:           Image.PreserveAspectFit
                mipmap:             true
                smooth:             true
                color:              enabled ? qgcPal.text : qgcPalDisabled.text
                enabled:            true
            }

            MouseArea {
                id:             stepBackPress
                anchors.fill:   parent
                onClicked: {
                    activeVehicle.setPositionTargetLocalNed(-_moveStep,0,0,0,false)
                }
            }
        }

        Rectangle {
            id:                 stepDummy2
            Layout.alignment:   Qt.AlignHCenter
            width:              _idealWidth
            height:             width
            radius:             _margins
            color:      "transparent"
            border.color:       qgcPal.text
            border.width:       1
            scale:              stepDummy2Press.pressedButtons ? 0.95 : 1

            QGCLabel {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                text:       "1.0"
            }

            // QGCColoredImage {
            //     anchors.verticalCenter: parent.verticalCenter
            //     anchors.horizontalCenter: parent.horizontalCenter
            //     height:             parent.height * 0.6
            //     width:              height
            //     source:             "/InstrumentValueIcons/zoom-out.svg"
            //     sourceSize.height:  height
            //     fillMode:           Image.PreserveAspectFit
            //     mipmap:             true
            //     smooth:             true
            //     color:              enabled ? qgcPal.text : qgcPalDisabled.text
            //     enabled:            true
            // }

            MouseArea {
                id:             stepDummy2Press
                anchors.fill:   parent
                onClicked: {
                    activeVehicle.setPositionTargetLocalNed(0,0,0,0,false)
                    _moveStepFact.value = 1
                }
            }
        }
    }
}
