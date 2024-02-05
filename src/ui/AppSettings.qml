/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts  1.2

import QGroundControl               1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0

Rectangle {
    id:     settingsView
    color:  qgcPal.window
    z:      QGroundControl.zOrderTopMost

    ExclusiveGroup { id : setupButtonGroup }

    readonly property real _defaultTextHeight:  ScreenTools.defaultFontPixelHeight
    readonly property real _defaultTextWidth:   ScreenTools.defaultFontPixelWidth
    readonly property real _horizontalMargin:   ScreenTools.defaultFontPixelHeight / 2
    readonly property real _verticalMargin:     ScreenTools.defaultFontPixelHeight / 2
    readonly property real _buttonHeight:       ScreenTools.isTinyScreen ? ScreenTools.defaultFontPixelHeight * 3 : ScreenTools.defaultFontPixelHeight * 2

    property bool _first: true

    property bool _commingFromRIDSettings:  false

    function showSettingsPage(settingsPage) {
        for (var i=0; i<buttonRepeater.count; i++) {
            var button = buttonRepeater.itemAt(i)
            if (button.text === settingsPage) {
                button.clicked()
                break
            }
        }
    }

    QGCPalette { id: qgcPal }

    Component.onCompleted: {
        //-- Default Settings
        if (globals.commingFromRIDIndicator) {
            rightPanel.source = "qrc:/qml/RemoteIDSettings.qml"
            globals.commingFromRIDIndicator = false
        } else {
            rightPanel.source =  "/qml/GeneralSettings.qml"
        }
    }

    SettingsPagesModel { id: settingsPagesModel }

    QGCFlickable {
        id:                 buttonList
        width:              buttonColumn.width
        anchors.topMargin:  _verticalMargin
        anchors.top:        parent.top
        anchors.bottom:     parent.bottom
        anchors.leftMargin: _horizontalMargin
        anchors.left:       parent.left
        contentHeight:      buttonColumn.height + _verticalMargin
        flickableDirection: Flickable.VerticalFlick
        clip:               true

        Column {
            id:         buttonColumn
            width:      _maxButtonWidth
            spacing:    _verticalMargin

            property real _maxButtonWidth: 0

            Component.onCompleted: reflowWidths()

            // I don't know why this does not work
            Connections {
                target:         QGroundControl.settingsManager.appSettings.appFontPointSize
                onValueChanged: buttonColumn.reflowWidths()
            }

            function reflowWidths() {
                buttonColumn._maxButtonWidth = 0
                for (var i = 0; i < children.length; i++) {
                    buttonColumn._maxButtonWidth = Math.max(buttonColumn._maxButtonWidth, children[i].width)
                }
                for (var j = 0; j < children.length; j++) {
                    children[j].width = buttonColumn._maxButtonWidth
                }
            }

            Repeater {
                id:     buttonRepeater
                model:  settingsPagesModel

                Component.onCompleted:  itemAt(0).checked = true

                SubMenuButton {
                    id:                 subMenu
                    imageResource:      menuIcon
                    setupIndicator:     false
                    exclusiveGroup:      setupButtonGroup
                    // autoExclusive:      true
                    text:               name
                    visible:            url !== "qrc:/qml/RemoteIDSettings.qml" ? true : QGroundControl.settingsManager.remoteIDSettings.enable.rawValue
                    enabled:            _enabled

                    onClicked: {

                        focus = true
                        if (mainWindow.preventViewSwitch()) {
                            return
                        }
                        if (rightPanel.source !== url) {
                            rightPanel.source = url
                        }
                        checked = true
                    }
                }
            }
        }
    }

    Rectangle {
        id:  topDividerBar
        anchors.top:            parent.top
        anchors.right:          parent.right
        anchors.left:           parent.left
        height:                 1
        color:                  Qt.darker(QGroundControl.globalPalette.text, 4)
    }

    Rectangle {
        id:                     divider
        anchors.topMargin:      _verticalMargin
        anchors.bottomMargin:   _verticalMargin
        anchors.leftMargin:     _horizontalMargin
        anchors.left:           buttonList.right
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        width:                  1
        color:                  qgcPal.windowShadeLight
    }

    //-- Panel Contents
    Loader {
        id:                     rightPanel
        anchors.leftMargin:     _horizontalMargin
        anchors.rightMargin:    _horizontalMargin
        anchors.topMargin:      _verticalMargin
        anchors.bottomMargin:   _verticalMargin
        anchors.left:           divider.right
        anchors.right:          parent.right
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
    }
}

