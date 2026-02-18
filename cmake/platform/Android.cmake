# ----------------------------------------------------------------------------
# QGroundControl Android Platform Configuration
# ----------------------------------------------------------------------------

if(NOT ANDROID)
    message(FATAL_ERROR "QGC: Invalid Platform: Android.cmake included but platform is not Android")
endif()

# ----------------------------------------------------------------------------
# Android NDK Version Validation
# ----------------------------------------------------------------------------
# CMAKE_ANDROID_NDK_VERSION format varies: "27.2" or "27.2.12829759"
# Extract major.minor from ndk_full_version for reliable comparison
if(DEFINED QGC_CONFIG_NDK_FULL_VERSION AND Qt6_VERSION VERSION_GREATER_EQUAL "${QGC_CONFIG_QT_MINIMUM_VERSION}")
    string(REGEX MATCH "^([0-9]+\\.[0-9]+)" _ndk_major_minor "${QGC_CONFIG_NDK_FULL_VERSION}")
    if(_ndk_major_minor AND NOT CMAKE_ANDROID_NDK_VERSION VERSION_GREATER_EQUAL "${_ndk_major_minor}")
        message(FATAL_ERROR "QGC: NDK ${CMAKE_ANDROID_NDK_VERSION} is too old. Qt ${Qt6_VERSION} requires NDK ${_ndk_major_minor}+ (${QGC_CONFIG_NDK_VERSION})")
    endif()
    unset(_ndk_major_minor)
endif()

# ----------------------------------------------------------------------------
# Android Version Number Validation
# ----------------------------------------------------------------------------

# Generation of Android version numbers must be consistent release to release
# to ensure they are always increasing for Google Play Store
if(CMAKE_PROJECT_VERSION_MAJOR GREATER 9)
    message(FATAL_ERROR "QGC: Major version must be single digit (0-9), got: ${CMAKE_PROJECT_VERSION_MAJOR}")
endif()
if(CMAKE_PROJECT_VERSION_MINOR GREATER 9)
    message(FATAL_ERROR "QGC: Minor version must be single digit (0-9), got: ${CMAKE_PROJECT_VERSION_MINOR}")
endif()
if(CMAKE_PROJECT_VERSION_PATCH GREATER 99)
    message(FATAL_ERROR "QGC: Patch version must be two digits (0-99), got: ${CMAKE_PROJECT_VERSION_PATCH}")
endif()

# ----------------------------------------------------------------------------
# Android ABI to Bitness Code Mapping
# ----------------------------------------------------------------------------
# NOTE: Bitness codes are 66/34 instead of 64/32 due to a historical
# version number bump requirement from an earlier Android release
set(ANDROID_BITNESS_CODE)
if(CMAKE_ANDROID_ARCH_ABI STREQUAL "armeabi-v7a" OR CMAKE_ANDROID_ARCH_ABI STREQUAL "x86")
    set(ANDROID_BITNESS_CODE 34)
elseif(CMAKE_ANDROID_ARCH_ABI STREQUAL "arm64-v8a" OR CMAKE_ANDROID_ARCH_ABI STREQUAL "x86_64")
    set(ANDROID_BITNESS_CODE 66)
else()
    message(FATAL_ERROR "QGC: Unsupported Android ABI: ${CMAKE_ANDROID_ARCH_ABI}. Supported: armeabi-v7a, arm64-v8a, x86, x86_64")
endif()

# ----------------------------------------------------------------------------
# Android Version Code Generation
# ----------------------------------------------------------------------------
# Zero-pad patch version if less than 10
set(ANDROID_PATCH_VERSION ${CMAKE_PROJECT_VERSION_PATCH})
if(CMAKE_PROJECT_VERSION_PATCH LESS 10)
    set(ANDROID_PATCH_VERSION "0${CMAKE_PROJECT_VERSION_PATCH}")
endif()

# Version code format: BBMIPPDDD (B=Bitness, M=Major, I=Minor, P=Patch, D=Dev) - Dev not currently supported and always 000
set(ANDROID_VERSION_CODE "${ANDROID_BITNESS_CODE}${CMAKE_PROJECT_VERSION_MAJOR}${CMAKE_PROJECT_VERSION_MINOR}${ANDROID_PATCH_VERSION}000")
message(STATUS "QGC: Android version code: ${ANDROID_VERSION_CODE}")

set_target_properties(${CMAKE_PROJECT_NAME}
    PROPERTIES
        # QT_ANDROID_ABIS ${CMAKE_ANDROID_ARCH_ABI}
        # QT_ANDROID_SDK_BUILD_TOOLS_REVISION
        QT_ANDROID_MIN_SDK_VERSION ${QGC_QT_ANDROID_MIN_SDK_VERSION}
        QT_ANDROID_TARGET_SDK_VERSION ${QGC_QT_ANDROID_TARGET_SDK_VERSION}
        QT_ANDROID_COMPILE_SDK_VERSION ${QGC_QT_ANDROID_COMPILE_SDK_VERSION}
        QT_ANDROID_PACKAGE_NAME "${QGC_ANDROID_PACKAGE_NAME}"
        QT_ANDROID_PACKAGE_SOURCE_DIR "${QGC_ANDROID_PACKAGE_SOURCE_DIR}"
        QT_ANDROID_VERSION_NAME "${CMAKE_PROJECT_VERSION}"
        QT_ANDROID_VERSION_CODE ${ANDROID_VERSION_CODE}
        QT_ANDROID_APP_NAME "AMC"
        QT_ANDROID_APP_ICON "@drawable/icon"
        # QT_QML_IMPORT_PATH
        QT_QML_ROOT_PATH "${CMAKE_SOURCE_DIR}"
        # QT_ANDROID_SYSTEM_LIBS_PREFIX
)

# if(CMAKE_BUILD_TYPE STREQUAL "Debug")
#     set(QT_ANDROID_APPLICATION_ARGUMENTS)
# endif()

list(APPEND QT_ANDROID_MULTI_ABI_FORWARD_VARS QGC_STABLE_BUILD QT_HOST_PATH)

# ----------------------------------------------------------------------------
# Workaround: Qt 6.10.x androiddeployqt dependency resolution failure
# androiddeployqt fails to resolve libQt6Core for arm64-v8a, causing all
# Qt libraries/plugins to be skipped from the APK.
# Strategy: Copy Qt .so files directly into a jniLibs directory that Gradle
# picks up (configured via build.gradle jniLibs.srcDirs = ['libs', '../qt_libs']).
# This completely bypasses androiddeployqt's broken dependency validation.
# Jar files are still set via QT_ANDROID_DEPLOYMENT_DEPENDENCIES for Java compilation.
# ----------------------------------------------------------------------------
set(_qt_prefix "${QT6_INSTALL_PREFIX}")
set(_abi "${CMAKE_ANDROID_ARCH_ABI}")
set(_qt_jnilib_dir "${CMAKE_BINARY_DIR}/qt_libs/${_abi}")

file(MAKE_DIRECTORY "${_qt_jnilib_dir}")

# Collect all Qt native libraries, plugins, and QML plugins
file(GLOB _qt_libs "${_qt_prefix}/lib/libQt6*_${_abi}.so")
file(GLOB_RECURSE _qt_plugins "${_qt_prefix}/plugins/*_${_abi}.so")
file(GLOB_RECURSE _qt_qml_plugins "${_qt_prefix}/qml/*_${_abi}.so")

set(_qt_all_so ${_qt_libs} ${_qt_plugins} ${_qt_qml_plugins})

# Exclude FFmpeg multimedia plugin (QGC uses GStreamer; FFmpeg has unresolvable deps)
list(FILTER _qt_all_so EXCLUDE REGEX "ffmpegmediaplugin")

# Copy all Qt .so files into qt_libs/${ABI}/ for Gradle to include in APK
file(COPY ${_qt_all_so} DESTINATION "${_qt_jnilib_dir}")

list(LENGTH _qt_all_so _qt_so_count)
message(STATUS "QGC: Copied ${_qt_so_count} Qt libraries to qt_libs/${_abi}/ (bypassing androiddeployqt)")

# Set QT_ANDROID_DEPLOYMENT_DEPENDENCIES with both .so and jar files.
# The .so entries prevent androiddeployqt from failing with "No platform plugin" error.
# Even though androiddeployqt Skips most .so files, the actual inclusion comes from qt_libs/.
file(GLOB _qt_jars "${_qt_prefix}/jar/*.jar")

set(_qt_all_deps ${_qt_all_so} ${_qt_jars})
set(_qt_deploy_deps "")
foreach(_dep IN LISTS _qt_all_deps)
    file(RELATIVE_PATH _rel "${_qt_prefix}" "${_dep}")
    list(APPEND _qt_deploy_deps "${_rel}")
endforeach()

list(LENGTH _qt_deploy_deps _deploy_count)
if(_deploy_count GREATER 0)
    set_property(TARGET ${CMAKE_PROJECT_NAME} PROPERTY QT_ANDROID_DEPLOYMENT_DEPENDENCIES "${_qt_deploy_deps}")
    message(STATUS "QGC: Set ${_deploy_count} deployment dependencies (${_qt_so_count} .so + jars)")
endif()

unset(_qt_prefix)
unset(_abi)
unset(_qt_jnilib_dir)
unset(_qt_libs)
unset(_qt_plugins)
unset(_qt_qml_plugins)
unset(_qt_all_so)
unset(_qt_so_count)
unset(_qt_jars)
unset(_qt_all_deps)
unset(_qt_deploy_deps)
unset(_deploy_count)

# ----------------------------------------------------------------------------
# Android OpenSSL Libraries
# ----------------------------------------------------------------------------
CPMAddPackage(
    NAME android_openssl
    GITHUB_REPOSITORY KDAB/android_openssl
    GIT_TAG b71f1470962019bd89534a2919f5925f93bc5779
)

if(android_openssl_ADDED)
    include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)
    add_android_openssl_libraries(${CMAKE_PROJECT_NAME})
    message(STATUS "QGC: Android OpenSSL libraries added")
else()
    message(WARNING "QGC: Failed to add Android OpenSSL libraries")
endif()

# ----------------------------------------------------------------------------
# Android Permissions
# ----------------------------------------------------------------------------

if(QGC_ENABLE_BLUETOOTH)
    qt_add_android_permission(${CMAKE_PROJECT_NAME}
        NAME android.permission.BLUETOOTH_SCAN
        ATTRIBUTES
            minSdkVersion 31
            usesPermissionFlags neverForLocation
    )
    qt_add_android_permission(${CMAKE_PROJECT_NAME}
        NAME android.permission.BLUETOOTH_CONNECT
        ATTRIBUTES
            minSdkVersion 31
            usesPermissionFlags neverForLocation
    )
endif()

if(NOT QGC_NO_SERIAL_LINK)
    qt_add_android_permission(${CMAKE_PROJECT_NAME}
        NAME android.permission.USB_PERMISSION
    )
endif()

# Need MulticastLock to receive broadcast UDP packets
qt_add_android_permission(${CMAKE_PROJECT_NAME}
    NAME android.permission.CHANGE_WIFI_MULTICAST_STATE
)

# Needed to keep working while 'asleep'
qt_add_android_permission(${CMAKE_PROJECT_NAME}
    NAME android.permission.WAKE_LOCK
)

# Needed for read/write to SD Card Path in AppSettings
qt_add_android_permission(${CMAKE_PROJECT_NAME}
    NAME android.permission.WRITE_EXTERNAL_STORAGE
    ATTRIBUTES
        maxSdkVersion 32
)
qt_add_android_permission(${CMAKE_PROJECT_NAME}
    NAME android.permission.READ_EXTERNAL_STORAGE
    ATTRIBUTES
        maxSdkVersion 33
)
qt_add_android_permission(${CMAKE_PROJECT_NAME}
    NAME android.permission.MANAGE_EXTERNAL_STORAGE
)

# Joystick
qt_add_android_permission(${CMAKE_PROJECT_NAME}
    NAME android.permission.VIBRATE
)

message(STATUS "QGC: Android platform configuration applied")
