import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

import QtQuick.Window
import QtQml.Models

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FlightDisplay
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.Vehicle

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

    function setAltRange(){
        if(_vehicleAltitude > maxAltitude - 5){
            maxAltitude = _vehicleAltitude + 5
        } else if(_vehicleAltitude < minAltitude + 5){
            minAltitude = _vehicleAltitude - 5
        }
    }

    function setTempRange(){
        if(_temperatureValue > tempMax - 2){
            tempMax = _temperatureValue + 2
        } else if(_temperatureValue < tempMin + 2){
            tempMin = _temperatureValue - 2
        }
    }

    function setHumiRange(){
        if(_humidityValue > humiMax - 5){
            humiMax = _humidityValue + 5
        } else if(_humidityValue < humiMin + 5){
            humiMin = _humidityValue - 5
        }
    }

    function setPressRange(){
        if(_pressureValue > presMax - 5){
            presMax = _pressureValue + 5
        } else if(_pressureValue < presMin + 5){
            presMin = _pressureValue - 5
        }
    }

    function setWindSpdRange(){
        if(_windSpdValue > wnSpMax - 5){
            wnSpMax = _windSpdValue + 5
        } else if(_windSpdValue < wnSpMin + 5){
            wnSpMin = _windSpdValue - 5
        }
    }

    function updateAtmosphericData(){

        var diffValue = Math.abs(_vehicleAltitude - preValue)

        if(diffValue >= diffGapValue) {
            preValue = _vehicleAltitude

            setAltRange()
            setTempRange()
            setHumiRange()
            setPressRange()
            setWindSpdRange()

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
        tempMin = 0
        tempMax = 0
        humiMin = 0
        humiMax = 0
        presMin = 0
        presMax = 0
        wnDrMin = 0
        wnDrMax = 360
        wnSpMin = 0
        wnSpMax = 0
        }

    Connections{
        target: _activeVehicle
        onAtmosphericValueChanged: {
            updateAtmosphericData()
        }
    }

    Rectangle {
        id: chartRectangle
        anchors.margins: _toolsMargin
        anchors.fill: parent
        width: parent.width
        height: parent.height
        color : Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5)
        border.color: qgcPal.text
        border.width: 1
        radius : _toolsMargin

        DeadMouseArea {
            anchors.fill: parent
        }

        QGCFlickable {
            id:                 flickable
            anchors.margins:    ScreenTools.defaultFontPixelHeight * 0.2
            anchors.top:        parent.top
            anchors.right:      parent.right
            width:              checkBoxRow.width + _toolsMargin * 2
            height:             parent.height - ScreenTools.defaultFontPixelHeight * 0.4
            contentHeight:      checkBoxRow.height
            flickableDirection: Flickable.VerticalFlick
            clip:               true

            ColumnLayout{
                id: checkBoxRow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: _toolsMargin
                spacing: ScreenTools.defaultFontPixelHeight / 4

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

                Item{
                    height: ScreenTools.defaultFontPixelHeight
                }

                QGCLabel{
                    text: "Interval(m)"
                }

                QGCTextField{
                    id: intervalTextField
                    placeholderText: qsTr("Alt Interval")
                    implicitWidth: parent.width//ScreenTools.defaultFontPixelWidth * 8
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

                QGCButton{
                    text: "Clear"
                    implicitWidth: parent.width
                    onClicked:  {
                        clearChart()
                    }
                }
            }
        }

        Rectangle{
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: flickable.left
            anchors.bottom: parent.bottom
            color: "transparent"

            ChartView{
                id: customChartView
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


