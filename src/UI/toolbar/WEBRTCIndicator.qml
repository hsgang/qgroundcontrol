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

    property real _margins:         ScreenTools.defaultFontPixelHeight / 2

    // WebRTC Link를 찾아서 참조 (rtcStatusMessage 속성 존재 여부로 확인)
    function findWebRtcLink() {
        var linksList = QGroundControl.linkManager.links
        if (!linksList) {
            return null
        }

        for (var i = 0; i < linksList.count; i++) {
            var link = linksList.get(i)
            // WebRTCLink는 rtcStatusMessage 프로퍼티를 가지고 있음
            if (link && typeof link.rtcStatusMessage !== 'undefined') {
                return link
            }
        }
        return null
    }

    property var _webrtcLink: null
    property bool showIndicator: _webrtcLink !== null

    // 초기화 시 한번만 WebRTC Link 찾기
    Component.onCompleted: {
        _webrtcLink = findWebRtcLink()
    }

    // links 목록이 변경될 때마다 WebRTC Link를 다시 찾음
    Connections {
        target: QGroundControl.linkManager
        function onLinksChanged() {
            _webrtcLink = findWebRtcLink()
        }
    }

    // WebRTC 통계 정보 (WebRTCLink에서 직접 접근)
    property real _rtt:             _webrtcLink ? _webrtcLink.webRtcRtt : 0
    property string _iceCandidate:  _webrtcLink ? _webrtcLink.iceCandidate : ""

    // 송수신 속도
    property real _webRtcSent:      _webrtcLink ? _webrtcLink.webRtcSent : 0
    property real _webRtcRecv:      _webrtcLink ? _webrtcLink.webRtcRecv : 0

    // 비디오 수신 통계
    property real _videoRate:       _webrtcLink ? _webrtcLink.rtcVideoRate : 0
    property real  _videoRateMbps:   (_videoRate * 8.192 / 1000.0).toFixed(2)  // KB/s -> Mbps (정확한 변환: KB * 8.192 bits/KB / 1000)
    property int  _videoPacketCount: _webrtcLink ? _webrtcLink.rtcVideoPacketCount : 0
    property int  _videoBytesReceived: _webrtcLink ? _webrtcLink.rtcVideoBytesReceived : 0

    // RTC Module 시스템 정보
    property real _rtcModuleCpuUsage:        _webrtcLink ? _webrtcLink.rtcModuleCpuUsage : 0
    property real _rtcModuleCpuTemperature:  _webrtcLink ? _webrtcLink.rtcModuleCpuTemperature : 0
    property real _rtcModuleMemoryUsage:     _webrtcLink ? _webrtcLink.rtcModuleMemoryUsage : 0
    property real _rtcModuleNetworkRx:       _webrtcLink ? _webrtcLink.rtcModuleNetworkRx : 0
    property real _rtcModuleNetworkTx:       _webrtcLink ? _webrtcLink.rtcModuleNetworkTx : 0
    property string _rtcModuleNetworkInterface: _webrtcLink ? _webrtcLink.rtcModuleNetworkInterface : ""

    // RTC Module 버전 정보
    property string _rtcModuleCurrentVersion: _webrtcLink ? _webrtcLink.rtcModuleCurrentVersion : ""
    property string _rtcModuleLatestVersion:  _webrtcLink ? _webrtcLink.rtcModuleLatestVersion : ""
    property bool _rtcModuleUpdateAvailable:  _webrtcLink ? _webrtcLink.rtcModuleUpdateAvailable : false

    // Video Metrics 정보
    property real _videoRtspPacketsPerSec:    _webrtcLink ? _webrtcLink.videoRtspPacketsPerSec : 0
    property real _videoDecodedFramesPerSec:  _webrtcLink ? _webrtcLink.videoDecodedFramesPerSec : 0
    property real _videoEncodedFramesPerSec:  _webrtcLink ? _webrtcLink.videoEncodedFramesPerSec : 0
    property real _videoTeeFramesPerSec:      _webrtcLink ? _webrtcLink.videoTeeFramesPerSec : 0
    property real _videoSrtFramesPerSec:      _webrtcLink ? _webrtcLink.videoSrtFramesPerSec : 0
    property real _videoRtpFramesPerSec:      _webrtcLink ? _webrtcLink.videoRtpFramesPerSec : 0

    Row {
        id: vehicleRow
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: ScreenTools.defaultFontPixelHeight / 5

        QGCLabel {
            horizontalAlignment: Text.AlignRight
            text: (_webrtcLink && _webrtcLink.webRtcRtt < 0) ? _webrtcLink.rtcStatusMessage : ""
            anchors.verticalCenter: parent.verticalCenter
            visible: text !== ""
        }

        QGCColoredImage {
            id:                 roiIcon
            width:              height
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            anchors.margins:    ScreenTools.defaultFontPixelHeight / 4
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
                text:           qsTr("%1 ms").arg(_rtt)
            }

            QGCLabel {
                anchors.left:   parent.left
                color:          qgcPal.buttonText
                font.pointSize: ScreenTools.smallFontPointSize
                text:           qsTr("%1 Mbps").arg(_videoRateMbps)
                width:          ScreenTools.smallFontPixelWidth * 10
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
                RowLayout {
                    spacing: _margins

                    SettingsGroupLayout {
                        heading: qsTr("RTC 상태 정보")
                        Layout.alignment: Qt.AlignTop

                        LabelledLabel {
                            label:      qsTr("응답지연")
                            labelText:  qsTr("%1 ms").arg(_rtt)
                        }
                        LabelledLabel {
                            label:      qsTr("데이터 송신")
                            labelText:  qsTr("%1 KB/s").arg(_webRtcSent.toFixed(2))
                        }
                        LabelledLabel {
                            label:      qsTr("데이터 수신")
                            labelText:  qsTr("%1 KB/s").arg(_webRtcRecv.toFixed(2))
                        }
                        LabelledLabel {
                            label:      qsTr("영상 수신")
                            labelText:  qsTr("%1 Mbps").arg(_videoRateMbps)
                        }
                        LabelledLabel {
                            label:      qsTr("ICE")
                            labelText:  _iceCandidate !== "" ? _iceCandidate : qsTr("N/A")
                            labelPreferredWidth: ScreenTools.defaultFontPixelWidth * 26
                            labelTextElide: Text.ElideMiddle
                            visible:    _iceCandidate !== ""
                        }
                    }

                    // RTC Module 시스템 정보 섹션
                    ColumnLayout {
                        spacing: _margins
                        Layout.alignment: Qt.AlignTop
                    
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
                            // LabelledLabel {
                            //     label:      qsTr("메모리 사용률")
                            //     labelText:  qsTr("%1%").arg(_rtcModuleMemoryUsage.toFixed(1))
                            // }
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

                        // Video Metrics 정보 섹션
                        SettingsGroupLayout {
                            heading: qsTr("비디오 메트릭 정보")

                            LabelledLabel {
                                label:      qsTr("RTSP 소스 패킷")
                                labelText:  qsTr("%1 pkt/s").arg(_videoRtspPacketsPerSec.toFixed(1))
                            }
                            // LabelledLabel {
                            //     label:      qsTr("디코딩 프레임")
                            //     labelText:  qsTr("%1 fps").arg(_videoDecodedFramesPerSec.toFixed(1))
                            // }
                            LabelledLabel {
                                label:      qsTr("인코딩 프레임")
                                labelText:  qsTr("%1 fps").arg(_videoEncodedFramesPerSec.toFixed(1))
                            }
                            // LabelledLabel {
                            //     label:      qsTr("SRT 프레임")
                            //     labelText:  qsTr("%1 fps").arg(_videoSrtFramesPerSec.toFixed(1))
                            // }
                            LabelledLabel {
                                label:      qsTr("RTP 프레임")
                                labelText:  qsTr("%1 fps").arg(_videoRtpFramesPerSec.toFixed(1))
                            }
                        }

                        // // RTC 모듈 버전 정보 섹션
                        // SettingsGroupLayout {
                        //     heading: qsTr("RTC 모듈 버전 정보")

                        //     LabelledLabel {
                        //         label:      qsTr("업데이트 상태")
                        //         labelText:  _rtcModuleUpdateAvailable ?
                        //                    qsTr("업데이트 가능 (%1)").arg(_rtcModuleCurrentVersion || qsTr("알 수 없음")) :
                        //                    qsTr("최신 버전 (%1)").arg(_rtcModuleCurrentVersion || qsTr("알 수 없음"))
                        //     }
                        // }

                        // SettingsGroupLayout {
                        //     heading: qsTr("RTC 모듈 제어")

                        //     LabelledButton {
                        //         label:      qsTr("모듈 재시작")
                        //         buttonText: qsTr("재시작")
                        //         enabled:    true
                        //         onClicked:  restartConfirmDialogComponent.createObject(mainWindow).open()
                        //     }
                        //     LabelledButton {
                        //         label:      qsTr("모듈 업데이트 확인")
                        //         buttonText: qsTr("확인")
                        //         onClicked:  if (_webrtcLink) _webrtcLink.sendCustomMessage("C")
                        //     }
                            
                        //     // 업데이트 가능한 경우에만 업데이트 버튼 표시
                        //     LabelledButton {
                        //         label:      qsTr("모듈 업데이트")
                        //         buttonText: qsTr("업데이트")
                        //         visible:    _rtcModuleUpdateAvailable
                        //         onClicked:  rtcUpdateConfirmDialogComponent.createObject(mainWindow).open()
                        //     }
                            
                        //     // 최신 버전인 경우 상태 텍스트 표시
                        //     LabelledLabel {
                        //         label:      qsTr("업데이트 상태")
                        //         labelText:  qsTr("최신 버전 (%1)").arg(_rtcModuleCurrentVersion || qsTr("알 수 없음"))
                        //         visible:    !_rtcModuleUpdateAvailable && _rtcModuleCurrentVersion !== ""
                        //     }
                        // }
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
                if (_webrtcLink) _webrtcLink.sendCustomMessage("B")
            }
        }
    }

    Component {
        id: rtcUpdateConfirmDialogComponent

        QGCSimpleMessageDialog {
            title: qsTr("모듈 업데이트 확인")
            text: qsTr("RTC 모듈을 업데이트 하시겠습니까?")
            buttons: Dialog.Yes | Dialog.No
            onAccepted: {
                if (_webrtcLink) _webrtcLink.sendCustomMessage("U")
            }
        }
    }
}
