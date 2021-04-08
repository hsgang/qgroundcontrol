/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.4
import QtPositioning            5.2
import QtQuick.Layouts          1.2
import QtQuick.Controls         1.4
import QtQuick.Dialogs          1.2
import QtGraphicalEffects       1.0

import QGroundControl                   1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.Controls          1.0
import QGroundControl.Palette           1.0
import QGroundControl.Vehicle           1.0
import QGroundControl.Controllers       1.0
import QGroundControl.FactSystem        1.0
import QGroundControl.FactControls      1.0

Rectangle {
    id:         panel
    height:     columnLayout.height + _margins*2
    color:      "#80000000"
    radius:     _margins

    property real _margins:                                   ScreenTools.defaultFontPixelHeight / 2

    property bool isShowSensorChart: false
    property bool isShowTemperature: false
    property bool isShowHumidity: false
    property bool isShowBarometer: false
    property bool isShowWindDir: false
    property bool isShowWindSpd: false

    ColumnLayout{
        id:columnLayout
        spacing: _margins
        anchors.horizontalCenter: panel.horizontalCenter

        GridLayout{
            id:     gridLayout
            columns: 2

            QGCSwitch{
                id:showSensorChart
                //text: qsTr("Show SensorChart")
                onClicked: {
                    if(checked){
                        isShowSensorChart = true
                    } else{
                        isShowSensorChart = false
                    }
                }
            }
            QGCLabel{
                text: qsTr("SensorChart")
            }
            QGCSwitch{
                id:qgcSwitch_temp
                visible: isShowSensorChart
                onClicked: {
                    if(checked){
                        isShowTemperature = true
                    } else{
                        isShowTemperature = false
                    }
                }
            }
            QGCLabel{
                visible: isShowSensorChart
                text: qsTr("Temperature")
            }
            QGCSwitch{
                id:qgcSwitch_humi
                visible: isShowSensorChart
                onClicked: {
                    if(checked){
                        isShowHumidity = true
                    } else{
                        isShowHumidity = false
                    }
                }
            }
            QGCLabel{
                visible: isShowSensorChart
                text: qsTr("Humidity")
            }
            QGCSwitch{
                id:qgcSwitch_baro
                visible: isShowSensorChart
                onClicked: {
                    if(checked){
                        isShowBarometer = true
                    } else{
                        isShowBarometer = false
                    }
                }
            }
            QGCLabel{
                visible: isShowSensorChart
                text: qsTr("Pressure")
            }
            QGCSwitch{
                id:qgcSwitch_windDir
                visible: isShowSensorChart
                onClicked: {
                    if(checked){
                        isShowWindDir = true
                    } else{
                        isShowWindDir = false
                    }
                }
            }
            QGCLabel{
                visible: isShowSensorChart
                text: qsTr("WindDir")
            }
            QGCSwitch{
                id:qgcSwitch_windSpd
                visible: isShowSensorChart
                onClicked: {
                    if(checked){
                        isShowWindSpd = true
                    } else{
                        isShowWindSpd = false
                    }
                }
            }
            QGCLabel{
                visible: isShowSensorChart
                text: qsTr("WindSpd")
            }
        }
    }
}
