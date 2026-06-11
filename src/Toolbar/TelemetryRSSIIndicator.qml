import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

//-------------------------------------------------------------------------
//-- Telemetry RSSI
Item {
    id:             control
    objectName:     "toolbar_telemetryRSSIIndicator"
    anchors.top:    parent.top
    anchors.bottom: parent.bottom
    width:          telemRow.width

    property bool showIndicator: _hasTelemetry

    property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    property var  _radioStatus:     _activeVehicle.radioStatus
    property bool _hasTelemetry:    _radioStatus.lrssi.rawValue !== 0

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
                    labelText:  _radioStatus.lrssi.rawValue + " " + qsTr("dBm")
                }

                LabelledLabel {
                    label:      qsTr("Remote RSSI:")
                    labelText:  _radioStatus.rrssi.rawValue + " " + qsTr("dBm")
                }

                LabelledLabel {
                    label:      qsTr("RX Errors:")
                    labelText:  _radioStatus.rxErrors.rawValue
                }

                LabelledLabel {
                    label:      qsTr("Errors Fixed:")
                    labelText:  _radioStatus.fixed.rawValue
                }

                LabelledLabel {
                    label:      qsTr("TX Buffer:")
                    labelText:  _radioStatus.txBuffer.rawValue
                }

                LabelledLabel {
                    label:      qsTr("Local Noise:")
                    labelText:  _radioStatus.lNoise.rawValue
                }

                LabelledLabel {
                    label:      qsTr("Remote Noise:")
                    labelText:  _radioStatus.rNoise.rawValue
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
                font.family:                ScreenTools.fixedFontFamily
                text:                       _activeVehicle ? _radioStatus.lrssi.rawValue : 0
            }
            QGCLabel {
                anchors.horizontalCenter:   parent.horizontalCenter
                color:                      qgcPal.buttonText
                font.family:                ScreenTools.fixedFontFamily
                text:                       _activeVehicle ? _radioStatus.rrssi.rawValue : 0
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
