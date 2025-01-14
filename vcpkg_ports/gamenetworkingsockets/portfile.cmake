set(SOURCE_PATH "${CMAKE_CURRENT_LIST_DIR}/../..")

# Select crypto backend based on the selected crypto "feature"
# WE ARE NOT SUPPOSED TO BE DOING THIS.
# I'd be super happy if somebody wants to fix this up properly.
if ("libsodium" IN_LIST FEATURES)
    set(CRYPTO_BACKEND "libsodium")
endif()
if ("bcrypt" IN_LIST FEATURES)
    set(CRYPTO_BACKEND "BCrypt")
endif()
if ( ( "${CRYPTO_BACKEND}" STREQUAL "" ) OR ( "openssl" IN_LIST FEATURES ) )
    set(CRYPTO_BACKEND "OpenSSL")
endif()

# Handle some simple options that we can just
# pass straight through to cmake
vcpkg_check_features(
    OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
		webrtc USE_STEAMWEBRTC
		examples BUILD_EXAMPLES
		tests BUILD_TESTS
		tools BUILD_TOOLS
)

# Check static versus dynamic in the triple.  Our cmakefile can build both
# of them, but in the context of vcpkg, we will only build one or the other
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" BUILD_SHARED_LIB)
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" BUILD_STATIC_LIB)

# Select how to link the MSVC C runtime lib.  When building the static
# lib, we will link the CRT statically.  Otherwise, link dynamically.
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" MSVC_CRT_STATIC)

if ( BUILD_EXAMPLES AND NOT BUILD_SHARED_LIB )
	message(FATAL_ERROR "Examples must be built with shared linkage")
endif()
if ( BUILD_TESTS AND NOT BUILD_STATIC_LIB )
	message(FATAL_ERROR "Tests must be built with static linkage")
endif()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
    -DUSE_CRYPTO=${CRYPTO_BACKEND}
	-DBUILD_STATIC_LIB=${BUILD_STATIC_LIB}
	-DBUILD_SHARED_LIB=${BUILD_SHARED_LIB}
	-DMSVC_CRT_STATIC=${MSVC_CRT_STATIC}
    ${FEATURE_OPTIONS}
)

vcpkg_install_cmake()
#vcpkg_fixup_cmake_targets(CONFIG_PATH "lib/cmake/GameNetworkingSockets")

# Copy some files

file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
vcpkg_copy_pdbs()

# Cleanup some file droppings that our cmakefile really should
# not be publishing
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
