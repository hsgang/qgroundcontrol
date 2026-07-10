target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        WebRTCConfiguration.cc
        WebRTCConfiguration.h
        WebRTCLink.cc
        WebRTCLink.h
        SignalingServerManager.cc
        SignalingServerManager.h
        WebRTCStats.h
        WebRTCTypes.h
)

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

# The WebRTC receive path is built on GStreamer webrtcbin (transport + NACK/RTX +
# data channels), so it compiles only when GStreamer video streaming is enabled.
if(QGC_ENABLE_GST_VIDEOSTREAMING)
    target_sources(${CMAKE_PROJECT_NAME}
        PRIVATE
            WebRTCBinSession.cc
            WebRTCBinSession.h
    )
endif()

find_package(Qt6 REQUIRED COMPONENTS Network WebSockets)

target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE Qt6::Network Qt6::WebSockets)
