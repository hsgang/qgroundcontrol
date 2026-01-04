import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

RowLayout {
    property alias label:                   label.text
    property alias from:                    slider.from
    property alias to:                      slider.to
    property real  sliderPreferredWidth:    -1

    spacing: ScreenTools.defaultFontPixelWidth * 2

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

    QGCSlider {
        id:                     slider
        Layout.preferredWidth:  sliderPreferredWidth
    }
}
