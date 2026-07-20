cmake_minimum_required(VERSION 3.15)
project(inio C)

set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# --- Find Lua ---------------------------------------------------------------

# Option 1: User-provided LUA_PREFIX
if(LUA_PREFIX)
    find_path(LUA_INCLUDE_DIR lua.h
        HINTS ${LUA_PREFIX}/include/lua ${LUA_PREFIX}/include
        NO_DEFAULT_PATH
    )
    find_library(LUA_LIBRARY
        NAMES lua lua54 lua5.4 lua53 lua5.3 lua52 lua5.2 lua51 lua5.1
        HINTS ${LUA_PREFIX}/lib ${LUA_PREFIX}/lib/lua
        NO_DEFAULT_PATH
    )
endif()

# Option 2: Try pkg-config
if(NOT LUA_LIBRARY)
    find_package(PkgConfig QUIET)
    if(PKG_CONFIG_FOUND)
        # Try versioned names first, then plain "lua"
        foreach(_lua_ver 5.4 5.3 5.2 5.1)
            pkg_check_modules(LUA QUIET lua${_lua_ver})
            if(LUA_FOUND)
                break()
            endif()
        endforeach()
        if(NOT LUA_FOUND)
            pkg_check_modules(LUA QUIET lua)
        endif()
    endif()
endif()

# Option 3: Fall back to find_path / find_library
if(NOT LUA_INCLUDE_DIR)
    find_path(LUA_INCLUDE_DIR lua.h
        PATHS
            /usr/include/lua5.4
            /usr/include/lua5.3
            /usr/include/lua5.2
            /usr/include/lua5.1
            /usr/include/lua
            /usr/local/include/lua5.4
            /usr/local/include/lua5.3
            /usr/local/include/lua5.2
            /usr/local/include/lua5.1
            /usr/local/include/lua
            /opt/homebrew/opt/lua/include/lua
            /opt/homebrew/include/lua
            "C:/Program Files/Lua/include"
            "C:/Lua/include"
    )
endif()

if(NOT LUA_LIBRARY)
    find_library(LUA_LIBRARY
        NAMES lua lua54 lua5.4 lua53 lua5.3 lua52 lua5.2 lua51 lua5.1
        PATHS
            /usr/lib
            /usr/lib/lua
            /usr/local/lib
            /usr/local/lib/lua
            /opt/homebrew/opt/lua/lib
            /opt/homebrew/lib
            "C:/Program Files/Lua/lib"
            "C:/Lua/lib"
    )
endif()

# Use pkg-config include dirs if we found them
if(LUA_FOUND AND LUA_INCLUDE_DIRS)
    set(LUA_INCLUDE_DIR ${LUA_INCLUDE_DIRS})
endif()

if(NOT LUA_LIBRARY)
    message(FATAL_ERROR
        "Could not find Lua library. Install Lua development files or "
        "pass -DLUA_PREFIX=/path/to/lua"
    )
endif()

message(STATUS "Lua include dir: ${LUA_INCLUDE_DIR}")
message(STATUS "Lua library:     ${LUA_LIBRARY}")

# --- Build shared library ---------------------------------------------------

add_library(inio_core SHARED inio.c modules/str.c)

target_include_directories(inio_core PRIVATE ${LUA_INCLUDE_DIR} ${CMAKE_SOURCE_DIR})
target_link_libraries(inio_core PRIVATE ${LUA_LIBRARY})

# Remove the "lib" prefix on all platforms so the output is inio_core.so
set_target_properties(inio_core PROPERTIES
    PREFIX ""
    OUTPUT_NAME "inio_core"
)

# Platform-specific shared library extension
if(APPLE)
    set_target_properties(inio_core PROPERTIES SUFFIX ".so")
elseif(WIN32)
    set_target_properties(inio_core PROPERTIES SUFFIX ".dll")
endif()

# --- Install ----------------------------------------------------------------

# Install the shared library to the Lua C modules directory
if(LUA_FOUND AND LUA_LIBRARIES_DIRS)
    set(_lua_cmod_dir "${LUA_LIBRARIES_DIRS}")
else()
    # Default: install alongside inio.lua into a standard Lua path
    set(_lua_cmod_dir "${CMAKE_INSTALL_LIBDIR}/lua")
endif()

install(TARGETS inio_core
    LIBRARY DESTINATION ${_lua_cmod_dir}
    RUNTIME DESTINATION ${_lua_cmod_dir}   # .dll on Windows
)

# Install the Lua wrapper module
find_program(LUA_EXECUTABLE
    NAMES lua lua5.4 lua5.3 lua5.2 lua5.1
)

if(LUA_EXECUTABLE)
    # Ask Lua where its package.path lives
    execute_process(
        COMMAND ${LUA_EXECUTABLE} -e "print(package.path:match('([^;]+)'))"
        OUTPUT_VARIABLE _lua_pkg_path
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
    if(_lua_pkg_path)
        get_filename_component(_lua_pkg_dir "${_lua_pkg_path}" DIRECTORY)
        install(FILES inio.lua DESTINATION "${_lua_pkg_dir}")
    else()
        install(FILES inio.lua DESTINATION "${CMAKE_INSTALL_DATADIR}/lua")
    endif()
else()
    install(FILES inio.lua DESTINATION "${CMAKE_INSTALL_DATADIR}/lua")
endif()
