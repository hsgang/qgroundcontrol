# ============================================================================
# Analyze View Unit Tests
# Tests for log analysis and telemetry visualization
# ============================================================================

add_subdirectory(GeoTag)

target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        OnboardLogDownloadTest.cc
        OnboardLogDownloadTest.h
        MavlinkLogTest.cc
        MavlinkLogTest.h
)

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
