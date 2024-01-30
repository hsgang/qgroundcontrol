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
import QGroundControl.Palette
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Controllers
import QGroundControl.FactSystem
import QGroundControl.FactControls

Rectangle {
    id:     _root
    width:  parent.width
    height: ScreenTools.toolbarHeight
    color:  qgcPal.toolbarBackground

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
            height:                 viewButtonRow.height * 0.8
            width:                  height
            color:                  "transparent"
            //border.color:           qgcPal.text
            radius:                 ScreenTools.defaultFontPixelHeight / 4

            QGCToolBarButton {
                anchors.centerIn:       parent
                icon.source:            "/qmlimages/Hamburger.svg"
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
            //anchors.right:          widgetControlButton.left //parent.right
            //anchors.top:            parent.top
            //anchors.bottom:         parent.bottom
            //anchors.margins:        ScreenTools.defaultFontPixelHeight * 0.5
            height:                 viewButtonRow.height * 0.7//parent.height - ScreenTools.defaultFontPixelHeight
            width:                  height
            color:                  "transparent"
            radius:                 ScreenTools.defaultFontPixelHeight * 0.2
            border.color:           qgcPal.text
            border.width:           1
            visible:                !ScreenTools.isMobile

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
            height:                 viewButtonRow.height * 0.7
        }

        QGCButton {
            id:                 disconnectButton
            text:               qsTr("Disconnect")
            onClicked:          _activeVehicle.closeVehicle()
            visible:            _activeVehicle && _communicationLost
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
        color:                  qgcPal.windowShade //"transparent"
        border.color:           qgcPal.text
        radius:                 ScreenTools.defaultFontPixelHeight / 4
        visible:                _activeVehicle

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
            source:             "qrc:/qml/QGroundControl/FlightDisplay/FlyViewToolBarIndicators.qml"
        }
    }  

    Rectangle {
        id:                     widgetControlButton
        anchors.right:          parent.right
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
            onClicked:          mainWindow.showIndicatorDrawer(widgetControlComponent)
        }
    }

    Component{
        id: linkManagerDialogComponent

        QGCPopupDialog {
            title :     qsTr("Link Management")
            buttons:    Dialog.Close

            Rectangle {
                id: _linkRoot
                color: qgcPal.window
                width: ScreenTools.defaultFontPixelWidth * 30
                height: ScreenTools.defaultFontPixelHeight * 15
                anchors.margins: ScreenTools.defaultFontPixelWidth

                QGCFlickable {
                    clip:               true
                    anchors.top:        parent.top
                    anchors.bottom:     buttonRow.top
                    anchors.bottomMargin: ScreenTools.defaultFontPixelHeight / 5
                    width:              parent.width
                    contentHeight:      settingsColumn.height
                    contentWidth:       _linkRoot.width
                    flickableDirection: Flickable.VerticalFlick

                    Column {
                        id:                 settingsColumn
                        width:              _linkRoot.width
                        anchors.margins:    ScreenTools.defaultFontPixelWidth
                        spacing:            ScreenTools.defaultFontPixelHeight / 2
                        Repeater {
                            model: QGroundControl.linkManager.linkConfigurations
                            delegate: QGCButton {
                                anchors.horizontalCenter:   settingsColumn.horizontalCenter
                                width:                      _linkRoot.width * 0.5
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
                    }
                    QGCButton {
                        text:       qsTr("Disconnect")
                        font.bold: true
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

    Component {
        id: widgetControlComponent

        ToolIndicatorPage{
            showExpand: false

            property real _margins: ScreenTools.defaultFontPixelHeight / 2

            contentComponent: Component {
                ColumnLayout {
                    Layout.preferredWidth:  parent.width
                    Layout.alignment:       Qt.AlignTop
                    spacing:                _margins

                    QGCLabel {
                        text:                   qsTr("FlyView Widget")
                        font.family:            ScreenTools.demiboldFontFamily
                        Layout.fillWidth:       true
                        horizontalAlignment:    Text.AlignHCenter
                    }

                    Rectangle {
                        Layout.preferredHeight: widgetGridLayout.height + _margins
                        Layout.preferredWidth:  widgetGridLayout.width + _margins
                        color:                  qgcPal.windowShade
                        radius:                 _margins / 4
                        Layout.fillWidth:       true

                        ColumnLayout {
                            id:                 widgetGridLayout
                            spacing:            _margins
                            anchors.margins:    _margins / 2
                            anchors.top:        parent.top
                            anchors.left:       parent.left
                            anchors.right:      parent.right

                            QGCLabel{ text: qsTr("Payload"); Layout.columnSpan : 2; Layout.alignment: Qt.AlignHCenter }


                            FactCheckBoxSlider {
                                Layout.fillWidth: true
                                text:       qsTr("PhotoVideo Control")
                                fact:       _showPhotoVideoControl
                                visible:    _showPhotoVideoControl.visible
                                property Fact   _showPhotoVideoControl:      QGroundControl.settingsManager.flyViewSettings.showPhotoVideoControl
                            }

                            FactCheckBoxSlider {
                                Layout.fillWidth: true
                                text:       qsTr("Mount Control")
                                fact:       _showGimbalControlPannel
                                visible:    _showGimbalControlPannel.visible
                                property Fact   _showGimbalControlPannel:      QGroundControl.settingsManager.flyViewSettings.showGimbalControlPannel
                            }

                            FactCheckBoxSlider {
                                Layout.fillWidth: true
                                text:       qsTr("Winch Control")
                                fact:       _showWinchControl
                                visible:    _showWinchControl.visible
                                property Fact   _showWinchControl:      QGroundControl.settingsManager.flyViewSettings.showWinchControl
                            }

                            FactCheckBoxSlider {
                                Layout.fillWidth: true
                                text:       qsTr("Chart Widget")
                                fact:       _showChartWidget
                                visible:    _showChartWidget.visible
                                property Fact   _showChartWidget:      QGroundControl.settingsManager.flyViewSettings.showChartWidget
                            }

                            FactCheckBoxSlider {
                                Layout.fillWidth: true
                                text:       qsTr("Atmospheric Data")
                                fact:       _showAtmosphericValueBar
                                visible:    _showAtmosphericValueBar.visible
                                property Fact   _showAtmosphericValueBar:      QGroundControl.settingsManager.flyViewSettings.showAtmosphericValueBar
                            }

                            Item{
                                height: _margins / 2
                            }

                            QGCLabel{ text: qsTr("Status"); Layout.columnSpan : 2; Layout.alignment: Qt.AlignHCenter }

                            FactCheckBoxSlider {
                                Layout.fillWidth: true
                                text:       qsTr("Mission Progress")
                                fact:       _showMissionProgress
                                visible:    _showMissionProgress.visible
                                property Fact   _showMissionProgress:      QGroundControl.settingsManager.flyViewSettings.showMissionProgress
                            }

                            FactCheckBoxSlider {
                                Layout.fillWidth: true
                                text:       qsTr("Telemetry Panel")
                                fact:       _showTelemetryPanel
                                visible:    _showTelemetryPanel.visible
                                property Fact   _showTelemetryPanel:      QGroundControl.settingsManager.flyViewSettings.showTelemetryPanel
                            }

                            FactCheckBoxSlider {
                                Layout.fillWidth: true
                                text:       qsTr("Vibration Status")
                                fact:       _showVibrationStatus
                                visible:    _showVibrationStatus.visible
                                property Fact   _showVibrationStatus:      QGroundControl.settingsManager.flyViewSettings.showVibrationStatus
                            }

                            FactCheckBoxSlider {
                                Layout.fillWidth: true
                                text:       qsTr("Vibration Status")
                                fact:       _showEKFStatus
                                visible:    _showEKFStatus.visible
                                property Fact   _showEKFStatus:      QGroundControl.settingsManager.flyViewSettings.showEKFStatus
                            }
                        }
                    }

                    QGCLabel {
                        text:                   qsTr("FlyView Settings")
                        font.family:            ScreenTools.demiboldFontFamily
                        Layout.fillWidth:       true
                        horizontalAlignment:    Text.AlignHCenter
                    }

                    Rectangle {
                        Layout.preferredHeight: settingsLayout.height + _margins
                        Layout.preferredWidth:  settingsLayout.width + _margins
                        color:                  qgcPal.windowShade
                        radius:                 _margins / 4
                        Layout.fillWidth:       true

                        GridLayout {
                            id:                 settingsLayout
                            flow:               GridLayout.LeftToRight
                            columns:            2
                            rowSpacing:         _margins
                            anchors.margins:    _margins / 2
                            anchors.top:        parent.top
                            anchors.left:       parent.left
                            anchors.right:      parent.right

                            QGCLabel{ text: qsTr("Background Opacity"); Layout.columnSpan: 2; Layout.alignment: Qt.AlignHCenter }
                            FactComboBox {
                                Layout.columnSpan:  2
                                Layout.fillWidth:   true
                                fact:               QGroundControl.settingsManager.flyViewSettings.flyviewWidgetOpacity
                                indexModel:         false
                            }
                        }
                    }

                }
            }
        }
    }

    //-------------------------------------------------------------------------
    //-- Branding Logo
//    Image {
//        anchors.right:          parent.right
//        anchors.top:            parent.top
//        anchors.bottom:         parent.bottom
//        anchors.margins:        ScreenTools.defaultFontPixelHeight * 0.66
//        visible:                currentToolbar !== planViewToolbar && _activeVehicle && !_communicationLost && x > (toolsFlickable.x + toolsFlickable.contentWidth + ScreenTools.defaultFontPixelWidth)
//        fillMode:               Image.PreserveAspectFit
//        source:                 _outdoorPalette ? _brandImageOutdoor : _brandImageIndoor
//        mipmap:                 true

//        property bool   _outdoorPalette:        qgcPal.globalTheme === QGCPalette.Light
//        property bool   _corePluginBranding:    QGroundControl.corePlugin.brandImageIndoor.length != 0
//        property string _userBrandImageIndoor:  QGroundControl.settingsManager.brandImageSettings.userBrandImageIndoor.value
//        property string _userBrandImageOutdoor: QGroundControl.settingsManager.brandImageSettings.userBrandImageOutdoor.value
//        property bool   _userBrandingIndoor:    _userBrandImageIndoor.length != 0
//        property bool   _userBrandingOutdoor:   _userBrandImageOutdoor.length != 0
//        property string _brandImageIndoor:      brandImageIndoor()
//        property string _brandImageOutdoor:     brandImageOutdoor()

//        function brandImageIndoor() {
//            if (_userBrandingIndoor) {
//                return _userBrandImageIndoor
//            } else {
//                if (_userBrandingOutdoor) {
//                    return _userBrandingOutdoor
//                } else {
//                    if (_corePluginBranding) {
//                        return QGroundControl.corePlugin.brandImageIndoor
//                    } else {
//                        return _activeVehicle ? _activeVehicle.brandImageIndoor : ""
//                    }
//                }
//            }
//        }

//        function brandImageOutdoor() {
//            if (_userBrandingOutdoor) {
//                return _userBrandingOutdoor
//            } else {
//                if (_userBrandingIndoor) {
//                    return _userBrandingIndoor
//                } else {
//                    if (_corePluginBranding) {
//                        return QGroundControl.corePlugin.brandImageOutdoor
//                    } else {
//                        return _activeVehicle ? _activeVehicle.brandImageOutdoor : ""
//                    }
//                }
//            }
//        }
//    }

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
