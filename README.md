# inio

A fast, lightweight INI configuration file reader for Lua.

Available in two variants:

- **C extension** (`inio.c`) -- compiled shared library for maximum performance
- **Pure Lua** (`lua/lua-inio.lua`) -- zero dependencies, no compilation needed

## Features

- **Standard INI syntax** -- sections, key=value pairs, `;` and `#` comments
- **Python-like OOP** -- `__init__` constructors, class inheritance, `isinstance()` checks
- **Built-in validators** -- number, port, IP, boolean, range, pattern matching
- **Environment interpolation** -- `${VAR}` syntax replaced with `os.getenv()` values
- **Config merging** -- combine multiple INI files or tables
- **Utility toolkit** -- flatten, unflatten, deep copy, filter, map, JSON export
- **Works everywhere** -- Linux, macOS, Windows
- **Two variants** -- choose C for speed or pure Lua for simplicity

## Prerequisites

### Lua

Install Lua (5.1 or newer) for your platform:

**macOS (Homebrew):**

```bash
brew install lua
```

**Ubuntu / Debian:**

```bash
sudo apt update
sudo apt install lua5.4 liblua5.4-dev
```

**Fedora / RHEL:**

```bash
sudo dnf install lua lua-devel
```

**Windows (MSYS2):**

```bash
pacman -S mingw-w64-ucrt-x86_64-lua
```

Verify:

```bash
lua -v
```

### C compiler (C extension only)

**macOS:**

```bash
xcode-select --install
```

**Ubuntu / Debian:**

```bash
sudo apt install build-essential
```

**Fedora / RHEL:**

```bash
sudo dnf groupinstall "Development Tools"
```

## Installation

### Pure Lua (no compilation needed)

Copy `lua/lua-inio.lua` and the `lua/lua-inio/` directory into your project.

```lua
local inio = require("lua.lua-inio")
local config = inio.connect("config.ini")
print(config:get("server", "host"))
```

No C compiler, no build step, no dependencies.

### C Extension

#### CMake (recommended)

```bash
cmake -B build
cmake --build build
```

**Custom Lua prefix:**

```bash
cmake -B build -DLUA_PREFIX=/path/to/lua
```

#### Makefile

```bash
make
```

#### LuaRocks

```bash
luarocks make inio-scm-1.rockspec
```

#### Manual build

```bash
cc -shared -fPIC -o inio_core.so inio.c \
    $(pkg-config --cflags lua) $(pkg-config --libs lua)
```

## Quick Start

### Pure Lua

1. Copy `lua/lua-inio.lua` and `lua/lua-inio/` to your project.
2. Create an INI file:

```ini
[server]
host=127.0.0.1
port=8080

[database]
name=myapp
user=admin
password=secret
```

3. Use it:

```lua
local inio = require("lua.lua-inio")
local config = inio.connect("config.ini")

-- Method access
print(config:get("server", "host"))   -- 127.0.0.1
print(config:get("server", "port"))   -- 8080

-- Direct table access
config._data.server.host = "192.168.1.1"
print(config._data.server.host)       -- 192.168.1.1
```

### C Extension

```lua
local inio = require("inio")
local config = inio.connect("config.ini")
print(config:get("server", "host"))
```

## API

### Module Functions

#### `inio.connect(file)`

Parse an INI file and return a `Config` object.

```lua
local config = inio.connect("config.ini")
```

#### `inio.parse(str)`

Parse an INI string directly.

```lua
local config = inio.parse("[app]\nname=myapp\nversion=1.0")
```

#### `inio.new()`

Create an empty Config object.

```lua
local config = inio.new()
config:set("section", "key", "value")
```

### Config Methods

#### `config:get(section, key)`

Get a value by section and key.

```lua
local value = config:get("server", "host")
```

#### `config:set(section, key, value)`

Set a value. Creates the section if needed.

```lua
config:set("database", "host", "localhost")
```

#### `config:has(section, key?)`

Check if a section or key exists.

```lua
config:has("server")           -- true
config:has("server", "host")   -- true
```

#### `config:remove(section, key?)`

Remove a key or entire section.

```lua
config:remove("server", "host")    -- remove key
config:remove("database")          -- remove section
```

#### `config:sections()`

List all section names.

```lua
local sections = config:sections()  -- {"server", "database"}
```

#### `config:keys(section)`

List all keys in a section.

```lua
local keys = config:keys("server")  -- {"host", "port"}
```

#### `config:section_count()`

Get the number of sections.

#### `config:key_count(section)`

Get the number of keys in a section.

#### `config:to_table()`

Get all data as a plain table (copy).

```lua
local t = config:to_table()
print(t.server.host)
```

#### `config:merge(other)`

Merge another Config or table into this one.

```lua
local defaults = inio.parse("[db]\nhost=localhost\nport=5432")
config:merge(defaults)
```

#### `config:interpolate_env()`

Replace `${VAR}` with `os.getenv("VAR")`.

```ini
[server]
host=${HOME}
```

```lua
config:interpolate_env()
print(config:get("server", "host"))  -- /Users/you
```

#### `config:validate(schema)`

Validate values against a schema.

```lua
local ok, errors = config:validate({
    ["server.port"] = inio.validators.is_port(),
    ["server.host"] = inio.validators.is_ipv4(),
})
if not ok then
    for _, e in ipairs(errors) do print(e) end
end
```

#### `config:save(file?)`

Write back to a file. Defaults to the original file.

```lua
config:save()              -- overwrite original
config:save("backup.ini")  -- save to new file
```

#### `config:get_file()`

Get the source file path.

#### `print(config)`

Calls `__tostring` automatically -- prints INI format.

### `config._data`

Direct table access for full manipulation.

```lua
print(config._data.server.host)
config._data.server.host = "10.0.0.1"
config._data.cache = { ttl = "300", enabled = "true" }
```

## Validators

Built-in validators for `config:validate()`. Each returns a function that takes a string and returns a boolean.

| Validator | Description |
|-----------|-------------|
| `validators.is_number()` | Value is a valid number |
| `validators.is_integer()` | Value is a valid integer |
| `validators.in_range(min, max)` | Value is within a numeric range |
| `validators.matches(pattern)` | Value matches a Lua pattern |
| `validators.one_of(list)` | Value is one of allowed values |
| `validators.not_empty()` | Value is not empty |
| `validators.is_ipv4()` | Value is a valid IPv4 address |
| `validators.is_port()` | Value is a valid port (1-65535) |
| `validators.is_boolean()` | Value is true/false/yes/no/on/off/1/0 |
| `validators.all_of(...)` | All validators must pass (AND) |
| `validators.any_of(...)` | Any validator must pass (OR) |

### Example

```lua
local v = inio.validators

local ok, errors = config:validate({
    ["server.host"] = v.all_of(v.not_empty(), v.is_ipv4()),
    ["server.port"] = v.all_of(v.not_empty(), v.is_port()),
    ["server.name"] = v.one_of({"prod", "staging", "dev"}),
    ["app.debug"]   = v.is_boolean(),
    ["app.level"]   = v.in_range(1, 100),
})
```

## Utilities

Helper functions via `inio.utils`.

| Function | Description |
|----------|-------------|
| `utils.deep_copy(tbl)` | Deep copy a table |
| `utils.deep_merge(a, b)` | Deep merge two tables |
| `utils.filter(tbl, fn)` | Filter key-value pairs |
| `utils.map(tbl, fn)` | Transform values |
| `utils.flatten(data)` | Flatten to dot-notation keys |
| `utils.unflatten(data)` | Unflatten back to nested table |
| `utils.to_json(data)` | Convert to JSON-compatible string |

### Examples

```lua
-- Flatten INI data to dot-notation
local flat = inio.utils.flatten(config:to_table())
-- { ["server.host"] = "127.0.0.1", ["server.port"] = "8080" }

-- Unflatten back
local nested = inio.utils.unflatten(flat)

-- Deep merge
local base = { server = { host = "localhost" } }
local over = { server = { port = "8080" } }
local merged = inio.utils.deep_merge(base, over)
-- { server = { host = "localhost", port = "8080" } }
```

## Class System

A lightweight Python-like class system via `inio.class`.

```lua
local Animal = inio.class.new("Animal")

function Animal:__init(name, sound)
    self.name = name
    self.sound = sound
end

function Animal:speak()
    return self.name .. " says " .. self.sound
end

local dog = Animal("Rex", "Woof")
print(dog:speak())                      -- Rex says Woof
print(inio.class.isinstance(dog, Animal))  -- true
print(inio.class.classname(dog))           -- Animal
```

## INI File Format

Standard INI syntax is supported:

```ini
; This is a comment (semicolon)
# This is also a comment (hash)

[section]
key=value
key with spaces = trimmed value

[nested]
database.host=localhost
database.port=5432
```

- **Sections** are enclosed in square brackets: `[section]`
- **Key-value pairs** are separated by `=`
- **Comments** start with `;` or `#`
- **Whitespace** around keys and values is trimmed automatically
- **Environment variables** `${VAR}` are interpolated when you call `config:interpolate_env()`

## Project Structure

```
lua-inio/
  lua/
    lua-inio.lua              # Main entry point
    lua-inio/
      class.lua               # Python-like class system
      config.lua              # Config class (core)
      validators.lua          # Built-in validators
      utils.lua               # Utility functions
  inio.c                      # C implementation
  inio.lua                    # Lua wrapper for C extension
  inio_core.so                # Compiled shared library (after build)
  modules/
    str.c                     # String utilities (C)
    str.h                     # String utilities header
  CMakeLists.txt              # CMake build
  Makefile                    # Make build
  inio-scm-1.rockspec         # LuaRocks package spec
  test.lua                    # C extension test
  config.ini                  # Sample INI file
```

## Running the Example

### Pure Lua

```bash
lua -e "
local inio = require('lua.lua-inio')
local config = inio.connect('config.ini')
print(config:get('player', 'name'))
print(config:get('server', 'port'))
"
```

### C Extension

```bash
cmake -B build && cmake --build build
cp build/inio_core.so .
lua test.lua
```

## License

MIT License. See [LICENSE](LICENSE) for details.
