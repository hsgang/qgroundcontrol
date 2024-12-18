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
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Palette

//-------------------------------------------------------------------------
//-- Telemetry RSSI
Item {
    id:             control
    anchors.top:    parent.top
    anchors.bottom: parent.bottom
    width:          telemRow.width

    property bool showIndicator: _hasTelemetry

    property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    property bool _hasTelemetry:    _activeVehicle ? (_activeVehicle.telemetryLRSSI !== 0 || _activeVehicle.telemetryRRSSI !== 0 || _activeVehicle.telemetryTXBuffer !== 0 ) : false

    Component {
        id: telemRSSIInfo

        ToolIndicatorPage{
            showExpand: false

            property real _margins: ScreenTools.defaultFontPixelHeight / 2

            contentComponent: Component {
                ColumnLayout {
                    Layout.preferredWidth: parent.width
                    spacing:                _margins

                    QGCLabel {
                        id:                 telemLabel
                        text:               qsTr("Telemetry RSSI Status")
                        font.family:        ScreenTools.demiboldFontFamily
                        Layout.alignment:   Qt.AlignHCenter
                    }

                    Rectangle {
                        Layout.preferredHeight: telemColumnLayout.height + _margins //ScreenTools.defaultFontPixelHeight / 2
                        Layout.preferredWidth:  telemColumnLayout.width + _margins //ScreenTools.defaultFontPixelHeight
                        color:                  qgcPal.windowShade
                        radius:                 _margins / 2
                        Layout.fillWidth:       true

                        ColumnLayout {
                            id:                 telemColumnLayout
                            anchors.margins:    _margins / 2
                            anchors.top:        parent.top
                            anchors.left:       parent.left
                            anchors.right:      parent.right
                            spacing:            ScreenTools.defaultFontPixelHeight / 3

                            ComponentLabelValueRow {
                                labelText:  qsTr("Local RSSI")
                                valueText:  _activeVehicle.telemetryLRSSI + " dBm"
                            }
                            Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; }
                            ComponentLabelValueRow {
                                labelText:  qsTr("Remote RSSI")
                                valueText:  _activeVehicle.telemetryRRSSI + " dBm"
                            }
                            Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; }
                            ComponentLabelValueRow {
                                labelText:  qsTr("RX Errors")
                                valueText:  _activeVehicle.telemetryRXErrors
                            }
                            Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; }
                            ComponentLabelValueRow {
                                labelText:  qsTr("Errors Fixed")
                                valueText:  _activeVehicle.telemetryFixed
                            }
                            Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; }
                            ComponentLabelValueRow {
                                labelText:  qsTr("TX Buffer")
                                valueText:  _activeVehicle.telemetryTXBuffer
                            }
                            Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; }
                            ComponentLabelValueRow {
                                labelText:  qsTr("Local Noise")
                                valueText:  _activeVehicle.telemetryLNoise
                            }
                            Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; }
                            ComponentLabelValueRow {
                                labelText:  qsTr("Remote Noise")
                                valueText:  _activeVehicle.telemetryRNoise
                            }
                        }
                    }
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
            mainWindow.showIndicatorDrawer(telemRSSIInfo)
        }
    }
}
