find_package(Qt6 REQUIRED COMPONENTS Core Positioning Test)

qt_add_library(GeoTest
    STATIC
        GeoTest.cc
        GeoTest.h
)

target_link_libraries(GeoTest
    PRIVATE
        Qt6::Positioning
        Qt6::Test
        Geo
    PUBLIC
        qgcunittest
)

target_include_directories(GeoTest PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
