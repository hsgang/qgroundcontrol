import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.FlightDisplay

Rectangle {
    id:     welcomeView
    color:  qgcPal.window
    z:      QGroundControl.zOrderTopMost

    readonly property real _defaultTextHeight:  ScreenTools.defaultFontPixelHeight
    readonly property real _defaultTextWidth:   ScreenTools.defaultFontPixelWidth
    readonly property real _horizontalMargin:   ScreenTools.defaultFontPixelHeight / 2
    readonly property real _verticalMargin:     ScreenTools.defaultFontPixelHeight / 2
    readonly property real _buttonHeight:       ScreenTools.isTinyScreen ? ScreenTools.defaultFontPixelHeight * 3 : ScreenTools.defaultFontPixelHeight * 2

    property var    _currentSelection:     null

    property var    _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    property var    _settingsManager:   QGroundControl.settingsManager
    property var    cloudSettings:      _settingsManager.cloudSettings
    property real   _urlFieldWidth:     ScreenTools.defaultFontPixelWidth * 30
    property real   _margins:           ScreenTools.defaultFontPixelHeight / 2

    property bool   _signedIn:  QGroundControl.cloudManager.signedIn
    property string _signedId:  QGroundControl.cloudManager.signedUserName
    property string _message:   QGroundControl.cloudManager.messageString

    QGCPalette { id: qgcPal }

    on_CurrentSelectionChanged: {
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

    DeadMouseArea {
        anchors.fill: parent
    }

    Item {
        id: welcomeViewHolder
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.left: parent.left

        Rectangle {
            id: loginRect
            height:                     loginLayout.height + _defaultTextHeight
            width:                      loginLayout.width + _defaultTextHeight
            color:                      "transparent"
            anchors.horizontalCenter:   parent.horizontalCenter
            anchors.verticalCenter:     parent.verticalCenter
            visible:                    true
            radius:                     _margins

            ColumnLayout {
                id:         loginLayout
                spacing:    _margins * 4
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                Component.onCompleted: {
                    QGroundControl.cloudManager.checkConnection()
                }

                Connections {
                    target: QGroundControl.cloudManager
                    function onConnectionSuccess() {
                        icon1.color = qgcPal.colorGreen
                        icon2.color = qgcPal.colorGreen
                        icon3.color = qgcPal.colorGreen
                    }
                    function onConnectionFailed() {
                        icon1.color = qgcPal.colorRed
                        icon2.color = qgcPal.colorRed
                        icon3.color = qgcPal.colorRed
                    }
                }

                Rectangle {
                    id: imageRect
                    width: ScreenTools.defaultFontPixelHeight * 8
                    height: ScreenTools.defaultFontPixelHeight * 8
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    color: "transparent"

                    Item {
                        width: ScreenTools.defaultFontPixelHeight * 6
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        Image {
                            id: vehicleImage0
                            anchors.fill: parent
                            source: "/qmlimages/amp_logo_white.png"
                            fillMode: Image.PreserveAspectFit
                        }
                        MultiEffect {
                            source:         vehicleImage0
                            anchors.fill:   vehicleImage0
                            shadowEnabled:  true
                            shadowBlur:     0.3
                            shadowColor:    qgcPal.text
                        }
                    }
                }

                Rectangle {
                    implicitWidth:  loginInputLayout.implicitWidth + _defaultTextHeight
                    implicitHeight: loginInputLayout.implicitHeight + _defaultTextHeight
                    color:          Qt.darker(qgcPal.windowShadeDark, 1.3)
                    radius:         _margins
                    border.color:   qgcPal.groupBorder
                    border.width:   1

                    ColumnLayout {
                        id: loginInputLayout
                        anchors.horizontalCenter:   parent.horizontalCenter
                        anchors.verticalCenter:     parent.verticalCenter
                        spacing: _margins

                        RowLayout {
                            spacing: _margins

                            ColumnLayout {
                                Layout.alignment: Qt.AlignHCenter

                                LabelledLabel {
                                    visible:                _signedIn
                                    Layout.preferredWidth:  loginFormLayout.width
                                    Layout.preferredHeight: loginFormLayout.height
                                    label:                  qsTr("User")
                                    labelText:              _signedId == "" ? qsTr("Connecting...") : _signedId
                                }

                                ColumnLayout {
                                    id:                 loginFormLayout
                                    Layout.fillWidth:   true
                                    Layout.fillHeight:  true
                                    spacing: _margins
                                    visible: !_signedIn

                                    ColumnLayout {
                                        Layout.fillWidth:   true
                                        spacing: ScreenTools.defaultFontPixelHeight / 2

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
                                            leftPadding:    ScreenTools.defaultFontPixelWidth

                                            property string placeholderText: qsTr("Input Email")

                                            Text {
                                                text: parent.placeholderText
                                                color: "#aaa"
                                                visible: !parent.text && !parent.activeFocus
                                                font: parent.font
                                                verticalAlignment: Text.AlignVCenter
                                            }

                                            Rectangle {
                                                anchors.verticalCenter:     parent.verticalCenter
                                                anchors.horizontalCenter:   parent.horizontalCenter
                                                width:      parent.width + ScreenTools.defaultFontPixelHeight / 4
                                                height:     parent.height + ScreenTools.defaultFontPixelHeight / 4
                                                radius:     ScreenTools.defaultFontPixelHeight / 4
                                                color: "transparent"
                                                border.color: qgcPal.groupBorder
                                                border.width: 1
                                            }

                                            KeyNavigation.tab: passwordField
                                        }
                                    }

                                    ColumnLayout {
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
                                            leftPadding:    ScreenTools.defaultFontPixelWidth

                                            property string placeholderText: qsTr("Input Password")

                                            Text {
                                                text: parent.placeholderText
                                                color: "#aaa"
                                                visible: !parent.text && !parent.activeFocus
                                                font: parent.font
                                                verticalAlignment: Text.AlignVCenter
                                            }

                                            Rectangle {
                                                anchors.verticalCenter:     parent.verticalCenter
                                                anchors.horizontalCenter:   parent.horizontalCenter
                                                width:      parent.width + ScreenTools.defaultFontPixelHeight / 4
                                                height:     parent.height + ScreenTools.defaultFontPixelHeight / 4
                                                radius:     ScreenTools.defaultFontPixelHeight / 4
                                                color: "transparent"
                                                border.color: qgcPal.groupBorder
                                                border.width: 1
                                            }
                                        }

                                        KeyNavigation.tab: loginButton
                                    }

                                    QGCLabel {
                                        id:     statusLabel
                                        Layout.alignment: Qt.AlignHCenter
                                        visible: _message !== "";
                                        text: _message
                                        color: qgcPal.colorRed
                                    }
                                }
                            }

                            Rectangle {
                                width: 1
                                Layout.fillHeight: true
                                color: qgcPal.groupBorder
                            }

                            ColumnLayout {
                                Layout.fillWidth:   true
                                Layout.alignment:   Qt.AlignHCenter
                                spacing:            _margins

                                QGCButton {
                                    id: loginButton
                                    text: qsTr("Login")
                                    iconSource: "/InstrumentValueIcons/log-in.svg"
                                    visible: !_signedIn
                                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 18
                                    Layout.alignment: Qt.AlignHCenter
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
                                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 18
                                    Layout.alignment: Qt.AlignHCenter
                                    onClicked: {
                                        QGroundControl.cloudManager.signUserOut()
                                        passwordField.text = "";
                                        QGroundControl.cloudManager.password = "";
                                    }
                                }

                                QGCButton {
                                    id: skipButton
                                    text: _signedIn ? "기체 선택" : "오프라인 모드"
                                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 18
                                    Layout.alignment: Qt.AlignHCenter
                                    onClicked: {
                                        loginRect.visible = false
                                        connectRect.visible = true
                                    }
                                }

                                Rectangle {
                                    height: 1
                                    Layout.fillWidth: true
                                    color: qgcPal.groupBorder
                                }

                                QGCButton {
                                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 18
                                    text:               "종료"
                                    onClicked: {
                                        if (mainWindow.allowViewSwitch()) {
                                            mainWindow.showMessageDialog(closeDialogTitle,
                                                              qsTr("애플리케이션을 종료하시겠습니까?"),
                                                              Dialog.Yes | Dialog.No,
                                                              function() { finishCloseProcess() })
                                        }
                                    }
                                }
                            }
                        }

                        Row {
                            Layout.alignment:   Qt.AlignHCenter
                            spacing:            2

                            QGCColoredImage {
                                id:                 icon1
                                height:             ScreenTools.defaultFontPixelHeight * 0.6
                                width:              height
                                sourceSize.height:  height
                                source:             "/InstrumentValueIcons/computer-laptop.svg"
                                fillMode:           Image.PreserveAspectFit
                                color:              qgcPal.text
                            }
                            QGCColoredImage {
                                id:                 icon2
                                height:             ScreenTools.defaultFontPixelHeight * 0.6
                                width:              height
                                sourceSize.height:  height
                                source:             "/InstrumentValueIcons/arrow-right-left.svg"
                                fillMode:           Image.PreserveAspectFit
                                color:              qgcPal.text
                            }
                            QGCColoredImage {
                                id:                 icon3
                                height:             ScreenTools.defaultFontPixelHeight * 0.6
                                width:              height
                                sourceSize.height:  height
                                source:             "/InstrumentValueIcons/cloud.svg"
                                fillMode:           Image.PreserveAspectFit
                                color:              qgcPal.text
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: connectRect
            height:                     connectLayout.height + _defaultTextHeight
            width:                      connectLayout.width + _defaultTextHeight
            anchors.horizontalCenter:   parent.horizontalCenter
            anchors.verticalCenter:     parent.verticalCenter
            visible:                    false
            color:          Qt.darker(qgcPal.windowShadeDark, 1.3)
            radius:         _margins
            border.color:   qgcPal.groupBorder
            border.width:   1

            ColumnLayout {
                id:         connectLayout
                spacing:    _margins
                anchors.horizontalCenter:   parent.horizontalCenter
                anchors.verticalCenter:     parent.verticalCenter

                QGCLabel {
                    id:         connectSectionLabel
                    text:       "기체 연결 리스트"
                    font.bold:  true
                    Layout.preferredWidth: flickableRect.width
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    spacing: _margins

                    ColumnLayout {

                        Rectangle {
                            id: flickableRect
                            color:              "transparent"
                            border.color:       qgcPal.groupBorder
                            width:              ScreenTools.defaultFontPixelWidth * 38
                            height:             ScreenTools.defaultFontPixelHeight * 16
                            radius:             _margins / 2

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
                                            text:                       object.name
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

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 0

                            ProgressBar {
                                id:     progressBar
                                width: parent.width
                                value: _activeVehicle ? _activeVehicle.loadProgress : 0
                                indeterminate:  _activeVehicle && _activeVehicle.loadProgress === 0

                                background: Rectangle {
                                    implicitWidth: parent.width
                                    implicitHeight: ScreenTools.defaultFontPixelHeight / 4
                                    color: qgcPal.windowShadeLight
                                    radius: height / 2
                                }

                                contentItem: Item {
                                    implicitWidth: parent.width
                                    implicitHeight: ScreenTools.defaultFontPixelHeight / 4

                                    // Progress indicator for determinate state.
                                    Rectangle {
                                        width: progressBar.visualPosition * parent.width
                                        height: parent.height
                                        radius: height / 2
                                        color: qgcPal.colorGreen
                                        visible: !progressBar.indeterminate
                                    }

                                    Item {
                                        anchors.fill: parent
                                        visible: progressBar.indeterminate && !_activeVehicle.initialConnectComplete
                                        clip: true

                                        Rectangle {
                                            id: movingBar
                                            width: 10
                                            height: progressBar.height
                                            radius: height / 2
                                            color: qgcPal.colorGreen
                                        }

                                        XAnimator on x {
                                            target: movingBar
                                            from: -10
                                            to: progressBar.width
                                            loops: Animation.Infinite
                                            duration: 1500
                                            easing.type: Easing.InOutQuad
                                            running: progressBar.indeterminate
                                        }
                                    }
                                }
                            }

                            QGCLabel {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                                text: _activeVehicle ? (_activeVehicle.initialConnectComplete ? "동기화 완료" : "매개변수 동기화중") : "대기중"
                            }

                            QGCLabel {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                                text: _currentSelection && (_currentSelection.linkType === 3) ? QGroundControl.linkManager.rtcStatusMessage : ""
                                font.pointSize: ScreenTools.smallFontPointSize
                            }
                        }
                    }

                    Rectangle {
                        width: 1
                        Layout.fillHeight: true
                        color: qgcPal.groupBorder
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        spacing: _margins

                        QGCButton {
                            Layout.fillWidth:   true
                            text:       qsTr("Connect")
                            font.bold: true
                            enabled:    _currentSelection && !_currentSelection.link
                            onClicked:  {
                                QGroundControl.linkManager.createConnectedLink(_currentSelection)
                            }
                        }
                        QGCButton {
                            Layout.fillWidth:   true
                            text:       qsTr("Disconnect")
                            font.bold: true
                            enabled:    _currentSelection && _currentSelection.link
                            onClicked:  {
                                _currentSelection.link.disconnect()
                                _currentSelection.linkChanged()
                            }
                        }

                        Rectangle {
                            height: 1
                            Layout.fillWidth: true
                            color: qgcPal.groupBorder
                        }

                        QGCButton {
                            Layout.fillWidth:   true
                            text:       "비행화면"
                            iconSource: "/qmlimages/PaperPlane.svg"
                            font.bold: true
                            onClicked: {
                                mainWindow.showFlyView()
                            }
                        }

                        QGCButton {
                            Layout.fillWidth:   true
                            text:       "자동경로"
                            iconSource: "/qmlimages/Plan.svg"
                            font.bold: true
                            onClicked: {
                                mainWindow.showPlanView()
                            }
                        }

                        Rectangle {
                            height: 1
                            Layout.fillWidth: true
                            color: qgcPal.groupBorder
                        }

                        QGCButton {
                            Layout.fillWidth:   true
                            text:       qsTr("Configure")
                            font.bold: true
                            onClicked: {
                                mainWindow.showAppSettings(qsTr("Comm Links"))
                            }
                        }

                        Rectangle {
                            height: 1
                            Layout.fillWidth: true
                            color: qgcPal.groupBorder
                        }

                        QGCButton {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 18
                            text:               "종료"
                            onClicked: {
                                if (mainWindow.allowViewSwitch()) {
                                    mainWindow.showMessageDialog(closeDialogTitle,
                                                      qsTr("애플리케이션을 종료하시겠습니까?"),
                                                      Dialog.Yes | Dialog.No,
                                                      function() { finishCloseProcess() })
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
