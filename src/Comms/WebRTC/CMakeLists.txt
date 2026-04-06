target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        WebRTCConfiguration.cc
        WebRTCConfiguration.h
        WebRTCWorker.cc
        WebRTCWorker.h
        WebRTCLink.cc
        WebRTCLink.h
        SignalingServerManager.cc
        SignalingServerManager.h
        WebRTCStats.h
)

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

if(ANDROID)
  set(OPENSSL_ROOT_DIR ${android_openssl_SOURCE_DIR}/ssl_3/${CMAKE_ANDROID_ARCH_ABI})
  set(OPENSSL_INCLUDE_DIR ${OPENSSL_ROOT_DIR}/include)
  set(OPENSSL_CRYPTO_LIBRARY ${OPENSSL_ROOT_DIR}/lib/libcrypto.a)
  set(OPENSSL_SSL_LIBRARY ${OPENSSL_ROOT_DIR}/lib/libssl.a)
  # Prevent NDK's prebuilt x86_64 libunwind.so from being linked into ARM64 builds
  set(OPENSSL_USE_STATIC_LIBS TRUE)
endif()

set(LIBDATACHANNEL_OPTIONS
    "NO_TESTS ON"
    "NO_EXAMPLES ON"
    "BUILD_SHARED_LIBS OFF"
    "CMAKE_BUILD_TYPE=Release"
)

# CPMAddPackage 호출
if(ANDROID)
  CPMAddPackage(
    NAME libdatachannel
    GITHUB_REPOSITORY paullouisageneau/libdatachannel
    GIT_TAG v0.24.1
    OPTIONS ${LIBDATACHANNEL_OPTIONS}
        "OPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR}"
        "OPENSSL_INCLUDE_DIR=${OPENSSL_INCLUDE_DIR}"
        "OPENSSL_CRYPTO_LIBRARY=${OPENSSL_CRYPTO_LIBRARY}"
        "OPENSSL_SSL_LIBRARY=${OPENSSL_SSL_LIBRARY}"
        "OPENSSL_USE_STATIC_LIBS=TRUE"
        "NO_MEDIA=ON"
    PATCH_COMMAND ${CMAKE_COMMAND} -E echo "include_directories(${OPENSSL_INCLUDE_DIR})" >> ${CMAKE_CURRENT_BINARY_DIR}/cpm_modules/libdatachannel/deps/libsrtp/CMakeLists.txt
  )
  # Prevent NDK prebuilt x86_64 libunwind.so from leaking into ARM64 link
  if(TARGET datachannel-static)
    get_target_property(_dc_libs datachannel-static INTERFACE_LINK_LIBRARIES)
    if(_dc_libs)
      list(FILTER _dc_libs EXCLUDE REGEX "libunwind")
      set_target_properties(datachannel-static PROPERTIES INTERFACE_LINK_LIBRARIES "${_dc_libs}")
    endif()
  endif()
else()
  CPMAddPackage(
    NAME libdatachannel
    GITHUB_REPOSITORY paullouisageneau/libdatachannel
    GIT_TAG v0.24.1
    GIT_SHALLOW TRUE
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

foreach(dep_target usrsctp srtp2 juice)
    if(TARGET ${dep_target})
        qgc_disable_dependency_warnings(${dep_target})
    endif()
endforeach()

# Android: rename libjuice's tcp_create_socket to avoid duplicate symbol
# with GStreamer's static libgsttcp.a (desktop uses shared GStreamer, no conflict)
if(ANDROID)
    if(TARGET juice)
        target_compile_definitions(juice PRIVATE tcp_create_socket=juice_tcp_create_socket)
    endif()
    if(TARGET juice-static)
        target_compile_definitions(juice-static PRIVATE tcp_create_socket=juice_tcp_create_socket)
    endif()
endif()

target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE LibDataChannel::LibDataChannel)

find_package(Qt6 REQUIRED COMPONENTS Network WebSockets)

target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE Qt6::Network Qt6::WebSockets)
