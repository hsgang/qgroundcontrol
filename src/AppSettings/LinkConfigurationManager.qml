import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

SettingsGroupLayout {
    id: _root
    heading: qsTr("Links")

    property var _linkManager: QGroundControl.linkManager

    QGCPalette { id: qgcPal }

    property real _iconSize: ScreenTools.defaultFontPixelHeight * 0.85

    // Link type icon / name / sub-info, matching the connect rows on
    // MainStatusIndicatorOfflinePage so both surfaces describe links identically.
    function _linkTypeIcon(linkType) {
        switch (linkType) {
        case LinkConfiguration.TypeSerial: return "/InstrumentValueIcons/usb.svg"
        case LinkConfiguration.TypeUdp:    return "/InstrumentValueIcons/network.svg"
        case LinkConfiguration.TypeTcp:    return "/InstrumentValueIcons/network-transmit-receive.svg"
        case LinkConfiguration.TypeWebRTC: return "/InstrumentValueIcons/cloud.svg"
        }
        return "/InstrumentValueIcons/link.svg"
    }
    function _linkTypeName(linkType) {
        switch (linkType) {
        case LinkConfiguration.TypeSerial: return qsTr("Serial")
        case LinkConfiguration.TypeUdp:    return qsTr("UDP")
        case LinkConfiguration.TypeTcp:    return qsTr("TCP")
        case LinkConfiguration.TypeWebRTC: return qsTr("WebRTC")
        }
        return qsTr("Link")
    }
    function _linkSubInfo(config) {
        var detail = ""
        switch (config.linkType) {
        case LinkConfiguration.TypeUdp:
            if (config.localPort > 0) {
                detail = ":" + config.localPort                 // QGC's listen port
            } else if (config.hostList && config.hostList.length > 0) {
                detail = config.hostList[0]                     // outgoing link: target host:port
            }
            break
        case LinkConfiguration.TypeWebRTC:
            detail = config.targetDroneId || ""
            break
        }
        return detail !== "" ? _linkTypeName(config.linkType) + " · " + detail : _linkTypeName(config.linkType)
    }

    QGCLabel {
        Layout.fillWidth:   true
        visible:            _linkCount === 0
        text:               qsTr("No links configured. Add a link below to connect.")
        color:              Qt.darker(qgcPal.text, 1.5)
        wrapMode:           Text.WordWrap
        font.pointSize:     ScreenTools.smallFontPointSize

        // Count the non-dynamic (user-configured) links so the empty hint only
        // shows when there is nothing to manage.
        property int _linkCount: {
            var count = 0
            for (var i = 0; i < _linkManager.linkConfigurations.count; ++i) {
                if (!_linkManager.linkConfigurations.get(i).dynamic) {
                    count++
                }
            }
            return count
        }
    }

    Repeater {
        model: _linkManager.linkConfigurations

        // Icon + name + "Type · detail" sub-info, mirroring the offline connect page.
        RowLayout {
            Layout.fillWidth:   true
            visible:            !object.dynamic
            spacing:            ScreenTools.defaultFontPixelWidth

            property bool _connected: object.link && object.link.linkConnected

            QGCColoredImage {
                source:             _linkTypeIcon(object.linkType)
                color:              qgcPal.text
                width:              _iconSize
                height:             _iconSize
                sourceSize.height:  _iconSize
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
                    text:               _linkSubInfo(object)
                    visible:            text !== ""
                    font.pointSize:     ScreenTools.smallFontPointSize
                    color:              Qt.darker(qgcPal.text, 1.5)
                    elide:              Text.ElideRight
                }
            }

            QGCButton {
                text:       _connected ? qsTr("Disconnect") : qsTr("Connect")
                primary:    !_connected
                onClicked: {
                    if (object.link) {
                        object.link.disconnect()
                    } else {
                        _linkManager.createConnectedLink(object)
                    }
                }
            }

            // Secondary actions (edit / delete) live in an overflow menu so the
            // row exposes a single primary button instead of mixed icons + button.
            QGCColoredImage {
                height:                 ScreenTools.minTouchPixels
                width:                  height
                sourceSize.height:      height
                fillMode:               Image.PreserveAspectFit
                mipmap:                 true
                smooth:                 true
                color:                  qgcPal.text
                source:                 "/InstrumentValueIcons/dots-horizontal-triple.svg"
                Layout.alignment:       Qt.AlignVCenter

                QGCMouseArea {
                    fillItem:   parent
                    onClicked:  actionMenu.popup()
                }

                QGCMenu {
                    id: actionMenu

                    QGCMenuItem {
                        text:        qsTr("Edit")
                        enabled:     !object.link
                        onTriggered: {
                            var editingConfig = _linkManager.startConfigurationEditing(object)
                            linkDialogFactory.open({ editingConfig: editingConfig, originalConfig: object })
                        }
                    }
                    QGCMenuItem {
                        text:        qsTr("Delete")
                        onTriggered: QGroundControl.showMessageDialog(
                                        _root,
                                        qsTr("Delete Link"),
                                        qsTr("Are you sure you want to delete '%1'?").arg(object.name),
                                        Dialog.Ok | Dialog.Cancel,
                                        function () {
                                            _linkManager.removeConfiguration(object)
                                        })
                    }
                }
            }
        }
    }

    LabelledButton {
        label:      qsTr("Add New Link")
        buttonText: qsTr("Add")

        onClicked: {
            var editingConfig = _linkManager.createConfiguration(ScreenTools.isSerialAvailable ? LinkConfiguration.TypeSerial : LinkConfiguration.TypeUdp, "")
            linkDialogFactory.open({ editingConfig: editingConfig, originalConfig: null })
        }
    }

    QGCPopupDialogFactory {
        id: linkDialogFactory

        dialogComponent: linkDialogComponent
    }

    Component {
        id: linkDialogComponent

        QGCPopupDialog {
            title:                  originalConfig ? qsTr("Edit Link") : qsTr("Add New Link")
            buttons:                Dialog.Save | Dialog.Cancel
            acceptButtonEnabled:    nameField.text !== ""

            property var originalConfig
            property var editingConfig

            onAccepted: {
                linkSettingsLoader.item.saveSettings()
                editingConfig.name = nameField.text
                if (originalConfig) {
                    _linkManager.endConfigurationEditing(originalConfig, editingConfig)
                } else {
                    editingConfig.dynamic = false
                    _linkManager.endCreateConfiguration(editingConfig)
                }
            }

            onRejected: _linkManager.cancelConfigurationEditing(editingConfig)

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight / 2

                RowLayout {
                    Layout.fillWidth:   true
                    spacing:            ScreenTools.defaultFontPixelWidth

                    QGCLabel { text: qsTr("Name") }
                    QGCTextField {
                        id:                 nameField
                        Layout.fillWidth:   true
                        text:               editingConfig.name
                        placeholderText:    qsTr("Enter name")
                    }
                }

                QGCCheckBoxSlider {
                    Layout.fillWidth:   true
                    text:               qsTr("Automatically Connect on Start")
                    checked:            editingConfig.autoConnect
                    onCheckedChanged:   editingConfig.autoConnect = checked
                }

                QGCCheckBoxSlider {
                    Layout.fillWidth:   true
                    text:               qsTr("High Latency")
                    checked:            editingConfig.highLatency
                    onCheckedChanged:   editingConfig.highLatency = checked
                }

                LabelledComboBox {
                    label:                  qsTr("Type")
                    enabled:                originalConfig == null
                    model:                  _linkManager.linkTypeStrings
                    Component.onCompleted:  comboBox.currentIndex = editingConfig.linkType

                    onActivated: (index) => {
                        if (index !== editingConfig.linkType) {
                            var name = nameField.text
                            editingConfig = _linkManager.createConfiguration(index, name)
                        }
                    }
                }

                Loader {
                    id:     linkSettingsLoader
                    source: editingConfig && editingConfig.settingsURL ? editingConfig.settingsURL : ""
                    asynchronous: true

                    property var subEditConfig:         editingConfig
                    property int _firstColumnWidth:     ScreenTools.defaultFontPixelWidth * 12
                    property int _secondColumnWidth:    ScreenTools.defaultFontPixelWidth * 30
                    property int _rowSpacing:           ScreenTools.defaultFontPixelHeight / 2
                    property int _colSpacing:           ScreenTools.defaultFontPixelWidth / 2

                    onStatusChanged: {
                        if (status === Loader.Error) {
                            console.warn("Failed to load link settings page:", source)
                        }
                    }
                }
            }
        }
    }
}
