/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.Controllers
import QGroundControl.ScreenTools
import QGroundControl.FlightDisplay

Rectangle {
    id:     _root
    color:  qgcPal.window
    z:      QGroundControl.zOrderTopMost

    signal popout()

    readonly property real _defaultTextHeight:  ScreenTools.defaultFontPixelHeight
    readonly property real _defaultTextWidth:   ScreenTools.defaultFontPixelWidth
    readonly property real _horizontalMargin:   ScreenTools.defaultFontPixelHeight / 2
    readonly property real _verticalMargin:     ScreenTools.defaultFontPixelHeight / 2
    readonly property real _buttonHeight:       ScreenTools.isTinyScreen ? ScreenTools.defaultFontPixelHeight * 3 : ScreenTools.defaultFontPixelHeight * 2

    GeoTagController {
        id: geoController
    }

    FlyViewToolBar {
        id:         toolbar
        visible:    !QGroundControl.videoManager.fullScreen
    }

    Item {
        id: analyzeviewHolder
        anchors.top:    toolbar.bottom
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right

        QGCFlickable {
            id:                 buttonScroll
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
                    model:  QGroundControl.corePlugin ? QGroundControl.corePlugin.analyzePages : []

                    Component.onCompleted:  itemAt(0).checked = true

                    SettingsButton {
                        Layout.fillWidth:   true
                        text:               modelData.title
                        icon.source:        modelData.icon

                        onClicked: {
                            panelLoader.source  = modelData.url
                            panelLoader.title   = modelData.title
                            checked             = true
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
            anchors.left:           buttonScroll.right
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            width:                  1
            color:                  qgcPal.windowShade
        }

        Loader {
            id:                     panelLoader
            anchors.topMargin:      _verticalMargin
            anchors.bottomMargin:   _verticalMargin
            anchors.leftMargin:     _horizontalMargin
            anchors.rightMargin:    _horizontalMargin
            anchors.left:           divider.right
            anchors.right:          parent.right
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            source:                 "LogDownloadPage.qml"

            property string title

            Connections {
                target:     panelLoader.item
                onPopout:   mainWindow.createrWindowedAnalyzePage(panelLoader.title, panelLoader.source)
            }
        }
    }
}
