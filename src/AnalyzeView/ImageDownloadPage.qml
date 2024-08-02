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

AnalyzePage {
    id:                 imageDownloadPage
    pageComponent:      pageComponent
    pageDescription:    qsTr("image Download")

    property real _margin:          ScreenTools.defaultFontPixelWidth
    property real _butttonWidth:    ScreenTools.defaultFontPixelWidth * 20

    property var selectedItems: []

    FileDialog {
        id: fileDialog
        title: "Choose where to save the file"
        fileMode: FileDialog.SaveFile
        nameFilters: ["All files (*)"]

        onAccepted: {
            var selectedFile = fileDialog.selectedFile
            downloadItem(fileDialog.currentItem, selectedFile)
        }
    }

    function downloadSelectedItems() {
        if (selectedItems.length > 0) {
            fileDialog.currentItem = selectedItems[0]
            fileDialog.open()
        }
    }

    function downloadItem(item, savePath) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    console.log("Download completed for: " + item.name);
                    saveFile(xhr.response, savePath);
                } else {
                    console.error("Download failed for: " + item.name);
                }
            }
        }

        xhr.open("GET", item.url, true);
        xhr.responseType = "arraybuffer";
        xhr.send();
    }

    function saveFile(data, filePath) {
        var dataUrl = "data:application/octet-stream;base64," + Qt.btoa(String.fromCharCode.apply(null, new Uint8Array(data)));
        var xhr = new XMLHttpRequest();
        xhr.open("GET", dataUrl, true);
        xhr.responseType = "blob";
        xhr.onload = function() {
            if (this.status === 200) {
                var blob = this.response;
                var reader = new FileReader();
                reader.onload = function(e) {
                    var contents = e.target.result;
                    var file = new File([contents], filePath);
                    var saveLink = document.createElement("a");
                    saveLink.href = URL.createObjectURL(file);
                    saveLink.download = filePath.split('/').pop();
                    saveLink.click();
                };
                reader.readAsArrayBuffer(blob);
            }
        };
        xhr.send();
    }

    function getMediaList(mediaType) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("Response received. Status:", xhr.status);
                //console.log("Response text:", xhr.responseText);

                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        //console.log("Parsed response:", JSON.stringify(response, null, 2));

                        if (response && response.success && response.data && Array.isArray(response.data.list)) {
                            mediaListModel.clear();
                            response.data.list.forEach(function(item) {
                                mediaListModel.append(item);
                            });
                        } else {
                            console.error("Invalid response structure");
                            if (response && response.message) {
                                console.error("Server message:", response.message);
                            }
                        }
                    } catch (e) {
                        console.error("Error parsing JSON:", e);
                    }
                } else {
                    console.error("HTTP Error:", xhr.status);
                }
            }
        }

        var url = "http://192.168.144.25:82/cgi-bin/media.cgi/api/v1/getmedialist";
        var data = {
            "media_type": mediaType,
            "path": "101SIYI_IMG",
            "start": 0,
            "count": 100
        };

        var fullUrl = url + "?" + serializeData(data);
        console.log("Sending request to:", fullUrl);

        xhr.open("GET", fullUrl, true);
        xhr.send();
    }

    function serializeData(obj) {
        return Object.keys(obj).map(function(key) {
            return encodeURIComponent(key) + '=' + encodeURIComponent(obj[key]);
        }).join('&');
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    ListModel { id: mediaListModel }

    Component {
        id: pageComponent

        RowLayout {
            width:  availableWidth
            height: availableHeight

            // ListView {
            //     Layout.fillWidth: true
            //     Layout.fillHeight: true
            //     model: mediaListModel
            //     delegate: QGCLabel {
            //         text: name + " - " + url
            //     }
            // }

            GridView {
                id: gridView
                Layout.fillWidth: true
                Layout.fillHeight: true
                cellWidth: 120
                cellHeight: 120
                model: mediaListModel

                delegate: Item {
                    width: 100
                    height: 100

                    Image {
                        anchors.fill: parent
                        source: model.url
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                    }

                    Text {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        text: model.name
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        color: "white"
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "blue"
                        opacity: 0.3
                        visible: selectedItems.indexOf(model) !== -1
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var index = selectedItems.indexOf(model);
                            if (index === -1) {
                                selectedItems.push(model);
                            } else {
                                selectedItems.splice(index, 1);
                            }
                            gridView.forceLayout();
                        }
                    }
                }
            }

            Column {
                spacing:            _margin
                Layout.alignment:   Qt.AlignTop | Qt.AlignLeft
                QGCButton {
                    text:       qsTr("Get Image List")
                    width:      _butttonWidth
                    onClicked: {
                        getMediaList(0)
                    }
                }
                QGCButton {
                    text:       qsTr("Get Video List")
                    width:      _butttonWidth

                    onClicked: {
                        getMediaList(1)
                    }
                }

                QGCButton {
                    text: qsTr("Download Selected")
                    width: _butttonWidth
                    enabled: selectedItems.length > 0
                    onClicked: {
                        downloadSelectedItems();
                    }
                }

                QGCButton {
                    text: qsTr("Clear Selection")
                    width: _butttonWidth
                    enabled: selectedItems.length > 0
                    onClicked: {
                        selectedItems = [];
                        gridView.forceLayout();
                    }
                }

                // QGCButton {
                //     enabled:    !logController.requestingList && !logController.downloadingLogs && logController.model.count > 0
                //     text:       qsTr("Erase All")
                //     width:      _butttonWidth
                //     onClicked:  mainWindow.showMessageDialog(qsTr("Delete All Log Files"),
                //                                              qsTr("All log files will be erased permanently. Is this really what you want?"),
                //                                              Dialog.Yes | Dialog.No,
                //                                              function() { logController.eraseAll() })
                // }

                // QGCButton {
                //     text:       qsTr("Cancel")
                //     width:      _butttonWidth
                //     enabled:    logController.requestingList || logController.downloadingLogs
                //     onClicked:  logController.cancel()
                // }
            }
        }
    }
}
