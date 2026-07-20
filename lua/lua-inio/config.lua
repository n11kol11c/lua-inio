--- @meta
--- Config class — the core object returned by inio.connect()

local class = require("lua.lua-inio.class")

---@class Config
local Config = class.new("Config")

--- Parse an INI file and create a Config instance.
---@param file string Path to the INI file
---@return Config
function Config:__init(file)
    self._data = {}
    self._file = file
    self._current_section = nil

    for raw_line in io.lines(file) do
        local line = raw_line:match("^%s*(.-)%s*$")

        if line == "" or line:sub(1, 1) == ";" or line:sub(1, 1) == "#" then
            -- skip empty lines and comments
        else
            local section = line:match("^%[(.+)%]$")
            if section then
                self._current_section = section:match("^%s*(.-)%s*$")
                self._data[self._current_section] = {}
            else
                local key, value = line:match("^(.-)%s*=%s*(.+)$")
                if key and self._current_section then
                    key = key:match("^%s*(.-)%s*$")
                    value = value:match("^%s*(.-)%s*$")
                    self._data[self._current_section][key] = value
                end
            end
        end
    end
end

--- Get a value by section and key.
---@param section string
---@param key string
---@return string|nil
function Config:get(section, key)
    local s = self._data[section]
    if s then return s[key] end
    return nil
end

--- Set a value. Creates the section if it doesn't exist.
---@param section string
---@param key string
---@param value string|number|boolean
function Config:set(section, key, value)
    if not self._data[section] then
        self._data[section] = {}
    end
    self._data[section][key] = tostring(value)
end

--- Check if a section or key exists.
---@param section string
---@param key string?
---@return boolean
function Config:has(section, key)
    if key then
        local s = self._data[section]
        return s ~= nil and s[key] ~= nil
    end
    return self._data[section] ~= nil
end

--- Delete a key or an entire section.
---@param section string
---@param key string?
---@return boolean success
function Config:remove(section, key)
    if key then
        local s = self._data[section]
        if s and s[key] then
            s[key] = nil
            return true
        end
        return false
    else
        if self._data[section] then
            self._data[section] = nil
            return true
        end
        return false
    end
end

--- List all section names.
---@return string[]
function Config:sections()
    local result = {}
    for k, _ in pairs(self._data) do
        result[#result + 1] = k
    end
    return result
end

--- List all keys in a section.
---@param section string
---@return string[]
function Config:keys(section)
    local s = self._data[section]
    if not s then return {} end
    local r = {}
    for k, _ in pairs(s) do r[#r + 1] = k end
    return r
end

--- Get the number of sections.
---@return number
function Config:section_count()
    local n = 0
    for _ in pairs(self._data) do n = n + 1 end
    return n
end

--- Get the number of keys in a section.
---@param section string
---@return number
function Config:key_count(section)
    local s = self._data[section]
    if not s then return 0 end
    local n = 0
    for _ in pairs(s) do n = n + 1 end
    return n
end

--- Get all data as a plain table.
---@return table
function Config:to_table()
    local copy = {}
    for s, entries in pairs(self._data) do
        copy[s] = {}
        for k, v in pairs(entries) do
            copy[s][k] = v
        end
    end
    return copy
end

--- Merge another Config or table into this one.
---@param other Config|table
function Config:merge(other)
    local other_data = other
    if class.isinstance(other, Config) then
        other_data = other._data
    end
    for section, entries in pairs(other_data) do
        if not self._data[section] then
            self._data[section] = {}
        end
        for k, v in pairs(entries) do
            self._data[section][k] = tostring(v)
        end
    end
end

--- Interpolate environment variables. Replaces ${VAR} with os.getenv("VAR").
---@return Config self
function Config:interpolate_env()
    for section, entries in pairs(self._data) do
        for k, v in pairs(entries) do
            self._data[section][k] = v:gsub("%$%{([^}]+)%}", function(var)
                return os.getenv(var) or ""
            end)
        end
    end
    return self
end

--- Validate values against a schema.
--- Schema format: { ["section.key"] = function(value) return true/false end }
---@param schema table
---@return boolean ok, string[] errors
function Config:validate(schema)
    local errors = {}
    for ref, validator in pairs(schema) do
        local s, k = ref:match("^(.-)%.(.+)$")
        if s and k then
            local val = self:get(s, k)
            if val then
                if not validator(val) then
                    errors[#errors + 1] = s .. "." .. k .. " = \"" .. val .. "\" failed validation"
                end
            else
                errors[#errors + 1] = s .. "." .. k .. " not found"
            end
        end
    end
    return #errors == 0, errors
end

--- Write the config back to a file.
---@param file string? Defaults to the original file path
---@return boolean success, string? error
function Config:save(file)
    local fp = io.open(file or self._file, "w")
    if not fp then return false, "cannot open file for writing" end

    for section, entries in pairs(self._data) do
        fp:write("[" .. section .. "]\n")
        for key, value in pairs(entries) do
            fp:write(key .. "=" .. value .. "\n")
        end
        fp:write("\n")
    end

    fp:close()
    return true
end

--- Get the source file path.
---@return string
function Config:get_file()
    return self._file
end

--- String representation.
---@return string
function Config:__tostring()
    local parts = {}
    for section, entries in pairs(self._data) do
        parts[#parts + 1] = "[" .. section .. "]"
        for key, value in pairs(entries) do
            parts[#parts + 1] = key .. "=" .. value
        end
        parts[#parts + 1] = ""
    end
    return table.concat(parts, "\n")
end

return Config
