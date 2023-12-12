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
    width:          siyirssiRow.width //(siyiStatusIcon.width + siyiStatusValuesColumn.width) * 1.1
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property SiYiTransmitter transmitter:   SiYi.transmitter

    property bool showIndicator:            transmitter.isConnected //QGroundControl.settingsManager.appSettings.enableSiyiSDK.rawValue//QGroundControl.siyiSDKManager.isConnected
    property var  _activeVehicle:           QGroundControl.multiVehicleManager.activeVehicle

    Component {
        id: siyiStatusInfo

        ToolIndicatorPage{
            showExpand: false

            property real _margins: ScreenTools.defaultFontPixelHeight

            contentItem: ColumnLayout {
                Layout.preferredWidth:  parent.width
                spacing:                ScreenTools.defaultFontPixelHeight

                QGCLabel {
                    id:                 telemLabel
                    text:               qsTr("Network Status")
                    font.family:        ScreenTools.demiboldFontFamily
                    Layout.alignment:   Qt.AlignHCenter
                }

                Rectangle {
                    Layout.preferredHeight: siyiColumnLayout.height + _margins //ScreenTools.defaultFontPixelHeight / 2
                    Layout.preferredWidth:  siyiColumnLayout.width + _margins //ScreenTools.defaultFontPixelHeight
                    color:                  qgcPal.windowShade
                    radius:                 _margins / 2
                    Layout.fillWidth:       true

                    ColumnLayout {
                        id:                 siyiColumnLayout
                        anchors.margins:    _margins / 2
                        anchors.top:        parent.top
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                        spacing:            _margins / 2

                    // ColumnLayout {
                    //     id:                 telemGrid
                    //     spacing:            ScreenTools.defaultFontPixelHeight * 0.5
                    //     Layout.fillWidth:   true

                        ComponentLabelValueRow {
                            labelText:  qsTr("Signal")
                            valueText:  transmitter.signalQuality + " %"
                        }
                        ComponentLabelValueRow {
                            labelText:  qsTr("RSSI")
                            valueText:  transmitter.rssi + " dBm"
                        }
                        ComponentLabelValueRow {
                            labelText:  qsTr("Inactive Time")
                            valueText:  transmitter.inactiveTime + " ms"
                        }
                        ComponentLabelValueRow {
                            labelText:  qsTr("Upstream")
                            valueText:  (transmitter.upStream / 1024).toFixed(1) + " KB/s"
                        }
                        ComponentLabelValueRow {
                            labelText:  qsTr("Downstream")
                            valueText:  (transmitter.downStream / 1024).toFixed(1) + " KB/s"
                        }
                        ComponentLabelValueRow {
                            labelText:  qsTr("TxBandwidth")
                            valueText:  (transmitter.txBanWidth / 1024).toFixed(1) + " Mb/s"
                        }
                        ComponentLabelValueRow {
                            labelText:  qsTr("RxBandwidth")
                            valueText:  (transmitter.rxBanWidth / 1024).toFixed(1) + " Mb/s"
                        }
                        ComponentLabelValueRow {
                            labelText:  qsTr("Frequency")
                            valueText:  transmitter.freq + " Mhz"
                        }
                        ComponentLabelValueRow {
                            labelText:  qsTr("Channel")
                            valueText:  transmitter.channel
                        }

                    // QGCLabel { text: qsTr("Signal:") }
                    // QGCLabel { text: transmitter.signalQuality + " %";                      horizontalAlignment: Text.AlignRight;}
                    // QGCLabel { text: qsTr("RSSI:") }
                    // QGCLabel { text: transmitter.rssi + " dBm";                             horizontalAlignment: Text.AlignRight;}
                    // QGCLabel { text: qsTr("Inactive Time:") }
                    // QGCLabel { text: transmitter.inactiveTime + " ms";                      horizontalAlignment: Text.AlignRight;}
                    // QGCLabel { text: qsTr("Upstream:") }
                    // QGCLabel { text: (transmitter.upStream / 1024).toFixed(1) + " KB/s";    horizontalAlignment: Text.AlignRight;}
                    // QGCLabel { text: qsTr("Downstream:") }
                    // QGCLabel { text: (transmitter.downStream / 1024).toFixed(1) + " KB/s";  horizontalAlignment: Text.AlignRight;}
                    // QGCLabel { text: qsTr("TxBandwidth:") }
                    // QGCLabel { text: (transmitter.txBanWidth / 1024).toFixed(1) + " MB/s";  horizontalAlignment: Text.AlignRight;}
                    // QGCLabel { text: qsTr("RxBandwidth:") }
                    // QGCLabel { text: (transmitter.rxBanWidth / 1024).toFixed(1) + " MB/s";  horizontalAlignment: Text.AlignRight;}
                    // QGCLabel { text: qsTr("Frequency:") }
                    // QGCLabel { text: transmitter.freq + " Mhz";                             horizontalAlignment: Text.AlignRight;}
                    // QGCLabel { text: qsTr("Channel:") }
                    // QGCLabel { text: transmitter.channel;                                   horizontalAlignment: Text.AlignRight;}
                    }
                }
            }
//        }
        } //ToolIndicatorPage
    }

    Row{
        id:             siyirssiRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        spacing:        ScreenTools.defaultFontPixelWidth/2

        Column {
            id:                     batteryValuesColumn
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin:     ScreenTools.defaultFontPixelWidth / 2
            //anchors.left:           batteryIcon.right

            QGCLabel {
                id:                 batteryVoltageValue
                anchors.right:      parent.right
                font.pointSize:     ScreenTools.smallFontPointSize
                color:              qgcPal.text
                text:               (transmitter.downStream / 1024).toFixed(0) + " KB/s"
            }

            QGCLabel {
                anchors.right:      parent.right
                color:              qgcPal.text
                text:               transmitter.rssi +" dBm"
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
        anchors.fill: parent
        onClicked: {
            //mainWindow.showIndicatorPopup(_root, siyiStatusInfo)
            mainWindow.showIndicatorDrawer(siyiStatusInfo)
        }
    }
}
