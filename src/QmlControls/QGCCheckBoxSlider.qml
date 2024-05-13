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
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Palette
import QGroundControl.ScreenTools

AbstractButton   {
    id:             control
    checkable:      true
    padding:        0

    property bool   _showBorder: qgcPal.globalTheme === QGCPalette.Light
    property alias description:         _description.text

    QGCPalette { id: qgcPal; colorGroupEnabled: control.enabled }

    contentItem: Item {
        implicitWidth:  label.contentWidth + indicator.width + ScreenTools.defaultFontPixelWidth
        implicitHeight: label.contentHeight + (description.length > 0 ? _description.contentHeight : 0)

        ColumnLayout {
            id:                 labelLayout
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            spacing : ScreenTools.defaultFontPixelHeight * 0.2
            QGCLabel {
                id:             label
                //anchors.left:   parent.left
                text:           visible ? control.text : "X"
                visible:        control.text !== ""
            }
            QGCLabel {
                id:                 _description
                visible:            description.length > 0
                Layout.fillWidth:   true
                font.pointSize:     ScreenTools.smallFontPointSize
                color:              Qt.darker(QGroundControl.globalPalette.text, 1.5)
            }
        }
    
        Rectangle {
            id:                     indicator
            anchors.right:          parent.right
            anchors.verticalCenter: parent.verticalCenter
            height:                 ScreenTools.defaultFontPixelHeight
            width:                  height * 2
            radius:                 height / 2
            color:                  control.checked ? qgcPal.brandingBlue : qgcPal.windowShade
            border.width:           _showBorder ? 1 : 0
            border.color:           qgcPal.buttonBorder

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x:                      checked ? indicator.width - width - 1 : 1
                height:                 parent.height - 2
                width:                  height
                radius:                 height / 2
                color:                  qgcPal.buttonText
            }
        }
    }
}
