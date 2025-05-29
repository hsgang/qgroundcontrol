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
        url: "qrc:/qml/QGroundControl/AppSettings/GeneralSettings.qml"
        menuIcon: "/InstrumentValueIcons/view-tile.svg"
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("Fly View")
        url: "qrc:/qml/QGroundControl/AppSettings/FlyViewSettings.qml"
        iconUrl: "qrc:/qmlimages/PaperPlane.svg"
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("Plan View")
        url: "qrc:/qml/QGroundControl/AppSettings/PlanViewSettings.qml"
        menuIcon: "/InstrumentValueIcons/path.svg"
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("Comm Links")
        url: "qrc:/qml/QGroundControl/AppSettings/LinkSettings.qml"
        menuIcon: "/InstrumentValueIcons/link.svg"
        _enabled: true
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("Video")
        url: "qrc:/qml/QGroundControl/AppSettings/VideoSettings.qml"
        iconUrl: "qrc:/InstrumentValueIcons/camera.svg"
        pageVisible: function() { return QGroundControl.settingsManager.videoSettings.visible }
    }

    ListElement {
        name: qsTr("Telemetry")
        url: "qrc:/qml/QGroundControl/AppSettings/TelemetrySettings.qml"
        menuIcon: "/InstrumentValueIcons/station.svg"
        _enabled: true
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("NTRIP")
        url: "/qml/NTRIPSettings.qml"
        menuIcon: "/InstrumentValueIcons/radar.svg"
        _enabled: true
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("Maps")
        url: "qrc:/qml/QGroundControl/AppSettings/MapSettings.qml"
        menuIcon: "/InstrumentValueIcons/globe.svg"
        _enabled: true
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("ADSB Server")
        url: "qrc:/qml/QGroundControl/AppSettings/ADSBServerSettings.qml"
        iconUrl: "qrc:/InstrumentValueIcons/airplane.svg"
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("MAVLink")
        url: "/qml/MavlinkSettings.qml"
        menuIcon: "/InstrumentValueIcons/conversation.svg"
        _enabled: false
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("Network RTK")
        url: "/qml/NTRIPSettings.qml"
        iconUrl: "/InstrumentValueIcons/radar.svg"
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("Cloud")
        url: "/qml/CloudSettings.qml"
        iconUrl: "/InstrumentValueIcons/cloud.svg"
        pageVisible: function() { return true }
    }


    ListElement {
        name: qsTr("PX4 Log Transfer")
        url: "qrc:/qml/QGroundControl/AppSettings/PX4LogTransferSettings.qml"
        iconUrl: "qrc:/InstrumentValueIcons/inbox-download.svg"
        pageVisible: function() { 
            var activeVehicle = QGroundControl.multiVehicleManager.activeVehicle
            return QGroundControl.corePlugin.options.showPX4LogTransferOptions && 
                        QGroundControl.px4ProFirmwareSupported && 
                        (activeVehicle ? activeVehicle.px4Firmware : true)
        }
    }

    ListElement {
        name: qsTr("Remote ID")
        url: "qrc:/qml/QGroundControl/AppSettings/RemoteIDSettings.qml"
        iconUrl: "qrc:/qmlimages/RidIconManNoID.svg"
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("Console")
        url: "/qml/QGroundControl/Controls/AppMessages.qml"
        menuIcon: "/InstrumentValueIcons/window-open.svg"
        _enabled: true
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("Help")
        url: "qrc:/qml/QGroundControl/AppSettings/HelpSettings.qml"
        iconUrl: "qrc:/InstrumentValueIcons/question.svg"
        pageVisible: function() { return true }
    }

//     ListElement {
//         name: qsTr("Mock Link")
//         url: "qrc:/qml/QGroundControl/AppSettings/MockLink.qml"
//         iconUrl: "qrc:/InstrumentValueIcons/drone.svg"
//         pageVisible: function() { return ScreenTools.isDebug }
//     }

//     ListElement {
//         name: qsTr("Debug")
//         url: "qrc:/qml/QGroundControl/AppSettings/DebugWindow.qml"
//         iconUrl: "qrc:/InstrumentValueIcons/bug.svg"
//         pageVisible: function() { return ScreenTools.isDebug }
//     }

//     ListElement {
//         name: qsTr("Palette Test")
//         url: "qrc:/qml/QGroundControl/AppSettings/QmlTest.qml"
//         iconUrl: "qrc:/InstrumentValueIcons/photo.svg"
//         pageVisible: function() { return ScreenTools.isDebug }
//     }
}

