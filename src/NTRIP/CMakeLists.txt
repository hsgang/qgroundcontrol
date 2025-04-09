find_package(Qt6 REQUIRED COMPONENTS Core)

target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        NTRIPManager.cc
        NTRIPManager.h
        NTRIPTCPLink.cc
        NTRIPTCPLink.h
)

target_link_libraries(${CMAKE_PROJECT_NAME}
    PUBLIC
        Qt6::Core
)

target_include_directories(${CMAKE_PROJECT_NAME} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

