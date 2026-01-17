import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls

Switch {
    id:             control
    spacing:        _noText ? 0 : ScreenTools.defaultFontPixelWidth
    focusPolicy:    Qt.ClickFocus
    leftPadding:    0

    property color  textColor:          qgcPal.buttonText
    property bool   textBold:           false
    property real   textFontPointSize:  ScreenTools.defaultFontPointSize

    property bool   _noText:            text === ""
    property bool   _showBorder:        qgcPal.globalTheme === QGCPalette.Light
    property bool   _showHighlight:     enabled && (pressed || checked)
    property int    _sliderInset:       2

    QGCPalette { id: qgcPal; colorGroupEnabled: control.enabled }

    Component.onCompleted: {
        if (_noText) {
            rightPadding = 0
        }
    }

    contentItem: Text {
        leftPadding:        control.indicator.width + control.spacing
        verticalAlignment:  Text.AlignVCenter
        text:               control.text
        font.pointSize:     textFontPointSize
        font.bold:          control.textBold
        font.family:        ScreenTools.normalFontFamily
        color:              control.textColor
    }

    indicator: Rectangle {
        id:                     switchTrack
        implicitWidth:          ScreenTools.defaultFontPixelHeight * 2
        implicitHeight:         ScreenTools.defaultFontPixelHeight
        x:                      control.leftPadding
        y:                      parent.height / 2 - height / 2
        radius:                 height / 2
        color:                  control.checked ? qgcPal.buttonHighlight : qgcPal.button
        border.width:           _showBorder ? 1 : 0
        border.color:           qgcPal.groupBorder

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        // Hover overlay
        Rectangle {
            anchors.fill:   parent
            color:          qgcPal.buttonHighlight
            opacity:        _showHighlight ? 1 : control.enabled && control.hovered ? 0.2 : 0
            radius:         parent.radius

            Behavior on opacity {
                NumberAnimation { duration: 100 }
            }
        }

        // Switch knob
        Rectangle {
            id:                     switchKnob
            anchors.verticalCenter: parent.verticalCenter
            x:                      control.checked ? switchTrack.width - width - _sliderInset : _sliderInset
            width:                  switchTrack.height - (_sliderInset * 2)
            height:                 width
            radius:                 height / 2
            color:                  qgcPal.buttonText

            Behavior on x {
                NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
            }
        }
    }
}
