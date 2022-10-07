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
    spacing:    ScreenTools.defaultFontPixelHeight * 0.5
    anchors.horizontalCenter:   parent.horizontalCenter
    anchors.top:                parent.top
    anchors.margins:            ScreenTools.defaultFontPixelHeight
    width:                      mainWindow.width * 0.5

    property var toastComponent

    Component.onCompleted:
    {
     toastComponent = Qt.createComponent("MessageToast.qml")
    }
}
