import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools


CheckBox {
    id:             control
    focusPolicy:    Qt.ClickFocus
    checked:        true
    leftPadding:    0

    property var            color:          qgcPal.text
    property bool           showSpacer:     true
    property ButtonGroup    buttonGroup:    null

    property real _sectionSpacer: ScreenTools.defaultFontPixelWidth / 2  // spacing between section headings

    onButtonGroupChanged: {
        if (buttonGroup) {
            buttonGroup.addButton(control)
        }
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    contentItem: ColumnLayout {
        Item {
            Layout.preferredHeight: control._sectionSpacer
            width:                  1
            visible:                control.showSpacer
        }

        QGCLabel {
            text:               control.text
            color:              control.color
            Layout.fillWidth:   true

            QGCColoredImage {
                anchors.right:          parent.right
                anchors.verticalCenter: parent.verticalCenter
                width:                  parent.height * 0.7
                height:                 width
                source:                 "/InstrumentValueIcons/cheveron-up.svg"//control.checked ? "/InstrumentValueIcons/cheveron-up.svg" : "/InstrumentValueIcons/cheveron-down.svg" //"/qmlimages/arrow-down.png"
                color:                  qgcPal.text
                rotation:               control.checked ? 0 : 180
                Behavior on rotation { NumberAnimation { duration: 300 }}
                // visible:                !control.checked
            }
        }

        Rectangle {
            Layout.fillWidth:   true
            height:             1
            color:              qgcPal.groupBorder
        }
    }

    indicator: Item {}
}
