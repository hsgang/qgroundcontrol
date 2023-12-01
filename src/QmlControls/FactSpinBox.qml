import QtQuick                      2.15//2.3
import QtQuick.Controls             2.15//1.4
//import QtQuick.Controls.Styles      1.4
import QtQuick.Layouts              1.15

import QGroundControl.FactSystem    1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0

SpinBox {
    id:             spinbox
    implicitWidth:  ScreenTools.defaultFontPixelWidth * 12
    implicitHeight: ScreenTools.defaultFontPixelHeight * 1.5
    font.pointSize: ScreenTools.defaultFontPointSize
    font.family:    ScreenTools.normalFontFamily

    stepSize:       stepValue * exponentiation
    value:          fact.value * exponentiation
    to:             toValue * exponentiation
    from:           fromValue * exponentiation

    editable:       true
    focusPolicy:    Qt.ClickFocus

    property Fact fact

    property real fromValue
    property real toValue
    property real stepValue
    property int  decimals

    property real realValue: value / exponentiation
    property real exponentiation : Math.pow(10, decimals)

    Component.onCompleted: _loadComplete = true

    onValueChanged: {
        if (_loadComplete) {
            fact.value = spinbox.value / exponentiation
        }
    }

    validator: DoubleValidator {
            bottom: Math.min(spinbox.from, spinbox.to)
            top:  Math.max(spinbox.from, spinbox.to)
    }

    textFromValue: function(value, locale) {
        return Number(value / exponentiation).toLocaleString(locale, 'f', spinbox.decimals)
    }

    valueFromText: function(text, locale) {
        return Number.fromLocaleString(locale, text) * exponentiation
    }

//    style: SpinBoxStyle{
//        background: Rectangle{
//            implicitWidth: spinbox.implicitWidth
//            implicitHeight: ScreenTools.defaultFontPixelHeight * 1.2
//            border.color: qgcPal.text
//            radius:         ScreenTools.defaultFontPixelHeight / 4
//        }

//        incrementControl: Rectangle{
//            implicitHeight: ScreenTools.defaultFontPixelHeight / 2
//            implicitWidth:  ScreenTools.defaultFontPixelWidth * 2
//            color:          qgcPal.button
//            border.color:   qgcPal.text
//            radius:         ScreenTools.defaultFontPixelHeight / 4
//            Text{
//                text: "▲"
//                font.pixelSize: ScreenTools.defaultFontPixelHeight / 2
//                anchors.centerIn: parent
//                color: qgcPal.text
//            }
//        }
//        decrementControl: Rectangle{
//            implicitHeight: ScreenTools.defaultFontPixelHeight / 2
//            implicitWidth:  ScreenTools.defaultFontPixelWidth * 2
//            color:          qgcPal.button
//            border.color:   qgcPal.text
//            radius:         ScreenTools.defaultFontPixelHeight / 4
//            Text{
//                text: "▼"
//                font.pixelSize: ScreenTools.defaultFontPixelHeight / 2
//                anchors.centerIn: parent
//                color: qgcPal.text
//            }
//        }
//    }
}
