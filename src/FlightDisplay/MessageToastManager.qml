import QtQuick

import QGroundControl.FlightDisplay
import QGroundControl.ScreenTools
import QGroundControl.Controls

ListView {
    function show(text, duration) {
        var splitedText = text.split("]");
        var splitedText2 = splitedText[1].split("<");
        text = splitedText2[0].toString();
        model.insert(0, {text: text, duration: duration});
    }

    id: root

    z:                          Infinity
    spacing:                    ScreenTools.defaultFontPixelWidth
    anchors.fill:               parent
    anchors.bottomMargin:       ScreenTools.defaultFontPixelHeight
    verticalLayoutDirection:    ListView.TopToBottom

    interactive: false

    displaced: Transition {
            NumberAnimation {
                properties: "y"
                easing.type: Easing.InOutQuad
            }
        }

    delegate: MessageToast {
        Component.onCompleted: {
            if (typeof duration === "undefined") {
                show(text);
            }
            else {
                show(text, duration);
            }
        }
    }

    model: ListModel {id: model}
}
