import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView
import QGroundControl.Toolbar

Item {
    required property var guidedValueSlider

    id:     control
    width:  parent.width
    height: _mainHeight + (batteryProgressBar.visible
                            ? batteryPercentChip.height + 2
                            : 0)
    //color:  "transparent"

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false
    property color  _mainStatusBGColor: qgcPal.brandingPurple
    property real   _leftRightMargin:   ScreenTools.defaultFontPixelWidth * 0.75
    property var    _guidedController:  globals.guidedControllerFlyView
    property real   _margins:           ScreenTools.defaultFontPixelWidth
    property real   _mainHeight:        ScreenTools.toolbarHeight

    QGCPalette { id: qgcPal }

    RowLayout {
        id:                     mainLayout
        anchors.bottomMargin:   1
        anchors.top:            parent.top
        anchors.left:           parent.left
        anchors.right:          parent.right
        anchors.rightMargin:    ScreenTools.defaultFontPixelWidth
        height:                 _mainHeight
        spacing:                ScreenTools.defaultFontPixelWidth

        RowLayout {
            id:                 leftStatusLayout
            Layout.fillHeight:  true
            Layout.alignment:   Qt.AlignLeft
            spacing:            ScreenTools.defaultFontPixelWidth

            Rectangle{
                id:                     menuNavigationButton
                Layout.leftMargin:      ScreenTools.defaultFontPixelWidth / 2
                height:                 _mainHeight * 0.8
                width:                  height
                color:                  qgcLogoButton.hovered
                                        ? Qt.rgba(qgcPal.buttonHighlight.r, qgcPal.buttonHighlight.g, qgcPal.buttonHighlight.b, 0.85)
                                        : qgcPal.windowTransparent
                radius:                 ScreenTools.defaultFontPixelHeight / 4

                QGCToolBarButton {
                    id:                         qgcLogoButton
                    anchors.horizontalCenter:   parent.horizontalCenter
                    anchors.verticalCenter:     parent.verticalCenter
                    icon.source:                "/res/amplogo.svg"
                    // logo:false so QGCColoredImage tints via palette text colour
                    // (visible on both light and dark themes). amplogo is monochrome.
                    onClicked:                  mainWindow.showToolSelectDialog()
                }
            }

            Rectangle{
                id:                     linkManagerButton
                height:                 _mainHeight * 0.8
                width:                  height
                color:                  linkMouseArea.containsMouse
                                        ? Qt.rgba(qgcPal.buttonHighlight.r, qgcPal.buttonHighlight.g, qgcPal.buttonHighlight.b, 0.85)
                                        : QGroundControl.globalPalette.windowTransparent
                radius:                 ScreenTools.defaultFontPixelHeight / 4
                visible:                !ScreenTools.isMobile/* && currentToolbar === flyViewToolbar*/

                QGCColoredImage{
                    height:             parent.height * 0.6
                    width:              height
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    source:             "/InstrumentValueIcons/link.svg"
                    sourceSize.height:  height
                    fillMode:           Image.PreserveAspectFit
                    mipmap:             true
                    color:              qgcPal.text
                }

                MouseArea{
                    id:                 linkMouseArea
                    anchors.fill:       parent
                    hoverEnabled:       true
                    onClicked:          linkManagerDialogComponent.createObject(mainWindow).open()
                }
            }

            MainStatusIndicator {
                id:      mainStatusIndicator
                height:  _mainHeight * 0.8
            }

            Rectangle {
                id: messageIndicator
                Layout.alignment:       Qt.AlignVCenter
                height:                 _mainHeight * 0.8
                Layout.preferredWidth:  childrenRect.width + ScreenTools.defaultFontPixelWidth * 2
                color:                  qgcPal.windowTransparent
                radius:                 ScreenTools.defaultFontPixelHeight / 4
                visible:                _activeVehicle

                MessageIndicator{
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.margins: ScreenTools.defaultFontPixelHeight * 0.3
                }
            }

            QGCButton {
                id:                 disconnectButton
                Layout.alignment:       Qt.AlignVCenter
                text:               qsTr("Disconnect")
                onClicked:          _activeVehicle.closeVehicle()
                visible:            _activeVehicle && _communicationLost
            }

            QGCButton {
                id:                 reconnectButton
                Layout.alignment:       Qt.AlignVCenter
                text:               qsTr("Reconnect")
                onClicked:          {
                    if (_activeVehicle) {
                        var primaryLinkName = _activeVehicle.vehicleLinkManager.primaryLinkName
                        var linkConfigs = QGroundControl.linkManager.linkConfigurations
                        for (var i = 0; i < linkConfigs.count; i++) {
                            var config = linkConfigs.get(i)
                            if (config.name === primaryLinkName) {
                                if (config.link) {
                                    // WebRTC 링크인 경우 재연결 메서드 사용
                                    if (config.linkType === 3) { // LinkConfiguration.TypeWebRTC = 3
                                        config.link.reconnectLink()
                                    } else {
                                        // 다른 링크는 기존 방식 사용
                                        config.link.disconnect()
                                        QGroundControl.linkManager.createConnectedLink(config)
                                    }
                                } else {
                                    // 링크가 없으면 새로 생성
                                    QGroundControl.linkManager.createConnectedLink(config)
                                }
                                break
                            }
                        }
                    }
                }
                visible:            _activeVehicle && _communicationLost
            }
        }
        RowLayout {
            id:                 centerPanel
            Layout.fillHeight:  true
        }

        RowLayout {
            id:                 rightStatusLayout
            Layout.fillHeight:  true
            Layout.alignment:   Qt.AlignRight
            spacing:            ScreenTools.defaultFontPixelWidth

            FlightModeIndicator {
                Layout.fillHeight:      true
                Layout.alignment:       Qt.AlignVCenter
                visible:                _activeVehicle
            }

            Rectangle {
                id: webrtcIndicatorRect
                Layout.alignment:       Qt.AlignVCenter
                height:                 _mainHeight * 0.8
                Layout.preferredWidth:  childrenRect.width + ScreenTools.defaultFontPixelWidth * 2
                color:                  qgcPal.windowTransparent
                radius:                 ScreenTools.defaultFontPixelHeight / 4
                visible:                webrtcIndicator.showIndicator
                border.color:           qgcPal.groupBorder
                border.width:           1

                WEBRTCIndicator{
                    id:                 webrtcIndicator
                    anchors.right:      parent.right
                    anchors.margins:    ScreenTools.defaultFontPixelHeight * 0.3
                }
            }

            FlyViewToolBarIndicators {
                id:                     toolIndicators
                Layout.fillHeight:      true
                Layout.alignment:       Qt.AlignVCenter
            }

            Rectangle {
                id:                     widgetControlButton
                Layout.alignment:       Qt.AlignVCenter
                height:                 _mainHeight * 0.8
                width:                  height
                color:                  widgetControlMouseArea.containsMouse
                                        ? Qt.rgba(qgcPal.buttonHighlight.r, qgcPal.buttonHighlight.g, qgcPal.buttonHighlight.b, 0.85)
                                        : qgcPal.windowTransparent
                radius:                 ScreenTools.defaultFontPixelHeight * 0.2

                QGCColoredImage{
                    height:             parent.height * 0.5
                    width:              height
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    source:             "/InstrumentValueIcons/navigation-more.svg"
                    sourceSize.height:  height
                    fillMode:           Image.PreserveAspectFit
                    mipmap:             true
                    color:              qgcPal.text
                }

                MouseArea{
                    id:                 widgetControlMouseArea
                    anchors.fill:       parent
                    hoverEnabled:       true
                    onClicked:          mainWindow.showIndicatorDrawer(widgetControlComponent, widgetControlButton)
                }
            }
        }
    }

    // 헤더 하단 배터리 잔량 프로그레스 바 — chip 의 세로 중앙과 정렬
    Rectangle {
        id:                     batteryProgressBar
        anchors.bottom:         parent.bottom
        anchors.bottomMargin:   batteryPercentChip.visible
                                    ? (batteryPercentChip.height - height) / 2 + 1
                                    : 0
        anchors.left:           parent.left
        anchors.right:          parent.right
        anchors.leftMargin:     ScreenTools.defaultFontPixelWidth
        anchors.rightMargin:    ScreenTools.defaultFontPixelWidth
        height:                 ScreenTools.defaultFontPixelHeight * 0.15
        radius:                 height / 2
        color:                  Qt.rgba(qgcPal.windowShade.r, qgcPal.windowShade.g, qgcPal.windowShade.b, 0.6)
        clip:                   true
        visible:                _activeVehicle && _activeVehicle.batteries.count > 0

        property var _battery: (_activeVehicle && _activeVehicle.batteries.count > 0) ? _activeVehicle.batteries.get(0) : null
        property var _batterySettings: QGroundControl.settingsManager.batteryIndicatorSettings
        property real _percent: _battery && !isNaN(_battery.percentRemaining.rawValue)
                                ? Math.max(0, Math.min(100, _battery.percentRemaining.rawValue)) : 0

        Rectangle {
            id:                 batteryProgressFill
            anchors.left:       parent.left
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            width:              parent.width * (batteryProgressBar._percent / 100)
            color: {
                if (!batteryProgressBar._battery) return qgcPal.text
                switch (batteryProgressBar._battery.chargeState.rawValue) {
                    case MAVLinkEnums.MAV_BATTERY_CHARGE_STATE_LOW:
                        return qgcPal.colorOrange
                    case MAVLinkEnums.MAV_BATTERY_CHARGE_STATE_CRITICAL:
                    case MAVLinkEnums.MAV_BATTERY_CHARGE_STATE_EMERGENCY:
                    case MAVLinkEnums.MAV_BATTERY_CHARGE_STATE_FAILED:
                    case MAVLinkEnums.MAV_BATTERY_CHARGE_STATE_UNHEALTHY:
                        return qgcPal.colorRed
                }
                if (!isNaN(batteryProgressBar._battery.percentRemaining.rawValue)) {
                    var bs = batteryProgressBar._batterySettings
                    if (batteryProgressBar._battery.percentRemaining.rawValue > bs.threshold1.rawValue) return qgcPal.colorGreen
                    if (batteryProgressBar._battery.percentRemaining.rawValue > bs.threshold2.rawValue) return qgcPal.colorYellowGreen
                    return qgcPal.colorYellow
                }
                return qgcPal.text
            }

            Behavior on width { NumberAnimation { duration: 250 } }
            Behavior on color { ColorAnimation { duration: 250 } }
        }
    }

    // 배터리 잔량 chip — 프로그레스 바 아래, 채움 끝 위치를 따라 이동
    Rectangle {
        id:             batteryPercentChip
        visible:        batteryProgressBar.visible && batteryProgressBar._battery
                            && !isNaN(batteryProgressBar._battery.percentRemaining.rawValue)
        width:          chipLabel.implicitWidth + ScreenTools.defaultFontPixelWidth * 1.6
        height:         chipLabel.implicitHeight + ScreenTools.defaultFontPixelHeight * 0.25
        color:          Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.9)
        border.color:   batteryProgressFill.color
        border.width:   1
        radius:         height / 2

        anchors.verticalCenter: batteryProgressBar.verticalCenter

        x: {
            var fillRightEdge = batteryProgressBar.x + batteryProgressFill.width
            var centered      = fillRightEdge - width / 2
            var minX          = batteryProgressBar.x
            var maxX          = batteryProgressBar.x + batteryProgressBar.width - width
            return Math.max(minX, Math.min(maxX, centered))
        }

        Behavior on x { NumberAnimation { duration: 250 } }
        Behavior on border.color { ColorAnimation { duration: 250 } }

        QGCLabel {
            id:                 chipLabel
            anchors.centerIn:   parent
            text:               batteryProgressBar._percent.toFixed(0) + "%"
            font.pointSize:     ScreenTools.smallFontPointSize
            font.bold:          true
            color:              batteryProgressFill.color
        }
    }

    Component{
        id: linkManagerDialogComponent

        QGCPopupDialog {
            id:         linkPopup
            title :     qsTr("Link Management")
            buttons:    Dialog.Close

            function linkTypeIcon(linkType) {
                switch (linkType) {
                    case LinkConfiguration.TypeSerial:    return "/InstrumentValueIcons/usb.svg"
                    case LinkConfiguration.TypeUdp:       return "/InstrumentValueIcons/network.svg"
                    case LinkConfiguration.TypeTcp:       return "/InstrumentValueIcons/network-transmit-receive.svg"
                    case LinkConfiguration.TypeWebRTC:    return "/InstrumentValueIcons/cloud.svg"
                    case LinkConfiguration.TypeBluetooth: return "/InstrumentValueIcons/bluetooth.svg"
                }
                return "/InstrumentValueIcons/link.svg"
            }
            function linkTypeName(linkType) {
                switch (linkType) {
                    case LinkConfiguration.TypeSerial:    return qsTr("Serial")
                    case LinkConfiguration.TypeUdp:       return qsTr("UDP")
                    case LinkConfiguration.TypeTcp:       return qsTr("TCP")
                    case LinkConfiguration.TypeWebRTC:    return qsTr("WebRTC")
                    case LinkConfiguration.TypeBluetooth: return qsTr("Bluetooth")
                }
                return qsTr("Link")
            }
            function linkSubInfo(config) {
                switch (config.linkType) {
                    case LinkConfiguration.TypeSerial:    return (config.portName || "") + (config.baud ? " · " + config.baud : "")
                    case LinkConfiguration.TypeUdp:       return ":" + config.localPort
                    case LinkConfiguration.TypeTcp:       return (config.host || "") + ":" + config.port
                    case LinkConfiguration.TypeWebRTC:    return config.targetDroneId || qsTr("(no target)")
                }
                return ""
            }

            ColumnLayout {
                id: contentsColumnLayout
                width:      ScreenTools.defaultFontPixelWidth * 48
                spacing:    ScreenTools.defaultFontPixelHeight / 4

                Rectangle {
                    id: flickableRect
                    Layout.fillWidth:   true
                    height:             ScreenTools.defaultFontPixelHeight * 20
                        color:              "transparent"
                        radius:             ScreenTools.defaultFontPixelHeight / 4
                        border.color:       qgcPal.groupBorder
                        border.width:       1
                        clip:               true

                        QGCFlickable {
                            clip:               true
                            anchors.fill:       parent
                            anchors.margins:    1   // 외곽 테두리 안쪽으로 클리핑
                            contentHeight:      settingsColumn.height
                            flickableDirection: Flickable.VerticalFlick

                            Column {
                                id:                 settingsColumn
                                width:              parent.width
                                spacing:            ScreenTools.defaultFontPixelHeight / 6

                                Repeater {
                                    model: QGroundControl.linkManager.linkConfigurations

                                    delegate: Rectangle {
                                        id:                 linkCard
                                        width:              settingsColumn.width
                                        height:             ScreenTools.defaultFontPixelHeight * 3.4
                                        color:              cardHoverArea.containsMouse
                                                                ? Qt.rgba(qgcPal.buttonHighlight.r, qgcPal.buttonHighlight.g, qgcPal.buttonHighlight.b, 0.18)
                                                                : "transparent"
                                        visible:            !object.dynamic

                                        HoverHandler { id: cardHoverArea }

                                        // link.linkConnected (C++ LinkInterface::isConnected) 로 실제 peer 연결 상태 판정
                                        // WebRTC 의 Idle 상태(link 존재하지만 연결 안 됨)도 정확히 false 로 표시됨
                                        property bool isWebRTC:          object.linkType === LinkConfiguration.TypeWebRTC
                                        property bool isConnected:       object.link !== null && object.link.linkConnected
                                        property bool isDroneOnline:     isWebRTC && !isConnected && object.serverConnected
                                        property color statusColor: isConnected
                                                                        ? qgcPal.colorGreen
                                                                        : (isDroneOnline ? qgcPal.colorBlue : qgcPal.colorGrey)
                                        property string statusText: isConnected
                                                                        ? qsTr("연결됨")
                                                                        : (isDroneOnline ? qsTr("온라인") : qsTr("대기"))

                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        // Left status strip
                                        Rectangle {
                                            anchors.left:           parent.left
                                            anchors.top:            parent.top
                                            anchors.bottom:         parent.bottom
                                            anchors.margins:        3
                                            width:                  3
                                            radius:                 width / 2
                                            color:                  linkCard.statusColor
                                            Behavior on color { ColorAnimation { duration: 200 } }
                                        }

                                        RowLayout {
                                            anchors.fill:           parent
                                            anchors.leftMargin:     ScreenTools.defaultFontPixelWidth * 1.5
                                            anchors.rightMargin:    ScreenTools.defaultFontPixelWidth / 2
                                            anchors.topMargin:      ScreenTools.defaultFontPixelHeight / 4
                                            anchors.bottomMargin:   ScreenTools.defaultFontPixelHeight / 4
                                            spacing:                ScreenTools.defaultFontPixelWidth * 0.6

                                            QGCColoredImage {
                                                Layout.preferredWidth:  ScreenTools.defaultFontPixelHeight * 1.1
                                                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.1
                                                source:                 linkPopup.linkTypeIcon(object.linkType)
                                                color:                  linkCard.statusColor
                                                fillMode:               Image.PreserveAspectFit
                                                mipmap:                 true
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth:   true
                                                spacing:            1

                                                QGCLabel {
                                                    Layout.fillWidth:   true
                                                    text:               object.name
                                                    font.bold:          true
                                                    elide:              Text.ElideRight
                                                }
                                                QGCLabel {
                                                    Layout.fillWidth:   true
                                                    text: {
                                                        var sub = linkPopup.linkSubInfo(object)
                                                        return linkPopup.linkTypeName(object.linkType) + (sub ? " · " + sub : "")
                                                    }
                                                    font.pointSize:     ScreenTools.smallFontPointSize
                                                    opacity:            0.65
                                                    elide:              Text.ElideRight
                                                }
                                            }

                                            // Status chip
                                            Rectangle {
                                                Layout.preferredWidth:  statusChipLabel.implicitWidth + ScreenTools.defaultFontPixelWidth * 1.4
                                                Layout.preferredHeight: statusChipLabel.implicitHeight + ScreenTools.defaultFontPixelHeight * 0.3
                                                radius:                 height / 2
                                                color:                  Qt.rgba(linkCard.statusColor.r, linkCard.statusColor.g, linkCard.statusColor.b, 0.15)
                                                border.color:           linkCard.statusColor
                                                border.width:           1

                                                QGCLabel {
                                                    id:                 statusChipLabel
                                                    anchors.centerIn:   parent
                                                    text:               linkCard.statusText
                                                    font.pointSize:     ScreenTools.smallFontPointSize
                                                    font.bold:          true
                                                    color:              linkCard.statusColor
                                                }
                                            }

                                            // Inline 토글 버튼
                                            QGCButton {
                                                id:                     toggleButton
                                                Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 7
                                                text:                   linkCard.isConnected ? qsTr("해제") : qsTr("연결")
                                                font.bold:              true
                                                horizontalAlignment:    Text.AlignHCenter
                                                contentItem: QGCLabel {
                                                    text:                   toggleButton.text
                                                    font:                   toggleButton.font
                                                    horizontalAlignment:    Text.AlignHCenter
                                                    verticalAlignment:      Text.AlignVCenter
                                                    color:                  toggleButton._showHighlight
                                                                                ? qgcPal.buttonHighlightText
                                                                                : qgcPal.buttonText
                                                }
                                                onClicked: {
                                                    if (linkCard.isConnected) {
                                                        object.link.disconnect()
                                                        object.linkChanged()
                                                    } else {
                                                        QGroundControl.linkManager.createConnectedLink(object)
                                                    }
                                                }
                                            }
                                        }

                                    }
                                }
                            }
                        }
                    }

                    // WebRTC 시그널링 상태 메시지 (전역 — WebRTC 링크가 있을 때 자동 표시)
                    QGCLabel {
                        Layout.fillWidth:       true
                        horizontalAlignment:    Text.AlignRight
                        text:                   QGroundControl.linkManager.rtcStatusMessage || ""
                        font.pointSize:         ScreenTools.smallFontPointSize
                        opacity:                0.7
                        visible:                text !== ""
                    }

                    // 새 연결 추가
                    QGCButton {
                        Layout.alignment:   Qt.AlignLeft
                        text:               qsTr("+ 새 연결 추가")
                        onClicked: {
                            linkPopup.close()
                            mainWindow.showSettingsTool("Comm Links")  // language-independent nameKey, not a display string
                        }
                    }
                }
            }
        }

    Component {
        id: widgetControlComponent

        WidgetControlPanel {
        }
    }
}
