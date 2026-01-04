import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView

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
