import QtQuick

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

Rectangle{

    id: root

    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.5

    function show(text, duration){
        theText.text = text;
        if(typeof duration !== "undefined"){
            if(duration >= 2*fadeTime)
                time = duration;
            else
                time = 2*fadeTime;
            }
        else
            time = defaultTime;
        anim.start();
    }

    property bool selfDestroying: false ///< Whether this Toast will selfdestroy when it is finished

    property real time: defaultTime
    readonly property real defaultTime: 10000
    readonly property real fadeTime: 300

    width: theText.width + _toolsMargin * 3
    height: theText.height + _toolsMargin * 0.5 // _toolsMargin
    radius: _toolsMargin

    anchors.horizontalCenter: parent.horizontalCenter

    color: "transparent"

    QGCLabel{
        id: theText
        text: ""

        horizontalAlignment: Text.AlignHCenter

        anchors.verticalCenter: parent.verticalCenter

        x: _toolsMargin
        y: _toolsMargin
    }

    SequentialAnimation on opacity{
        id: anim

        running: false

        NumberAnimation{
            to: 0.9
            duration: fadeTime
        }
        PauseAnimation{
            duration: time - 2*fadeTime
        }
        NumberAnimation{
            to: 0
            duration: fadeTime
        }

        onRunningChanged:{
            if(!running && selfDestroying)
                root.destroy();
        }
    }
}
