import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.ScreenTools

TabBar {
    id: control

    contentItem: ListView {
        model: control.contentModel
        currentIndex: control.currentIndex

        spacing: control.spacing
        orientation: ListView.Vertical   // <<-- VERTICAL
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.AutoFlickIfNeeded
        snapMode: ListView.SnapToItem

        highlightMoveDuration: 0
        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: ScreenTools.defaultFontPixelHeight
        preferredHighlightEnd: height - ScreenTools.defaultFontPixelHeight
    }

    background: Rectangle {
        color: qgcPal.window
    }
}
