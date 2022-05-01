import QtQuick 2.0

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0


/**
* @brief An Android-like timed message text in a box that selfdestroys when finished if desired
*/
Rectangle{

    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75

    /**
    * Public
    */

    /**
    * @brief Shows this Toast
    *
    * @param {string} text Text to show
    * @param {real} duration Duration to show in milliseconds, defaults to 3000
    */
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

    /**
    * Private
    */

    id: root

    property real time: defaultTime
    readonly property real defaultTime: 5000
    readonly property real fadeTime: 300

    width: theText.width + _toolsMargin * 3
    height: theText.height // _toolsMargin
    radius: _toolsMargin

    anchors.horizontalCenter: parent.horizontalCenter
    //anchors.verticalCenter: parent.verticalCenter

//    opacity: 0
    color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5)

//    Text{
//        id: theText
//        text: ""

//        horizontalAlignment: Text.AlignHCenter
//        x: margin
//        y: margin
//    }

    QGCLabel{
        id: theText
        text: ""

        horizontalAlignment: Text.AlignHCenter

        //anchors.verticalCenter: parent.verticalCenter

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
