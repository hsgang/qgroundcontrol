import QtQuick 2.0

import QGroundControl.FlightDisplay 1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Controls      1.0

Column{
    id: root

    function show(text, duration){
        var toast = toastComponent.createObject(root);
        toast.selfDestroying = true;
        toast.show(text, duration);
    }

    z: Infinity
    spacing:    ScreenTools.defaultFontPixelHeight * 0.5
    //anchors.centerIn: parent
    anchors.horizontalCenter:   parent.horizontalCenter
    anchors.top:                parent.top
    anchors.margins:            ScreenTools.defaultFontPixelHeight

//    height: parent.height * 0.2
//    clip: true

    property var toastComponent

    Component.onCompleted:
    {
     toastComponent = Qt.createComponent("MessageToast.qml")
    }
}
