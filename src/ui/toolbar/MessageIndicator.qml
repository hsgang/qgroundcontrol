/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick          2.3
import QtQuick.Controls 2.5
import QtQuick.Layouts  1.2

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0

//-------------------------------------------------------------------------
//-- Message Indicator
Item {
    id:             _root
    width:          messageIconRow.width //height * 1.4
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator: true

    property var qgcPal: QGroundControl.globalPalette

    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property bool   _isMessageImportant:    _activeVehicle ? !_activeVehicle.messageTypeNormal && !_activeVehicle.messageTypeNone : false

    function getMessageColor() {
        if (_activeVehicle) {
            if (_activeVehicle.messageTypeNone)
                return qgcPal.text //qgcPal.colorGrey
            if (_activeVehicle.messageTypeNormal)
                return qgcPal.alertBackground;
            if (_activeVehicle.messageTypeWarning)
                return qgcPal.colorOrange;
            if (_activeVehicle.messageTypeError)
                return qgcPal.colorRed;
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

        Rectangle{
            width:              1
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            color:              qgcPal.text
            opacity:            0.5
        }

        QGCColoredImage {
            width:              height
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            source:             "/qmlimages/alarm.svg"
            sourceSize.height:  height * 0.8
            fillMode:           Image.PreserveAspectFit
            color:              getMessageColor()
            visible:            _activeVehicle //!criticalMessageIcon.visible

            MouseArea {
                anchors.fill:   parent
                onClicked:      mainWindow.showIndicatorDrawer(vehicleMessagesPopup)
            }
        }
    }

    Component {
        id: vehicleMessagesPopup

        ToolIndicatorPage {
            showExpand: false

            property bool _noMessages: messageText.length === 0

            function formatMessage(message) {
                message = message.replace(new RegExp("<#E>", "g"), "color: " + qgcPal.warningText + "; font: " + (ScreenTools.defaultFontPointSize.toFixed(0) - 1) + "pt monospace;");
                message = message.replace(new RegExp("<#I>", "g"), "color: " + qgcPal.warningText + "; font: " + (ScreenTools.defaultFontPointSize.toFixed(0) - 1) + "pt monospace;");
                message = message.replace(new RegExp("<#N>", "g"), "color: " + qgcPal.text + "; font: " + (ScreenTools.defaultFontPointSize.toFixed(0) - 1) + "pt monospace;");
                return message;
            }

            Component.onCompleted: {
                messageText.text = formatMessage(_activeVehicle.formattedMessages)
                //-- Hack to scroll to last message
                _activeVehicle.resetMessages()
            }

            Connections {
                target:                 _activeVehicle
                onNewFormattedMessage:  messageText.insert(0, formatMessage(formattedMessage))
            }

            contentItem: TextArea {
                id:                     messageText
                width:                  Math.max(ScreenTools.defaultFontPixelWidth * 30, contentWidth + ScreenTools.defaultFontPixelWidth)
                height:                 Math.max(ScreenTools.defaultFontPixelHeight * 20, contentHeight)
                readOnly:               true
                textFormat:             TextEdit.RichText
                color:                  qgcPal.text
                placeholderText:        qsTr("No Messages")
                placeholderTextColor:   qgcPal.text
                padding:                0

                Rectangle {
                    anchors.right:   parent.right
                    anchors.top:     parent.top
                    width:                      ScreenTools.defaultFontPixelHeight * 1.25
                    height:                     width
                    radius:                     width / 2
                    color:                      QGroundControl.globalPalette.button
                    border.color:               QGroundControl.globalPalette.buttonText
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
                            //indicatorDrawer.close()
                            drawer.close()
                        }
                    }
                }
            }
//            QGCFlickable {
//                id:                 messageFlick
//                anchors.margins:    ScreenTools.defaultFontPixelHeight
//                anchors.fill:       parent
//                contentHeight:      messageText.height
//                contentWidth:       messageText.width
//                pixelAligned:       true

//                TextEdit {
//                    id:                 messageText
//                    readOnly:           true
//                    textFormat:         TextEdit.RichText
//                    selectByMouse:      true
//                    color:              qgcPal.text
//                    selectionColor:     qgcPal.text
//                    selectedTextColor:  qgcPal.window
//                }
//            }
        }
    }
}
