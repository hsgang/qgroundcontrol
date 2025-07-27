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

import QGroundControl.ScreenTools


import QGroundControl.FactControls

Item {
    id: control

    property bool showIndicator: true

    property var  activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    width:                      ScreenTools.defaultFontPixelWidth * 20
    anchors.top:                parent.top
    anchors.bottom:             parent.bottom
    anchors.horizontalCenter:   parent.horizontalCenter

    Rectangle {
        width:  parent.width
        height: parent.height
        color: "transparent"
        // radius: ScreenTools.defaultFontPixelHeight / 4
        // border.width: 1
        // border.color: qgcPal.text

        RowLayout {
            anchors.horizontalCenter:   parent.horizontalCenter
            anchors.verticalCenter:     parent.verticalCenter

            Column {

                QGCLabel {
                    id:                 modeTranslatedLabel
                    text:               activeVehicle ? activeVehicle.flightMode : qsTr("비행모드")
                    font.pointSize:     ScreenTools.largeFontPointSize * 0.9
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            QGCColoredImage {
                height:             ScreenTools.defaultFontPixelHeight
                width:              height
                source:             "/InstrumentValueIcons/cheveron-down.svg"
                color:              qgcPal.buttonText
            }
        }

        MouseArea {
            anchors.fill:   parent
            onClicked:      mainWindow.showIndicatorDrawer(drawerComponent, control)
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
