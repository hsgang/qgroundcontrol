/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FlyView
import QGroundControl.FlightMap
import QGroundControl.Controls

Item {
    id:     root
    clip:   true

    property bool useSmallFont: true

    property double _ar:                QGroundControl.videoManager.gstreamerEnabled
                                            ? QGroundControl.videoManager.videoSize.width / QGroundControl.videoManager.videoSize.height
                                            : QGroundControl.videoManager.aspectRatio
    property bool   _showGrid:          QGroundControl.settingsManager.videoSettings.gridLines.rawValue
    property var    _dynamicCameras:    globals.activeVehicle ? globals.activeVehicle.cameraManager : null
    property bool   _connected:         globals.activeVehicle ? !globals.activeVehicle.communicationLost : false
    property int    _curCameraIndex:    _dynamicCameras ? _dynamicCameras.currentCamera : 0
    property bool   _isCamera:          _dynamicCameras ? _dynamicCameras.cameras.count > 0 : false
    property var    _camera:            _isCamera ? _dynamicCameras.cameras.get(_curCameraIndex) : null
    property bool   _hasZoom:           _camera && _camera.hasZoom
    property int    _fitMode:           QGroundControl.settingsManager.videoSettings.videoFit.rawValue

    property bool   _isMode_FIT_WIDTH:  _fitMode === 0
    property bool   _isMode_FIT_HEIGHT: _fitMode === 1
    property bool   _isMode_FILL:       _fitMode === 2
    property bool   _isMode_NO_CROP:    _fitMode === 3

    function getWidth() {
        return videoBackground.getWidth()
    }
    function getHeight() {
        return videoBackground.getHeight()
    }
    property var    _settingsManager:   QGroundControl.settingsManager
    property var    _videoSettings:     _settingsManager.videoSettings
    property string _videoSource:       _videoSettings.videoSource.rawValue
    // property bool   _isGst:             QGroundControl.videoManager.isGStreamer
    property bool   _isRTSP:            _videoSource === _videoSettings.rtspVideoSource
    property var    _videoManager:              QGroundControl.videoManager
    property bool   _videoAutoStreamConfig:     _videoManager.autoStreamConfigured


    property double _thermalHeightFactor: 0.85 //-- TODO

        // Image {
        //     id:             noVideo
        //     anchors.fill:   parent
        //     source:         "/res/NoVideoBackground.jpg"
        //     fillMode:       Image.PreserveAspectCrop
        //     visible:        !(QGroundControl.videoManager.decoding)

        Rectangle {
            id:             noVideo
            anchors.fill:   parent
            visible:        !(QGroundControl.videoManager.decoding)
            color:          qgcPal.window

            Rectangle {
                anchors.centerIn:   parent
                width:              noVideoColumn.width + ScreenTools.defaultFontPixelHeight
                height:             noVideoColumn.height + ScreenTools.defaultFontPixelHeight / 2
                radius:             ScreenTools.defaultFontPixelHeight / 4
                color:              "transparent"//Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.7)
                //opacity:            0.5

                RowLayout {
                    id: noVideoColumn
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing:   ScreenTools.defaultFontPixelHeight / 2

                    BusyIndicator {
                        id: control
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        Layout.fillWidth: true

                        property real size:ScreenTools.defaultFontPixelHeight * 1.5
                        property real ballSize: ScreenTools.defaultFontPixelHeight / 6

                        contentItem:  Item {
                            implicitWidth:  control.size
                            implicitHeight: control.size

                            Item {
                                id: item
                                x: control.size / 2 - control.size / 2
                                y: control.size / 2 - control.size / 2
                                width: control.size
                                height: control.size
                                //opacity: control.running ? 1 : 0

                                OpacityAnimator on opacity{
                                    duration: 300
                                    from: 0
                                    to: 1
                                }

                                RotationAnimator {
                                    target: item
                                    running: control.visible && control.running
                                    from: 0
                                    to: 360
                                    loops: Animation.Infinite
                                    duration: 2100
                                }

                                Repeater {
                                    id: repeater
                                    model: 7

                                    Rectangle {
                                        x: item.width / 2 - width / 2
                                        y: item.height / 2 - height / 2
                                        implicitWidth: control.ballSize * 2
                                        implicitHeight: control.ballSize * 2
                                        radius: control.ballSize
                                        color: "transparent"
                                        border.color: qgcPal.text
                                        transform: [
                                            Translate {
                                                y: -Math.min(item.width, item.height) * 0.5 + control.ballSize
                                            },
                                            Rotation {
                                                angle: index / repeater.count * 360
                                                origin.x: control.ballSize
                                                origin.y: control.ballSize
                                            }
                                        ]
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        Layout.alignment:   Qt.AlignVCenter | Qt.AlignHCenter
                        Layout.fillWidth:   true
                        spacing:            ScreenTools.defaultFontPixelHeight / 4

                        QGCLabel {
                            id:             noVideoLabel
                            text:           QGroundControl.settingsManager.videoSettings.streamEnabled.rawValue ? qsTr("WAITING FOR VIDEO") : qsTr("VIDEO DISABLED")
                            font.bold:      true
                            color:          qgcPal.text
                            font.pointSize: useSmallFont ? ScreenTools.smallFontPointSize : ScreenTools.largeFontPointSize
                        }

                        QGCLabel {
                            text:           _videoAutoStreamConfig ? qsTr("Auto Configured") : _videoSource
                            font.pointSize: ScreenTools.smallFontPointSize
                        }

                        QGCLabel {
                            text:           _videoSettings.rtspUrl.rawValue
                            visible:        _isRTSP && !_videoAutoStreamConfig
                            font.pointSize: ScreenTools.smallFontPointSize
                        }
                    }
                }
            }
        }

    Rectangle {
        id:             videoBackground
        anchors.fill:   parent
        color:          "black"
        visible:        QGroundControl.videoManager.decoding
        function getWidth() {
            if(_ar != 0.0){
                if(_isMode_FIT_HEIGHT
                        || (_isMode_FILL && (root.width/root.height < _ar))
                        || (_isMode_NO_CROP && (root.width/root.height > _ar))){
                    // This return value has different implications depending on the mode
                    // For FIT_HEIGHT and FILL
                    //    makes so the video width will be larger than (or equal to) the screen width
                    // For NO_CROP Mode
                    //    makes so the video width will be smaller than (or equal to) the screen width
                    return root.height * _ar
                }
            }
            return root.width
        }
        function getHeight() {
            if(_ar != 0.0){
                if(_isMode_FIT_WIDTH
                        || (_isMode_FILL && (root.width/root.height > _ar))
                        || (_isMode_NO_CROP && (root.width/root.height < _ar))){
                    // This return value has different implications depending on the mode
                    // For FIT_WIDTH and FILL
                    //    makes so the video height will be larger than (or equal to) the screen height
                    // For NO_CROP Mode
                    //    makes so the video height will be smaller than (or equal to) the screen height
                    return root.width * (1 / _ar)
                }
            }
            return root.height
        }
        Component {
            id: videoBackgroundComponent
            QGCVideoBackground {
                id:             videoContent
                objectName:     "videoContent"

                Connections {
                    target: QGroundControl.videoManager
                    function onImageFileChanged(filename) {
                        videoContent.grabToImage(function(result) {
                            if (!result.saveToFile(filename)) {
                                console.error('Error capturing video frame');
                            }
                        });
                    }
                }

                Rectangle {
                    color:  Qt.rgba(1,1,1,0.5)
                    height: parent.height
                    width:  1
                    x:      parent.width * 0.33
                    visible: _showGrid && !QGroundControl.videoManager.fullScreen
                }
                Rectangle {
                    color:  Qt.rgba(1,1,1,0.5)
                    height: parent.height
                    width:  1
                    x:      parent.width * 0.66
                    visible: _showGrid && !QGroundControl.videoManager.fullScreen
                }
                Rectangle {
                    color:  Qt.rgba(1,1,1,0.5)
                    width:  parent.width
                    height: 1
                    y:      parent.height * 0.33
                    visible: _showGrid && !QGroundControl.videoManager.fullScreen
                }
                Rectangle {
                    color:  Qt.rgba(1,1,1,0.5)
                    width:  parent.width
                    height: 1
                    y:      parent.height * 0.66
                    visible: _showGrid && !QGroundControl.videoManager.fullScreen
                }
            }
        }
        Loader {
            // GStreamer is causing crashes on Lenovo laptop OpenGL Intel drivers. In order to workaround this
            // we don't load a QGCVideoBackground object when video is disabled. This prevents any video rendering
            // code from running. Hence the Loader to completely remove it.
            height:             parent.getHeight()
            width:              parent.getWidth()
            anchors.centerIn:   parent
            visible:            QGroundControl.videoManager.decoding
            sourceComponent:    videoBackgroundComponent

            property bool videoDisabled: QGroundControl.settingsManager.videoSettings.videoSource.rawValue === QGroundControl.settingsManager.videoSettings.disabledVideoSource
        }

        //-- Thermal Image
        Item {
            id:                 thermalItem
            width:              height * QGroundControl.videoManager.thermalAspectRatio
            height:             _camera ? (_camera.thermalMode === MavlinkCameraControl.THERMAL_FULL ? parent.height : (_camera.thermalMode === MavlinkCameraControl.THERMAL_PIP ? ScreenTools.defaultFontPixelHeight * 12 : parent.height * _thermalHeightFactor)) : 0
            anchors.centerIn:   parent
            visible:            QGroundControl.videoManager.hasThermal && _camera.thermalMode !== MavlinkCameraControl.THERMAL_OFF
            function pipOrNot() {
                if(_camera) {
                    if(_camera.thermalMode === MavlinkCameraControl.THERMAL_PIP) {
                        anchors.centerIn    = undefined
                        anchors.top         = parent.top
                        anchors.topMargin   = mainWindow.header.height + (ScreenTools.defaultFontPixelHeight * 0.5)
                        anchors.left        = parent.left
                        anchors.leftMargin  = ScreenTools.defaultFontPixelWidth * 12
                    } else {
                        anchors.top         = undefined
                        anchors.topMargin   = undefined
                        anchors.left        = undefined
                        anchors.leftMargin  = undefined
                        anchors.centerIn    = parent
                    }
                }
            }
            Connections {
                target:                 _camera
                function onThermalModeChanged() { thermalItem.pipOrNot() }
            }
            onVisibleChanged: {
                thermalItem.pipOrNot()
            }
            QGCVideoBackground {
                id:             thermalVideo
                objectName:     "thermalVideo"
                anchors.fill:   parent
                opacity:        _camera ? (_camera.thermalMode === MavlinkCameraControl.THERMAL_BLEND ? _camera.thermalOpacity / 100 : 1.0) : 0
            }
        }
        //-- Zoom
        PinchArea {
            id:             pinchZoom
            enabled:        _hasZoom
            anchors.fill:   parent
            onPinchStarted: pinchZoom.zoom = 0
            onPinchUpdated: {
                if(_hasZoom) {
                    var z = 0
                    if(pinch.scale < 1) {
                        z = Math.round(pinch.scale * -10)
                    } else {
                        z = Math.round(pinch.scale)
                    }
                    if(pinchZoom.zoom != z) {
                        _camera.stepZoom(z)
                    }
                }
            }
            property int zoom: 0
        }
    }
}
