import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls


SettingsPage {
    property real   _urlFieldWidth:     ScreenTools.defaultFontPixelWidth * 25

    property var    _settingsManager:   QGroundControl.settingsManager
    property var    cloudSettings:      _settingsManager.cloudSettings

    property bool   _signedIn:          QGroundControl.cloudManager.signedIn
    property string _signedUserName:    QGroundControl.cloudManager.signedUserName
    


    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Cloud Login")
        visible: !_signedIn

        RowLayout {
            Layout.fillWidth:   true

            QGCLabel {
                Layout.fillWidth:   true
                text: qsTr("Email")
            }
            TextInput {
                id: emailField
                Layout.preferredWidth: _urlFieldWidth
                font.pointSize: ScreenTools.defaultFontPointSize
                font.family:    ScreenTools.normalFontFamily
                color:          qgcPal.text
                antialiasing:   true
                text:           QGroundControl.cloudManager.emailAddress

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width:          parent.width
                    height:         1
                    color:          qgcPal.groupBorder
                }

                KeyNavigation.tab: passwordField
            }
        }

        RowLayout {
            Layout.fillWidth:   true

            QGCLabel {
                Layout.fillWidth:   true
                text: qsTr("Password")
            }
            TextInput {
                id: passwordField
                Layout.preferredWidth: _urlFieldWidth
                font.pointSize: ScreenTools.defaultFontPointSize
                font.family:    ScreenTools.normalFontFamily
                color:          qgcPal.text
                antialiasing:   true
                echoMode:       TextField.PasswordEchoOnEdit
                text:           QGroundControl.cloudManager.password

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width:      parent.width
                    height:     1
                    color:      qgcPal.groupBorder
                }

                KeyNavigation.tab: loginButton
            }
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Cloud Login")
        visible: _signedIn

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("User")
            labelText:          _signedUserName == "" ? qsTr("Connecting...") : _signedUserName
        }
    }

    RowLayout {
        Layout.fillWidth:   true
        Layout.alignment: Qt.AlignHCenter

        QGCButton {
            id: loginButton
            text: qsTr("Login")
            visible: !_signedIn
            Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 25
            onClicked:  {
                var email = emailField.text
                var password = passwordField.text
                QGroundControl.cloudManager.signUserIn(email, password)
            }
        }

        QGCButton {
            text: qsTr("Logout")
            visible: _signedIn
            Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 25

            onClicked: {
                QGroundControl.cloudManager.signUserOut()
            }
        }
    }

    // WebRTC 설정 섹션
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("RTC 설정")

        LabelledFactTextField {
            Layout.fillWidth:   true
            textFieldPreferredWidth:    _urlFieldWidth * 1.4
            label:              qsTr("서버 주소")
            description:        qsTr("example - example.host.com")
            fact:               cloudSettings.webrtcSignalingServer
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            textFieldPreferredWidth:    _urlFieldWidth * 1.4
            label:              qsTr("TURN 사용자명")
            description:        qsTr("TURN 서버 인증 사용자명")
            fact:               cloudSettings.webrtcTurnUsername
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            textFieldPreferredWidth:    _urlFieldWidth * 1.4
            label:              qsTr("TURN 비밀번호")
            description:        qsTr("TURN 서버 인증 비밀번호")
            fact:               cloudSettings.webrtcTurnPassword
        }
    }
}
