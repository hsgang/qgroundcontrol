import QtQuick
import QtQuick.Controls

import QGroundControl

Canvas {
    id:     root

    width:  _width
    height: _height

    property real   _width:             ScreenTools.defaultFontPixelHeight * 2
    property real   _height:            ScreenTools.defaultFontPixelHeight * 2
    property real   anchorPointX:       _width / 2
    property real   anchorPointY:       _height / 2

    property real   _aimLineLength:     ScreenTools.defaultFontPixelWidth
    property var    _aimLineColor:      qgcPal.colorGreen

    transform: Rotation { origin.x: width/2; origin.y: height/2; angle: 45}

    Rectangle {
        id:                             indicator
        anchors.horizontalCenter:       parent.horizontalCenter
        anchors.verticalCenter:         parent.verticalCenter
        width:                          _width
        height:                         width
        color:                          "transparent"
        border.color:                   _aimLineColor
        border.width:                   1
        radius:                         _width / 2
    }

    Rectangle {
        anchors.verticalCenter:         indicator.verticalCenter
        anchors.right:                  indicator.left
        width:                          _aimLineLength
        height:                         1
        color:                          _aimLineColor
    }

    Rectangle {
        anchors.verticalCenter:         indicator.verticalCenter
        anchors.left:                   indicator.right
        width:                          _aimLineLength
        height:                         1
        color:                          _aimLineColor
    }

    Rectangle {
        anchors.horizontalCenter:       indicator.horizontalCenter
        anchors.bottom:                 indicator.top
        width:                          1
        height:                         _aimLineLength
        color:                          _aimLineColor
    }

    Rectangle {
        anchors.horizontalCenter:       indicator.horizontalCenter
        anchors.top:                    indicator.bottom
        width:                          1
        height:                         _aimLineLength
        color:                          _aimLineColor
    }
}
