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
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.Palette

Rectangle {
    id:         control
    width:      ScreenTools.defaultFontPixelWidth * 35
    height:     ScreenTools.defaultFontPixelHeight * 6
    radius:     ScreenTools.defaultFontPixelHeight / 2
    color:      qgcPal.window
    visible:    false
    border.color: qgcPal.colorYellow
    border.width: 2

    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: false
    }

    property var    _activeVehicle:    QGroundControl.multiVehicleManager.activeVehicle
    property real   _margins:         ScreenTools.defaultFontPixelWidth / 2

    property int    receivedCustomCmd: 0
    property int    receivedTagId:  0

    QGCPalette { id: qgcPal }

    Connections {
        target: _activeVehicle
        onRequestConfirmationReceived: (customCmd, show, tagId) => {
            if (customCmd !== 1) {
                return
            }
            receivedTagId = tagId
            if(show > 0) {
                control.visible = true
            } else if (show === 0) {
                control.visible = false
            }
        }
    }

    ColumnLayout {
        id:     mainLayout
        anchors.margins: _margins
        anchors.fill:    parent

        QGCLabel {
            id:                 label
            Layout.alignment:   Qt.AlignHCenter
            text:               "확인 요청"
            font.bold:          true
        }

        QGCLabel {
            id:                 desc
            Layout.alignment:   Qt.AlignHCenter
            text:               qsTr("배송 태그 %1 인식").arg(receivedTagId)
        }

        RowLayout {
            Layout.alignment:   Qt.AlignHCenter

            QGCButton {
                id:             buttonAuto
                text:           "자동 시퀀스"
                onClicked: {
                    control.visible = false
                    _activeVehicle.sendCommand(192, 31010, 1, 1, 0, receivedTagId, 1, 0, 0, 0)
                    //(int compId, int command, bool showError, double param1, double param2, double param3, double param4, double param5, double param6, double param7)
                }
            }

            QGCButton {
                id:             buttonManual
                text:           "수동"
                onClicked: {
                    control.visible = false
                    _activeVehicle.setPositionTargetLocalNed(0,0,0,0,false)
                }
            }

            QGCButton {
                id:             buttonCancel
                text:           "취소"
                onClicked: {
                    control.visible = false
                }
            }
        }
    }
}

