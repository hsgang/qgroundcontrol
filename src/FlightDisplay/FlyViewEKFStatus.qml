import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.MultiVehicleManager
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.Palette

Rectangle {
    id:         ekfStatus
    height:     ekfStatusItem.height + ScreenTools.defaultFontPixelHeight / 2
    width:      ekfStatusItem.width + ScreenTools.defaultFontPixelHeight / 2
    color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.3)
    radius:     _margins
    border.color: Qt.rgba(qgcPal.text.r, qgcPal.text.g, qgcPal.text.b, 0.5)

    property var    _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle
    property bool   _available:     !isNaN(_activeVehicle.vibration.xAxis.rawValue)
    property real   _margins:       ScreenTools.defaultFontPixelWidth / 2
    property real   _barWidth:      ScreenTools.defaultFontPixelWidth * 3
    property real   _barHeight:     ScreenTools.defaultFontPixelHeight * 4
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
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: ScreenTools.defaultFontPixelWidth / 2

        RowLayout {
            id:         barRow
            spacing:    ScreenTools.defaultFontPixelWidth * 2

            ColumnLayout {
                Layout.minimumWidth: ScreenTools.defaultFontPixelWidth * 7

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
                    font.pointSize: ScreenTools.defaultFontPointSize * 0.8
                }
            }

            ColumnLayout {
                Layout.minimumWidth: ScreenTools.defaultFontPixelWidth * 7

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
                    font.pointSize: ScreenTools.defaultFontPointSize * 0.8
                }
            }

            ColumnLayout {
                Layout.minimumWidth: ScreenTools.defaultFontPixelWidth * 7

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
                    font.pointSize: ScreenTools.defaultFontPointSize * 0.8
                }
            }

            ColumnLayout {
                Layout.minimumWidth: ScreenTools.defaultFontPixelWidth * 7

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
                    font.pointSize: ScreenTools.defaultFontPointSize * 0.8
                }
            }

            ColumnLayout {
                Layout.minimumWidth: ScreenTools.defaultFontPixelWidth * 7

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
                    font.pointSize: ScreenTools.defaultFontPointSize * 0.8
                }
            }
        }

        // Column {
        //     anchors.margins:    ScreenTools.defaultFontPixelWidth
        //     anchors.left:       barRow.right

        //     QGCLabel {
        //         text: qsTr("EKF Flags")
        //         font.pointSize: ScreenTools.defaultFontPointSize * 0.8
        //     }
        // }

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

