/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QGroundControl.FlightDisplay 1.0

GuidedToolStripAction {
    text:       _guidedController.startMissionTitle
    iconSource: "/InstrumentValueIcons/path.svg"
    visible:    _guidedController.showStartMission
    enabled:    _guidedController.showStartMission && !_guidedController._vehicleInMissionMode && _guidedController._vehicleArmed
    actionID:   _guidedController.actionStartMission
}
