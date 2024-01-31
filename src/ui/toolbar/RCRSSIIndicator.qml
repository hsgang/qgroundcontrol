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
//-- RC RSSI Indicator
Item {
    id:             _root
    width:          rssiRow.width
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator: _activeVehicle.supportsRadio && _rcRSSIAvailable

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _rcRSSIAvailable:   _activeVehicle ? _activeVehicle.rcRSSI > 0 && _activeVehicle.rcRSSI <= 100 : false

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
                //opacity:            _rcRSSIAvailable ? 1 : 0.5
                color:              (_activeVehicle && _rcRSSIAvailable && _activeVehicle.rcRSSI >= 30) ? qgcPal.buttonText : qgcPal.colorOrange
            }
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorDrawer(rcRSSIInfo)
    }

    Component {
        id: rcRSSIInfo

        ToolIndicatorPage{
            showExpand: false

            property real _margins: ScreenTools.defaultFontPixelHeight

            contentComponent: Component {
                ColumnLayout {
                    spacing:                ScreenTools.defaultFontPixelHeight

                    SettingsGroupLayout {
                        heading: _activeVehicle ? (_activeVehicle.rcRSSI !== 255 ? qsTr("RC RSSI Status") : qsTr("RC RSSI Data Unavailable")) : qsTr("N/A", "No data available")

                        LabelledLabel {
                            label:      qsTr("RC RSSI")
                            labelText:  _activeVehicle ? (_activeVehicle.rcRSSI + "%") : 0
                        }
                    }
                }
            }
        }
    }
}
