import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts  1.2
import QtQuick.Dialogs  1.2

import QGroundControl                   1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.MultiVehicleManager 1.0
import QGroundControl.Controls          1.0
import QGroundControl.FactControls      1.0
import QGroundControl.Palette           1.0

Rectangle {
    id:         atmosphericValueBar
    height:     atmosphericValueGrid.height + ScreenTools.defaultFontPixelHeight * 0.2
    width:      atmosphericValueGrid.width + ScreenTools.defaultFontPixelWidth * 2
    color:      "#80000000"
    radius:     _margins

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property real _temperatureValue:  _activeVehicle ? _activeVehicle.atmosphericSensor.temperature.rawValue.toFixed(1) : 0
    property real _humidityValue:  _activeVehicle ? _activeVehicle.atmosphericSensor.humidity.rawValue.toFixed(1) : 0
    property real _pressureValue:  _activeVehicle ? _activeVehicle.atmosphericSensor.pressure.rawValue.toFixed(1) : 0
    property real _windDirValue:  _activeVehicle ? _activeVehicle.atmosphericSensor.windDir.rawValue.toFixed(1) : 0
    property real _windSpdValue:  _activeVehicle ? _activeVehicle.atmosphericSensor.windSpd.rawValue.toFixed(1) : 0

    GridLayout {
        id:                 atmosphericValueGrid
        anchors.margins:    ScreenTools.defaultFontPixelHeight
        rowSpacing:      ScreenTools.defaultFontPixelWidth
        anchors.horizontalCenter: atmosphericValueBar.horizontalCenter
        anchors.verticalCenter:   atmosphericValueBar.verticalCenter
        rows: 1

        QGCLabel { text: qsTr("W/D:") }
        QGCLabel { text: _windDirValue ? _windDirValue + " deg  " : qsTr("--")
            Layout.preferredWidth:    ScreenTools.defaultFontPixelWidth * 8
            }
        QGCLabel { text: qsTr("W/S:") }
        QGCLabel { text: _windSpdValue ? QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_windSpdValue).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsSpeedUnitsString : qsTr("--")
            Layout.preferredWidth:    ScreenTools.defaultFontPixelWidth * 8
            }
        QGCLabel { text: qsTr("T:") }
        QGCLabel { text: _temperatureValue ? _temperatureValue + " C  " : qsTr("--")
            Layout.preferredWidth:    ScreenTools.defaultFontPixelWidth * 8
            }
        QGCLabel { text: qsTr("H:") }
        QGCLabel { text: _humidityValue ? _humidityValue + " %  " : qsTr("--")
            Layout.preferredWidth:    ScreenTools.defaultFontPixelWidth * 8
            }
        QGCLabel { text: qsTr("P:") }
        QGCLabel { text: _pressureValue ? _pressureValue + " hPa  " : qsTr("--")
            Layout.preferredWidth:    ScreenTools.defaultFontPixelWidth * 8
            }
    }
}


