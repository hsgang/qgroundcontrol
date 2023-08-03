/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick                          2.11
import QtQuick.Controls                 2.4

import QGroundControl                   1.0
import QGroundControl.FlightDisplay     1.0
import QGroundControl.FlightMap         1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.Controls          1.0
import QGroundControl.Palette           1.0
import QGroundControl.Vehicle           1.0
import QGroundControl.Controllers       1.0

import SiYi.Object 1.0
import QtGraphicalEffects 1.12
import "qrc:/qml/QGroundControl/Controls"

Item {
    id: controlRectangle
    anchors.left: parent.left
    anchors.leftMargin: 150
    anchors.topMargin: 10
    width: controlColumn.width
    height: controlColumn.height
    anchors.top: parent.top
    //visible: camera.isConnected

    property var siyi: SiYi
    property SiYiCamera camera: siyi.camera
    property bool isRecording: camera.isRecording
    property int minDelta: 5
    property int buttonSize:    ScreenTools.defaultFontPixelHeight * 3

    Text {
        id: btText
        text: "1234"
        anchors.verticalCenter: parent.verticalCenter
        visible: false
    }

    Column {
        id: controlColumn
        spacing: ScreenTools.defaultFontPixelHeight

        Image { // 放大
            id: zoomInImage
            sourceSize.width: buttonSize // btText.width
            sourceSize.height: buttonSize
            source: camera.enableZoom
                    ? zoomInMA.pressed ? "qrc:/resources/SiYi/ZoomInGreen.svg" : "qrc:/resources/SiYi/ZoomIn.svg"
                    : "qrc:/resources/SiYi/empty.png"
            anchors.horizontalCenter: parent.horizontalCenter
            fillMode: Image.PreserveAspectFit
            cache: false
            MouseArea {
                id: zoomInMA
                anchors.fill: parent
                onPressed: {
                    if (camera.is4k) {
                        camera.emitOperationResultChanged(-1)
                    } else {
                        camera.zoom(1)
                        zoomInTimer.start()
                        console.info("zoomIn start--------------------------------")
                    }
                }
                onReleased: {
                    zoomInTimer.stop()
                    camera.zoom(0)
                    console.info("zoomIn stop--------------------------------")
                }
            }
//                ColorOverlay {
//                    anchors.fill: zoomInImage
//                    source: zoomInImage
//                    color: zoomInMA.pressed ? "green" : "white"
//                }
            Timer {
                id: zoomInTimer
                interval: 100
                repeat: false
                running: false
                onTriggered: {
                    camera.zoom(1)
                    zoomInTimer.start()
                }
            }
        }

        Image { // 缩小
            id: zoomOut
            sourceSize.width: buttonSize
            sourceSize.height: buttonSize
            source: camera.enableZoom
                    ? zoomOutMA.pressed ? "qrc:/resources/SiYi/ZoomOutGreen.svg" : "qrc:/resources/SiYi/ZoomOut.svg"
                    : "qrc:/resources/SiYi/empty.png"
            anchors.horizontalCenter: parent.horizontalCenter
            fillMode: Image.PreserveAspectFit
            cache: false
            MouseArea {
                id: zoomOutMA
                anchors.fill: parent
                onPressed: {
                    if (camera.is4k) {
                        camera.emitOperationResultChanged(-1)
                    } else {
                        camera.zoom(-1)
                        zoomOutTimer.start()
                    }
                }
                onReleased: {
                    zoomOutTimer.stop()
                    camera.zoom(0)
                }
            }
//                ColorOverlay {
//                    anchors.fill: zoomOut
//                    source: zoomOut
//                    color: zoomOutMA.pressed ? "green" : "white"
//                }
            Timer {
                id: zoomOutTimer
                interval: 100
                repeat: false
                running: false
                onTriggered: {
                    camera.zoom(-1)
                    zoomOutTimer.start()
                }
            }
        }

        Image { // 回中
            id: reset
            sourceSize.width: buttonSize
            sourceSize.height: buttonSize
            source: camera.enableControl
                    ? resetMA.pressed ? "qrc:/resources/SiYi/ResetGreen.svg" : "qrc:/resources/SiYi/Reset.svg"
                    : "qrc:/resources/SiYi/empty.png"
            anchors.horizontalCenter: parent.horizontalCenter
            fillMode: Image.PreserveAspectFit
            cache: false
            MouseArea {
                id: resetMA
                anchors.fill: parent
                onPressed: camera.resetPostion()
            }
//                ColorOverlay {
//                    anchors.fill: reset
//                    source: reset
//                    color: resetMA.pressed ? "green" : "white"
//                }
        }

        Image { // 拍照
            id: photo
            sourceSize.width: buttonSize
            sourceSize.height: buttonSize
            source: camera.enablePhoto
                    ? photoMA.pressed ? "qrc:/resources/SiYi/PhotoGreen.svg" : "qrc:/resources/SiYi/Photo.svg"
                    : "qrc:/resources/SiYi/empty.png"
            anchors.horizontalCenter: parent.horizontalCenter
            fillMode: Image.PreserveAspectFit
            cache: false
            MouseArea {
                id: photoMA
                anchors.fill: parent
                onPressed: {
                    console.info("camera.sendCommand(SiYiCamera.CameraCommandTakePhoto)")
                    camera.sendCommand(SiYiCamera.CameraCommandTakePhoto)
                }
            }
//                ColorOverlay {
//                    anchors.fill: photo
//                    source: photo
//                    color: photoMA.pressed ? "green" : "white"
//                }
        }

        Image { // 录像
            id: video
            //sourceSize.width: btText.width
            //sourceSize.height: btText.width
            width: buttonSize
            height: buttonSize
            cache: false
//                source: {
//                    if (camera.enableVideo) {
//                        if (camera.isRecording) {
//                            return "qrc:/resources/SiYi/Stop.svg"
//                        } else {
//                            return "qrc:/resources/SiYi/Video.png"
//                        }
//                    } else {
//                        return "qrc:/resources/SiYi/empty.png"
//                    }
//                }
            anchors.horizontalCenter: parent.horizontalCenter
            fillMode: Image.PreserveAspectFit
            visible: camera.enableVideo
            MouseArea {
                id: videoMA
                anchors.fill: parent
                onPressed: {
                    if (camera.isRecording) {
                        camera.sendRecodingCommand(SiYiCamera.CloseRecording)
                    } else {
                        camera.sendRecodingCommand(SiYiCamera.OpenRecording)
                    }
                }
            }
//                ColorOverlay {
//                    anchors.fill: video
//                    source: video
//                    color: {
//                        if (camera.isRecording) {
//                            return "red"
//                        } else {
//                            return videoMA.pressed ? "green" : "white"
//                        }
//                    }
//                }
            Connections {
                target: camera
                function onEnableVideoChanged() {
                    video.source = "qrc:/resources/SiYi/empty.png"
                    if (camera.enableVideo) {
                        if (camera.isRecording) {
                            video.source = "qrc:/resources/SiYi/Stop.svg"
                        } else {
                            video.source = "qrc:/resources/SiYi/Video.png"
                        }
                    }
                }

                function onIsRecordingChanged() {
                    video.source = "qrc:/resources/SiYi/empty.png"
                    if (camera.isRecording) {
                        video.source = "qrc:/resources/SiYi/Stop.svg"
                    } else {
                        video.source = "qrc:/resources/SiYi/Video.png"
                    }
                }
            }
        }

        Image { // 远景
            id: far
            sourceSize.width: buttonSize
            sourceSize.height: buttonSize
            source: camera.enableFocus
                    ? farMA.pressed ? "qrc:/resources/SiYi/farGreen.svg" : "qrc:/resources/SiYi/far.svg"
                    : "qrc:/resources/SiYi/empty.png"
            anchors.horizontalCenter: parent.horizontalCenter
            fillMode: Image.PreserveAspectFit
            cache: false
            MouseArea {
                id: farMA
                anchors.fill: parent
                onPressed: {
                    camera.focus(1)
                    farTimer.start()
                }
                onReleased: {
                    farTimer.stop()
                    camera.focus(0)
                }
            }
//                ColorOverlay {
//                    anchors.fill: far
//                    source: far
//                    color: farMA.pressed ? "green" : "white"
//                }
            Timer {
                id: farTimer
                interval: 100
                repeat: false
                running: false
                onTriggered: {
                    camera.focus(1)
                    farTimer.start()
                }
            }
        }

        Image { // 近景
            id: neer
            sourceSize.width: buttonSize
            sourceSize.height: buttonSize
            source: camera.enableFocus
                    ? neerMA.pressed ? "qrc:/resources/SiYi/neerGreen.svg" : "qrc:/resources/SiYi/neer.svg"
                    : "qrc:/resources/SiYi/empty.png"
            anchors.horizontalCenter: parent.horizontalCenter
            fillMode: Image.PreserveAspectFit
            cache: false
            MouseArea {
                id: neerMA
                anchors.fill: parent
                onPressed: {
                    camera.focus(-1)
                    neerTimer.start()
                }
                onReleased: {
                    neerTimer.stop()
                    camera.focus(0)
                }
            }
//                ColorOverlay {
//                    anchors.fill: neer
//                    source: neer
//                    color: neerMA.pressed ? "green" : "white"
//                }
            Timer {
                id: neerTimer
                interval: 100
                repeat: false
                running: false
                onTriggered: {
                    camera.focus(-1)
                    neerTimer.start()
                }
            }
        }
    }
}
