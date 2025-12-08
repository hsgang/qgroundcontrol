/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QGroundControl.FlyView

GuidedToolStripAction {
    text:       _guidedController.changeAltTitle
    iconSource: "/InstrumentValueIcons/move-vertical.svg"
    visible:    _guidedController.showChangeAlt
    enabled:    _guidedController.showChangeAlt
    actionID:   _guidedController.actionChangeAlt
}
