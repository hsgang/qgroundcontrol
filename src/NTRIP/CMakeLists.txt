find_package(Qt6 REQUIRED COMPONENTS Core)

qt_add_library(NTRIP STATIC
    NTRIP.cc
    NTRIP.h
)

target_link_libraries(NTRIP
    PUBLIC
        Qt6::Core
        Qt6::Network
        QGC
        GPS
)

target_include_directories(NTRIP
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
)
