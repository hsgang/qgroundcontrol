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
import QGroundControl.Palette
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.SettingsManager
import QGroundControl.Controls

FirstRunPrompt {
    title:      qsTr("Link Management")
    promptId:   QGroundControl.corePlugin.connectFirstRunPromptId
    markAsShownOnClose: false
    buttons: Dialog.Close

    property var    _currentSelection:     null

    property var    _settingsManager:   QGroundControl.settingsManager
    property var    cloudSettings:      _settingsManager.cloudSettings
    property real   _urlFieldWidth:     ScreenTools.defaultFontPixelWidth * 25
    property real   _margins:           ScreenTools.defaultFontPixelHeight / 2

    property bool   _signedIn: QGroundControl.cloudManager.signedIn
    property string _signedId: QGroundControl.cloudManager.signedId
    property string _message: QGroundControl.cloudManager.messageString

    QGCPalette { id: qgcPal }

    RowLayout {
        spacing: _margins

        Rectangle {
            Layout.fillHeight:  true
            width:              ScreenTools.defaultFontPixelWidth * 36
            //border.color:       "red"
            color:              "transparent"

            ColumnLayout {
                id:         columnLayout2
                spacing:    _margins
                anchors.fill: parent
                //Layout.fillWidth:  true

                // Image {
                //     Layout.fillWidth:   true
                //     sourceSize.width: ScreenTools.defaultFontPixelHeight * 6
                //     sourceSize.height: ScreenTools.defaultFontPixelHeight * 6
                //     source: "/vehicleImage/amp1600.png"
                //     fillMode: Image.PreserveAspectFit
                // }

                Rectangle {
                    Layout.fillWidth:   true
                    width: ScreenTools.defaultFontPixelHeight * 6
                    height: ScreenTools.defaultFontPixelHeight * 6
                    color: "transparent"

                    SwipeView {
                        id: swipeView
                        anchors.fill: parent
                        interactive: false  // 자동 스와이프를 위해 수동 스와이프 비활성화 (원하면 true로 설정)
                        clip: true

                        Image {
                            source: "/vehicleImage/amp1600.png"
                            fillMode: Image.PreserveAspectFit
                            visible: swipeView.currentIndex === 0
                        }
                        Image {
                            source: "/vehicleImage/amp1200.png"
                            fillMode: Image.PreserveAspectFit
                            visible: swipeView.currentIndex === 1
                        }
                        Image {
                            source: "/vehicleImage/amp1100.png"
                            fillMode: Image.PreserveAspectFit
                            visible: swipeView.currentIndex === 2
                        }
                        Image {
                            source: "/vehicleImage/amp900.png"
                            fillMode: Image.PreserveAspectFit
                            visible: swipeView.currentIndex === 3
                        }
                    }

                    Timer {
                        interval: 3000  // 3초 간격
                        running: true
                        repeat: true
                        onTriggered: {
                            swipeView.currentIndex = (swipeView.currentIndex + 1) % swipeView.count
                        }
                    }
                }

                QGCLabel {
                    text:       qsTr("Cloud Login [%1]").arg(QGroundControl.cloudManager.networkStatus)
                    wrapMode:   Text.WordWrap
                    font.bold:  true
                }

                // LabelledLabel {
                //     Layout.fillWidth:   true
                //     label:              qsTr("네트워크 상태")
                //     labelText:          QGroundControl.cloudManager.networkStatus
                // }

                LabelledLabel {
                    visible:            _signedIn
                    Layout.fillWidth:   true
                    label:              qsTr("User")
                    labelText:          _signedId == "" ? qsTr("Connecting...") : _signedId
                }

                ColumnLayout {
                    Layout.fillWidth:   true
                    Layout.fillHeight:  true
                    spacing: _margins
                    visible: !_signedIn

                    RowLayout {
                        Layout.fillWidth:   true
                        //Layout.fillHeight:  true

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
                            focus:          true
                            text:           QGroundControl.cloudManager.emailAddress

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

                        KeyNavigation.tab: loginButton
                    }

                    QGCLabel {
                        visible: _message !== "";
                        text: _message
                        color: qgcPal.colorRed
                    }
                }

                RowLayout {
                    Layout.fillWidth:   true
                    Layout.alignment: Qt.AlignHCenter

                    QGCButton {
                        id: loginButton
                        text: qsTr("Login")
                        visible: !_signedIn
                        Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 12
                        onClicked:  {
                            var email = emailField.text
                            var password = passwordField.text
                            QGroundControl.cloudManager.signUserIn(email, password)
                            QGroundControl.cloudManager.emailAddress = emailField.text
                            QGroundControl.cloudManager.password = passwordField.text
                        }
                        KeyNavigation.tab: emailField
                    }

                    QGCButton {
                        id: logoutButton
                        text: qsTr("Logout")
                        visible: _signedIn
                        Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 12
                        onClicked: {
                            QGroundControl.cloudManager.signUserOut()
                            passwordField.text = "";
                            QGroundControl.cloudManager.password = "";
                        }
                    }
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
            id:         columnLayout
            spacing:    ScreenTools.defaultFontPixelHeight

            QGCLabel {
                id:         unitsSectionLabel
                text:       qsTr("연결 항목") //qsTr("Choose the link you want to connect.")
                font.bold:  true
                Layout.preferredWidth: flickableRect.width
                wrapMode: Text.WordWrap
            }

            Rectangle {
                id: flickableRect
                color:              "transparent"
                border.color:       qgcPal.groupBorder
                width:              ScreenTools.defaultFontPixelWidth * 36
                height:             ScreenTools.defaultFontPixelHeight * 10
                radius:             _margins

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
                        spacing:            _margins
                        Repeater {
                            model: QGroundControl.linkManager.linkConfigurations
                            delegate: QGCButton {
                                anchors.horizontalCenter:   settingsColumn.horizontalCenter
                                width:                      ScreenTools.defaultFontPixelWidth * 34
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
                    onClicked:  QGroundControl.linkManager.createConnectedLink(_currentSelection)
                    implicitWidth: ScreenTools.defaultFontPixelWidth * 12
                }
                QGCButton {
                    text:       qsTr("Disconnect")
                    font.bold: true
                    enabled:    _currentSelection && _currentSelection.link
                    onClicked:  {
                        _currentSelection.link.disconnect()
                        _currentSelection.linkChanged()
                    }
                    implicitWidth: ScreenTools.defaultFontPixelWidth * 12
                }
                QGCButton {
                    text:       qsTr("Configure")
                    font.bold: true
                    onClicked: {
                        close()
                        mainWindow.showAppSettings(qsTr("Comm Links"))
                    }

                    implicitWidth: ScreenTools.defaultFontPixelWidth * 8
                }
            }
        }

    }
}
