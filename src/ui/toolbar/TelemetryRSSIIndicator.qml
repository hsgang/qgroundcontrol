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
    anchors.top:    parent.top
    anchors.bottom: parent.bottom
    width:          telemRow.width

    property bool showIndicator: _hasTelemetry

    property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    property bool _hasTelemetry:    _activeVehicle ? (_activeVehicle.telemetryLRSSI !== 0 || _activeVehicle.telemetryRRSSI !== 0) : false

    Component {
        id: telemRSSIInfo
        Rectangle {
            width:  telemCol.width   + ScreenTools.defaultFontPixelWidth  * 3
            height: telemCol.height  + ScreenTools.defaultFontPixelHeight * 2
            radius: ScreenTools.defaultFontPixelHeight * 0.5
            color:  qgcPal.window
            border.color:   qgcPal.text
            Column {
                id:                 telemCol
                spacing:            ScreenTools.defaultFontPixelHeight * 0.5
                width:              Math.max(telemGrid.width, telemLabel.width)
                anchors.margins:    ScreenTools.defaultFontPixelHeight
                anchors.centerIn:   parent
                QGCLabel {
                    id:             telemLabel
                    text:           qsTr("Telemetry RSSI Status")
                    font.family:    ScreenTools.demiboldFontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                GridLayout {
                    id:                 telemGrid
                    anchors.margins:    ScreenTools.defaultFontPixelHeight
                    columnSpacing:      ScreenTools.defaultFontPixelWidth
                    columns:            2
                    anchors.horizontalCenter: parent.horizontalCenter
                    QGCLabel { text: qsTr("Local RSSI:") }
                    QGCLabel { text: _activeVehicle.telemetryLRSSI + " dBm"}
                    QGCLabel { text: qsTr("Remote RSSI:") }
                    QGCLabel { text: _activeVehicle.telemetryRRSSI + " dBm"}
                    QGCLabel { text: qsTr("RX Errors:") }
                    QGCLabel { text: _activeVehicle.telemetryRXErrors }
                    QGCLabel { text: qsTr("Errors Fixed:") }
                    QGCLabel { text: _activeVehicle.telemetryFixed }
                    QGCLabel { text: qsTr("TX Buffer:") }
                    QGCLabel { text: _activeVehicle.telemetryTXBuffer }
                    QGCLabel { text: qsTr("Local Noise:") }
                    QGCLabel { text: _activeVehicle.telemetryLNoise }
                    QGCLabel { text: qsTr("Remote Noise:") }
                    QGCLabel { text: _activeVehicle.telemetryRNoise }
                }
            }
        }
    }

    Row{
        id:                 telemRow
        anchors.top:        parent.top
        anchors.bottom:     parent.bottom
        spacing:            ScreenTools.defaultFontPixelWidth / 2

        QGCColoredImage {
            id:                 telemIcon
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            width:              height
            sourceSize.height:  height
            source:             "/qmlimages/TelemRSSI.svg"
            fillMode:           Image.PreserveAspectFit
            color:              qgcPal.buttonText
        }

        Column {
            id:                     telemValuesColumn
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins:        ScreenTools.defaultFontPixelWidth / 2
            width:                  ScreenTools.defaultFontPixelWidth * 3

            QGCLabel {
                anchors.horizontalCenter:   parent.horizontalCenter
                color:                      qgcPal.buttonText
                text:                       _activeVehicle ? _activeVehicle.telemetryLRSSI : 0
            }
            QGCLabel {
                anchors.horizontalCenter:   parent.horizontalCenter
                color:                      qgcPal.buttonText
                text:                       _activeVehicle ? _activeVehicle.telemetryRRSSI : 0
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            mainWindow.showIndicatorPopup(_root, telemRSSIInfo)
        }
    }
}
