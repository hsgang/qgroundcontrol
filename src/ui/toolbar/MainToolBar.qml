/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.12
import QtQuick.Controls 2.4
import QtQuick.Layouts  1.11
import QtQuick.Dialogs  1.3

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.Palette               1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Controllers           1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.FactControls          1.0

Rectangle {
    id:     _root
    color:  qgcPal.window //toolbarBackground

    property int currentToolbar: flyViewToolbar

    readonly property int flyViewToolbar:   0
    readonly property int planViewToolbar:  1
    readonly property int simpleToolbar:    2

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false
    property color  _mainStatusBGColor: qgcPal.brandingPurple

    property var    _currentSelection:     null

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

    // Rectangle {
    //     anchors.fill:   mainStatusIndicator //viewButtonRow
    //     visible:        currentToolbar === flyViewToolbar

    //     gradient: Gradient {
    //         orientation: Gradient.Horizontal
    //         GradientStop { position: 0;                                     color: _mainStatusBGColor }
    //         GradientStop { position: currentButton.x + currentButton.width; color: _mainStatusBGColor }
    //         GradientStop { position: 1;                                     color: _root.color }
    //     }
    // }

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
                anchors.centerIn:       parent
                //Layout.preferredHeight: currentButton.height
                icon.source:            "/InstrumentValueIcons/menu.svg" //"/qmlimages/Hamburger.svg"
                logo:                   true
                onClicked:
                    if(viewSelectDrawer.visible === false){
                        viewSelectDrawer.visible = true
                    }
                    else if(viewSelectDrawer.visible === true){
                        viewSelectDrawer.visible = false
                    }
            }
        }

        Rectangle{
            id:                     linkManagerButton
            height:                 viewButtonRow.height * 0.7
            width:                  height
            color:                  "transparent"
            radius:                 ScreenTools.defaultFontPixelHeight / 4
            border.color:           !_activeVehicle ? qgcPal.colorRed : qgcPal.colorGreen
            border.width:           1
            visible:                !ScreenTools.isMobile && currentToolbar === flyViewToolbar

            QGCColoredImage{
                height:             parent.height * 0.7
                width:              height
                anchors.margins:    ScreenTools.defaultFontPixelHeight * 0.2
                anchors.fill:       parent
                source:             "/InstrumentValueIcons/link.svg"
                sourceSize.height:  height
                fillMode:           Image.PreserveAspectFit
                color:              !_activeVehicle ? qgcPal.colorRed : qgcPal.colorGreen
            }

            MouseArea{
                anchors.fill:       parent
                onClicked:          linkManagerDialogComponent.createObject(mainWindow).open()
            }
        }

        MainStatusIndicator {
            //Layout.preferredHeight: viewButtonRow.height
            height:                 viewButtonRow.height * 0.7
            visible:                currentToolbar === flyViewToolbar
        }

        QGCButton {
            id:                 disconnectButton
            text:               qsTr("Disconnect")
            onClicked:          _activeVehicle.closeVehicle()
            visible:            _activeVehicle && _communicationLost && currentToolbar === flyViewToolbar
        }
    }

    Rectangle {
        id:                     vehicleModeIndicatorRect
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.left:           viewButtonRow.right
        anchors.right:          flightModeIndicatorRect.left
        anchors.margins:        ScreenTools.defaultFontPixelHeight * 0.66
        color:                  "transparent"
        visible:                currentToolbar == flyViewToolbar

        Row {
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            anchors.margins:    ScreenTools.defaultFontPixelHeight * 0.66
            spacing:            ScreenTools.defaultFontPixelHeight * 0.5

            property var  _activeVehicle:           QGroundControl.multiVehicleManager.activeVehicle

            Repeater {
                model: _activeVehicle ? _activeVehicle.modeIndicators : []
                Loader {
                    anchors.verticalCenter: parent.verticalCenter
                    source:             modelData
                    visible:            item.showIndicator
                }
            }
        }
    }

    Rectangle {
        id:                     flightModeIndicatorRect
        width:                  ScreenTools.defaultFontPixelHeight * 8
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.margins:        ScreenTools.defaultFontPixelHeight * 0.33
        anchors.horizontalCenter: parent.horizontalCenter
        color:                  qgcPal.windowShadeDark //"transparent"
        border.color:           qgcPal.text
        radius:                 ScreenTools.defaultFontPixelHeight / 4
        visible:                currentToolbar == flyViewToolbar && _activeVehicle

        Loader{
            id:             flightModeIndicatorLoader
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            source:        "qrc:/qml/QGroundControl/Controls/FlightModeMenuIndicator.qml"
            width:              parent.width
        }
    }

//    QGCFlickable {
//        id:                     vehicleStatusFlickable
//        anchors.leftMargin:     ScreenTools.defaultFontPixelWidth * ScreenTools.largeFontPointRatio * 1.5
//        anchors.left:           flightModeIndicatorRect.right
//        anchors.bottomMargin:   1
//        anchors.top:            parent.top
//        anchors.bottom:         parent.bottom
//        anchors.right:          parent.right
//        contentWidth:           statusIndicatorLoader.x + statusIndicatorLoader.width
//        flickableDirection:     Flickable.HorizontalFlick
//        visible:                currentToolbar == flyViewToolbar
    Rectangle {
        id:                     vehicleStatusRect
        visible:                currentToolbar == flyViewToolbar
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.bottomMargin:   1
        anchors.left:           flightModeIndicatorRect.right
        anchors.leftMargin:     ScreenTools.defaultFontPixelWidth
        anchors.right:          widgetControlButton.left
        anchors.rightMargin:    ScreenTools.defaultFontPixelWidth
        color:                  "transparent"

        Loader {
            id:                 statusIndicatorLoader
            //anchors.left:       parent.left
            anchors.right:      parent.right
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            source:             currentToolbar == flyViewToolbar ? "qrc:/toolbar/MainToolBarIndicators.qml" : ""
        }
    }

    QGCFlickable {
        id:                     toolsFlickable
        anchors.leftMargin:     ScreenTools.defaultFontPixelWidth
        anchors.left:           viewButtonRow.right
        anchors.bottomMargin:   1
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.right:          parent.right
        anchors.rightMargin:    ScreenTools.defaultFontPixelWidth
        contentWidth:           indicatorLoader.x + indicatorLoader.width
        flickableDirection:     Flickable.HorizontalFlick
        visible:                currentToolbar == planViewToolbar

        Loader {
            id:                 indicatorLoader
            anchors.left:       parent.left
            anchors.right:      parent.right
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            source:             currentToolbar == planViewToolbar ? "qrc:/qml/PlanToolBarIndicators.qml" : ""
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
        // border.color:           qgcPal.text
        // border.width:           1
        visible:                currentToolbar === flyViewToolbar

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
            onClicked:          mainWindow.showIndicatorDrawer(widgetControlComponent)
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
        visible:                !ScreenTools.isMobile && currentToolbar !== planViewToolbar && x > (toolsFlickable.x + toolsFlickable.contentWidth + ScreenTools.defaultFontPixelWidth)
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
            title :     qsTr("Link Management")
            buttons:    StandardButton.Close

            Rectangle {
                id: _linkRoot
                color: qgcPal.window
                width: ScreenTools.defaultFontPixelWidth * 30
                height: ScreenTools.defaultFontPixelHeight * 20
                anchors.margins: ScreenTools.defaultFontPixelWidth

                Rectangle {
                    id: flickableRect
                    anchors.top:        parent.top
                    anchors.bottom:     buttonRow.top
                    anchors.margins:    ScreenTools.defaultFontPixelHeight / 2
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    color:              qgcPal.windowShadeDark
                    radius:             ScreenTools.defaultFontPixelHeight / 2

                    QGCFlickable {
                        clip:               true
                        anchors.top:        parent.top
                        anchors.bottom:     parent.bottom
                        anchors.margins:    ScreenTools.defaultFontPixelHeight / 4
                        // anchors.bottom:     buttonRow.top
                        // anchors.bottomMargin: ScreenTools.defaultFontPixelHeight / 5
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                        //width:              parent.width
                        contentHeight:      settingsColumn.height
                        //contentWidth:       _linkRoot.width
                        flickableDirection: Flickable.VerticalFlick

                        Column {
                            id:                 settingsColumn
                            width:              flickableRect.width
                            anchors.horizontalCenter: parent.horizontalCenter
                            //anchors.margins:    ScreenTools.defaultFontPixelWidth
                            spacing:            ScreenTools.defaultFontPixelHeight / 2
                            Repeater {
                                model: QGroundControl.linkManager.linkConfigurations
                                delegate: QGCButton {
                                    anchors.horizontalCenter:   settingsColumn.horizontalCenter
                                    width:                      _linkRoot.width * 0.7
                                    text:                       object.name + (object.link ? " (" + qsTr("Connected") + ")" : "")
                                    autoExclusive:              true
                                    visible:                    !object.dynamic
                                    onClicked: {
                                        checked = true
                                        _currentSelection = object
                                        //console.log("clicked", object, object.link)
                                    }
                                }
                            }
                        }
                    }
                }

                Row {
                    id:                 buttonRow
                    spacing:            ScreenTools.defaultFontPixelWidth
                    anchors.bottom:     parent.bottom
                    anchors.margins:    ScreenTools.defaultFontPixelWidth
                    anchors.horizontalCenter: parent.horizontalCenter

                    QGCButton {
                        text:       qsTr("Connect")
                        font.bold: true
                        enabled:    _currentSelection && !_currentSelection.link
                        onClicked:  QGroundControl.linkManager.createConnectedLink(_currentSelection)
                        implicitWidth: ScreenTools.defaultFontPixelWidth * 12
                    }
                    QGCButton {
                        text:       qsTr("Disconnect")
                        font.bold: true
                        enabled:    _currentSelection && _currentSelection.link
                        onClicked:  {
                            _currentSelection.link.disconnect()
                            _currentSelection.linkChanged()
                        }
                        implicitWidth: ScreenTools.defaultFontPixelWidth * 12
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

    // Small parameter download progress bar
    Rectangle {
        anchors.bottom: parent.bottom
        height:         _root.height * 0.05
        width:          _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
        color:          qgcPal.colorGreen
        visible:        !largeProgressBar.visible
    }

    // Large parameter download progress bar
    Rectangle {
        id:             largeProgressBar
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right
        height:         parent.height
        color:          qgcPal.window
        visible:        _showLargeProgress

        property bool _initialDownloadComplete: _activeVehicle ? _activeVehicle.initialConnectComplete : true
        property bool _userHide:                false
        property bool _showLargeProgress:       !_initialDownloadComplete && !_userHide && qgcPal.globalTheme === QGCPalette.Light

        Connections {
            target:                 QGroundControl.multiVehicleManager
            function onActiveVehicleChanged(activeVehicle) { largeProgressBar._userHide = false }
        }

        Rectangle {
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            width:          _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
            color:          qgcPal.colorGreen
        }

        QGCLabel {
            anchors.centerIn:   parent
            text:               qsTr("Downloading")
            font.pointSize:     ScreenTools.largeFontPointSize
        }

        QGCLabel {
            anchors.margins:    _margin
            anchors.right:      parent.right
            anchors.bottom:     parent.bottom
            text:               qsTr("Click anywhere to hide")

            property real _margin: ScreenTools.defaultFontPixelWidth / 2
        }

        MouseArea {
            anchors.fill:   parent
            onClicked:      largeProgressBar._userHide = true
        }
    }
}
