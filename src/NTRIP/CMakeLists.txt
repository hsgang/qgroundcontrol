find_package(Qt6 REQUIRED COMPONENTS Core Network Positioning)

qt_add_library(NTRIP STATIC
    NTRIPManager.cc
    NTRIPManager.h
    NTRIPTCPLink.cc
    NTRIPTCPLink.h
)

target_link_libraries(NTRIP
    PRIVATE
        Utilities
        Settings
    PUBLIC
        Qt6::Core
        Qt6::Network
        Qt6::Positioning
        QGC
        GPS
)

target_include_directories(NTRIP
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
)
