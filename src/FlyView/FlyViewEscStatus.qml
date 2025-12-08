import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

Rectangle {
    id:         escStatus

    property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    property real _motorCount:      _activeVehicle ? _activeVehicle.motorCount : 0
    property bool _coaxialMotors:   _activeVehicle ? _activeVehicle.coaxialMotors : false

    property real size:             _defaultSize
    property real _defaultSize:     ScreenTools.defaultFontPixelHeight * (10)
    property real _sizeRatio:       ScreenTools.isTinyScreen ? (size / _defaultSize) * 0.5 : size / _defaultSize
    property int  _fontSize:        ScreenTools.defaultFontPointSize * _sizeRatio
    property real _dataFontSize:    ScreenTools.defaultFontPointSize * 0.7

    property real backgroundOpacity: QGroundControl.settingsManager.flyViewSettings.flyviewWidgetOpacity.rawValue

    property real maxRpm:           5500
    property real maxTemperature:   60

    property real _totalCurrent:     {_activeVehicle ?
                                    _activeVehicle.escStatus.currentFirst.rawValue
                                    + _activeVehicle.escStatus.currentSecond.rawValue
                                    + _activeVehicle.escStatus.currentThird.rawValue
                                    + _activeVehicle.escStatus.currentFourth.rawValue
                                    + _activeVehicle.escStatus.currentFifth.rawValue
                                    + _activeVehicle.escStatus.currentSixth.rawValue
                                    + _activeVehicle.escStatus.currentSeventh.rawValue
                                    + _activeVehicle.escStatus.currentEighth.rawValue
                                    : 0
                                    }
    height:     columnLayout.height + _toolsMargin * 2
    width:      columnLayout.width + _toolsMargin * 2
    color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, backgroundOpacity)
    radius:     width / 4

    function motorLayout() {
        if(_motorCount == 4) {
            return [2,0,1,3]
        } else if (_motorCount == 8) {
            return [1,0,2,3]
        } else {
            return [2,0,1,3]
        }
    }

    property var escData: [
        {rpm: _activeVehicle ? _activeVehicle.escStatus.rpmFirst.rawValue : 0,
         voltage: _activeVehicle ? _activeVehicle.escStatus.voltageFirst.rawValue : 0,
         temperature: _activeVehicle ? _activeVehicle.escStatus.temperatureFirst.rawValue : 0,
         current: _activeVehicle ? _activeVehicle.escStatus.currentFirst.rawValue: 0 },
        {rpm: _activeVehicle ? _activeVehicle.escStatus.rpmSecond.rawValue : 0,
         voltage: _activeVehicle ? _activeVehicle.escStatus.voltageSecond.rawValue : 0,
         temperature: _activeVehicle ? _activeVehicle.escStatus.temperatureSecond.rawValue : 0,
         current: _activeVehicle ? _activeVehicle.escStatus.currentSecond.rawValue: 0 },
        {rpm: _activeVehicle ? _activeVehicle.escStatus.rpmThird.rawValue : 0,
         voltage: _activeVehicle ? _activeVehicle.escStatus.voltageThird.rawValue : 0,
         temperature: _activeVehicle ? _activeVehicle.escStatus.temperatureThird.rawValue : 0,
        current: _activeVehicle ? _activeVehicle.escStatus.currentThird.rawValue: 0 },
        {rpm: _activeVehicle ? _activeVehicle.escStatus.rpmFourth.rawValue : 0,
         voltage: _activeVehicle ? _activeVehicle.escStatus.voltageFourth.rawValue : 0,
         temperature: _activeVehicle ? _activeVehicle.escStatus.temperatureFourth.rawValue : 0,
         current: _activeVehicle ? _activeVehicle.escStatus.currentFourth.rawValue: 0 },
        {rpm: _activeVehicle ? _activeVehicle.escStatus.rpmFifth.rawValue : 0,
         voltage: _activeVehicle ? _activeVehicle.escStatus.voltageFifth.rawValue : 0,
         temperature: _activeVehicle ? _activeVehicle.escStatus.temperatureFifth.rawValue : 0,
         current: _activeVehicle ? _activeVehicle.escStatus.currentFifth.rawValue: 0 },
        {rpm: _activeVehicle ? _activeVehicle.escStatus.rpmSixth.rawValue : 0,
         voltage: _activeVehicle ? _activeVehicle.escStatus.voltageSixth.rawValue : 0,
         temperature: _activeVehicle ? _activeVehicle.escStatus.temperatureSixth.rawValue : 0,
         current: _activeVehicle ? _activeVehicle.escStatus.currentSixth.rawValue: 0 },
        {rpm: _activeVehicle ? _activeVehicle.escStatus.rpmSeventh.rawValue : 0,
         voltage: _activeVehicle ? _activeVehicle.escStatus.voltageSeventh.rawValue : 0,
         temperature: _activeVehicle ? _activeVehicle.escStatus.temperatureSeventh.rawValue : 0,
         current: _activeVehicle ? _activeVehicle.escStatus.currentSeventh.rawValue: 0 },
        {rpm: _activeVehicle ? _activeVehicle.escStatus.rpmEighth.rawValue : 0,
         voltage: _activeVehicle ? _activeVehicle.escStatus.voltageEighth.rawValue : 0,
         temperature: _activeVehicle ? _activeVehicle.escStatus.temperatureEighth.rawValue : 0,
         current: _activeVehicle ? _activeVehicle.escStatus.currentEighth.rawValue: 0 }
    ]

    ColumnLayout{
        id: columnLayout
        anchors.centerIn: parent

        QGCLabel {
            visible:            escGrid2.visible
            Layout.alignment:   Qt.AlignHCenter
            text: "Total_Curr: " + _totalCurrent.toFixed(2) + " A"
        }

        Grid {
            id: escGrid
            spacing:    ScreenTools.defaultFontPixelWidth / 2
            columns:    2
            rows:       2

            property var customOrder: motorLayout()

            Repeater {
                model: 4
                delegate: FlyViewEscIndicator {
                    escIndex:   escGrid.customOrder[index] + 1
                    rpm:        escData[escGrid.customOrder[index]].rpm
                    voltage:    escData[escGrid.customOrder[index]].voltage
                    temperature:escData[escGrid.customOrder[index]].temperature
                    current:    escData[escGrid.customOrder[index]].current
                    maxRpm: escStatus.maxRpm
                    maxTemperature: escStatus.maxTemperature
                }
            }
        }

        Grid {
            id: escGrid2
            visible:    _motorCount > 4
            spacing:    ScreenTools.defaultFontPixelWidth / 2
            columns:    2
            rows:       2

            property var customOrder: [4,5,7,6]

            Repeater {
                model: 4
                delegate: FlyViewEscIndicator {
                    escIndex:   escGrid2.customOrder[index] + 1
                    rpm:        escData[escGrid2.customOrder[index]].rpm
                    voltage:    escData[escGrid2.customOrder[index]].voltage
                    temperature:escData[escGrid2.customOrder[index]].temperature
                    current:    escData[escGrid2.customOrder[index]].current
                    maxRpm: escStatus.maxRpm
                    maxTemperature: escStatus.maxTemperature
                }
            }
        }
    }
}



