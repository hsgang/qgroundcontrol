import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

RowLayout {
    property alias label:                   _label.text
    property alias description:             _description.text
    property alias buttonText:              _button.text
    property real  buttonPreferredWidth:    -1

    signal clicked

    id:         _root
    spacing:    ScreenTools.defaultFontPixelWidth * 2

    ColumnLayout {
        spacing : ScreenTools.defaultFontPixelHeight * 0.2

        QGCLabel {
            id:                 _label
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

    QGCButton {
        id:                     _button
        Layout.preferredWidth:  buttonPreferredWidth
        onClicked:              _root.clicked()
    }
}
