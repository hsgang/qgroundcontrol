import QtQuick

import QGroundControl.FlightDisplay
import QGroundControl.ScreenTools
import QGroundControl.Controls

Column{
    id: root

    function show(text, duration){
        var toast = toastComponent.createObject(root);
        toast.selfDestroying = true;
        var splitedText = text.split("]");
        var splitedText2 = splitedText[1].split("<");
        text = splitedText2[0].toString();
        toast.show(text, duration);
    }

    z: Infinity
    spacing:    0
    anchors.horizontalCenter:   parent.horizontalCenter
    anchors.bottom:             parent.bottom
    width:                      toastComponent ? toastComponent.width : 0//Math.max(toastComponent.width, mainWindow.width * 0.2)

    property var toastComponent

    Component.onCompleted:
    {
        toastComponent = Qt.createComponent("MessageToast.qml")
    }
}
