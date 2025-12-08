/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

ColumnLayout {
    id: root
    spacing: ScreenTools.defaultFontPixelHeight / 4

    property Fact   fact:                   null
    property bool   showUnits:              true
    property bool   showLabel:              true
    property string label:                  fact ? fact.name : ""
    property real   largeStep:              10
    property real   smallStep:              1
    property bool   showEnableCheckbox:     false
    property alias  enableCheckBoxChecked:  enableCheckbox.checked

    signal enableCheckboxClicked

    property real   _value:             fact ? fact.value : 0
    property string _units:             fact && showUnits ? fact.units : ""
    property int    _decimalPlaces:     fact ? fact.decimalPlaces : 2
    property real   _minValue:          fact ? fact.min : -Infinity
    property real   _maxValue:          fact ? fact.max : Infinity

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    function clampValue(value) {
        return Math.max(_minValue, Math.min(_maxValue, value))
    }

    function formatValue(value) {
        return value.toFixed(_decimalPlaces)
    }

    function updateFactValue(newValue) {
        if (fact) {
            fact.value = clampValue(newValue)
        }
    }

    RowLayout {
        QGCLabel {
            Layout.fillWidth:   true
            text:               label + (showUnits && _units !== "" ? " (" + _units + ")" : "")
            visible:            showLabel && label !== ""
        }

        QGCCheckBoxSlider {
            id:         enableCheckbox
            visible:    root.showEnableCheckbox
            Layout.alignment:   Qt.AlignLeft

            onClicked: root.enableCheckboxClicked()
        }
    }

    RowLayout {
        Layout.fillWidth:   true
        spacing:            ScreenTools.defaultFontPixelWidth * 0.5

        // Large decrement button (-10)
        QGCButton {
            text: "-" + largeStep
            enabled: root.enabled && fact && (_value - largeStep >= _minValue) && (!root.showEnableCheckbox || enableCheckbox.checked)
            Layout.preferredWidth: ScreenTools.defaultFontPixelWidth* 6
            onClicked: updateFactValue(_value - largeStep)
            leftPadding:    ScreenTools.defaultFontPixelWidth
            rightPadding:   ScreenTools.defaultFontPixelWidth
        }

        // Small decrement button (-1)
        QGCButton {
            text: "-" + smallStep
            enabled: root.enabled && fact && (_value - smallStep >= _minValue) && (!root.showEnableCheckbox || enableCheckbox.checked)
            Layout.preferredWidth: ScreenTools.defaultFontPixelWidth* 6
            onClicked: updateFactValue(_value - smallStep)
            leftPadding:    ScreenTools.defaultFontPixelWidth
            rightPadding:   ScreenTools.defaultFontPixelWidth
        }

        FactTextField {
            id:                     factTextField
            Layout.fillWidth:       true
            fact:                   root.fact
            showUnits:              false
            horizontalAlignment:    Text.AlignHCenter
            enabled:                !root.showEnableCheckbox || enableCheckbox.checked
        }

        // Small increment button (+1)
        QGCButton {
            text: "+" + smallStep
            enabled: root.enabled && fact && (_value + smallStep <= _maxValue) && (!root.showEnableCheckbox || enableCheckbox.checked)
            Layout.preferredWidth: ScreenTools.defaultFontPixelWidth* 6
            onClicked: updateFactValue(_value + smallStep)
            leftPadding:    ScreenTools.defaultFontPixelWidth
            rightPadding:   ScreenTools.defaultFontPixelWidth
        }

        // Large increment button (+10)
        QGCButton {
            text: "+" + largeStep
            enabled: root.enabled && fact && (_value + largeStep <= _maxValue) && (!root.showEnableCheckbox || enableCheckbox.checked)
            Layout.preferredWidth: ScreenTools.defaultFontPixelWidth* 6
            onClicked: updateFactValue(_value + largeStep)
            leftPadding:    ScreenTools.defaultFontPixelWidth
            rightPadding:   ScreenTools.defaultFontPixelWidth
        }
    }
}
