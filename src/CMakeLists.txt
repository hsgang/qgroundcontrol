qt_add_library(QGroundControlModule STATIC)

qt_add_qml_module(QGroundControlModule
    URI QGroundControl
    VERSION 1.0
    RESOURCE_PREFIX /qml
    IMPORTS
        QGC
    NO_PLUGIN
)

add_subdirectory(ADSB)
add_subdirectory(AnalyzeView)
add_subdirectory(Android)
add_subdirectory(API)
add_subdirectory(AutoPilotPlugins)
add_subdirectory(Camera)
add_subdirectory(Comms)
add_subdirectory(FactSystem)
add_subdirectory(FirmwarePlugin)
add_subdirectory(FlightDisplay)
add_subdirectory(FlightMap)
add_subdirectory(FollowMe)
add_subdirectory(Gimbal)
add_subdirectory(GPS)
add_subdirectory(Joystick)
add_subdirectory(MAVLink)
add_subdirectory(MissionManager)
add_subdirectory(NTRIP)
add_subdirectory(PositionManager)
add_subdirectory(QmlControls)
add_subdirectory(Settings)
add_subdirectory(SiYi)
add_subdirectory(Terrain)
add_subdirectory(UI)
add_subdirectory(Utilities)
add_subdirectory(UTMSP)
add_subdirectory(Vehicle)
add_subdirectory(VideoManager)
add_subdirectory(Viewer3D)

add_subdirectory(QtLocationPlugin)

target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        main.cc
        CmdLineOptParser.cc
        CmdLineOptParser.h
        pch.h
        QGCApplication.cc
        QGCApplication.h
)

if(NOT ANDROID AND NOT IOS)
    target_sources(${CMAKE_PROJECT_NAME}
        PRIVATE
            RunGuard.cc
            RunGuard.h
    )
endif()

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(${CMAKE_PROJECT_NAME}
    PRIVATE
        Qt6::Charts
        Qt6::Concurrent
        Qt6::Core
        Qt6::Core5Compat
        Qt6::CorePrivate
        Qt6::Gui
        Qt6::Location
        Qt6::LocationPrivate
        Qt6::Multimedia
        Qt6::MultimediaQuickPrivate
        Qt6::Network
        Qt6::Positioning
        Qt6::PositioningPrivate
        Qt6::Qml
        Qt6::QmlIntegration
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Sensors
        Qt6::Svg
        Qt6::TextToSpeech
        Qt6::Widgets
        Qt6::Xml
        # Explicitly link QML modules, needed by Qt 6.6.3
        # TODO: Remove when support for this version is dropped
        AnalyzeViewModule
        AppSettingsModule
        AutoPilotPluginsCommonModule
        FactControlsModule
        FirstRunPromptDialogsModule
        FlightDisplayModule
        FlightMapModule
        MainWindowModule
        QGroundControlControlsModule
        QGroundControlModule
        ScreenToolsModule
        ToolbarModule
        UTMSPModule
        VehicleSetupModule
)

if(NOT QGC_DISABLE_APM_PLUGIN AND NOT QGC_DISABLE_APM_PLUGIN_FACTORY)
    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE AutoPilotPluginsAPMModule)
endif()
if(NOT QGC_DISABLE_PX4_PLUGIN AND NOT QGC_DISABLE_PX4_PLUGIN_FACTORY)
    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE AutoPilotPluginsPX4Module)
endif()
if(QGC_VIEWER3D)
    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE Viewer3DModule)
endif()
if(NOT QGC_AIRLINK_DISABLED)
    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE AirLinkModule)
endif()

target_compile_definitions(${CMAKE_PROJECT_NAME}
    PRIVATE
        QGC_APP_NAME="${QGC_APP_NAME}"
        QGC_ORG_NAME="${QGC_ORG_NAME}"
        QGC_ORG_DOMAIN="${QGC_ORG_DOMAIN}"
        QGC_APP_VERSION_STR="${QGC_APP_VERSION_STR}"
        QGC_SETTINGS_VERSION=${QGC_SETTINGS_VERSION}
        $<$<NOT:$<BOOL:${QGC_STABLE_BUILD}>>:QGC_DAILY_BUILD>
        $<$<BOOL:${QGC_DISABLE_APM_MAVLINK}>:QGC_NO_ARDUPILOT_DIALECT>
)

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_compile_definitions(${CMAKE_PROJECT_NAME}
        PRIVATE
            NDEBUG
            QT_NO_DEBUG
            QT_MESSAGELOGCONTEXT
    )
else()
    target_compile_definitions(${CMAKE_PROJECT_NAME}
        PRIVATE
            QT_DISABLE_DEPRECATED_UP_TO=0x060800
            QT_ENABLE_STRICT_MODE_UP_TO=0x060800
            $<$<BOOL:${QGC_DEBUG_QML}>:QT_QML_DEBUG>
    )
endif()

set_target_properties(${CMAKE_PROJECT_NAME}
    PROPERTIES
        QT_RESOURCE_PREFIX "/qml"
        OUTPUT_NAME ${CMAKE_PROJECT_NAME}
)

target_precompile_headers(${CMAKE_PROJECT_NAME} PRIVATE pch.h)

if(QGC_CUSTOM_BUILD)
    find_package(Qt6 REQUIRED COMPONENTS ${CUSTOM_QT_COMPONENTS})
    target_sources(${CMAKE_PROJECT_NAME} PRIVATE ${CUSTOM_SOURCES})
    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE ${CUSTOM_LIBRARIES})
    target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${CUSTOM_INCLUDE_DIRECTORIES})
    target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE ${CUSTOM_DEFINITIONS})
endif()
