/****************************************************************************
 *
 * (c) 2009-2022 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts  1.11

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.FactControls          1.0

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
