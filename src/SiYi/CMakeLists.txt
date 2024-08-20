find_package(Qt6 REQUIRED COMPONENTS Core Network)

qt_add_library(SiYi STATIC
    SiYi.cc
    SiYi.h
    SiYiCamera.cc
    SiYiCamera.h
    SiYiCrcApi.cc
    SiYiCrcApi.h
    SiYiTcpClient.cc
    SiYiTcpClient.h
    SiYiTransmitter.cc
    SiYiTransmitter.h
)

target_link_libraries(SiYi
    PRIVATE
        Qt6::Widgets
        Utilities
    PUBLIC
        Qt6::Core
        Qt6::Network
        QGC
)

target_include_directories(SiYi PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
