import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.FlightMap

Item {
    id: root
    height: columnLayout.height
    width:  columnLayout.width

    property var    _activeVehicle:          QGroundControl.multiVehicleManager.activeVehicle

    property real   size:         _defaultSize
    property real   _defaultSize: ScreenTools.defaultFontPixelHeight * 7
    property real   _sizeRatio:   ScreenTools.isTinyScreen ? (size / _defaultSize) * 0.5 : size / _defaultSize
    property int    _fontSize:    ScreenTools.defaultFontPointSize * _sizeRatio

    property real   _logCount:      _activeVehicle?.atmosphericSensor?.logCount?.rawValue ?? NaN
    property real   _temperature:   _activeVehicle?.atmosphericSensor?.temperature?.rawValue ?? NaN
    property real   _humidity:      _activeVehicle?.atmosphericSensor?.humidity?.rawValue ?? NaN
    property real   _pressure:      _activeVehicle?.atmosphericSensor?.pressure?.rawValue ?? NaN
    property real   _windDir:       _activeVehicle?.atmosphericSensor?.windDir?.rawValue ?? NaN
    property real   _windSpd:       _activeVehicle?.atmosphericSensor?.windSpd?.rawValue ?? NaN
    property real   _pm1p0:         _activeVehicle?.atmosphericSensor?.opc1?.rawValue ?? NaN
    property real   _pm2p5:         _activeVehicle?.atmosphericSensor?.opc2?.rawValue ?? NaN
    property real   _pm10:          _activeVehicle?.atmosphericSensor?.opc3?.rawValue ?? NaN
    property real   _radiation:     _activeVehicle?.atmosphericSensor?.radiation?.rawValue ?? NaN
    property real   _hubTemp1:      _activeVehicle?.atmosphericSensor?.hubTemp1?.rawValue ?? NaN
    property real   _hubTemp2:      _activeVehicle?.atmosphericSensor?.hubTemp2?.rawValue ?? NaN
    property real   _hubHumi1:      _activeVehicle?.atmosphericSensor?.hubHumi1?.rawValue ?? NaN
    property real   _hubHumi2:      _activeVehicle?.atmosphericSensor?.hubHumi2?.rawValue ?? NaN
    property real   _hubPressure:   _activeVehicle?.atmosphericSensor?.hubPressure?.rawValue ?? NaN
    property real   _batt:          _activeVehicle?.atmosphericSensor?.batt?.rawValue ?? NaN
    property real   _sdVolume:      _activeVehicle?.atmosphericSensor?.sdVolume?.rawValue ?? NaN
    property var    _timeHMS:       _activeVehicle?.atmosphericSensor?.timeHMS?.rawValue ?? "--:--:--"
    property int    _windRef:       _activeVehicle?.atmosphericSensor?.windRef?.rawValue ?? 0

    property string _logCountText:    !isNaN(_logCount)     ? _logCount.toFixed(0)     : "--"
    property string _temperatureText: !isNaN(_temperature)  ? _temperature.toFixed(2) + " ℃" : "--.- ℃"
    property string _humidityText:    !isNaN(_humidity)     ? _humidity.toFixed(2) + " Rh%" : "--.- Rh%"
    property string _pressureText:    !isNaN(_pressure)     ? _pressure.toFixed(2) + " hPa" : "----.- hPa"
    property string _windDirText:     !isNaN(_windDir)      ? _windDir.toFixed(0) + " °" : "--- °"
    property string _windSpdText:     !isNaN(_windSpd)      ? _windSpd.toFixed(1) + " ㎧" : "--.- ㎧"
    property string _pm1p0Text:       !isNaN(_pm1p0)        ? _pm1p0.toFixed(0)       : "-.-"
    property string _pm2p5Text:       !isNaN(_pm2p5)        ? _pm2p5.toFixed(0)       : "-.-"
    property string _pm10Text:        !isNaN(_pm10)         ? _pm10.toFixed(0)        : "-.-"
    property string _radiationText:   !isNaN(_radiation)    ? _radiation.toFixed(0)   : "-.-"
    property string _hubTemp1Text:    !isNaN(_hubTemp1)     ? _hubTemp1.toFixed(2) + " ℃" : "--.- ℃"
    property string _hubTemp2Text:    !isNaN(_hubTemp2)     ? _hubTemp2.toFixed(2) + " ℃" : "--.- ℃"
    property string _hubHumi1Text:    !isNaN(_hubHumi1)     ? _hubHumi1.toFixed(2) + " Rh%" : "--.- Rh%"
    property string _hubHumi2Text:    !isNaN(_hubHumi2)     ? _hubHumi2.toFixed(2) + " Rh%" : "--.- Rh%"
    property string _hubPressureText: !isNaN(_hubPressure)  ? _hubPressure.toFixed(2) + " hPa" : "----.- hPa"
    property string _battText:        !isNaN(_batt)         ? _batt.toFixed(0) + " %" : "--- %"
    property string _sdVolumeText:    _sdVolume > 0         ? _sdVolume.toFixed(2) + " GB" : "Error"
    property string _timeHMSText:     _timeHMS !== ""      ? _timeHMS : "--:--:--"
    property string _windRefText:     _windRef === 2 ? "T" : _windRef === 1 ? "R" : ""

    property bool   _logActive:       _activeVehicle ? _activeVehicle.customLogActive : false
    property bool   _logManualActive: _activeVehicle ? _activeVehicle.customLogManualActive : false

    function isWindVaneOK(){
        return _activeVehicle && !isNaN(_windDir)
    }

    RowLayout {
        id: columnLayout
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        // LEFT column: compass dial on top, recording status + start button below.
        ColumnLayout {
            Layout.alignment:   Qt.AlignTop
            spacing:            _toolsMargin

            Rectangle {
                id:         windvaneView
                height:     size
                width:      size
                color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.9)
                radius:     size / 2
                border.color: qgcPal.text
                Layout.alignment: Qt.AlignHCenter

                CompassDial {
                    id: compassDial
                    anchors.fill:   parent
                }

                Image {
                    id:                 windvaneExternal
                    source:             isWindVaneOK() ? "/qmlimages/windVaneArrow.svg" : ""
                    mipmap:             true
                    fillMode:           Image.PreserveAspectFit
                    anchors.fill:       parent
                    sourceSize.height:  parent.height

                    transform: Rotation {
                        origin.x:       windvaneExternal.width  / 2
                        origin.y:       windvaneExternal.height / 2
                        angle:          _windDir
                    }
                }

                Rectangle {
                    height: windvaneInnerColumn.height + _toolsMargin * 2
                    width: windvaneInnerColumn.width + _toolsMargin * 2
                    color: "transparent"
                    radius: ScreenTools.defaultFontPixelHeight / 4
                    border.color: Qt.rgba(qgcPal.text.r, qgcPal.text.g, qgcPal.text.b, 0.5)
                    anchors.centerIn: parent

                    ColumnLayout {
                        id: windvaneInnerColumn
                        anchors.centerIn: parent

                        QGCLabel {
                            Layout.alignment:       Qt.AlignHCenter
                            text:                   _windSpdText
                            horizontalAlignment:    Text.AlignHCenter
                            font.pointSize:         ScreenTools.defaultFontPointSize * 1.2
                        }
                        QGCLabel {
                            Layout.alignment:       Qt.AlignHCenter
                            text:                   _windDirText + (root._windRefText ? " (" + root._windRefText + ")" : "")
                            horizontalAlignment:    Text.AlignHCenter
                            font.pointSize:         ScreenTools.defaultFontPointSize * 1.2
                        }
                    }
                }
            }

            // Recording status + start/stop button (separated from the value grid).
            Rectangle {
                Layout.fillWidth:       true
                Layout.preferredHeight: recordingColumn.implicitHeight + _toolsMargin * 2
                color:                  qgcPal.windowTransparent
                radius:                 _toolsMargin

                ColumnLayout {
                    id:                 recordingColumn
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins:    _toolsMargin

                    RowLayout {
                        Layout.fillWidth:   true
                        spacing:            ScreenTools.defaultFontPixelWidth

                        Rectangle {
                            id:                     logStatusLed
                            Layout.preferredWidth:  ScreenTools.defaultFontPixelHeight * 0.7
                            Layout.preferredHeight: width
                            Layout.alignment:       Qt.AlignVCenter
                            radius:                 width / 2
                            color:                  _logActive ? "#22cc22" : "#888888"
                            border.color:           Qt.darker(color, 1.4)
                            border.width:           1
                            opacity:                1.0

                            Behavior on color { ColorAnimation { duration: 150 } }

                            SequentialAnimation {
                                running: _logActive
                                loops:   Animation.Infinite
                                NumberAnimation { target: logStatusLed; property: "opacity"; to: 0.35; duration: 700; easing.type: Easing.InOutSine }
                                NumberAnimation { target: logStatusLed; property: "opacity"; to: 1.0;  duration: 700; easing.type: Easing.InOutSine }
                                onStopped: logStatusLed.opacity = 1.0
                            }
                        }

                        QGCLabel {
                            text:               _logActive
                                                ? (_logManualActive ? qsTr("수동 기록 중") : qsTr("자동 기록 중"))
                                                : qsTr("기록 대기중")
                            Layout.alignment:   Qt.AlignVCenter
                            Layout.fillWidth:   true
                        }

                        QGCColoredImage {
                            Layout.preferredWidth:  ScreenTools.defaultFontPixelHeight * 0.7
                            Layout.preferredHeight: width
                            Layout.alignment:       Qt.AlignVCenter
                            source:                 "/InstrumentValueIcons/folder-outline.svg"
                            sourceSize.width:       width
                            sourceSize.height:      height
                            fillMode:               Image.PreserveAspectFit
                            color:                  folderIconMa.pressed ? qgcPal.colorBlue
                                                    : (folderIconMa.containsMouse ? qgcPal.colorBlue : qgcPal.text)

                            MouseArea {
                                id:             folderIconMa
                                anchors.fill:   parent
                                hoverEnabled:   true
                                cursorShape:    Qt.PointingHandCursor
                                onClicked:      logFolderDialog.open()
                            }

                            ToolTip.text:       qsTr("저장 폴더 보기")
                            ToolTip.visible:    folderIconMa.containsMouse
                            ToolTip.delay:      500
                        }
                    }

                    QGCButton {
                        Layout.fillWidth:   true
                        text:       _logManualActive ? qsTr("기록 정지") : qsTr("기록 시작")
                        enabled:    _activeVehicle !== null
                        onClicked:  if (_activeVehicle) _activeVehicle.customLogManualActive = !_logManualActive
                    }
                }
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignTop
            height:     valueGridLayout.height + _toolsMargin * 2
            width:      valueGridLayout.width + _toolsMargin * 2
            color:      qgcPal.windowTransparent
            radius:     _toolsMargin

            ColumnLayout {
                id: valueGridLayout
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter

                LabelledLabel {
                    label:      "SHT_Temp"
                    labelText: _temperatureText
                }
                LabelledLabel {
                    label:      "HUB_Temp1"
                    labelText: _hubTemp1Text
                }
                LabelledLabel {
                    label:      "HUB_Temp2"
                    labelText: _hubTemp2Text
                }
                LabelledLabel {
                    label:      "SHT_Humi"
                    labelText: _humidityText
                }
                LabelledLabel {
                    label:      "HUB_Humi1"
                    labelText: _hubHumi1Text
                }
                LabelledLabel {
                    label:      "HUB_Humi2"
                    labelText: _hubHumi2Text
                }
                LabelledLabel {
                    label:      "Pressure"
                    labelText: _pressureText
                }
                LabelledLabel {
                    label:      "HUB_Pres"
                    labelText: _hubPressureText
                }
                Rectangle {
                    height: 1
                    Layout.fillWidth: true
                    color: qgcPal.groupBorder
                }
                LabelledLabel {
                    label:      "HUB_Batt"
                    labelText: _battText
                }
                LabelledLabel {
                    label:      "SD_Volume"
                    labelText: _sdVolumeText
                }
                LabelledLabel {
                    label:      "Time"
                    labelText: _timeHMSText
                }
                LabelledLabel {
                    label:      "LogCount"
                    labelText: _logCountText
                }
            }
        }
    }

    Dialog {
        id:                 logFolderDialog
        title:              qsTr("로그 저장 폴더")
        modal:              true
        standardButtons:    Dialog.Close
        parent:             Overlay.overlay
        anchors.centerIn:   Overlay.overlay
        width:              Math.min(mainWindow.width * 0.8, ScreenTools.defaultFontPixelWidth * 80)

        property string savePath: QGroundControl.settingsManager.appSettings.logSavePath

        ColumnLayout {
            anchors.left:   parent.left
            anchors.right:  parent.right
            spacing:        ScreenTools.defaultFontPixelHeight / 2

            QGCLabel {
                text:               qsTr("센서 로그가 아래 폴더에 저장됩니다:")
                Layout.fillWidth:   true
                wrapMode:           Text.WordWrap
            }

            Rectangle {
                Layout.fillWidth:       true
                Layout.preferredHeight: pathText.implicitHeight + ScreenTools.defaultFontPixelHeight / 2
                color:                  qgcPal.windowShade
                border.color:           qgcPal.groupBorder
                radius:                 ScreenTools.defaultFontPixelHeight / 4

                QGCLabel {
                    id:                 pathText
                    text:               logFolderDialog.savePath
                    anchors.margins:    ScreenTools.defaultFontPixelWidth / 2
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    wrapMode:           Text.WrapAnywhere
                    font.family:        ScreenTools.fixedFontFamily
                }
            }

            RowLayout {
                Layout.fillWidth:   true
                spacing:            ScreenTools.defaultFontPixelWidth

                QGCButton {
                    text:               qsTr("폴더 열기")
                    Layout.fillWidth:   true
                    // Android/iOS: file:// URIs are blocked for external apps (Android 7+ FileUriExposedException, iOS sandbox)
                    visible:            !ScreenTools.isMobile
                    onClicked:          Qt.openUrlExternally("file:///" + logFolderDialog.savePath.replace(/\\/g, "/"))
                }
                QGCButton {
                    text:               qsTr("경로 복사")
                    Layout.fillWidth:   true
                    onClicked:          QGroundControl.copyToClipboard(logFolderDialog.savePath)
                }
            }
        }
    }
}
