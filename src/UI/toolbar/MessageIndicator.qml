import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

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
            height:             parent.height * 0.8
            width:              height
            anchors.verticalCenter:   parent.verticalCenter
            sourceSize.height:  height
            source:             "/InstrumentValueIcons/notifications-outline.svg"
            fillMode:           Image.PreserveAspectFit
            mipmap:             true
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

    Component {
        id: vehicleMessagesPopup

        ToolIndicatorPage {
            id:             toolIndicatorPage
            showExpand:     false

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
    }
}
