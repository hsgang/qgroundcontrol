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

RowLayout {
    property alias label:                   label.text
    property alias description:             _description.text
    property alias model:                   _comboBox.model
    property alias currentIndex:            _comboBox.currentIndex
    property alias currentText:             _comboBox.currentText
    property alias alternateText:           _comboBox.alternateText
    property var   comboBox:                _comboBox
    property real  comboBoxPreferredWidth:  -1

    spacing: ScreenTools.defaultFontPixelWidth

    signal activated(int index)

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

    QGCComboBox {
        id:                     _comboBox
        Layout.preferredWidth:  comboBoxPreferredWidth
        sizeToContents:         true
        onActivated: (index) => { parent.activated(index) }
    }
}
