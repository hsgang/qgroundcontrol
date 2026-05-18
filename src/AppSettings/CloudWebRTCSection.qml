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

    LabelledFactTextField {
        Layout.fillWidth:   true
        textFieldPreferredWidth:    _urlFieldWidth * 1.4
        label:              qsTr("서버 주소")
        fact:               cloudSettings.webrtcSignalingServer
    }

    LabelledFactTextField {
        Layout.fillWidth:   true
        textFieldPreferredWidth:    _urlFieldWidth * 1.4
        label:              qsTr("API 키")
        fact:               cloudSettings.webrtcApiKey
    }

    LabelledFactTextField {
        Layout.fillWidth:   true
        textFieldPreferredWidth:    _urlFieldWidth * 1.4
        label:              qsTr("TURN 서버")
        fact:               cloudSettings.webrtcTurnServer
    }

    LabelledFactTextField {
        Layout.fillWidth:   true
        textFieldPreferredWidth:    _urlFieldWidth * 1.4
        label:              qsTr("TURN 사용자명")
        fact:               cloudSettings.webrtcTurnUsername
    }

    LabelledFactTextField {
        Layout.fillWidth:   true
        textFieldPreferredWidth:    _urlFieldWidth * 1.4
        label:              qsTr("TURN 비밀번호")
        fact:               cloudSettings.webrtcTurnPassword
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
