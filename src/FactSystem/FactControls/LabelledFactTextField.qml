import QtQuick          2.3
import QtQuick.Layouts  1.2

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0

RowLayout {
    property string label:                   fact.shortDescription
    property alias  description:             _description.text
    property alias  fact:                    _factTextField.fact
    property real   textFieldPreferredWidth: -1
    property alias  textFieldUnitsLabel:     _factTextField.unitsLabel
    property alias  textFieldShowUnits:      _factTextField.showUnits
    property alias  textFieldShowHelp:       _factTextField.showHelp

    spacing: ScreenTools.defaultFontPixelWidth * 2

    ColumnLayout {
        spacing : ScreenTools.defaultFontPixelHeight * 0.2

        QGCLabel {
            Layout.fillWidth:   true
            text:               label
        }
        QGCLabel {
            id:                 _description
            visible:            description !== ""
            Layout.fillWidth:   true
            font.pointSize:     ScreenTools.smallFontPointSize
            color:              Qt.darker(QGroundControl.globalPalette.text, 1.5)
            wrapMode:           Text.WordWrap
            width:              parent.width
        }
    }

    FactTextField {
        id:                     _factTextField
        Layout.preferredWidth:  textFieldPreferredWidth
    }
}
