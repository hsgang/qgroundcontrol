import QtQuick          2.3
import QtQuick.Layouts  1.2

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0

RowLayout {
    property alias label:                   label.text
    property alias description:             _description.text
    property alias fact:                    _comboBox.fact
    property alias indexModel:              _comboBox.indexModel
    property var   comboBox:                _comboBox
    property real  comboBoxPreferredWidth:  -1

    spacing: ScreenTools.defaultFontPixelWidth * 2

    signal activated(int index)

    ColumnLayout {
        spacing : ScreenTools.defaultFontPixelHeight * 0.2
        visible:    label !== ""

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
            lineHeight:         0.5
            //wrapMode:           Text.WordWrap
        }
    }

    FactComboBox {
        id:                     _comboBox
        Layout.preferredWidth:  comboBoxPreferredWidth
        sizeToContents: true
        onActivated: (index) => { parent.activated(index) }
    }
}
