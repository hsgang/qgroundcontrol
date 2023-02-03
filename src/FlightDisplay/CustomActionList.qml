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
        spacing:    ScreenTools.defaultFontPixelWidth * 0.5

        QGCLabel { text: qsTr("Custom Action:") }

        Repeater {
            model: [
                "Test 1",
                "Test 2",
                "Test 3",
                "Test 4",
            ]

            QGCButton {
                text:               modelData
                Layout.fillWidth:   true

                onClicked: {
                    console.log(modelData)
                }
            }
        } // Repeater
    } // ColumnLayout
}
