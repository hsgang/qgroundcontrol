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
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls

Rectangle {
    id:     _root
    width:  parent.width
    height: ScreenTools.toolbarHeight
    color:  qgcPal.toolbarBackground

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false
    property color  _mainStatusBGColor: qgcPal.brandingPurple

    QGCPalette { id: qgcPal }

    /// Bottom single pixel divider
    Rectangle {
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        height:         1
        color:          "black"
        visible:        qgcPal.globalTheme === QGCPalette.Light
    }

    RowLayout {
        id:                     viewButtonRow
        anchors.bottomMargin:   1
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        spacing:                ScreenTools.defaultFontPixelWidth

        Rectangle {
            id:                     currentButton
            Layout.leftMargin:      ScreenTools.defaultFontPixelWidth / 2
            height:                 viewButtonRow.height * 0.7
            width:                  height
            color:                  "transparent"
            border.color:           qgcPal.text
            border.width:           1
            radius:                 ScreenTools.defaultFontPixelHeight / 4

            QGCToolBarButton {
                anchors.horizontalCenter:   parent.horizontalCenter
                anchors.verticalCenter:     parent.verticalCenter
                icon.source:            "/qmlimages/Hamburger.svg"
                logo:                   true
                onClicked:
                    // if(viewSelectDrawer.visible === false){
                    //     viewSelectDrawer.visible = true
                    // }
                    // else if(viewSelectDrawer.visible === true){
                    //     viewSelectDrawer.visible = false
                    // }
                    viewSelectDrawer.open()
            }
        }

        Rectangle{
            id:                     linkManagerButton
            height:                 viewButtonRow.height * 0.7
            width:                  height
            color:                  "transparent"
            radius:                 ScreenTools.defaultFontPixelHeight / 4
            border.color:           !_activeVehicle ? qgcPal.brandingBlue : qgcPal.colorGreen
            border.width:           1
            visible:                !ScreenTools.isMobile/* && currentToolbar === flyViewToolbar*/

            QGCColoredImage{
                height:             parent.height * 0.7
                width:              height
                anchors.margins:    ScreenTools.defaultFontPixelHeight * 0.2
                anchors.fill:       parent
                source:             "/InstrumentValueIcons/link.svg"
                sourceSize.height:  height
                fillMode:           Image.PreserveAspectFit
                color:              !_activeVehicle ? qgcPal.brandingBlue : qgcPal.colorGreen
            }

            MouseArea{
                anchors.fill:       parent
                onClicked:          linkManagerDialogComponent.createObject(mainWindow).open()
            }
        }

        MainStatusIndicator {
            height:                 viewButtonRow.height * 0.7
        }

        QGCButton {
            id:                 disconnectButton
            text:               qsTr("Disconnect")
            onClicked:          _activeVehicle.closeVehicle()
            visible:            _activeVehicle && _communicationLost
        }

        RowLayout {
            // anchors.top:        parent.top
            // anchors.bottom:     parent.bottom
            // anchors.margins:    ScreenTools.defaultFontPixelHeight * 0.66
            spacing:            ScreenTools.defaultFontPixelHeight * 0.5

            property var  _activeVehicle:           QGroundControl.multiVehicleManager.activeVehicle

            Repeater {
                model: _activeVehicle ? _activeVehicle.modeIndicators : []
                Loader {
                    //anchors.verticalCenter: parent.verticalCenter
                    source:             modelData
                    visible:            item.showIndicator
                }
            }
        }

        Rectangle {
            id:                 flightModeIndicatorRect
            width:              ScreenTools.defaultFontPixelHeight * 8
            height:             viewButtonRow.height * 0.7
            color:              "transparent"
            radius:             ScreenTools.defaultFontPixelHeight / 4
            visible:            _activeVehicle

            Loader{
                id:             flightModeIndicatorLoader
                anchors.top:    parent.top
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                source:         { _activeVehicle
                                    ? (_activeVehicle.apmFirmware
                                       ? "qrc:/qml/QGroundControl/Toolbar/APMFlightModeIndicator.qml"
                                       : "qrc:/PX4/Indicators/PX4FlightModeIndicator.qml")
                                  : "qrc:/qml/QGroundControl/Controls/FlightModeIndicator.qml" }
                width:              parent.width
            }
        }
    }

    Rectangle {
        id: webrtcIndicatorRect
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.bottomMargin:   1
        // anchors.left:           viewButtonRow.right
        // anchors.leftMargin:     ScreenTools.defaultFontPixelWidth
        anchors.right:          vehicleStatusRect.left
        anchors.rightMargin:    ScreenTools.defaultFontPixelWidth
        width:                  childrenRect.width
        color:                  "transparent"
        visible:                QGroundControl.linkManager.webRtcLinkExists

        WEBRTCIndicator{
            anchors.margins: ScreenTools.defaultFontPixelHeight * 0.66
        }
    }

    Rectangle {
        id:                     vehicleStatusRect
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.bottomMargin:   1
        // anchors.left:           webrtcIndicatorRect.right
        // anchors.leftMargin:     ScreenTools.defaultFontPixelWidth
        width:                  statusIndicatorLoader.width
        anchors.right:          widgetControlButton.left
        anchors.rightMargin:    ScreenTools.defaultFontPixelWidth
        color:                  "transparent"

        Loader {
            id:                 statusIndicatorLoader
            //anchors.left:       parent.left
            anchors.right:      parent.right
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            source:             "qrc:/qml/QGroundControl/Controls/FlyViewToolBarIndicators.qml"
        }
    }

    Rectangle {
        id:                     widgetControlButton
        anchors.right:          !ScreenTools.isMobile ? brandImageRect.left : parent.right
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.margins:        ScreenTools.defaultFontPixelHeight * 0.5
        height:                 parent.height - ScreenTools.defaultFontPixelHeight
        width:                  height
        color:                  "transparent"
        radius:                 ScreenTools.defaultFontPixelHeight * 0.2

        QGCColoredImage{
            height:             parent.height * 0.7
            width:              height
            anchors.margins:    ScreenTools.defaultFontPixelHeight * 0.2
            anchors.fill:       parent
            source:             "/InstrumentValueIcons/navigation-more.svg"
            sourceSize.height:  height
            fillMode:           Image.PreserveAspectFit
            color:              qgcPal.text
        }

        MouseArea{
            anchors.fill:       parent
            onClicked:          mainWindow.showIndicatorDrawer(widgetControlComponent, widgetControlButton)
        }
    }

    //-------------------------------------------------------------------------
    //-- Branding Logo

    Rectangle {
        id: brandImageRect
        anchors.right:          parent.right
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.margins:        ScreenTools.defaultFontPixelHeight / 2
        visible:                !ScreenTools.isMobile /*&& currentToolbar !== planViewToolbar && x > (toolsFlickable.x + toolsFlickable.contentWidth + ScreenTools.defaultFontPixelWidth) */
        color:                  "transparent"
        border.color:           qgcPal.text
        border.width:           1
        width:                  ScreenTools.defaultFontPixelHeight * 6
        radius:                 ScreenTools.defaultFontPixelHeight / 4

        Image {
            id:                     brandImage
            anchors.fill:           parent
            anchors.margins:        ScreenTools.defaultFontPixelHeight / 4
            // anchors.right:          parent.right
            // anchors.top:            parent.top
            // anchors.bottom:         parent.bottom
            // anchors.margins:        ScreenTools.defaultFontPixelHeight * 0.66
            // visible:                !ScreenTools.isMobile && currentToolbar !== planViewToolbar && x > (toolsFlickable.x + toolsFlickable.contentWidth + ScreenTools.defaultFontPixelWidth)
            fillMode:               Image.PreserveAspectFit
            source:                 _outdoorPalette ? _brandImageOutdoor : _brandImageIndoor
            sourceSize.width: 256
            sourceSize.height: 256
            mipmap:                 true

            property bool   _outdoorPalette:        qgcPal.globalTheme === QGCPalette.Light
            property bool   _corePluginBranding:    QGroundControl.corePlugin.brandImageIndoor.length != 0
            property string _userBrandImageIndoor:  QGroundControl.settingsManager.brandImageSettings.userBrandImageIndoor.value
            property string _userBrandImageOutdoor: QGroundControl.settingsManager.brandImageSettings.userBrandImageOutdoor.value
            property bool   _userBrandingIndoor:    _userBrandImageIndoor.length != 0
            property bool   _userBrandingOutdoor:   _userBrandImageOutdoor.length != 0
            property string _brandImageIndoor:      brandImageIndoor()
            property string _brandImageOutdoor:     brandImageOutdoor()

            function brandImageIndoor() {
               if (_userBrandingIndoor) {
                   return _userBrandImageIndoor
               } else {
                   if (_userBrandingOutdoor) {
                       return _userBrandingOutdoor
                   } else {
                       if (_corePluginBranding) {
                           return "/qmlimages/amp_logo_white.png" //QGroundControl.corePlugin.brandImageIndoor
                       } else {
                           return "/qmlimages/amp_logo_white.png" //_activeVehicle ? _activeVehicle.brandImageIndoor : ""
                       }
                   }
               }
            }

            function brandImageOutdoor() {
               if (_userBrandingOutdoor) {
                   return _userBrandingOutdoor
               } else {
                   if (_userBrandingIndoor) {
                       return _userBrandingIndoor
                   } else {
                       if (_corePluginBranding) {
                           return "/qmlimages/amp_logo_blue.png" //QGroundControl.corePlugin.brandImageOutdoor
                       } else {
                           return "/qmlimages/amp_logo_blue.png" //_activeVehicle ? _activeVehicle.brandImageOutdoor : ""
                       }
                   }
               }
            }
        }
    }

    Component{
        id: linkManagerDialogComponent

        QGCPopupDialog {
            id:         linkPopup
            title :     qsTr("Link Management")
            buttons:    Dialog.Close

            property var    _currentSelection:     null

            // TimedProgressTracker {
            //     id:                     closeProgressTracker
            //     timeoutSeconds:         10
            //     onTimeout:              linkPopup.close()
            // }

            Rectangle {
                id: _linkRoot
                color: qgcPal.window
                width:  contentsColumnLayout.width
                height: contentsColumnLayout.height
                anchors.margins: ScreenTools.defaultFontPixelWidth
                radius: ScreenTools.defaultFontPixelHeight / 2

                ColumnLayout {
                    id: contentsColumnLayout
                    width:      ScreenTools.defaultFontPixelWidth * 40
                    spacing:    ScreenTools.defaultFontPixelHeight / 2

                    // QGCLabel {
                    //     id:   closeProgressLabel
                    //     visible:            closeProgressTracker.running && closeProgressTracker.progressLabel
                    //     Layout.fillWidth:   true
                    //     horizontalAlignment: Text.AlignRight
                    //     text: qsTr("Automatically close in %1 seconds").arg(closeProgressTracker.progressLabel)

                    //     MouseArea {
                    //         anchors.fill: parent
                    //         onClicked: {
                    //             if (closeProgressTracker.running) {
                    //                 closeProgressTracker.stop()
                    //             }
                    //         }
                    //     }
                    // }

                    Rectangle {
                        id: flickableRect
                        Layout.fillWidth:   true
                        height:             ScreenTools.defaultFontPixelHeight * 16
                        color:              "transparent"
                        radius:             ScreenTools.defaultFontPixelHeight / 2
                        border.color:       qgcPal.groupBorder

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
                                    delegate: SettingsButton {
                                        anchors.horizontalCenter:   settingsColumn.horizontalCenter
                                        width:                      ScreenTools.defaultFontPixelWidth * 34
                                        icon.source:                "/InstrumentValueIcons/link.svg"
                                        icon.color:                 object.link ? qgcPal.colorGreen : qgcPal.text
                                        text:                       object.name
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

                    QGCLabel {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        text: _currentSelection && (_currentSelection.linkType === 3) ? QGroundControl.linkManager.rtcStatusMessage : ""
                        font.pointSize: ScreenTools.smallFontPointSize
                    }

                    Row {
                        id:                 buttonRow
                        spacing:            ScreenTools.defaultFontPixelWidth
                        Layout.alignment:   Qt.AlignHCenter

                        QGCButton {
                            implicitWidth: ScreenTools.defaultFontPixelWidth * 12
                            text:       qsTr("Connect")
                            font.bold:  true
                            enabled:    _currentSelection && !_currentSelection.link
                            onClicked:  {
                                QGroundControl.linkManager.createConnectedLink(_currentSelection)
                                // if (_currentSelection && _currentSelection.link) {
                                //     closeProgressTracker.start()
                                // }
                            }
                        }

                        QGCButton {
                            implicitWidth: ScreenTools.defaultFontPixelWidth * 12
                            text:       qsTr("Disconnect")
                            font.bold:  true
                            enabled:    _currentSelection && _currentSelection.link
                            onClicked:  {
                                _currentSelection.link.disconnect()
                                _currentSelection.linkChanged()
                                // if (closeProgressTracker.running) {
                                //     closeProgressTracker.stop()
                                // }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: widgetControlComponent

        WidgetControlPanel {
        }
    }

    ParameterDownloadProgress {
        anchors.fill: parent
    }
}
