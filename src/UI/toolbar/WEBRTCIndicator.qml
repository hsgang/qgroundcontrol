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
import QGroundControl.Controllers
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.FactSystem
import QGroundControl.FactControls

//-------------------------------------------------------------------------
Item {
    id:             control
    width:          vehicleRow.width
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator:        QGroundControl.linkManager.webRtcRtt > 0
    property real _margins:             ScreenTools.defaultFontPixelHeight / 2
    property real _rtt:                 QGroundControl.linkManager.webRtcRtt
    property real _videoRate:           QGroundControl.linkManager.rtcVideoRate

    Row {
        id: vehicleRow
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: ScreenTools.defaultFontPixelHeight / 5

        QGCColoredImage {
            id:                 roiIcon
            width:              height
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            source:             "/InstrumentValueIcons/network-transmit-receive.svg"
            color:              qgcPal.text
            fillMode:           Image.PreserveAspectFit
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            QGCLabel {
                anchors.left:   parent.left
                color:          qgcPal.buttonText
                font.pointSize: ScreenTools.smallFontPointSize
                text: qsTr("%1 ms").arg(_rtt)
            }

            QGCLabel {
                anchors.left:   parent.left
                color:          qgcPal.buttonText
                font.pointSize: ScreenTools.defaultFontPointSize
                text: qsTr("RTC")
            }
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorDrawer(webrtcIndicatorPage, control)
    }

    Component {
        id: webrtcIndicatorPage

        ToolIndicatorPage {
            showExpand: false

            contentComponent: SettingsGroupLayout {
                heading: qsTr("WEBRTC Status")

                LabelledLabel {
                    label:      qsTr("RTT")
                    labelText:  qsTr("%1 ms").arg(_rtt)
                }
                LabelledLabel {
                    label:      qsTr("Rate")
                    labelText:  qsTr("%1 KB/s").arg(_videoRate)
                }
            }
        }
    }
}
