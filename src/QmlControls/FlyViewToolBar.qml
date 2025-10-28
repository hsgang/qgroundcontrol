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
import QGroundControl.Toolbar

Rectangle {
    id:     control
    width:  parent.width
    height: ScreenTools.toolbarHeight
    color:  "transparent"

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false
    property color  _mainStatusBGColor: qgcPal.brandingPurple
    property real   _leftRightMargin:   ScreenTools.defaultFontPixelWidth * 0.75

    QGCPalette { id: qgcPal }

    /// Bottom single pixel divider
    Rectangle {
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        height:         1
        color:          qgcPal.toolbarDivider
    }

    // Rectangle {
    //     id:             gradientBackground
    //     anchors.top:    parent.top
    //     anchors.bottom: parent.bottom
    //     anchors.left:   parent.left
    //     width:          leftStatusLayout.width
    //     opacity:        qgcPal.windowTransparent.a
        
    //     gradient: Gradient {
    //         orientation: Gradient.Horizontal
    //         GradientStop { position: 0; color: _mainStatusBGColor }
    //         //GradientStop { position: qgcButton.x + qgcButton.width; color: _mainStatusBGColor }
    //         GradientStop { position: 1; color: qgcPal.window }
    //     }
    // }

    RowLayout {
        id:                     mainLayout
        anchors.bottomMargin:   1
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.left:           parent.left
        anchors.right:          brandingLogo.visible ? brandingLogo.left : parent.right
        anchors.rightMargin:    ScreenTools.defaultFontPixelWidth
        spacing:                ScreenTools.defaultFontPixelWidth

        RowLayout {
            id:                 leftStatusLayout
            Layout.fillHeight:  true
            Layout.alignment:   Qt.AlignLeft
            spacing:            ScreenTools.defaultFontPixelWidth

            Rectangle{
                id:                     menuNavigationButton
                Layout.leftMargin:      ScreenTools.defaultFontPixelWidth / 2
                height:                 control.height * 0.8
                width:                  height
                color:                  qgcPal.windowTransparent
                radius:                 ScreenTools.defaultFontPixelHeight / 4
                border.color:           qgcPal.windowTransparentText
                border.width:           1

                QGCToolBarButton {
                    anchors.horizontalCenter:   parent.horizontalCenter
                    anchors.verticalCenter:     parent.verticalCenter
                    icon.source:                "/qmlimages/Hamburger.svg"
                    logo:                       true
                    onClicked:                  viewSelectDrawer.visible ? viewSelectDrawer.close() : viewSelectDrawer.open()
                }
            }

            Rectangle{
                id:                     linkManagerButton
                height:                 control.height * 0.8
                width:                  height
                color:                  QGroundControl.globalPalette.windowTransparent
                radius:                 ScreenTools.defaultFontPixelHeight / 4
                border.color:           qgcPal.windowTransparentText
                border.width:           1
                visible:                !ScreenTools.isMobile/* && currentToolbar === flyViewToolbar*/

                QGCColoredImage{
                    height:             parent.height * 0.6
                    width:              height
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    source:             "/InstrumentValueIcons/link.svg"
                    sourceSize.height:  height
                    fillMode:           Image.PreserveAspectFit
                    mipmap:             true
                    color:              qgcPal.windowTransparentText
                }

                MouseArea{
                    anchors.fill:       parent
                    onClicked:          linkManagerDialogComponent.createObject(mainWindow).open()
                }
            }

            MainStatusIndicator {
                id:      mainStatusIndicator
                height:  control.height * 0.8
            }

            Rectangle {
                id: messageIndicator
                Layout.alignment:       Qt.AlignVCenter
                height:                 control.height * 0.8
                Layout.preferredWidth:  childrenRect.width + ScreenTools.defaultFontPixelWidth * 2
                color:                  qgcPal.windowTransparent
                radius:                 ScreenTools.defaultFontPixelHeight / 4
                visible:                _activeVehicle

                MessageIndicator{
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.margins: ScreenTools.defaultFontPixelHeight * 0.3
                }
            }

            QGCButton {
                id:                 disconnectButton
                Layout.alignment:       Qt.AlignVCenter
                text:               qsTr("Disconnect")
                onClicked:          _activeVehicle.closeVehicle()
                visible:            _activeVehicle && _communicationLost
            }

            QGCButton {
                id:                 reconnectButton
                Layout.alignment:       Qt.AlignVCenter
                text:               qsTr("Reconnect")
                onClicked:          {
                    if (_activeVehicle) {
                        var primaryLinkName = _activeVehicle.vehicleLinkManager.primaryLinkName
                        var linkConfigs = QGroundControl.linkManager.linkConfigurations
                        for (var i = 0; i < linkConfigs.count; i++) {
                            var config = linkConfigs.get(i)
                            if (config.name === primaryLinkName) {
                                if (config.link) {
                                    config.link.disconnect()
                                }
                                QGroundControl.linkManager.createConnectedLink(config)
                                break
                            }
                        }
                    }
                }
                visible:            _activeVehicle && _communicationLost
            }
        }

        RowLayout {
            id:                 rightStatusLayout
            Layout.fillHeight:  true
            Layout.alignment:   Qt.AlignRight
            spacing:            ScreenTools.defaultFontPixelWidth

            FlightModeIndicator {
                Layout.fillHeight:      true
                Layout.alignment:       Qt.AlignVCenter
                visible:                _activeVehicle
            }

            Rectangle {
                id: webrtcIndicatorRect
                //Layout.fillHeight:      true
                Layout.alignment:       Qt.AlignVCenter
                height:                 control.height * 0.8
                Layout.preferredWidth:  childrenRect.width + ScreenTools.defaultFontPixelWidth * 2
                color:                  qgcPal.windowTransparent
                radius:                 ScreenTools.defaultFontPixelHeight / 4
                visible:                QGroundControl.linkManager.webRtcLinkExists

                WEBRTCIndicator{
                    anchors.right:   parent.right
                    anchors.margins: ScreenTools.defaultFontPixelHeight * 0.3
                }
            }

            QGCFlickable {
                id:                     indicatorsFlickable
                Layout.alignment:       Qt.AlignRight
                Layout.fillHeight:      true
                Layout.preferredWidth:  Math.min(contentWidth, availableWidth)
                contentWidth:           toolIndicators.width
                flickableDirection:     Flickable.HorizontalFlick

                property real availableWidth: mainLayout.width - leftStatusLayout.width

                FlyViewToolBarIndicators { id: toolIndicators }
            }

            Rectangle {
                id:                     widgetControlButton
                Layout.alignment:       Qt.AlignVCenter
                height:                 control.height * 0.8
                width:                  height
                color:                  qgcPal.windowTransparent
                radius:                 ScreenTools.defaultFontPixelHeight * 0.2

                QGCColoredImage{
                    height:             parent.height * 0.5
                    width:              height
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    source:             "/InstrumentValueIcons/navigation-more.svg"
                    sourceSize.height:  height
                    fillMode:           Image.PreserveAspectFit
                    mipmap:             true
                    color:              qgcPal.windowTransparentText
                }

                MouseArea{
                    anchors.fill:       parent
                    onClicked:          mainWindow.showIndicatorDrawer(widgetControlComponent, widgetControlButton)
                }
            }
        }
    }

    //-------------------------------------------------------------------------
    //-- Branding Logo

    Rectangle {
        id: brandingLogo
        anchors.right:          parent.right
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.margins:        ScreenTools.defaultFontPixelHeight / 2
        visible:                !ScreenTools.isMobile /*&& currentToolbar !== planViewToolbar && x > (toolsFlickable.x + toolsFlickable.contentWidth + ScreenTools.defaultFontPixelWidth) */
        color:                  "transparent"
        border.color:           qgcPal.windowTransparentText
        border.width:           1
        width:                  ScreenTools.defaultFontPixelHeight * 6
        radius:                 ScreenTools.defaultFontPixelHeight / 4

        Image {
            id:                     brandImage
            anchors.fill:           parent
            anchors.margins:        ScreenTools.defaultFontPixelHeight / 4
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
                                        icon.color:                 object.link ? qgcPal.colorGreen : qgcPal.windowTransparentText
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
