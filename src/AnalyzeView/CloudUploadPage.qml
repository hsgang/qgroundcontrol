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
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.FactControls

AnalyzePage {
    id:                 cloudUploadPage
    pageComponent:      pageComponent
    pageDescription:    qsTr("Cloud Upload Page")

    property var  cloudManager:     QGroundControl.cloudManager
    property real _margin:          ScreenTools.defaultFontPixelWidth
    property real _butttonWidth:    ScreenTools.defaultFontPixelWidth * 18
    property var _isSignIn:         QGroundControl.cloudManager.signedIn
    property string _signedId:      QGroundControl.cloudManager.signedId

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    Component {
        id: pageComponent

        RowLayout {
            width:  availableWidth
            height: availableHeight

            function loadFileList() {
                var dir = dirCombobox.currentText
                cloudManager.loadDirFile(dir)
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
                    contentWidth:       gridLayout.width
                    contentHeight:      gridLayout.height

                    GridLayout {
                        id:                 gridLayout
                        rows:               cloudManager.fileList.length + 1
                        columns:            3
                        flow:               GridLayout.TopToBottom
                        columnSpacing:      ScreenTools.defaultFontPixelHeight
                        rowSpacing:         ScreenTools.defaultFontPixelWidth

                        QGCLabel {
                            text: qsTr("File")
                        }
                        Repeater {
                            model: QGroundControl.cloudManager.fileList

                            QGCLabel {
                                text: modelData["fileName"]
                            }
                        }

                        QGCLabel {
                            text: qsTr("Size")
                        }
                        Repeater {
                            model: QGroundControl.cloudManager.fileList

                            QGCLabel {
                                text: modelData["fileSize"]
                            }
                        }

                        QGCLabel {
                            text: qsTr("Upload")
                        }
                        Repeater {
                            model: QGroundControl.cloudManager.fileList

                            QGCButton {
                                property bool exists : modelData["existsInMinio"]
                                text: exists ? qsTr("Uploaded") : qsTr("Upload")
                                enabled: _isSignIn && !exists
                                onClicked: {
                                    var bucketName = dirCombobox.currentText;
                                    QGroundControl.cloudManager.uploadFile(modelData["filePath"], bucketName, modelData["fileName"]);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
