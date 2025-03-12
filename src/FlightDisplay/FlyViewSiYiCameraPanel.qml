

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
    //clip: true
    //anchors.fill: parent
    color:  Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, _backgroundOpacity)
    width:  mainGridLayout.width + _margins
    height: mainGridLayout.height + _margins
    radius: _margins

    property var siyi: SiYi
    property SiYiCamera camera: siyi.camera
    property SiYiTransmitter transmitter: siyi.transmitter
    property bool isRecording: camera.isRecording
    property int minDelta: 5
    property bool hasBeenMoved: false

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
    property real _fontSize: ScreenTools.isMobile ? ScreenTools.defaultFontPointSize * 0.8 : ScreenTools.defaultFontPointSize
    property real _idealWidth:  ScreenTools.defaultFontPixelWidth * 7
    property real _backgroundOpacity:  QGroundControl.settingsManager.flyViewSettings.flyviewWidgetOpacity.rawValue

    GridLayout {
        id:     mainGridLayout
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        columnSpacing:              ScreenTools.defaultFontPixelHeight / 2
        rowSpacing:                 columnSpacing
        columns:                    2

        QGCLabel {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            text : "SIYI Camera"
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            height : 1
            color : qgcPal.groupBorder
        }

        QGCColumnButton{
            id:                 photoButton
            implicitWidth:      _idealWidth
            implicitHeight:     width

            iconSource:         "/SiYi/Photo.svg"
            text:               "Photo"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                camera.sendCommand(SiYiCamera.CameraCommandTakePhoto)
            }
        }

        QGCColumnButton{
            id:                 videoButton
            implicitWidth:      _idealWidth
            implicitHeight:     width

            iconSource:         "/SiYi/Video.svg"
            text:               "Record"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                if (camera.isRecording) {
                    camera.sendRecodingCommand(
                                SiYiCamera.CloseRecording)
                } else {
                    camera.sendRecodingCommand(SiYiCamera.OpenRecording)
                }
            }

            Connections {
                target: camera
                function onEnableVideoChanged() {
                    videoButton.iconSource = "/SiYi/empty.png"
                    if (camera.enableVideo) {
                        if (camera.isRecording) {
                            videoButton.iconSource = "/SiYi/Stop.svg"
                            videoButton.iconColor = qgcPal.colorRed
                            videoButton.text = "Recording"
                        } else {
                            videoButton.iconSource = "/SiYi/Video.png"
                            videoButton.text = "Record"
                        }
                    }
                }

                function onIsRecordingChanged() {
                    videoButton.iconSource = "/SiYi/empty.png"
                    if (camera.isRecording) {
                        videoButton.iconSource = "/SiYi/Stop.svg"
                        videoButton.iconColor = qgcPal.colorRed
                        videoButton.text = "Recording"
                    } else {
                        videoButton.iconSource = "/SiYi/Video.png"
                        videoButton.text = "Record"
                    }
                }
            }
        }

        Rectangle {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            height : 1
            color : qgcPal.groupBorder
        }

        QGCColumnButton{
            id:                 zoomInButton
            implicitWidth:      _idealWidth
            implicitHeight:     width

            iconSource:         "/SiYi/ZoomIn.svg"
            text:               "ZoomIn"
            font.pointSize:     _fontSize * 0.7

            onPressed: {
                if (camera.is4k) {
                    camera.emitOperationResultChanged(-1)
                } else {
                    camera.zoom(1)
                    zoomInTimer.start()
                }
            }
            onReleased: {
                zoomInTimer.stop()
                camera.zoom(0)
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

        QGCColumnButton{
            id:                 zoomOutButton
            implicitWidth:      _idealWidth
            implicitHeight:     width

            iconSource:         "/SiYi/ZoomOut.svg"
            text:               "ZoomOut"
            font.pointSize:     _fontSize * 0.7

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

        QGCColumnButton{
            id:                 farButton
            implicitWidth:      _idealWidth
            implicitHeight:     width

            iconSource:         "/SiYi/far.svg"
            text:               "Far"
            font.pointSize:     _fontSize * 0.7

            onPressed: {
                camera.focus(1)
                farTimer.start()
            }
            onReleased: {
                farTimer.stop()
                camera.focus(0)
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

        QGCColumnButton{
            id:                 neerButton
            implicitWidth:      _idealWidth
            implicitHeight:     width

            iconSource:         "/SiYi/neer.svg"
            text:               "Neer"
            font.pointSize:     _fontSize * 0.7

            onPressed: {
                camera.focus(-1)
                farTimer.start()
            }
            onReleased: {
                farTimer.stop()
                camera.focus(0)
            }
            Timer {
                id: neerTimer
                interval: 100
                repeat: false
                running: false
                onTriggered: {
                    camera.focus(-1)
                    farTimer.start()
                }
            }
        }

        Rectangle {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            height : 1
            color : qgcPal.groupBorder
        }

        QGCColumnButton{
            id:                 resetButton
            implicitWidth:      _idealWidth
            implicitHeight:     width

            iconSource:         "/SiYi/Reset.svg"
            text:               "Reset"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                camera.resetPostion()
            }
        }

        QGCColumnButton{
            id:                 aiButton
            implicitWidth:      _idealWidth
            implicitHeight:     width

            iconSource:         "/SiYi/AiGreen.svg"
            iconColor:          camera.aiModeOn ? (camera.isTracking ? qgcPal.colorRed : qgcPal.colorGreen) : qgcPal.text
            text:               "AI"
            font.pointSize:     _fontSize * 0.7
            visible:            camera.enableAi

            onClicked: {
                if (camera.aiModeOn) {
                    if (camera.isTracking) {
                        camera.setTrackingTarget(false, 0, 0)
                    } else {
                        camera.setAiModel(SiYiCamera.AiModeOff)
                    }
                } else {
                    camera.setAiModel(SiYiCamera.AiModeOn)
                }
            }
        }

        QGCColumnButton{
            id:                 laserButton
            implicitWidth:      _idealWidth
            implicitHeight:     width

            iconSource:         "/SiYi/LaserDistance.svg"
            iconColor:          {
                if (camera.laserStateHasResponse) {
                    if (camera.laserStateOn) {
                        return qgcPal.colorGreen
                    } else {
                        return qgcPal.text
                    }
                } else {
                    if (root.laserIconShow) {
                        return qgcPal.colorGreen
                    } else {
                        return qgcPal.text
                    }
                }
            }
            text:               "Laser"
            font.pointSize:     _fontSize * 0.7
            visible:            camera.enableLaser

            onClicked: {
                if (camera.laserStateHasResponse) {
                    console.info("Set laser state: ",
                                 camera.laserStateOn ? "OFF" : "ON")
                    var onState = camera.laserStateOn ? SiYiCamera.LaserStateOff : SiYiCamera.LaserStateOn
                    camera.setLaserState(onState)
                } else {
                    root.laserIconShow = !root.laserIconShow
                }
            }
        }

        QGCColumnButton{
            id:                 screenButton
            implicitWidth:      _idealWidth
            implicitHeight:     width

            iconSource:         "/InstrumentValueIcons/view-tile.svg"
            text:               "Screen"
            font.pointSize:     _fontSize * 0.7
            //visible:            camera.enableThermal

            onClicked: {
                imageModePopupDialog.open()
            }
        }

        QGCColumnButton{
            id:                 paletteButton
            implicitWidth:      _idealWidth
            implicitHeight:     width

            iconSource:         "/InstrumentValueIcons/border-all.svg"
            text:               "Palette"
            font.pointSize:     _fontSize * 0.7
            //visible:            camera.enableThermal

            onClicked: {
                thermalPalettePopupDialog.open()
            }
        }
    }

    QGCPopupDialog {
        id: imageModePopupDialog
        title: qsTr("Select image mode")
        buttons: Dialog.Cancel
        destroyOnClose: false

        property var imageModeModel: [
            { label: "Zoom",       mode0: 0, mode1: 1, icon: "/InstrumentValueIcons/view-tile.svg" },
            { label: "Wide",       mode0: 1, mode1: 0, icon: "/InstrumentValueIcons/view-tile.svg" },
            { label: "Thermal",    mode0: 2, mode1: 0, icon: "/InstrumentValueIcons/view-tile.svg" },
            { label: "Zoom\n/Thermal", mode0: 3, mode1: 1, icon: "/InstrumentValueIcons/view-tile.svg" },
            { label: "Wide\n/Thermal", mode0: 4, mode1: 0, icon: "/InstrumentValueIcons/view-tile.svg" },
            { label: "Zoom\n/Wide",    mode0: 5, mode1: 0, icon: "/InstrumentValueIcons/view-tile.svg" }
        ]

        GridLayout {
            rows: 2
            columns: 3
            rowSpacing: _margins * 3
            columnSpacing: _margins * 3

            Repeater {
                model: imageModePopupDialog.imageModeModel
                delegate: Column {
                    QGCColoredImage {
                        width: ScreenTools.implicitButtonHeight * 1.5
                        height: width
                        source: modelData.icon
                        fillMode: Image.PreserveAspectFit
                        anchors.horizontalCenter: parent.horizontalCenter

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (currentImageMode < 9) {
                                    camera.imageMode(modelData.mode0, modelData.mode1)
                                }
                                imageModePopupDialog.close()
                            }
                        }
                    }
                    QGCLabel {
                        text: modelData.label
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }

    QGCPopupDialog {
        id: thermalPalettePopupDialog
        title: qsTr("Select image mode")
        buttons: Dialog.Cancel
        destroyOnClose: false

        property var paletteModel: [
            { paletteId: 0, label: "White Hot", icon: "/InstrumentValueIcons/border-all.svg" },
            { paletteId: 2, label: "Sepia",     icon: "/InstrumentValueIcons/border-all.svg" },
            { paletteId: 3, label: "Ironbow",   icon: "/InstrumentValueIcons/border-all.svg" },
            { paletteId: 4, label: "Rainbow",   icon: "/InstrumentValueIcons/border-all.svg" },
            { paletteId: 5, label: "Night",     icon: "/InstrumentValueIcons/border-all.svg" },
            { paletteId: 6, label: "Aurora",    icon: "/InstrumentValueIcons/border-all.svg" },
            { paletteId: 7, label: "Red Hot",   icon: "/InstrumentValueIcons/border-all.svg" },
            { paletteId: 8, label: "Jungle",    icon: "/InstrumentValueIcons/border-all.svg" },
            { paletteId: 9, label: "Medical",   icon: "/InstrumentValueIcons/border-all.svg" },
            { paletteId: 10, label: "Black Hot",icon: "/InstrumentValueIcons/border-all.svg" },
            { paletteId: 11, label: "Glory Hot",icon: "/InstrumentValueIcons/border-all.svg" }
        ]

        GridLayout {
            rows: 2
            columns: 6
            rowSpacing: _margins * 3
            columnSpacing: _margins * 3

            Repeater {
                model: thermalPalettePopupDialog.paletteModel
                delegate: Column {
                    QGCColoredImage {
                        width: ScreenTools.implicitButtonHeight * 1.5
                        height: width
                        source: modelData.icon
                        fillMode: Image.PreserveAspectFit
                        anchors.horizontalCenter: parent.horizontalCenter

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                camera.thermalPalette(modelData.paletteId)
                                thermalPalettePopupDialog.close()
                            }
                        }
                    }
                    QGCLabel {
                        text: modelData.label
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }

    // QGCPopupDialog {
    //     id: imageModePopupDialog
    //     title: qsTr("Select image mode")
    //     buttons: Dialog.Cancel
    //     destroyOnClose: false

    //     GridLayout {
    //         //Layout.fillWidth: true
    //         rows: 2
    //         rowSpacing: _margins * 3
    //         columns: 3
    //         columnSpacing: _margins * 3

    //         Column {
    //             QGCColoredImage {
    //                 width: ScreenTools.implicitButtonHeight * 1.5
    //                 height: width
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
    //                 width: ScreenTools.implicitButtonHeight * 1.5
    //                 height: width
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
    //                 width: ScreenTools.implicitButtonHeight * 1.5
    //                 height: width
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
    //                 width: ScreenTools.implicitButtonHeight * 1.5
    //                 height: width
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
    //                 width: ScreenTools.implicitButtonHeight * 1.5
    //                 height: width
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
    //                 width: ScreenTools.implicitButtonHeight * 1.5
    //                 height: width
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
    //         rowSpacing: _margins * 3
    //         columns: 6
    //         columnSpacing: _margins * 3

    //         Column {
    //             QGCColoredImage {
    //                 width: ScreenTools.implicitButtonHeight * 1.5
    //                 height: width
    //                 source: "/InstrumentValueIcons/border-all.svg"
    //                 fillMode: Image.PreserveAspectFit
    //                 anchors.horizontalCenter:   parent.horizontalCenter

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: {
    //                         camera.thermalPalette(0)
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
    //                 width: ScreenTools.implicitButtonHeight * 1.5
    //                 height: width
    //                 source: "/InstrumentValueIcons/border-all.svg"
    //                 fillMode: Image.PreserveAspectFit
    //                 anchors.horizontalCenter:   parent.horizontalCenter

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: {
    //                         camera.thermalPalette(2)
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
    //                 width: ScreenTools.implicitButtonHeight * 1.5
    //                 height: width
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
    //                 width: ScreenTools.implicitButtonHeight * 1.5
    //                 height: width
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
    //                 width: ScreenTools.implicitButtonHeight * 1.5
    //                 height: width
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
    //                 width: ScreenTools.implicitButtonHeight * 1.5
    //                 height: width
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
    //                 width: ScreenTools.implicitButtonHeight * 1.5
    //                 height: width
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
    //                 width: ScreenTools.implicitButtonHeight * 1.5
    //                 height: width
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
    //                 width: ScreenTools.implicitButtonHeight * 1.5
    //                 height: width
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
    //                 width: ScreenTools.implicitButtonHeight * 1.5
    //                 height: width
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
    //                 width: ScreenTools.implicitButtonHeight * 1.5
    //                 height: width
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
}
