import QGroundControl
import QGroundControl.FlyView

GuidedToolStripAction {
    text:       _guidedController.takeoffTitle
    iconSource: "/res/takeoff.svg"
    visible:    _guidedController.showTakeoff || !_guidedController.showLand
    enabled:    _guidedController.showTakeoff && _guidedController._vehicleArmed
    actionID:   _guidedController.actionTakeoff
}
