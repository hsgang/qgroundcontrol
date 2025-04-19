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
        }
        FlyViewValueBar{
            //Layout.alignment:   Qt.AlignBottom
            Layout.alignment:   Qt.AlignRight
            extraWidth:         instrumentPanel.extraValuesWidth

            valueArea_userSettingsGroup:      valueArea.telemetryBarUserSettingsGroup
            valueArea_defaultSettingsGroup:   valueArea.telemetryBarDefaultSettingsGroup
            valueArea_vehicle:                QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle
        }
    }

    FlyViewInstrumentPanel {
        id:         instrumentPanel
        visible:    QGroundControl.corePlugin.options.flyView.showInstrumentPanel && _showSingleVehicleUI
        Layout.alignment:   Qt.AlignBottom
    }
}
