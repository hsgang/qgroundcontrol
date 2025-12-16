/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

//-------------------------------------------------------------------------
//-- Telemetry RSSI
Item {
    id:             control
    anchors.top:    parent.top
    anchors.bottom: parent.bottom
    width:          telemRow.width

    property bool showIndicator: _hasTelemetry

    property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    property bool _hasTelemetry:    _activeVehicle.telemetryLRSSI !== 0

    // QGCColoredImage {
    //     id:                 telemIcon
    //     anchors.top:        parent.top
    //     anchors.bottom:     parent.bottom
    //     width:              height
    //     sourceSize.height:  height
    //     source:             "/qmlimages/TelemRSSI.svg"
    //     fillMode:           Image.PreserveAspectFit
    //     color:              qgcPal.buttonText
    // }

    Component {
        id: telemRSSIInfo

        ToolIndicatorPage{
            showExpand: false

            contentComponent: SettingsGroupLayout {
                heading: qsTr("Telemetry RSSI Status")

                LabelledLabel {
                    label:      qsTr("Local RSSI:")
                    labelText:  _activeVehicle.telemetryLRSSI + " " + qsTr("dBm")
                }

                LabelledLabel {
                    label:      qsTr("Remote RSSI:")
                    labelText:  _activeVehicle.telemetryRRSSI + " " + qsTr("dBm")
                }

                LabelledLabel {
                    label:      qsTr("RX Errors:")
                    labelText:  _activeVehicle.telemetryRXErrors
                }

                LabelledLabel {
                    label:      qsTr("Errors Fixed:")
                    labelText:  _activeVehicle.telemetryFixed
                }

                LabelledLabel {
                    label:      qsTr("TX Buffer:")
                    labelText:  _activeVehicle.telemetryTXBuffer
                }

                LabelledLabel {
                    label:      qsTr("Local Noise:")
                    labelText:  _activeVehicle.telemetryLNoise
                }

                LabelledLabel {
                    label:      qsTr("Remote Noise:")
                    labelText:  _activeVehicle.telemetryRNoise
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
            //mainWindow.showIndicatorPopup(_root, telemRSSIInfo)
            mainWindow.showIndicatorDrawer(telemRSSIInfo, control)
        }
    }
}
