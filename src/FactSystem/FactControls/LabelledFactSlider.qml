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
import QGroundControl.FactControls

ColumnLayout {
    property alias label:                   label.text
    property alias description:             _description.text
    property alias fact:                    factSlider.fact
    property alias from:                    factSlider.from
    property alias to:                      factSlider.to
    property alias stepSize:                factSlider.stepSize
    property real  sliderPreferredWidth:    -1
    
    enabled:       fact

    QGCLabel {
        id:                 label
        Layout.fillWidth:   true
    }

    QGCLabel {
        id:                 _description
        visible:            description !== ""
        Layout.fillWidth:   true
        font.pointSize:     ScreenTools.smallFontPointSize
        color:              Qt.darker(QGroundControl.globalPalette.text, 1.5)
    }

    FactSlider {
        id:                     factSlider
        Layout.preferredWidth:  sliderPreferredWidth
    }
}
