import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

//-------------------------------------------------------------------------
//-- Message Indicator
Item {
    id:             control
    width:          messageIconRow.width //height * 1.4
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool   showIndicator: true

    property var    qgcPal: QGroundControl.globalPalette

    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property bool   _isMessageImportant:    _activeVehicle ? !_activeVehicle.messageTypeNormal && !_activeVehicle.messageTypeNone : false
    property real   _messageTextLength:     0
    property int    unreadMessageCount: 0

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
            height:             parent.height * 0.9
            width:              height
            anchors.verticalCenter:   parent.verticalCenter
            sourceSize.height:  height
            source:             "/InstrumentValueIcons/notifications-outline.svg"
            fillMode:           Image.PreserveAspectFit
            color:              getMessageColor()

            Rectangle {
                color:          qgcPal.window
                height:         ScreenTools.defaultFontPixelHeight * 0.9
                width:          messageTextLengthLabel.width + (ScreenTools.defaultFontPixelHeight * 0.6)
                border.color:   qgcPal.text
                radius:         height / 3
                anchors.top:    parent.top
                anchors.right:  parent.right
                visible:        unreadMessageCount > 0

                QGCLabel {
                    id:     messageTextLengthLabel
                    text:   unreadMessageCount > 99 ? "99+" : unreadMessageCount
                    font.pointSize: ScreenTools.smallFontPointSize
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill:   parent
                onClicked:      mainWindow.showIndicatorDrawer(vehicleMessagesPopup, control)
            }
        }
    }

    // function countUnreadMessages() {
    //         var count = 0;
    //         for (var i = 0; i < messageModel.count; i++) {
    //             if (!messageModel.get(i).checked) {
    //                 count++;
    //             }
    //         }
    //         return count;
    //     }

    // function updateUnreadMessageCount() {
    //     unreadMessageCount = countUnreadMessages();
    // }

    // function parseMessage(message) {
    //     //var regex = /<font style="<#[EIN]>">\[(\d{2}:\d{2}:\d{2}\.\d{3})\s*\]\s*(.*?)<\/font>/;
    //     //var regex = /<font style="<#[A-Z]+>">\[(\d{2}:\d{2}:\d{2}\.\d{3})(?:\s+[A-Z]+:\d+)?\]\s*(.*?)<\/font>/;
    //     var regex = /<font style="<#([A-Z]+)>">\[(\d{2}:\d{2}:\d{2}\.\d{3})\s+[A-Z]+:(\d+)\]\s*(.*?)<\/font>/;

    //     var match = message.match(regex);
    //     if (match) {
    //         var type = match[1];
    //         var time = match[2];
    //         var component = match[3];
    //         var content = match[4];
    //         content = content.replace(/<[^>]*>/g, ''); // HTML 태그 제거
    //         messageModel.insert(0, {"message": content, "time": time, "type": type, "component": component, "checked": false});
    //         updateUnreadMessageCount();
    //         // console.log(message);
    //         // console.log(type);
    //         // console.log(time);
    //         // console.log(component);
    //         // console.log(content);
    //     } else { // 매칭되지 않을 경우 전체 메시지를 content로 반환
    //         time = "";
    //         content = message.replace(/<[^>]*>/g, ''); // HTML 태그 제거
    //         console.log(message);
    //     }
    // }

    // Connections {
    //     target:                _activeVehicle
    //     onNewFormattedMessage: function(formattedMessage) {
    //         parseMessage(formattedMessage)
    //     }
    // }

    // ListModel {
    //     id: messageModel

    //     onCountChanged: {
    //         updateUnreadMessageCount()
    //     }
    // }

    Component {
        id: vehicleMessagesPopup

        ToolIndicatorPage {
            id:             toolIndicatorPage
            showExpand:     false

            // Component.onDestruction: {
            //     for (var i = 0; i < messageModel.count; i++) {
            //         messageModel.setProperty(i, "checked", true)
            //     }
            //     updateUnreadMessageCount()
            // }

            contentComponent: Component {
                SettingsGroupLayout {
                    //Layout.fillWidth:   true
                    heading:            qsTr("Vehicle Messages")
                    visible:            !vehicleMessageList.noMessages

                    VehicleMessageList {
                        id: vehicleMessageList
                    }
                }
            }
        }

        // ToolIndicatorPage {
        //     id:             toolIndicatorPage
        //     showExpand:     false

        //     Component.onDestruction: {
        //         for (var i = 0; i < messageModel.count; i++) {
        //             messageModel.setProperty(i, "checked", true)
        //         }
        //         updateUnreadMessageCount()
        //     }

        //     contentComponent: Component {
        //         QGCListView {
        //             id: messageListView

        //             width:                      ScreenTools.defaultFontPixelWidth * 60
        //             height:                     toolIndicatorPage.childrenRect.height //ScreenTools.defaultFontPixelHeight * 20
        //             verticalLayoutDirection:    ListView.TopToBottom
        //             spacing:                    ScreenTools.defaultFontPixelWidth

        //             model: messageModel
        //             delegate: messageDelegate

        //             Component {
        //                 id: messageDelegate
        //                 Item {
        //                     width:  messageListView.width
        //                     height: childrenRect.height
        //                     Column {
        //                         QGCLabel{
        //                             text:       "[" + model.time + "] - COMP" + model.component
        //                             opacity:    0.6
        //                             font.pointSize: ScreenTools.smallFontPointSize
        //                         }
        //                         QGCLabel {
        //                             width:      messageListView.width - ScreenTools.defaultFontPixelHeight
        //                             text:       model.message
        //                             opacity:    model.checked ? 0.6 : 1
        //                             textFormat: Text.PlainText
        //                             wrapMode:   Text.Wrap
        //                             color:      model.type !== "N" ? qgcPal.colorRed : qgcPal.text
        //                         }
        //                     }
        //                 }
        //             }

        //             Rectangle {
        //                 anchors.right:  parent.right
        //                 anchors.top:    parent.top
        //                 width:          ScreenTools.defaultFontPixelHeight * 2
        //                 height:         width
        //                 radius:         width / 4
        //                 color:          QGroundControl.globalPalette.windowShadeDark
        //                 border.color:   QGroundControl.globalPalette.text
        //                 border.width:   1
        //                 visible:        messageModel.count > 0

        //                 QGCColoredImage {
        //                     anchors.margins:    ScreenTools.defaultFontPixelHeight * 0.25
        //                     anchors.centerIn:   parent
        //                     anchors.fill:       parent
        //                     sourceSize.height:  height
        //                     source:             "/res/TrashDelete.svg"
        //                     fillMode:           Image.PreserveAspectFit
        //                     mipmap:             true
        //                     smooth:             true
        //                     color:              qgcPal.text
        //                 }

        //                 QGCMouseArea {
        //                     fillItem: parent
        //                     onClicked: {
        //                         _activeVehicle.clearMessages()
        //                         messageModel.clear()
        //                         updateUnreadMessageCount()
        //                         componentDrawer.visible = false
        //                     }
        //                 }
        //             }
        //         }
        //     }
        // }
    }
}
