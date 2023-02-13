/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.11
import QtQuick.Layouts  1.11

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0

//-------------------------------------------------------------------------
//-- Telemetry RSSI
Item {
    id:             _root
    width:          (extPowerStatusIcon.width + extPowerValuesColumn.width) * 1.1
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator:    true//QGroundControl.siyiSDKManager.isConnected

    property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
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

    property real _meanACInput : ((_acInputVolatage1Value + _acInputVolatage2Value + _acInputVolatage3Value) / 3).toFixed(1)
    property real _meanDCOutput: (((_dcOutputVolatage1Value + _dcOutputVolatage2Value + _dcOutputVolatage3Value) / 3) * ((_dcOutputCurrent1Value + _dcOutputCurrent2Value + _dcOutputCurrent3Value) / 3)).toFixed(1)

    Component {
        id: extPowerStatusInfo

        Rectangle {
            width:  extPowerCol.width   + ScreenTools.defaultFontPixelWidth  * 3
            height: extPowerCol.height  + ScreenTools.defaultFontPixelHeight * 2
            radius: ScreenTools.defaultFontPixelHeight * 0.5
            color:  qgcPal.window
            border.color:   qgcPal.text

            Column {
                id:                 extPowerCol
                spacing:            ScreenTools.defaultFontPixelHeight * 0.5
                width:              Math.max(extPowerGrid.width, extPowerLabel.width)
                anchors.margins:    ScreenTools.defaultFontPixelHeight
                anchors.centerIn:   parent

                QGCLabel {
                    id:             extPowerLabel
                    text:           qsTr("External Power Status")
                    font.family:    ScreenTools.demiboldFontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                GridLayout {
                    id:                 extPowerGrid
                    anchors.margins:    ScreenTools.defaultFontPixelHeight
                    columnSpacing:      ScreenTools.defaultFontPixelWidth
                    columns:            2
                    anchors.horizontalCenter: parent.horizontalCenter

                    QGCLabel { text: qsTr("AC1_V"); opacity: 0.7}
                    QGCLabel { text: _activeVehicle ? _activeVehicle.externalPowerStatus.acInputVolatage1.rawValue.toFixed(1) + " V": "No data"}
                    QGCLabel { text: qsTr("AC2_V"); opacity: 0.7}
                    QGCLabel { text: _activeVehicle ? _activeVehicle.externalPowerStatus.acInputVolatage2.rawValue.toFixed(1) + " V": "No data"}
                    QGCLabel { text: qsTr("AC3_V"); opacity: 0.7}
                    QGCLabel { text: _activeVehicle ? _activeVehicle.externalPowerStatus.acInputVolatage3.rawValue.toFixed(1) + " V": "No data"}
                    QGCLabel { text: qsTr("DC1_V"); opacity: 0.7}
                    QGCLabel { text: _activeVehicle ? _activeVehicle.externalPowerStatus.dcOutputVolatage1.rawValue.toFixed(1) + " V" : "No data"}
                    QGCLabel { text: qsTr("DC2_V"); opacity: 0.7}
                    QGCLabel { text: _activeVehicle ? _activeVehicle.externalPowerStatus.dcOutputVolatage2.rawValue.toFixed(1) + " V" : "No data"}
                    QGCLabel { text: qsTr("DC3_V"); opacity: 0.7}
                    QGCLabel { text: _activeVehicle ? _activeVehicle.externalPowerStatus.dcOutputVolatage3.rawValue.toFixed(1) + " V" : "No data"}
                    QGCLabel { text: qsTr("DC1_C"); opacity: 0.7}
                    QGCLabel { text: _activeVehicle ? _activeVehicle.externalPowerStatus.dcOutputCurrent1.rawValue.toFixed(1) + " A" : "No data"}
                    QGCLabel { text: qsTr("DC2_C"); opacity: 0.7}
                    QGCLabel { text: _activeVehicle ? _activeVehicle.externalPowerStatus.dcOutputCurrent2.rawValue.toFixed(1) + " A" : "No data"}
                    QGCLabel { text: qsTr("DC3_C"); opacity: 0.7}
                    QGCLabel { text: _activeVehicle ? _activeVehicle.externalPowerStatus.dcOutputCurrent3.rawValue.toFixed(1) + " A" : "No data"}
                    QGCLabel { text: qsTr("TEMP"); opacity: 0.7}
                    QGCLabel { text: _activeVehicle ? _activeVehicle.externalPowerStatus.temperature.rawValue.toFixed(1) + " ℃" : "No data"}
                    QGCLabel { text: qsTr("BATT"); opacity: 0.7}
                    QGCLabel { text: _activeVehicle ? _activeVehicle.externalPowerStatus.batteryVoltage.rawValue.toFixed(1) + " V" : "No data"}
                    QGCLabel { text: qsTr("STATUS"); opacity: 0.7}
                    QGCLabel { text: _activeVehicle ? _activeVehicle.externalPowerStatus.batteryChange.enumStringValue : "Unknown" }
                }
            }
        }
    }

    Row{
        id:         extPowerRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        spacing:        ScreenTools.defaultFontPixelWidth/4

        QGCColoredImage {
            id:                 extPowerStatusIcon
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            anchors.margins:    ScreenTools.defaultFontPixelWidth/2
            width:              height * 0.9
            sourceSize.height:  height * 0.9
            source:             "/qmlimages/ExternalPower.svg"
            fillMode:           Image.PreserveAspectFit
            color:              _meanACInput > 170 ? qgcPal.buttonText : qgcPal.colorRed
        }
        Column {
            id:                     extPowerValuesColumn
            anchors.verticalCenter: parent.verticalCenter
//            anchors.leftMargin:     ScreenTools.defaultFontPixelWidth / 2
//            anchors.left:           siyiStatusIcon.right

            QGCLabel {
                anchors.horizontalCenter:   parent.horizontalCenter
                color:                      qgcPal.buttonText
                text:                       _acInputVolatage1Value ? _meanACInput + "V" : "No data"
            }

            QGCLabel {
                anchors.horizontalCenter:   parent.horizontalCenter
                color:                      qgcPal.buttonText
                text:                       _dcOutputVolatage1Value ? _meanDCOutput + "W" : "No data"
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            mainWindow.showIndicatorPopup(_root, extPowerStatusInfo)
        }
    }
}
