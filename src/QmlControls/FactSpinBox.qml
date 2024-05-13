import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl.FactSystem
import QGroundControl.Palette
import QGroundControl.ScreenTools

SpinBox {
    id:             control
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

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    Component.onCompleted: _loadComplete = true

    onValueChanged: {
        if (_loadComplete) {
            fact.value = parseFloat((control.value/exponentiation).toFixed(decimals))
        }
    }

    validator: DoubleValidator {
            bottom: Math.min(control.from, control.to)
            top:  Math.max(control.from, control.to)
    }

    textFromValue: function(value, locale) {
        return Number(value/exponentiation).toLocaleString(locale, 'f', control.decimals)
    }

    valueFromText: function(text, locale) {
        return Number.fromLocaleString(locale, text) * exponentiation
    }

    contentItem: TextInput {
        z: 2
        text: control.textFromValue(control.value, control.locale)

        font: control.font
        color: "#000000"
        selectionColor: "#000000"
        selectedTextColor: "#ffffff"
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter

        readOnly: !control.editable
        validator: control.validator
        inputMethodHints: Qt.ImhFormattedNumbersOnly
    }

    up.indicator: Rectangle {
        x: control.mirrored ? 0 : parent.width - width
        height: parent.height
        implicitWidth: ScreenTools.defaultFontPixelHeight
        implicitHeight: parent.height
        color: control.up.pressed ? qgcPal.windowShadeLight : qgcPal.windowShade
        radius: ScreenTools.defaultFontPixelHeight / 4
        border.color: "#ffffff"

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
        implicitWidth: ScreenTools.defaultFontPixelHeight
        implicitHeight: parent.height
        color: control.down.pressed ? qgcPal.windowShadeLight : qgcPal.windowShade
        radius: ScreenTools.defaultFontPixelHeight / 4
        border.color: "#ffffff"

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
        border.color: "#bdbebf"
        radius: ScreenTools.defaultFontPixelHeight / 4
    }
}
