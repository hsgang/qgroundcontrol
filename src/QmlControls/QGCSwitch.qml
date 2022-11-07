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
        implicitWidth:  ScreenTools.defaultFontPixelWidth * 4
        implicitHeight: ScreenTools.defaultFontPixelHeight * 0.8
        x:  control.leftPadding
        y:  parent.height / 2 - height / 2
        color:          (control.checked && control.enabled) ? qgcPal.buttonHighlight : qgcPal.colorGrey
        radius:         implicitHeight * 0.5
        border.color:   qgcPal.button
        border.width:   1

        Rectangle {
            x: control.checked ? parent.width - width : 0
            implicitWidth:  ScreenTools.defaultFontPixelHeight
            implicitHeight: implicitWidth
            anchors.verticalCenter: parent.verticalCenter
            color:          control.enabled ? qgcPal.text : qgcPal.colorGrey
            radius:         implicitHeight * 0.5
            border.color:   qgcPal.button
            border.width:   1
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

//    style: SwitchStyle {
//        groove:     Rectangle {
//            implicitWidth:  ScreenTools.defaultFontPixelWidth * 4
//            implicitHeight: ScreenTools.defaultFontPixelHeight
//            color:          (control.checked && control.enabled) ? qgcPal.buttonHighlight : qgcPal.colorGrey
//            radius:         implicitHeight * 0.5
//            border.color:   qgcPal.button
//            border.width:   1
//        }
//        handle:     Rectangle {
//            implicitWidth:  ScreenTools.defaultFontPixelHeight
//            implicitHeight: implicitWidth
//            color:          (control.checked && control.enabled) ? qgcPal.text : qgcPal.colorGrey
//            radius:         implicitHeight * 0.5
//            border.color:   qgcPal.button
//            border.width:   1
//        }
//    }
}
