/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.12
import QtQuick.Layouts          1.12

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.Controllers   1.0
import QGroundControl.ScreenTools   1.0

Component {

    ColumnLayout {
        id: _root
        spacing:    ScreenTools.defaultFontPixelWidth * 0.5

        CustomActionManager {
            id: manager
        }

        QGCLabel { text: qsTr("Custom Action:") }

        Repeater {
            model: manager.actions

            QGCButton {
                text:              object.label
                Layout.fillWidth:  true

                onClicked: {
                    var vehicle = QGroundControl.multiVehicleManager.activeVehicle
                    object.sendTo(vehicle)
                }
            }
        } // Repeater
    } // ColumnLayout
}
