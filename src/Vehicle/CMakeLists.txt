find_package(Qt6 REQUIRED COMPONENTS Core Gui Positioning Qml)

qt_add_library(Vehicle STATIC
    Autotune.cpp
    Autotune.h
    FTPManager.cc
    FTPManager.h
    InitialConnectStateMachine.cc
    InitialConnectStateMachine.h
    MAVLinkLogManager.cc
    MAVLinkLogManager.h
    MultiVehicleManager.cc
    MultiVehicleManager.h
    RemoteIDManager.cc
    RemoteIDManager.h
    StandardModes.cc
    StandardModes.h
    TerrainProtocolHandler.cc
    TerrainProtocolHandler.h
    TrajectoryPoints.cc
    TrajectoryPoints.h
    Vehicle.cc
    Vehicle.h
    VehicleLinkManager.cc
    VehicleLinkManager.h
    VehicleObjectAvoidance.cc
    VehicleObjectAvoidance.h
    AtmosphericSensorFactGroup.cc
    AtmosphericSensorFactGroup.h
    VehicleEKFStatusFactGroup.cc
    VehicleEKFStatusFactGroup.h
    VehicleLandingTargetFactGroup.cc
    VehicleLandingTargetFactGroup.h
    WinchStatusFactGroup.cc
    WinchStatusFactGroup.h
    TunnelingDataFactGroup.cc
    TunnelingDataFactGroup.h
    GeneratorStatusFactGroup.cc
    GeneratorStatusFactGroup.h
    ExternalPowerStatusFactGroup.cc
    ExternalPowerStatusFactGroup.h
)

target_link_libraries(Vehicle
    PRIVATE
        Qt6::Qml
        ADSB
        API
        AutoPilotPlugins
        Camera
        Joystick
        MockLink
        PositionManager
        UTMSP
        VideoManager
        Gimbal
    PUBLIC
        Qt6::Core
        Qt6::Gui
        Qt6::Positioning
        Comms
        FactSystem
        FirmwarePlugin
        Gimbal
        MAVLink
        MissionManager
        Utilities
)

target_include_directories(Vehicle PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

add_subdirectory(Actuators)
add_subdirectory(ComponentInformation)
add_subdirectory(FactGroups)
