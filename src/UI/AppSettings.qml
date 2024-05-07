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
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.ScreenTools

Rectangle {
    id:     settingsView
    color:  qgcPal.window
    z:      QGroundControl.zOrderTopMost

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
        anchors.topMargin:  _defaultTextHeight / 2
        anchors.top:        parent.top
        anchors.bottom:     parent.bottom
        anchors.leftMargin: _horizontalMargin
        anchors.left:       parent.left
        contentHeight:      buttonColumn.height
        flickableDirection: Flickable.VerticalFlick
        clip:               true

        // Column {
        //     id:         buttonColumn
        //     width:      _maxButtonWidth
        //     spacing:    _verticalMargin

        //     property real _maxButtonWidth: 0

        //     Component.onCompleted: reflowWidths()

        //     // I don't know why this does not work
        //     Connections {
        //         target:         QGroundControl.settingsManager.appSettings.appFontPointSize
        //         onValueChanged: buttonColumn.reflowWidths()
        //     }

        //     function reflowWidths() {
        //         buttonColumn._maxButtonWidth = 0
        //         for (var i = 0; i < children.length; i++) {
        //             buttonColumn._maxButtonWidth = Math.max(buttonColumn._maxButtonWidth, children[i].width)
        //         }
        //         for (var j = 0; j < children.length; j++) {
        //             children[j].width = buttonColumn._maxButtonWidth
        //         }
        //     }
        ColumnLayout {
            id:         buttonColumn
            spacing:    _defaultTextHeight / 2

            Repeater {
                id:     buttonRepeater
                model:  settingsPagesModel

                Component.onCompleted:  itemAt(0).checked = true

                SubMenuButton {
                    id:                 subMenu
                    imageResource:      iconUrl
                    setupIndicator:     false
                    autoExclusive:      true
                    text:               name
                    visible:            url !== "qrc:/qml/RemoteIDSettings.qml" ? true : QGroundControl.settingsManager.remoteIDSettings.enable.rawValue

                    onClicked: {
//                        __rightPanel.source = modelData.url
//                        //__rightPanel.title  = modelData.title
//                        checked             = true

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
//                Button {
//                    padding:            ScreenTools.defaultFontPixelWidth / 2
//                    autoExclusive:      true
//                    Layout.fillWidth:   true
//                    visible:            pageVisible()

//                    background: Rectangle {
//                        color:  checked ? qgcPal.buttonHighlight : "transparent"
//                        radius: ScreenTools.defaultFontPixelWidth / 2
//                    }

//                    contentItem: QGCLabel {
//                        text:   name
//                        color:  checked ? qgcPal.buttonHighlightText : qgcPal.buttonText
//                    }

//                    onClicked: {
//                        focus = true
//                        if (mainWindow.preventViewSwitch()) {
//                            return
//                        }
//                        if (rightPanel.source !== url) {
//                            rightPanel.source = url
//                        }
//                        checked = true
//                    }

//                    Component.onCompleted: {
//                        if (globals.commingFromRIDIndicator) {
//                            _commingFromRIDSettings = true
//                        }
//                        if(_first) {
//                            _first = false
//                            checked = true
//                        }
//                        if (_commingFromRIDSettings) {
//                            checked = false
//                            _commingFromRIDSettings = false
//                            if (modelData.url == "/qml/RemoteIDSettings.qml") {
//                                checked = true
//                            }
//                        }
//                    }
//                }
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

