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
import QGroundControl.ScreenTools   1.0

Component {

    ColumnLayout {
        id: _root
        spacing:    ScreenTools.defaultFontPixelWidth * 0.5

        property var activeVehicle:  QGroundControl.multiVehicleManager.activeVehicle

        property var json_string: '
        {
            "version":  1,
            "fileType": "CustomActions",
            "CustomActions": [
                {
                    "label":  "Image Start Capture",
                    "mavCmd": 2000,
                    "param1": 0,
                    "param2": 0,
                    "param3": 0,
                    "param4": 0,
                    "param5": 0,
                    "param6": 0,
                    "param7": 0
                },
                {
                    "label":  "Image Stop Capture",
                    "mavCmd": 2001,
                    "param1": 0,
                    "param2": 0,
                    "param3": 0,
                    "param4": 0,
                    "param5": 0,
                    "param6": 0,
                    "param7": 0
                }
            ]
        }'
        property var json: JSON.parse(json_string)

        QGCLabel { text: qsTr("Custom Action:") }

        Repeater {
            model: _root.json.CustomActions

            QGCButton {
                text:               modelData.label
                Layout.fillWidth:   true

                onClicked: {
                    var vehicle = _root.activeVehicle
                    if (vehicle) {
                        const show_error = true
                        var comp_id = vehicle.defaultComponentId
                        vehicle.sendCommand(
                                    comp_id,
                                    modelData.mavCmd,
                                    show_error,
                                    modelData.param1,
                                    modelData.param2,
                                    modelData.param3,
                                    modelData.param4,
                                    modelData.param5,
                                    modelData.param6,
                                    modelData.param7
                        )
                    }
                }
            }
        } // Repeater
    } // ColumnLayout
}
