package = "inio"
version = "scm-1"

source = {
   url = "git+https://github.com/n11kol11c/lua-inio.git",
   branch = "main",
}

description = {
   summary = "A lightweight C-based INI file reader for Lua",
   detailed = [[
      inio is a fast, minimal C extension for reading INI configuration
      files in Lua. It parses standard INI syntax (sections, key=value
      pairs, comments) directly in C for maximum performance with a
      simple two-function API.
   ]],
   homepage = "https://github.com/n11kol11c/lua-inio",
   license = "MIT",
}

dependencies = {
   "lua >= 5.1",
}

build = {
   type = "builtin",
   modules = {
      inio_core = {
         sources = { "inio.c" },
         libraries = { "lua" },
         incdirs = { "$(LUA_INCDIR)" },
         libdirs = { "$(LUA_LIBDIR)" },
      },
      inio = "inio.lua",
   },
}
