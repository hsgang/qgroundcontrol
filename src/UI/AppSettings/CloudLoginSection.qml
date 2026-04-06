import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

SettingsGroupLayout {
    heading: qsTr("Cloud Login")

    property real   _urlFieldWidth:     ScreenTools.defaultFontPixelWidth * 25
    property bool   _signedIn:          QGroundControl.cloudManager.signedIn
    property string _signedUserName:    QGroundControl.cloudManager.signedUserName

    ColumnLayout {
        Layout.fillWidth:   true
        visible:            !_signedIn
        spacing:            ScreenTools.defaultFontPixelHeight * 0.5

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

        QGCButton {
            id: loginButton
            text: qsTr("Login")
            Layout.fillWidth:   true
            onClicked: {
                var email = emailField.text
                var password = passwordField.text
                QGroundControl.cloudManager.signUserIn(email, password)
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth:   true
        visible:            _signedIn
        spacing:            ScreenTools.defaultFontPixelHeight * 0.5

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("User")
            labelText:          _signedUserName == "" ? qsTr("Connecting...") : _signedUserName
        }

        QGCButton {
            text: qsTr("Logout")
            Layout.fillWidth:   true
            onClicked: {
                QGroundControl.cloudManager.signUserOut()
            }
        }
    }
}
