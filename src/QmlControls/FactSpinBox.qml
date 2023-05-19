import QtQuick                      2.3
import QtQuick.Controls             1.4
import QtQuick.Controls.Styles      1.4
import QtQuick.Layouts              1.15

import QGroundControl.FactSystem    1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0

SpinBox {
    id:             spinbox
    implicitWidth:  ScreenTools.defaultFontPixelWidth * 10
    font.pointSize: ScreenTools.defaultFontPointSize
    font.family:    ScreenTools.normalFontFamily

    minimumValue:   fromValue
    maximumValue:   toValue
    stepSize:       stepValue
    value:          fact.value

    property Fact fact

    property real fromValue:    0
    property real toValue:      100.0
    property real stepValue:    0.1

    Component.onCompleted: _loadComplete = true

    onValueChanged: {
        if (_loadComplete) {
            fact.value = spinbox.value
        }
    }

    style: SpinBoxStyle{
        background: Rectangle{
            implicitWidth: spinbox.implicitWidth
            implicitHeight: ScreenTools.defaultFontPixelHeight * 1.2
            border.color: qgcPal.text
            radius:         ScreenTools.defaultFontPixelHeight / 4
        }

        incrementControl: Rectangle{
            implicitHeight: ScreenTools.defaultFontPixelHeight / 2
            implicitWidth:  ScreenTools.defaultFontPixelWidth * 2
            color:          qgcPal.button
            border.color:   qgcPal.text
            radius:         ScreenTools.defaultFontPixelHeight / 4
            Text{
                text: "▲"
                font.pixelSize: ScreenTools.defaultFontPixelHeight / 2
                anchors.centerIn: parent
                color: qgcPal.text
            }
        }
        decrementControl: Rectangle{
            implicitHeight: ScreenTools.defaultFontPixelHeight / 2
            implicitWidth:  ScreenTools.defaultFontPixelWidth * 2
            color:          qgcPal.button
            border.color:   qgcPal.text
            radius:         ScreenTools.defaultFontPixelHeight / 4
            Text{
                text: "▼"
                font.pixelSize: ScreenTools.defaultFontPixelHeight / 2
                anchors.centerIn: parent
                color: qgcPal.text
            }
        }
    }
}
