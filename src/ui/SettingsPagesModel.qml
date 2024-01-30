/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQml.Models

import QGroundControl
import QGroundControl.ScreenTools

ListModel {
    ListElement {
        name: qsTr("General")
        url: "/qml/GeneralSettings.qml"
        menuIcon: "/InstrumentValueIcons/view-tile.svg"
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("Fly View")
        url: "/qml/FlyViewSettings.qml"
        menuIcon: "/InstrumentValueIcons/send.svg"
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("Plan View")
        url: "/qml/PlanViewSettings.qml"
        menuIcon: "/InstrumentValueIcons/path.svg"
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("Video")
        url: "/qml/VideoSettings.qml"
        menuIcon: "/InstrumentValueIcons/view-carousel.svg"
        pageVisible: function() { return QGroundControl.settingsManager.videoSettings.visible }
    }

    ListElement {
        name: qsTr("Telemetry")
        url: "/qml/TelemetrySettings.qml"
        menuIcon: "/InstrumentValueIcons/station.svg"
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("ADSB Server")
        url: "/qml/ADSBServerSettings.qml"
        menuIcon: "/InstrumentValueIcons/radar.svg"
        pageVisible: function() { return true }
    }

    //ListElement {
    //    name: qsTr("General Old")
    //    url: "/qml/GeneralSettings2.qml"
    //    pageVisible: function() { return true }
    //}

    ListElement {
        name: qsTr("Comm Links")
        url: "/qml/LinkSettings.qml"
        menuIcon: "/InstrumentValueIcons/station.svg"
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("Offline Maps")
        url: "/qml/OfflineMap.qml"
        menuIcon: "/InstrumentValueIcons/map.svg"
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("MAVLink")
        url: "/qml/MavlinkSettings.qml"
        menuIcon: "/InstrumentValueIcons/conversation.svg"
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("Remote ID")
        url: "/qml/RemoteIDSettings.qml"
        menuIcon: "/InstrumentValueIcons/inbox-full.svg"
        pageVisible: function() { return QGroundControl.settingsManager.remoteIDSettings.enable.rawValue }
    }

    ListElement {
        name: qsTr("Console")
        url: "/qml/QGroundControl/Controls/AppMessages.qml"
        menuIcon: "/InstrumentValueIcons/window-open.svg"
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("Help")
        url: "/qml/HelpSettings.qml"
        menuIcon: "/InstrumentValueIcons/information-outline.svg"
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("Mock Link")
        url: "/qml/MockLink.qml"
        menuIcon: "/qmlimages/Gears.svg"
        pageVisible: function() { return ScreenTools.isDebug }
    }

    ListElement {
        name: qsTr("Debug")
        url: "/qml/DebugWindow.qml"
        menuIcon: "/qmlimages/Gears.svg"
        pageVisible: function() { return ScreenTools.isDebug }
    }

    ListElement {
        name: qsTr("Palette Test")
        url: "/qml/QmlTest.qml"
        menuIcon: "/qmlimages/Gears.svg"
        pageVisible: function() { return ScreenTools.isDebug }
    }
}

