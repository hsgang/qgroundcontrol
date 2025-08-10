import QtQuick
import QtQuick.Controls

import QGroundControl

Menu {
    background: Rectangle {
        implicitWidth: ScreenTools.defaultFontPixelWidth * 30
        color: qgcPal.window
        border.color: qgcPal.text
        border.width: 1
    }
    padding: {
        left: ScreenTools.defaultFontPixelWidth / 2
        right: ScreenTools.defaultFontPixelWidth / 2
    }
}
