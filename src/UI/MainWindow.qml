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

import QGroundControl.Controls
import QGroundControl.FactControls

import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.VehicleSetup
import QGroundControl.AnalyzeView

/// @brief Native QML top level window
/// All properties defined here are visible to all QML pages.
ApplicationWindow {
    id:             mainWindow
    title:          QGroundControl.displayName
    visible:        true
    flags:          Qt.Window | (ScreenTools.isMobile ? (Qt.ExpandedClientAreaHint | Qt.NoTitleBarBackgroundHint) : 0)
    topPadding:     ScreenTools.isMobile ? 0 : undefined
    bottomPadding:  ScreenTools.isMobile ? 0 : undefined
    leftPadding:    ScreenTools.isMobile ? 0 : undefined
    rightPadding:   ScreenTools.isMobile ? 0 : undefined

    property bool   _utmspSendActTrigger

    Component.onCompleted: {
        // Start the sequence of first run prompt(s)
        firstRunPromptManager.nextPrompt()
    }

    /// Saves main window position and size and re-opens it in the same position and size next time
    MainWindowSavedState {
        window: mainWindow
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

        // Number of QGCTextField's with validation errors. Used to prevent closing panels with validation errors.
        property int                validationErrorCount:           0 

        // Property to manage RemoteID quick access to settings page
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

    // This function is used to prevent view switching if there are validation errors
    function allowViewSwitch(previousValidationErrorCount = 0) {
        // Run validation on active focus control to ensure it is valid before switching views
        if (mainWindow.activeFocusControl instanceof FactTextField) {
            mainWindow.activeFocusControl._onEditingFinished()
        }
        return globals.validationErrorCount <= previousValidationErrorCount
    }

    function viewSwitch(currentToolbar) {
        welcomeView.visible     = false
        flyView.visible         = false
        planView.visible        = false
        setupView.visible       = false
        analyzeView.visible     = false
        appSettings.visible     = false
        toolbar.currentToolbar  = currentToolbar
        viewer3DWindow.close()
    }

    function showFlyView() {
        if (!flyView.visible) {
            mainWindow.showPreFlightChecklistIfNeeded()
        }
        //mainWindow.popView()
        //viewSwitch(toolbar.flyViewToolbar)
        welcomeView.visible = false
        flyView.visible     = true
        planView.visible    = false
        setupView.visible   = false
        analyzeView.visible = false
        appSettings.visible = false
    }

    function showPlanView() {
        //viewSwitch(toolbar.planViewToolbar)
        welcomeView.visible = false
        flyView.visible     = false
        planView.visible    = true
        setupView.visible   = false
        analyzeView.visible = false
        appSettings.visible = false
    }

    function showAnalyzeTool() {
        //showTool(qsTr("Analyze Tools"), "AnalyzeView.qml", "/qmlimages/Analyze.svg")
        welcomeView.visible = false
        flyView.visible     = false
        planView.visible    = false
        setupView.visible   = false
        analyzeView.visible = true
        appSettings.visible = false
    }

    function showVehicleConfig() {
        //showTool(qsTr("Vehicle Configuration"), "SetupView.qml", "/qmlimages/Quad.svg")
        welcomeView.visible = false
        flyView.visible     = false
        planView.visible    = false
        setupView.visible   = true
        analyzeView.visible = false
        appSettings.visible = false
    }

    function showVehicleConfigParametersPage() {
        showVehicleConfig()
        //toolDrawerLoader.item.showParametersPanel()
        setupView.showParametersPanel()
    }

    function showKnownVehicleComponentConfigPage(knownVehicleComponent) {
        showVehicleConfig()
        let vehicleComponent = globals.activeVehicle.autopilotPlugin.findKnownVehicleComponent(knownVehicleComponent)
        if (vehicleComponent) {
            //toolDrawerLoader.item.showVehicleComponentPanel(vehicleComponent)
            setupView.showVehicleComponentPanel(vehicleComponent)
        }
    }

    function showAppSettings(settingsPage = "") {
        // showTool(qsTr("Application Settings"), "AppSettings.qml", "/qmlimages/Gears.svg")
        welcomeView.visible = false
        flyView.visible     = false
        planView.visible    = false
        analyzeView.visible = false
        setupView.visible   = false
        appSettings.visible = true
        if (settingsPage !== "") {
            //toolDrawerLoader.item.showSettingsPage(settingsPage)
            appSettings.showSettingsPage(settingsPage)
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

    function showMessageDialog(dialogTitle, dialogText, buttons = Dialog.Ok, acceptFunction = null, closeFunction = null) {
        simpleMessageDialogComponent.createObject(mainWindow, { title: dialogTitle, text: dialogText, buttons: buttons, acceptFunction: acceptFunction, closeFunction: closeFunction }).open()
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

    // Check for things which should prevent the app from closing
    //  Returns true if it is OK to close
    readonly property int _skipUnsavedMissionCheckMask: 0x01
    readonly property int _skipPendingParameterWritesCheckMask: 0x02
    readonly property int _skipActiveConnectionsCheckMask: 0x04
    property int _closeChecksToSkip: 0
    function performCloseChecks() {
        if (!(_closeChecksToSkip & _skipUnsavedMissionCheckMask) && !checkForUnsavedMission()) {
            return false
        }
        if (!(_closeChecksToSkip & _skipPendingParameterWritesCheckMask) && !checkForPendingParameterWrites()) {
            return false
        }
        if (!(_closeChecksToSkip & _skipActiveConnectionsCheckMask) && !checkForActiveConnections()) {
            return false
        }
        finishCloseProcess()
        return true
    }

    property string closeDialogTitle: qsTr("Close %1").arg(QGroundControl.appName)

    function checkForUnsavedMission() {
        if (planView._planMasterController.dirty) {
            mainWindow.showMessageDialog(closeDialogTitle,
                              qsTr("You have a mission edit in progress which has not been saved/sent. If you close you will lose changes. Are you sure you want to close?"),
                              Dialog.Yes | Dialog.No,
                              function() { _closeChecksToSkip |= _skipUnsavedMissionCheckMask; performCloseChecks() })
            return false
        } else {
            return true
        }
    }

    function checkForPendingParameterWrites() {
        for (var index=0; index<QGroundControl.multiVehicleManager.vehicles.count; index++) {
            if (QGroundControl.multiVehicleManager.vehicles.get(index).parameterManager.pendingWrites) {
                mainWindow.showMessageDialog(closeDialogTitle,
                    qsTr("You have pending parameter updates to a vehicle. If you close you will lose changes. Are you sure you want to close?"),
                    Dialog.Yes | Dialog.No,
                    function() { _closeChecksToSkip |= _skipPendingParameterWritesCheckMask; performCloseChecks() })
                return false
            }
        }
        return true
    }

    function checkForActiveConnections() {
        if (globals.activeVehicle) {
            mainWindow.showMessageDialog(closeDialogTitle,
                qsTr("There are still active connections to vehicles. Are you sure you want to exit?"),
                Dialog.Yes | Dialog.No,
                function() { _closeChecksToSkip |= _skipActiveConnectionsCheckMask; performCloseChecks() })
            return false
        } else {
            return true
        }
    }

    onClosing: (close) => {
        if (!_forceClose) {
            _closeChecksToSkip = 0
            close.accepted = performCloseChecks()
        }
    }

    background: Rectangle {
        anchors.fill:   parent
        color:          QGroundControl.globalPalette.window
    }

    WelcomeView {
        id:             welcomeView
        anchors.fill:   parent
    }

    FlyView { 
        id:                     flyView
        anchors.fill:           parent
    }

    PlanView {
        id:             planView
        anchors.fill:   parent
        visible:        false
    }

    SetupView{
        id:             setupView
        anchors.fill:   parent
        visible:        false
    }

    AnalyzeView{
        id:             analyzeView
        anchors.fill:   parent
        visible:        false
    }

    AppSettings{
        id:             appSettings
        anchors.fill:   parent
        visible:        false
    }

    function showToolSelectDialog() {
        if (mainWindow.allowViewSwitch()) {
            mainWindow.showIndicatorDrawer(toolSelectComponent, null)
        }
    }

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
        leftPadding:    0

        property var    _mainWindow:       mainWindow
        property real   _toolButtonHeight: ScreenTools.defaultFontPixelHeight * 3

        Rectangle {
            id:     mainLayoutRect
            anchors.top: parent.top
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
                    anchors.margins:    ScreenTools.defaultFontPixelHeight / 2
                    anchors.left:       parent.left
                    anchors.top:        parent.top
                    spacing:            ScreenTools.defaultFontPixelHeight / 2

                    SettingsButton {
                        id:                 flyButton
                        height:             ScreenTools.defaultFontPixelHeight * 3
                        Layout.fillWidth:   true
                        text:               qsTr("Fly View")
                        icon.source:        "/qmlimages/PaperPlane.svg"
                        onClicked: {
                            if (mainWindow.allowViewSwitch()) {
                                mainWindow.closeIndicatorDrawer()
                                toolDrawer.visible = false
                                mainWindow.showFlyView()
                                checkedMenu()
                                flyButton.checked = true
                                viewSelectDrawer.visible = false
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height : 1
                        color : qgcPal.groupBorder
                    }

                    SettingsButton {
                        id:                 planButton
                        height:             ScreenTools.defaultFontPixelHeight * 3
                        Layout.fillWidth:   true
                        text:               qsTr("Plan View")
                        icon.source:        "/qmlimages/Plan.svg"
                        onClicked: {
                            if (mainWindow.allowViewSwitch()) {
                                mainWindow.closeIndicatorDrawer()
                                toolDrawer.visible = false
                                mainWindow.showPlanView()
                                checkedMenu()
                                planButton.checked = true
                                viewSelectDrawer.visible = false
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height : 1
                        color : qgcPal.groupBorder
                    }

                    SettingsButton {
                        id:                 setupButton
                        height:             ScreenTools.defaultFontPixelHeight * 3
                        Layout.fillWidth:   true
                        text:               qsTr("Vehicle Configuration")
                        icon.source:        "/qmlimages/Quad.svg"
                        onClicked: {
                            if (mainWindow.allowViewSwitch()) {
                                mainWindow.closeIndicatorDrawer()
                                toolDrawer.visible = false
                                mainWindow.showVehicleConfig()
                                checkedMenu()
                                setupButton.checked = true
                                viewSelectDrawer.visible = false
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height : 1
                        color : qgcPal.groupBorder
                    }

                    SettingsButton {
                        id:                 analyzeButton
                        height:             ScreenTools.defaultFontPixelHeight * 3
                        Layout.fillWidth:   true
                        text:               qsTr("Analyze Tools")
                        icon.source:        "/qmlimages/Analyze.svg"
                        visible:            QGroundControl.corePlugin.showAdvancedUI
                        onClicked: {
                            if (mainWindow.allowViewSwitch()) {
                                mainWindow.closeIndicatorDrawer()
                                toolDrawer.visible = false
                                mainWindow.showAnalyzeTool()
                                checkedMenu()
                                analyzeButton.checked = true
                                viewSelectDrawer.visible = false
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height : 1
                        color : qgcPal.groupBorder
                    }

                    SettingsButton {
                        id:                 settingsButton
                        height:             ScreenTools.defaultFontPixelHeight * 3
                        Layout.fillWidth:   true
                        text:               qsTr("App Settings")
                        icon.source:        "/qmlimages/Gears.svg"
                        visible:            !QGroundControl.corePlugin.options.combineSettingsAndSetup
                        onClicked: {
                            if (mainWindow.allowViewSwitch()) {
                                mainWindow.closeIndicatorDrawer()
                                toolDrawer.visible = false
                                mainWindow.showAppSettings()
                                checkedMenu()
                                settingsButton.checked = true
                                viewSelectDrawer.visible = false
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height : 1
                        color : qgcPal.groupBorder
                        visible : closeButton.visible
                    }

                    SettingsButton {
                        id:                 closeButton
                        height:             ScreenTools.defaultFontPixelHeight * 3
                        Layout.fillWidth:   true
                        text:               "종료"
                        icon.source:        "/InstrumentValueIcons/close.svg"
                        visible:            mainWindow.visibility === Window.FullScreen
                        onClicked: {
                            if (mainWindow.allowViewSwitch()) {
                                mainWindow.showMessageDialog(closeDialogTitle,
                                                  qsTr("Are you sure you want to close?"),
                                                  Dialog.Yes | Dialog.No,
                                                  function() { performCloseChecks() })
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
                }

                QGCLabel {
                    text:                   QGroundControl.qgcAppDate
                    font.pointSize:         ScreenTools.smallFontPointSize
                    wrapMode:               QGCLabel.WrapAnywhere
                    Layout.maximumWidth:    parent.width
                    Layout.alignment:       Qt.AlignHCenter
                    visible:                QGroundControl.qgcDailyBuild

                    QGCMouseArea {
                        id:                 easterEggMouseArea
                        anchors.topMargin:  -versionLabel.height
                        anchors.fill:       parent

                        onClicked: (mouse) => {
                            if (mouse.modifiers & Qt.ControlModifier) {
                                QGroundControl.corePlugin.showTouchAreas = !QGroundControl.corePlugin.showTouchAreas
                                showTouchAreasNotification.open()
                            } else if (ScreenTools.isMobile || mouse.modifiers & Qt.ShiftModifier) {
                                mainWindow.closeIndicatorDrawer()
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

                                // This allows you to change this on mobile
                                onPressAndHold: {
                                    QGroundControl.corePlugin.showTouchAreas = !QGroundControl.corePlugin.showTouchAreas
                                    showTouchAreasNotification.open()
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
        id:             toolDrawer
        height:         mainWindow.height
        width:          mainWindow.width
        edge:           Qt.LeftEdge
        dragMargin:     0
        closePolicy:    Drawer.NoAutoClose
        interactive:    false
        visible:        false

        property var backIcon
        property string toolTitle:  toolbarDrawerText.text
        property alias toolSource:  toolDrawerLoader.source
        property var toolIcon

        onVisibleChanged: {
            if (!toolDrawer.visible) {
                toolDrawerLoader.source = ""
            }
        }

        // This need to block click event leakage to underlying map.
        DeadMouseArea {
            anchors.fill: parent
        }

        Rectangle {
            id:             toolDrawerToolbar
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.top:    parent.top
            height:         ScreenTools.toolbarHeight
            color:          qgcPal.toolbarBackground

            RowLayout {
                id:                 toolDrawerToolbarLayout
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
                    text:           toolDrawer.toolTitle
                    font.pointSize: ScreenTools.largeFontPointSize
                }
            }

            QGCMouseArea {
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                x:                  parent.mapFromItem(backIcon, backIcon.x, backIcon.y).x
                width:              backIcon.width //(backTextLabel.x + backTextLabel.width) - backIcon.x
                onClicked: {
                    if (mainWindow.allowViewSwitch()) {
                        toolDrawer.visible = false
                    }
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
                function onPopout() { toolDrawer.visible = false }
            }
        }
    }

    //-------------------------------------------------------------------------
    //-- Critical Vehicle Message Popup

    function showCriticalVehicleMessage(message) {
        closeIndicatorDrawer()
        if (criticalVehicleMessagePopup.visible || QGroundControl.videoManager.fullScreen) {
            // We received additional warning message while an older warning message was still displayed.
            // When the user close the older one drop the message indicator tool so they can see the rest of them.
            criticalVehicleMessagePopup.additionalCriticalMessagesReceived = true
        } else {
            criticalVehicleMessagePopup.criticalVehicleMessage      = message
            criticalVehicleMessagePopup.additionalCriticalMessagesReceived = false
            criticalVehicleMessagePopup.open()
        }
    }

    Popup {
        id:                 criticalVehicleMessagePopup
        y:                  ScreenTools.toolbarHeight + ScreenTools.defaultFontPixelHeight
        x:                  Math.round((mainWindow.width - width) * 0.5)
        width:              mainWindow.width  * 0.55
        height:             criticalVehicleMessageText.contentHeight + ScreenTools.defaultFontPixelHeight * 2
        modal:              false
        focus:              true

        property alias  criticalVehicleMessage:             criticalVehicleMessageText.text
        property bool   additionalCriticalMessagesReceived: false

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
                visible:                    criticalVehicleMessagePopup.additionalCriticalMessagesReceived

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
                if (criticalVehicleMessagePopup.additionalCriticalMessagesReceived) {
                    criticalVehicleMessagePopup.additionalCriticalMessagesReceived = false;
                    flyView.dropMainStatusIndicatorTool();
                } else {
                    QGroundControl.multiVehicleManager.activeVehicle.resetErrorLevelMessages();
                }
            }
        }
    }

    //-------------------------------------------------------------------------
    //-- Indicator Drawer

    function showIndicatorDrawer(drawerComponent, indicatorItem) {
        indicatorDrawer.sourceComponent = drawerComponent
        indicatorDrawer.indicatorItem = indicatorItem
        indicatorDrawer.open()
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
        padding:        _margins
        visible:        false
        modal:          false
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
                color:          QGroundControl.globalPalette.window
                radius:         indicatorDrawer._margins
                opacity:        0.85
                border.color:   qgcPal.groupBorder
                border.width:   1
            }

            Rectangle {
                anchors.horizontalCenter:   backgroundRect.right
                anchors.verticalCenter:     backgroundRect.top
                width:                      ScreenTools.largeFontPixelHeight
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
            implicitHeight: Math.min(mainWindow.contentItem.height - ScreenTools.toolbarHeight - (2 * indicatorDrawer._margins) - (indicatorDrawer.padding * 2), indicatorDrawerLoader.height)
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
