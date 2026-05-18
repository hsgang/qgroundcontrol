/****************************************************************************
 *
 * (c) 2009-2022 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.FactSystem
import QGroundControl.FactControls

// This is the contentItem portion of the ToolIndicatorPage for the Flight Mode toolbar item.
// It supports changing the flight mode and editing the flight mode list.
// It works for both PX4 and APM firmware.

ColumnLayout {
    id:         modeColumn
    spacing:    modeEditCheckBox.checked ? ScreenTools.defaultFontPixelHeight / 4 : ScreenTools.defaultFontPixelHeight / 2

    property var  activeVehicle:            QGroundControl.multiVehicleManager.activeVehicle
    property var  flightModeSettings:       QGroundControl.settingsManager.flightModeSettings
    property var  hiddenFlightModesFact:    null
    property var  hiddenFlightModesList:    [] 

    Component.onCompleted: {
        if (activeVehicle.px4Firmware) {
            hiddenFlightModesFact = flightModeSettings.px4HiddenFlightModes
        } else if (activeVehicle.apmFirmware) {
            hiddenFlightModesFact = flightModeSettings.apmHiddenFlightModes
        } else {
            modeEditCheckBox.enabled = false
        }
        // Split string into list of flight modes
        if (hiddenFlightModesFact) {
            hiddenFlightModesList = hiddenFlightModesFact.value.split(",")
        }
        hiddenModesLabel.calcVisible()
    }

    QGCCheckBoxSlider {
        id:                 modeEditCheckBox
        Layout.fillWidth:   true
        text:               qsTr("Edit")
        visible:            enabled && expanded

        onClicked: {
            for (var i=0; i<modeRepeater.count; i++) {
                var button      = modeRepeater.itemAt(i).children[0]
                var checkBox    = modeRepeater.itemAt(i).children[1]

                if (checked) {
                    checkBox.checked = !hiddenFlightModesList.find(item => { return item === button.text } )
                }
            }
        }
    }

    Repeater {
        id:     modeRepeater
        model:  activeVehicle ? activeVehicle.flightModes : []

        // 모든 RowLayout 항목을 추적
        property var buttonRows: []

        RowLayout {
            spacing: ScreenTools.defaultFontPixelHeight
            visible: modeEditCheckBox.checked || !hiddenFlightModesList.find(item => { return item === modelData } )

            property bool clickedOnce: false

            Component.onCompleted: {
                modeRepeater.buttonRows.push(this)
            }

            QGCButton {
                id:                 modeButton
                //text:               clickedOnce ? modelData + "\n 한번더 클릭하여 모드 변경"  : modelData
                Layout.fillWidth:   true
                checked:            modeEditCheckBox.checked || (modelData !== activeVehicle.flightMode) ? false : true
                //wrapMode:           Text.Wrap
                contentItem: Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    QGCLabel {
                        text: modelData
                        //font.pixelSize: ScreenTools.defaultFontPixelHeight  // 첫 번째 줄: 일반 크기
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.Wrap
                    }

                    QGCLabel {
                        text: clickedOnce ? "한번더 클릭하여 모드 변경" : ""
                        font.pointSize: ScreenTools.defaultFontPointSize * 0.8 // 두 번째 줄: 더 작은 크기
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.Wrap
                        visible: clickedOnce
                    }
                }

                onClicked: {
                    if (modeEditCheckBox.checked) {
                        parent.children[1].toggle()
                        parent.children[1].clicked()
                    } else {
                        // 다른 RowLayout들의 clickedOnce를 초기화
                        for (var i = 0; i < modeRepeater.buttonRows.length; i++) {
                            var row = modeRepeater.buttonRows[i]
                            if (row !== parent) {
                                row.clickedOnce = false
                            }
                        }

                        if (!parent.clickedOnce) {
                            // 첫 번째 클릭: 자신만 true로
                            parent.clickedOnce = true
                        } else {
                            // 두 번째 클릭: flightMode 설정하고 초기화
                            activeVehicle.flightMode = modelData
                            parent.clickedOnce = false
                        }
                        // var controller = globals.guidedControllerFlyView
                        // controller.confirmAction(controller.actionSetFlightMode, modelData)
                        // mainWindow.closeIndicatorDrawer()
                    }
                }
            }

            QGCCheckBoxSlider {
                visible: modeEditCheckBox.checked && expanded

                onClicked: {
                    hiddenFlightModesList = []
                    for (var i=0; i<modeRepeater.count; i++) {
                        var checkBox = modeRepeater.itemAt(i).children[1]
                        if (!checkBox.checked) {
                            hiddenFlightModesList.push(modeRepeater.model[i])
                        }
                    }
                    hiddenFlightModesFact.value = hiddenFlightModesList.join(",")
                    hiddenModesLabel.calcVisible()
                }
            }
        }
    }

    QGCLabel {
        id: hiddenModesLabel
        text: qsTr("Some Modes Hidden")
        Layout.fillWidth: true
        font.pointSize: ScreenTools.smallFontPointSize
        horizontalAlignment: Text.AlignHCenter
        visible: false

        function calcVisible() {
            hiddenModesLabel.visible = hiddenFlightModesList.length > 0
        }
    }
}
