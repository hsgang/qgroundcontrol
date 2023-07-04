import QtQuick          2.11
import QtQuick.Layouts  1.11

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0

Item {
    id:             _root
    width:          siyirssiRow.width //(siyiStatusIcon.width + siyiStatusValuesColumn.width) * 1.1
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator:    QGroundControl.settingsManager.appSettings.enableSiyiSDK.rawValue//QGroundControl.siyiSDKManager.isConnected
    property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    property bool _hasTelemetry:    _activeVehicle ? _activeVehicle.telemetryLRSSI !== 0 : false

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
                    text:           qsTr("Link Status")
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
                    QGCLabel { text: QGroundControl.siyiSDKManager.signal + " %"}
                    QGCLabel { text: qsTr("RSSI:") }
                    QGCLabel { text: QGroundControl.siyiSDKManager.rssi + " dBm"}
                    QGCLabel { text: qsTr("Inactive Time:") }
                    QGCLabel { text: QGroundControl.siyiSDKManager.inactiveTime + " ms"}
                    QGCLabel { text: qsTr("Upstream:") }
                    QGCLabel { text: (QGroundControl.siyiSDKManager.upstream / 1000).toFixed(1) + " kbps" }
                    QGCLabel { text: qsTr("Downstream:") }
                    QGCLabel { text: (QGroundControl.siyiSDKManager.downstream / 1000).toFixed(1) + " kbps" }
                    QGCLabel { text: qsTr("TxBandwidth:") }
                    QGCLabel { text: (QGroundControl.siyiSDKManager.txbandwidth / 1000).toFixed(1) + " Mbps" }
                    QGCLabel { text: qsTr("RxBandwidth:") }
                    QGCLabel { text: (QGroundControl.siyiSDKManager.rxbandwidth / 1000).toFixed(1) + " Mbps" }
                    QGCLabel { text: qsTr("Frequency:") }
                    QGCLabel { text: QGroundControl.siyiSDKManager.freq + " Mhz"}
                    QGCLabel { text: qsTr("Channel:") }
                    QGCLabel { text: QGroundControl.siyiSDKManager.channel }
                }
            }
        }
    }

    Row{
        id:             siyirssiRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        spacing:        ScreenTools.defaultFontPixelWidth/2

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
                percent:                    QGroundControl.siyiSDKManager.signal
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
                color:              QGroundControl.siyiSDKManager.signal > 30 ? qgcPal.buttonText : qgcPal.colorOrange
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
