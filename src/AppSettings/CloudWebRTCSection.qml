import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

SettingsGroupLayout {
    heading: qsTr("RTC 설정")

    property real _urlFieldWidth: ScreenTools.defaultFontPixelWidth * 25
    property var  cloudSettings:  QGroundControl.settingsManager.cloudSettings

    RowLayout {
        Layout.fillWidth:   true
        spacing:            ScreenTools.defaultFontPixelWidth

        QGCLabel {
            text:               qsTr("연결 상태:")
            Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 12
        }

        Rectangle {
            width:  ScreenTools.defaultFontPixelHeight * 0.6
            height: width
            radius: width / 2
            color:  QGroundControl.signalingServerManager.isConnected ? qgcPal.colorGreen : qgcPal.colorRed
        }

        QGCLabel {
            text:               QGroundControl.signalingServerManager.connectionStatus
            Layout.fillWidth:   true
            elide:              Text.ElideRight
        }
    }

    // 서버 주소(호스트) 하나만 입력받는다. 시그널링 WS, auth-issuer(https://{host}/auth-api),
    // TURN 자격 발급이 모두 이 호스트에서 파생된다.
    // 빌드에 서버 주소가 주입된 배포본에서는 입력란을 숨긴다.
    LabelledFactTextField {
        Layout.fillWidth:   true
        textFieldPreferredWidth:    _urlFieldWidth * 1.4
        label:              qsTr("서버 주소")
        fact:               cloudSettings.webrtcSignalingServer
        visible:            !cloudSettings.webrtcSignalingServerFromBuild
    }

    // 정적 TURN 서버/사용자명/비밀번호 및 Auth Issuer URL은 서버 호스트에서 파생/발급되므로 UI에서 제거.
    // Auth Client ID는 비워도 기본값 operator-ui로 발급되므로 UI 입력란은 제거.
    // (다른 client(mission-scheduler 등)가 필요하면 설정파일의 webrtcAuthClientId로 override)

    // 빌드에 auth secret이 주입된 배포본에서는 입력란을 숨겨 오퍼레이터에게 노출하지 않는다.
    LabelledFactTextField {
        Layout.fillWidth:   true
        textFieldPreferredWidth:    _urlFieldWidth * 1.4
        label:              qsTr("Auth Client Secret")
        fact:               cloudSettings.webrtcAuthClientSecret
        visible:            !cloudSettings.webrtcAuthClientSecretFromBuild
    }

    LabelledFactTextField {
        Layout.fillWidth:   true
        textFieldPreferredWidth:    _urlFieldWidth * 1.4
        label:              qsTr("ICE Bind Address")
        fact:               cloudSettings.webrtcBindAddress
    }

    RowLayout {
        Layout.fillWidth:   true
        Layout.topMargin:   ScreenTools.defaultFontPixelHeight

        QGCButton {
            text:               qsTr("설정 적용")
            Layout.fillWidth:   true
            onClicked: {
                QGroundControl.signalingServerManager.applyNewSettings()
            }
        }
    }
}
