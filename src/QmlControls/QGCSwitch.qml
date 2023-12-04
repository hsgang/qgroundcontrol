/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Styles

import QGroundControl.Palette
import QGroundControl.ScreenTools

Switch {
    id: control
    text: ""

    QGCPalette { id:qgcPal; colorGroupEnabled: true }
    indicator: Rectangle {
        implicitWidth:  ScreenTools.defaultFontPixelWidth * 6
        implicitHeight: ScreenTools.defaultFontPixelHeight
        color:          (control.checked && control.enabled) ? qgcPal.colorGreen : qgcPal.colorGrey
        radius:         3
        border.color:   qgcPal.button
        border.width:   1
    }

    contentItem: Text {
            text: control.text
            font: control.font
            opacity: enabled ? 1.0 : 0.3
            color: qgcPal.text
            verticalAlignment: Text.AlignVCenter
            leftPadding: control.indicator.width + control.spacing
    }
}
