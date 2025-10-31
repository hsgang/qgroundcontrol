# ============================================================================
# CreateIFWInstaller.cmake
# Qt Installer Framework (IFW) installer creation using binarycreator
# ============================================================================

message(STATUS "QGC: Creating Qt Installer Framework (IFW) Installer")

# ----------------------------------------------------------------------------
# Validate Required Variables
# ----------------------------------------------------------------------------
foreach(p IN ITEMS
    CMAKE_PROJECT_NAME
    CMAKE_PROJECT_VERSION
    CMAKE_INSTALL_PREFIX
    CMAKE_BINARY_DIR
    CMAKE_SOURCE_DIR)
    if(NOT DEFINED ${p})
        message(FATAL_ERROR "QGC: Missing required var: ${p}")
    endif()
endforeach()

# ----------------------------------------------------------------------------
# Locate QtIFW binarycreator Utility
# ----------------------------------------------------------------------------
find_program(QGC_IFW_BINARYCREATOR binarycreator
    PATHS
        "${Qt6_ROOT_DIR}/../../Tools/QtInstallerFramework/*/bin"
        "$ENV{QTIFWDIR}/bin"
        "$ENV{Programfiles}/Qt/Tools/QtInstallerFramework/*/bin"
        "$ENV{PROGRAMFILES}/Qt/Tools/QtInstallerFramework/*/bin"
    DOC "Path to the QtIFW binarycreator utility."
)

if(NOT QGC_IFW_BINARYCREATOR)
    message(FATAL_ERROR "QGC: QtIFW binarycreator not found. Install Qt Installer Framework from Qt Maintenance Tool.")
endif()

message(STATUS "QGC: Found binarycreator: ${QGC_IFW_BINARYCREATOR}")

# ----------------------------------------------------------------------------
# Prepare IFW Package Structure
# ----------------------------------------------------------------------------
set(IFW_PACKAGES_DIR "${CMAKE_BINARY_DIR}/_ifw_packages")
set(IFW_CONFIG_DIR "${CMAKE_BINARY_DIR}/_ifw_config")
set(IFW_PACKAGE_DIR "${IFW_PACKAGES_DIR}/org.mavlink.${CMAKE_PROJECT_NAME}")

# Create directories
file(MAKE_DIRECTORY "${IFW_CONFIG_DIR}")
file(MAKE_DIRECTORY "${IFW_PACKAGE_DIR}/meta")
file(MAKE_DIRECTORY "${IFW_PACKAGE_DIR}/data")

# ----------------------------------------------------------------------------
# Prepare Icon Resources
# ----------------------------------------------------------------------------
# Convert ICO to PNG for IFW (IFW prefers PNG)
set(IFW_ICON_SOURCE "${QGC_WINDOWS_ICON_PATH}")
set(IFW_LOGO_SOURCE "${CMAKE_SOURCE_DIR}/resources/icons/qgroundcontrol.png")

# Copy icon files to config directory
if(EXISTS "${IFW_ICON_SOURCE}")
    file(COPY "${IFW_ICON_SOURCE}" DESTINATION "${IFW_CONFIG_DIR}/")
    get_filename_component(ICON_FILENAME "${IFW_ICON_SOURCE}" NAME_WE)
    set(HAS_INSTALLER_ICON TRUE)
endif()

if(EXISTS "${IFW_LOGO_SOURCE}")
    file(COPY "${IFW_LOGO_SOURCE}" DESTINATION "${IFW_CONFIG_DIR}/")
    set(HAS_WINDOW_ICON TRUE)
endif()

# ----------------------------------------------------------------------------
# Generate config.xml
# ----------------------------------------------------------------------------
set(CONFIG_XML_CONTENT "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<Installer>
    <Name>${CMAKE_PROJECT_NAME}</Name>
    <Version>1.0.0</Version>
    <Title>${CMAKE_PROJECT_NAME} Installer</Title>
    <Publisher>${QGC_ORG_NAME}</Publisher>
    <StartMenuDir>${CMAKE_PROJECT_NAME}</StartMenuDir>
    <TargetDir>@ApplicationsDir@/AMC</TargetDir>
    <WizardStyle>Modern</WizardStyle>")

# Add icon if available
if(HAS_INSTALLER_ICON)
    string(APPEND CONFIG_XML_CONTENT "
    <InstallerApplicationIcon>WindowsQGC</InstallerApplicationIcon>")
endif()

if(HAS_WINDOW_ICON)
    string(APPEND CONFIG_XML_CONTENT "
    <InstallerWindowIcon>qgroundcontrol</InstallerWindowIcon>")
endif()

string(APPEND CONFIG_XML_CONTENT "
</Installer>
")

file(WRITE "${IFW_CONFIG_DIR}/config.xml" "${CONFIG_XML_CONTENT}")

# ----------------------------------------------------------------------------
# Generate package.xml
# ----------------------------------------------------------------------------
file(WRITE "${IFW_PACKAGE_DIR}/meta/package.xml" "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<Package>
    <DisplayName>${CMAKE_PROJECT_NAME}</DisplayName>
    <Description>${CMAKE_PROJECT_NAME} Ground Control Station</Description>
    <Version>${CMAKE_PROJECT_VERSION}</Version>
    <ReleaseDate>${QGC_BUILD_DATE}</ReleaseDate>
    <Default>true</Default>
    <Essential>true</Essential>
    <ForcedInstallation>true</ForcedInstallation>
</Package>
")

# ----------------------------------------------------------------------------
# Copy installscript.js if exists
# ----------------------------------------------------------------------------
set(INSTALL_SCRIPT_SRC "${CMAKE_SOURCE_DIR}/deploy/installer/packages/org.mavlink.qgroundcontrol/meta/installscript.js")
if(EXISTS "${INSTALL_SCRIPT_SRC}")
    file(COPY "${INSTALL_SCRIPT_SRC}" DESTINATION "${IFW_PACKAGE_DIR}/meta/")
endif()

# ----------------------------------------------------------------------------
# Copy installed files to package data directory
# ----------------------------------------------------------------------------
message(STATUS "QGC: Copying installed files to IFW package...")
file(COPY "${CMAKE_INSTALL_PREFIX}/" DESTINATION "${IFW_PACKAGE_DIR}/data/")

# ----------------------------------------------------------------------------
# Set Output Installer Name
# ----------------------------------------------------------------------------
if(CMAKE_CROSSCOMPILING)
    set(QGC_IFW_OUT "${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}-installer-${CMAKE_HOST_SYSTEM_PROCESSOR}-${CMAKE_SYSTEM_PROCESSOR}.exe")
else()
    set(QGC_IFW_OUT "${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}-installer-${CMAKE_SYSTEM_PROCESSOR}.exe")
endif()

file(TO_NATIVE_PATH "${QGC_IFW_OUT}" QGC_IFW_OUT_NATIVE)

# ----------------------------------------------------------------------------
# Execute IFW binarycreator
# ----------------------------------------------------------------------------
message(STATUS "QGC: Executing binarycreator...")
execute_process(
    COMMAND "${QGC_IFW_BINARYCREATOR}"
        -c "${IFW_CONFIG_DIR}/config.xml"
        -p "${IFW_PACKAGES_DIR}"
        "${QGC_IFW_OUT_NATIVE}"
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    COMMAND_ECHO STDOUT
    RESULT_VARIABLE IFW_RESULT
    OUTPUT_VARIABLE IFW_OUTPUT
    ERROR_VARIABLE IFW_ERROR
)

if(NOT IFW_RESULT EQUAL 0)
    message(FATAL_ERROR "QGC: IFW installer creation failed:\n${IFW_ERROR}")
endif()

message(STATUS "QGC: IFW installer created: ${QGC_IFW_OUT}")
