find_package(Qt6 REQUIRED COMPONENTS Core Network)

target_sources(${CMAKE_PROJECT_NAME}
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
        SiYiUniRC.cc
        SiYiUniRC.h
)

target_link_libraries(${CMAKE_PROJECT_NAME}
    PUBLIC
        Qt6::Core
        Qt6::Network
)

target_include_directories(${CMAKE_PROJECT_NAME} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
