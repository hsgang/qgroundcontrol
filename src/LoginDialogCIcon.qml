import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4

import QGroundControl.FactControls 1.0
import QGroundControl.Palette 1.0


Item {
    id: unicodeIcon

    property alias unicodeText: unicodeTxt.text
    property alias fontSize: unicodeTxt.font.pointSize

    Text {
        id: unicodeTxt
        //    text: "\uf023"
        font.pointSize: 14
        font.family: "fontawesome"
        color: mainAppColor
        anchors.centerIn: parent
        //anchors.left: parent.left
        //anchors.verticalCenter: parent.verticalCenter
        //leftPadding: 10
    }
}
