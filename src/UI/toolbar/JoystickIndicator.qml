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

// Joystick Indicator
Item {
    id:             _root
    width:          joystickRow.width
    anchors.top:    parent.top
    anchors.bottom: parent.bottom
    visible:        globals.activeVehicle ? globals.activeVehicle.sub : false


    Component {
        id: joystickInfo

        Rectangle {
            width:  joystickCol.width   + ScreenTools.defaultFontPixelWidth  * 3
            height: joystickCol.height  + ScreenTools.defaultFontPixelHeight * 2
            radius: ScreenTools.defaultFontPixelHeight * 0.5
            color:  qgcPal.window
            border.color:   qgcPal.text

            Column {
                id:                 joystickCol
                spacing:            ScreenTools.defaultFontPixelHeight * 0.5
                width:              Math.max(joystickGrid.width, joystickLabel.width)
                anchors.margins:    ScreenTools.defaultFontPixelHeight
                anchors.centerIn:   parent

                QGCLabel {
                    id:             joystickLabel
                    text:           qsTr("Joystick Status")
                    font.bold:      true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                GridLayout {
                    id:                 joystickGrid
                    anchors.margins:    ScreenTools.defaultFontPixelHeight
                    columnSpacing:      ScreenTools.defaultFontPixelWidth
                    columns:            2
                    anchors.horizontalCenter: parent.horizontalCenter

                    QGCLabel { text: qsTr("Connected:") }
                    QGCLabel {
                        text:  joystickManager.activeJoystick ? qsTr("Yes") : qsTr("No")
                        color: joystickManager.activeJoystick ? qgcPal.buttonText : "red"
                    }
                    QGCLabel { text: qsTr("Enabled:") }
                    QGCLabel {
                        text:  globals.activeVehicle && globals.activeVehicle.joystickEnabled ? qsTr("Yes") : qsTr("No")
                        color: globals.activeVehicle && globals.activeVehicle.joystickEnabled ? qgcPal.buttonText : "red"
                    }
                }
            }
        }
    }

    Row {
        id:             joystickRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        spacing:        ScreenTools.defaultFontPixelWidth

        Rectangle{
            width:              1
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            color:              qgcPal.text
            opacity:            0.5
        }

        QGCColoredImage {
            width:              height
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            sourceSize.height:  height
            source:             "/qmlimages/Joystick.png"
            fillMode:           Image.PreserveAspectFit
            color: {
                if(globals.activeVehicle && joystickManager.activeJoystick) {
                    if(globals.activeVehicle.joystickEnabled) {
                        // Everything ready to use joystick
                        return qgcPal.buttonText
                    }
                    // Joystick is not enabled in the joystick configuration page
                    return "yellow"
                }
                // Joystick not available or there is no active vehicle
                return "red"
            }
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked: {
            mainWindow.showIndicatorPopup(_root, joystickInfo)
        }
    }
}
