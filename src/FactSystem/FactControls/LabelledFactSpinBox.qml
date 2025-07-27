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
import QGroundControl.FactControls

RowLayout {
    property alias label:                   label.text
    property alias description:             _description.text
    property alias fact:                    factSpinbox.fact
    property alias fromValue:               factSpinbox.fromValue
    property alias toValue:                 factSpinbox.toValue
    property alias stepValue:               factSpinbox.stepValue
    property alias decimals:                factSpinbox.decimals
    property real  spinboxPreferredWidth:   -1
    
    enabled:       fact

    ColumnLayout {
        spacing:        ScreenTools.defaultFontPixelHeight * 0.2
        visible:        label !== ""

        QGCLabel {
            id:                     label
            Layout.fillWidth:       true
            Layout.minimumWidth:    spinboxPreferredWidth * 0.8
        }

        QGCLabel {
            id:                 _description
            visible:            description !== ""
            Layout.fillWidth:   true
            font.pointSize:     ScreenTools.smallFontPointSize
            color:              Qt.darker(QGroundControl.globalPalette.text, 1.5)
        }
    }

    FactSpinBox {
        id:                     factSpinbox
        Layout.preferredWidth:  spinboxPreferredWidth
    }
}
