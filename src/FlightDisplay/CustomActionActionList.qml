/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQml.Models 2.12

import QGroundControl                   1.0
import QGroundControl.Controls          1.0
import QGroundControl.FlightDisplay     1.0

ToolStripAction {
    text:           qsTr("Custom")
    iconSource:     "/InstrumentValueIcons/navigation-more.svg"
    visible:        true
    enabled:        _activeVehicle

    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle

    onTriggered: { console.log("CUSTOM ACTION PARENT!") }

//    ToolStrip {
//        id:     _toolStrip
//        title:  qsTr("Custom S")

//        model: _toolStripActionList.model

//    }

//    ToolStripActionList {
//        id: _toolStripActionList

//        model: [
//            ToolStripAction {
//                text:           qsTr("Custom 1")
//                iconSource:     "/res/gear-white.svg"
//                onTriggered: { console.log("CUSTOM ACTION 1!") }
//            },
//            ToolStripAction {
//                text:           qsTr("Custom 2")
//                iconSource:     "/res/gear-white.svg"
//                onTriggered: { console.log("CUSTOM ACTION 2!") }
//            }
//        ]
//    }
}
