import QtQuick          2.11
import QtQuick.Layouts  1.11

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0

import SiYi.Object 1.0

Item {
    id:             _root
    width:          siyirssiRow.width
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property SiYiTransmitter transmitter:   SiYi.transmitter

    property bool showIndicator:            transmitter.isConnected
    property var  _activeVehicle:           QGroundControl.multiVehicleManager.activeVehicle
    property real _columnSpacing:   ScreenTools.defaultFontPixelHeight / 3
    property real _margins:         ScreenTools.defaultFontPixelHeight / 2

    Row{
        id:             siyirssiRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        spacing:        ScreenTools.defaultFontPixelWidth / 2

        Column {
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin:     ScreenTools.defaultFontPixelWidth / 2

            QGCLabel {
                anchors.right:      parent.right
                font.pointSize:     ScreenTools.smallFontPointSize
                color:              qgcPal.text
                text:               (transmitter.downStream / 1024).toFixed(0) + "KB"
            }

            QGCLabel {
                anchors.right:      parent.right
                color:              qgcPal.text
                text:               transmitter.rssi
            }
        }

        Rectangle{
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            height:             parent.height
            width:              height
            color:              "transparent"

            SignalStrength {
                anchors.horizontalCenter:   parent.horizontalCenter
                anchors.verticalCenter:     parent.verticalCenter
                size:                       parent.height * 0.9
                percent:                    transmitter.signalQuality
            }

            QGCColoredImage {
                id:                 siyiStatusIcon
                anchors.top:        parent.top
                anchors.left:       parent.left
                width:              parent.width / 2
                height:             width
                sourceSize.height:  height
                source:             "/qmlimages/TelemRSSI.svg"
                fillMode:           Image.PreserveAspectFit
                color:              transmitter.signalQuality > 10 ? qgcPal.buttonText : qgcPal.colorOrange
            }
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorDrawer(siyiStatusInfo)
    }

    Component {
        id: siyiStatusInfo

        ToolIndicatorPage{
            showExpand: false

            property real _margins: ScreenTools.defaultFontPixelHeight / 2

            contentComponent: Component {
                ColumnLayout {
                    spacing:                _margins

                    SettingsGroupLayout {
                        heading:            qsTr("Network Status")

                        LabelledLabel {
                            label:  qsTr("Signal")
                            labelText:  transmitter.signalQuality + " %"
                        }
                        LabelledLabel {
                            label:  qsTr("RSSI")
                            labelText:  transmitter.rssi + " dBm"
                        }
                        LabelledLabel {
                            label:  qsTr("Inactive Time")
                            labelText:  transmitter.inactiveTime + " ms"
                        }
                        LabelledLabel {
                            label:  qsTr("Upstream")
                            labelText:  (transmitter.upStream / 1024).toFixed(1) + " KB/s"
                        }
                        LabelledLabel {
                            label:  qsTr("Downstream")
                            labelText:  (transmitter.downStream / 1024).toFixed(1) + " KB/s"
                        }
                        LabelledLabel {
                            label:  qsTr("TxBandwidth")
                            labelText:  (transmitter.txBanWidth / 1024).toFixed(1) + " Mb/s"
                        }
                        LabelledLabel {
                            label:  qsTr("RxBandwidth")
                            labelText:  (transmitter.rxBanWidth / 1024).toFixed(1) + " Mb/s"
                        }
                        LabelledLabel {
                            label:  qsTr("Frequency")
                            labelText:  transmitter.freq + " Mhz"
                        }
                        LabelledLabel {
                            label:  qsTr("Channel")
                            labelText:  transmitter.channel
                        }
                    }
                }
            }
        } //ToolIndicatorPage
    }
}
