/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.12 //2.3
import QtQuick.Controls         2.12 //1.2
import QtQuick.Controls.Styles  1.4

import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0

Switch {
    id: control
    text: ""

    QGCPalette { id:qgcPal; colorGroupEnabled: true }

    indicator: Rectangle{
        height: ScreenTools.defaultFontPixelHeight * 0.9
        width:  height * 2
        x:  control.leftPadding
        y:  parent.height / 2 - height / 2
        color:          (control.checked && control.enabled) ? qgcPal.brandingBlue : qgcPal.windowShadeLight
        radius:         height / 2

        Rectangle {
            x: control.checked ? parent.width - width - 4 : 4
            height:  parent.height - 8
            width: height
            anchors.verticalCenter: parent.verticalCenter
            color:          qgcPal.colorWhite//control.enabled ? qgcPal.colorWhite : qgcPal.colorGrey
            radius:         height / 2
        }
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
