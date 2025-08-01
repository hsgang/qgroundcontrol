/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightDisplay

RowLayout {
    // TelemetryValuesBar {
    //     Layout.alignment:   Qt.AlignBottom
    //     visible:            QGroundControl.settingsManager.flyViewSettings.showTelemetryPanel.rawValue
    // }

    ColumnLayout {
        Layout.alignment:   Qt.AlignBottom

        TelemetryValuesBar {
            //Layout.alignment:   Qt.AlignBottom
            Layout.alignment:   Qt.AlignRight
            visible:            QGroundControl.settingsManager.flyViewSettings.showTelemetryPanel.rawValue

            settingsGroup:          factValueGrid.telemetryBarSettingsGroup
            specificVehicleForCard: null // Tracks active vehicle
        }
        FlyViewValueBar{
            //Layout.alignment:   Qt.AlignBottom
            Layout.alignment:   Qt.AlignRight
            extraWidth:         instrumentPanel.extraValuesWidth
        }
    }

    FlyViewInstrumentPanel {
        id:                 instrumentPanel
        Layout.alignment:   Qt.AlignBottom
        visible:            QGroundControl.corePlugin.options.flyView.showInstrumentPanel && _showSingleVehicleUI
    }
}
