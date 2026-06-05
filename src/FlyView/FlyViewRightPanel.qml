import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView
import QGroundControl.FlightMap
import QGroundControl.FactControls

// Shows a single payload/control panel on the right edge. Which panel is shown is
// driven entirely by the per-panel "show" Facts toggled from the toolbar widget
// control header (WidgetControlPanel). Only one panel may be active at a time:
// turning one Fact on automatically turns the others off (exclusive state).
Item {
    id: _root

    width:  contentLoader.item ? contentLoader.item.width : 0

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    property var _flyViewSettings: QGroundControl.settingsManager.flyViewSettings

    // Ordered list of selectable panels. Exactly one (or none) of the facts is on.
    property var _pages: [
        { fact: _flyViewSettings.showPhotoVideoControl,      comp: photoVideoControlComponent },
        { fact: _flyViewSettings.showSiyiCameraControl,      comp: siyiCameraControlComponent },
        { fact: _flyViewSettings.showVehicleStepMoveControl, comp: stepMoveControlComponent },
        { fact: _flyViewSettings.showGimbalControlPannel,    comp: gimbalControlComponent },
        { fact: _flyViewSettings.showWinchControl,           comp: winchControlComponent },
        { fact: _flyViewSettings.showWindvane,               comp: windvaneControlComponent }
    ]

    // Index of the single active page (first fact that is on), or -1 if none.
    property int _activeIndex: {
        for (var i = 0; i < _pages.length; i++) {
            if (_pages[i].fact && _pages[i].fact.rawValue) {
                return i
            }
        }
        return -1
    }

    // Exclusive state: when activeFact is turned on, turn every other page off.
    function _enforceExclusive(activeFact) {
        for (var i = 0; i < _pages.length; i++) {
            var f = _pages[i].fact
            if (f && f !== activeFact && f.rawValue) {
                f.rawValue = false
            }
        }
    }

    Component.onCompleted: {
        // Normalize any saved multi-on state down to a single active page.
        var seen = false
        for (var i = 0; i < _pages.length; i++) {
            var f = _pages[i].fact
            if (f && f.rawValue) {
                if (seen) {
                    f.rawValue = false
                } else {
                    seen = true
                }
            }
        }
    }

    // Drive exclusivity off each fact: whenever one turns on, clear the others.
    Connections {
        target: _flyViewSettings.showPhotoVideoControl
        function onRawValueChanged() { if (_flyViewSettings.showPhotoVideoControl.rawValue) _root._enforceExclusive(_flyViewSettings.showPhotoVideoControl) }
    }
    Connections {
        target: _flyViewSettings.showSiyiCameraControl
        function onRawValueChanged() { if (_flyViewSettings.showSiyiCameraControl.rawValue) _root._enforceExclusive(_flyViewSettings.showSiyiCameraControl) }
    }
    Connections {
        target: _flyViewSettings.showVehicleStepMoveControl
        function onRawValueChanged() { if (_flyViewSettings.showVehicleStepMoveControl.rawValue) _root._enforceExclusive(_flyViewSettings.showVehicleStepMoveControl) }
    }
    Connections {
        target: _flyViewSettings.showGimbalControlPannel
        function onRawValueChanged() { if (_flyViewSettings.showGimbalControlPannel.rawValue) _root._enforceExclusive(_flyViewSettings.showGimbalControlPannel) }
    }
    Connections {
        target: _flyViewSettings.showWinchControl
        function onRawValueChanged() { if (_flyViewSettings.showWinchControl.rawValue) _root._enforceExclusive(_flyViewSettings.showWinchControl) }
    }
    Connections {
        target: _flyViewSettings.showWindvane
        function onRawValueChanged() { if (_flyViewSettings.showWindvane.rawValue) _root._enforceExclusive(_flyViewSettings.showWindvane) }
    }

    Loader {
        id:                     contentLoader
        anchors.right:          parent.right
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent:        _activeIndex >= 0 ? _pages[_activeIndex].comp : null
    }

    Component {
        id: photoVideoControlComponent
        PhotoVideoControl { }
    }
    Component {
        id: siyiCameraControlComponent
        FlyViewSiYiCameraPanel { }
    }
    Component {
        id: stepMoveControlComponent
        VehicleStepMoveControl { }
    }
    Component {
        id: gimbalControlComponent
        GimbalControl { }
    }
    Component {
        id: winchControlComponent
        WinchControlPanel { }
    }
    Component {
        id: windvaneControlComponent
        FlyViewWindvane { }
    }
}
