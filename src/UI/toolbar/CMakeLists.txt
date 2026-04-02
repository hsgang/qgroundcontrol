qt_add_library(ToolbarModule STATIC)

qt_add_qml_module(ToolbarModule
    URI QGroundControl.Toolbar
    VERSION 1.0
    RESOURCE_PREFIX /qml
    QML_FILES
        APMBatteryIndicator.qml
        APMFlightModeIndicator.qml
        ArmedIndicator.qml
        BatteryIndicator.qml
        BatteryIndicatorPage.qml
        EscIndicator.qml
        EscIndicatorPage.qml
        FlightModeIndicator.qml
        FlightModeMenuIndicator.qml
        FlightModeToolIndicatorContentItem.qml
        FlyViewToolBar.qml
        FlyViewToolBarIndicators.qml
        GCSControlIndicator.qml
        GimbalIndicator.qml
        GPS2Indicator.qml
        GPSIndicator.qml
        GPSIndicatorPage.qml
        GPSResilienceIndicator.qml
        GPSRTKIndicator.qml
        JoystickIndicator.qml
        MainStatusIndicator.qml
        MainStatusIndicatorOfflinePage.qml
        MessageIndicator.qml
        ModeIndicator.qml
        MultiVehicleSelector.qml
        ParameterDownloadProgress.qml
        PlanViewToolBar.qml
        PrecisionLandingIndicator.qml
        RCRSSIIndicator.qml
        RemoteIDIndicator.qml
        RemoteIDIndicatorPage.qml
        RTKGPSIndicator.qml
        SelectViewDropdown.qml
        SignalStrength.qml
        SiyiRSSIIndicator.qml
        LinkIndicator.qml
        TelemetryRSSIIndicator.qml
        VehicleGPSIndicator.qml
        VehicleIndicator.qml
        VehicleIndicatorPage.qml
        VehicleMessageList.qml
        WEBRTCIndicator.qml
        WidgetControlPanel.qml
    NO_PLUGIN
)
