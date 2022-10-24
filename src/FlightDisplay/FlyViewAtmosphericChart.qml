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
    property real   _altitudeValue:       _activeVehicle ? _activeVehicle.altitudeRelative.rawValue.toFixed(1) : 0

    property real   preAltitudeValue: 0
    property real   preValue: 0
    property real   maxAltitude: 0
    property real   diffGapValue: 0.1

    function getMaxAltitude(){
        if(_vehicleAltitude > preAltitudeValue){
            preAltitudeValue = _vehicleAltitude
            maxAltitude = _vehicleAltitude
        }
    }

    function atmosphericDataGet(){

        console.log(" ttttt")

        var diffValue = Math.abs(_vehicleAltitude - preValue)

        if(diffValue >= diffGapValue) {
            seriesTemp.append(_temperatureValue, _vehicleAltitude)
            seriesHumi.append(_humidityValue, _vehicleAltitude)
            seriesPress.append(_pressureValue, _vehicleAltitude)
            seriesWindDir.append(_windDirValue, _vehicleAltitude)
            seriesWindSpd.append(_windSpdValue, _vehicleAltitude)
            preValue = _vehicleAltitude
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
        }

    Connections{
        target: _activeVehicle
        onAtmosphericValueChanged: {
        //onCoordinateChanged:{
            atmosphericDataGet()
            getMaxAltitude()
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

        RowLayout{
            id: checkBoxRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: _toolsMargin

            CheckBox {
                id: tempCheck
                style: CheckBoxStyle {
                    label: Text {
                        color: qgcPal.text
                        text: "Temperature"
                    }
                }
            }
            CheckBox {
                id: humiCheck
                style: CheckBoxStyle {
                    label: Text {
                        color: qgcPal.text
                        text: "Humidity"
                    }
                }
            }
            CheckBox {
                id: presCheck
                style: CheckBoxStyle {
                    label: Text {
                        color: qgcPal.text
                        text: "Pressure"
                    }
                }
            }
            CheckBox {
                id: windDirCheck
                style: CheckBoxStyle {
                    label: Text {
                        color: qgcPal.text
                        text: "WindDir"
                    }
                }
            }
            CheckBox {
                id: windSpdCheck
                style: CheckBoxStyle {
                    label: Text {
                        color: qgcPal.text
                        text: "WindSpd"
                    }
                }
            }

            QGCButton{
                text: "Clear"
                onClicked:  {
                    clearChart()
                }
            }
        }

        Rectangle{
            anchors.top: checkBoxRow.bottom
            anchors.left: parent.left
            anchors.right: parent.right
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
                        min: -20
                        max: 40
                    }
                    axisY: ValueAxis {
                        labelsColor: qgcPal.text
                        min: 0
                        max: maxAltitude + 10
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
                        min: 0
                        max: 100
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
                        min: 500
                        max: 1050
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
                        min: 0
                        max: 20
                    }
                }
            }
        }
    }

}


