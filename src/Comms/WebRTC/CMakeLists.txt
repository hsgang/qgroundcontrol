target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        WebRTCLink.cc
        WebRTCLink.h
)

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

if(ANDROID)
  set(OPENSSL_ROOT_DIR ${android_openssl_SOURCE_DIR}/ssl_3/${CMAKE_ANDROID_ARCH_ABI})
  set(OPENSSL_INCLUDE_DIR ${OPENSSL_ROOT_DIR}/include)
endif()

set(LIBDATACHANNEL_OPTIONS
    "NO_TESTS ON"
    "NO_EXAMPLES ON"
    "BUILD_SHARED_LIBS OFF"
)

# CPMAddPackage 호출
if(ANDROID)
  CPMAddPackage(
    NAME libdatachannel
    GITHUB_REPOSITORY paullouisageneau/libdatachannel
    GIT_TAG master
    OPTIONS ${LIBDATACHANNEL_OPTIONS}
    PATCH_COMMAND ${CMAKE_COMMAND} -E echo "include_directories(${OPENSSL_INCLUDE_DIR})" >> ${CMAKE_CURRENT_BINARY_DIR}/cpm_modules/libdatachannel/deps/libsrtp/CMakeLists.txt
  )
else()
  CPMAddPackage(
    NAME libdatachannel
    GITHUB_REPOSITORY paullouisageneau/libdatachannel
    GIT_TAG master
    OPTIONS ${LIBDATACHANNEL_OPTIONS}
  )
endif()

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
