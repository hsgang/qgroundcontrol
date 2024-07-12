import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl.Palette
import QGroundControl.ScreenTools

/// Standard push button control:
///     If there is both an icon and text the icon will be to the left of the text
///     If icon only, icon will be centered
Button {
    id:             control
    hoverEnabled:   !ScreenTools.isMobile
    topPadding:     _verticalPadding
    bottomPadding:  _verticalPadding
    leftPadding:    _horizontalPadding
    rightPadding:   _horizontalPadding
    focusPolicy:    Qt.ClickFocus
    font.family:    ScreenTools.normalFontFamily
    font.pointSize: ScreenTools.defaultFontPointSize
    text:           ""

    property bool   primary:        false                               ///< primary button for a group of buttons
    property real   pointSize:      ScreenTools.defaultFontPointSize    ///< Point size for button text
    property bool   showBorder:     qgcPal.globalTheme === QGCPalette.Light
    property bool   iconLeft:       false
    property real   backRadius:     ScreenTools.buttonBorderRadius
    property real   heightFactor:   0.5
    property real   fontWeight:     Font.Normal
    property string iconSource:     ""

    property alias wrapMode:            text.wrapMode
    property alias horizontalAlignment: text.horizontalAlignment

    property bool   _showHighlight:     enabled && (pressed | hovered | checked)

    property int _horizontalPadding:    ScreenTools.defaultFontPixelWidth
    property int _verticalPadding:      Math.round(ScreenTools.defaultFontPixelHeight * heightFactor)

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    background: Rectangle {
        id:             backRect
        radius:         backRadius
        implicitWidth:  ScreenTools.implicitButtonWidth
        implicitHeight: ScreenTools.implicitButtonHeight
        border.width:   showBorder ? 1 : 0
        border.color:   qgcPal.groupBorder
        color:          _showHighlight ?
                            qgcPal.windowShadeLight :
                            (primary ? qgcPal.windowShadeLight : qgcPal.windowShade)
    }

    contentItem: RowLayout {
            spacing: ScreenTools.defaultFontPixelWidth

            QGCColoredImage {
                id:                     icon
                Layout.alignment:       Qt.AlignHCenter
                source:                 control.iconSource
                height:                 text.height
                width:                  height
                color:                  text.color
                fillMode:               Image.PreserveAspectFit
                sourceSize.height:      height
                visible:                control.iconSource !== ""
            }

            QGCLabel {
                id:                     text
                Layout.alignment:       Qt.AlignHCenter
                text:                   control.text
                font.pointSize:         control.font.pointSize
                font.family:            control.font.family
                font.weight:            fontWeight
                color:                  _showHighlight ? qgcPal.buttonHighlightText : (primary ? qgcPal.primaryButtonText : qgcPal.buttonText)
                visible:                control.text !== "" 
            }
    }
}
