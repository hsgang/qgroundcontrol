import QtQuick          2.3
import QtQuick.Layouts  1.2

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0

GridLayout {
    property alias label:                   label.text
    property alias description:             _description.text
    property alias fact:                    factSlider.fact
    property alias from:                    factSlider.from
    property alias to:                      factSlider.to
    property alias stepSize:                factSlider.stepSize
    property real  sliderPreferredWidth:    -1
    property bool  isRow:                   false

    rowSpacing: ScreenTools.defaultFontPixelWidth
    columnSpacing: ScreenTools.defaultFontPixelWidth * 2

    flow:    isRow ? GridLayout.LeftToRight : GridLayout.TopToBottom

    ColumnLayout {
        spacing : ScreenTools.defaultFontPixelHeight * 0.2

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
    }

    FactSlider {
        id:                     factSlider
        Layout.preferredWidth:  sliderPreferredWidth
    }
}
