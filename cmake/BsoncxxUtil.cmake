# Define and link a form of the bsoncxx library
#
# This function requires the following variables to be defined in its parent scope:
# - bsoncxx_sources
# - libbson_target
function(bsoncxx_add_library TARGET OUTPUT_NAME LINK_TYPE)
    add_library(${TARGET} ${LINK_TYPE}
        ${bsoncxx_sources}
    )

    set_target_properties(${TARGET} PROPERTIES
        OUTPUT_NAME ${OUTPUT_NAME}
        VERSION ${BSONCXX_VERSION}
        DEFINE_SYMBOL BSONCXX_EXPORT
    )

    if(LINK_TYPE STREQUAL "SHARED")
        set_target_properties(${TARGET} PROPERTIES
            CXX_VISIBILITY_PRESET hidden
            VISIBILITY_INLINES_HIDDEN ON
            SOVERSION ${BSONCXX_ABI_VERSION}
        )
    endif()

    if(LINK_TYPE STREQUAL "STATIC")
        target_compile_definitions(bsoncxx_static PUBLIC BSONCXX_STATIC)
    endif()

    if(BSONCXX_POLY_USE_MNMLSTC AND NOT BSONCXX_POLY_USE_SYSTEM_MNMLSTC)
        add_dependencies(${TARGET} EP_mnmlstc_core)
        ExternalProject_Get_Property(EP_mnmlstc_core source_dir)
        target_include_directories(${TARGET} PUBLIC $<BUILD_INTERFACE:${source_dir}/include>)
    elseif(BSONCXX_POLY_USE_BOOST)
        target_include_directories(${TARGET} PUBLIC ${Boost_INCLUDE_DIRS})
    endif()

    target_link_libraries(${TARGET} PRIVATE ${libbson_target})

    generate_export_header(${TARGET}
        BASE_NAME BSONCXX
        EXPORT_MACRO_NAME BSONCXX_API
        NO_EXPORT_MACRO_NAME BSONCXX_PRIVATE
        EXPORT_FILE_NAME config/export.hpp
        STATIC_DEFINE BSONCXX_STATIC
    )
endfunction(bsoncxx_add_library)

# Install the specified forms of the bsoncxx library (i.e., shared and/or static)
# with associated CMake config files
function(bsoncxx_install BSONCXX_TARGET_LIST BSONCXX_PKG_DEP)
    install(TARGETS
        ${BSONCXX_TARGET_LIST}
        EXPORT bsoncxx_targets
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT runtime
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT runtime
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT dev
        INCLUDES DESTINATION ${BSONCXX_HEADER_INSTALL_DIR}
    )

    write_basic_package_version_file(
        "${CMAKE_CURRENT_BINARY_DIR}/bsoncxx-config-version.cmake"
        VERSION ${BSONCXX_VERSION}
        COMPATIBILITY SameMajorVersion
    )

    configure_file(cmake/bsoncxx-config.cmake.in
        "${CMAKE_CURRENT_BINARY_DIR}/bsoncxx-config.cmake"
        @ONLY
    )

    export(EXPORT bsoncxx_targets
        NAMESPACE mongo::
        FILE "${CMAKE_CURRENT_BINARY_DIR}/bsoncxx_targets.cmake"
    )

    install(EXPORT bsoncxx_targets
        NAMESPACE mongo::
        FILE bsoncxx_targets.cmake
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/bsoncxx-${BSONCXX_VERSION}
    )

    install(
        FILES
            "${CMAKE_CURRENT_BINARY_DIR}/bsoncxx-config-version.cmake"
            "${CMAKE_CURRENT_BINARY_DIR}/bsoncxx-config.cmake"
        DESTINATION
            ${CMAKE_INSTALL_LIBDIR}/cmake/bsoncxx-${BSONCXX_VERSION}
        COMPONENT
            Devel
    )
endfunction(bsoncxx_install)
