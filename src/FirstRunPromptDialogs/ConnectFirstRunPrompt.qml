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
import QtQuick.Effects

import QGroundControl
import QGroundControl.Palette
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.SettingsManager
import QGroundControl.Controls

FirstRunPrompt {
    id:         root
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

    on_CurrentSelectionChanged: {
        console.log(_currentSelection.name, _currentSelection.model, _currentSelection.highLatency)

        if (!_currentSelection || !_currentSelection.model) {
            vehicleImage0.source = "/qmlimages/amp_logo_white.png"
            return
        }

        vehicleImage0.source = ""

        var modelName = _currentSelection.model
        switch (modelName) {
        case "AMP1600":
            vehicleImage0.source = "/vehicleImage/amp1600.png"
            break
        case "AMP1150":
            vehicleImage0.source = "/vehicleImage/amp1200.png"
            break
        case "AMP1100":
            vehicleImage0.source = "/vehicleImage/amp1100.png"
            break
        case "AMP850":
            vehicleImage0.source = "/vehicleImage/amp900.png"
            break
        default:
            vehicleImage0.source = "/qmlimages/amp_logo_white.png"
            break
        }
    }

    ProgressTracker {
        id:                     closeProgressTracker
        timeoutSeconds:         5000 * 0.001
        onTimeout:              root.close()
    }

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

                Rectangle {
                    id: imageRect
                    //Layout.fillWidth:   true
                    width: ScreenTools.defaultFontPixelHeight * 6
                    height: ScreenTools.defaultFontPixelHeight * 6
                    Layout.alignment: Qt.AlignCenter
                    color: "transparent"

                    Item {
                        width: ScreenTools.defaultFontPixelHeight * 6
                        height: width
                        //visible: !_currentSelection || _currentSelection.model === "Generic" || !_currentSelection.model
                        Image {
                            id: vehicleImage0
                            anchors.fill: parent
                            source: "/qmlimages/amp_logo_white.png"
                            fillMode: Image.PreserveAspectFit
                        }
                        MultiEffect {
                            source: vehicleImage0
                            anchors.fill: vehicleImage0
                            shadowEnabled: true
                            shadowBlur: 0.3 // _currentSelection ? (_currentSelection.link ? 1.0 : 0.3) : 0.3
                            shadowColor: qgcPal.text // _currentSelection ? (_currentSelection.link ? qgcPal.colorGreen : qgcPal.text) : qgcPal.text
                        }
                    }
                    // QGCLabel {
                    //     text:   _currentSelection ? _currentSelection.model : "NONE"
                    //     anchors.top:   imageRect.top
                    //     anchors.right:  imageRect.right
                    // }
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
            spacing:    ScreenTools.defaultFontPixelHeight / 2

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
                            delegate: SettingsButton {
                                anchors.horizontalCenter:   settingsColumn.horizontalCenter
                                width:                      ScreenTools.defaultFontPixelWidth * 34
                                icon.source:                "/InstrumentValueIcons/link.svg"
                                icon.color:                 object.link ? qgcPal.colorGreen : qgcPal.text
                                text:                       object.name// + (object.link ? " (" + qsTr("Connected") + ")" : "")
                                autoExclusive:              true
                                visible:                    !object.dynamic
                                onClicked: {1
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
                    implicitWidth: ScreenTools.defaultFontPixelWidth * 12
                    text:       qsTr("Connect")
                    font.bold: true
                    enabled:    _currentSelection && !_currentSelection.link
                    onClicked:  {
                        QGroundControl.linkManager.createConnectedLink(_currentSelection)
                        if (_currentSelection && _currentSelection.link) {
                            closeProgressTracker.start()
                        }
                    }
                }
                QGCButton {
                    implicitWidth: ScreenTools.defaultFontPixelWidth * 12
                    text:       qsTr("Disconnect")
                    font.bold: true
                    enabled:    _currentSelection && _currentSelection.link
                    onClicked:  {
                        _currentSelection.link.disconnect()
                        _currentSelection.linkChanged()
                        if (closeProgressTracker.running) {
                            closeProgressTracker.stop()
                        }
                    }
                }
                QGCButton {
                    implicitWidth: ScreenTools.defaultFontPixelWidth * 8
                    text:       qsTr("Configure")
                    font.bold: true
                    onClicked: {
                        close()
                        mainWindow.showAppSettings(qsTr("Comm Links"))
                    }
                }
            }

            QGCLabel {
                id:   closeProgressLabel
                visible:            closeProgressTracker.running && closeProgressTracker.progressLabel
                Layout.fillWidth:   true
                horizontalAlignment: Text.AlignRight
                text: "연결되었습니다. " + qsTr("Automatically close in %1 seconds").arg(closeProgressTracker.progressLabel)

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (closeProgressTracker.running) {
                            closeProgressTracker.stop()
                        }
                    }
                }
            }
        }

    }
}
