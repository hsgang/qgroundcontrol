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
import QGroundControl.ScreenTools
import QGroundControl.SettingsManager
import QGroundControl.Controls

FirstRunPrompt {
    title:      qsTr("Link Management")
    promptId:   QGroundControl.corePlugin.connectFirstRunPromptId
    markAsShownOnClose: false

    property var    _currentSelection:     null

    property var    _settingsManager:   QGroundControl.settingsManager
    property var    cloudSettings:      _settingsManager.cloudSettings
    property real   _urlFieldWidth:     ScreenTools.defaultFontPixelWidth * 25

    property bool   _signedIn: QGroundControl.cloudManager.signedIn
    property string _signedId: QGroundControl.cloudManager.signedId

    RowLayout {
        spacing: ScreenTools.defaultFontPixelHeight

        ColumnLayout {
            id:         columnLayout
            spacing:    ScreenTools.defaultFontPixelHeight

            QGCLabel {
                id:         unitsSectionLabel
                text:       qsTr("Choose the link you want to connect.")

                Layout.preferredWidth: flickableRect.width
                wrapMode: Text.WordWrap
            }

            Rectangle {
                id: flickableRect
                color:              qgcPal.windowShadeDark
                width:              ScreenTools.defaultFontPixelWidth * 40
                height:             ScreenTools.defaultFontPixelHeight * 10
                radius:             ScreenTools.defaultFontPixelHeight / 2

                QGCFlickable {
                    clip:               true
                    anchors.top:        parent.top
                    anchors.bottom:     parent.bottom
                    anchors.margins:    ScreenTools.defaultFontPixelHeight / 4
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    contentHeight:      settingsColumn.height
                    flickableDirection: Flickable.VerticalFlick

                    Column {
                        id:                 settingsColumn
                        width:              flickableRect.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing:            ScreenTools.defaultFontPixelHeight / 2
                        Repeater {
                            model: QGroundControl.linkManager.linkConfigurations
                            delegate: QGCButton {
                                anchors.horizontalCenter:   settingsColumn.horizontalCenter
                                width:                      ScreenTools.defaultFontPixelWidth * 36
                                text:                       object.name + (object.link ? " (" + qsTr("Connected") + ")" : "")
                                autoExclusive:              true
                                visible:                    !object.dynamic
                                onClicked: {
                                    checked = true
                                    _currentSelection = object
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                spacing:            ScreenTools.defaultFontPixelWidth
                Layout.fillWidth:   true
                Layout.alignment:   Qt.AlignCenter

                QGCButton {
                    text:       qsTr("Connect")
                    font.bold: true
                    enabled:    _currentSelection && !_currentSelection.link
                    onClicked:  {
                        QGroundControl.linkManager.createConnectedLink(_currentSelection)
                        close()
                    }
                    implicitWidth: ScreenTools.defaultFontPixelWidth * 12
                }
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignCenter
            width: 1
            height: columnLayout.height
            color: qgcPal.groupBorder
        }

        ColumnLayout {
            id:         columnLayout2
            spacing:    ScreenTools.defaultFontPixelHeight
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 40

            QGCLabel {
                text:       qsTr("Cloud Login")
                wrapMode:   Text.WordWrap
            }

            LabelledLabel {
                visible:            _signedIn
                Layout.fillWidth:   true
                label:              qsTr("User")
                labelText:          _signedId == "" ? qsTr("Connecting...") : _signedId
            }

            RowLayout {
                Layout.fillWidth:   true
                visible: !_signedIn

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

                    property string placeholderText: qsTr("Input Email")

                    Text {
                        text: parent.placeholderText
                        color: "#aaa"
                        visible: !parent.text && !parent.activeFocus
                        font: parent.font
                        verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width:      parent.width
                        height:     1
                        color: qgcPal.groupBorder
                    }
                }
            }

            RowLayout {
                Layout.fillWidth:   true
                visible: !_signedIn

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

                    property string placeholderText: qsTr("Input Password")

                    Text {
                        text: parent.placeholderText
                        color: "#aaa"
                        visible: !parent.text && !parent.activeFocus
                        font: parent.font
                        verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width:      parent.width
                        height:     1
                        color: qgcPal.groupBorder
                    }
                }
            }
            Keys.forwardTo: [emailField, passwordField]

            RowLayout {
                Layout.fillWidth:   true
                Layout.alignment: Qt.AlignHCenter

                QGCButton {
                    text: qsTr("Login")
                    visible: !_signedIn
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 12
                    //Layout.alignment: Qt.AlignCenter
                    onClicked:  {
                        var email = emailField.text
                        var password = passwordField.text
                        QGroundControl.cloudManager.signUserIn(email, password)
                    }
                }
                QGCButton {
                    text: qsTr("Logout")
                    visible: _signedIn
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 12
                    onClicked: {
                        QGroundControl.cloudManager.signUserOut()
                    }
                }
            }

        }
    }
}
