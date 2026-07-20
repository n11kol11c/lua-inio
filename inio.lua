local inio_core = require("inio_core")

local inio = {}

--- Opens an INI file for reading.
--- Must be called before using `inio.get`.
---@param file string Path to the INI file
---@return nil
function inio.open(file)
    inio_core.open(file)
end

--- Returns a value from the loaded INI file.
---@param section string The INI section name (without brackets)
---@param key string The key to look up
---@return string|nil value The value, or nil if not found
function inio.get(section, key)
    return inio_core.get(section, key)
end

return inio
