/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


/**
 * @file
 *   @brief QGC Main Tool Signal Strength
 *   @author Gus Grubba <gus@auterion.com>
 */

import QtQuick

import QGroundControl
import QGroundControl.Controls

Item {
    id:     signalRoot
    width:  size
    height: size

    property real size:     50
    property real percent:  0

    QGCPalette { id: qgcPal }

    Row {
        width:  parent.width
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 2
        Rectangle {
            anchors.bottom: parent.bottom
            height: parent.height * 0.2
            width: signalRoot.width / 5 - parent.spacing
            color: percent > 10 ? qgcPal.text : qgcPal.colorRed
            radius: width / 3
        }
        Rectangle {
            anchors.bottom: parent.bottom
            height: parent.height * 0.4
            width: signalRoot.width / 5 - parent.spacing
            color: percent > 30 ? qgcPal.text : Qt.rgba(qgcPal.colorGrey.r, qgcPal.colorGrey.g, qgcPal.colorGrey.b, 0.6)
            radius: width / 3
        }
        Rectangle {
            anchors.bottom: parent.bottom
            height: parent.height * 0.6
            width: signalRoot.width / 5 - parent.spacing
            color: percent > 50 ? qgcPal.text : Qt.rgba(qgcPal.colorGrey.r, qgcPal.colorGrey.g, qgcPal.colorGrey.b, 0.6)
            radius: width / 3
        }
        Rectangle {
            anchors.bottom: parent.bottom
            height: parent.height * 0.8
            width: signalRoot.width / 5 - parent.spacing
            color: percent > 70 ? qgcPal.text : Qt.rgba(qgcPal.colorGrey.r, qgcPal.colorGrey.g, qgcPal.colorGrey.b, 0.6)
            radius: width / 3
        }
        Rectangle {
            anchors.bottom: parent.bottom
            height: parent.height
            width: signalRoot.width / 5 - parent.spacing
            color: percent > 90 ? qgcPal.text : Qt.rgba(qgcPal.colorGrey.r, qgcPal.colorGrey.g, qgcPal.colorGrey.b, 0.6)
            radius: width / 3
        }
    }

}
