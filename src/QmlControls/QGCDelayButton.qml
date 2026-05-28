import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes

import QGroundControl
import QGroundControl.Controls

DelayButton {
    id:             control
    hoverEnabled:   !ScreenTools.isMobile
    topPadding:     _verticalPadding
    bottomPadding:  _verticalPadding
    leftPadding:    _horizontalPadding
    rightPadding:   _horizontalPadding
    focusPolicy:    Qt.ClickFocus
    font.family:    ScreenTools.normalFontFamily
    delay:          defaultDelay

    property bool   showBorder:     qgcPal.globalTheme === QGCPalette.Light
    property real   backRadius:     ScreenTools.defaultBorderRadius
    property real   heightFactor:   0.5
    property real   fontWeight:     Font.Normal // default for qml Text
    property real   pointSize:      ScreenTools.defaultFontPointSize
    property int    defaultDelay:   500

    property alias wrapMode:            text.wrapMode
    property alias horizontalAlignment: text.horizontalAlignment
    property alias backgroundColor:     backRect.color
    property alias textColor:           text.color
    property color borderColor:         qgcPal.buttonBorder
    property real  borderWidth:         showBorder ? 1 : 0
    property color highlightColor:      qgcPal.buttonHighlight
    property bool  progressBorder:      false   // when true: border draws clockwise as progress advances

    property bool   _showHighlight:     enabled && pressed
    property int    _horizontalPadding: ScreenTools.defaultFontPixelWidth * 2
    property int    _verticalPadding:   Math.round(ScreenTools.defaultFontPixelHeight * heightFactor)
    property bool   _showHelp:          false
    property bool   _activated:         false

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    Timer {
        id:         helpTimeout
        interval:   3000
        repeat:     false
        onTriggered: control._showHelp = false
    }

    onActivated: {
        _activated = true
        _showHelp = false
    }
    onPressed: {
        _activated = false
    }
    onReleased: {
        _showHelp = !_activated
        _activated = false
        if (_showHelp) {
            helpTimeout.start()
        } else {
            helpTimeout.stop()
        }
    }

    background: Rectangle {
        id:             backRect
        radius:         backRadius
        implicitWidth:  Math.max(ScreenTools.defaultFontPixelWidth * 16, Math.max(control._showHelp ? helpText.contentWidth : 0, ScreenTools.implicitButtonWidth))
        implicitHeight: ScreenTools.implicitButtonHeight
        border.width:   control.borderWidth
        border.color:   control.borderColor
        color:          qgcPal.button

        Rectangle {
            anchors.fill:   parent
            color:          control.highlightColor
            opacity:        control._showHighlight
                                ? (control.progressBorder ? 0.18 : 1)
                                : (control.enabled && control.hovered ? 0.15 : 0)
            radius:         parent.radius

            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on color   { ColorAnimation  { duration: 150 } }
        }

        QGCColoredImage {
            anchors.topMargin:      _sliderIndicatorMargin
            anchors.bottomMargin:   _sliderIndicatorMargin
            anchors.leftMargin:     control.pressed ? (parent.width - width) * control.progress : 0
            anchors.left:           parent.left
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            width:                  height
            source:                 "qrc:/res/chevron-double-right.svg"
            sourceSize.height:      parent.height
            fillMode:               Image.PreserveAspectFit
            color:                  control._showHighlight ? qgcPal.buttonHighlightText : qgcPal.buttonText
            opacity:                control._showHighlight ? 0.75 : 0.2
            visible:                !control.progressBorder

            property real _sliderIndicatorMargin: ScreenTools.defaultFontPixelHeight * 0.5
        }

        // 시계방향 진행 테두리 — progressBorder 옵션이 켜진 경우에만 활성화
        Shape {
            id:             progressShape
            anchors.fill:   parent
            anchors.margins: control.borderWidth / 2
            antialiasing:   true
            visible:        control.progressBorder

            property real w:         width
            property real h:         height
            property real r:         Math.max(0, control.backRadius - control.borderWidth / 2)
            property real strokeW:   Math.max(2, control.borderWidth + 2)   // 정적 테두리보다 두껍게
            property real perimeter: 2 * Math.max(0, w - 2 * r)
                                     + 2 * Math.max(0, h - 2 * r)
                                     + 2 * Math.PI * r

            // 진행 호 — 상단 중앙에서 시작해 시계방향으로 progress 만큼 그려짐
            ShapePath {
                strokeWidth:    progressShape.strokeW
                strokeColor:    control.progress > 0 ? control.borderColor : "transparent"
                fillColor:      "transparent"
                strokeStyle:    ShapePath.DashLine
                capStyle:       ShapePath.FlatCap
                joinStyle:      ShapePath.RoundJoin

                startX: progressShape.w / 2
                startY: 0
                PathLine { x: progressShape.w - progressShape.r; y: 0 }
                PathArc  { x: progressShape.w; y: progressShape.r; radiusX: progressShape.r; radiusY: progressShape.r; direction: PathArc.Clockwise }
                PathLine { x: progressShape.w; y: progressShape.h - progressShape.r }
                PathArc  { x: progressShape.w - progressShape.r; y: progressShape.h; radiusX: progressShape.r; radiusY: progressShape.r; direction: PathArc.Clockwise }
                PathLine { x: progressShape.r; y: progressShape.h }
                PathArc  { x: 0; y: progressShape.h - progressShape.r; radiusX: progressShape.r; radiusY: progressShape.r; direction: PathArc.Clockwise }
                PathLine { x: 0; y: progressShape.r }
                PathArc  { x: progressShape.r; y: 0; radiusX: progressShape.r; radiusY: progressShape.r; direction: PathArc.Clockwise }
                PathLine { x: progressShape.w / 2; y: 0 }

                dashPattern: [
                    (progressShape.perimeter * control.progress) / progressShape.strokeW,
                    progressShape.perimeter / progressShape.strokeW
                ]
            }
        }

        QGCLabel {
            id:                         helpText
            text:                       qsTr("Hold to Confirm")
            anchors.bottom:             parent.bottom
            anchors.horizontalCenter:   parent.horizontalCenter
            font.pointSize:             ScreenTools.smallFontPointSize
            color:                      control._showHighlight ? qgcPal.buttonHighlightText : qgcPal.buttonText
            visible:                    control._showHelp
        }
    }

    contentItem: QGCLabel {
        id:                     text
        horizontalAlignment:    Text.AlignHCenter
        text:                   control.text
        font.pointSize:         control.pointSize
        font.family:            control.font.family
        font.weight:            control.fontWeight
        color:                  control._showHighlight ? qgcPal.buttonHighlightText : qgcPal.buttonText
    }
}
