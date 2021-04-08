import QtQuick                      2.12
import QtQuick.Controls             2.4
import QtQuick.Layouts              1.12
import QtCharts                     2.3

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0
import QGroundControl.Controls      1.0
import QGroundControl.Palette       1.0

Rectangle {
    id:                 sensorChartPanel
    //height:             chartView.height + (_toolsMargin * 2)
    width:              chartView.width + (_toolsMargin * 2)
    color:              qgcPal.window
    radius:             ScreenTools.defaultFontPixelWidth / 2
    opacity:            0.7

    ChartView {
        id: chartView
        //readonly property var startDate: new Date('1995-12-17T03:20:00')
        readonly property var startDate: new Date()
        anchors.fill: parent
        anchors.margins: 0
        antialiasing: true
        //legend.visible: false
        theme:ChartView.ChartThemeQt
        backgroundColor: "transparent"
        //plotArea: Qt.rect(chartView.x-10, chartView.y-10, chartView.width+10, chartView.height+10)

                // The number of vertical tick lines to scroll to the right
        function scrollTicksRight(ticks) {
            chartView.scrollRight(axisX.tickDistance() * ticks)
        }

        Timer {
            property var  _activeVehicle:       QGroundControl.multiVehicleManager.activeVehicle
            property real _sensorTemp: _activeVehicle ? _activeVehicle.sensor.sensorTemp.rawValue : 0
            property real _sensorHumi: _activeVehicle ? _activeVehicle.sensor.sensorHumi.rawValue : 0
            property real _sensorBaro: _activeVehicle ? _activeVehicle.sensor.sensorBaro.rawValue : 0
            property real _sensorWindDir: _activeVehicle ? _activeVehicle.sensor.sensorWindDir.rawValue : 0
            property real _sensorWindSpd: _activeVehicle ? _activeVehicle.sensor.sensorWindSpd.rawValue : 0

            property real hz: 10
            property real period: 1 / hz
            property real periodMs: period * 1000
            property int counter: 0
            property real sinusStep: 0
            function generateAndAppendPoint() {
                let x = chartView.startDate.getTime() + counter
                //let y = 5 * Math.cos(sinusStep) + 5
                let yTemp = _sensorTemp
                let yHumi = _sensorHumi
                let yBaro = _sensorBaro
                let yWindDir = _sensorWindDir
                let yWindSpd = _sensorWindSpd
                splineSeries_temp.append(x, yTemp)
                splineSeries_humi.append(x, yHumi)
                splineSeries_baro.append(x, yBaro)
                splineSeries_windDir.append(x, yWindDir)
                splineSeries_windSpd.append(x, yWindSpd)
                counter += periodMs
                sinusStep += 0.1
                if (x > dataTimeAxis.max)
                    chartView.scrollRight(10)
            }
            interval: periodMs
            running: true
            repeat: true
            onTriggered: generateAndAppendPoint()
        }

        ValueAxis{
        }

        DateTimeAxis{
            id: dataTimeAxis
            // The distance between two vertical tick lines
            function tickDistance() {
                return (chartView.plotArea.width / (axisX.tickCount - 1))
            }
            // Remove points that are no longer visible
            function removeOldPoints() {
                let pointsToRemove = 0
                let size = splineSeries_temp.count
                for (let i = 0; i < size; i++) {
                    if (splineSeries_temp.at(i).x < min)
                        pointsToRemove++
                    else
                        break
                }
                splineSeries_temp.removePoints(0, pointsToRemove)
            }
            tickCount: 6
            format: "mm:ss"
            min: chartView.startDate
            max: new Date(chartView.startDate.getTime() + 1800000)
            onMinChanged: removeOldPoints()
        }

        SplineSeries {
            id: splineSeries_temp
            name: "Temperature"
            useOpenGL: true
            visible: externalSensorControl.isShowTemperature
            function newestPoint() {
                return splineSeries_temp.at(splineSeries_temp.count - 1)
            }
            axisX: dataTimeAxis
            axisY: ValueAxis {
                visible: externalSensorControl.isShowTemperature
                titleText: "Temp[&deg;c]"
                min: -20
                max: 50
            }
        }
        SplineSeries {
            id: splineSeries_humi
            name: "Humidity"
            useOpenGL: true
            visible: externalSensorControl.isShowHumidity
            function newestPoint() {
                return splineSeries_humi.at(splineSeries_humi.count - 1)
            }
            axisX: dataTimeAxis
            axisY: ValueAxis {
                visible: externalSensorControl.isShowHumidity
                titleText: "Humi[RH%]"
                min: 0
                max: 100
            }
        }
        SplineSeries {
            id: splineSeries_baro
            name: "Pressure"
            useOpenGL: true
            visible: externalSensorControl.isShowBarometer
            function newestPoint() {
                return splineSeries_baro.at(splineSeries_baro.count - 1)
            }
            axisX: dataTimeAxis
            axisY: ValueAxis {
                visible: externalSensorControl.isShowBarometer
                titleText: "Pressure[hPa]"
                min: 700
                max: 1050
            }
        }
        SplineSeries {
            id: splineSeries_windDir
            name: "WindDir"
            useOpenGL: true
            visible: externalSensorControl.isShowWindDir
            function newestPoint() {
                return splineSeries_windDir.at(splineSeries_windDir.count - 1)
            }
            axisX: dataTimeAxis
            axisY: ValueAxis {
                visible: externalSensorControl.isShowWindDir
                titleText: "windDir[&deg;]"
                min: 0
                max: 360
            }
        }
        SplineSeries {
            id: splineSeries_windSpd
            name: "WindSpd"
            useOpenGL: true
            visible: externalSensorControl.isShowWindSpd
            function newestPoint() {
                return splineSeries_windSpd.at(splineSeries_windSpd.count - 1)
            }
            axisX: dataTimeAxis
            axisY: ValueAxis {
                visible: externalSensorControl.isShowWindSpd
                titleText: "windSpd"
                min: -5
                max: 20
            }
        }
    }
}
