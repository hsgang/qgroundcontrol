import QtQuick

import QGroundControl
import QGroundControl.Controls

Canvas {
    id:                 control
    anchors.centerIn:   parent
    width:              compassSize * 1/4
    height:             width

    property real compassSize
    property real heading
    property bool simplified:    false

    property var _qgcPal: QGroundControl.globalPalette

    Connections {
        target:                 _qgcPal
        function onGlobalThemeChanged() { control.requestPaint() }
    }

    onPaint: {
        var ctx = getContext("2d")
        ctx.strokeStyle = simplified ? "#0088e4" : _qgcPal.text
        ctx.fillStyle = "#0088e4"
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.moveTo(width / 2, 0)
        ctx.lineTo(width, height)
        ctx.lineTo(width / 2, height * 0.75)
        ctx.lineTo(width / 2, 0)
        ctx.fill()
        ctx.stroke()
        ctx.fillStyle = "#0f3e61" //"#C72B27"
        ctx.beginPath()
        ctx.moveTo(width / 2, 0)
        ctx.lineTo(0, height)
        ctx.lineTo(width / 2, height * 0.75)
        ctx.lineTo(width / 2, 0)
        ctx.fill()
        ctx.stroke()
    }

    transform: Rotation {
        origin.x:   control.width / 2
        origin.y:   control.height / 2
        angle:      heading
    }
}
