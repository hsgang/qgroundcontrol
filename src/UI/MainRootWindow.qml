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
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Window

import QGroundControl
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap

import QGroundControl.UTMSP

/// @brief Native QML top level window
/// All properties defined here are visible to all QML pages.
ApplicationWindow {
    id:             mainWindow
    minimumWidth:   ScreenTools.isMobile ? ScreenTools.screenWidth  : Math.min(ScreenTools.defaultFontPixelWidth * 100, Screen.width)
    minimumHeight:  ScreenTools.isMobile ? ScreenTools.screenHeight : Math.min(ScreenTools.defaultFontPixelWidth * 50, Screen.height)
    visible:        true

    property string _startTimeStamp
    property bool   _showVisible
    property string _flightID
    property bool   _utmspSendActTrigger
    property bool   _utmspStartTelemetry

    Component.onCompleted: {
        //-- Full screen on mobile or tiny screens
        if (!ScreenTools.isFakeMobile && (ScreenTools.isMobile || Screen.height / ScreenTools.realPixelDensity < 120)) {
            mainWindow.showFullScreen()
        } else {
            width   = ScreenTools.isMobile ? ScreenTools.screenWidth  : Math.min(250 * Screen.pixelDensity, Screen.width)
            height  = ScreenTools.isMobile ? ScreenTools.screenHeight : Math.min(150 * Screen.pixelDensity, Screen.height)
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

    readonly property real      _topBottomMargins:          ScreenTools.defaultFontPixelHeight * 0.5

    //-------------------------------------------------------------------------
    //-- Global Scope Variables

    QtObject {
        id: globals

        readonly property var       activeVehicle:                  QGroundControl.multiVehicleManager.activeVehicle
        readonly property real      defaultTextHeight:              ScreenTools.defaultFontPixelHeight
        readonly property real      defaultTextWidth:               ScreenTools.defaultFontPixelWidth
        readonly property var       planMasterControllerFlyView:    flyView.planController
        readonly property var       guidedControllerFlyView:        flyView.guidedController

        property bool               validationError:                false   // There is a FactTextField somewhere with a validation error

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

    /// @return true: View switches are not currently allowed
    function preventViewSwitch() {
        return globals.validationError
    }

    function viewSwitch(currentToolbar) {
        flyView.visible         = false
        planView.visible        = false
        analyzeView.visible     = false
        setupView.visible       = false
        appSettings.visible     = false
        toolbar.currentToolbar  = currentToolbar
    }

    function showFlyView() {
        if (!flyView.visible) {
            mainWindow.showPreFlightChecklistIfNeeded()
        }
        //mainWindow.popView()
        //viewSwitch(toolbar.flyViewToolbar)
        flyView.visible = true
        planView.visible = false
    }

    function showPlanView() {
        //viewSwitch(toolbar.planViewToolbar)
        planView.visible = true
        flyView.visible = false
    }

    function showAnalyzeTool() {
        showTool(qsTr("Analyze Tools"), "AnalyzeView.qml", "/qmlimages/Analyze.svg")
    }

    function showSetupTool(setupPage = "") {
        showTool(qsTr("Vehicle Setup"), "SetupView.qml", "/qmlimages/Quad.svg")
        if (setupPage !== "") {
            toolDrawerLoader.item.showNamedComponentPanel(setupPage)
        }
    }

    function showAppSettings(settingsPage = "") {
        showTool(qsTr("Application Settings"), "AppSettings.qml", "/qmlimages/Gears.svg")
        if (settingsPage !== "") {
            toolDrawerLoader.item.showSettingsPage(settingsPage)
        }
    }

    function showTool(toolTitle, toolSource, toolIcon) {
        //toolDrawer.backIcon     = flyView.visible ? "/qmlimages/PaperPlane.svg" : "/qmlimages/Plan.svg"
        toolDrawer.toolTitle    = toolTitle
        toolDrawer.toolSource   = toolSource
        toolDrawer.toolIcon     = toolIcon
        toolDrawer.visible      = true
    }

    function checkedMenu() {
        flyButton.checked = false
        planButton.checked = false
        analyzeButton.checked = false
        setupButton.checked = false
        settingsButton.checked = false
    }

    //-------------------------------------------------------------------------
    //-- Global simple message dialog

    function showMessageDialog(dialogTitle, dialogText, buttons = Dialog.Ok, acceptFunction = null) {
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
        if (planView._planMasterController.dirty) {
            showMessageDialog(closeDialogTitle,
                              qsTr("You have a mission edit in progress which has not been saved/sent. If you close you will lose changes. Are you sure you want to close?"),
                              Dialog.Yes | Dialog.No,
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
                    Dialog.Yes | Dialog.No,
                    function() { checkForActiveConnections() })
                return
            }
        }
        checkForActiveConnections()
    }

    function checkForActiveConnections() {
        if (globals.activeVehicle) {
            mainWindow.showMessageDialog(closeDialogTitle,
                qsTr("There are still active connections to vehicles. Are you sure you want to exit?"),
                Dialog.Yes | Dialog.No,
                function() { finishCloseProcess() })
        } else {
            finishCloseProcess()
        }
    }

    onClosing: (close) => {
        if (!_forceClose) {
            close.accepted = false
            checkForUnsavedMission()
        }
    }

    background: Rectangle {
        anchors.fill:   parent
        color:          QGroundControl.globalPalette.window
    }

    FlyView { 
        id:                     flyView
        anchors.fill:           parent
        utmspSendActTrigger:    _utmspSendActTrigger
    }

    PlanView {
        id:             planView
        anchors.fill:   parent
        visible:        false

        onActivationParamsSent:{
            if(_utmspEnabled){
                _startTimeStamp = startTime
                _showVisible = activate
                _flightID = flightID
            }
        }
    }
//    //-------------------------------------------------------------------------
//    /// Toolbar
//    header: MainToolBar {
//        id:         toolbar
//        height:     ScreenTools.toolbarHeight
//        visible:    !(QGroundControl.videoManager.fullScreen && flyView.visible)
//    }

    footer: LogReplayStatusBar {
        visible: QGroundControl.settingsManager.flyViewSettings.showLogReplayStatusBar.rawValue
    }

//    function showToolSelectDialog() {
//        if (!mainWindow.preventViewSwitch()) {
//            mainWindow.showIndicatorDrawer(toolSelectComponent, null)
//        }
//    }

    Drawer {
        id:             viewSelectDrawer
        y:              ScreenTools.toolbarHeight
        height:         mainWindow.height - ScreenTools.toolbarHeight
        width:          mainLayoutRect.width
        edge:           Qt.LeftEdge
        interactive:    true
        dragMargin:     0
        modal:          false
        visible:        false

        property var    _mainWindow:       mainWindow
        property real   _toolButtonHeight: ScreenTools.defaultFontPixelHeight * 3

        Rectangle {
            id:     mainLayoutRect
            width:  mainLayout.width + (mainLayout.anchors.margins * 2)
            height: parent.height
            color:  qgcPal.windowShadeDark

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
                                toolDrawer.visible = false
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
                                toolDrawer.visible = false
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
                                toolDrawer.visible = false
                                mainWindow.showSetupTool()
                                checkedMenu()
                                //setupButton.checked = true
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
                                toolDrawer.visible = false
                                mainWindow.showAnalyzeTool()
                                checkedMenu()
                                //analyzeButton.checked = true
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
                                toolDrawer.visible = false
                                mainWindow.showAppSettings()
                                checkedMenu()
                                //settingsButton.checked = true
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
                    text:                   QGroundControl.qgcVersion
                    font.pointSize:         ScreenTools.smallFontPointSize
                    wrapMode:               QGCLabel.WrapAnywhere
                    Layout.maximumWidth:    parent.width
                    Layout.alignment:       Qt.AlignHCenter

                    QGCMouseArea {
                        id:                 easterEggMouseArea
                        anchors.topMargin:  -versionLabel.height
                        anchors.fill:       parent

                        onClicked: (mouse) => {
                            console.log("clicked")
                            if (mouse.modifiers & Qt.ControlModifier) {
                                QGroundControl.corePlugin.showTouchAreas = !QGroundControl.corePlugin.showTouchAreas
                                showTouchAreasNotification.open()
                            } else if (ScreenTools.isMobile || mouse.modifiers & Qt.ShiftModifier) {
                                if(!QGroundControl.corePlugin.showAdvancedUI) {
                                    advancedModeOnConfirmation.open()
                                } else {
                                    advancedModeOffConfirmation.open()
                                }
                            }
                        }

                        // This allows you to change this on mobile
                        onPressAndHold: {
                            QGroundControl.corePlugin.showTouchAreas = !QGroundControl.corePlugin.showTouchAreas
                            showTouchAreasNotification.open()
                        }

                        MessageDialog {
                            id:                 showTouchAreasNotification
                            title:              qsTr("Debug Touch Areas")
                            text:               qsTr("Touch Area display toggled")
                            buttons:    MessageDialog.Ok
                        }

                        MessageDialog {
                            id:                 advancedModeOnConfirmation
                            title:              qsTr("Advanced Mode")
                            text:               QGroundControl.corePlugin.showAdvancedUIMessage
                            buttons:    MessageDialog.Yes | MessageDialog.No
                            onButtonClicked: function (button, role) {
                                switch (button) {
                                case MessageDialog.Yes:
                                    QGroundControl.corePlugin.showAdvancedUI = true
                                    advancedModeOnConfirmation.close()
                                    break;
                                }
                            }
                        }

                        MessageDialog {
                            id:                 advancedModeOffConfirmation
                            title:              qsTr("Advanced Mode")
                            text:               qsTr("Turn off Advanced Mode?")
                            buttons:    MessageDialog.Yes | MessageDialog.No
                            onButtonClicked: function (button, role) {
                                switch (button) {
                                case MessageDialog.Yes:
                                    QGroundControl.corePlugin.showAdvancedUI = false
                                    advancedModeOffConfirmation.close()
                                    break;
                                case MessageDialog.No:
                                    resetPrompt.close()
                                    break;
                                }
                            }
                        }
                    }
                }
            }

            QGCMouseArea {
                anchors.fill: qgcVersionLayout

                onClicked: {
                    if (mouse.modifiers & Qt.ShiftModifier) {
                        QGroundControl.corePlugin.showTouchAreas = !QGroundControl.corePlugin.showTouchAreas
                    } else {
                        if(!QGroundControl.corePlugin.showAdvancedUI) {
                            advancedModeOnConfirmation.open()
                        } else {
                            //QGroundControl.corePlugin.showAdvancedUI = false
                            advancedModeOffConfirmation.open()
                        }
                    }
                }
            }
        }
    }

    Drawer {
        id:             componentDrawer
        y:              ScreenTools.toolbarHeight
        height:         mainWindow.height - ScreenTools.toolbarHeight
        width:          componentDrawerLayoutRect.width
        edge:           Qt.RightEdge
        interactive:    true
        dragMargin:     0
        visible:        false
        modal:          true
        padding:        _margins

        property var sourceComponent
        property bool _expanded: false

        property real _margins: ScreenTools.defaultFontPixelHeight / 4

        onVisibleChanged: {
            if(visible == true) {
                componentDrawerLoader.sourceComponent   = componentDrawer.sourceComponent
                _expanded                               = false
            } else if(visible == false) {
                componentDrawerLoader.sourceComponent   = undefined
                _expanded                               = false
            }
        }

        Rectangle {
            id:     componentDrawerLayoutRect
            width:  componentContents.width + (componentDrawer._margins * 2)
            height: parent.height
            color:  qgcPal.windowShadeDark

            QGCFlickable {
                anchors.margins:    componentDrawer._margins
                anchors.top:        parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                flickableDirection: QGCFlickable.VerticalFlick
                width:  Math.min(mainWindow.contentItem.width - (2 * componentDrawer._margins) - (componentDrawer.padding * 2), componentDrawerLoader.width)
                height: { componentExpandButton.visible ?
                    parent.height - componentExpandButton.height - ScreenTools.defaultFontPixelHeight :
                    parent.height - ScreenTools.defaultFontPixelHeight }
                contentWidth:   componentContents.width
                contentHeight:  componentContents.height

                Rectangle {
                    id:         componentContents
                    anchors.margins: componentDrawer._margins
                    width:      300 //componentDrawerLoader.width
                    height:     20
                    color:      "transparent"

                    Loader {
                        id: componentDrawerLoader
                        //anchors.fill: parent

                        onHeightChanged: componentContents.height = height
                        onWidthChanged: componentContents.width = width + (componentDrawer._margins * 2)

                        Binding {
                            target:     componentDrawerLoader.item
                            property:   "expanded"
                            value:      componentDrawer._expanded
                        }

                        Binding {
                            target:     componentDrawerLoader.item
                            property:   "dividerHeight"
                            value:      componentDrawer.height
                        }
                    }
                } //componentContents
            }

            Rectangle {
                id:                         componentExpandButton
                anchors.bottom:             componentDrawerLayoutRect.bottom
                anchors.bottomMargin:       ScreenTools.defaultFontPixelHeight / 4
                anchors.horizontalCenter:   parent.horizontalCenter
                width:                      componentExpandButtonLabel.width + (componentDrawer._margins * 2) * 3
                height:                     componentExpandButtonLabel.height * 2
                radius:                     componentDrawer._margins
                color:                      QGroundControl.globalPalette.windowShadeDark
                border.color:               QGroundControl.globalPalette.text
                visible:                    componentDrawerLoader.item && componentDrawerLoader.item.showExpand && !componentDrawer._expanded

                QGCLabel {
                    id:                 componentExpandButtonLabel
                    anchors.centerIn:   parent
                    text:               qsTr("Detail")
                    color:              QGroundControl.globalPalette.text
                }

                QGCMouseArea {
                    fillItem: parent
                    onClicked: {
                        componentDrawer._expanded = true
                    }
                }
            }
        }
    }

    Component {
        id: planViewComponent

        PlanView {
            id: planView
            onActivationParamsSent:{
                if(_utmspEnabled){
                    _startTimeStamp = startTime
                    _showVisible = activate
                    _flightID = flightID
                }
            }
        }
    }

    Component {
        id: analyzeViewComponent

        AnalyzeView{
            id:             analyzeView
        }
    }

    Component {
        id: setupViewComponent

        SetupView{
            id:             setupView
        }
    }

    Component {
        id: appSettingsComponent

        AppSettings{
            id:             appSettings
        }
    }

//    AnalyzeView{
//        id:             analyzeView
//        anchors.fill:   parent
//        visible:        false
//    }

//    SetupView{
//        id:             setupView
//        anchors.fill:   parent
//        visible:        false
//    }

//    AppSettings{
//        id:             appSettings
//        anchors.fill:   parent
//        visible:        false
//    }

    Drawer {
        id:             toolDrawer
        height:         mainWindow.height
        width:          mainWindow.width
        edge:           Qt.LeftEdge
        dragMargin:     0
        closePolicy:    Drawer.NoAutoClose
        interactive:    false
        visible:        false

        //property alias backIcon:    backIcon.source
        property alias toolTitle:   toolbarDrawerText.text
        property alias toolSource:  toolDrawerLoader.source
        property alias toolIcon:    toolIcon.source

        // Unload the loader only after closed, otherwise we will see a "blank" loader in the meantime
        onClosed: {
            toolDrawer.toolSource = ""
        }
        
        Rectangle {
            id:             toolDrawerToolbar
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.top:    parent.top
            height:         ScreenTools.toolbarHeight
            color:          qgcPal.toolbarBackground

            RowLayout {
                anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                anchors.left:       parent.left
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                spacing:            ScreenTools.defaultFontPixelWidth

                // QGCColoredImage {
                //     id:                     backIcon
                //     width:                  ScreenTools.defaultFontPixelHeight * 2
                //     height:                 ScreenTools.defaultFontPixelHeight * 2
                //     fillMode:               Image.PreserveAspectFit
                //     mipmap:                 true
                //     color:                  qgcPal.text
                // }

                Rectangle {
                    id:    backIcon
                    height: parent.height * 0.7
                    width: height
                    color: "transparent"
                    border.color: qgcPal.text
                    border.width: 1
                    radius: ScreenTools.defaultFontPixelHeight / 4

                    QGCColoredImage{
                        height:             parent.height * 0.7
                        width:              height
                        anchors.margins:    ScreenTools.defaultFontPixelHeight * 0.2
                        //anchors.fill:       parent
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        source:             "/InstrumentValueIcons/arrow-thin-left.svg"
                        sourceSize.height:  height
                        fillMode:           Image.PreserveAspectFit
                        color:              qgcPal.text
                    }
                }

                // QGCLabel {
                //     id:     backTextLabel
                //     text:   qsTr("Back")
                // }

                // QGCLabel {
                //     font.pointSize: ScreenTools.largeFontPointSize
                //     text:           "<"
                // }

                QGCColoredImage {
                    id:                     toolIcon
                    width:                  ScreenTools.defaultFontPixelHeight * 1.2
                    height:                 ScreenTools.defaultFontPixelHeight * 1.2
                    fillMode:               Image.PreserveAspectFit
                    mipmap:                 true
                    color:                  qgcPal.text
                }

                QGCLabel {
                    id:             toolbarDrawerText
                    font.pointSize: ScreenTools.largeFontPointSize
                }
            }            

            QGCMouseArea {
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                x:                  parent.mapFromItem(backIcon, backIcon.x, backIcon.y).x
                width:              backIcon.width //(backTextLabel.x + backTextLabel.width) - backIcon.x
                onClicked: {
                    toolDrawer.visible      = false
                }
            }
        }

        Loader {
            id:             toolDrawerLoader
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.top:    toolDrawerToolbar.bottom
            anchors.bottom: parent.bottom

            Connections {
                target:                 toolDrawerLoader.item
                ignoreUnknownSignals:   true
                onPopout:               toolDrawer.visible = false
            }
        }
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
            textFormat:         TextEdit.RichText
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                criticalVehicleMessagePopup.close()
                if (criticalVehicleMessagePopup.dropMessageIndicatorOnClose) {
                    criticalVehicleMessagePopup.dropMessageIndicatorOnClose = false;
                    QGroundControl.multiVehicleManager.activeVehicle.resetErrorLevelMessages();
                    flyView.dropMessageIndicatorTool();
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
        //indicatorDrawer.sourceComponent = drawerComponent
        //indicatorDrawer.open()
        componentDrawer.sourceComponent = drawerComponent
        componentDrawer.visible = true
    }

    function closeIndicatorDrawer() {
        indicatorDrawer.close()
    }

    Popup {
        id:             indicatorDrawer
        x:              calcXPosition()
        y:              ScreenTools.toolbarHeight + _margins
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
        property var indicatorItem

        property bool _expanded:    false
        property real _margins:     ScreenTools.defaultFontPixelHeight / 4

        function calcXPosition() {
            if (indicatorItem) {
                var xCenter = indicatorItem.mapToItem(mainWindow.contentItem, indicatorItem.width / 2, 0).x
                return Math.max(_margins, Math.min(xCenter - (contentItem.implicitWidth / 2), mainWindow.contentItem.width - contentItem.implicitWidth - _margins - (indicatorDrawer.padding * 2) - (ScreenTools.defaultFontPixelHeight / 2)))
            } else {
                return _margins
            }
        }

        onOpened: {
            _expanded                               = false;
            indicatorDrawerLoader.sourceComponent   = indicatorDrawer.sourceComponent
        }
        onClosed: {
            _expanded                               = false
            indicatorItem                           = undefined
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
                width:                      ScreenTools.defaultFontPixelHeight * 2
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
                    onClicked: {
                        indicatorDrawer._expanded = true
                    }
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
            } // loader
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

    Connections{
         target: activationbar
         function onActivationTriggered(value){
              _utmspSendActTrigger= value
         }
    }

    UTMSPActivationStatusBar{
         id:                         activationbar
         activationStartTimestamp:  _startTimeStamp
         activationApproval:        _showVisible && QGroundControl.utmspManager.utmspVehicle.vehicleActivation
         flightID:                  _flightID
         anchors.fill:              parent
    }
}