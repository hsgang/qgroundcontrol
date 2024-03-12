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
import QGroundControl.FactControls

SettingsPage {
    property var    _linkManager: QGroundControl.linkManager
    property real   _comboBoxPreferredWidth:    ScreenTools.defaultFontPixelWidth * 15
    property real   _layoutWidth:   ScreenTools.defaultFontPixelWidth * 42
    property var    autoConnectSettings:    QGroundControl.settingsManager.autoConnectSettings

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
        heading:    qsTr("Added Link List")

        Repeater {
            model: _linkManager.linkConfigurations

            RowLayout {
                Layout.fillWidth:   true
                visible:            !object.dynamic

                QGCButton {
                    text:       object.link ? qsTr("Disconnect") : qsTr("Connect")
                    onClicked: {
                        if (object.link) {
                            object.link.disconnect()
                            object.linkChanged()
                        } else {
                            _linkManager.createConnectedLink(object)
                        }
                    }
                }

                QGCLabel {
                    Layout.fillWidth:   true
                    text:               object.name
                }

                QGCButton {
                    text:       qsTr("Edit") //object.link ? qsTr("Disconnect") : qsTr("Connect")
                    enabled:    !object.link
                    onClicked: {
                        var editingConfig = _linkManager.startConfigurationEditing(object)
                        linkDialogComponent.createObject(mainWindow, { editingConfig: editingConfig, originalConfig: object }).open()
                    }
                }

                QGCButton {
                    text:       qsTr("Delete")//object.link ? qsTr("Disconnect") : qsTr("Connect")
                    enabled:    !object.link
                    onClicked:  mainWindow.showMessageDialog(
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

    SettingsGroupLayout {
        heading:    qsTr("Auto Connect")

        Repeater {
            id: autoConnectRepeater

            model: [
                autoConnectSettings.autoConnectPixhawk,
                autoConnectSettings.autoConnectSiKRadio,
                autoConnectSettings.autoConnectUDP,
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

    Component {
        id: linkDialogComponent

        QGCPopupDialog {
            title:          originalConfig ? qsTr("Edit Link") : qsTr("Add New Link")
            buttons:        Dialog.Save | Dialog.Cancel
            acceptAllowed:  nameField.text !== ""

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
                    source: subEditConfig.settingsURL

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


// Rectangle {
//     id:                 _linkRoot
//     color:              qgcPal.window
//     anchors.fill:       parent
//     anchors.margins:    ScreenTools.defaultFontPixelWidth

//     property real   _borderWidth:       1 //ScreenTools.defaultFontPixelWidth * 0.2
//     property real   _margins:           ScreenTools.defaultFontPixelWidth

//     property var _currentSelection:     null
//     property int _firstColumnWidth:     ScreenTools.defaultFontPixelWidth * 12
//     property int _secondColumnWidth:    ScreenTools.defaultFontPixelWidth * 30
//     property int _rowSpacing:           ScreenTools.defaultFontPixelHeight / 2
//     property int _colSpacing:           ScreenTools.defaultFontPixelWidth / 2

//     QGCPalette {
//         id:                 qgcPal
//         colorGroupEnabled:  enabled
//     }

//     function openCommSettings(originalLinkConfig) {
//         settingsLoader.originalLinkConfig = originalLinkConfig
//         if (originalLinkConfig) {
//             // Editing existing link config
//             settingsLoader.editingConfig = QGroundControl.linkManager.startConfigurationEditing(originalLinkConfig)
//         } else {
//             // Create new link configuration
//             settingsLoader.editingConfig = QGroundControl.linkManager.createConfiguration(ScreenTools.isSerialAvailable ? LinkConfiguration.TypeSerial : LinkConfiguration.TypeUdp, "")
//         }
//         settingsLoader.sourceComponent = commSettings
//     }

//     Component.onDestruction: {
//         if (settingsLoader.sourceComponent) {
//             settingsLoader.sourceComponent = null
//             QGroundControl.linkManager.cancelConfigurationEditing(settingsLoader.editingConfig)
//         }
//     }

//     Rectangle {
//         anchors.top:            parent.top
//         anchors.horizontalCenter: parent.horizontalCenter
//         height:                 parent.height - buttonRow.height - (_margins * 2)
//         width:                  buttonRow.width
//         color:                  qgcPal.window
//         border.color:           qgcPal.windowShade
//         border.width:           _borderWidth
//         radius:                 _margins
//         Layout.fillWidth:       true

//         QGCFlickable {
//             clip:               true
//             anchors.top:        parent.top
//             anchors.horizontalCenter: parent.horizontalCenter
//             anchors.margins:    _margins
//             width:              parent.width
//             height:             parent.height - buttonRow.height - (_margins * 4)
//             contentHeight:      settingsColumn.height
//             contentWidth:       _linkRoot.width
//             flickableDirection: Flickable.VerticalFlick

//             Column {
//                 id:                 settingsColumn
//                 width:              buttonRow.width + (_margins * 2)
//                 anchors.margins:    ScreenTools.defaultFontPixelWidth
//                 spacing:            ScreenTools.defaultFontPixelHeight / 2
//                 Repeater {
//                     model: QGroundControl.linkManager.linkConfigurations
//                     delegate: QGCButton {
//                         anchors.horizontalCenter:   settingsColumn.horizontalCenter
//                         width:                      settingsColumn.width * 0.7
//                         text:                       object.name + (object.link ? " (" + qsTr("Connected") + ")" : "")
//                         autoExclusive:              true
//                         visible:                    !object.dynamic
//                         onClicked: {
//                             checked = true
//                             _currentSelection = object
//                             //console.log("clicked", object, object.link)
//                         }
//                     }
//                 }
//             }
//         } // qgcflickable

//     } //rectangle

//     Row {
//         id:                 buttonRow
//         spacing:            ScreenTools.defaultFontPixelWidth
//         anchors.bottom:     parent.bottom
//         anchors.margins:    ScreenTools.defaultFontPixelWidth
//         anchors.horizontalCenter: parent.horizontalCenter
//         QGCButton {
//             text:       qsTr("Delete")
//             enabled:    _currentSelection && !_currentSelection.dynamic &&!_currentSelection.link
//             onClicked:  deleteDialog.visible = true

//             MessageDialog {
//                 id:         deleteDialog
//                 visible:    false
//                 icon:       StandardIcon.Warning
//                 standardButtons: StandardButton.Yes | StandardButton.No
//                 title:      qsTr("Remove Link Configuration")
//                 text:       _currentSelection ? qsTr("Remove %1. Is this really what you want?").arg(_currentSelection.name) : ""

//                 onYes: {
//                     QGroundControl.linkManager.removeConfiguration(_currentSelection)
//                     _currentSelection = null
//                     deleteDialog.visible = false
//                 }
//                 onNo: deleteDialog.visible = false
//             }
//         }
//         QGCButton {
//             text:       qsTr("Edit")
//             enabled:    _currentSelection && !_currentSelection.link
//             onClicked:  _linkRoot.openCommSettings(_currentSelection)
//         }
//         QGCButton {
//             text:       qsTr("Add")
//             onClicked:  _linkRoot.openCommSettings(null)
//         }
//         QGCButton {
//             text:       qsTr("Connect")
//             enabled:    _currentSelection && !_currentSelection.link
//             onClicked:  QGroundControl.linkManager.createConnectedLink(_currentSelection)
//         }
//         QGCButton {
//             text:       qsTr("Disconnect")
//             enabled:    _currentSelection && _currentSelection.link
//             onClicked:  {
//                 _currentSelection.link.disconnect()
//                 _currentSelection.linkChanged()
//             }
//         }
//         QGCButton {
//             text:       qsTr("MockLink Options")
//             visible:    _currentSelection && _currentSelection.link && _currentSelection.link.isMockLink
//             onClicked:  mockLinkOptionDialog.open()

//             MockLinkOptionsDlg {
//                 id:     mockLinkOptionDialog
//                 link:   _currentSelection ? _currentSelection.link : undefined
//             }
//         }
//     }

//     Loader {
//         id:             settingsLoader
//         anchors.fill:   parent
//         visible:        sourceComponent ? true : false

//         property var originalLinkConfig:    null
//         property var editingConfig:      null
//     }

//     //---------------------------------------------
//     // Comm Settings
//     Component {
//         id: commSettings
//         Rectangle {
//             id:             settingsRect
//             color:          qgcPal.window
//             anchors.fill:   parent
//             anchors.horizontalCenter:   parent.horizontalCenter
//             property real   _panelWidth:    width * 0.8

//             QGCFlickable {
//                 id:                 settingsFlick
//                 clip:               true
//                 anchors.fill:       parent
//                 anchors.margins:    ScreenTools.defaultFontPixelWidth
//                 contentHeight:      mainLayout.height
//                 contentWidth:       mainLayout.width

//                 ColumnLayout {
//                     id:         mainLayout
//                     spacing:    _rowSpacing

//                     QGCGroupBox {
//                         title: originalLinkConfig ? qsTr("Edit Link Configuration Settings") : qsTr("Create New Link Configuration")

//                         ColumnLayout {
//                             spacing: _rowSpacing

//                             GridLayout {
//                                 columns:        2
//                                 columnSpacing:  _colSpacing
//                                 rowSpacing:     _rowSpacing

//                                 QGCLabel { text: qsTr("Name") }
//                                 QGCTextField {
//                                     id:                     nameField
//                                     Layout.preferredWidth:  _secondColumnWidth
//                                     Layout.fillWidth:       true
//                                     text:                   editingConfig.name
//                                     placeholderText:        qsTr("Enter name")
//                                 }

//                                 QGCCheckBox {
//                                     Layout.columnSpan:  2
//                                     text:               qsTr("Automatically Connect on Start")
//                                     checked:            editingConfig.autoConnect
//                                     onCheckedChanged:   editingConfig.autoConnect = checked
//                                 }

//                                 QGCCheckBox {
//                                     Layout.columnSpan:  2
//                                     text:               qsTr("High Latency")
//                                     checked:            editingConfig.highLatency
//                                     onCheckedChanged:   editingConfig.highLatency = checked
//                                 }

//                                 QGCLabel { text: qsTr("Type") }
//                                 QGCComboBox {
//                                     Layout.preferredWidth:  _secondColumnWidth
//                                     Layout.fillWidth:       true
//                                     enabled:                originalLinkConfig == null
//                                     model:                  QGroundControl.linkManager.linkTypeStrings
//                                     currentIndex:           editingConfig.linkType

//                                     onActivated: {
//                                         if (index !== editingConfig.linkType) {
//                                             // Save current name
//                                             var name = nameField.text
//                                             // Create new link configuration
//                                             editingConfig = QGroundControl.linkManager.createConfiguration(index, name)
//                                         }
//                                     }
//                                 }
//                             }

//                             Loader {
//                                 id:     linksettingsLoader
//                                 source: subEditConfig.settingsURL

//                                 property var subEditConfig: editingConfig
//                             }
//                         }
//                     }

//                     RowLayout {
//                         Layout.alignment:   Qt.AlignHCenter
//                         spacing:            _colSpacing

//                         QGCButton {
//                             width:      ScreenTools.defaultFontPixelWidth * 10
//                             text:       qsTr("OK")
//                             enabled:    nameField.text !== ""

//                             onClicked: {
//                                 // Save editing
//                                 linksettingsLoader.item.saveSettings()
//                                 editingConfig.name = nameField.text
//                                 settingsLoader.sourceComponent = null
//                                 if (originalLinkConfig) {
//                                     QGroundControl.linkManager.endConfigurationEditing(originalLinkConfig, editingConfig)
//                                 } else {
//                                     // If it was edited, it's no longer "dynamic"
//                                     editingConfig.dynamic = false
//                                     QGroundControl.linkManager.endCreateConfiguration(editingConfig)
//                                 }
//                             }
//                         }

//                         QGCButton {
//                             width:      ScreenTools.defaultFontPixelWidth * 10
//                             text:       qsTr("Cancel")
//                             onClicked: {
//                                 settingsLoader.sourceComponent = null
//                                 QGroundControl.linkManager.cancelConfigurationEditing(settingsLoader.editingConfig)
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }
// }
