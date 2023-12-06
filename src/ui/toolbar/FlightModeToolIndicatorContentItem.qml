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

        RowLayout {
            spacing: ScreenTools.defaultFontPixelHeight
            visible: modeEditCheckBox.checked || !hiddenFlightModesList.find(item => { return item === modelData } )

            QGCButton {
                id:                 modeButton
                text:               modelData
                Layout.fillWidth:   true
                checked:            modeEditCheckBox.checked || (modelData !== activeVehicle.flightMode) ? false : true

                onClicked: {
                    if (modeEditCheckBox.checked) {
                        parent.children[1].toggle()
                        parent.children[1].clicked()
                    } else {
                        activeVehicle.flightMode = modelData
                        //drawer.close()
                    }
                }
            }

            QGCCheckBoxSlider {
                visible: modeEditCheckBox.checked

                onClicked: {
                    hiddenFlightModesList = []
                    for (var i=0; i<modeRepeater.count; i++) {
                        var checkBox = modeRepeater.itemAt(i).children[1]
                        if (!checkBox.checked) {
                            hiddenFlightModesList.push(modeRepeater.model[i])
                        }
                    }
                    hiddenFlightModesFact.value = hiddenFlightModesList.join(",")
                }
            }
        }
    }
}
