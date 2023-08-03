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

    property SiYiTransmitter transmitter: SiYi.transmitter

    property bool showIndicator:    transmitter.isConnected //QGroundControl.settingsManager.appSettings.enableSiyiSDK.rawValue//QGroundControl.siyiSDKManager.isConnected
    property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle

    Component {
        id: siyiStatusInfo

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
                    text:           qsTr("Network Status")
                    font.family:    ScreenTools.demiboldFontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                GridLayout {
                    id:                 telemGrid
                    anchors.margins:    ScreenTools.defaultFontPixelHeight
                    columnSpacing:      ScreenTools.defaultFontPixelWidth
                    columns:            2
                    anchors.horizontalCenter: parent.horizontalCenter

                    QGCLabel { text: qsTr("Signal:") }
                    QGCLabel { text: transmitter.signalQuality + " %"}
                    QGCLabel { text: qsTr("RSSI:") }
                    QGCLabel { text: transmitter.rssi + " dBm"}
                    QGCLabel { text: qsTr("Inactive Time:") }
                    QGCLabel { text: transmitter.inactiveTime + " ms"}
                    QGCLabel { text: qsTr("Upstream:") }
                    QGCLabel { text: (transmitter.upStream / 1024).toFixed(1) + " Kb/s" }
                    QGCLabel { text: qsTr("Downstream:") }
                    QGCLabel { text: (transmitter.downStream / 1024).toFixed(1) + " Kb/s" }
                    QGCLabel { text: qsTr("TxBandwidth:") }
                    QGCLabel { text: (transmitter.txBanWidth / 1024).toFixed(1) + " Mb/s" }
                    QGCLabel { text: qsTr("RxBandwidth:") }
                    QGCLabel { text: (transmitter.rxBanWidth / 1024).toFixed(1) + " Mb/s" }
                    QGCLabel { text: qsTr("Frequency:") }
                    QGCLabel { text: transmitter.freq + " Mhz"}
                    QGCLabel { text: qsTr("Channel:") }
                    QGCLabel { text: transmitter.channel }
                }
            }
        }
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
                text:               (transmitter.downStream / 1024).toFixed(0) + " Kb/s"
            }

            QGCLabel {
                anchors.right:      parent.right
                color:              qgcPal.text
                text:               transmitter.rssi +" dBm"
            }
        }

        Rectangle{
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            height:         parent.height
            width:          height
            color:          "transparent"

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
                //opacity:            QGroundControl.siyiSDKManager.signal !== 0 ? 1 : 0.5
                color:              transmitter.signalQuality > 30 ? qgcPal.buttonText : qgcPal.colorOrange
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            mainWindow.showIndicatorPopup(_root, siyiStatusInfo)
        }
    }
}
