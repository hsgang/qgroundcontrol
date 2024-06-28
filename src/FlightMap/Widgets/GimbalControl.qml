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
    border.color:   qgcPal.text
    border.width:   1
    radius:     _margins * 1.5
    visible:    _showGimbalControl && multiVehiclePanelSelector.showSingleVehiclePanel

    property real   _margins:           ScreenTools.defaultFontPixelHeight / 2
    property real   _idealWidth:        ScreenTools.defaultFontPixelWidth * 7
    property real   anchorsMargins:     _margins
    property real   _fontSize:          ScreenTools.isMobile ? ScreenTools.defaultFontPointSize * 0.8 : ScreenTools.defaultFontPointSize
    property real   backgroundOpacity:  QGroundControl.settingsManager.flyViewSettings.flyviewWidgetOpacity.rawValue

    // The following properties relate to a simple camera
    property var    _flyViewSettings:       QGroundControl.settingsManager.flyViewSettings
    property bool   _showGimbalControl:     _flyViewSettings.showGimbalControlPannel.rawValue

    // The following settings and functions unify between a mavlink camera and a simple video stream for simple access

    property var    activeVehicle:          QGroundControl.multiVehicleManager.activeVehicle
    property var    gimbalController:         activeVehicle.gimbalController
    property var    activeGimbal:             gimbalController.activeGimbal
    property bool   _gimbalAvailable:         activeGimbal ? true : false
    property bool   _gimbalRollAvailable:     activeGimbal && activeGimbal.curRoll ? true : false
    property bool   _gimbalPitchAvailable:    activeGimbal && activeGimbal.curPitch ? true : false
    property bool   _gimbalYawAvailable:      activeGimbal && activeGimbal.curYaw ? true : false
    property real   _gimbalRoll:              _gimbalAvailable && _gimbalRollAvailable ? activeGimbal.curRoll : 0
    property real   _gimbalPitch:             _gimbalAvailable && _gimbalPitchAvailable ? activeGimbal.curPitch : 0
    property real   _gimbalYaw:               _gimbalAvailable && _gimbalYawAvailable ? activeGimbal.curYaw : 0
    property string _gimbalRollString:        activeVehicle && _gimbalRollAvailable ? _gimbalRoll.toFixed(2) : "--"
    property string _gimbalPitchString:       activeVehicle && _gimbalPitchAvailable ? _gimbalPitch.toFixed(2) : "--"
    property string _gimbalYawString:         activeVehicle && _gimbalYawAvailable ? _gimbalYaw.toFixed(2) : "--"

    property double _localPitch: 0.0
    property double _localYaw: 0.0
    property int    _gimbalModeStatus: 0

    Rectangle{
        anchors.top: parent.bottom
        anchors.topMargin: _margins / 2
        anchors.right: parent.right
        anchors.horizontalCenter: parent.horizontalCenter
        width:          gimbalAngleValueRow.width
        height:         gimbalAngleValueRow.height
        color:          Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, backgroundOpacity)
        radius:         _margins / 2
        ColumnLayout{
            id: gimbalAngleValueRow

            QGCLabel{
                text: activeGimbal ? "P: " + activeGimbal.absolutePitch.rawValue.toFixed(1) : "no value"
                font.pointSize: _fontSize
            }
            QGCLabel{
                text: activeGimbal ? "Y: " + activeGimbal.bodyYaw.rawValue.toFixed(1) : "no value"
                font.pointSize: _fontSize
            }
            QGCLabel{
                text: activeGimbal ? "R: " + activeGimbal.absoluteRoll.rawValue.toFixed(1) : "no value"
                font.pointSize: _fontSize
            }
            QGCLabel{
                text: activeGimbal ? "gimbalCnt: " + gimbalController.gimbals.count.toFixed(0) : "no value"
                font.pointSize: _fontSize
            }
            QGCLabel{
                text: activeGimbal ? "gimbalId: " + activeGimbal.deviceId.rawValue.toFixed(0) : "no value"
                font.pointSize: _fontSize
            }
        }
    }

    GridLayout {
        id:                         mainGridLayout
        anchors.verticalCenter:     parent.verticalCenter
        anchors.horizontalCenter:   parent.horizontalCenter
        columnSpacing:              ScreenTools.defaultFontPixelHeight / 2
        rowSpacing:                 columnSpacing
        columns:                    3

        Rectangle {
            id:                 zoomIn
            width:              _idealWidth - anchorsMargins
            height:             width
            radius:             _margins
            color:              "transparent"
            border.color:       qgcPal.text
            border.width:       1
            scale:              zoomInPress.pressedButtons ? 0.95 : 1

            QGCColoredImage {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                height:             parent.height * 0.6
                width:              height
                source:             "/InstrumentValueIcons/zoom-in.svg"
                sourceSize.height:  height
                fillMode:           Image.PreserveAspectFit
                mipmap:             true
                smooth:             true
                color:              enabled ? qgcPal.text : qgcPalDisabled.text
                enabled:            true
            }

            MouseArea {
                id:             zoomInPress
                anchors.fill:   parent
                onClicked: {
                    _mavlinkCamera.stepZoom(1)
                }
            }
        }

        Rectangle {
            id:                 gimbalUp
            Layout.alignment:   Qt.AlignHCenter
            width:              _idealWidth - anchorsMargins
            height:             width
            radius:             _margins
            color:      "transparent"
            border.color:       qgcPal.text
            border.width:       1
            scale:              gimbalUpPress.pressedButtons ? 0.95 : 1

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
                id: gimbalUpPress
                anchors.fill:   parent
                onClicked: {
                    _localPitch += 2.0
                    //-- Arbitrary range
                    if(_localPitch < -90.0) _localPitch = -90.0;
                    if(_localPitch >  35.0) _localPitch =  35.0;
                    gimbalController.sendPitchBodyYaw(_localPitch, _localYaw, true)
                }
            }
        }

        Rectangle {
            id:                 baseDown
            Layout.alignment:   Qt.AlignHCenter
            width:              _idealWidth - anchorsMargins
            height:             width
            radius:             _margins
            color:      "transparent"
            border.color:       qgcPal.text
            border.width:       1
            scale:              baseDownPress.pressedButtons ? 0.95 : 1

            QGCColoredImage {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                height:             parent.height * 0.6
                width:              height
                source:             "/InstrumentValueIcons/arrow-base-down.svg"
                sourceSize.height:  height
                fillMode:           Image.PreserveAspectFit
                mipmap:             true
                smooth:             true
                color:              enabled ? qgcPal.text : qgcPalDisabled.text
                enabled:            true
            }

            MouseArea {
                id:             baseDownPress
                anchors.fill:   parent
                onClicked: {
                    gimbalController.sendPitchBodyYaw(-90.0, 0.0, true)
                }
            }
        }

        Rectangle {
            id:                 gimbalLeft
            Layout.alignment:   Qt.AlignHCenter
            width:              _idealWidth - anchorsMargins
            height:             width
            radius:             _margins
            color:      "transparent"
            border.color:       qgcPal.text
            border.width:       1
            scale:              gimbalLeftPress.pressedButtons ? 0.95 : 1

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
                id:             gimbalLeftPress
                anchors.fill:   parent
                onClicked: {
                    _localYaw += -2
                    //-- Arbitrary range
                    if(_localYaw < -90.0) _localYaw = -90.0;
                    if(_localYaw >  90.0) _localYaw =  90.0;
                    gimbalController.sendPitchBodyYaw(_localPitch, _localYaw, true)
                }
            }
        }

        Rectangle {
            id:                 gimbalHome
            Layout.alignment:   Qt.AlignHCenter
            width:              _idealWidth - anchorsMargins
            height:             width
            radius:             _margins
            color:      "transparent"
            border.color:       qgcPal.text
            border.width:       1
            scale:              gimbalHomePress.pressedButtons ? 0.95 : 1

            QGCColoredImage {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                height:             parent.height * 0.6
                width:              height
                source:             "/InstrumentValueIcons/target.svg"
                sourceSize.height:  height
                fillMode:           Image.PreserveAspectFit
                mipmap:             true
                smooth:             true
                color:              enabled ? qgcPal.text : qgcPalDisabled.text
                enabled:            true
            }

            MouseArea {
                id:             gimbalHomePress
                anchors.fill:   parent
                onClicked: {
                    gimbalController.centerGimbal()
                    _localPitch = 0
                    _localYaw = 0
                }
            }
        }

        Rectangle {
            id:                 gimbalRight
            Layout.alignment:   Qt.AlignHCenter
            width:              _idealWidth - anchorsMargins
            height:             width
            radius:             _margins
            color:      "transparent"
            border.color:       qgcPal.text
            border.width:       1
            scale:              gimbalRightPress.pressedButtons ? 0.95 : 1

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
                id:             gimbalRightPress
                anchors.fill:   parent
                onClicked: {
                    _localYaw += 2
                    //-- Arbitrary range
                    if(_localYaw < -90.0) _localYaw = -90.0;
                    if(_localYaw >  90.0) _localYaw =  90.0;
                    gimbalController.sendPitchBodyYaw(_localPitch, _localYaw, true)
                }
            }
        }

        Rectangle {
            id:                 zoomOut
            Layout.alignment:   Qt.AlignHCenter
            width:              _idealWidth - anchorsMargins
            height:             width
            radius:             _margins
            color:      "transparent"
            border.color:       qgcPal.text
            border.width:       1
            scale:              zoomOutPress.pressedButtons ? 0.95 : 1

            QGCColoredImage {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                height:             parent.height * 0.6
                width:              height
                source:             "/InstrumentValueIcons/zoom-out.svg"
                sourceSize.height:  height
                fillMode:           Image.PreserveAspectFit
                mipmap:             true
                smooth:             true
                color:              enabled ? qgcPal.text : qgcPalDisabled.text
                enabled:            true
            }

            MouseArea {
                id:             zoomOutPress
                anchors.fill:   parent
                onClicked: {
                    _mavlinkCamera.stepZoom(-1)
                }
            }
        }

        Rectangle {
            id:                 gimbalDown
            Layout.alignment:   Qt.AlignHCenter
            width:              _idealWidth - anchorsMargins
            height:             width
            radius:             _margins
            color:      "transparent"
            border.color:       qgcPal.text
            border.width:       1
            scale:              gimbalDownPress.pressedButtons ? 0.95 : 1

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
                id:             gimbalDownPress
                anchors.fill:   parent
                onClicked: {
                    _localPitch += -2
                    //-- Arbitrary range
                    if(_localPitch < -90.0) _localPitch = -90.0;
                    if(_localPitch >  35.0) _localPitch =  35.0;
                    gimbalController.sendPitchBodyYaw(_localPitch, _localYaw, true)
                }
            }
        }

        Rectangle {
            id:                 gimbalMode
            Layout.alignment:   Qt.AlignHCenter
            width:              _idealWidth - anchorsMargins
            height:             width
            radius:             _margins
            color:      "transparent"
            border.color:       qgcPal.text
            border.width:       1
            scale:              gimbalModePress.pressedButtons ? 0.95 : 1

            QGCColoredImage {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                height:             parent.height * 0.6
                width:              height
                source:             "/InstrumentValueIcons/navigation-more.svg"
                sourceSize.height:  height
                fillMode:           Image.PreserveAspectFit
                mipmap:             true
                smooth:             true
                color:              enabled ? qgcPal.text : qgcPalDisabled.text
                enabled:            true
            }

            MouseArea {
                id:             gimbalModePress
                anchors.fill:   parent
                onClicked: {
                    gimbalController.setGimbalRcTargeting()
                }
            }
        }
    }
}
