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
import QGroundControl.FactControls

Rectangle {
    id:         gimbalControlPannel
    width:      mainGridLayout.width + _margins
    height:     mainGridLayout.height + _margins
    color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, backgroundOpacity)
    // border.color:   Qt.rgba(qgcPal.text.r, qgcPal.text.g, qgcPal.text.b, 0.5)
    // border.width:   1
    radius:     _margins
    //visible:    _showGimbalControl && multiVehiclePanelSelector.showSingleVehiclePanel

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
    property var    gimbalController:       activeVehicle ? activeVehicle.gimbalController : undefined
    property var    activeGimbal:           activeVehicle ? gimbalController.activeGimbal : undefined
    property bool   _gimbalAvailable:       activeGimbal ? true : false
    property bool   _gimbalRollAvailable:   activeGimbal && activeGimbal.curRoll ? true : false
    property bool   _gimbalPitchAvailable:  activeGimbal && activeGimbal.curPitch ? true : false
    property bool   _gimbalYawAvailable:    activeGimbal && activeGimbal.curYaw ? true : false
    property real   _gimbalRoll:            _gimbalAvailable && _gimbalRollAvailable ? activeGimbal.curRoll : 0
    property real   _gimbalPitch:           _gimbalAvailable && _gimbalPitchAvailable ? activeGimbal.curPitch : 0
    property real   _gimbalYaw:             _gimbalAvailable && _gimbalYawAvailable ? activeGimbal.curYaw : 0
    property string _gimbalRollString:      activeVehicle && _gimbalRollAvailable ? _gimbalRoll.toFixed(2) : "--"
    property string _gimbalPitchString:     activeVehicle && _gimbalPitchAvailable ? _gimbalPitch.toFixed(2) : "--"
    property string _gimbalYawString:       activeVehicle && _gimbalYawAvailable ? _gimbalYaw.toFixed(2) : "--"

    property double _localPitch: 0.0
    property double _localYaw: 0.0
    property int    _gimbalModeStatus: 0

    property var    _dynamicCameras:    globals.activeVehicle ? globals.activeVehicle.cameraManager : null
    property bool   _connected:         globals.activeVehicle ? !globals.activeVehicle.communicationLost : false
    property int    _curCameraIndex:    _dynamicCameras ? _dynamicCameras.currentCamera : 0
    property bool   _isCamera:          _dynamicCameras ? _dynamicCameras.cameras.count > 0 : false
    property var    _camera:            _isCamera ? _dynamicCameras.cameras.get(_curCameraIndex) : null
    property bool   _hasZoom:           _camera && _camera.hasZoom

    GridLayout {
        id:                         mainGridLayout
        anchors.verticalCenter:     parent.verticalCenter
        anchors.horizontalCenter:   parent.horizontalCenter
        columnSpacing:              _margins
        rowSpacing:                 columnSpacing
        columns:                    3

        QGCLabel{
            Layout.columnSpan: 3
            Layout.fillWidth: true
            text: "마운트 제어"
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            Layout.columnSpan: 3
            Layout.fillWidth: true
            height : 1
            color : qgcPal.groupBorder
        }

        QGCColumnButton{
            id:                 zoomIn
            implicitWidth:      _idealWidth
            implicitHeight:     width

            iconSource:         "/InstrumentValueIcons/zoom-in.svg"
            text:               "Zoom+"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                _camera.stepZoom(1)
            }
        }

        QGCColumnButton{
            id:                 gimbalUp
            implicitWidth:      _idealWidth
            implicitHeight:     width

            iconSource:         "/InstrumentValueIcons/arrow-thick-up.svg"
            text:               "UP"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                _localPitch += 2.0
                //-- Arbitrary range
                if(_localPitch < -90.0) _localPitch = -90.0;
                if(_localPitch >  35.0) _localPitch =  35.0;
                gimbalController.sendPitchBodyYaw(_localPitch, _localYaw, true)
            }
        }

        QGCColumnButton{
            id:                 baseDown
            implicitWidth:      _idealWidth
            implicitHeight:     width

            iconSource:         "/InstrumentValueIcons/arrow-base-down.svg"
            text:               "Down"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                gimbalController.sendPitchBodyYaw(-90.0, 0.0, true)
            }
        }

        QGCColumnButton{
            id:                 gimbalLeft
            implicitWidth:      _idealWidth
            implicitHeight:     width

            iconSource:         "/InstrumentValueIcons/arrow-thick-left.svg"
            text:               "Left"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                _localYaw += -2
                //-- Arbitrary range
                if(_localYaw < -90.0) _localYaw = -90.0;
                if(_localYaw >  90.0) _localYaw =  90.0;
                gimbalController.sendPitchBodyYaw(_localPitch, _localYaw, true)
            }
        }

        QGCColumnButton{
            id:                 gimbalHome
            implicitWidth:      _idealWidth
            implicitHeight:     width

            iconSource:         "/InstrumentValueIcons/target.svg"
            text:               "Center"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                gimbalController.centerGimbal()
                _localPitch = 0
                _localYaw = 0
            }
        }

        QGCColumnButton{
            id:                 gimbalRight
            implicitWidth:      _idealWidth
            implicitHeight:     width

            iconSource:         "/InstrumentValueIcons/arrow-thick-right.svg"
            text:               "Right"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                _localYaw += 2
                //-- Arbitrary range
                if(_localYaw < -90.0) _localYaw = -90.0;
                if(_localYaw >  90.0) _localYaw =  90.0;
                gimbalController.sendPitchBodyYaw(_localPitch, _localYaw, true)
            }
        }

        QGCColumnButton{
            id:                 zoomOut
            implicitWidth:      _idealWidth
            implicitHeight:     width

            iconSource:         "/InstrumentValueIcons/zoom-out.svg"
            text:               "Zoom-"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                _camera.stepZoom(-1)
            }
        }

        QGCColumnButton{
            id:                 gimbalDown
            implicitWidth:      _idealWidth
            implicitHeight:     width

            iconSource:         "/InstrumentValueIcons/arrow-thick-down.svg"
            text:               "Down"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                _localPitch += -2
                //-- Arbitrary range
                if(_localPitch < -90.0) _localPitch = -90.0;
                if(_localPitch >  35.0) _localPitch =  35.0;
                gimbalController.sendPitchBodyYaw(_localPitch, _localYaw, true)
            }
        }

        QGCColumnButton{
            id:                 gimbalMode
            implicitWidth:      _idealWidth
            implicitHeight:     width

            iconSource:         "/InstrumentValueIcons/navigation-more.svg"
            text:               "RC"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                gimbalController.setGimbalRcTargeting()
            }
        }

        Rectangle {
            Layout.columnSpan: 3
            Layout.fillWidth: true
            height : 1
            color : qgcPal.groupBorder
        }

        ColumnLayout {
            Layout.columnSpan: 3
            Layout.fillWidth: true

            LabelledLabel {
                Layout.fillWidth:   true
                label:              "Pitch"
                labelText:          activeGimbal ? activeGimbal.absolutePitch.rawValue.toFixed(1) : "no value"
            }
            LabelledLabel {
                Layout.fillWidth:   true
                label:              "Yaw"
                labelText:          activeGimbal ? activeGimbal.bodyYaw.rawValue.toFixed(1) : "no value"
            }
        }
    }
}
