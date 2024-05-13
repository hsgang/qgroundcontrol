/****************************************************************************
 *
 * (c) 2009-2022 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

RowLayout {
    property alias label:                   _labelLabel.text
    property alias description:             _description.text
    property alias labelText:              _label.text
    property real  labelPreferredWidth:    -1

    spacing: ScreenTools.defaultFontPixelWidth * 2

    ColumnLayout {
        spacing : ScreenTools.defaultFontPixelHeight * 0.2

        QGCLabel {
            id:                 _labelLabel
            Layout.fillWidth:   true
        }
        QGCLabel {
            id:                 _description
            visible:            description !== ""
            Layout.fillWidth:   true
            font.pointSize:     ScreenTools.smallFontPointSize
            elide:              Text.ElideMiddle
            color:              Qt.darker(QGroundControl.globalPalette.text, 1.5)
        }
    }

    QGCLabel {
        id:                     _label
        Layout.preferredWidth:  labelPreferredWidth
    }
}
