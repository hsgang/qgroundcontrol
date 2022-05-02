import QtQuick 2.0

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0

import QtGraphicalEffects 1.0

Rectangle{

    id: root

    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75

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
    height: theText.height // _toolsMargin
    radius: _toolsMargin

    anchors.horizontalCenter: parent.horizontalCenter

    //color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5)
    color: "transparent"

//    Text{
//        id: theText
//        color: qgcPal.text
//        font.pointSize: ScreenTools.defaultFontPointSize
//        font.family:    ScreenTools.normalFontFamily
//        antialiasing:   true

//        text: ""

//        anchors.horizontalCenter: parent.horizontalCenter
//        anchors.verticalCenter: parent.verticalCenter
//        //x: _toolsMargin
//        //y: _toolsMargin
//        wrapMode: Text.WordWrap
//    }

    Glow {
        anchors.fill: theText
        radius: 2
        samples: 5
        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
        source: theText
    }

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
