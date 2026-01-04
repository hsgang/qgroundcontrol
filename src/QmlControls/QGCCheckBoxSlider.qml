import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

AbstractButton   {
    id:         control
    checkable:  true
    padding:    0

    property bool _showBorder:      qgcPal.globalTheme === QGCPalette.Light
    property alias description:     _description.text
    property int  _sliderInset:     2
    property bool _showHighlight:   enabled && (pressed || checked)

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
                //anchors.left:   parent.left
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
            color:                  checked ? qgcPal.buttonHighlight : qgcPal.button
            border.width:           _showBorder ? 1 : 0
            border.color:           qgcPal.groupBorder

            Rectangle {
                anchors.fill:   parent
                color:          qgcPal.buttonHighlight
                opacity:        _showHighlight ? 1 : control.enabled && control.hovered ? .2 : 0
                radius:         parent.radius
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x:                      checked ? indicator.width - width - _sliderInset : _sliderInset
                height:                 parent.height - (_sliderInset * 2)
                width:                  height
                radius:                 height / 2
                color:                  qgcPal.buttonText
            }
        }
    }
}
