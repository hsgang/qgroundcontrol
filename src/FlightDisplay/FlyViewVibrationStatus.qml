import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.FactControls

Rectangle {
    id:         vibrationStatus
    height:     vibrationItem.height + ScreenTools.defaultFontPixelHeight / 2
    width:      vibrationItem.width + ScreenTools.defaultFontPixelHeight / 2
    color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.3)
    radius:     _margins
    border.color: Qt.rgba(qgcPal.text.r, qgcPal.text.g, qgcPal.text.b, 0.5)

    property var    _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle
    property bool   _available:     !isNaN(_activeVehicle.vibration.xAxis.rawValue)
    property real   _margins:       ScreenTools.defaultFontPixelWidth / 2
    property real   _barWidth:      ScreenTools.defaultFontPixelWidth * 3
    property real   _barHeight:     ScreenTools.defaultFontPixelHeight * 4
    property real   _xValue:        _activeVehicle.vibration.xAxis.rawValue
    property real   _yValue:        _activeVehicle.vibration.yAxis.rawValue
    property real   _zValue:        _activeVehicle.vibration.zAxis.rawValue

    readonly property real _barMinimum:     0.0
    readonly property real _barMaximum:     90.0
    readonly property real _barBadValue:    60.0
    readonly property real _barMidValue:    30.0

    Item {
        id:     vibrationItem
        width:  childrenRect.width
        height: childrenRect.height
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: ScreenTools.defaultFontPixelWidth / 2

        RowLayout {
            id:         barRow
            spacing:    ScreenTools.defaultFontPixelWidth * 2

            ColumnLayout {
                Layout.minimumWidth: ScreenTools.defaultFontPixelWidth * 7

                Rectangle {
                    id:                 xBar
                    height:             _barHeight
                    width:              _barWidth
                    Layout.alignment:   Qt.AlignHCenter
                    color:              "transparent"
                    border.width:       1
                    border.color:       qgcPal.text

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         parent.height * (Math.min(_barMaximum, _xValue) / (_barMaximum - _barMinimum))
                        color:          qgcPal.colorWhite
                    }

                    // Max vibe indication line at 60
                    Rectangle {
                        anchors.topMargin:      parent.height * (1.0 - ((_barBadValue - _barMinimum) / (_barMaximum - _barMinimum)))
                        anchors.top:            parent.top
                        anchors.left:           parent.left
                        anchors.right:          parent.right
                        width:                  parent.width
                        height:                 1
                        color:                  "red"
                    }

                    // Mid vibe indication line at 30
                    Rectangle {
                        anchors.topMargin:      parent.height * (1.0 - ((_barMidValue - _barMinimum) / (_barMaximum - _barMinimum)))
                        anchors.top:            parent.top
                        anchors.left:           parent.left
                        anchors.right:          parent.right
                        width:                  parent.width
                        height:                 1
                        color:                  "red"
                    }
                }

                QGCLabel {
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("X \n(%1)").arg(_xValue.toFixed(0))
                    font.pointSize: ScreenTools.defaultFontPointSize * 0.8
                }
            }

            ColumnLayout {
                Layout.minimumWidth: ScreenTools.defaultFontPixelWidth * 7

                Rectangle {
                    height:             _barHeight
                    width:              _barWidth
                    Layout.alignment:   Qt.AlignHCenter
                    color:              "transparent"
                    border.width:       1
                    border.color:       qgcPal.text

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         parent.height * (Math.min(_barMaximum, _yValue) / (_barMaximum - _barMinimum))
                        color:          qgcPal.colorWhite
                    }

                    // Max vibe indication line at 60
                    Rectangle {
                        anchors.topMargin:      parent.height * (1.0 - ((_barBadValue - _barMinimum) / (_barMaximum - _barMinimum)))
                        anchors.top:            parent.top
                        anchors.left:           parent.left
                        anchors.right:          parent.right
                        width:                  parent.width
                        height:                 1
                        color:                  "red"
                    }

                    // Mid vibe indication line at 30
                    Rectangle {
                        anchors.topMargin:      parent.height * (1.0 - ((_barMidValue - _barMinimum) / (_barMaximum - _barMinimum)))
                        anchors.top:            parent.top
                        anchors.left:           parent.left
                        anchors.right:          parent.right
                        width:                  parent.width
                        height:                 1
                        color:                  "red"
                    }
                }

                QGCLabel {
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("Y \n(%1)").arg(_yValue.toFixed(0))
                    font.pointSize: ScreenTools.defaultFontPointSize * 0.8
                }
            }

            ColumnLayout {
                Layout.minimumWidth: ScreenTools.defaultFontPixelWidth * 7

                Rectangle {
                    height:             _barHeight
                    width:              _barWidth
                    Layout.alignment:   Qt.AlignHCenter
                    color:              "transparent"
                    border.width:       1
                    border.color:       qgcPal.text

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         parent.height * (Math.min(_barMaximum, _zValue) / (_barMaximum - _barMinimum))
                        color:          qgcPal.colorWhite
                    }

                    // Max vibe indication line at 60
                    Rectangle {
                        anchors.topMargin:      parent.height * (1.0 - ((_barBadValue - _barMinimum) / (_barMaximum - _barMinimum)))
                        anchors.top:            parent.top
                        anchors.left:           parent.left
                        anchors.right:          parent.right
                        width:                  parent.width
                        height:                 1
                        color:                  "red"
                    }

                    // Mid vibe indication line at 30
                    Rectangle {
                        anchors.topMargin:      parent.height * (1.0 - ((_barMidValue - _barMinimum) / (_barMaximum - _barMinimum)))
                        anchors.top:            parent.top
                        anchors.left:           parent.left
                        anchors.right:          parent.right
                        width:                  parent.width
                        height:                 1
                        color:                  "red"
                    }
                }

                QGCLabel {
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("Z \n(%1)").arg(_zValue.toFixed(0))
                    font.pointSize: ScreenTools.defaultFontPointSize * 0.8
                }
            }
        }

        Column {
            anchors.margins:    ScreenTools.defaultFontPixelWidth
            anchors.left:       barRow.right

            QGCLabel {
                text: qsTr("Clip count")
                font.pointSize: ScreenTools.defaultFontPointSize * 0.8
            }

            QGCLabel {
                text: qsTr("Accel 1: %1").arg(_activeVehicle.vibration.clipCount1.rawValue)
                font.pointSize: ScreenTools.defaultFontPointSize * 0.8
            }

            QGCLabel {
                text: qsTr("Accel 2: %1").arg(_activeVehicle.vibration.clipCount2.rawValue)
                font.pointSize: ScreenTools.defaultFontPointSize * 0.8
            }

            QGCLabel {
                text: qsTr("Accel 3: %1").arg(_activeVehicle.vibration.clipCount3.rawValue)
                font.pointSize: ScreenTools.defaultFontPointSize * 0.8
            }
        }

        Rectangle {
            anchors.fill:   parent
            color:          qgcPal.window
            opacity:        0.75
            visible:        !_available

            QGCLabel {
                anchors.fill:           parent
                horizontalAlignment:    Text.AlignHCenter
                verticalAlignment:      Text.AlignVCenter
                text:                   qsTr("Not Available")
            }
        }
    }
}

