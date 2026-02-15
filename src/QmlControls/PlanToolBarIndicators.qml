import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

// Toolbar for Plan View
RowLayout {
    required property var planMasterController

    id: root
    spacing: ScreenTools.defaultFontPixelWidth

    property var _planMasterController: planMasterController
    property var _missionController: _planMasterController.missionController
    property var _geoFenceController: _planMasterController.geoFenceController
    property var _rallyPointController: _planMasterController.rallyPointController
    property bool _controllerOffline: _planMasterController.offline
    property var _controllerDirty: _planMasterController.dirty
    property var _syncInProgress: _planMasterController.syncInProgress
    property var _visualItems: _missionController.visualItems
    property bool _hasPlanItems: _planMasterController.containsItems

    readonly property real _margins: ScreenTools.defaultFontPixelWidth

    function _uploadClicked() {
        _planMasterController.upload()
    }

    function _downloadClicked() {
        if (_planMasterController.dirty) {
            QGroundControl.showMessageDialog(root, qsTr("Download"),
                                         qsTr("You have unsaved/unsent changes. Downloading from the Vehicle will lose these changes. Are you sure?"),
                                         Dialog.Yes | Dialog.Cancel,
                                         function() { _planMasterController.loadFromVehicle() })
        } else {
            _planMasterController.loadFromVehicle()
        }
    }

    function _loadFromFile() {
        if (_planMasterController.dirty) {
            QGroundControl.showMessageDialog(root, qsTr("Open Plan"),
                                        qsTr("You have unsaved/unsent changes. Loading a new Plan will lose these changes. Are you sure?"),
                                        Dialog.Yes | Dialog.Cancel,
                                        function() { _planMasterController.loadFromSelectedFile() } )
        } else {
            _planMasterController.loadFromSelectedFile()
        }
    }

    function _loadFromCloud() {
        if (_planMasterController.dirty) {
            mainWindow.showMessageDialog(qsTr("Open Plan from Cloud"),
                                        qsTr("You have unsaved/unsent changes. Loading a new Plan will lose these changes. Are you sure?"),
                                        Dialog.Yes | Dialog.Cancel,
                                        function() {
                                            _planMasterController.getListFromCloud()
                                            showCloudDownloadDialog()
                                        } )
        } else {
            _planMasterController.getListFromCloud()
            showCloudDownloadDialog()
        }
    }

    function showCloudDownloadDialog() {
        var dialog = cloudDownloadDialogComponent.createObject(mainWindow)
        dialog.open()
    }

    function _saveToCurrentFile() {
        if(_planMasterController.currentPlanFile !== "") {
            _planMasterController.saveToCurrent()
            QGroundControl.showMessageDialog(root, qsTr("Save"),
                                        qsTr("Plan saved to `%1`").arg(_planMasterController.currentPlanFile),
                                        Dialog.Ok)
        } else {
            _planMasterController.saveToSelectedFile()
        }
    }

    function _saveAsNewFile() {
        _planMasterController.saveToSelectedFile()
    }

    function _saveToCloud() {
        if (!_planMasterController.containsItems) {
            mainWindow.showMessageDialog(qsTr("Save to Cloud"), qsTr("No mission items to save."))
            return
        }
        var dialog = cloudUploadDialogComponent.createObject(mainWindow)
        dialog.open()
    }

    function _saveAsKMLClicked() {
        // Don't save if we only have Mission Settings item
        if (_visualItems.count > 1) {
            _planMasterController.saveKmlToSelectedFile()
        }
    }

    function _storageClearButtonClicked() {
        QGroundControl.showMessageDialog(root, qsTr("Clear"),
                                     qsTr("Are you sure you want to remove all the items from the plan editor?"),
                                     Dialog.Yes | Dialog.Cancel,
                                     function() { _planMasterController.removeAll(); })
    }

    function _vehicleClearButtonClicked() {
        QGroundControl.showMessageDialog(root, qsTr("Clear"),
                                     qsTr("Are you sure you want to remove the plan from the vehicle and the plan editor?"),
                                     Dialog.Yes | Dialog.Cancel,
                                     function() {
                                        _planMasterController.removeAllFromVehicle()
                                     })
    }

    function _clearClicked() {
        if (_planMasterController.offline) {
            _storageClearButtonClicked();
        } else {
            _vehicleClearButtonClicked();
        }
    }

    QGCPalette { id: qgcPal }

    QGCButton {
        id: openButton
        text: qsTr("Open")
        iconSource: "/InstrumentValueIcons/download.svg"
        enabled: !_planMasterController.syncInProgress

        onClicked: {
            let position = Qt.point(0, 0)
            position = mapToItem(globals.parent, position)
            var dropPanel = openDropPanelComponent.createObject(mainWindow, { clickRect: Qt.rect(position.x, position.y, width, height) })
            dropPanel.open()
        }
    }

    QGCButton {
        id: saveButton
        text: qsTr("Save")
        iconSource: "/InstrumentValueIcons/upload.svg"
        enabled: !_syncInProgress && _hasPlanItems
        primary: _controllerDirty

        onClicked: {
            let position = Qt.point(0, 0)
            position = mapToItem(globals.parent, position)
            var dropPanel = saveDropPanelComponent.createObject(mainWindow, { clickRect: Qt.rect(position.x, position.y, width, height) })
            dropPanel.open()
        }
    }

    QGCButton {
        id: uploadButton
        text: qsTr("Upload")
        iconSource: "/res/UploadToVehicle.svg"
        enabled: !_syncInProgress && _hasPlanItems
        visible: !_syncInProgress
        primary: _controllerDirty
        onClicked: _uploadClicked()
    }

    QGCButton {
        text: qsTr("Clear")
        iconSource: "/res/TrashCan.svg"
        enabled: !_syncInProgress
        onClicked: _clearClicked()
    }

    QGCButton {
        iconSource: "/InstrumentValueIcons/navigation-more.svg"

        onClicked: {
            let position = Qt.point(width, height / 2)
            // For some strange reason using mainWindow in mapToItem doesn't work, so we use globals.parent instead which also gets us mainWindow
            position = mapToItem(globals.parent, position)
            var dropPanel = hamburgerDropPanelComponent.createObject(mainWindow, { clickRect: Qt.rect(position.x, position.y, 0, 0) })
            dropPanel.open()
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignVCenter
        spacing: 0

        QGCLabel {
            text: _leftClickText()
            font.pointSize: ScreenTools.smallFontPointSize
            visible: _editingLayer === _layerMission || _editingLayer === _layerRally

            function _leftClickText() {
                if (_editingLayer === _layerMission) {
                    return qsTr("- Click on the map to add Waypoint")
                } else {
                    return qsTr("- Click on the map to add Rally Point")
                }
            }
        }

        QGCLabel {
            text: qsTr("- %1 to add ROI %2").arg(ScreenTools.isMobile ? qsTr("Press and hold") : qsTr("Right click")).arg(_missionController.isROIActive ? qsTr("or Cancel ROI") : "")
            font.pointSize: ScreenTools.smallFontPointSize
            visible: _editingLayer === _layerMission && _planMasterController.controllerVehicle.roiModeSupported
        }
    }

    Component {
        id: openDropPanelComponent

        DropPanel {
            id: openDropPanel

            sourceComponent: Component {
                ColumnLayout {
                    spacing: ScreenTools.defaultFontPixelHeight / 2

                    QGCButton {
                        Layout.fillWidth: true
                        text: qsTr("From Vehicle")
                        iconSource: "/qmlimages/vehicleQuadRotor.svg"
                        enabled: !_syncInProgress

                        onClicked: {
                            openDropPanel.close()
                            _downloadClicked()
                        }
                    }

                    QGCButton {
                        Layout.fillWidth: true
                        text: qsTr("From File")
                        iconSource: "/qmlimages/Plan.svg"
                        enabled: !_syncInProgress

                        onClicked: {
                            openDropPanel.close()
                            _loadFromFile()
                        }
                    }

                    QGCButton {
                        Layout.fillWidth: true
                        text: qsTr("From Cloud")
                        iconSource: "/InstrumentValueIcons/cloud-download.svg"
                        enabled: !_syncInProgress
                        visible: QGroundControl.cloudManager.signedIn

                        onClicked: {
                            openDropPanel.close()
                            _loadFromCloud()
                        }
                    }
                }
            }
        }
    }

    Component {
        id: saveDropPanelComponent

        DropPanel {
            id: saveDropPanel

            sourceComponent: Component {
                ColumnLayout {
                    spacing: ScreenTools.defaultFontPixelHeight / 2

                    QGCButton {
                        Layout.fillWidth: true
                        text: qsTr("Save")
                        iconSource: "/res/SaveToDisk.svg"
                        enabled: !_syncInProgress && _planMasterController.currentPlanFile !== ""

                        onClicked: {
                            saveDropPanel.close()
                            _saveToCurrentFile()
                        }
                    }

                    QGCButton {
                        Layout.fillWidth: true
                        text: qsTr("Save As...")
                        iconSource: "/res/SaveToDisk.svg"
                        enabled: !_syncInProgress

                        onClicked: {
                            saveDropPanel.close()
                            _saveAsNewFile()
                        }
                    }

                    QGCButton {
                        Layout.fillWidth: true
                        text: qsTr("Save to Cloud")
                        iconSource: "/InstrumentValueIcons/cloud-upload.svg"
                        enabled: !_syncInProgress
                        visible: QGroundControl.cloudManager.signedIn

                        onClicked: {
                            saveDropPanel.close()
                            _saveToCloud()
                        }
                    }
                }
            }
        }
    }

    Component {
        id: cloudUploadDialogComponent

        QGCPopupDialog {
            title: qsTr("Save to Cloud")
            buttons: Dialog.Close

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight / 2
                width: ScreenTools.defaultFontPixelWidth * 40

                QGCLabel {
                    text: qsTr("Enter mission file name:")
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: ScreenTools.defaultFontPixelHeight * 3
                    color: "transparent"
                    border.width: 1
                    border.color: qgcPal.groupBorder
                    radius: ScreenTools.defaultFontPixelWidth / 4

                    TextInput {
                        id: uploadNameField
                        anchors.fill: parent
                        anchors.margins: ScreenTools.defaultFontPixelWidth / 2
                        verticalAlignment: TextInput.AlignVCenter
                        font.pointSize: ScreenTools.defaultFontPointSize
                        font.family: ScreenTools.normalFontFamily
                        color: qgcPal.text
                        antialiasing: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: ScreenTools.defaultFontPixelWidth

                    Item { Layout.fillWidth: true }

                    QGCButton {
                        text: qsTr("Cancel")
                        onClicked: close()
                    }

                    QGCButton {
                        text: qsTr("Upload")
                        primary: true
                        enabled: uploadNameField.text.length > 0

                        onClicked: {
                            var uploadName = uploadNameField.text
                            if (uploadName.length > 0) {
                                _planMasterController.uploadToCloud(uploadName)
                                _planMasterController.getListFromCloud()
                                mainWindow.showMessageDialog(
                                    qsTr("Upload Complete"),
                                    qsTr("Mission '%1' uploaded to cloud successfully.").arg(uploadName),
                                    Dialog.Ok
                                )
                                close()
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: cloudDownloadDialogComponent

        QGCPopupDialog {
            title: qsTr("Download from Cloud")
            buttons: Dialog.Close

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight / 2
                width: ScreenTools.defaultFontPixelWidth * 50

                QGCLabel {
                    text: qsTr("Select a mission file to download:")
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: qgcPal.groupBorder
                }

                ListView {
                    id: cloudListView
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 20
                    clip: true

                    model: QGroundControl.cloudManager.dnEntryPlanFile

                    delegate: Item {
                        width: parent.width
                        height: cloudFileButton.height + ScreenTools.defaultFontPixelWidth

                        QGCButton {
                            id: cloudFileButton
                            width: parent.width - deleteIcon.width - ScreenTools.defaultFontPixelWidth
                            height: ScreenTools.implicitButtonHeight * 1.2

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                                anchors.rightMargin: ScreenTools.defaultFontPixelWidth
                                spacing: 0

                                QGCLabel {
                                    text: modelData["FileName"]
                                }
                                QGCLabel {
                                    text: modelData["LastModified"]
                                    font.pointSize: ScreenTools.smallFontPointSize
                                    Layout.alignment: Qt.AlignRight
                                    opacity: 0.7
                                }
                            }

                            onClicked: {
                                mainWindow.showMessageDialog(
                                    qsTr("Download Mission File"),
                                    qsTr("Download '%1' from cloud storage?").arg(modelData["FileName"]),
                                    Dialog.Ok | Dialog.Cancel,
                                    function () {
                                        QGroundControl.cloudManager.downloadObject("amp-mission-files", modelData["Key"], modelData["FileName"])
                                        close()
                                    }
                                )
                            }
                        }

                        QGCColoredImage {
                            id: deleteIcon
                            anchors.left: cloudFileButton.right
                            anchors.leftMargin: ScreenTools.defaultFontPixelWidth / 2
                            anchors.verticalCenter: cloudFileButton.verticalCenter
                            height: ScreenTools.minTouchPixels
                            width: height
                            sourceSize.height: height
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                            smooth: true
                            color: qgcPal.text
                            source: "/res/TrashDelete.svg"

                            QGCMouseArea {
                                fillItem: parent
                                onClicked: {
                                    mainWindow.showMessageDialog(
                                        qsTr("Delete Mission File"),
                                        qsTr("Delete '%1' from cloud storage?").arg(modelData["FileName"]),
                                        Dialog.Ok | Dialog.Cancel,
                                        function () {
                                            QGroundControl.cloudManager.deleteObject("amp-mission-files", modelData["Key"])
                                            _planMasterController.getListFromCloud()
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: hamburgerDropPanelComponent

        DropPanel {
            id: dropPanel

            sourceComponent: Component {
                ColumnLayout {
                    spacing: ScreenTools.defaultFontPixelHeight / 2

                    QGCButton {
                        Layout.fillWidth: true
                        text: qsTr("Save as KML")
                        enabled: !_syncInProgress && _hasPlanItems

                        onClicked: {
                            dropPanel.close()
                            _saveAsKMLClicked()
                        }
                    }

                    QGCButton {
                        Layout.fillWidth: true
                        text: qsTr("Download")
                        enabled: !_syncInProgress
                        visible: !_syncInProgress

                        onClicked: {
                            dropPanel.close()
                            _downloadClicked()
                        }
                    }
                }
            }
        }
    }
}
