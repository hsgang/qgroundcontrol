import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts  1.2
import QtQuick.Dialogs  1.2

import QGroundControl                   1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.MultiVehicleManager 1.0
import QGroundControl.Controls          1.0
import QGroundControl.FactControls      1.0
import QGroundControl.Palette           1.0

Rectangle {
    id:         ekfStatus
    height:     ekfStatusItem.height// + ScreenTools.defaultFontPixelHeight * 0.5
    width:      ekfStatusItem.width// + ScreenTools.defaultFontPixelWidth * 3
    color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5)
    radius:     _margins
    border.color: qgcPal.text

    property var    _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle
    property bool   _available:     !isNaN(_activeVehicle.vibration.xAxis.rawValue)
    property real   _margins:       ScreenTools.defaultFontPixelWidth / 2
    property real   _barWidth:      ScreenTools.defaultFontPixelWidth * 7
    property real   _barHeight:     ScreenTools.defaultFontPixelHeight * 10
    property real   _velocity_variance:     _activeVehicle.ekfStatus.velocity_variance.rawValue
    property real   _pos_horiz_variance:    _activeVehicle.ekfStatus.pos_horiz_variance.rawValue
    property real   _pos_vert_variance:     _activeVehicle.ekfStatus.pos_vert_variance.rawValue
    property real   _compass_variance:      _activeVehicle.ekfStatus.compass_variance.rawValue
    property real   _terrain_alt_variance:  _activeVehicle.ekfStatus.terrain_alt_variance.rawValue

    readonly property real _barMinimum:     0.0
    readonly property real _barMaximum:     1.0
    readonly property real _barBadValue:    0.8
    readonly property real _barMidValue:    0.5

    Item {
        id:     ekfStatusItem
        width:  childrenRect.width
        height: childrenRect.height
        anchors.margins: ScreenTools.defaultFontPixelWidth / 2

        RowLayout {
            id:         barRow
            spacing:    ScreenTools.defaultFontPixelWidth * 2

            ColumnLayout {
                Rectangle {
                    id:                 veloVariance
                    height:             _barHeight
                    width:              _barWidth
                    Layout.alignment:   Qt.AlignHCenter
                    color:              "transparent"
                    border.width:       1
                    border.color:       qgcPal.text

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         parent.height * (Math.min(_barMaximum, _velocity_variance) / (_barMaximum - _barMinimum))
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
                    text:               qsTr("Velocity\n (%1)").arg(_velocity_variance.toFixed(2))
                }
            }

            ColumnLayout {
                Rectangle {
                    id:                 posHVariance
                    height:             _barHeight
                    width:              _barWidth
                    Layout.alignment:   Qt.AlignHCenter
                    color:              "transparent"
                    border.width:       1
                    border.color:       qgcPal.text

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         parent.height * (Math.min(_barMaximum, _pos_horiz_variance) / (_barMaximum - _barMinimum))
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
                    text:               qsTr("Pos_H\n (%1)").arg(_pos_horiz_variance.toFixed(2))
                }
            }

            ColumnLayout {
                Rectangle {
                    id:                 posVVariance
                    height:             _barHeight
                    width:              _barWidth
                    Layout.alignment:   Qt.AlignHCenter
                    color:              "transparent"
                    border.width:       1
                    border.color:       qgcPal.text

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         parent.height * (Math.min(_barMaximum, _pos_vert_variance) / (_barMaximum - _barMinimum))
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
                    text:               qsTr("Pos_V\n (%1)").arg(_pos_vert_variance.toFixed(2))
                }
            }

            ColumnLayout {
                Rectangle {
                    id:                 compassVariance
                    height:             _barHeight
                    width:              _barWidth
                    Layout.alignment:   Qt.AlignHCenter
                    color:              "transparent"
                    border.width:       1
                    border.color:       qgcPal.text

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         parent.height * (Math.min(_barMaximum, _compass_variance) / (_barMaximum - _barMinimum))
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
                    text:               qsTr("Compass\n (%1)").arg(_compass_variance.toFixed(2))
                }
            }

            ColumnLayout {
                Rectangle {
                    id:                 terrainVariance
                    height:             _barHeight
                    width:              _barWidth
                    Layout.alignment:   Qt.AlignHCenter
                    color:              "transparent"
                    border.width:       1
                    border.color:       qgcPal.text

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         parent.height * (Math.min(_barMaximum, _terrain_alt_variance) / (_barMaximum - _barMinimum))
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
                    text:               qsTr("Terrain\n (%1)").arg(_terrain_alt_variance.toFixed(2))
                }
            }
        }

        Column {
            anchors.margins:    ScreenTools.defaultFontPixelWidth
            anchors.left:       barRow.right

            QGCLabel {
                text: qsTr("EKF Flags")
            }

//            QGCLabel {
//                text: qsTr("Accel 1: %1").arg(_activeVehicle.vibration.clipCount1.rawValue)
//            }

//            QGCLabel {
//                text: qsTr("Accel 2: %1").arg(_activeVehicle.vibration.clipCount2.rawValue)
//            }

//            QGCLabel {
//                text: qsTr("Accel 3: %1").arg(_activeVehicle.vibration.clipCount3.rawValue)
//            }
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

