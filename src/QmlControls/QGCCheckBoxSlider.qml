/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts  1.15

import QGroundControl               1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0

AbstractButton   {
    id:             control
    checkable:      true
    padding:        0

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
            height:                 ScreenTools.defaultFontPixelHeight * 0.9
            width:                  height * 2
            radius:                 height / 2
            color:                  control.checked ? qgcPal.brandingBlue : qgcPal.windowShade

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x:                      checked ? indicator.width - width - 4 : 4
                height:                 parent.height - 8
                width:                  height
                radius:                 height / 2
                color:                  qgcPal.colorWhite
            }
        }
    }
}
