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
import QGroundControl.ScreenTools
import QGroundControl.AppSettings

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
            rightPanel.source = "qrc:/qml/QGroundControl/AppSettings/RemoteIDSettings.qml"
            globals.commingFromRIDIndicator = false
        } else {
            rightPanel.source =  "qrc:/qml/QGroundControl/AppSettings/GeneralSettings.qml"
        }
    }

    SettingsPagesModel { id: settingsPagesModel }

    FlyViewToolBar {
        id:         toolbar
        visible:    !QGroundControl.videoManager.fullScreen
    }

    Item {
        id: appsettingsHolder
        anchors.top:    toolbar.bottom
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right

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

            ColumnLayout {
                id:         buttonColumn
                spacing:    _defaultTextHeight / 2

                Repeater {
                    id:     buttonRepeater
                    model:  settingsPagesModel

                    Component.onCompleted:  itemAt(0).checked = true

                    SettingsButton {
                        Layout.fillWidth:   true
                        text:               name
                        icon.source:        iconUrl
                        visible:            pageVisible()

                        onClicked: {
                            if (mainWindow.allowViewSwitch()) {
                                if (rightPanel.source !== url) {
                                    rightPanel.source = url
                                }
                                checked = true
                            }
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
}

