/****************************************************************************
 *
 * (c) 2009-2022 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.FactSystem
import QGroundControl.FactControls

Item {
    id: _root

    property bool showIndicator: true

    property var  activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    width:                      parent.width
    anchors.top:                parent.top
    anchors.bottom:             parent.bottom
    anchors.horizontalCenter:   parent.horizontalCenter

    Rectangle {
        width:  parent.width
        height: parent.height
        color: "transparent"

        QGCLabel {
            id:                 modeLabel
            text:                       activeVehicle ? activeVehicle.flightMode : qsTr("N/A", "No data to display")
            font.pointSize:             ScreenTools.largeFontPointSize * 0.9
            anchors.horizontalCenter:   parent.horizontalCenter
            anchors.verticalCenter:     parent.verticalCenter
        }

        MouseArea {
            anchors.fill:   parent
            onClicked:      mainWindow.showIndicatorDrawer(drawerComponent)
        }
    }

    Component {
        id:             drawerComponent

        ToolIndicatorPage {
            id:         mainLayout
            showExpand: true

            // Mode list
            contentComponent: FlightModeToolIndicatorContentItem { }

        }
    }
}
