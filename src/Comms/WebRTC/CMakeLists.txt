target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        WebRTCLink.cc
        WebRTCLink.h
)

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

set(LIBDATACHANNEL_OPTIONS
    "NO_TESTS ON"
    "NO_EXAMPLES ON"
    "BUILD_SHARED_LIBS OFF"
)

if(ANDROID)
  list(APPEND LIBDATACHANNEL_OPTIONS "USE_OPENSSL ON")
  list(APPEND LIBDATACHANNEL_OPTIONS "OPENSSL_ROOT_DIR=${android_openssl_SOURCE_DIR}/ssl_3/${CMAKE_ANDROID_ARCH_ABI}")
endif()

CPMAddPackage(
  NAME libdatachannel
  GITHUB_REPOSITORY paullouisageneau/libdatachannel
  GIT_TAG master
  OPTIONS ${LIBDATACHANNEL_OPTIONS}
)

# CPMAddPackage(
#   NAME libdatachannel
#   GITHUB_REPOSITORY paullouisageneau/libdatachannel
#   GIT_TAG master
#   OPTIONS
#     "NO_TESTS ON"
#     "NO_EXAMPLES ON"
#     "BUILD_SHARED_LIBS OFF"
# )

target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE LibDataChannel::LibDataChannel)

find_package(Qt6 REQUIRED COMPONENTS WebSockets)

target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE Qt6::WebSockets)
