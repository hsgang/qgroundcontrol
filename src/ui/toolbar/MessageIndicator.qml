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
import QGroundControl.FactSystem
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Palette

//-------------------------------------------------------------------------
//-- Message Indicator
Item {
    id:             control
    width:          messageIconRow.width //height * 1.4
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator: true

    property var qgcPal: QGroundControl.globalPalette

    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property bool   _isMessageImportant:    _activeVehicle ? !_activeVehicle.messageTypeNormal && !_activeVehicle.messageTypeNone : false

    function dropMessageIndicator() {
        mainWindow.showIndicatorDrawer(drawerComponent, control)
    }

    function getMessageColor() {
        if (_activeVehicle) {
            if (_activeVehicle.messageTypeNone)
                return qgcPal.text //qgcPal.colorGrey
            if (_activeVehicle.messageTypeNormal)
                return qgcPal.text //alertBackground;
            if (_activeVehicle.messageTypeWarning)
                return qgcPal.alertBackground //colorOrange;
            if (_activeVehicle.messageTypeError)
                return qgcPal.colorRed
            // Cannot be so make make it obnoxious to show error
            console.warn("MessageIndicator.qml:getMessageColor Invalid vehicle message type", _activeVehicle.messageTypeNone)
            return "purple";
        }
        //-- It can only get here when closing (vehicle gone while window active)
        return qgcPal.colorGrey
    }

    Row {
        id:             messageIconRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        spacing:        ScreenTools.defaultFontPixelWidth/2

        QGCColoredImage {
            height:             parent.height * 0.8
            width:              height
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            source:             "/InstrumentValueIcons/notifications-outline.svg"
            sourceSize.height:  height * 0.7
            fillMode:           Image.PreserveAspectFit
            color:              getMessageColor()
            visible:            _activeVehicle //!criticalMessageIcon.visible
//            opacity:            _noMessages ? 0.5 : 1

            MouseArea {
                anchors.fill:   parent
                onClicked:      mainWindow.showIndicatorDrawer(vehicleMessagesPopup)
            }
        }
    }

    Component {
        id: vehicleMessagesPopup

        ToolIndicatorPage {
            showExpand:         false

            function formatMessage(message) {
                message = message.replace(new RegExp("<#E>", "g"), "color: " + qgcPal.warningText + "; font: " + (ScreenTools.defaultFontPointSize.toFixed(0)) + "pt monospace;");
                message = message.replace(new RegExp("<#I>", "g"), "color: " + qgcPal.warningText + "; font: " + (ScreenTools.defaultFontPointSize.toFixed(0)) + "pt monospace;");
                message = message.replace(new RegExp("<#N>", "g"), "color: " + qgcPal.text + "; font: " + (ScreenTools.defaultFontPointSize.toFixed(0)) + "pt monospace;");
                return message;
            }

            contentComponent: Component {
                TextArea {
                    id:                     messageText
                    width:                  Math.max(ScreenTools.defaultFontPixelWidth * 30, contentWidth + ScreenTools.defaultFontPixelWidth)
                    height:                 Math.max(ScreenTools.defaultFontPixelHeight * 3, contentHeight)
                    readOnly:               true
                    textFormat:             TextEdit.RichText
                    color:                  qgcPal.text
                    placeholderText:        qsTr("No Messages")
                    placeholderTextColor:   qgcPal.text
                    padding:                0

                    property bool _noMessages: messageText.length === 0

                    Connections {
                        target:                 _activeVehicle
                        onNewFormattedMessage:  {
                            messageText.append(formatMessage(formattedMessage))
                        }
                    }

                    Component.onCompleted: {
                        messageText.text = formatMessage(_activeVehicle.formattedMessages)
                        _activeVehicle.resetAllMessages()
                    }

                    Rectangle {
                        anchors.right:              parent.right
                        anchors.bottom:             parent.bottom
                        width:                      ScreenTools.defaultFontPixelHeight * 2
                        height:                     width
                        radius:                     width / 4
                        color:                      QGroundControl.globalPalette.windowShadeDark
                        border.color:               QGroundControl.globalPalette.text
                        visible:                    !_noMessages

                        QGCColoredImage {
                            anchors.margins:    ScreenTools.defaultFontPixelHeight * 0.25
                            anchors.centerIn:   parent
                            anchors.fill:       parent
                            sourceSize.height:  height
                            source:             "/res/TrashDelete.svg"
                            fillMode:           Image.PreserveAspectFit
                            mipmap:             true
                            smooth:             true
                            color:              qgcPal.text
                        }

                        QGCMouseArea {
                            fillItem: parent
                            onClicked: {
                                _activeVehicle.clearMessages()
                                componentDrawer.visible = false
                            }
                        }
                    }
                }
            }
        }
    }
}
