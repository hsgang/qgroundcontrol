import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl.FactSystem
import QGroundControl.Palette
import QGroundControl.ScreenTools

SpinBox {
    id:             control
    implicitWidth:  ScreenTools.defaultFontPixelWidth * 20
    implicitHeight: ScreenTools.defaultFontPixelHeight * 1.5
    font.pointSize: ScreenTools.defaultFontPointSize
    font.family:    ScreenTools.normalFontFamily

    // from:           fromValue * exponentiation
    // value:          fact.value * exponentiation
    // to:             toValue * exponentiation
    // stepSize:       stepValue * exponentiation
    from:           decimalToInt(fromValue)
    value:          decimalToInt(factValue)
    to:             decimalToInt(toValue)
    stepSize:       decimalToInt(stepValue)
    editable:       true
    focusPolicy:    Qt.ClickFocus

    property Fact fact

    property real fromValue
    property real toValue
    property real stepValue
    property int  decimals
    property real factValue: fact.value

    property real realValue: value / exponentiation
    property real exponentiation : Math.pow(10, decimals + 3)

    function decimalToInt(decimal) {
        return decimal * exponentiation
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    Component.onCompleted: _loadComplete = true

    onValueModified: {
        if (_loadComplete) {
            console.log(value)
            fact.value = Number(Math.round(value)/exponentiation.toFixed(decimals))//parseFloat((control.value/exponentiation).toFixed(decimals))
            console.log(fact.value)
        }
    }

    validator: DoubleValidator {
            bottom: Math.min(control.from, control.to)
            top:  Math.max(control.from, control.to)
            decimals: control.decimals
            notation: DoubleValidator.StandardNotation
    }

    textFromValue: function(value, locale) {
        return Number(Math.round(value)/exponentiation).toLocaleString(locale, 'f', control.decimals)
    }

    valueFromText: function(text, locale) {
        return Math.round(Number.fromLocaleString(locale, text) * exponentiation)
    }

    contentItem: TextInput {
        z: 2
        text: control.textFromValue(control.value, control.locale)

        font: control.font
        color: qgcPal.text
        selectionColor: qgcPal.text
        selectedTextColor: qgcPal.window
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter

        readOnly: !control.editable
        validator: control.validator
        inputMethodHints: Qt.ImhFormattedNumbersOnly
    }

    up.indicator: Rectangle {
        x: control.mirrored ? 0 : parent.width - width
        height: parent.height
        implicitWidth: ScreenTools.defaultFontPixelHeight * 1.6
        implicitHeight: parent.height
        color: (control.up.hovered || control.up.pressed) ? qgcPal.buttonHighlight : qgcPal.windowShade
        radius: ScreenTools.defaultFontPixelHeight / 4
        border.color: qgcPal.groupBorder

        Text {
            text: "+"
            font.pixelSize: control.font.pixelSize * 2
            color: qgcPal.text
            anchors.fill: parent
            fontSizeMode: Text.Fit
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    down.indicator: Rectangle {
        x: control.mirrored ? parent.width - width : 0
        height: parent.height
        implicitWidth: ScreenTools.defaultFontPixelHeight * 1.6
        implicitHeight: parent.height
        color: (control.down.hovered || control.down.pressed) ? qgcPal.buttonHighlight : qgcPal.windowShade
        radius: ScreenTools.defaultFontPixelHeight / 4
        border.color: qgcPal.groupBorder

        Text {
            text: "-"
            font.pixelSize: control.font.pixelSize * 2
            color: qgcPal.text
            anchors.fill: parent
            fontSizeMode: Text.Fit
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    background: Rectangle {
        implicitWidth: control.implicitWidth
        border.color: qgcPal.groupBorder
        color: qgcPal.windowShadeLight
        radius: ScreenTools.defaultFontPixelHeight / 4
    }
}
