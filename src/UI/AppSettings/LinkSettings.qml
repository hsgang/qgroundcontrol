import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

SettingsPage {
    id:                             _root
    property var    _linkManager: QGroundControl.linkManager
    property var    _siyi: QGroundControl.siyi
    property var    _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property real   _comboBoxPreferredWidth:    ScreenTools.defaultFontPixelWidth * 15
    property real   _layoutWidth:   ScreenTools.defaultFontPixelWidth * 42
    property var    _autoConnectSettings:    QGroundControl.settingsManager.autoConnectSettings

    SettingsGroupLayout {
        heading:    qsTr("Link Manager")

        LabelledButton {
            label:      qsTr("Add New Link")
            buttonText: qsTr("Add")

            onClicked: {
                var editingConfig = _linkManager.createConfiguration(ScreenTools.isSerialAvailable ? LinkConfiguration.TypeSerial : LinkConfiguration.TypeUdp, "")
                linkDialogComponent.createObject(mainWindow, { editingConfig: editingConfig, originalConfig: null }).open()
            }
        }
    }    

    SettingsGroupLayout {
        heading: qsTr("Added Link List")

        Repeater {
            id: linkRepeater
            model: _linkManager.linkConfigurations

            ColumnLayout {
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelWidth / 2

                RowLayout {
                    Layout.fillWidth:   true
                    visible:            !object.dynamic

                    QGCLabel {
                        Layout.fillWidth:   true
                        text:               object.name
                    }

                    QGCButton {
                        text:       object.link ? qsTr("Disconnect") : qsTr("Connect")
                        onClicked: {
                            if (object.link) {
                                object.link.disconnect()
                            } else {
                                _linkManager.createConnectedLink(object)
                            }
                        }
                    }

                    QGCButton {
                        iconSource:             "/InstrumentValueIcons/edit-pencil.svg"
                        visible:                !object.link
                        onClicked: {
                            var editingConfig = _linkManager.startConfigurationEditing(object)
                            linkDialogComponent.createObject(mainWindow, { editingConfig: editingConfig, originalConfig: object }).open()
                        }
                    }

                    QGCButton {
                        iconSource:             "/InstrumentValueIcons/trash.svg"
                        visible:                !object.link
                        textColor:              qgcPal.colorRed
                        onClicked:  mainWindow.showMessageDialog(
                                        qsTr("Delete Link"),
                                        qsTr("Are you sure you want to delete '%1'?").arg(object.name),
                                        Dialog.Ok | Dialog.Cancel,
                                        function () {
                                            _linkManager.removeConfiguration(object)
                                        })
                    }
                    
                }

                Rectangle {
                    visible:    object.link && _activeVehicle && _activeVehicle.loadProgress > 0
                    width:      parent.width
                    height:     ScreenTools.defaultFontPixelHeight / 4
                    color:      qgcPal.windowShade
                    radius:     height / 2

                    Rectangle {
                        anchors.left: parent.left
                        height:         parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        width:          _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
                        color:          qgcPal.colorGreen
                        radius:         height / 2
                    }
                }

                QGCLabel {
                    visible: object.link !== null && object.link.rttMs !== undefined
                    text: object.link ? qsTr("RTT %1 ms").arg(object.link.rttMs) : ""
                    font.pointSize: ScreenTools.smallFontPointSize
                }
            }
        }

        QGCLabel {
            visible: linkRepeater.count < 1
            text: qsTr("No Links Configured")
        }
    }

    SettingsGroupLayout {
        heading: qsTr("NMEA GPS")
        visible: QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.visible && QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.visible

        LabelledComboBox {
            id: nmeaPortCombo
            label: qsTr("Device")

            model: ListModel {}

            onActivated: (index) => {
                if (index !== -1) {
                    QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.value = comboBox.textAt(index);
                }
            }

            Component.onCompleted: {
                var model = []

                model.push(qsTr("Disabled"))
                model.push(qsTr("UDP Port"))

                if (QGroundControl.linkManager.serialPorts.length === 0) {
                    model.push(qsTr("Serial <none available>"))
                } else {
                    for (var i in QGroundControl.linkManager.serialPorts) {
                        model.push(QGroundControl.linkManager.serialPorts[i])
                    }
                }
                nmeaPortCombo.model = model

                const index = nmeaPortCombo.comboBox.find(QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.valueString);
                nmeaPortCombo.currentIndex = index;
            }
        }

        LabelledComboBox {
            id: nmeaBaudCombo
            visible: (nmeaPortCombo.currentText !== "UDP Port") && (nmeaPortCombo.currentText !== "Disabled")
            label: qsTr("Baudrate")
            model: QGroundControl.linkManager.serialBaudRates

            onActivated: (index) => {
                if (index !== -1) {
                    QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.value = parseInt(comboBox.textAt(index));
                }
            }

            Component.onCompleted: {
                const index = nmeaBaudCombo.comboBox.find(QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.valueString);
                nmeaBaudCombo.currentIndex = index;
            }
        }

        LabelledFactTextField {
            visible: nmeaPortCombo.currentText === "UDP Port"
            label: qsTr("NMEA stream UDP port")
            fact: QGroundControl.settingsManager.autoConnectSettings.nmeaUdpPort
        }
    }

    // SettingsGroupLayout {
    //     heading:    qsTr("Auto Connect")

    //     Repeater {
    //         id: autoConnectRepeater

    //         model: [
    //             _autoConnectSettings.autoConnectPixhawk,
    //             _autoConnectSettings.autoConnectSiKRadio,
    //             _autoConnectSettings.autoConnectUDP,
    //         ]

    //         property var names: [
    //             qsTr("USB port"),
    //             qsTr("RF Telemetry"),
    //             qsTr("UDP Network")
    //         ]

    //         FactCheckBoxSlider {
    //             Layout.fillWidth:   true
    //             text:               autoConnectRepeater.names[index]
    //             fact:               modelData
    //             visible:            modelData.visible
    //         }
    //     }
    // }

    SettingsGroupLayout {
        heading:    qsTr("SIYI Transmitter")

        RowLayout{
            QGCTextField {
                id: ipInput
                Layout.fillWidth: true
                text:   _siyi.transmitter.ip
            }
            QGCButton {
                text: qsTr("Change IP")
                enabled:   ipInput.text !== _siyi.transmitter.ip
                onClicked: {
                    _siyi.transmitter.analyzeIp(ipInput.text)
                }
            }
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
                    // If it was edited, it's no longer "dynamic"
                    editingConfig.dynamic = false
                    _linkManager.endCreateConfiguration(editingConfig)
                }
            }

            onRejected: _linkManager.cancelConfigurationEditing(editingConfig)

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight / 2
                width: _layoutWidth

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

                Binding {
                    target: nameField
                    property: "text"
                    value: (originalConfig == null) ? (
                           editingConfig.linkType === LinkConfiguration.TypeSerial ?
                           qsTr("Serial_") + linkSettingsLoader.subEditConfig.portDisplayName +"_" + linkSettingsLoader.subEditConfig.baud.toString() :
                           (editingConfig.linkType === LinkConfiguration.TypeUdp ?
                           qsTr("UDP_") + linkSettingsLoader.subEditConfig.hostList[0] :
                           (editingConfig.linkType === LinkConfiguration.TypeTcp ?
                           qsTr("TCP_") + linkSettingsLoader.subEditConfig.host + ":" + linkSettingsLoader.subEditConfig.port.toString() :
                           (editingConfig.linkType === LinkConfiguration.TypeWebRTC ?
                           qsTr("RTC_") + linkSettingsLoader.subEditConfig.targetDroneId :
                           qsTr("Other"))))
                        ) : editingConfig.name
                }

                // QGCCheckBoxSlider {
                //     Layout.fillWidth:   true
                //     text:               qsTr("Automatically Connect on Start")
                //     checked:            editingConfig.autoConnect
                //     onCheckedChanged:   editingConfig.autoConnect = checked
                // }

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
                    comboBoxPreferredWidth: _comboBoxPreferredWidth

                    onActivated: (index) => {
                        if (index !== editingConfig.linkType) {
                            // Save current name
                            var name = nameField.text
                            // Create new link configuration
                            editingConfig = _linkManager.createConfiguration(index, name)
                        }
                    }
                }

                Loader {
                    id:     linkSettingsLoader
                    source: subEditConfig && subEditConfig.settingsURL ? subEditConfig.settingsURL : ""
                    asynchronous: true

                    property var subEditConfig:         editingConfig
                    property int _firstColumnWidth:     ScreenTools.defaultFontPixelWidth * 12
                    property int _secondColumnWidth:    ScreenTools.defaultFontPixelWidth * 30
                    property int _rowSpacing:           ScreenTools.defaultFontPixelHeight / 2
                    property int _colSpacing:           ScreenTools.defaultFontPixelWidth / 2
                    property real _columnLayoutWidth:   _layoutWidth

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
