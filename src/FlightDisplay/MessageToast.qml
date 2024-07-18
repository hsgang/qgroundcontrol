import QtQuick

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Palette

Rectangle {

    function show(text, duration) {
        message.text = text;
        if (typeof duration !== "undefined") {
            time = Math.max(duration, 2 * fadeTime);
        }
        else {
            time = defaultTime;
        }
        animation.start();
    }

    id: root

    readonly property real  defaultTime:    3000
    property real           time:           defaultTime
    readonly property real  fadeTime:       300
    property real           margin:         ScreenTools.defaultFontPixelWidth

    anchors.left:   (parent != null) ? parent.left : undefined
    width:          message.implicitWidth + (margin * 2)
    height:         message.height + margin
    radius:         margin
    color:          qgcPal.window

    Text {
        id:                 message
        color:              qgcPal.text
        wrapMode:           Text.Wrap
        horizontalAlignment:Text.AlignLeft
        anchors {
            top:    parent.top
            left:   parent.left
            right:  parent.right
            margins:margin / 2
        }
    }

    SequentialAnimation on opacity {
        id: animation
        running: false


        NumberAnimation {
            to: 1
            duration: fadeTime
        }

        PauseAnimation {
            duration: time - 2 * fadeTime
        }

        NumberAnimation {
            to: 0
            duration: fadeTime
        }

        onRunningChanged: {
            if (!running) {
                messageToastManager.model.remove(index);//root.destroy();
            }
        }
    }
}

