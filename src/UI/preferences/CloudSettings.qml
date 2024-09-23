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
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.ScreenTools 


SettingsPage {
    property var    _settingsManager:   QGroundControl.settingsManager
    property var    cloudSettings:      _settingsManager.cloudSettings
    property real   _urlFieldWidth:     ScreenTools.defaultFontPixelWidth * 25

    property bool _signedIn: QGroundControl.cloudManager.signedIn
    property string _signedId: QGroundControl.cloudManager.signedId

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

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width:      parent.width
                    height:     1
                    color: qgcPal.groupBorder
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
                echoMode: TextField.PasswordEchoOnEdit

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width:      parent.width
                    height:     1
                    color: qgcPal.groupBorder
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
            labelText:          _signedId == "" ? qsTr("Connecting...") : _signedId
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

    // SettingsGroupLayout {
    //     Layout.fillWidth:   true
    //     heading:            qsTr("SignUp")

    //     LabelledButton {
    //         label:      qsTr("SignUp")
    //         buttonText: qsTr("SignUp")
    //         onClicked:  {
    //             console.log("Clicked SignUp");
    //             var email = emailField.fact.value.toString()
    //             var password = passwordField.fact.value.toString()
    //             console.log("email:"+email);
    //             console.log("password:"+password);
    //             QGroundControl.cloudManager.signUserUp(email, password)
    //         }
    //     }
    // }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Cloud API Keys")

        LabelledFactTextField {
            Layout.fillWidth:   true
            textFieldPreferredWidth:    _urlFieldWidth
            label:              qsTr("API Key")
            description:        qsTr("google firebase")
            fact:               cloudSettings.firebaseAPIKey
            visible:            cloudSettings.firebaseAPIKey.visible
        }
    }
}
