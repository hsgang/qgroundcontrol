cmake_minimum_required(VERSION 3.21.1 FATAL_ERROR)

#######################################################
#                   Project Info
#######################################################

project(QGroundControl LANGUAGES C CXX)
# set_target_properties(${PROJECT_NAME} PROPERTIES VERSION 1.0)

#######################################################
#            CMake Configuration Options
#######################################################
# Setting configuration options and conditionally adding compile options

set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug;Release;RelWithDebInfo;MinSizeRel;Coverage")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/staging)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

include(FeatureSummary)

# CMake build type
# Debug Release RelWithDebInfo MinSizeRel Coverage
if (NOT CMAKE_BUILD_TYPE)
    # default to release with debug symbols
    set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Build type" FORCE)
endif()

# Add folder where are supportive functions
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# Stable or daily build option
option(STABLE_BUILD "Stable build option" OFF)

if (STABLE_BUILD)
    message(STATUS "Stable Build")
else ()
    message(STATUS "Daily Build")
    add_compile_definitions(DAILY_BUILD)
endif()

include(CMakeDependentOption)
cmake_dependent_option(BUILD_TESTING "Enable testing" ON "CMAKE_BUILD_TYPE STREQUAL Debug" OFF)

#######################################################
#               OS Configuration
#######################################################
if (LINUX)
    # if USE_WAYLAND == 0, use X11 instead of Wayland
    set(USE_WAYLAND 1)
endif ()

include(CompileOptions)

#######################################################
#               Qt6 Configuration
#######################################################

include(Qt6QGCConfiguration)
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Qt version: ${QT_VERSION}")
message(STATUS "Qt spec: ${QT_MKSPEC}")

if(LINUX)
    set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/AppDir/usr)
endif()

# Find Qt6 libraries
find_package(Qt6
    REQUIRED
    COMPONENTS
        Bluetooth
        Charts
        Concurrent
        Core
        Core5Compat
        Location
        Multimedia
        Network
        Positioning
        Quick
        QuickControls2
        QuickWidgets
        OpenGL
        Sql
        Svg
        Test
        TextToSpeech
        Widgets
        Xml
    OPTIONAL_COMPONENTS
        LinguistTools
        SerialPort
    HINTS
        ${QT_LIBRARY_HINTS}
)

qt_standard_project_setup(REQUIRES 6.6.0)

# this is required since user can have Qt5 and Qt6 installed at the same time, and then Qt_DIR
# might point to Qt5, but we want to use Qt6
# especially qmdnsengine uses Qt_DIR to choose Qt version
if (Qt6_DIR)
    set(QT_DIR ${Qt6_DIR})
endif ()

qt_policy(
    SET QTP0001 NEW
    SET QTP0002 NEW
)

set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml" CACHE PATH "Install path for QML" FORCE)
set(QML_IMPORT_PATH ${CMAKE_SOURCE_DIR}/qml ${CMAKE_BINARY_DIR}/imports CACHE STRING "Extra QML Import Paths" FORCE)

#######################################################
#                QML Configuration
#######################################################

# Pre-compile QML files using the Qt Quick compiler.
option(COMPILE_QML "Pre-compile QML files using the Qt Quick compiler." FALSE)
add_feature_info(COMPILE_QML COMPILE_QML "Pre-compile QML files using the Qt Quick compiler.")
if(COMPILE_QML)
    find_package(Qt6QuickCompiler)
    set_package_properties(Qt6QuickCompiler PROPERTIES
            DESCRIPTION "Pre-compile QML files using the Qt Quick compiler."
            TYPE OPTIONAL
    )
endif()

# Enable QML debugging/profiling support.
option(DEBUG_QML "Build QGroundControl with QML debugging/profiling support." FALSE)
add_feature_info(DEBUG_QML DEBUG_QML "Build QGroundControl with QML debugging/profiling support.")
if(DEBUG_QML)
    message(STATUS "To enable the QML debugger/profiler, run with: '-qmljsdebugger=port:1234'")
    add_compile_definitions(
        QMLJSDEBUGGER
        QT_QML_DEBUG
    )
endif()


#######################################################
#               QGroundControl Info
#######################################################
# Setting organization related definitions

set(COMPANY "Mavlink")
set(COPYRIGHT "Copyright (c) 2018 QGroundControl. All rights reserved.")
set(IDENTIFIER "io.mavlink.qgroundcontrol")

add_compile_definitions(
    QGC_APPLICATION_NAME="QGroundControl"
    QGC_ORG_NAME="QGroundControl.org"
    QGC_ORG_DOMAIN="org.qgroundcontrol"
)

#######################################################
#                QGroundControl Git Information
#######################################################

include(Git)
message(STATUS "QGroundControl version: ${APP_VERSION_STR}")

#######################################################
#                QGroundControl Resources
#######################################################
include_directories(
        libs/libevents

        libs/mavlink/include/mavlink/v2.0
        libs/mavlink/include/mavlink/v2.0/all
        libs/mavlink/include/mavlink/v2.0/common

        libs/shapelib
)

add_subdirectory(libs)
add_subdirectory(src)

set(QGC_RESOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/qgcimages.qrc
        ${CMAKE_CURRENT_SOURCE_DIR}/qgcresources.qrc
        ${CMAKE_CURRENT_SOURCE_DIR}/qgroundcontrol.qrc
        ${CMAKE_CURRENT_SOURCE_DIR}/resources/InstrumentValueIcons/InstrumentValueIcons.qrc
        ${CMAKE_CURRENT_SOURCE_DIR}/src/FirmwarePlugin/APM/APMResources.qrc
        ${CMAKE_CURRENT_SOURCE_DIR}/src/FirmwarePlugin/PX4/PX4Resources.qrc
)

if (WIN32)
    # append application icon resource for Windows
    set(QGC_RESOURCES
            ${QGC_RESOURCES}
            ${CMAKE_CURRENT_SOURCE_DIR}/windows/QGroundControl.rc)
endif()

if(CONFIG_UTM_ADAPTER)
    list(APPEND QGC_RESOURCES
            ${CMAKE_CURRENT_SOURCE_DIR}/src/UTMSP/utmsp.qrc
    )
else()
    list(APPEND QGC_RESOURCES
            ${CMAKE_CURRENT_SOURCE_DIR}/src/UTMSP/dummy/utmsp_dummy.qrc
    )
endif()

if (BUILD_TESTING)
    list(APPEND QGC_RESOURCES ${CMAKE_CURRENT_SOURCE_DIR}/test/UnitTest.qrc)
endif()

if(WIN32)
    list(APPEND QGC_RESOURCES ${CMAKE_SOURCE_DIR}/deploy/windows/QGroundControl.rc)
elseif(MACOS)
    set(MACOSX_BUNDLE_ICON_FILE macx.icns)
    set(app_icon_macos "${CMAKE_CURRENT_SOURCE_DIR}/resources/icons/macx.icns")
    set_source_files_properties(${app_icon_macos} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
    list(APPEND QGC_RESOURCES
            ${app_icon_macos}
    )
endif()

#######################################################
#               QGroundControl Target
#######################################################

qt_add_executable(${PROJECT_NAME} src/main.cc ${QGC_RESOURCES})

set_target_properties(${PROJECT_NAME}
    PROPERTIES
        QT_RESOURCE_PREFIX "/qgc"
)

if(Qt6LinguistTools_FOUND)
    file(GLOB TS_SOURCES RELATIVE ${CMAKE_SOURCE_DIR} ${CMAKE_SOURCE_DIR}/translations/qgc_*.ts)
    # TODO: Update to new qt_add_translations form in Qt6.7
    qt_add_translations(${PROJECT_NAME}
        TS_FILES
            ${TS_SOURCES}
    )
endif()

if(MACOS)
    set_target_properties(${PROJECT_NAME}
        PROPERTIES
            MACOSX_BUNDLE TRUE
            MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/deploy/mac/MacOSXBundleInfo.plist.in
    )
elseif(IOS)
    set_target_properties(${PROJECT_NAME}
       PROPERTIES
           QT_IOS_LAUNCH_SCREEN ${CMAKE_SOURCE_DIR}/deploy/ios/QGCLaunchScreen.xib
    )
elseif(WIN32)
    set_target_properties(${PROJECT_NAME} PROPERTIES WIN32_EXECUTABLE TRUE)
elseif(ANDROID)
    add_android_openssl_libraries(${PROJECT_NAME})

    set_target_properties(${PROJECT_NAME}
        PROPERTIES
            QT_ANDROID_ABIS ${ANDROID_ABI}
            QT_ANDROID_MIN_SDK_VERSION 26
            QT_ANDROID_TARGET_SDK_VERSION 33
            QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_SOURCE_DIR}/android
            QT_ANDROID_VERSION_NAME ${APP_VERSION_STR}
            # QT_ANDROID_VERSION_CODE 5.0
            QT_QML_ROOT_PATH ${CMAKE_SOURCE_DIR}
    )

    if(CMAKE_BUILD_TYPE STREQUAL "Release" AND ANDROID_KEYSTORE_PASSWORD)
        set(QT_ANDROID_SIGN_APK TRUE)
    endif()
endif()

target_link_libraries(${PROJECT_NAME} PRIVATE qgc)

#######################################################
#               Testing Configuration
#######################################################

if(BUILD_TESTING)
    add_subdirectory(test)
    target_link_libraries(${PROJECT_NAME} PRIVATE qgctest)
endif()

#######################################################
#		Install Configuration
#######################################################

include(GNUInstallDirs)

# Files/directories to install
#install(
#    TARGETS ${PROJECT_NAME}
#    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
#    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
#    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
#)
install(
        TARGETS ${PROJECT_NAME}
        DESTINATION ${CMAKE_INSTALL_BINDIR}
)
if(NOT ANDROID)
    qt_generate_deploy_qml_app_script(
        TARGET ${PROJECT_NAME}
        OUTPUT_SCRIPT deploy_script
        MACOS_BUNDLE_POST_BUILD
    )
    install(SCRIPT ${deploy_script})
endif()
install(
        DIRECTORY ${CMAKE_SOURCE_DIR}/resources/
        DESTINATION ${CMAKE_INSTALL_DATADIR}/qgroundcontrol
)
install(
        FILES ${CMAKE_SOURCE_DIR}/deploy/org.mavlink.qgroundcontrol.desktop
        DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
)
install(
        FILES ${CMAKE_SOURCE_DIR}/resources/icons/qgroundcontrol.png
        DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/128x128/apps/
        RENAME org.mavlink.qgroundcontrol.png
)
configure_file(
        ${CMAKE_SOURCE_DIR}/deploy/org.mavlink.qgroundcontrol.metainfo.xml.in
        ${CMAKE_BINARY_DIR}/metainfo/org.mavlink.qgroundcontrol.metainfo.xml
        @ONLY
)
install(
        FILES ${CMAKE_BINARY_DIR}/metainfo/org.mavlink.qgroundcontrol.metainfo.xml
        DESTINATION ${CMAKE_INSTALL_DATADIR}/metainfo/
    )
    install(SCRIPT "${CMAKE_SOURCE_DIR}/cmake/CreateAppImage.cmake")
endif()

#######################################################
#               Serial Port Configuration
#######################################################
if(NOT QT_MKSPEC MATCHES "winrt")
    target_link_libraries(${PROJECT_NAME}
        PUBLIC
            Qt6::SerialPort
        )
endif()

#include(QGCDeploy)