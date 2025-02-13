/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QGroundControl.FlightDisplay

GuidedToolStripAction {
    text:       _guidedController.continueMissionTitle
    iconSource: "/qmlimages/Plan.svg" //"/InstrumentValueIcons/path.svg"
    visible:    _guidedController.showContinueMission
    enabled:    _guidedController.showContinueMission && !_guidedController._vehicleInMissionMode && _guidedController._vehicleArmed
    actionID:   _guidedController.actionContinueMission
}
