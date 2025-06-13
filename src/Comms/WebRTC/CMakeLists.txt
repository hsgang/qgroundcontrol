target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        WebRTCLink.cc
        WebRTCLink.h
)

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

CPMAddPackage(
  NAME libdatachannel
  GITHUB_REPOSITORY paullouisageneau/libdatachannel
  GIT_TAG master
  OPTIONS
    "NO_TESTS ON"
    "NO_EXAMPLES ON"
    "BUILD_SHARED_LIBS OFF"
)

target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE LibDataChannel::LibDataChannel)

find_package(Qt6 REQUIRED COMPONENTS WebSockets)

target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE Qt6::WebSockets)
