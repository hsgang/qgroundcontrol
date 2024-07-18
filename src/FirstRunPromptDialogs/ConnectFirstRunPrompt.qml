/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.SettingsManager
import QGroundControl.Controls

FirstRunPrompt {
    title:      qsTr("Link Management")
    promptId:   QGroundControl.corePlugin.connectFirstRunPromptId
    markAsShownOnClose: false

    property var    _currentSelection:     null

    ColumnLayout {
        id:         linkColumnLayout
        spacing:    ScreenTools.defaultFontPixelHeight

        QGCLabel {
            id:         unitsSectionLabel
            text:       qsTr("Choose the link you want to connect.")

            Layout.preferredWidth: flickableRect.width
            wrapMode: Text.WordWrap
        }

        Rectangle {
            id: flickableRect
            color:              qgcPal.windowShadeDark
            width:              ScreenTools.defaultFontPixelWidth * 40
            height:             ScreenTools.defaultFontPixelHeight * 10
            radius:             ScreenTools.defaultFontPixelHeight / 2

            QGCFlickable {
                clip:               true
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                anchors.margins:    ScreenTools.defaultFontPixelHeight / 4
                anchors.left:       parent.left
                anchors.right:      parent.right
                contentHeight:      settingsColumn.height
                flickableDirection: Flickable.VerticalFlick

                Column {
                    id:                 settingsColumn
                    width:              flickableRect.width
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing:            ScreenTools.defaultFontPixelHeight / 2
                    Repeater {
                        model: QGroundControl.linkManager.linkConfigurations
                        delegate: QGCButton {
                            anchors.horizontalCenter:   settingsColumn.horizontalCenter
                            width:                      ScreenTools.defaultFontPixelWidth * 36
                            text:                       object.name + (object.link ? " (" + qsTr("Connected") + ")" : "")
                            autoExclusive:              true
                            visible:                    !object.dynamic
                            onClicked: {
                                checked = true
                                _currentSelection = object
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            spacing:            ScreenTools.defaultFontPixelWidth
            Layout.fillWidth:   true
            Layout.alignment:   Qt.AlignCenter

            QGCButton {
                text:       qsTr("Connect")
                font.bold: true
                enabled:    _currentSelection && !_currentSelection.link
                onClicked:  {
                    QGroundControl.linkManager.createConnectedLink(_currentSelection)
                    close()
                }
                implicitWidth: ScreenTools.defaultFontPixelWidth * 12
            }
        }
    }
}
