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
import Qt.labs.qmlmodels

import QGroundControl
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.Controllers
import QGroundControl.ScreenTools
import QGroundControl.FactSystem
import QGroundControl.FactControls

AnalyzePage {
    id:                 cloudUploadPage
    pageComponent:      pageComponent
    pageDescription:    qsTr("Cloud Upload Page")

    property real _margin:          ScreenTools.defaultFontPixelWidth
    property real _butttonWidth:    ScreenTools.defaultFontPixelWidth * 10
    property var _isSignIn:         QGroundControl.cloudManager.signedIn

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    Component {
        id: pageComponent

        RowLayout {
            width:  availableWidth
            height: availableHeight

            function loadFileList() {
                var dir = dirCombobox.currentText
                QGroundControl.cloudManager.loadDirFile(dir)
            }

            ColumnLayout{
                Layout.fillWidth: true
                Layout.fillHeight: true

                QGCLabel{
                    visible: !_isSignIn
                    color:  qgcPal.colorRed
                    text: qsTr("클라우드 서비스 계정이 활성화되지 않았습니다.")
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color:  qgcPal.groupBorder
                }

                RowLayout{
                    Layout.fillWidth: true

                    QGCLabel{
                        text:qsTr("Upload Directory")
                    }
                    QGCComboBox{
                        id: dirCombobox
                        model: ["Sensors","Missions","Telemetry"]
                        onCurrentTextChanged:{
                            loadFileList()
                        }
                    }
                    QGCButton {
                        Layout.alignment: Qt.AlignRight
                        text: qsTr("Reload")
                        onClicked: {
                            QGroundControl.cloudManager.loadDirFile(dirCombobox.currentText)
                        }
                    }
                }

                Rectangle {
                    //width:  parent.width
                    Layout.fillWidth: true
                    height: 1
                    color:  qgcPal.groupBorder
                }

                RowLayout{
                    id: progressBarLayout
                    property real value : QGroundControl.cloudManager.uploadProgressValue
                    visible: value > 0 && value < 100

                    QGCLabel{
                        text:qsTr("Uploading ") + progressBarLayout.value.toFixed(1) + "%"
                    }
                    ProgressBar {
                        Layout.fillWidth: true
                        height: ScreenTools.defaultFontPixelWidth
                        from: 0
                        to: 100
                        value: progressBarLayout.value
                    }
                }

                QGCFlickable {
                    Layout.fillWidth:   true
                    Layout.fillHeight:  true
                    contentWidth:       columnLayout.width
                    contentHeight:      columnLayout.height
                    // contentWidth:       gridLayout.width
                    // contentHeight:      gridLayout.height

                    // GridLayout {
                    //     id:                 gridLayout
                    //     rows:               QGroundControl.cloudManager.fileList.count + 1
                    //     columns:            3
                    //     flow:               GridLayout.TopToBottom
                    //     columnSpacing:      ScreenTools.defaultFontPixelWidth
                    //     rowSpacing:         0

                    //     QGCLabel {
                    //         text: qsTr("File")
                    //     }
                    //     Repeater {
                    //         model: QGroundControl.cloudManager.fileList

                    //         QGCLabel {
                    //             text: modelData["fileName"]
                    //         }
                    //     }

                    //     QGCLabel {
                    //         text: qsTr("Size")
                    //     }
                    //     Repeater {
                    //         model: QGroundControl.cloudManager.fileList

                    //         QGCLabel {
                    //             text: "[" + modelData["fileSize"] + "]"
                    //         }
                    //     }

                    //     QGCLabel {
                    //         text: qsTr("Upload")
                    //     }
                    //     Repeater {
                    //         model: QGroundControl.cloudManager.fileList

                    //         QGCButton {
                    //             property bool exists : modelData["existsInMinio"]
                    //             text: exists ? qsTr("Uploaded") : qsTr("Upload")
                    //             enabled: _isSignIn && !exists
                    //             onClicked: {
                    //                 var bucketName = "log/"+dirCombobox.currentText;
                    //                 QGroundControl.cloudManager.uploadFile(modelData["filePath"], bucketName, modelData["fileName"]);
                    //             }
                    //         }
                    //     }
                    // }
                    ColumnLayout {
                        id: columnLayout

                        Repeater {
                            model: QGroundControl.cloudManager.fileList

                            Item {
                                id:    item
                                width: parent.width
                                height: rowLayout.height + ScreenTools.defaultFontPixelWidth

                                RowLayout {
                                    id: rowLayout
                                    spacing: 10

                                    QGCLabel {
                                        text: modelData["fileName"]
                                        width: parent.width * 0.6
                                    }

                                    QGCLabel {
                                        text: "[" + modelData["fileSize"] + "]"
                                    }

                                    QGCButton {
                                        property bool exists : modelData["existsInMinio"]
                                        text: exists ? qsTr("Uploaded") : qsTr("Upload")
                                        enabled: _isSignIn && !exists
                                        onClicked: {
                                            var bucketName = "log/"+dirCombobox.currentText;
                                            QGroundControl.cloudManager.uploadFile(modelData["filePath"], bucketName, modelData["fileName"]);
                                        }
                                    }
                                }
                                Rectangle {
                                    anchors.top: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width:  item.width
                                    height: 1
                                    color:  qgcPal.groupBorder
                                }
                            }
                        }
                    }
                }
            }

            // Column {
            //     spacing:            _margin
            //     Layout.alignment:   Qt.AlignTop | Qt.AlignLeft
            //     QGCButton {
            //         enabled:    !logController.requestingList && !logController.downloadingLogs
            //         text:       qsTr("Refresh")
            //         width:      _butttonWidth
            //         onClicked: {
            //             if (!QGroundControl.multiVehicleManager.activeVehicle || QGroundControl.multiVehicleManager.activeVehicle.isOfflineEditingVehicle) {
            //                 mainWindow.showMessageDialog(qsTr("Log Refresh"), qsTr("You must be connected to a vehicle in order to download logs."))
            //             } else {
            //                 logController.refresh()
            //             }
            //         }
            //     }
            //     QGCButton {
            //         enabled:    !logController.requestingList && !logController.downloadingLogs
            //         text:       qsTr("Download")
            //         width:      _butttonWidth

            //         onClicked: {
            //             var logsSelected = false
            //             for (var i = 0; i < logController.model.count; i++) {
            //                 var o = logController.model.get(i)
            //                 if (o.selected) {
            //                     logsSelected = true
            //                     break
            //                 }
            //             }
            //             if (!logsSelected) {
            //                 mainWindow.showMessageDialog(qsTr("Log Download"), qsTr("You must select at least one log file to download."))
            //                 return
            //             }

            //             if (ScreenTools.isMobile) {
            //                 // You can't pick folders in mobile, only default location is used
            //                 logController.download()
            //             } else {
            //                 fileDialog.title =          qsTr("Select save directory")
            //                 fileDialog.folder =         QGroundControl.settingsManager.appSettings.logSavePath
            //                 fileDialog.selectFolder =   true
            //                 fileDialog.openForLoad()
            //             }
            //         }

            //         QGCFileDialog {
            //             id: fileDialog
            //             onAcceptedForLoad: (file) => {
            //                 logController.download(file)
            //                 close()
            //             }
            //         }
            //     }

            //     QGCButton {
            //         enabled:    !logController.requestingList && !logController.downloadingLogs && logController.model.count > 0
            //         text:       qsTr("Erase All")
            //         width:      _butttonWidth
            //         onClicked:  mainWindow.showMessageDialog(qsTr("Delete All Log Files"),
            //                                                  qsTr("All log files will be erased permanently. Is this really what you want?"),
            //                                                  Dialog.Yes | Dialog.No,
            //                                                  function() { logController.eraseAll() })
            //     }

            //     QGCButton {
            //         text:       qsTr("Cancel")
            //         width:      _butttonWidth
            //         enabled:    logController.requestingList || logController.downloadingLogs
            //         onClicked:  logController.cancel()
            //     }
            // }
        }
    }
}
