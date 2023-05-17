/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQml.Models 2.12
import QtQuick                  2.12
import QtQuick.Layouts          1.12

import QGroundControl                   1.0
import QGroundControl.Controls          1.0
import QGroundControl.Controllers       1.0
import QGroundControl.FlightDisplay     1.0
import QGroundControl.ScreenTools       1.0

ToolStripAction {
    text:           qsTr("Custom")
    iconSource:     "/InstrumentValueIcons/navigation-more.svg"
    visible:        isEnabled
    enabled:        manager.hasActions && _activeVehicle

    property var _activeVehicle:  QGroundControl.multiVehicleManager.activeVehicle
    property bool isEnabled:      QGroundControl.settingsManager.flyViewSettings.enableCustomActions.rawValue

    property var _manager: CustomActionManager {
        id: manager
    }

    dropPanelComponent: Component {
        ColumnLayout {
            id: _root
            spacing:    ScreenTools.defaultFontPixelWidth * 0.5

            QGCLabel {
                text: qsTr("Custom Action")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            }

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

}
