/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.FactControls

//-------------------------------------------------------------------------
Item {
    id:             control
    width:          vehicleRow.width
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator:    QGroundControl.linkManager.webRtcRtt > 0
    property real _margins:         ScreenTools.defaultFontPixelHeight / 2
    property real _rtt:             QGroundControl.linkManager.webRtcRtt
    property real _webRtcSent:      QGroundControl.linkManager.webRtcSent
    property real _webRtcRecv:      QGroundControl.linkManager.webRtcRecv
    property real _videoRate:       QGroundControl.linkManager.rtcVideoRate
    property int  _videoRateInt:    Math.round(_videoRate)

    Row {
        id: vehicleRow
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: ScreenTools.defaultFontPixelHeight / 5

        QGCColoredImage {
            id:                 roiIcon
            width:              height
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            source:             "/InstrumentValueIcons/network-transmit-receive.svg"
            color:              qgcPal.text
            fillMode:           Image.PreserveAspectFit
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            QGCLabel {
                anchors.left:   parent.left
                color:          qgcPal.buttonText
                font.pointSize: ScreenTools.smallFontPointSize
                text: qsTr("%1 ms").arg(_rtt)
            }

            QGCLabel {
                anchors.left:   parent.left
                color:          qgcPal.buttonText
                font.pointSize: ScreenTools.smallFontPointSize
                text: qsTr("%1 KB/s").arg(_videoRateInt)
            }
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorDrawer(webrtcIndicatorPage, control)
    }

    Component {
        id: webrtcIndicatorPage

        ToolIndicatorPage {
            showExpand: false

            contentComponent: SettingsGroupLayout {
                heading: qsTr("RTC 상태 정보")

                LabelledLabel {
                    label:      qsTr("응답시간")
                    labelText:  qsTr("%1 ms").arg(_rtt)
                }
                LabelledLabel {
                    label:      qsTr("데이터 송신")
                    labelText:  qsTr("%1 KB/s").arg(_webRtcSent)
                }
                LabelledLabel {
                    label:      qsTr("데이터 수신")
                    labelText:  qsTr("%1 KB/s").arg(_webRtcRecv)
                }
                LabelledLabel {
                    label:      qsTr("영상 다운로드")
                    labelText:  qsTr("%1 KB/s").arg(_videoRateInt)
                }
                // LabelledButton {
                //     label:      qsTr("영상 재시작")
                //     buttonText: qsTr("재시작")
                //     enabled:    true
                //     onClicked:  QGroundControl.linkManager.sendWebRTCCustomMessage("R")
                // }
                LabelledButton {
                    label:      qsTr("모듈 재시작")
                    buttonText: qsTr("재시작")
                    enabled:    true
                    onClicked:  QGroundControl.linkManager.sendWebRTCCustomMessage("B")
                }
            }
        }
    }
}
