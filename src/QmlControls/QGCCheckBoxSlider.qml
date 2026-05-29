import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

AbstractButton   {
    id:         control
    checkable:  true
    padding:    0

    property bool _isLight:         qgcPal.globalTheme === QGCPalette.Light
    property alias description:     _description.text
    property int  _sliderInset:     2

    // OFF track: always brighter than page background to stay visible on dark theme
    property color _trackOff:       _isLight ? qgcPal.windowShade
                                             : Qt.lighter(qgcPal.windowShade, 1.6)

    QGCPalette { id: qgcPal; colorGroupEnabled: control.enabled }

    contentItem: Item {
        implicitWidth:  label.contentWidth + indicator.width + ScreenTools.defaultFontPixelWidth
        implicitHeight: label.contentHeight + (description.length > 0 ? _description.contentHeight : 0)

        ColumnLayout {
            id:                 labelLayout
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            spacing : ScreenTools.defaultFontPixelHeight * 0.2
            QGCLabel {
                id:             label
                text:           visible ? control.text : "X"
                visible:        control.text !== ""
            }
            QGCLabel {
                id:                 _description
                visible:            description.length > 0
                Layout.fillWidth:   true
                font.pointSize:     ScreenTools.smallFontPointSize
                color:              Qt.darker(QGroundControl.globalPalette.text, 1.5)
            }
        }

        Rectangle {
            id:                     indicator
            anchors.right:          parent.right
            anchors.verticalCenter: parent.verticalCenter
            height:                 ScreenTools.defaultFontPixelHeight
            width:                  height * 2
            radius:                 height / 2
            color:                  control.checked ? qgcPal.buttonHighlight : _trackOff
            border.width:           1
            border.color:           control.checked ? Qt.darker(qgcPal.buttonHighlight, 1.2)
                                                    : qgcPal.groupBorder
            opacity:                control.enabled ? 1.0 : 0.45

            Behavior on color { ColorAnimation { duration: 160 } }

            // Hover tint (subtle — never makes OFF look ON)
            Rectangle {
                anchors.fill: parent
                radius:       parent.radius
                color:        control.checked ? Qt.lighter(qgcPal.buttonHighlight, 1.15)
                                              : Qt.lighter(_trackOff, 1.15)
                opacity:      control.enabled && control.hovered ? 0.35 : 0
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            // Thumb drop shadow (1px offset)
            Rectangle {
                y:      (indicator.height - height) / 2 + 1
                x:      control.checked ? indicator.width - width - _sliderInset
                                        : _sliderInset
                height: indicator.height - (_sliderInset * 2)
                width:  height
                radius: height / 2
                color:  "#33000000" // ~20% black, theme-agnostic
                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            }

            // Thumb (white, theme-agnostic — matches iOS / Material 3 / Win11 / macOS)
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x:            control.checked ? indicator.width - width - _sliderInset
                                              : _sliderInset
                height:       indicator.height - (_sliderInset * 2)
                width:        height
                radius:       height / 2
                color:        "#FFFFFF"
                border.width: 1
                border.color: "#1F000000" // ~12% black to define edge
                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            }
        }
    }
}
