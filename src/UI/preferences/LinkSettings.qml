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
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.FactSystem

import SiYi.Object

SettingsPage {
    property var    _linkManager: QGroundControl.linkManager
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
                    enabled:                !object.link

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
                    enabled:                !object.link

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
        }

        QGCLabel {
            visible: linkRepeater.count < 1
            text: qsTr("No Links Configured")
        }
    }

    // SettingsGroupLayout {
    //     heading:    qsTr("Added Link List")

    //     Repeater {
    //         id: linkRepeater
    //         model: _linkManager.linkConfigurations

    //         RowLayout {
    //             Layout.fillWidth:   true
    //             visible:            !object.dynamic

    //             QGCButton {
    //                 text:       object.link ? qsTr("Disconnect") : qsTr("Connect")
    //                 onClicked: {
    //                     if (object.link) {
    //                         object.link.disconnect()
    //                         object.linkChanged()
    //                     } else {
    //                         _linkManager.createConnectedLink(object)
    //                     }
    //                 }
    //             }

    //             QGCLabel {
    //                 Layout.fillWidth:   true
    //                 text:               object.name
    //             }

    //             QGCButton {
    //                 text:       qsTr("Edit") //object.link ? qsTr("Disconnect") : qsTr("Connect")
    //                 enabled:    !object.link
    //                 onClicked: {
    //                     var editingConfig = _linkManager.startConfigurationEditing(object)
    //                     linkDialogComponent.createObject(mainWindow, { editingConfig: editingConfig, originalConfig: object }).open()
    //                 }
    //             }

    //             QGCButton {
    //                 text:       qsTr("Delete")//object.link ? qsTr("Disconnect") : qsTr("Connect")
    //                 enabled:    !object.link
    //                 onClicked:  mainWindow.showMessageDialog(
    //                                 qsTr("Delete Link"),
    //                                 qsTr("Are you sure you want to delete '%1'?").arg(object.name),
    //                                 Dialog.Ok | Dialog.Cancel,
    //                                 function () {
    //                                     _linkManager.removeConfiguration(object)
    //                                 })
    //             }
    //         }
    //     }

    //     QGCLabel {
    //         visible: linkRepeater.count < 1
    //         text: qsTr("No Links Configured")
    //     }
    // }

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
                           qsTr("Other")))
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
