import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

Item {
    id:         control
    width:      mainLayout.width
    height:     mainLayout.implicitHeight + (_margins * 2)
    visible:    false

    property var    guidedController
    property var    guidedValueSlider
    property var    messageDisplay
    property string title
    property string message
    property int    action
    property var    actionData
    property bool   hideTrigger:        false
    property var    mapIndicator
    property alias  optionText:         optionCheckBox.text
    property alias  optionChecked:      optionCheckBox.checked

    property real _margins:         2
    property bool _emergencyAction: guidedController ? (action === guidedController.actionEmergencyStop) : false

    Component.onCompleted: guidedController.confirmDialog = this

    onHideTriggerChanged: {
        if (hideTrigger) {
            confirmCancelled()
        }
    }

    function show(immediate) {
        if (immediate) {
            _reallyShow()
        } else {
            // We delay showing the confirmation for a small amount in order for any other state
            // changes to propogate through the system. This way only the final state shows up.
            visibleTimer.restart()
        }
    }

    function reset() {
        visible = false
        if (guidedValueSlider) {
            guidedValueSlider.visible = false
        }
        hideTrigger = false
        visibleTimer.stop()
        if (messageDisplay) {
            messageDisplay.opacity = 1.0
        }
        // messageFadeTimer.stop()
        // messageOpacityAnimation.stop()
    }

    // Cancel the current pending action and notify its map indicator.
    // Pass incomingIndicator when superseding one action with another (e.g. from confirmAction):
    // if the old and new indicator are the same object, actionCancelled() is intentionally skipped
    // so that a show() call made before confirmAction() is not undone (e.g. goto -> goto).
    // Omit incomingIndicator (or pass undefined) for explicit user cancellation via the X button
    // or auto-hide trigger, where the indicator must always be notified.
    function confirmCancelled(incomingIndicator) {
        reset()
        if (mapIndicator && mapIndicator !== incomingIndicator) {
            mapIndicator.actionCancelled()
        }
        mapIndicator = undefined
    }

    function _reallyShow() {
        visible = true
        if (messageDisplay) {
            messageDisplay.opacity = 1.0
        }
        // messageFadeTimer.start()
    }

    Timer {
        id:             visibleTimer
        interval:       1000
        repeat:         false
        onTriggered:    _reallyShow()
    }

    QGCPalette { id: qgcPal }

    RowLayout {
        id:         mainLayout
        y:          _margins
        height:     implicitHeight
        spacing:    ScreenTools.defaultFontPixelWidth

        QGCDelayButton {
            id:                 confirmButton
            text:               control.title
            enabled:            true
            backgroundColor:    Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.75)
            borderColor:        _emergencyAction ? qgcPal.colorRed : qgcPal.colorOrange
            borderWidth:        2
            highlightColor:     _emergencyAction ? qgcPal.colorRed : qgcPal.colorOrange
            progressBorder:     true
            fontWeight:         Font.Bold
            pointSize:          ScreenTools.mediumFontPointSize
            heightFactor:       0.8
            backRadius:         height / 2
            leftPadding:        ScreenTools.defaultFontPixelWidth * 4
            rightPadding:       ScreenTools.defaultFontPixelWidth * 4

            onActivated: {
                control.visible = false
                var sliderOutputValue = 0
                if (guidedValueSlider && guidedValueSlider.visible) {
                    sliderOutputValue = guidedValueSlider.getOutputValue()
                    guidedValueSlider.visible = false
                }
                hideTrigger = false
                let success = false
                if (guidedController) {
                    success = guidedController.executeAction(control.action, control.actionData, sliderOutputValue, control.optionChecked)
                }
                if (mapIndicator) {
                    if (success) {
                        mapIndicator.actionConfirmed()
                    } else {
                        mapIndicator.actionCancelled()
                    }
                    mapIndicator = undefined
                }
            }
        }

        QGCCheckBox {
            id:                 optionCheckBox
            visible:            text !== ""
        }

        // Circular cancel button, height-matched to the confirm button so the two
        // read as a paired confirm / cancel control.
        Rectangle {
            id:                 cancelButton
            Layout.alignment:   Qt.AlignVCenter
            implicitWidth:      confirmButton.height * 0.8
            implicitHeight:     confirmButton.height * 0.8
            radius:             width / 2
            color:              cancelMouseArea.containsMouse
                                    ? qgcPal.windowShadeLight
                                    : Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.75)
            border.color:       qgcPal.text
            border.width:       2

            QGCColoredImage {
                anchors.centerIn:   parent
                width:              parent.width * 0.4
                height:             width
                sourceSize.height:  height
                source:             "/res/XDelete.svg"
                fillMode:           Image.PreserveAspectFit
                color:              qgcPal.text
            }

            QGCMouseArea {
                id:             cancelMouseArea
                fillItem:       parent
                hoverEnabled:   true
                onClicked:      confirmCancelled()
            }
        }
    }
}
