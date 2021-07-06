import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4

import QGroundControl.FactControls 1.0
import QGroundControl.Palette 1.0


Button {
    id: control
    text: qsTr("Log In")
    //font.pointSize: 16

    property alias name: control.text
    property color baseColor
    property color borderColor

    Text {
    //contentItem: Text {
        text: control.text
        //font: control.font
        opacity: enabled ? 1.0 : 0.3
        color: control.down ? "#ffffff" : "#ffffff"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    Rectangle {
    //background: Rectangle {
        id: bgrect
        implicitWidth: 100
        implicitHeight: 50
        color: baseColor //"#6fda9c"
        opacity: control.down ? 0.7 : 1
        radius: height/2
        border.color: borderColor
    }
}
