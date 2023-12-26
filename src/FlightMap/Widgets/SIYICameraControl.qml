import QtQuick                          2.11
import QtQuick.Controls                 2.4
import QtQuick.Layouts                  1.2

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
//import "qrc:/qml/QGroundControl/Controls"

Rectangle {
    id: controlRectangle
    width: controlColumn.width + (_margins * 2)
    height: controlColumn.height + (_margins * 2)
    //visible: camera.isConnected
    color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.7)
    radius:     _margins
    visible:    camera.enablePhoto

    property real   _margins:                                   ScreenTools.defaultFontPixelHeight / 2

    property var siyi: SiYi
    property SiYiCamera camera: siyi.camera
    property bool isRecording: camera.isRecording
    property int minDelta: 5
    property int buttonSize:    ScreenTools.defaultFontPixelHeight * 2

    GridLayout {
        id: controlColumn
        //spacing: ScreenTools.defaultFontPixelHeight

        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter

        columns: 2

        Image { // 拍照
            id: photo
            sourceSize.width: buttonSize
            sourceSize.height: buttonSize
            visible: camera.enablePhoto
            source: photoMA.pressed ? "/SiYi/PhotoGreen.svg" : "/SiYi/Photo.svg"
            Layout.alignment: Qt.AlignHCenter
//            source: camera.enablePhoto
//                    ? photoMA.pressed ? "/SiYi/PhotoGreen.svg" : "/SiYi/Photo.svg"
//                    : "/SiYi/empty.png"
//            anchors.horizontalCenter: parent.horizontalCenter
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
        }

        Image { // 录像
            id: video
            sourceSize.width: buttonSize
            sourceSize.height: buttonSize
            width: buttonSize
            height: buttonSize
            cache: false

            Layout.alignment: Qt.AlignHCenter // nchors.horizontalCenter: parent.horizontalCenter
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

            Connections {
                target: camera
                function onEnableVideoChanged() {
                    video.source = "/SiYi/empty.png"
                    if (camera.enableVideo) {
                        if (camera.isRecording) {
                            video.source = "/SiYi/Stop.svg"
                        } else {
                            video.source = "/SiYi/Video.png"
                        }
                    }
                }

                function onIsRecordingChanged() {
                    video.source = "/SiYi/empty.png"
                    if (camera.isRecording) {
                        video.source = "/SiYi/Stop.svg"
                    } else {
                        video.source = "/SiYi/Video.png"
                    }
                }
            }
        }

        Image { // 放大
            id: zoomInImage
            sourceSize.width: buttonSize // btText.width
            sourceSize.height: buttonSize
            visible: camera.enableZoom
            source: zoomInMA.pressed ? "/SiYi/ZoomInGreen.svg" : "/SiYi/ZoomIn.svg"
//            source: camera.enableZoom
//                    ? zoomInMA.pressed ? "/SiYi/ZoomInGreen.svg" : "/SiYi/ZoomIn.svg"
//                    : "/SiYi/empty.png"
//            anchors.horizontalCenter: parent.horizontalCenter
            Layout.alignment: Qt.AlignHCenter
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
            visible: camera.enableZoom
            source: zoomOutMA.pressed ? "/SiYi/ZoomOutGreen.svg" : "/SiYi/ZoomOut.svg"
            Layout.alignment: Qt.AlignHCenter
//            source: camera.enableZoom
//                    ? zoomOutMA.pressed ? "/SiYi/ZoomOutGreen.svg" : "/SiYi/ZoomOut.svg"
//                    : "/SiYi/empty.png"
//            anchors.horizontalCenter: parent.horizontalCenter
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

        Image { // 远景
            id: far
            sourceSize.width: buttonSize
            sourceSize.height: buttonSize
            visible: camera.enableFocus
            source: farMA.pressed ? "/SiYi/farGreen.svg" : "/SiYi/far.svg"
            Layout.alignment: Qt.AlignHCenter
//            source: camera.enableFocus
//                    ? farMA.pressed ? "/SiYi/farGreen.svg" : "/SiYi/far.svg"
//                    : "/SiYi/empty.png"
//            anchors.horizontalCenter: parent.horizontalCenter
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
            visible: camera.enableFocus
            source: neerMA.pressed ? "/SiYi/neerGreen.svg" : "/SiYi/neer.svg"
            Layout.alignment: Qt.AlignHCenter
//            source: camera.enableFocus
//                    ? neerMA.pressed ? "/SiYi/neerGreen.svg" : "/SiYi/neer.svg"
//                    : "/SiYi/empty.png"
//            anchors.horizontalCenter: parent.horizontalCenter
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

        Image { // 回中
            id: reset
            sourceSize.width: buttonSize
            sourceSize.height: buttonSize
            visible: camera.enableControl
            source: resetMA.pressed ? "/SiYi/ResetGreen.svg" : "/SiYi/Reset.svg"
            Layout.alignment: Qt.AlignHCenter
//            source: camera.enableControl
//                    ? resetMA.pressed ? "/SiYi/ResetGreen.svg" : "/SiYi/Reset.svg"
//                    : "/SiYi/empty.png"
//            anchors.horizontalCenter: parent.horizontalCenter
            fillMode: Image.PreserveAspectFit
            cache: false
            MouseArea {
                id: resetMA
                anchors.fill: parent
                onPressed: camera.resetPostion()
            }
        }
    }
}
