/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.15
import QtQuick.Controls         2.15
import QtQuick.Layouts          1.15

import QGroundControl.FactSystem    1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0

SpinBox {
    id:             spinbox
    implicitWidth:  ScreenTools.defaultFontPixelWidth * 14
    font.pointSize: ScreenTools.defaultFontPointSize
    font.family:    ScreenTools.normalFontFamily
    editable:       true

    from:           spinbox.fromValue * spinbox.factor
    to:             spinbox.toValue * spinbox.factor
    stepSize:       spinbox.stepValue * spinbox.factor
    value:          spinbox.internalValue

    property Fact fact

    property bool _loadComplete: false

    property int    decimals:     0
    property double fromValue:  0.0
    property double toValue:    100.0
    property double internalValue:  spinbox.realValue * spinbox.factor
    property double realValue:    fact.value//.toFixed(spinbox.decimals)
    property double stepValue:    0.1

    readonly property int factor: Math.pow(10, spinbox.decimals)

    Component.onCompleted: _loadComplete = true

    validator: DoubleValidator {
        bottom: Math.min(spinbox.from, spinbox.to)
        top:  Math.max(spinbox.from, spinbox.to)
    }

    textFromValue: function(value, locale) {
        return Number(value / spinbox.factor).toLocaleString(locale, 'f', spinbox.decimals)
    }

    valueFromText: function(text, locale) {
        return Number.fromLocaleString(locale, text) * spinbox.factor
    }

    onRealValueChanged:
        if (_loadComplete) {
            spinbox.internalValue = spinbox.realValue * spinbox.factor
            //fact.value = Math.round(spinbox.realValue * spinbox.factor) / spinbox.factor
        }

    onInternalValueChanged: {
        if(_loadComplete) {
            spinbox.realValue = spinbox.internalValue / spinbox.factor
            //fact.value = Math.round(spinbox.realValue * spinbox.factor) / spinbox.factor
            //fact.value = spinbox.realValue
        }
    }

    onValueChanged: {
        if (_loadComplete) {
            //fact.value = Math.round(spinbox.realValue * spinbox.factor) / spinbox.factor

            fact.value = (spinbox.value / spinbox.factor)
        }
    }

    up.indicator: Rectangle{
        height: parent.height
        width:  height
        anchors.right: parent.right
        anchors.top:    parent.top
        color: qgcPal.button
        border.color:   qgcPal.text
        radius:     ScreenTools.defaultFontPixelHeight / 4
        Text {
            text: '+'
            anchors.centerIn: parent
            color: qgcPal.text
        }
    }

    down.indicator: Rectangle{
        height: parent.height
        width:  height
        anchors.left: parent.left
        anchors.top:    parent.top
        color: qgcPal.button
        border.color:   qgcPal.text
        radius:     ScreenTools.defaultFontPixelHeight / 4
        Text {
            text: '-'
            anchors.centerIn: parent
            color: qgcPal.text
        }
    }
}
