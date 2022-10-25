import QtQuick                  2.12
import QtQuick.Controls         1.2
import QtQuick.Controls.Styles  1.4
import QtQuick.Layouts          1.12
import QtCharts                 2.3

import QtQuick.Window           2.2
import QtQml.Models             2.1

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0

Item{
    id: chartWidgetRoot

    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle

    property real   _vehicleAltitude:           _activeVehicle ? _activeVehicle.altitudeRelative.rawValue.toFixed(1) : 0

    property real   _temperatureValue:    _activeVehicle ? _activeVehicle.atmosphericSensor.temperature.rawValue.toFixed(1) : 0
    property real   _humidityValue:       _activeVehicle ? _activeVehicle.atmosphericSensor.humidity.rawValue.toFixed(1) : 0
    property real   _pressureValue:       _activeVehicle ? _activeVehicle.atmosphericSensor.pressure.rawValue.toFixed(1) : 0
    property real   _windDirValue:        _activeVehicle ? _activeVehicle.atmosphericSensor.windDir.rawValue.toFixed(1) : 0
    property real   _windSpdValue:        _activeVehicle ? _activeVehicle.atmosphericSensor.windSpd.rawValue.toFixed(1) : 0

    property real   preAltitudeValue: 0
    property real   preValue: 0
    property real   maxAltitude: 0
    property real   minAltitude: 0
    property real   diffGapValue: 1
    property real   count: 0

    property int   tempMin: _temperatureValue - 2
    property int   tempMax: _temperatureValue + 2
    property int   humiMin: _humidityValue - 5
    property int   humiMax: _humidityValue + 5
    property int   presMin: _pressureValue - 5
    property int   presMax: _pressureValue + 5
    property int   wnDrMin: 0
    property int   wnDrMax: 360
    property int   wnSpMin: _windSpdValue - 5
    property int   wnSpMax: _windSpdValue + 5

    function getAltRange(){
        var value = _vehicleAltitude
        if(value > maxAltitude - 5){
            maxAltitude = value + 5
        }
        else if(value < minAltitude + 5){
            minAltitude = value - 5
        }
    }

    function getTempRange(){
        var Value = _temperatureValue
        if(Value > tempMax - 2){
            tempMax = Value + 2
        }
        else if(Value < tempMin + 2){
            tempMin = Value - 2
        }
    }

    function getHumiRange(){
        var Value = _humidityValue
        if(Value > humiMax - 5){
            humiMax = Value + 5
        }
        else if(Value < humiMin + 5){
            humiMin = Value - 5
        }
    }

    function getPressRange(){
        var Value = _pressureValue
        if(Value > presMax - 5){
            presMax = Value + 5
        }
        else if(Value < presMin + 5){
            presMin = Value - 5
        }
    }

    function getWindSpdRange(){
        var Value = _windSpdValue
        if(Value > wnSpMax - 5){
            wnSpMax = Value + 5
        }
        else if(Value < wnSpMin + 5){
            wnSpMin = Value - 5
        }
    }

    function atmosphericDataGet(){

        var diffValue = Math.abs(_vehicleAltitude - preValue)

        if(diffValue >= diffGapValue) {
            preValue = _vehicleAltitude

            getAltRange()
            getTempRange()
            getHumiRange()
            getPressRange()
            getWindSpdRange()

            if(tempCheck.checked){
                seriesTemp.append(_temperatureValue, _vehicleAltitude)
            }
            if(humiCheck.checked){
                seriesHumi.append(_humidityValue, _vehicleAltitude)
            }
            if(presCheck.checked){
                seriesPress.append(_pressureValue, _vehicleAltitude)
            }
            if(windDirCheck.checked){
                seriesWindDir.append(_windDirValue, _vehicleAltitude)
            }
            if(windSpdCheck.checked){
                seriesWindSpd.append(_windSpdValue, _vehicleAltitude)
            }
            if(tempCheck.checked || humiCheck.checked || presCheck.checked || windDirCheck.checked || windSpdCheck.checked){
                count++
            }

            //console.log("count :", count)
        }
    }

    function clearChart(){
        seriesTemp.removePoints(0,seriesTemp.count)
        seriesHumi.removePoints(0,seriesHumi.count)
        seriesPress.removePoints(0,seriesPress.count)
        seriesWindDir.removePoints(0,seriesWindDir.count)
        seriesWindSpd.removePoints(0,seriesWindSpd.count)
        maxAltitude = 0
        preValue = 0
        count = 0
        }

    Connections{
        target: _activeVehicle
        onAtmosphericValueChanged: {
            atmosphericDataGet()            
        }
    }

    Rectangle {
        id: chartRectangle
        anchors.margins: _toolsMargin
        anchors.fill: parent
        width: parent.width
        height: parent.height
        color : "#80000000"
        border.color: "white"
        border.width: 1
        radius : _toolsMargin

        ColumnLayout{
            id: checkBoxRow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: _toolsMargin
            spacing: 2

            QGCCheckBox {
                id: tempCheck
                text: "Temperature"
            }
            QGCCheckBox {
                id: humiCheck
                text: "Humidity"
            }
            QGCCheckBox {
                id: presCheck
                text: "Pressure"
            }
            QGCCheckBox {
                id: windDirCheck
                text: "WindDir"
            }
            QGCCheckBox {
                id: windSpdCheck
                text: "WindSpd"
            }

            QGCButton{
                text: "Clear"
                onClicked:  {
                    clearChart()
                }
            }

            QGCLabel{
                text: "Interval(m)"
            }

            QGCTextField{
                id: intervalTextField
                placeholderText: qsTr("input Interval")
                width: ScreenTools.defaultFontPixelWidth * 5
            }

            QGCButton{
                text:"Set Interval"
                onClicked: {
                    diffGapValue = intervalTextField.text
                }
            }

            QGCLabel{
                text: "Count : " + count
            }

            QGCLabel{
                text: "Interval : " + diffGapValue
            }
        }

        Rectangle{
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: checkBoxRow.left
            anchors.bottom: parent.bottom
            color: "transparent"

            ChartView{
                id: customChartView
                title : "Atmospheric Profile Data"
                titleColor: qgcPal.text
                anchors.fill: parent
                antialiasing: true
                backgroundColor: "transparent"
                legend.labelColor: qgcPal.text

                ScatterSeries{
                    id: seriesTemp
                    name: "Temperature"
                    visible: tempCheck.checked
                    markerSize: _toolsMargin

                    axisX: ValueAxis {
                        visible: tempCheck.checked
                        labelsColor: qgcPal.text
                        min: tempMin
                        max: tempMax
                        labelsFont: Qt.font({pointSize: ScreenTools.defaultFontPointSize})
                    }
                    axisY: ValueAxis {
                        labelsColor: qgcPal.text
                        min: minAltitude
                        max: maxAltitude
                        labelsFont: Qt.font({pointSize: ScreenTools.defaultFontPointSize})
                    }
                }
                ScatterSeries{
                    id: seriesHumi
                    name: "Humidity"
                    visible: humiCheck.checked
                    markerSize: _toolsMargin
                    axisX: ValueAxis {
                        visible: humiCheck.checked
                        labelsColor: qgcPal.text
                        min: humiMin
                        max: humiMax
                        labelsFont: Qt.font({pointSize: ScreenTools.defaultFontPointSize})
                    }
                }
                ScatterSeries{
                    id: seriesPress
                    name: "Pressure"
                    visible: presCheck.checked
                    markerSize: _toolsMargin
                    axisX: ValueAxis {
                        visible: presCheck.checked
                        labelsColor: qgcPal.text
                        min: presMin
                        max: presMax
                        labelsFont: Qt.font({pointSize: ScreenTools.defaultFontPointSize})
                    }
                }
                ScatterSeries{
                    id: seriesWindDir
                    name: "WindDir"
                    visible: windDirCheck.checked
                    markerSize: _toolsMargin
                    axisX: ValueAxis {
                        visible: windDirCheck.checked
                        labelsColor: qgcPal.text
                        min: 0
                        max: 360
                        labelsFont: Qt.font({pointSize: ScreenTools.defaultFontPointSize})
                    }
                }
                ScatterSeries{
                    id: seriesWindSpd
                    name: "WindSpd"
                    visible: windSpdCheck.checked
                    markerSize: _toolsMargin
                    axisX: ValueAxis {
                        visible: windSpdCheck.checked
                        labelsColor: qgcPal.text
                        min: wnSpMin
                        max: wnSpMax
                        labelsFont: Qt.font({pointSize: ScreenTools.defaultFontPointSize})
                    }
                }
            }
        }
    }
}


