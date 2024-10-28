find_package(Qt6 REQUIRED COMPONENTS Core Network Positioning)

qt_add_library(NTRIP STATIC
    NTRIPManager.cc
    NTRIPManager.h
    NTRIPTCPLink.cc
    NTRIPTCPLink.h
)

target_link_libraries(NTRIP
    PRIVATE
        QGC
        Utilities
        Settings
    PUBLIC
        Qt6::Core
        Qt6::Network
        Qt6::Positioning
        GPS
	GPSDrivers
)

target_include_directories(NTRIP
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
	${px4-gpsdrivers_SOURCE_DIR}/src
)
