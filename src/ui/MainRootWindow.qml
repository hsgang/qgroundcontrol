/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.15  //2.11
import QtQuick.Controls 2.15   //2.4
import QtQuick.Dialogs  1.3
import QtQuick.Layouts  1.11
import QtQuick.Window   2.11

import QGroundControl               1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.FlightMap     1.0

/// @brief Native QML top level window
/// All properties defined here are visible to all QML pages.
ApplicationWindow {
    id:             mainWindow
    minimumWidth:   ScreenTools.isMobile ? Screen.width  : Math.min(ScreenTools.defaultFontPixelWidth * 100, Screen.width)
    minimumHeight:  ScreenTools.isMobile ? Screen.height : Math.min(ScreenTools.defaultFontPixelWidth * 50, Screen.height)
    visible:        true

    Component.onCompleted: {
        //-- Full screen on mobile or tiny screens
        if (ScreenTools.isMobile || Screen.height / ScreenTools.realPixelDensity < 120) {
            mainWindow.showFullScreen()
        } else {
            width   = ScreenTools.isMobile ? Screen.width  : Math.min(250 * Screen.pixelDensity, Screen.width)
            height  = ScreenTools.isMobile ? Screen.height : Math.min(150 * Screen.pixelDensity, Screen.height)
        }

        // Start the sequence of first run prompt(s)
        firstRunPromptManager.nextPrompt()
    }

    QtObject {
        id: firstRunPromptManager

        property var currentDialog:     null
        property var rgPromptIds:       QGroundControl.corePlugin.firstRunPromptsToShow()
        property int nextPromptIdIndex: 0

        function clearNextPromptSignal() {
            if (currentDialog) {
                currentDialog.closed.disconnect(nextPrompt)
            }
        }

        function nextPrompt() {
            if (nextPromptIdIndex < rgPromptIds.length) {
                var component = Qt.createComponent(QGroundControl.corePlugin.firstRunPromptResource(rgPromptIds[nextPromptIdIndex]));
                currentDialog = component.createObject(mainWindow)
                currentDialog.closed.connect(nextPrompt)
                currentDialog.open()
                nextPromptIdIndex++
            } else {
                currentDialog = null
                showPreFlightChecklistIfNeeded()
            }
        }
    }

    property var                _rgPreventViewSwitch:       [ false ]

    readonly property real      _topBottomMargins:          ScreenTools.defaultFontPixelHeight * 0.5

    //-------------------------------------------------------------------------
    //-- Global Scope Variables

    QtObject {
        id: globals

        readonly property var       activeVehicle:                  QGroundControl.multiVehicleManager.activeVehicle
        readonly property real      defaultTextHeight:              ScreenTools.defaultFontPixelHeight
        readonly property real      defaultTextWidth:               ScreenTools.defaultFontPixelWidth
        readonly property var       planMasterControllerFlyView:    flightView.planController
        readonly property var       guidedControllerFlyView:        flightView.guidedController

        property var                planMasterControllerPlanView:   null
        property var                currentPlanMissionItem:         planMasterControllerPlanView ? planMasterControllerPlanView.missionController.currentPlanViewItem : null

        // Property to manage RemoteID quick acces to settings page
        property bool               commingFromRIDIndicator:        false
    }

    /// Default color palette used throughout the UI
    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    //-------------------------------------------------------------------------
    //-- Actions

    signal armVehicleRequest
    signal forceArmVehicleRequest
    signal disarmVehicleRequest
    signal vtolTransitionToFwdFlightRequest
    signal vtolTransitionToMRFlightRequest
    signal showPreFlightChecklistIfNeeded

    //-------------------------------------------------------------------------
    //-- Global Scope Functions

    /// Prevent view switching
    function pushPreventViewSwitch() {
        _rgPreventViewSwitch.push(true)
    }

    /// Allow view switching
    function popPreventViewSwitch() {
        if (_rgPreventViewSwitch.length == 1) {
            console.warn("mainWindow.popPreventViewSwitch called when nothing pushed")
            return
        }
        _rgPreventViewSwitch.pop()
    }

    /// @return true: View switches are not currently allowed
    function preventViewSwitch() {
        return _rgPreventViewSwitch[_rgPreventViewSwitch.length - 1]
    }

    function viewSwitch(currentToolbar) {
        flightView.visible      = false
        planView.visible        = false
        analyzeView.visible     = false
        setupView.visible       = false
        appSettings.visible     = false
        toolbar.currentToolbar  = currentToolbar
    }

    function showFlyView() {
        if (!flightView.visible) {
            mainWindow.showPreFlightChecklistIfNeeded()
        }
        viewSwitch(toolbar.flyViewToolbar)
        flightView.visible = true
    }

    function showPlanView() {
        viewSwitch(toolbar.planViewToolbar)
        planView.visible = true
    }

    function showAnalyzeTool() {
        viewSwitch(toolbar.flyViewToolbar)
        analyzeView.visible = true
    }

    function showSetupTool() {
        viewSwitch(toolbar.flyViewToolbar)
        setupView.visible = true
    }

    function showVehicleSetupTool(setupPage = "") {
        setupView.visible = true
        if (setupPage !== "") {
            setupView.showNamedComponentPanel(setupPage)
        }
    }

    function showAppSettings() {
        viewSwitch(toolbar.flyViewToolbar)
        appSettings.visible = true
    }

    function showSettingsTool(settingsPage = "") {
        viewSwitch(toolbar.flyViewToolbar)
        appSettings.visible = true
        if (settingsPage !== "") {
            appSettings.showSettingsPage(settingsPage)
        }
    }

//    function showSettingsTool(settingsPage = "") {
//        showTool(qsTr("Application Settings"), "AppSettings.qml", "/res/QGCLogoWhite")
//        if (settingsPage !== "") {
//            toolDrawerLoader.item.showSettingsPage(settingsPage)
//        }
//    }

    function checkedMenu() {
        flyButton.checked = false
        planButton.checked = false
        analyzeButton.checked = false
        setupButton.checked = false
        settingsButton.checked = false
    }

    //-------------------------------------------------------------------------
    //-- Global simple message dialog

    function showMessageDialog(dialogTitle, dialogText, buttons = StandardButton.Ok, acceptFunction = null) {
        simpleMessageDialogComponent.createObject(mainWindow, { title: dialogTitle, text: dialogText, buttons: buttons, acceptFunction: acceptFunction }).open()
    }

    // This variant is only meant to be called by QGCApplication
    function _showMessageDialog(dialogTitle, dialogText) {
        showMessageDialog(dialogTitle, dialogText)
    }

    Component {
        id: simpleMessageDialogComponent

        QGCSimpleMessageDialog {
        }
    }

    /// Saves main window position and size
    MainWindowSavedState {
        window: mainWindow
    }

    property bool _forceClose: false

    function finishCloseProcess() {
        _forceClose = true
        // For some reason on the Qml side Qt doesn't automatically disconnect a signal when an object is destroyed.
        // So we have to do it ourselves otherwise the signal flows through on app shutdown to an object which no longer exists.
        firstRunPromptManager.clearNextPromptSignal()
        QGroundControl.linkManager.shutdown()
        QGroundControl.videoManager.stopVideo();
        mainWindow.close()
    }

    // On attempting an application close we check for:
    //  Unsaved missions - then
    //  Pending parameter writes - then
    //  Active connections

    property string closeDialogTitle: qsTr("Close %1").arg(QGroundControl.appName)

    function checkForUnsavedMission() {
        if (globals.planMasterControllerPlanView && globals.planMasterControllerPlanView.dirty) {
            showMessageDialog(closeDialogTitle,
                              qsTr("You have a mission edit in progress which has not been saved/sent. If you close you will lose changes. Are you sure you want to close?"),
                              StandardButton.Yes | StandardButton.No,
                              function() { checkForPendingParameterWrites() })
        } else {
            checkForPendingParameterWrites()
        }
    }

    function checkForPendingParameterWrites() {
        for (var index=0; index<QGroundControl.multiVehicleManager.vehicles.count; index++) {
            if (QGroundControl.multiVehicleManager.vehicles.get(index).parameterManager.pendingWrites) {
                mainWindow.showMessageDialog(closeDialogTitle,
                    qsTr("You have pending parameter updates to a vehicle. If you close you will lose changes. Are you sure you want to close?"),
                    StandardButton.Yes | StandardButton.No,
                    function() { checkForActiveConnections() })
                return
            }
        }
        checkForActiveConnections()
    }

    function checkForActiveConnections() {
        if (QGroundControl.multiVehicleManager.activeVehicle) {
            mainWindow.showMessageDialog(closeDialogTitle,
                qsTr("There are still active connections to vehicles. Are you sure you want to exit?"),
                StandardButton.Yes | StandardButton.No,
                function() { finishCloseProcess() })
        } else {
            finishCloseProcess()
        }
    }

    onClosing: {
        if (!_forceClose) {
            close.accepted = false
            checkForUnsavedMission()
        }
    }

    //-------------------------------------------------------------------------
    /// Main, full window background (Fly View)
    background: Item {
        id:             rootBackground
        anchors.fill:   parent
    }

    //-------------------------------------------------------------------------
    /// Toolbar
    header: MainToolBar {
        id:         toolbar
        height:     ScreenTools.toolbarHeight
        visible:    !QGroundControl.videoManager.fullScreen
    }

    footer: LogReplayStatusBar {
        visible: QGroundControl.settingsManager.flyViewSettings.showLogReplayStatusBar.rawValue
    }

    function showToolSelectDialog() {
        if (!mainWindow.preventViewSwitch()) {
            mainWindow.showIndicatorDrawer(toolSelectComponent)
        }
    }

    Drawer {
        id:             viewSelectDrawer
        y:              header.height
        height:         mainWindow.height - header.height
        width:          mainLayoutRect.width
        edge:           Qt.LeftEdge
        interactive:    true
        dragMargin:     0
        visible:        false

        property var    _mainWindow:       mainWindow
        property real   _toolButtonHeight: ScreenTools.defaultFontPixelHeight * 3

        Rectangle {
            id:     mainLayoutRect
            width:  mainLayout.width + (mainLayout.anchors.margins * 2)
            height: parent.height
            color:  qgcPal.window //Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.5)

            QGCFlickable {
                anchors.top:        parent.top
                anchors.bottom:     qgcVersionLayout.top
                anchors.left:       parent.left
                anchors.right:      parent.right
                contentHeight:      mainLayout.height + (mainLayout.anchors.margins * 2)
                flickableDirection: QGCFlickable.VerticalFlick

                ColumnLayout {
                    id:                 mainLayout
                    anchors.margins:    ScreenTools.defaultFontPixelWidth
                    anchors.left:       parent.left
                    anchors.top:        parent.top
                    spacing:            ScreenTools.defaultFontPixelWidth

                    SubMenuButton {
                        id:                 flyButton
                        height:             viewSelectDrawer._toolButtonHeight
                        Layout.fillWidth:   true
                        checked:            true
                        text:               qsTr("Fly View")
                        imageResource:      "/qmlimages/PaperPlane.svg"
                        imageColor:         qgcPal.text
                        onClicked: {
                            if (!mainWindow.preventViewSwitch()) {
                                mainWindow.showFlyView()
                                checkedMenu()
                                flyButton.checked = true
                                viewSelectDrawer.visible = false
                            }
                        }
                    }

                    SubMenuButton {
                        id:                 planButton
                        height:             viewSelectDrawer._toolButtonHeight
                        Layout.fillWidth:   true
                        text:               qsTr("Plan View")
                        imageResource:      "/qmlimages/Plan.svg"
                        imageColor:         qgcPal.text
                        onClicked: {
                            if (!mainWindow.preventViewSwitch()) {
                                mainWindow.showPlanView()
                                checkedMenu()
                                planButton.checked = true
                                viewSelectDrawer.visible = false
                            }
                        }
                    }

                    SubMenuButton {
                        id:                 setupButton
                        height:             viewSelectDrawer._toolButtonHeight
                        Layout.fillWidth:   true
                        text:               qsTr("Vehicle Setup")
                        imageColor:         qgcPal.text
                        imageResource:      "/qmlimages/Quad.svg"
                        onClicked: {
                            if (!mainWindow.preventViewSwitch()) {
                                mainWindow.showSetupTool()
                                checkedMenu()
                                setupButton.checked = true
                                viewSelectDrawer.visible = false
                            }
                        }
                    }

                    SubMenuButton {
                        id:                 analyzeButton
                        height:             viewSelectDrawer._toolButtonHeight
                        Layout.fillWidth:   true
                        text:               qsTr("Analyze Tools")
                        imageResource:      "/qmlimages/Analyze.svg"
                        imageColor:         qgcPal.text
                        visible:            QGroundControl.corePlugin.showAdvancedUI
                        onClicked: {
                            if (!mainWindow.preventViewSwitch()) {
                                mainWindow.showAnalyzeTool()
                                checkedMenu()
                                analyzeButton.checked = true
                                viewSelectDrawer.visible = false
                            }
                        }
                    }                    

                    SubMenuButton {
                        id:                 settingsButton
                        height:             viewSelectDrawer._toolButtonHeight
                        Layout.fillWidth:   true
                        text:               qsTr("App Settings")
                        imageResource:      "/qmlimages/Gears.svg"
                        imageColor:         qgcPal.text
                        visible:            !QGroundControl.corePlugin.options.combineSettingsAndSetup
                        onClicked: {
                            if (!mainWindow.preventViewSwitch()) {
                                mainWindow.showAppSettings()
                                checkedMenu()
                                settingsButton.checked = true
                                viewSelectDrawer.visible = false
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                id:                     qgcVersionLayout
                anchors.bottom:         parent.bottom
                height:                 ScreenTools.defaultFontPixelHeight * 3
                width:                  parent.width
                spacing:                0
                Layout.alignment:       Qt.AlignHCenter

                QGCLabel {
                    id:                     versionLabel
                    text:                   QGroundControl.appName
                    font.pointSize:         ScreenTools.smallFontPointSize
                    wrapMode:               QGCLabel.WordWrap
                    Layout.maximumWidth:    parent.width
                    Layout.alignment:       Qt.AlignHCenter
                }

                QGCLabel {
                    text:                   qsTr("Version: %1").arg(QGroundControl.qgcVersion)
                    font.pointSize:         ScreenTools.smallFontPointSize
                    wrapMode:               QGCLabel.WrapAnywhere
                    Layout.maximumWidth:    parent.width
                    Layout.alignment:       Qt.AlignHCenter
                }
            }

            QGCMouseArea {
                anchors.fill: qgcVersionLayout

                onClicked: {
                    if (mouse.modifiers & Qt.ShiftModifier) {
                        QGroundControl.corePlugin.showTouchAreas = !QGroundControl.corePlugin.showTouchAreas
                    } else {
                        if(!QGroundControl.corePlugin.showAdvancedUI) {
                            advancedModeConfirmation.open()
                        } else {
                            QGroundControl.corePlugin.showAdvancedUI = false
                        }
                    }
                }

                MessageDialog {
                    id:                 advancedModeConfirmation
                    title:              qsTr("Advanced Mode")
                    text:               QGroundControl.corePlugin.showAdvancedUIMessage
                    standardButtons:    StandardButton.Yes | StandardButton.No
                    onYes: {
                        QGroundControl.corePlugin.showAdvancedUI = true
                        advancedModeConfirmation.close()
                    }
                }
            }
        }
    }


    FlyView {
        id:             flightView
        anchors.fill:   parent
    }

    PlanView {
        id:             planView
        anchors.fill:   parent
        visible:        false
    }

    AnalyzeView{
        id:             analyzeView
        anchors.fill:   parent
        visible:        false
    }

    SetupView{
        id:             setupView
        anchors.fill:   parent
        visible:        false
    }

    AppSettings{
        id:             appSettings
        anchors.fill:   parent
        visible:        false
    }

    //-------------------------------------------------------------------------
    //-- Critical Vehicle Message Popup

    function showCriticalVehicleMessage(message) {
//        indicatorPopup.close()
//        if (criticalVehicleMessagePopup.visible || QGroundControl.videoManager.fullScreen) {
//            _vehicleMessageQueue.push(message)
//        } else {
//            _vehicleMessage = message
//            criticalVehicleMessagePopup.open()
//        }
//        indicatorPopup.close()
//        if (criticalVehicleMessagePopup.visible || QGroundControl.videoManager.fullScreen) {
//            // We received additional wanring message while an older warning message was still displayed.
//            // When the user close the older one drop the message indicator tool so they can see the rest of them.
//            criticalVehicleMessagePopup.dropMessageIndicatorOnClose = true
//        } else {
//            criticalVehicleMessagePopup.criticalVehicleMessage      = message
//            criticalVehicleMessagePopup.dropMessageIndicatorOnClose = false
//            criticalVehicleMessagePopup.open()
//        }
    }

    Popup {
        id:                 criticalVehicleMessagePopup
        y:                  ScreenTools.defaultFontPixelHeight
        x:                  Math.round((mainWindow.width - width) * 0.5)
        width:              mainWindow.width  * 0.55
        height:             criticalVehicleMessageText.contentHeight + ScreenTools.defaultFontPixelHeight * 2
        modal:              false
        focus:              true
        closePolicy:        Popup.CloseOnEscape

        property alias  criticalVehicleMessage:        criticalVehicleMessageText.text
        property bool   dropMessageIndicatorOnClose:   false

        background: Rectangle {
            anchors.fill:   parent
            color:          qgcPal.alertBackground
            radius:         ScreenTools.defaultFontPixelHeight * 0.5
            border.color:   qgcPal.alertBorder
            border.width:   2

            Rectangle {
                anchors.horizontalCenter:   parent.horizontalCenter
                anchors.top:                parent.top
                anchors.topMargin:          -(height / 2)
                color:                      qgcPal.alertBackground
                radius:                     ScreenTools.defaultFontPixelHeight * 0.25
                border.color:               qgcPal.alertBorder
                border.width:               1
                width:                      vehicleWarningLabel.contentWidth + _margins
                height:                     vehicleWarningLabel.contentHeight + _margins

                property real _margins: ScreenTools.defaultFontPixelHeight * 0.25

                QGCLabel {
                    id:                 vehicleWarningLabel
                    anchors.centerIn:   parent
                    text:               qsTr("Vehicle Error")
                    font.pointSize:     ScreenTools.smallFontPointSize
                    color:              qgcPal.alertText
                }
            }

            Rectangle {
                id:                         additionalErrorsIndicator
                anchors.horizontalCenter:   parent.horizontalCenter
                anchors.bottom:             parent.bottom
                anchors.bottomMargin:       -(height / 2)
                color:                      qgcPal.alertBackground
                radius:                     ScreenTools.defaultFontPixelHeight * 0.25
                border.color:               qgcPal.alertBorder
                border.width:               1
                width:                      additionalErrorsLabel.contentWidth + _margins
                height:                     additionalErrorsLabel.contentHeight + _margins
                visible:                    criticalVehicleMessagePopup.dropMessageIndicatorOnClose

                property real _margins: ScreenTools.defaultFontPixelHeight * 0.25

                QGCLabel {
                    id:                 additionalErrorsLabel
                    anchors.centerIn:   parent
                    text:               qsTr("Additional errors received")
                    font.pointSize:     ScreenTools.smallFontPointSize
                    color:              qgcPal.alertText
                }
            }
        }

        QGCLabel {
            id:                 criticalVehicleMessageText
            width:              criticalVehicleMessagePopup.width - ScreenTools.defaultFontPixelHeight
            anchors.centerIn:   parent
            wrapMode:           Text.WordWrap
            color:              qgcPal.alertText
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                criticalVehicleMessagePopup.close()
                if (criticalVehicleMessagePopup.dropMessageIndicatorOnClose) {
                    criticalVehicleMessagePopup.dropMessageIndicatorOnClose = false;
                    QGroundControl.multiVehicleManager.activeVehicle.resetErrorLevelMessages();
                    toolbar.dropMessageIndicatorTool();
                }
            }
        }
    }

    //-------------------------------------------------------------------------
    //-- Indicator Popups - deprecated, use Indicator Drawer instead

    function showIndicatorPopup(item, dropItem) {
        indicatorPopup.currentIndicator = dropItem
        indicatorPopup.currentItem = item
        indicatorPopup.open()
    }

    function hideIndicatorPopup() {
        indicatorPopup.close()
        indicatorPopup.currentItem = null
        indicatorPopup.currentIndicator = null
    }

    Popup {
        id:             indicatorPopup
        padding:        ScreenTools.defaultFontPixelWidth * 0.75
        modal:          true
        focus:          true
        closePolicy:    Popup.CloseOnEscape | Popup.CloseOnPressOutside
        property var    currentItem:        null
        property var    currentIndicator:   null
        background: Rectangle {
            width:  loader.width
            height: loader.height
            color:  Qt.rgba(0,0,0,0)
        }
        Loader {
            id:             loader
            onLoaded: {
                var centerX = mainWindow.contentItem.mapFromItem(indicatorPopup.currentItem, 0, 0).x - (loader.width * 0.5)
                if((centerX + indicatorPopup.width) > (mainWindow.width - ScreenTools.defaultFontPixelWidth)) {
                    centerX = mainWindow.width - indicatorPopup.width - ScreenTools.defaultFontPixelWidth
                }
                indicatorPopup.x = centerX
            }
        }
        onOpened: {
            loader.sourceComponent = indicatorPopup.currentIndicator
        }
        onClosed: {
            loader.sourceComponent = null
            indicatorPopup.currentIndicator = null
        }
    }

    //-------------------------------------------------------------------------
    //-- Indicator Drawer

    function showIndicatorDrawer(drawerComponent) {
        indicatorDrawer.sourceComponent = drawerComponent
        indicatorDrawer.open()
    }

    Popup {
        id:             indicatorDrawer
        x:              _margins
        y:              _margins
        leftInset:      0
        rightInset:     0
        topInset:       0
        bottomInset:    0
        padding:        _margins * 2
        visible:        false
        modal:          true
        focus:          true
        closePolicy:    Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property var sourceComponent

        property bool _expanded:    false
        property real _margins:     ScreenTools.defaultFontPixelHeight / 4

        onOpened: {
            _expanded                               = false;
            indicatorDrawerLoader.sourceComponent   = indicatorDrawer.sourceComponent
        }
        onClosed: {
            _expanded                               = false
            indicatorDrawerLoader.sourceComponent   = undefined
        }

        background: Item {
            Rectangle {
                id:             backgroundRect
                anchors.fill:   parent
                height:         indicatorDrawerLoader.height
                color:          QGroundControl.globalPalette.window
                radius:         indicatorDrawer._margins
                opacity:        0.85
            }

            Rectangle {
                anchors.top:                backgroundRect.top
                anchors.topMargin:          ScreenTools.defaultFontPixelHeight / 4
                anchors.left:               backgroundRect.right
                anchors.leftMargin:         ScreenTools.defaultFontPixelHeight / 4
                width:                      ScreenTools.defaultFontPixelHeight
                height:                     width
                radius:                     width / 2
                color:                      QGroundControl.globalPalette.button
                border.color:               QGroundControl.globalPalette.buttonText
                visible:                    indicatorDrawerLoader.item && indicatorDrawerLoader.item.showExpand && !indicatorDrawer._expanded

                QGCLabel {
                    anchors.centerIn:   parent
                    text:               ">"
                    color:              QGroundControl.globalPalette.buttonText
                }  

                QGCMouseArea {
                    fillItem: parent
                    onClicked: indicatorDrawer._expanded = true
                }
            }
        }

        contentItem: QGCFlickable {
            id:             indicatorDrawerLoaderFlickable
            implicitWidth:  Math.min(mainWindow.contentItem.width - (2 * indicatorDrawer._margins) - (indicatorDrawer.padding * 2), indicatorDrawerLoader.width)
            implicitHeight: Math.min(mainWindow.contentItem.height - (2 * indicatorDrawer._margins) - (indicatorDrawer.padding * 2), indicatorDrawerLoader.height)
            contentWidth:   indicatorDrawerLoader.width
            contentHeight:  indicatorDrawerLoader.height

            Loader {
                id: indicatorDrawerLoader

                Binding {
                    target:     indicatorDrawerLoader.item
                    property:   "expanded"
                    value:      indicatorDrawer._expanded
                }

                Binding {
                    target:     indicatorDrawerLoader.item
                    property:   "drawer"
                    value:      indicatorDrawer
                }

            }
        }
    }

    // We have to create the popup windows for the Analyze pages here so that the creation context is rooted
    // to mainWindow. Otherwise if they are rooted to the AnalyzeView itself they will die when the analyze viewSwitch
    // closes.

    function createrWindowedAnalyzePage(title, source) {
        var windowedPage = windowedAnalyzePage.createObject(mainWindow)
        windowedPage.title = title
        windowedPage.source = source
    }

    Component {
        id: windowedAnalyzePage

        Window {
            width:      ScreenTools.defaultFontPixelWidth  * 100
            height:     ScreenTools.defaultFontPixelHeight * 40
            visible:    true

            property alias source: loader.source

            Rectangle {
                color:          QGroundControl.globalPalette.window
                anchors.fill:   parent

                Loader {
                    id:             loader
                    anchors.fill:   parent
                    onLoaded:       item.popped = true
                }
            }

            onClosing: {
                visible = false
                source = ""
            }
        }
    }
}
