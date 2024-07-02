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
    text:       _guidedController.changeAltTitle
    iconSource: "/InstrumentValueIcons/cloud-upload.svg"
    visible:    _guidedController.showChangeAlt
    enabled:    _guidedController.showChangeAlt
    actionID:   _guidedController.actionChangeAlt
}
