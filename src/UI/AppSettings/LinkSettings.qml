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
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls
import SiYi.Object

SettingsPage {
    property var    _linkManager: QGroundControl.linkManager
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
                    QGCColoredImage {
                        height:                 ScreenTools.minTouchPixels
                        width:                  height
                        sourceSize.height:      height
                        fillMode:               Image.PreserveAspectFit
                        mipmap:                 true
                        smooth:                 true
                        color:                  qgcPalEdit.text
                        source:                 "/res/pencil.svg"
                        visible:                !object.link

                        QGCPalette {
                            id: qgcPalEdit
                            colorGroupEnabled: parent.enabled
                        }

                        QGCMouseArea {
                            fillItem: parent
                            onClicked: {
                                var editingConfig = _linkManager.startConfigurationEditing(object)
                                linkDialogComponent.createObject(mainWindow, { editingConfig: editingConfig, originalConfig: object }).open()
                            }
                        }
                    }
                    QGCColoredImage {
                        height:                 ScreenTools.minTouchPixels
                        width:                  height
                        sourceSize.height:      height
                        fillMode:               Image.PreserveAspectFit
                        mipmap:                 true
                        smooth:                 true
                        color:                  qgcPalDelete.text
                        source:                 "/res/TrashDelete.svg"
                        visible:                !object.link

                        QGCPalette {
                            id: qgcPalDelete
                            colorGroupEnabled: parent.enabled
                        }

                        QGCMouseArea {
                            fillItem:   parent
                            onClicked:  mainWindow.showMessageDialog(
                                            qsTr("Delete Link"),
                                            qsTr("Are you sure you want to delete '%1'?").arg(object.name),
                                            Dialog.Ok | Dialog.Cancel,
                                            function () {
                                                _linkManager.removeConfiguration(object)
                                            })
                        }
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

    SettingsGroupLayout {
        heading:    qsTr("Auto Connect")

        Repeater {
            id: autoConnectRepeater

            model: [
                _autoConnectSettings.autoConnectPixhawk,
                _autoConnectSettings.autoConnectSiKRadio,
                _autoConnectSettings.autoConnectUDP,
            ]

            property var names: [
                qsTr("USB port"),
                qsTr("RF Telemetry"),
                qsTr("UDP Network")
            ]

            FactCheckBoxSlider {
                Layout.fillWidth:   true
                text:               autoConnectRepeater.names[index]
                fact:               modelData
                visible:            modelData.visible
            }
        }
    }

    SettingsGroupLayout {
        heading:    qsTr("SIYI Transmitter")

        RowLayout{
            QGCTextField {
                id: ipInput
                Layout.fillWidth: true
                text:   SiYi.transmitter.ip
            }
            QGCButton {
                text: qsTr("Change IP")
                enabled:   ipInput.text !== SiYi.transmitter.ip
                onClicked: {
                    SiYi.transmitter.analyzeIp(ipInput.text)
                }
            }
        }
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
                    label:                  qsTr("모델")
                    model:                  ["Generic","AMP1600","AMP1150","AMP1100","AMP850"]
                    comboBoxPreferredWidth: _comboBoxPreferredWidth

                    Component.onCompleted: {
                        let index = model.indexOf(editingConfig.model);
                        comboBox.currentIndex = index !== -1 ? index : 0;
                    }

                    onActivated: (index) => {
                        editingConfig.model = model[index]; // 선택된 값 반영
                    }
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
                    //source: subEditConfig.settingsURL
                    source: subEditConfig && subEditConfig.settingsURL ? subEditConfig.settingsURL : ""

                    property var subEditConfig:         editingConfig
                    property int _firstColumnWidth:     ScreenTools.defaultFontPixelWidth * 12
                    property int _secondColumnWidth:    ScreenTools.defaultFontPixelWidth * 30
                    property int _rowSpacing:           ScreenTools.defaultFontPixelHeight / 2
                    property int _colSpacing:           ScreenTools.defaultFontPixelWidth / 2
                    property real _columnLayoutWidth:   _layoutWidth
                }
            }
        }
    }
}
