import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

ToolIndicatorPage {
    id:         control
    showExpand: true

    property var    linkConfigs:            QGroundControl.linkManager.linkConfigurations
    property bool   noLinks:                true
    property var    editingConfig:          null

    property var    _pal:           QGroundControl.globalPalette
    property real   _iconSize:      ScreenTools.defaultFontPixelHeight * 0.85
    property real   _rowVMargin:    ScreenTools.defaultFontPixelHeight * 0.5
    property real   _minPageWidth:  ScreenTools.defaultFontPixelWidth * 28

    function linkTypeIcon(linkType) {
        switch (linkType) {
            case LinkConfiguration.TypeSerial:    return "/InstrumentValueIcons/usb.svg"
            case LinkConfiguration.TypeUdp:       return "/InstrumentValueIcons/network.svg"
            case LinkConfiguration.TypeTcp:       return "/InstrumentValueIcons/network-transmit-receive.svg"
            case LinkConfiguration.TypeWebRTC:    return "/InstrumentValueIcons/cloud.svg"
        }
        return "/InstrumentValueIcons/link.svg"
    }

    function linkTypeName(linkType) {
        switch (linkType) {
            case LinkConfiguration.TypeSerial:    return qsTr("Serial")
            case LinkConfiguration.TypeUdp:       return qsTr("UDP")
            case LinkConfiguration.TypeTcp:       return qsTr("TCP")
            case LinkConfiguration.TypeWebRTC:    return qsTr("WebRTC")
        }
        return qsTr("Link")
    }

    function linkSubInfo(config) {
        var detail = ""
        switch (config.linkType) {
            case LinkConfiguration.TypeUdp:
                if (config.localPort > 0) {
                    detail = ":" + config.localPort                 // QGC's listen port
                } else if (config.hostList && config.hostList.length > 0) {
                    detail = config.hostList[0]                     // outgoing link: show the target host:port
                }
                break
            case LinkConfiguration.TypeWebRTC:
                detail = config.targetDroneId || ""
                break
        }
        return detail !== "" ? linkTypeName(config.linkType) + " · " + detail : linkTypeName(config.linkType)
    }

    Component.onCompleted: {
        for (var i = 0; i < linkConfigs.count; i++) {
            var linkConfig = linkConfigs.get(i)
            if (!linkConfig.dynamic && !linkConfig.isAutoConnect) {
                noLinks = false
                break
            }
        }
    }

    contentComponent: Component {
        SettingsGroupLayout {
            heading:        qsTr("Select Link to Connect")
            showDividers:   true

            QGCLabel {
                text:       qsTr("No Links Configured")
                visible:    noLinks
            }

            Repeater {
                model: linkConfigs

                delegate: Item {
                    id:                     linkRow
                    Layout.fillWidth:       true
                    Layout.minimumWidth:    control._minPageWidth
                    implicitHeight:         linkRowLayout.implicitHeight + (control._rowVMargin * 2)
                    visible:                !object.dynamic

                    property bool _connected: !!object.link

                    Rectangle {
                        id:             hoverRect
                        anchors.fill:   parent
                        radius:         ScreenTools.defaultFontPixelHeight / 3
                        color:          linkMouseArea.containsMouse ? control._pal.windowShadeLight : "transparent"

                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    RowLayout {
                        id:                 linkRowLayout
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                        anchors.leftMargin: ScreenTools.defaultFontPixelWidth / 2
                        anchors.rightMargin:ScreenTools.defaultFontPixelWidth / 2
                        anchors.verticalCenter: parent.verticalCenter
                        spacing:            ScreenTools.defaultFontPixelWidth

                        QGCColoredImage {
                            source:             control.linkTypeIcon(object.linkType)
                            color:              control._pal.text
                            width:              control._iconSize
                            height:             control._iconSize
                            sourceSize.height:  control._iconSize
                            fillMode:           Image.PreserveAspectFit
                            Layout.alignment:   Qt.AlignVCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth:   true
                            spacing:            0

                            QGCLabel {
                                Layout.fillWidth:   true
                                text:               object.name
                                font.bold:          true
                                elide:              Text.ElideRight
                            }

                            QGCLabel {
                                Layout.fillWidth:   true
                                text:               control.linkSubInfo(object)
                                visible:            text !== ""
                                font.pointSize:     ScreenTools.smallFontPointSize
                                color:              Qt.darker(control._pal.text, 1.5)
                                elide:              Text.ElideRight
                            }
                        }

                        // This page is only shown while disconnected, so there is no "connected"
                        // state to display — just a chevron hinting the row connects on click.
                        QGCColoredImage {
                            source:             "/InstrumentValueIcons/cheveron-right.svg"
                            color:              control._pal.text
                            width:              control._iconSize
                            height:             control._iconSize
                            sourceSize.height:  control._iconSize
                            fillMode:           Image.PreserveAspectFit
                            opacity:            linkMouseArea.containsMouse ? 1 : 0.5
                            Layout.alignment:   Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        id:             linkMouseArea
                        anchors.fill:   parent
                        hoverEnabled:   true
                        enabled:        !linkRow._connected
                        cursorShape:    enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                        onClicked: {
                            QGroundControl.linkManager.createConnectedLink(object)
                            mainWindow.closeIndicatorDrawer()
                        }
                    }
                }
            }
        }
    }

    expandedComponent: Component {
        ColumnLayout {
            spacing: ScreenTools.defaultFontPixelHeight / 2

            SettingsGroupLayout {
                RowLayout {
                    Layout.fillWidth:       true
                    Layout.minimumWidth:    control._minPageWidth
                    spacing:                ScreenTools.defaultFontPixelWidth

                    QGCColoredImage {
                        source:             "/InstrumentValueIcons/cog.svg"
                        color:              control._pal.text
                        width:              control._iconSize
                        height:             control._iconSize
                        sourceSize.height:  control._iconSize
                        fillMode:           Image.PreserveAspectFit
                        Layout.alignment:   Qt.AlignVCenter
                    }

                    QGCLabel {
                        Layout.fillWidth:   true
                        text:               qsTr("Communication Links")
                    }

                    QGCButton {
                        text: qsTr("Configure")

                        onClicked: {
                            mainWindow.showSettingsTool("Comm Links")  // language-independent nameKey, not a display string
                            mainWindow.closeIndicatorDrawer()
                        }
                    }
                }
            }
        }
    }
}
