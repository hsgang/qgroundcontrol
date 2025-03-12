

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
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.Vehicle
import QGroundControl.Controllers

import SiYi.Object
import "qrc:/qml/QGroundControl/Controls"
import "qrc:/qml/QGroundControl/FlightDisplay"

Rectangle {
    id: root
    clip: true
    anchors.fill: parent
    color: "#00000000"
    visible: true //!_mainWindowIsMap && camera.isConnected && QGroundControl.settingsManager.flyViewSettings.showSiyiCameraControl.rawValue

    property var siyi: SiYi
    property SiYiCamera camera: siyi.camera
    property SiYiTransmitter transmitter: siyi.transmitter
    property bool isRecording: camera.isRecording
    property int minDelta: 5
    property bool hasBeenMoved: false

    //property real videoW: using1080p ? 1920 : 1280 //camera.resolutionW //1280
    //property real videoH: using1080p ? 1080 : 720 //camera.resolutionH //720
    property real videoW: 1280
    property real videoH: 720
    property bool expended: true
    property bool using1080p: false //camera.using1080p
    property real iconScale: SiYi.isAndroid ? 0.7 : 1.5
    //property int  iconLeftMargin: 150
    property bool laserIconShow: false
    property bool showLaserOnLeft: camera.mainStreamSplitMode === 3
                                   || camera.mainStreamSplitMode === 5
    property bool doNotShowLaserIcon: camera.mainStreamSplitMode === 1
                                      || camera.mainStreamSplitMode === 2
                                      || camera.mainStreamSplitMode === 4

    property int currentImageMode : 0
    property int currentThermalPalette : 0

    property real _margins : ScreenTools.defaultFontPixelHeight / 2

    MouseArea {
        id: controlMouseArea
        anchors.fill: parent
        hoverEnabled: false
        visible: camera.isConnected
        onPressed: function(event) {
            if (camera.isTracking) {
                return
            }

            enableControl = true
            controlMouseArea.originX = event.x
            controlMouseArea.originY = event.y
            controlMouseArea.currentX = event.x
            controlMouseArea.currentY = event.y
            controlMouseArea.pitch = 0
            controlMouseArea.yaw = 0
            contrlTimer.start()
        }
        onReleased: {
            if (camera.isTracking) {
                return
            }

            camera.turn(0, 0)
            console.info("camera.turn(0, 0)")
            enableControl = false
            contrlTimer.stop()
        }
        onPositionChanged: function(event) {
            if (camera.isTracking) {
                return
            }

            hasBeenMoved = true
            controlMouseArea.currentX = event.x
            controlMouseArea.currentY = event.y

            controlMouseArea.yaw = controlMouseArea.currentX - controlMouseArea.originX
            controlMouseArea.pitch = controlMouseArea.currentY - controlMouseArea.originY
            //controlMouseArea.yaw = controlMouseArea.yaw / 5
            //controlMouseArea.pitch = controlMouseArea.pitch / 5
            if (Math.abs(controlMouseArea.yaw) > Math.abs(
                        controlMouseArea.pitch)) {
                if (Math.abs(controlMouseArea.yaw) > minDelta) {
                    controlMouseArea.pitch = 0
                    controlMouseArea.isYDirection = false

                    if (contrlTimer.sendEnable) {
                        contrlTimer.sendEnable = false
                        var cookedX = controlMouseArea.yaw * 100 / root.width
                        camera.turn(cookedX, 0)
                    }
                }
            } else {
                if (Math.abs(controlMouseArea.pitch) > minDelta) {
                    controlMouseArea.yaw = 0
                    controlMouseArea.isYDirection = true

                    if (contrlTimer.sendEnable) {
                        contrlTimer.sendEnable = false
                        var cookedY = controlMouseArea.pitch * 100 / root.height
                        camera.turn(0, -cookedY)
                    }
                }
            }
        }
        onDoubleClicked: {
            if (camera.isTracking) {
                return
            }

            console.info("camera.resetPostion()")
            camera.resetPostion()
        }
        onClicked: function (mouse) {
            if (hasBeenMoved) {
                hasBeenMoved = false
                return
            }

            if (camera.aiModeOn) {
                var w = root.width
                var h = root.height
                var x = mouse.x
                var y = mouse.y
                var cookedX = (x * videoW) / root.width
                var cookedY = (y * videoH) / root.height
                console.info("camera.setTrackingTarget()", cookedX, cookedY,
                             root.width, root.height)
                camera.setTrackingTarget(true, cookedX, cookedY)
            } else {

                // 中间区域10%才生效


                /*if (mouse.x < root.width / 2 - root.width * 0.05) {
                    return
                }
                if (mouse.x > root.width / 2 + root.width * 0.05) {
                    return
                }
                if (mouse.y < root.height / 2 - root.height * 0.05) {
                    return
                }
                if (mouse.y > root.height / 2 + root.height * 0.05) {
                    return
                }*/
                console.info("camera.autoFocus()")
                camera.autoFocus(mouse.x, mouse.y, root.width, root.height)
            }
        }

        Timer {
            id: contrlTimer
            running: false
            interval: 100
            repeat: true
            onTriggered: {
                contrlTimer.sendEnable = true

                /*if (controlMouseArea.enableControl) {
                    if (controlMouseArea.yaw < -100) {
                        controlMouseArea.yaw = -100
                    }

                    if (controlMouseArea.yaw > 100) {
                        controlMouseArea.yaw = 100
                    }

                    if (controlMouseArea.pitch < -100) {
                        controlMouseArea.pitch = -100
                    }

                    if (controlMouseArea.pitch > 100) {
                        controlMouseArea.pitch = 100
                    }

                    if (Math.abs(controlMouseArea.pitch) > minDelta) {
                        controlMouseArea.prePitch = controlMouseArea.pitch
                    }

                    if (Math.abs(controlMouseArea.yaw) > minDelta) {
                        controlMouseArea.preYaw = controlMouseArea.yaw
                    }

                    if (Math.abs(controlMouseArea.pitch) < minDelta && Math.abs(
                                controlMouseArea.yaw) < minDelta) {
                        return
                    }

                    hasBeenMoved = true
                    camera.turn(controlMouseArea.isYDirection ? 0 : Math.abs(
                                                                    controlMouseArea.yaw) < minDelta ? controlMouseArea.preYaw : controlMouseArea.yaw,
                                controlMouseArea.isYDirection ? Math.abs(
                                                                    controlMouseArea.pitch) < minDelta ? -controlMouseArea.prePitch : -controlMouseArea.pitch : 0)
                }*/
            }
            onRunningChanged: {
                if (!running) {
                    controlMouseArea.originX = 0
                    controlMouseArea.originY = 0
                    controlMouseArea.currentX = 0
                    controlMouseArea.currentY = 0
                    camera.turn(0, 0)
                }
            }
            property bool sendEnable: false
        }

        property bool enableControl: false
        property int pitch: 0
        property int yaw: 0
        property int prePitch: 0
        property int preYaw: 0
        property int originX: 0
        property int originY: 0
        property int currentX: 0
        property int currentY: 0
        property bool isYDirection: false
    }

    // Item {
    //     id: controlRectangle
    //     anchors.right: parent.right
    //     anchors.rightMargin: _margins * 3
    //     anchors.top:    parent.top
    //     anchors.topMargin: _margins * 3
    //     width: controlColumn.width
    //     height: controlColumn.height

    //     Text {
    //         id: btText
    //         text: "1234"
    //         anchors.verticalCenter: parent.verticalCenter
    //         visible: false
    //     }

    //     Rectangle {
    //         width:  controlRectangle.width + _margins
    //         height: controlRectangle.height + _margins
    //         color:  Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5)
    //         radius: _margins

    //         Column {
    //             anchors.right: controlColumn.left
    //             anchors.rightMargin: _margins * 2
    //             anchors.top: controlColumn.top
    //             spacing: _margins

    //             FakeToolStripHoverButton {
    //                 width:  _margins * 6
    //                 iconSource: SiYi.hideWidgets ? using1080p ? "/SiYi/NavGreen.svg" : "/SiYi/NavRed.svg" : "/SiYi/nav.svg"
    //                 fullColorIcon: true
    //                 text:       "Nav"
    //                 visible: expended

    //                 onClicked: SiYi.hideWidgets = !SiYi.hideWidgets
    //                 onPressAndHold: {
    //                     camera.using1080p = !camera.using1080p
    //                     console.info("using1080p", using1080p)
    //                 }
    //             }

    //             FakeToolStripHoverButton {
    //                 width:  _margins * 6
    //                 iconSource: camera.aiModeOn ? (camera.isTracking ? "/SiYi/AiRed.svg" : "/SiYi/AiGreen.svg") : (pressed ? "/SiYi/AiGreen.svg" : "/SiYi/Ai.svg")
    //                 fullColorIcon: true
    //                 text:       "AI"
    //                 visible: expended ? camera.enableAi : false

    //                 onClicked: {
    //                     if (camera.aiModeOn) {
    //                         if (camera.isTracking) {
    //                             camera.setTrackingTarget(false, 0, 0)
    //                         } else {
    //                             camera.setAiModel(SiYiCamera.AiModeOff)
    //                         }
    //                     } else {
    //                         camera.setAiModel(SiYiCamera.AiModeOn)
    //                     }
    //                 }
    //             }

    //             FakeToolStripHoverButton {
    //                 width:  _margins * 6
    //                 iconSource: {
    //                     if (pressed) {
    //                         return "/SiYi/LaserDistanceGreen.svg"
    //                     }

    //                     if (camera.laserStateHasResponse) {
    //                         if (camera.laserStateOn) {
    //                             return "/SiYi/LaserDistanceGreen.svg"
    //                         } else {
    //                             return "/SiYi/LaserDistance.svg"
    //                         }
    //                     } else {
    //                         if (root.laserIconShow) {
    //                             return "/SiYi/LaserDistanceGreen.svg"
    //                         } else {
    //                             return "/SiYi/LaserDistance.svg"
    //                         }
    //                     }
    //                 }
    //                 fullColorIcon: true
    //                 text:       "Laser"
    //                 visible: expended ? camera.enableLaser : false

    //                 onClicked: {
    //                     if (camera.laserStateHasResponse) {
    //                         console.info("Set laser state: ",
    //                                      camera.laserStateOn ? "OFF" : "ON")
    //                         var onState = camera.laserStateOn ? SiYiCamera.LaserStateOff : SiYiCamera.LaserStateOn
    //                         camera.setLaserState(onState)
    //                     } else {
    //                         root.laserIconShow = !root.laserIconShow
    //                     }
    //                 }
    //             }

    //             FakeToolStripHoverButton {
    //                 width:  _margins * 6
    //                 iconSource: "/InstrumentValueIcons/view-tile.svg"
    //                 text:       "Screen"
    //                 visible: expended ? camera.enableThermal : false

    //                 onClicked: {
    //                     imageModePopupDialog.open()
    //                 }
    //             }

    //             FakeToolStripHoverButton {
    //                 width:  _margins * 6
    //                 iconSource: "/InstrumentValueIcons/border-all.svg"
    //                 text:       "Palette"
    //                 visible: expended ? camera.enableThermal : false

    //                 onClicked: {
    //                     thermalPalettePopupDialog.open()
    //                 }
    //             }
    //         }

    //         Column {
    //             id: controlColumn
    //             spacing: _margins
    //             anchors.horizontalCenter: parent.horizontalCenter
    //             anchors.verticalCenter: parent.verticalCenter

    //             Image {
    //                 anchors.horizontalCenter: parent.horizontalCenter
    //                 source: "/SiYi/buttonRight.svg"
    //                 fillMode: Image.PreserveAspectFit
    //                 sourceSize.width: btText.width * iconScale
    //                 sourceSize.height: btText.width * iconScale
    //                 rotation: expended ? 0 : 180
    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: root.expended = !root.expended
    //                 }
    //             }

    //             FakeToolStripHoverButton {
    //                 width:  _margins * 6
    //                 iconSource: pressed ? "/SiYi/ZoomInGreen.svg" : "/SiYi/ZoomIn.svg"
    //                 fullColorIcon: true
    //                 text:       "ZoomIn"

    //                 onPressed: {
    //                     if (camera.is4k) {
    //                         camera.emitOperationResultChanged(-1)
    //                     } else {
    //                         camera.zoom(1)
    //                         zoomInTimer.start()
    //                     }
    //                 }
    //                 onReleased: {
    //                     zoomInTimer.stop()
    //                     camera.zoom(0)
    //                 }

    //                 Timer {
    //                     id: zoomInTimer
    //                     interval: 100
    //                     repeat: false
    //                     running: false
    //                     onTriggered: {
    //                         camera.zoom(1)
    //                         zoomInTimer.start()
    //                     }
    //                 }
    //             }

    //             // Image {
    //             //     // 放大
    //             //     id: zoomInImage
    //             //     sourceSize.width: btText.width * iconScale
    //             //     sourceSize.height: btText.width * iconScale
    //             //     source: zoomInMA.pressed ? "/SiYi/ZoomInGreen.svg" : "/SiYi/ZoomIn.svg"
    //             //     //anchors.verticalCenter: parent.verticalCenter
    //             //     anchors.horizontalCenter: parent.horizontalCenter
    //             //     fillMode: Image.PreserveAspectFit
    //             //     cache: false
    //             //     visible: expended ? camera.enableZoom : false
    //             //     MouseArea {
    //             //         id: zoomInMA
    //             //         anchors.fill: parent
    //             //         onPressed: {
    //             //             if (camera.is4k) {
    //             //                 camera.emitOperationResultChanged(-1)
    //             //             } else {
    //             //                 camera.zoom(1)
    //             //                 zoomInTimer.start()
    //             //             }
    //             //         }
    //             //         onReleased: {
    //             //             zoomInTimer.stop()
    //             //             camera.zoom(0)
    //             //         }
    //             //     }
    //             //     Timer {
    //             //         id: zoomInTimer
    //             //         interval: 100
    //             //         repeat: false
    //             //         running: false
    //             //         onTriggered: {
    //             //             camera.zoom(1)
    //             //             zoomInTimer.start()
    //             //         }
    //             //     }
    //             // }

    //             FakeToolStripHoverButton {
    //                 width:  _margins * 6
    //                 iconSource: pressed ? "/SiYi/ZoomOutGreen.svg" : "/SiYi/ZoomOut.svg"
    //                 fullColorIcon: true
    //                 text:       "ZoomOut"

    //                 onPressed: {
    //                     if (camera.is4k) {
    //                         camera.emitOperationResultChanged(-1)
    //                     } else {
    //                         camera.zoom(-1)
    //                         zoomOutTimer.start()
    //                     }
    //                 }
    //                 onReleased: {
    //                     zoomOutTimer.stop()
    //                     camera.zoom(0)
    //                 }

    //                 Timer {
    //                     id: zoomOutTimer
    //                     interval: 100
    //                     repeat: false
    //                     running: false
    //                     onTriggered: {
    //                         camera.zoom(-1)
    //                         zoomOutTimer.start()
    //                     }
    //                 }
    //             }
    //             // Image {
    //             //     // 缩小
    //             //     id: zoomOut
    //             //     sourceSize.width: btText.width * iconScale
    //             //     sourceSize.height: btText.width * iconScale
    //             //     source: zoomOutMA.pressed ? "/SiYi/ZoomOutGreen.svg" : "/SiYi/ZoomOut.svg"
    //             //     //anchors.verticalCenter: parent.verticalCenter
    //             //     anchors.horizontalCenter: parent.horizontalCenter
    //             //     fillMode: Image.PreserveAspectFit
    //             //     cache: false
    //             //     visible: expended ? camera.enableZoom : false
    //             //     MouseArea {
    //             //         id: zoomOutMA
    //             //         anchors.fill: parent
    //             //         onPressed: {
    //             //             if (camera.is4k) {
    //             //                 camera.emitOperationResultChanged(-1)
    //             //             } else {
    //             //                 camera.zoom(-1)
    //             //                 zoomOutTimer.start()
    //             //             }
    //             //         }
    //             //         onReleased: {
    //             //             zoomOutTimer.stop()
    //             //             camera.zoom(0)
    //             //         }
    //             //     }
    //             //     Timer {
    //             //         id: zoomOutTimer
    //             //         interval: 100
    //             //         repeat: false
    //             //         running: false
    //             //         onTriggered: {
    //             //             camera.zoom(-1)
    //             //             zoomOutTimer.start()
    //             //         }
    //             //     }
    //             // }

    //             FakeToolStripHoverButton {
    //                 width:  _margins * 6
    //                 iconSource: pressed ? "/SiYi/ResetGreen.svg" : "/SiYi/Reset.svg"
    //                 fullColorIcon: true
    //                 text:       "Reset"

    //                 onPressed: camera.resetPostion()
    //             }

    //             // Image {
    //             //     // 回中
    //             //     id: reset
    //             //     sourceSize.width: btText.width * iconScale
    //             //     sourceSize.height: btText.width * iconScale
    //             //     source: resetMA.pressed ? "/SiYi/ResetGreen.svg" : "/SiYi/Reset.svg"
    //             //     //anchors.verticalCenter: parent.verticalCenter
    //             //     anchors.horizontalCenter: parent.horizontalCenter
    //             //     fillMode: Image.PreserveAspectFit
    //             //     cache: false
    //             //     visible: expended ? camera.enableControl : false
    //             //     MouseArea {
    //             //         id: resetMA
    //             //         anchors.fill: parent
    //             //         onPressed: camera.resetPostion()
    //             //     }
    //             // }

    //             FakeToolStripHoverButton {
    //                 width:  _margins * 6
    //                 iconSource: pressed ? "/SiYi/PhotoGreen.svg" : "/SiYi/Photo.svg"
    //                 fullColorIcon: true
    //                 text:       "Photo"

    //                 onPressed: camera.sendCommand(SiYiCamera.CameraCommandTakePhoto)
    //             }

    //             // Image {
    //             //     // 拍照
    //             //     id: photo
    //             //     sourceSize.width: btText.width * iconScale
    //             //     sourceSize.height: btText.width * iconScale
    //             //     source: photoMA.pressed ? "/SiYi/PhotoGreen.svg" : "/SiYi/Photo.svg"
    //             //     //anchors.verticalCenter: parent.verticalCenter
    //             //     anchors.horizontalCenter: parent.horizontalCenter
    //             //     fillMode: Image.PreserveAspectFit
    //             //     cache: false
    //             //     visible: expended ? camera.enablePhoto : false
    //             //     MouseArea {
    //             //         id: photoMA
    //             //         anchors.fill: parent
    //             //         onPressed: {
    //             //             // console.info("camera.sendCommand(SiYiCamera.CameraCommandTakePhoto)")
    //             //             camera.sendCommand(SiYiCamera.CameraCommandTakePhoto)
    //             //         }
    //             //     }
    //             // }

    //             FakeToolStripHoverButton {
    //                 id: video
    //                 width:  _margins * 6
    //                 //iconSource: pressed ? "/SiYi/PhotoGreen.svg" : "/SiYi/Photo.svg"
    //                 fullColorIcon: true
    //                 text:       "Record"

    //                 onPressed: {
    //                     if (camera.isRecording) {
    //                         camera.sendRecodingCommand(
    //                                     SiYiCamera.CloseRecording)
    //                     } else {
    //                         camera.sendRecodingCommand(SiYiCamera.OpenRecording)
    //                     }
    //                 }

    //                 Connections {
    //                     target: camera
    //                     function onEnableVideoChanged() {
    //                         video.iconSource = "/SiYi/empty.png"
    //                         if (camera.enableVideo) {
    //                             if (camera.isRecording) {
    //                                 video.iconSource = "/SiYi/Stop.svg"
    //                                 video.text = "Recording"
    //                             } else {
    //                                 video.iconSource = "/SiYi/Video.png"
    //                                 video.text = "Record"
    //                             }
    //                         }
    //                     }

    //                     function onIsRecordingChanged() {
    //                         video.iconSource = "/SiYi/empty.png"
    //                         if (camera.isRecording) {
    //                             video.iconSource = "/SiYi/Stop.svg"
    //                             video.text = "Recording"
    //                         } else {
    //                             video.iconSource = "/SiYi/Video.png"
    //                             video.text = "Record"
    //                         }
    //                     }
    //                 }
    //             }

    //             // Image {
    //             //     // 录像
    //             //     id: video
    //             //     //sourceSize.width: (btText.width - 8) * iconScale
    //             //     //sourceSize.height: (btText.width + 8) * iconScale
    //             //     width: (btText.width) * iconScale
    //             //     height: (btText.width + 4) * iconScale
    //             //     cache: false
    //             //     //anchors.verticalCenter: parent.verticalCenter
    //             //     anchors.horizontalCenter: parent.horizontalCenter
    //             //     //fillMode: Image.PreserveAspectFit
    //             //     visible: expended ? camera.enableVideo : false
    //             //     MouseArea {
    //             //         id: videoMA
    //             //         anchors.fill: parent
    //             //         onPressed: {
    //             //             if (camera.isRecording) {
    //             //                 camera.sendRecodingCommand(
    //             //                             SiYiCamera.CloseRecording)
    //             //             } else {
    //             //                 camera.sendRecodingCommand(SiYiCamera.OpenRecording)
    //             //             }
    //             //         }
    //             //     }
    //             //     Connections {
    //             //         target: camera
    //             //         function onEnableVideoChanged() {
    //             //             video.source = "/SiYi/empty.png"
    //             //             if (camera.enableVideo) {
    //             //                 if (camera.isRecording) {
    //             //                     video.source = "/SiYi/Stop.svg"
    //             //                 } else {
    //             //                     video.source = "/SiYi/Video.png"
    //             //                 }
    //             //             }
    //             //         }

    //             //         function onIsRecordingChanged() {
    //             //             video.source = "/SiYi/empty.png"
    //             //             if (camera.isRecording) {
    //             //                 video.source = "/SiYi/Stop.svg"
    //             //             } else {
    //             //                 video.source = "/SiYi/Video.png"
    //             //             }
    //             //         }
    //             //     }
    //             // }

    //             // Image {
    //             //     // 远景
    //             //     id: far
    //             //     sourceSize.width: btText.width * iconScale
    //             //     sourceSize.height: btText.width * iconScale
    //             //     source: farMA.pressed ? "/SiYi/farGreen.svg" : "/SiYi/far.svg"
    //             //     //anchors.verticalCenter: parent.verticalCenter
    //             //     anchors.horizontalCenter: parent.horizontalCenter
    //             //     fillMode: Image.PreserveAspectFit
    //             //     cache: false
    //             //     visible: expended ? camera.enableFocus : false
    //             //     MouseArea {
    //             //         id: farMA
    //             //         anchors.fill: parent
    //             //         onPressed: {
    //             //             camera.focus(1)
    //             //             farTimer.start()
    //             //         }
    //             //         onReleased: {
    //             //             farTimer.stop()
    //             //             camera.focus(0)
    //             //         }
    //             //     }
    //             //     Timer {
    //             //         id: farTimer
    //             //         interval: 100
    //             //         repeat: false
    //             //         running: false
    //             //         onTriggered: {
    //             //             camera.focus(1)
    //             //             farTimer.start()
    //             //         }
    //             //     }
    //             // }

    //             // Image {
    //             //     // 近景
    //             //     id: neer
    //             //     sourceSize.width: btText.width * iconScale
    //             //     sourceSize.height: btText.width * iconScale
    //             //     source: neerMA.pressed ? "/SiYi/neerGreen.svg" : "/SiYi/neer.svg"
    //             //     //anchors.verticalCenter: parent.verticalCenter
    //             //     anchors.horizontalCenter: parent.horizontalCenter
    //             //     fillMode: Image.PreserveAspectFit
    //             //     cache: false
    //             //     visible: expended ? camera.enableFocus : false
    //             //     MouseArea {
    //             //         id: neerMA
    //             //         anchors.fill: parent
    //             //         onPressed: {
    //             //             camera.focus(-1)
    //             //             neerTimer.start()
    //             //         }
    //             //         onReleased: {
    //             //             neerTimer.stop()
    //             //             camera.focus(0)
    //             //         }
    //             //     }
    //             //     Timer {
    //             //         id: neerTimer
    //             //         interval: 100
    //             //         repeat: false
    //             //         running: false
    //             //         onTriggered: {
    //             //             camera.focus(-1)
    //             //             neerTimer.start()
    //             //         }
    //             //     }
    //             // }
    //         }
    //     }
    // }
    // Item {
    //     height: parent.height
    //     width: showLaserOnLeft ? root.width / 2 : root.width
    //     Image {
    //         id: laserImage
    //         source: "/SiYi/+.svg"
    //         visible: {
    //             if (root.doNotShowLaserIcon) {
    //                 return false
    //             }
    //             if (camera.laserStateHasResponse) {
    //                 return camera.laserStateOn
    //             } else {
    //                 return root.laserIconShow
    //             }
    //         }
    //         anchors.centerIn: parent
    //         sourceSize.width: btText.width * (SiYi.isAndroid ? iconScale : 2)
    //         sourceSize.height: btText.width * (SiYi.isAndroid ? iconScale : 2)
    //     }

    //     Rectangle {
    //         id: laserInfo
    //         anchors.top: laserImage.bottom
    //         anchors.left: laserImage.right
    //         width: infoGridLayout.width + _margins
    //         height: infoGridLayout.height + _margins / 2
    //         radius: _margins / 2
    //         color:  Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5)
    //         visible: {
    //             if (camera.laserStateHasResponse) {
    //                 return camera.laserStateOn
    //             } else {
    //                 return root.laserIconShow
    //             }
    //         }
    //         //anchors.left: parent.right
    //         //anchors.leftMargin: controlColumn.spacing
    //         // QGCLabel {
    //         //     id: laserLabel
    //         //     padding: 0
    //         //     text: camera.cookedLaserDistance + "m" + "\n" + camera.cookedLongitude
    //         //           + "°" + "\n" + camera.cookedLatitude + "°"
    //         //     color: qgcPal.text
    //         //     font.pointSize: ScreenTools.
    //         // }
    //         ColumnLayout {
    //             id: infoGridLayout
    //             anchors.centerIn: parent
    //             spacing: 0
    //             QGCLabel {
    //                 padding: 0
    //                 text: camera.cookedLaserDistance + "m"
    //                 color: qgcPal.text
    //             }
    //             QGCLabel {
    //                 color: qgcPal.text
    //                 text: camera.cookedLongitude + "°"
    //                 font.pointSize: ScreenTools.smallFontPointSize
    //             }
    //             QGCLabel {
    //                 color: qgcPal.text
    //                 text: camera.cookedLatitude + "°"
    //                 font.pointSize: ScreenTools.smallFontPointSize
    //             }
    //         }
    //     }
    // }

    // QGCPopupDialog {
    //     id: imageModePopupDialog
    //     title: qsTr("Select image mode")
    //     buttons: Dialog.Cancel
    //     destroyOnClose: false

    //     GridLayout {
    //         //Layout.fillWidth: true
    //         rows: 2
    //         rowSpacing: _toolsMargin * 2
    //         columns: 3
    //         columnSpacing: _toolsMargin * 2

    //         Column {
    //             QGCColoredImage {
    //                 width: ScreenTools.defaultFontPixelHeight * 3
    //                 height: width
    //                 sourceSize.width: btText.width * iconScale
    //                 sourceSize.height: btText.width * iconScale
    //                 source: "/InstrumentValueIcons/view-tile.svg"
    //                 fillMode: Image.PreserveAspectFit
    //                 anchors.horizontalCenter:   parent.horizontalCenter

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: {
    //                         if(currentImageMode < 9){
    //                             camera.imageMode(0,1)
    //                         }
    //                         imageModePopupDialog.close()
    //                         //imageModeControl.visible = false
    //                     }
    //                 }
    //             }
    //             QGCLabel {
    //                 text: "Zoom"
    //                 anchors.horizontalCenter:   parent.horizontalCenter
    //             }
    //         }
    //         Column {
    //             QGCColoredImage {
    //                 width: ScreenTools.defaultFontPixelHeight * 3
    //                 height: width
    //                 sourceSize.width: btText.width * iconScale
    //                 sourceSize.height: btText.width * iconScale
    //                 source: "/InstrumentValueIcons/view-tile.svg"
    //                 fillMode: Image.PreserveAspectFit
    //                 anchors.horizontalCenter:   parent.horizontalCenter

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: {
    //                         if(currentImageMode < 9){
    //                             camera.imageMode(1,0)
    //                         }
    //                         imageModePopupDialog.close()
    //                         //imageModeControl.visible = false
    //                     }
    //                 }
    //             }
    //             QGCLabel {
    //                 text: "Wide"
    //                 anchors.horizontalCenter:   parent.horizontalCenter
    //             }
    //         }
    //         Column {
    //             QGCColoredImage {
    //                 width: ScreenTools.defaultFontPixelHeight * 3
    //                 height: width
    //                 sourceSize.width: btText.width * iconScale
    //                 sourceSize.height: btText.width * iconScale
    //                 source: "/InstrumentValueIcons/view-tile.svg"
    //                 fillMode: Image.PreserveAspectFit
    //                 anchors.horizontalCenter:   parent.horizontalCenter

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: {
    //                         if(currentImageMode < 9){
    //                             camera.imageMode(2,0)
    //                         }
    //                         imageModePopupDialog.close()
    //                         //imageModeControl.visible = false
    //                     }
    //                 }
    //             }
    //             QGCLabel {
    //                 text: "Thermal"
    //                 anchors.horizontalCenter:   parent.horizontalCenter
    //             }
    //         }
    //         Column {
    //             QGCColoredImage {
    //                 width: ScreenTools.defaultFontPixelHeight * 3
    //                 height: width
    //                 sourceSize.width: btText.width * iconScale
    //                 sourceSize.height: btText.width * iconScale
    //                 source: "/InstrumentValueIcons/view-tile.svg"
    //                 fillMode: Image.PreserveAspectFit
    //                 anchors.horizontalCenter:   parent.horizontalCenter

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: {
    //                         if(currentImageMode < 9){
    //                             camera.imageMode(3,1)
    //                         }
    //                         imageModePopupDialog.close()
    //                         //imageModeControl.visible = false
    //                     }
    //                 }
    //             }
    //             QGCLabel {
    //                 text: "Zoom\n/Thermal"
    //                 anchors.horizontalCenter:   parent.horizontalCenter
    //             }
    //         }
    //         Column {
    //             QGCColoredImage {
    //                 width: ScreenTools.defaultFontPixelHeight * 3
    //                 height: width
    //                 sourceSize.width: btText.width * iconScale
    //                 sourceSize.height: btText.width * iconScale
    //                 source: "/InstrumentValueIcons/view-tile.svg"
    //                 fillMode: Image.PreserveAspectFit
    //                 anchors.horizontalCenter:   parent.horizontalCenter

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: {
    //                         if(currentImageMode < 9){
    //                             camera.imageMode(4,0)
    //                         }
    //                         imageModePopupDialog.close()
    //                         //imageModeControl.visible = false
    //                     }
    //                 }
    //             }
    //             QGCLabel {
    //                 text: "Wide\n/Thermal"
    //                 anchors.horizontalCenter:   parent.horizontalCenter
    //             }
    //         }
    //         Column {
    //             QGCColoredImage {
    //                 width: ScreenTools.defaultFontPixelHeight * 3
    //                 height: width
    //                 sourceSize.width: btText.width * iconScale
    //                 sourceSize.height: btText.width * iconScale
    //                 source: "/InstrumentValueIcons/view-tile.svg"
    //                 fillMode: Image.PreserveAspectFit
    //                 anchors.horizontalCenter:   parent.horizontalCenter

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: {
    //                         if(currentImageMode < 9){
    //                             camera.imageMode(5,0)
    //                         }
    //                         imageModePopupDialog.close()
    //                         //imageModeControl.visible = false
    //                     }
    //                 }
    //             }
    //             QGCLabel {
    //                 text: "Zoom\n/Wide"
    //                 anchors.horizontalCenter:   parent.horizontalCenter
    //             }
    //         }
    //     }
    // }

    // QGCPopupDialog {
    //     id: thermalPalettePopupDialog
    //     title: qsTr("Select image mode")
    //     buttons: Dialog.Cancel
    //     destroyOnClose: false

    //     GridLayout {
    //         rows: 2
    //         rowSpacing: _toolsMargin * 2
    //         columns: 6
    //         columnSpacing: _toolsMargin * 2

    //         Column {
    //             QGCColoredImage {
    //                 width: ScreenTools.defaultFontPixelHeight * 3
    //                 height: width
    //                 sourceSize.width: btText.width * iconScale
    //                 sourceSize.height: btText.width * iconScale
    //                 source: "/InstrumentValueIcons/border-all.svg"
    //                 fillMode: Image.PreserveAspectFit
    //                 anchors.horizontalCenter:   parent.horizontalCenter

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: {
    //                         camera.thermalPalette(0)
    //                         //thermalPalettePopupDialog.close()
    //                     }
    //                 }
    //             }
    //             QGCLabel {
    //                 text: "White Hot"
    //                 anchors.horizontalCenter:   parent.horizontalCenter
    //             }
    //         }
    //         Column {
    //             QGCColoredImage {
    //                 width: ScreenTools.defaultFontPixelHeight * 3
    //                 height: width
    //                 sourceSize.width: btText.width * iconScale
    //                 sourceSize.height: btText.width * iconScale
    //                 source: "/InstrumentValueIcons/border-all.svg"
    //                 fillMode: Image.PreserveAspectFit
    //                 anchors.horizontalCenter:   parent.horizontalCenter

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: {
    //                         camera.thermalPalette(2)
    //                         //thermalPalettePopupDialog.close()
    //                     }
    //                 }
    //             }
    //             QGCLabel {
    //                 text: "Sepia"
    //                 anchors.horizontalCenter:   parent.horizontalCenter
    //             }
    //         }
    //         Column {
    //             QGCColoredImage {
    //                 width: ScreenTools.defaultFontPixelHeight * 3
    //                 height: width
    //                 sourceSize.width: btText.width * iconScale
    //                 sourceSize.height: btText.width * iconScale
    //                 source: "/InstrumentValueIcons/border-all.svg"
    //                 fillMode: Image.PreserveAspectFit
    //                 anchors.horizontalCenter:   parent.horizontalCenter

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: {
    //                         camera.thermalPalette(3)
    //                         thermalPalettePopupDialog.close()
    //                     }
    //                 }
    //             }
    //             QGCLabel {
    //                 text: "Ironbow"
    //                 anchors.horizontalCenter:   parent.horizontalCenter
    //             }
    //         }
    //         Column {
    //             QGCColoredImage {
    //                 width: ScreenTools.defaultFontPixelHeight * 3
    //                 height: width
    //                 sourceSize.width: btText.width * iconScale
    //                 sourceSize.height: btText.width * iconScale
    //                 source: "/InstrumentValueIcons/border-all.svg"
    //                 fillMode: Image.PreserveAspectFit
    //                 anchors.horizontalCenter:   parent.horizontalCenter

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: {
    //                         camera.thermalPalette(4)
    //                         thermalPalettePopupDialog.close()
    //                     }
    //                 }
    //             }
    //             QGCLabel {
    //                 text: "Rainbow"
    //                 anchors.horizontalCenter:   parent.horizontalCenter
    //             }
    //         }
    //         Column {
    //             QGCColoredImage {
    //                 width: ScreenTools.defaultFontPixelHeight * 3
    //                 height: width
    //                 sourceSize.width: btText.width * iconScale
    //                 sourceSize.height: btText.width * iconScale
    //                 source: "/InstrumentValueIcons/border-all.svg"
    //                 fillMode: Image.PreserveAspectFit
    //                 anchors.horizontalCenter:   parent.horizontalCenter

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: {
    //                         camera.thermalPalette(5)
    //                         thermalPalettePopupDialog.close()
    //                     }
    //                 }
    //             }
    //             QGCLabel {
    //                 text: "Night"
    //                 anchors.horizontalCenter:   parent.horizontalCenter
    //             }
    //         }
    //         Column {
    //             QGCColoredImage {
    //                 width: ScreenTools.defaultFontPixelHeight * 3
    //                 height: width
    //                 sourceSize.width: btText.width * iconScale
    //                 sourceSize.height: btText.width * iconScale
    //                 source: "/InstrumentValueIcons/border-all.svg"
    //                 fillMode: Image.PreserveAspectFit
    //                 anchors.horizontalCenter:   parent.horizontalCenter

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: {
    //                         camera.thermalPalette(6)
    //                         thermalPalettePopupDialog.close()
    //                     }
    //                 }
    //             }
    //             QGCLabel {
    //                 text: "Aurora"
    //                 anchors.horizontalCenter:   parent.horizontalCenter
    //             }
    //         }
    //         Column {
    //             QGCColoredImage {
    //                 width: ScreenTools.defaultFontPixelHeight * 3
    //                 height: width
    //                 sourceSize.width: btText.width * iconScale
    //                 sourceSize.height: btText.width * iconScale
    //                 source: "/InstrumentValueIcons/border-all.svg"
    //                 fillMode: Image.PreserveAspectFit
    //                 anchors.horizontalCenter:   parent.horizontalCenter

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: {
    //                         camera.thermalPalette(7)
    //                         thermalPalettePopupDialog.close()
    //                     }
    //                 }
    //             }
    //             QGCLabel {
    //                 text: "Red Hot"
    //                 anchors.horizontalCenter:   parent.horizontalCenter
    //             }
    //         }
    //         Column {
    //             QGCColoredImage {
    //                 width: ScreenTools.defaultFontPixelHeight * 3
    //                 height: width
    //                 sourceSize.width: btText.width * iconScale
    //                 sourceSize.height: btText.width * iconScale
    //                 source: "/InstrumentValueIcons/border-all.svg"
    //                 fillMode: Image.PreserveAspectFit
    //                 anchors.horizontalCenter:   parent.horizontalCenter

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: {
    //                         camera.thermalPalette(8)
    //                         thermalPalettePopupDialog.close()
    //                     }
    //                 }
    //             }
    //             QGCLabel {
    //                 text: "Jungle"
    //                 anchors.horizontalCenter:   parent.horizontalCenter
    //             }
    //         }
    //         Column {
    //             QGCColoredImage {
    //                 width: ScreenTools.defaultFontPixelHeight * 3
    //                 height: width
    //                 sourceSize.width: btText.width * iconScale
    //                 sourceSize.height: btText.width * iconScale
    //                 source: "/InstrumentValueIcons/border-all.svg"
    //                 fillMode: Image.PreserveAspectFit
    //                 anchors.horizontalCenter:   parent.horizontalCenter

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: {
    //                         camera.thermalPalette(9)
    //                         thermalPalettePopupDialog.close()
    //                     }
    //                 }
    //             }
    //             QGCLabel {
    //                 text: "Medical"
    //                 anchors.horizontalCenter:   parent.horizontalCenter
    //             }
    //         }
    //         Column {
    //             QGCColoredImage {
    //                 width: ScreenTools.defaultFontPixelHeight * 3
    //                 height: width
    //                 sourceSize.width: btText.width * iconScale
    //                 sourceSize.height: btText.width * iconScale
    //                 source: "/InstrumentValueIcons/border-all.svg"
    //                 fillMode: Image.PreserveAspectFit
    //                 anchors.horizontalCenter:   parent.horizontalCenter

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: {
    //                         camera.thermalPalette(10)
    //                         thermalPalettePopupDialog.close()
    //                     }
    //                 }
    //             }
    //             QGCLabel {
    //                 text: "Black Hot"
    //                 anchors.horizontalCenter:   parent.horizontalCenter
    //             }
    //         }
    //         Column {
    //             QGCColoredImage {
    //                 width: ScreenTools.defaultFontPixelHeight * 3
    //                 height: width
    //                 sourceSize.width: btText.width * iconScale
    //                 sourceSize.height: btText.width * iconScale
    //                 source: "/InstrumentValueIcons/border-all.svg"
    //                 fillMode: Image.PreserveAspectFit
    //                 anchors.horizontalCenter:   parent.horizontalCenter

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: {
    //                         camera.thermalPalette(11)
    //                         thermalPalettePopupDialog.close()
    //                     }
    //                 }
    //             }
    //             QGCLabel {
    //                 text: "Glory Hot"
    //                 anchors.horizontalCenter:   parent.horizontalCenter
    //             }
    //         }
    //     }
    // }

    // Rectangle {
    //     id: thermalPaletteControl
    //     width:      paletteSelectLayout.width + (_toolsMargin * 4)
    //     height:     paletteSelectLayout.height + (_toolsMargin * 4)
    //     color:      qgcPal.window
    //     radius:     _toolsMargin
    //     anchors.verticalCenter:     parent.verticalCenter
    //     anchors.horizontalCenter:   parent.horizontalCenter
    //     visible:    false

    //     ColumnLayout {
    //         id: paletteSelectLayout
    //         anchors.horizontalCenter: parent.horizontalCenter
    //         anchors.verticalCenter: parent.verticalCenter

    //         QGCLabel {
    //             Layout.fillWidth: true
    //             Layout.alignment: Qt.AlignHCenter
    //             text: qsTr("Select thermal palette")
    //         }

    //         GridLayout {
    //             Layout.fillWidth: true
    //             rows: 2
    //             rowSpacing: _toolsMargin * 2
    //             columns: 6
    //             columnSpacing: _toolsMargin * 2

    //             Column {
    //                 QGCColoredImage {
    //                     width: ScreenTools.defaultFontPixelHeight * 3
    //                     height: width
    //                     sourceSize.width: btText.width * iconScale
    //                     sourceSize.height: btText.width * iconScale
    //                     source: "/InstrumentValueIcons/border-all.svg"
    //                     fillMode: Image.PreserveAspectFit
    //                     anchors.horizontalCenter:   parent.horizontalCenter

    //                     MouseArea {
    //                         anchors.fill: parent
    //                         onClicked: {
    //                             if(currentThermalPalette < 12){
    //                                 camera.thermalPalette(0)
    //                             }
    //                             thermalPaletteControl.visible = false
    //                         }
    //                     }
    //                 }
    //                 QGCLabel {
    //                     text: "White Hot"
    //                     anchors.horizontalCenter:   parent.horizontalCenter
    //                 }
    //             }
    //             Column {
    //                 QGCColoredImage {
    //                     width: ScreenTools.defaultFontPixelHeight * 3
    //                     height: width
    //                     sourceSize.width: btText.width * iconScale
    //                     sourceSize.height: btText.width * iconScale
    //                     source: "/InstrumentValueIcons/border-all.svg"
    //                     fillMode: Image.PreserveAspectFit
    //                     anchors.horizontalCenter:   parent.horizontalCenter

    //                     MouseArea {
    //                         anchors.fill: parent
    //                         onClicked: {
    //                             if(currentThermalPalette < 12){
    //                                 camera.thermalPalette(2)
    //                             }
    //                             thermalPaletteControl.visible = false
    //                         }
    //                     }
    //                 }
    //                 QGCLabel {
    //                     text: "Sepia"
    //                     anchors.horizontalCenter:   parent.horizontalCenter
    //                 }
    //             }
    //             Column {
    //                 QGCColoredImage {
    //                     width: ScreenTools.defaultFontPixelHeight * 3
    //                     height: width
    //                     sourceSize.width: btText.width * iconScale
    //                     sourceSize.height: btText.width * iconScale
    //                     source: "/InstrumentValueIcons/border-all.svg"
    //                     fillMode: Image.PreserveAspectFit
    //                     anchors.horizontalCenter:   parent.horizontalCenter

    //                     MouseArea {
    //                         anchors.fill: parent
    //                         onClicked: {
    //                             if(currentThermalPalette < 12){
    //                                 camera.thermalPalette(3)
    //                             }
    //                             thermalPaletteControl.visible = false
    //                         }
    //                     }
    //                 }
    //                 QGCLabel {
    //                     text: "Ironbow"
    //                     anchors.horizontalCenter:   parent.horizontalCenter
    //                 }
    //             }
    //             Column {
    //                 QGCColoredImage {
    //                     width: ScreenTools.defaultFontPixelHeight * 3
    //                     height: width
    //                     sourceSize.width: btText.width * iconScale
    //                     sourceSize.height: btText.width * iconScale
    //                     source: "/InstrumentValueIcons/border-all.svg"
    //                     fillMode: Image.PreserveAspectFit
    //                     anchors.horizontalCenter:   parent.horizontalCenter

    //                     MouseArea {
    //                         anchors.fill: parent
    //                         onClicked: {
    //                             if(currentThermalPalette < 12){
    //                                 camera.thermalPalette(4)
    //                             }
    //                             thermalPaletteControl.visible = false
    //                         }
    //                     }
    //                 }
    //                 QGCLabel {
    //                     text: "Rainbow"
    //                     anchors.horizontalCenter:   parent.horizontalCenter
    //                 }
    //             }
    //             Column {
    //                 QGCColoredImage {
    //                     width: ScreenTools.defaultFontPixelHeight * 3
    //                     height: width
    //                     sourceSize.width: btText.width * iconScale
    //                     sourceSize.height: btText.width * iconScale
    //                     source: "/InstrumentValueIcons/border-all.svg"
    //                     fillMode: Image.PreserveAspectFit
    //                     anchors.horizontalCenter:   parent.horizontalCenter

    //                     MouseArea {
    //                         anchors.fill: parent
    //                         onClicked: {
    //                             if(currentThermalPalette < 12){
    //                                 camera.thermalPalette(5)
    //                             }
    //                             thermalPaletteControl.visible = false
    //                         }
    //                     }
    //                 }
    //                 QGCLabel {
    //                     text: "Night"
    //                     anchors.horizontalCenter:   parent.horizontalCenter
    //                 }
    //             }
    //             Column {
    //                 QGCColoredImage {
    //                     width: ScreenTools.defaultFontPixelHeight * 3
    //                     height: width
    //                     sourceSize.width: btText.width * iconScale
    //                     sourceSize.height: btText.width * iconScale
    //                     source: "/InstrumentValueIcons/border-all.svg"
    //                     fillMode: Image.PreserveAspectFit
    //                     anchors.horizontalCenter:   parent.horizontalCenter

    //                     MouseArea {
    //                         anchors.fill: parent
    //                         onClicked: {
    //                             if(currentThermalPalette < 12){
    //                                 camera.thermalPalette(6)
    //                             }
    //                             thermalPaletteControl.visible = false
    //                         }
    //                     }
    //                 }
    //                 QGCLabel {
    //                     text: "Aurora"
    //                     anchors.horizontalCenter:   parent.horizontalCenter
    //                 }
    //             }
    //             Column {
    //                 QGCColoredImage {
    //                     width: ScreenTools.defaultFontPixelHeight * 3
    //                     height: width
    //                     sourceSize.width: btText.width * iconScale
    //                     sourceSize.height: btText.width * iconScale
    //                     source: "/InstrumentValueIcons/border-all.svg"
    //                     fillMode: Image.PreserveAspectFit
    //                     anchors.horizontalCenter:   parent.horizontalCenter

    //                     MouseArea {
    //                         anchors.fill: parent
    //                         onClicked: {
    //                             if(currentThermalPalette < 12){
    //                                 camera.thermalPalette(7)
    //                             }
    //                             thermalPaletteControl.visible = false
    //                         }
    //                     }
    //                 }
    //                 QGCLabel {
    //                     text: "Red Hot"
    //                     anchors.horizontalCenter:   parent.horizontalCenter
    //                 }
    //             }
    //             Column {
    //                 QGCColoredImage {
    //                     width: ScreenTools.defaultFontPixelHeight * 3
    //                     height: width
    //                     sourceSize.width: btText.width * iconScale
    //                     sourceSize.height: btText.width * iconScale
    //                     source: "/InstrumentValueIcons/border-all.svg"
    //                     fillMode: Image.PreserveAspectFit
    //                     anchors.horizontalCenter:   parent.horizontalCenter

    //                     MouseArea {
    //                         anchors.fill: parent
    //                         onClicked: {
    //                             if(currentThermalPalette < 12){
    //                                 camera.thermalPalette(8)
    //                             }
    //                             thermalPaletteControl.visible = false
    //                         }
    //                     }
    //                 }
    //                 QGCLabel {
    //                     text: "Jungle"
    //                     anchors.horizontalCenter:   parent.horizontalCenter
    //                 }
    //             }
    //             Column {
    //                 QGCColoredImage {
    //                     width: ScreenTools.defaultFontPixelHeight * 3
    //                     height: width
    //                     sourceSize.width: btText.width * iconScale
    //                     sourceSize.height: btText.width * iconScale
    //                     source: "/InstrumentValueIcons/border-all.svg"
    //                     fillMode: Image.PreserveAspectFit
    //                     anchors.horizontalCenter:   parent.horizontalCenter

    //                     MouseArea {
    //                         anchors.fill: parent
    //                         onClicked: {
    //                             if(currentThermalPalette < 12){
    //                                 camera.thermalPalette(9)
    //                             }
    //                             thermalPaletteControl.visible = false
    //                         }
    //                     }
    //                 }
    //                 QGCLabel {
    //                     text: "Medical"
    //                     anchors.horizontalCenter:   parent.horizontalCenter
    //                 }
    //             }
    //             Column {
    //                 QGCColoredImage {
    //                     width: ScreenTools.defaultFontPixelHeight * 3
    //                     height: width
    //                     sourceSize.width: btText.width * iconScale
    //                     sourceSize.height: btText.width * iconScale
    //                     source: "/InstrumentValueIcons/border-all.svg"
    //                     fillMode: Image.PreserveAspectFit
    //                     anchors.horizontalCenter:   parent.horizontalCenter

    //                     MouseArea {
    //                         anchors.fill: parent
    //                         onClicked: {
    //                             if(currentThermalPalette < 12){
    //                                 camera.thermalPalette(10)
    //                             }
    //                             thermalPaletteControl.visible = false
    //                         }
    //                     }
    //                 }
    //                 QGCLabel {
    //                     text: "Black Hot"
    //                     anchors.horizontalCenter:   parent.horizontalCenter
    //                 }
    //             }
    //             Column {
    //                 QGCColoredImage {
    //                     width: ScreenTools.defaultFontPixelHeight * 3
    //                     height: width
    //                     sourceSize.width: btText.width * iconScale
    //                     sourceSize.height: btText.width * iconScale
    //                     source: "/InstrumentValueIcons/border-all.svg"
    //                     fillMode: Image.PreserveAspectFit
    //                     anchors.horizontalCenter:   parent.horizontalCenter

    //                     MouseArea {
    //                         anchors.fill: parent
    //                         onClicked: {
    //                             if(currentThermalPalette < 12){
    //                                 camera.thermalPalette(11)
    //                             }
    //                             thermalPaletteControl.visible = false
    //                         }
    //                     }
    //                 }
    //                 QGCLabel {
    //                     text: "Glory Hot"
    //                     anchors.horizontalCenter:   parent.horizontalCenter
    //                 }
    //             }
    //         }
    //     }
    // }

    // Component.onCompleted: {
    //     SiYi.iconsHeight = Qt.binding(function () {
    //         return controlColumn.height
    //     })
    // }

    function updateLaserInfoPos() {
        if (root.width - laserImage.x < laserInfo.width) {
            laserInfo.x = laserImage.x - laserInfo.width
        } else {
            laserInfo.x = laserImage.x + laserImage.width
        }

        if (root.height - laserImage.y < laserInfo.height) {
            laserInfo.y = laserImage.y - laserInfo.height
        } else {
            laserInfo.y = laserImage.y + laserImage.height
        }
    }
}
