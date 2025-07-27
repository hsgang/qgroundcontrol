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

import QGroundControl.ScreenTools


//-------------------------------------------------------------------------
//-- RC RSSI Indicator
Item {
    id:             control
    width:          rssiRow.width * 1.1
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator: _activeVehicle.supportsRadio && _rcRSSIAvailable

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false
    property bool   _rcRSSIAvailable:   _activeVehicle.rcRSSI > 0 && _activeVehicle.rcRSSI <= 100

    Component {
        id: rcRSSIInfoPage

        ToolIndicatorPage {
            showExpand: false

            contentComponent: SettingsGroupLayout {
                heading: qsTr("RC RSSI Status")

                LabelledLabel {
                    label:      qsTr("RSSI")
                    labelText:  _activeVehicle.rcRSSI + "%"
                }
            }
        }
    }

    Row {
        id:             rssiRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        spacing:        ScreenTools.defaultFontPixelWidth / 2

        Rectangle{
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            height:         parent.height
            width:          height
            color:          "transparent"

            SignalStrength {
                anchors.horizontalCenter:   parent.horizontalCenter
                anchors.verticalCenter:     parent.verticalCenter
                size:                       parent.height * 0.9// * 0.5
                percent:                    _rcRSSIAvailable ? _activeVehicle.rcRSSI : 0
            }

            QGCColoredImage {
                id:                 rssiValuesIcon
                width:              parent.width / 2
                height:             width
                anchors.top:        parent.top
                anchors.left:       parent.left
                sourceSize.height:  height
                source:             "/qmlimages/RC.svg"
                fillMode:           Image.PreserveAspectFit
                color:              qgcPal.text
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin:     ScreenTools.defaultFontPixelWidth / 2

            QGCLabel {
                anchors.left:   parent.left
                font.pointSize: ScreenTools.smallFontPointSize
                color:          qgcPal.text
                text:           _activeVehicle.rcRSSI + "%"
            }

            QGCLabel {
                anchors.left:   parent.left
                color:          qgcPal.text
                text:           "RC"
            }
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorDrawer(rcRSSIInfoPage, control)
    }
}
