/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.15 //2.12
import QtQuick.Controls 2.4
import QtQuick.Layouts  1.12 //1.12
import QtQuick.Shapes   1.15

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Controls      1.0
import QGroundControl.Palette       1.0

Item {
    id: root

    property var    guidedController
    property var    altitudeSlider
    property string title                                       // Currently unused
    property alias  message:            messageText.text
    property int    action
    property var    actionData
    property bool   hideTrigger:        false
    property var    mapIndicator
    property alias  optionText:         optionCheckBox.text
    property alias  optionChecked:      optionCheckBox.checked

    property real _margins:         ScreenTools.defaultFontPixelWidth / 2
    property bool _emergencyAction: action === guidedController.actionEmergencyStop

    Component.onCompleted: guidedController.confirmDialog = this

    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30
    property int    size: _rightPanelWidth * 0.65

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    width: size
    height: size
    visible: false

    function show(immediate) {
        if (immediate) {
            visible = true
        } else {
            // We delay showing the confirmation for a small amount in order for any other state
            // changes to propogate through the system. This way only the final state shows up.
            visibleTimer.restart()
        }
    }

    function confirmCancelled() {
        altitudeSlider.visible = false
        visible = false
        hideTrigger = false
        visibleTimer.stop()
        if (mapIndicator) {
            mapIndicator.actionCancelled()
            mapIndicator = undefined
        }
    }

    onHideTriggerChanged: {
            if (hideTrigger) {
                confirmCancelled()
            }
        }

    onConfirmSignal: {
        //console.log("onMyPressAndHold")
        root.visible = false
        feeder.value = 0
        var altitudeChange = 0
        if (altitudeSlider.visible) {
            altitudeChange = altitudeSlider.getAltitudeChangeValue()
            altitudeSlider.visible = false
        }
        hideTrigger = false
        guidedController.executeAction(root.action, root.actionData, altitudeChange, root.optionChecked)
        if (mapIndicator) {
            mapIndicator.actionConfirmed()
            mapIndicator = undefined
        }
    }

    Timer {
        id:             visibleTimer
        interval:       1000
        repeat:         false
        onTriggered:    visible = true
    }

    property real startAngle: 0
    property real spanAngle: 360
    property real minValue: 0
    property real maxValue: 100
    property int  dialWidth: 15

    property color backgroundColor: "transparent"
    property color dialColor: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5)//"#FF505050"
    property color progressColor: qgcPal.buttonHighlight // "#FFA51BAB"

    property int penStyle: Qt.RoundCap
    //property int dialType: RadialBarShape.DialType.FullDial

    signal pressSignal
    signal releaseSignal
    signal confirmSignal

//    onPressSignal: {
//        console.log("Emit PressSignal")
//    }

//    onReleaseSignal: {
//        console.log("Emit ReleaseSignal")
//    }

    QtObject {
        id: internals

        property real baseRadius: Math.min(root.width / 2, root.height / 2)
        property real radiusOffset: internals.isFullDial ? root.dialWidth / 2 : root.dialWidth / 2
        property real actualSpanAngle: internals.isFullDial ? 360 : root.spanAngle
        property color transparentColor: "transparent"
        property color dialColor: internals.isNoDial ? internals.transparentColor : root.dialColor
    }

    QtObject {
        id: feeder

        property real value: 0

        SequentialAnimation on value {
            id: animator
            running: false
            onFinished: confirmSignal()
            NumberAnimation { to: 100; duration: 500 }
        }
    }

    Shape {
        id: shape
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 8

        property real value: feeder.value

        ShapePath {
            id: pathBackground
            strokeColor: internals.transparentColor
            fillColor: root.backgroundColor
            capStyle: root.penStyle

            PathAngleArc {
                radiusX: internals.baseRadius - root.dialWidth
                radiusY: internals.baseRadius - root.dialWidth
                centerX: root.width / 2
                centerY: root.height / 2
                startAngle: 0
                sweepAngle: 360
            }
        }

        ShapePath {
            id: pathDial
            strokeColor: root.dialColor
            fillColor: internals.transparentColor
            strokeWidth: root.dialWidth
            capStyle: root.penStyle

            PathAngleArc {
                radiusX: internals.baseRadius - internals.radiusOffset
                radiusY: internals.baseRadius - internals.radiusOffset
                centerX: root.width / 2
                centerY: root.height / 2
                startAngle: root.startAngle - 90
                sweepAngle: internals.actualSpanAngle
            }
        }

        ShapePath {
            id: pathProgress
            strokeColor: root.progressColor
            fillColor: internals.transparentColor
            strokeWidth: root.dialWidth
            capStyle: root.penStyle

            PathAngleArc {
                id:      pathProgressArc
                radiusX: internals.baseRadius - internals.radiusOffset
                radiusY: internals.baseRadius - internals.radiusOffset
                centerX: root.width / 2
                centerY: root.height / 2
                startAngle: root.startAngle - 90
                sweepAngle: (internals.actualSpanAngle / root.maxValue * shape.value)
            }
        }
    }

    Rectangle {
        id: pressArea
        width: parent.width * 0.8
        height: parent.height * 0.8
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        radius: width / 2
        color: qgcPal.windowShadeLight
        opacity: onPressSignal ? 1 : 0.5
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onPressed: {
            animator.restart();
            parent.pressSignal();
        }
        onReleased: {
            animator.stop()
            feeder.value = 0
            parent.releaseSignal();
        }
    }

    Rectangle {
        id: cancelRectangle
        width: parent.width * 0.2
        height: width
        anchors.left: parent.right
        anchors.top: parent.bottom
        radius: width / 2
        color: qgcPal.windowShadeLight

        QGCColoredImage {
            anchors.margins:    parent.height / 4
            anchors.fill:       parent
            source:             "/res/XDelete.svg"
            fillMode:           Image.PreserveAspectFit
            color:              qgcPal.text
        }
    }

    MouseArea {
        id: cancelRectangleArea
        anchors.fill: cancelRectangle
        onClicked:
            confirmCancelled()
    }

    QGCCheckBox {
        id:                 optionCheckBox
        Layout.alignment:   Qt.AlignHCenter
        text:               ""
        visible:            text !== ""
    }
    Rectangle {
        width: messageText.width * 1.2
        height: messageText.height * 1.5
        radius: height / 2
        anchors.margins: _toolsMargin
        anchors.bottom: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        color: qgcPal.windowShadeDark
        QGCLabel {
            id:                     messageText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter:   parent.verticalCenter
            //Layout.fillWidth:       true
            horizontalAlignment:    Text.AlignHCenter
            wrapMode:               Text.WordWrap
            color:                  qgcPal.text
        }
    }

    QGCLabel{
        text: "Press to Confirm"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter:   parent.verticalCenter
        //Layout.fillWidth:       true
        horizontalAlignment:    Text.AlignHCenter
        wrapMode:               Text.WordWrap
    }
}


