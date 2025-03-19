find_package(Qt6 REQUIRED COMPONENTS Core)

target_sources(QGC
    PRIVATE
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

target_link_libraries(QGC
    PUBLIC
        Qt6::Core
)

target_include_directories(QGC PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
