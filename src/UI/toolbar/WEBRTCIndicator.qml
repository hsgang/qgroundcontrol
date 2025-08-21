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
    
    // RTC Module 시스템 정보
    property real _rtcModuleCpuUsage:        QGroundControl.linkManager.rtcModuleCpuUsage
    property real _rtcModuleCpuTemperature:  QGroundControl.linkManager.rtcModuleCpuTemperature
    property real _rtcModuleMemoryUsage:     QGroundControl.linkManager.rtcModuleMemoryUsage
    property real _rtcModuleNetworkRx:       QGroundControl.linkManager.rtcModuleNetworkRx
    property real _rtcModuleNetworkTx:       QGroundControl.linkManager.rtcModuleNetworkTx
    property string _rtcModuleNetworkInterface: QGroundControl.linkManager.rtcModuleNetworkInterface

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

            contentComponent: Component {
                ColumnLayout {
                    spacing: _margins

                    SettingsGroupLayout {
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
                    }

                    // RTC Module 시스템 정보 섹션
                    SettingsGroupLayout {
                        heading: qsTr("RTC 모듈 시스템 정보")

                        LabelledLabel {
                            label:      qsTr("CPU 사용률")
                            labelText:  qsTr("%1%").arg(_rtcModuleCpuUsage.toFixed(1))
                        }
                        LabelledLabel {
                            label:      qsTr("CPU 온도")
                            labelText:  qsTr("%1°C").arg(_rtcModuleCpuTemperature.toFixed(1))
                        }
                        LabelledLabel {
                            label:      qsTr("메모리 사용률")
                            labelText:  qsTr("%1%").arg(_rtcModuleMemoryUsage.toFixed(1))
                        }
                        LabelledLabel {
                            label:      qsTr("네트워크 수신")
                            labelText:  qsTr("%1 Mbps").arg(_rtcModuleNetworkRx.toFixed(2))
                        }
                        LabelledLabel {
                            label:      qsTr("네트워크 송신")
                            labelText:  qsTr("%1 Mbps").arg(_rtcModuleNetworkTx.toFixed(2))
                        }
                        LabelledLabel {
                            label:      qsTr("인터페이스")
                            labelText:  _rtcModuleNetworkInterface
                        }
                    }

                    SettingsGroupLayout {
                        heading: qsTr("RTC 모듈 제어")

                        LabelledButton {
                            label:      qsTr("모듈 재시작")
                            buttonText: qsTr("재시작")
                            enabled:    true
                            onClicked:  restartConfirmDialogComponent.createObject(mainWindow).open()
                        }
                    }
                }
            }
        }
    }

    Component {
        id: restartConfirmDialogComponent

        QGCSimpleMessageDialog {
            title: qsTr("모듈 재시작 확인")
            text: qsTr("RTC 모듈을 재시작하시겠습니까?\n\n재시작 후에는 수동으로 다시 연결하여야 합니다.")
            buttons: Dialog.Yes | Dialog.No
            onAccepted: {
                QGroundControl.linkManager.sendWebRTCCustomMessage("B")
            }
        }
    }
}
