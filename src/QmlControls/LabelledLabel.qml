import QtQuick          2.3
import QtQuick.Layouts  1.2

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0

RowLayout {
    property alias label:                  _labelLabel.text
    property alias description:            _description.text
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
            color:              Qt.darker(QGroundControl.globalPalette.text, 1.5)
        }
    }

    QGCLabel {
        id:                     _label
        Layout.preferredWidth:  labelPreferredWidth
    }
}
