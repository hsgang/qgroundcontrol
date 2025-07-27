import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls

Rectangle {
    id: control
    width: ScreenTools.defaultFontPixelHeight * 5
    height: width
    radius: width / 2
    color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.6)

    property int escIndex
    property real rpm
    property real voltage
    property real temperature
    property real current
    property real maxRpm
    property real maxTemperature

    property real _strokeWidth : ScreenTools.defaultFontPixelWidth * 0.8

    Shape {
        anchors.fill: parent
        ShapePath {
            strokeColor: Qt.rgba(qgcPal.text.r, qgcPal.text.g, qgcPal.text.b, 0.3)
            strokeWidth: _strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: control.width / 2
                centerY: control.height / 2
                radiusX: control.width * 0.45 - _strokeWidth / 2
                radiusY: radiusX
                startAngle: -270
                sweepAngle: 360
            }
        }

        ShapePath {
            strokeColor: qgcPal.textHighlight
            strokeWidth: _strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                id: pathAngleArc
                centerX: control.width / 2
                centerY: control.height / 2
                radiusX: control.width * 0.45 - _strokeWidth / 2
                radiusY: radiusX
                startAngle: -270
                sweepAngle: (rpm / maxRpm) * 360
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 0

        QGCLabel {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "RPM" + escIndex
            font.pointSize: _dataFontSize * 0.7
        }

        QGCLabel {
            anchors.horizontalCenter: parent.horizontalCenter
            text: isNaN(rpm) ? "--" : rpm.toFixed(0)
            font.bold: true
            font.pointSize: _dataFontSize * 1.1
        }

        QGCLabel {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Power"
            font.pointSize: _dataFontSize * 0.7
        }

        QGCLabel {
            anchors.horizontalCenter: parent.horizontalCenter
            text: isNaN(voltage) ? "--" : voltage.toFixed(1) + " V" + (isNaN(current) ? "" : "/ " + current.toFixed(1) + " A")
            font.bold: true
            font.pointSize: _dataFontSize * 1.1
        }

        QGCLabel {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Temp"
            font.pointSize: _dataFontSize * 0.7
        }

        QGCLabel {
            anchors.horizontalCenter: parent.horizontalCenter
            text: isNaN(temperature) ? "--" : temperature.toFixed(0) + " ℃"
            font.bold: true
            font.pointSize: _dataFontSize * 1.1
        }        
    }

    SequentialAnimation {
        id: valueAnimation

        NumberAnimation {
            target: pathAngleArc
            property: "sweepAngle"
            from: 0
            to: 360
            duration: 1000
            easing.type: Easing.InOutQuad
        }

        PauseAnimation {
            duration: 300
        }

        NumberAnimation {
            target: pathAngleArc
            property: "sweepAngle"
            from: 360
            to: 0
            duration: 2000
            easing.type: Easing.InOutQuad
        }
    }

    Component.onCompleted: {
        valueAnimation.start()
    }
    onVisibleChanged: {
        valueAnimation.restart()
    }
}




