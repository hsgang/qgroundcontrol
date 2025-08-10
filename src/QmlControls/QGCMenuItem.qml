import QtQuick
import QtQuick.Controls

import QGroundControl

MenuItem {
    id: control
    // MenuItem doesn't support !visible so we have to hack it in
    height: visible ? implicitHeight : 0

    background: Rectangle {
        color:          control.hovered ? qgcPal.buttonHighlight : qgcPal.window
    }

    indicator: Item {
        x: control.width - width - (ScreenTools.defaultFontPixelWidth / 4)
        visible:            control.checkable
        implicitWidth:  ScreenTools.defaultFontPixelHeight
        implicitHeight: ScreenTools.defaultFontPixelHeight
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            width:              ScreenTools.defaultFontPixelHeight * 0.8
            height:             ScreenTools.defaultFontPixelHeight * 0.8
            anchors.centerIn:   parent
            border.color:       qgcPal.text
            radius: 3

            QGCColoredImage {
                height:         parent.height * 0.7
                width:          height
                anchors.fill:   parent
                source:         "/InstrumentValueIcons/checkmark.svg"
                sourceSize.height: height
                fillMode:       Image.PreserveAspectFit
                color:          qgcPal.window
                visible:            control.checked
            }
        }
    }

    contentItem: Text{
        //leftPadding:            control.checkable ? control.indicator.width : ScreenTools.defaultFontPixelWidth / 2
        text:                   control.text;
        font.pointSize:         ScreenTools.defaultFontPointSize
        color:                  qgcPal.text
        horizontalAlignment:    Text.AlignLeft
        verticalAlignment:      Text.AlignVCenter
        elide:                  Text.ElideRight
    }
}
