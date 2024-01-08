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
import QGroundControl.Palette
import QGroundControl.Vehicle
import QGroundControl.Controllers
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
    visible:    (_mavlinkCamera || _videoStreamAvailable || _simpleCameraAvailable) && _showGimbalControl && multiVehiclePanelSelector.showSingleVehiclePanel

    property real   _margins:         ScreenTools.defaultFontPixelHeight / 2
    property real   _idealWidth:      ScreenTools.isMobile ? ScreenTools.minTouchPixels * 0.8 : (ScreenTools.defaultFontPixelWidth * 7)
    property real   anchorsMargins:   _margins
    property real   backgroundOpacity:                          QGroundControl.settingsManager.flyViewSettings.flyviewWidgetOpacity.rawValue

    property var    _activeVehicle:                             QGroundControl.multiVehicleManager.activeVehicle

    // The following properties relate to a simple camera
    property var    _flyViewSettings:                           QGroundControl.settingsManager.flyViewSettings
    property bool   _simpleCameraAvailable:                     !_mavlinkCamera && _activeVehicle && _flyViewSettings.showSimpleCameraControl.rawValue
    property bool   _onlySimpleCameraAvailable:                 !_anyVideoStreamAvailable && _simpleCameraAvailable
    property bool   _simpleCameraIsShootingInCurrentMode:       _onlySimpleCameraAvailable && !_simplePhotoCaptureIsIdle
    property bool   _showGimbalControl:                         _flyViewSettings.showGimbalControlPannel.rawValue

    // The following properties relate to a simple video stream
    property bool   _videoStreamAvailable:                      _videoStreamManager.hasVideo
    property var    _videoStreamSettings:                       QGroundControl.settingsManager.videoSettings
    property var    _videoStreamManager:                        QGroundControl.videoManager
    property bool   _videoStreamAllowsPhotoWhileRecording:      true
    property bool   _videoStreamIsStreaming:                    _videoStreamManager.streaming
    property bool   _simplePhotoCaptureIsIdle:             true
    property bool   _videoStreamRecording:                      _videoStreamManager.recording
    property bool   _videoStreamCanShoot:                       _videoStreamIsStreaming
    property bool   _videoStreamIsShootingInCurrentMode:        _videoStreamInPhotoMode ? !_simplePhotoCaptureIsIdle : _videoStreamRecording
    property bool   _videoStreamInPhotoMode:                    false

    // The following properties relate to a mavlink protocol camera
    property var    _mavlinkCameraManager:                      _activeVehicle ? _activeVehicle.cameraManager : null
    property int    _mavlinkCameraManagerCurCameraIndex:        _mavlinkCameraManager ? _mavlinkCameraManager.currentCamera : -1
    property bool   _noMavlinkCameras:                          _mavlinkCameraManager ? _mavlinkCameraManager.cameras.count === 0 : true
    property var    _mavlinkCamera:                             !_noMavlinkCameras ? (_mavlinkCameraManager.cameras.get(_mavlinkCameraManagerCurCameraIndex) && _mavlinkCameraManager.cameras.get(_mavlinkCameraManagerCurCameraIndex).paramComplete ? _mavlinkCameraManager.cameras.get(_mavlinkCameraManagerCurCameraIndex) : null) : null
    property bool   _multipleMavlinkCameras:                    _mavlinkCameraManager ? _mavlinkCameraManager.cameras.count > 1 : false
    property string _mavlinkCameraName:                         _mavlinkCamera && _multipleMavlinkCameras ? _mavlinkCamera.modelName : ""
    property bool   _noMavlinkCameraStreams:                    _mavlinkCamera ? _mavlinkCamera.streamLabels.length : true
    property bool   _multipleMavlinkCameraStreams:              _mavlinkCamera ? _mavlinkCamera.streamLabels.length > 1 : false
    property int    _mavlinCameraCurStreamIndex:                _mavlinkCamera ? _mavlinkCamera.currentStream : -1
    property bool   _mavlinkCameraHasThermalVideoStream:        _mavlinkCamera ? _mavlinkCamera.thermalStreamInstance : false
    property bool   _mavlinkCameraModeUndefined:                _mavlinkCamera ? _mavlinkCamera.cameraMode === QGCCameraControl.CAM_MODE_UNDEFINED : true
    property bool   _mavlinkCameraInVideoMode:                  _mavlinkCamera ? _mavlinkCamera.cameraMode === QGCCameraControl.CAM_MODE_VIDEO : false
    property bool   _mavlinkCameraInPhotoMode:                  _mavlinkCamera ? _mavlinkCamera.cameraMode === QGCCameraControl.CAM_MODE_PHOTO : false
    property bool   _mavlinkCameraElapsedMode:                  _mavlinkCamera && _mavlinkCamera.cameraMode === QGCCameraControl.CAM_MODE_PHOTO && _mavlinkCamera.photoMode === QGCCameraControl.PHOTO_CAPTURE_TIMELAPSE
    property bool   _mavlinkCameraHasModes:                     _mavlinkCamera && _mavlinkCamera.hasModes
    property bool   _mavlinkCameraVideoIsRecording:             _mavlinkCamera && _mavlinkCamera.videoStatus === QGCCameraControl.VIDEO_CAPTURE_STATUS_RUNNING
    property bool   _mavlinkCameraPhotoCaptureIsIdle:           _mavlinkCamera && (_mavlinkCamera.photoStatus === QGCCameraControl.PHOTO_CAPTURE_IDLE || _mavlinkCamera.photoStatus >= QGCCameraControl.PHOTO_CAPTURE_LAST)
    property bool   _mavlinkCameraStorageReady:                 _mavlinkCamera && _mavlinkCamera.storageStatus === QGCCameraControl.STORAGE_READY
    property bool   _mavlinkCameraBatteryReady:                 _mavlinkCamera && _mavlinkCamera.batteryRemaining >= 0
    property bool   _mavlinkCameraStorageSupported:             _mavlinkCamera && _mavlinkCamera.storageStatus !== QGCCameraControl.STORAGE_NOT_SUPPORTED
    property bool   _mavlinkCameraAllowsPhotoWhileRecording:    false
    property bool   _mavlinkCameraCanShoot:                     (!_mavlinkCameraModeUndefined && ((_mavlinkCameraStorageReady && _mavlinkCamera.storageFree > 0) || !_mavlinkCameraStorageSupported)) || _videoStreamManager.streaming
    property bool   _mavlinkCameraIsShooting:                   ((_mavlinkCameraInVideoMode && _mavlinkCameraVideoIsRecording) || (_mavlinkCameraInPhotoMode && !_mavlinkCameraPhotoCaptureIsIdle)) || _videoStreamManager.recording

    // The following settings and functions unify between a mavlink camera and a simple video stream for simple access

    property bool   _anyVideoStreamAvailable:                   _videoStreamManager.hasVideo
    property string _cameraName:                                _mavlinkCamera ? _mavlinkCameraName : ""
    property bool   _showModeIndicator:                         _mavlinkCamera ? _mavlinkCameraHasModes : _videoStreamManager.hasVideo
    property bool   _modeIndicatorPhotoMode:                    _mavlinkCamera ? _mavlinkCameraInPhotoMode : _videoStreamInPhotoMode || _onlySimpleCameraAvailable
    property bool   _allowsPhotoWhileRecording:                  _mavlinkCamera ? _mavlinkCameraAllowsPhotoWhileRecording : _videoStreamAllowsPhotoWhileRecording
    property bool   _switchToPhotoModeAllowed:                  !_modeIndicatorPhotoMode && (_mavlinkCamera ? !_mavlinkCameraIsShooting : true)
    property bool   _switchToVideoModeAllowed:                  _modeIndicatorPhotoMode && (_mavlinkCamera ? !_mavlinkCameraIsShooting : true)
    property bool   _videoIsRecording:                          _mavlinkCamera ? _mavlinkCameraIsShooting : _videoStreamRecording
    property bool   _canShootInCurrentMode:                     _mavlinkCamera ? _mavlinkCameraCanShoot : _videoStreamCanShoot || _simpleCameraAvailable
    property bool   _isShootingInCurrentMode:                   _mavlinkCamera ? _mavlinkCameraIsShooting : _videoStreamIsShootingInCurrentMode || _simpleCameraIsShootingInCurrentMode

    property var    _gimbalController:        _activeVehicle ? _activeVehicle.gimbalController : undefined
    property var    _activeGimbal:            _gimbalController ? _gimbalController.activeGimbal : undefined
    property bool   _gimbalAvailable:         _activeGimbal ? true : false
    property bool   _gimbalRollAvailable:     _activeGimbal && _activeGimbal.curRoll ? true : false
    property bool   _gimbalPitchAvailable:    _activeGimbal && _activeGimbal.curPitch ? true : false
    property bool   _gimbalYawAvailable:      _activeGimbal && _activeGimbal.curYaw ? true : false
    property real   _gimbalRoll:              _gimbalAvailable && _gimbalRollAvailable ? _activeGimbal.curRoll : 0
    property real   _gimbalPitch:             _gimbalAvailable && _gimbalPitchAvailable ? _activeGimbal.curPitch : 0
    property real   _gimbalYaw:               _gimbalAvailable && _gimbalYawAvailable ? _activeGimbal.curYaw : 0
    property string _gimbalRollString:        _activeVehicle && _gimbalRollAvailable ? _gimbalRoll.toFixed(2) : "--"
    property string _gimbalPitchString:       _activeVehicle && _gimbalPitchAvailable ? _gimbalPitch.toFixed(2) : "--"
    property string _gimbalYawString:         _activeVehicle && _gimbalYawAvailable ? _gimbalYaw.toFixed(2) : "--"

    property double _localPitch: 0.0
    property double _localYaw: 0.0
    property int    _gimbalModeStatus: 0

    Rectangle{
        anchors.top: parent.bottom
        anchors.margins: _margins / 2
        anchors.horizontalCenter: parent.horizontalCenter
        width:          gimbalAngleValueRow.width
        height:         gimbalAngleValueRow.height
        color:          "transparent"
        GridLayout{
            id: gimbalAngleValueRow
            rowSpacing: ScreenTools.defaultFontPixelHeight / 5
            columns: 3

            QGCLabel{
                text: " R: " +_gimbalRollString
                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 6
            }
            QGCLabel{
                text: " P: " +_gimbalPitchString
                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 6
            }
            QGCLabel{
                text: " Y: " +_gimbalYawString
                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 6
            }
            QGCLabel{
                text: "data:" + _gimbalAvailable
                Layout.columnSpan: 3
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
            color:      "transparent"
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
                    _localPitch += 2
                    //-- Arbitrary range
                    if(_localPitch < -90.0) _localPitch = -90.0;
                    if(_localPitch >  35.0) _localPitch =  35.0;
                    _activeVehicle.gimbalController.sendGimbalManagerPitchYaw(_localPitch, _localYaw)
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
                    _activeVehicle.gimbalController.sendGimbalManagerPitchYaw(-90, 0)
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
                    _activeVehicle.gimbalController.sendGimbalManagerPitchYaw(_localPitch, _localYaw)
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
                    _activeVehicle.gimbalController.centerGimbal()
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
                    _activeVehicle.gimbalController.sendGimbalManagerPitchYaw(_localPitch, _localYaw)
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
                    _activeVehicle.gimbalController.sendGimbalManagerPitchYaw(_localPitch, _localYaw)
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
                     _activeVehicle.gimbalController.setGimbalRcTargeting()
                }
            }
        }
    }
}
