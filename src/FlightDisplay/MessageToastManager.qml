import QtQuick 2.0

import QGroundControl.FlightDisplay 1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Controls      1.0

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
    spacing:    0//ScreenTools.defaultFontPixelHeight * 0.2
    anchors.horizontalCenter:   parent.horizontalCenter
    anchors.bottom:             parent.bottom
    width:                      Math.max(toastComponent.width, mainWindow.width * 0.2)

    property var toastComponent

    Component.onCompleted:
    {
     toastComponent = Qt.createComponent("MessageToast.qml")
    }
}
