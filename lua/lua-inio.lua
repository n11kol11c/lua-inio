--- @meta
---
--- inio — Lightweight INI configuration library for Lua
---
--- Usage:
---   local inio = require("lua.lua-inio")
---   local config = inio.connect("config.ini")
---   print(config:get("server", "host"))
---
--- @version 1.0.0-beta

local Config = require("lua.lua-inio.config")
local class = require("lua.lua-inio.class")
local validators = require("lua.lua-inio.validators")
local utils = require("lua.lua-inio.utils")

---@class inio
local inio = {}

--- Library metadata.
---@class inio.meta
inio.iniometa = {
    __version = "1.0.0-beta",
    __name = "inio",
}

--- Expose the Config class directly for subclassing.
inio.Config = Config

--- Expose the class system.
inio.class = class

--- Expose built-in validators.
inio.validators = validators

--- Expose utility functions.
inio.utils = utils

--- Open an INI file and return a Config object.
---@param file string Path to the INI file
---@return Config config The parsed config object
function inio.connect(file)
    return Config(file)
end

--- Create a new empty Config object.
---@return Config config
function inio.new()
    local obj = setmetatable({ _data = {}, _file = nil }, Config)
    return obj
end

--- Parse an INI string directly.
---@param str string INI-formatted string
---@return Config config
function inio.parse(str)
    local obj = setmetatable({ _data = {}, _file = nil }, Config)

    local current_section = nil
    for raw_line in str:gmatch("[^\r\n]+") do
        local line = raw_line:match("^%s*(.-)%s*$")

        if line ~= "" and line:sub(1, 1) ~= ";" and line:sub(1, 1) ~= "#" then
            local section = line:match("^%[(.+)%]$")
            if section then
                current_section = section:match("^%s*(.-)%s*$")
                obj._data[current_section] = {}
            else
                local key, value = line:match("^(.-)%s*=%s*(.+)$")
                if key and current_section then
                    key = key:match("^%s*(.-)%s*$")
                    value = value:match("^%s*(.-)%s*$")
                    obj._data[current_section][key] = value
                end
            end
        end
    end

    return obj
end

return inio
