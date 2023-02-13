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
    id:         externalPowerView
    height:     externalPowerValueColumn.height + ScreenTools.defaultFontPixelHeight * 0.5
    width:      externalPowerValueColumn.width + ScreenTools.defaultFontPixelWidth * 3
    color:      "#80000000"
    radius:     _margins
    border.color: qgcPal.text

    property var  _activeVehicle:           QGroundControl.multiVehicleManager.activeVehicle
    property real _acInputVolatage1Value:   _activeVehicle ? _activeVehicle.externalPowerStatus.acInputVolatage1.rawValue.toFixed(1) : NaN
    property real _acInputVolatage2Value:   _activeVehicle ? _activeVehicle.externalPowerStatus.acInputVolatage2.rawValue.toFixed(1) : NaN
    property real _acInputVolatage3Value:   _activeVehicle ? _activeVehicle.externalPowerStatus.acInputVolatage3.rawValue.toFixed(1) : NaN
    property real _dcOutputVolatage1Value:  _activeVehicle ? _activeVehicle.externalPowerStatus.dcOutputVolatage1.rawValue.toFixed(1) : NaN
    property real _dcOutputVolatage2Value:  _activeVehicle ? _activeVehicle.externalPowerStatus.dcOutputVolatage2.rawValue.toFixed(1) : NaN
    property real _dcOutputVolatage3Value:  _activeVehicle ? _activeVehicle.externalPowerStatus.dcOutputVolatage3.rawValue.toFixed(1) : NaN
    property real _dcOutputCurrent1Value:   _activeVehicle ? _activeVehicle.externalPowerStatus.dcOutputCurrent1.rawValue.toFixed(1) : NaN
    property real _dcOutputCurrent2Value:   _activeVehicle ? _activeVehicle.externalPowerStatus.dcOutputCurrent2.rawValue.toFixed(1) : NaN
    property real _dcOutputCurrent3Value:   _activeVehicle ? _activeVehicle.externalPowerStatus.dcOutputCurrent3.rawValue.toFixed(1) : NaN
    property real _temperatureValue:        _activeVehicle ? _activeVehicle.externalPowerStatus.temperature.rawValue.toFixed(1) : NaN
    property real _batteryVoltageValue:     _activeVehicle ? _activeVehicle.externalPowerStatus.batteryVoltage.rawValue.toFixed(1) : NaN
    property real _batteryChangeValue:      _activeVehicle ? _activeVehicle.externalPowerStatus.batteryChange.rawValue.toFixed(0) : NaN

    property real _preferredWidth : ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 6 : ScreenTools.defaultFontPixelWidth * 9

    property bool _converterWork : _activeVehicle ? _batteryChangeValue == 0 | _batteryChangeValue == 2 | _batteryChangeValue == 3 : false
    property bool _batteryWork : _activeVehicle ? _batteryChangeValue == 1 | _batteryChangeValue == 2 | _batteryChangeValue == 3 : false

    Column{
        id:                 externalPowerValueColumn
        spacing:            ScreenTools.defaultFontPixelWidth
        width:              Math.max(externalPowerStatusViewLabel.width, externalPowerStatusViewer.width)
        anchors.margins:    ScreenTools.defaultFontPixelHeight
        anchors.centerIn:   parent

        QGCLabel {
            id:     externalPowerStatusViewLabel
            text:   qsTr("External Power Status")
            font.family:    ScreenTools.demiboldFontFamily
            anchors.horizontalCenter: parent.horizontalCenter
        }       

        GridLayout{
            id: externalPowerStatusViewer
            anchors.margins:            ScreenTools.defaultFontPixelHeight
            //anchors.verticalCenter:     parnet.verticalCenter
            rows: 5

            Rectangle{
                width: ScreenTools.defaultFontPixelHeight * 3
                height: ScreenTools.defaultFontPixelHeight * 3
                color: "transparent"
                radius: _margins
                border.color: _batteryChangeValue == 1 | _batteryChangeValue == 2 ? "red" : qgcPal.text

                QGCColoredImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top:        parent.top
                    anchors.bottom:     parent.bottom
                    anchors.margins:    _margins
                    width:              height * 0.9
                    sourceSize.width:   width
                    source:             "/InstrumentValueIcons/servers.svg"
                    fillMode:           Image.PreserveAspectFit
                    color:              _batteryChangeValue == 1 | _batteryChangeValue == 2 ? "red" : qgcPal.text
                }
            }

            Rectangle {
                width: ScreenTools.defaultFontPixelWidth * 4
                height: ScreenTools.defaultFontPixelHeight
                color: "transparent"

                property int currentRectangle: 1

                Timer {
                    interval: 500
                    running: true
                    repeat: true
                    onTriggered: parent.currentRectangle = (parent.currentRectangle % 4) + 1
                }

                Rectangle {
                    width: ScreenTools.defaultFontPixelWidth
                    height: ScreenTools.defaultFontPixelHeight
                    x: 0
                    color: _converterWork == true && parent.currentRectangle == 1 ? "green" : "transparent"
                    border.color: qgcPal.text
                }

                Rectangle {
                    width: ScreenTools.defaultFontPixelWidth
                    height: ScreenTools.defaultFontPixelHeight
                    x: ScreenTools.defaultFontPixelWidth
                    color: _converterWork == true && parent.currentRectangle == 2 ? "green" : "transparent"
                    border.color: qgcPal.text
                }

                Rectangle {
                    width: ScreenTools.defaultFontPixelWidth
                    height: ScreenTools.defaultFontPixelHeight
                    x: ScreenTools.defaultFontPixelWidth * 2
                    color: _converterWork == true && parent.currentRectangle == 3 ? "green" : "transparent"
                    border.color: qgcPal.text
                }
                Rectangle {
                    width: ScreenTools.defaultFontPixelWidth
                    height: ScreenTools.defaultFontPixelHeight
                    x: ScreenTools.defaultFontPixelWidth * 3
                    color: _converterWork == true && parent.currentRectangle == 4 ? "green" : "transparent"
                    border.color: qgcPal.text
                }
            }

            Rectangle{
                width: ScreenTools.defaultFontPixelHeight * 3
                height: ScreenTools.defaultFontPixelHeight * 3
                color: "transparent"
                radius: _margins
                border.color: qgcPal.text

                QGCColoredImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top:        parent.top
                    anchors.bottom:     parent.bottom
                    anchors.margins:    _margins
                    width:              height * 0.9
                    sourceSize.width:   width
                    source:             "/qmlimages/Quad.svg"
                    fillMode:           Image.PreserveAspectFit
                    color:              qgcPal.text
                }
            }

            Rectangle{
                width: ScreenTools.defaultFontPixelWidth * 4
                height: ScreenTools.defaultFontPixelHeight
                color: "transparent"

                property int currentRectangle: 1

                Timer {
                    interval: 500
                    running: true
                    repeat: true
                    onTriggered: parent.currentRectangle = (parent.currentRectangle % 4) + 1
                }

                Rectangle {
                    width: ScreenTools.defaultFontPixelWidth
                    height: ScreenTools.defaultFontPixelHeight
                    x: 0
                    color: _batteryWork == true && parent.currentRectangle == 4 ? "red" : "transparent"
                    border.color: qgcPal.text
                }

                Rectangle {
                    width: ScreenTools.defaultFontPixelWidth
                    height: ScreenTools.defaultFontPixelHeight
                    x: ScreenTools.defaultFontPixelWidth
                    color: _batteryWork == true && parent.currentRectangle == 3 ? "red" : "transparent"
                    border.color: qgcPal.text
                }

                Rectangle {
                    width: ScreenTools.defaultFontPixelWidth
                    height: ScreenTools.defaultFontPixelHeight
                    x: ScreenTools.defaultFontPixelWidth * 2
                    color: _batteryWork == true && parent.currentRectangle == 2 ? "red" : "transparent"
                    border.color: qgcPal.text
                }

                Rectangle {
                    width: ScreenTools.defaultFontPixelWidth
                    height: ScreenTools.defaultFontPixelHeight
                    x: ScreenTools.defaultFontPixelWidth * 3
                    color: _batteryWork == true && parent.currentRectangle == 1 ? "red" : "transparent"
                    border.color: qgcPal.text
                }
            }

            Rectangle{
                width: ScreenTools.defaultFontPixelHeight * 3
                height: ScreenTools.defaultFontPixelHeight * 3
                color: "transparent"
                radius: _margins
                border.color: qgcPal.text

                QGCColoredImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top:        parent.top
                    anchors.bottom:     parent.bottom
                    anchors.margins:    _margins
                    width:              height * 0.9
                    sourceSize.width:   width
                    source:             "/qmlimages/Battery.svg"
                    fillMode:           Image.PreserveAspectFit
                    color:              qgcPal.text
                }
            }
        }

//        GridLayout {
//            id:                         externalPowerStatusValueGrid
//            anchors.margins:            ScreenTools.defaultFontPixelHeight
//            columnSpacing:              ScreenTools.defaultFontPixelWidth
//            anchors.horizontalCenter:   parent.horizontalCenter
//            columns: 2

//            QGCLabel { text: qsTr("AC1_V"); opacity: 0.7}
//            QGCLabel { text: _acInputVolatage1Value ? _acInputVolatage1Value + " V" : "No data"}

//            QGCLabel { text: qsTr("AC2_V"); opacity: 0.7}
//            QGCLabel { text: _acInputVolatage2Value ? _acInputVolatage2Value + " V": "No data"}

//            QGCLabel { text: qsTr("AC3_V"); opacity: 0.7}
//            QGCLabel { text: _acInputVolatage3Value ? _acInputVolatage3Value + " V": "No data"}

//            QGCLabel { text: qsTr("DC1_V"); opacity: 0.7}
//            QGCLabel { text: _dcOutputVolatage1Value ? _dcOutputVolatage1Value + " V" : "No data"}

//            QGCLabel { text: qsTr("DC2_V"); opacity: 0.7}
//            QGCLabel { text: _dcOutputVolatage2Value ? _dcOutputVolatage2Value + " V" : "No data"}

//            QGCLabel { text: qsTr("DC3_V"); opacity: 0.7}
//            QGCLabel { text: _dcOutputVolatage3Value ? _dcOutputVolatage3Value + " V" : "No data"}

//            QGCLabel { text: qsTr("DC1_C"); opacity: 0.7}
//            QGCLabel { text: _dcOutputCurrent1Value ? _dcOutputCurrent1Value + " A" : "No data"}

//            QGCLabel { text: qsTr("DC2_C"); opacity: 0.7}
//            QGCLabel { text: _dcOutputCurrent2Value ? _dcOutputCurrent2Value + " A" : "No data"}

//            QGCLabel { text: qsTr("DC3_C"); opacity: 0.7}
//            QGCLabel { text: _dcOutputCurrent3Value ? _dcOutputCurrent3Value + " A" : "No data"}

//            QGCLabel { text: qsTr("TEMP"); opacity: 0.7}
//            QGCLabel { text: _temperatureValue ? _temperatureValue + " ℃" : "No data"}

//            QGCLabel { text: qsTr("BATT"); opacity: 0.7}
//            QGCLabel { text: _batteryVoltageValue ? _batteryVoltageValue + " V" : "No data"}

//            QGCLabel { text: qsTr("STATUS"); opacity: 0.7}
//            QGCLabel { text: _batteryChangeValue ? _batteryChangeValue : "No data"}
//        }
    }
}

