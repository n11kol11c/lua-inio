--- @meta
--- Utility functions for working with INI data

local utils = {}

--- Deep copy a table.
---@param tbl table
---@return table
function utils.deep_copy(tbl)
    if type(tbl) ~= "table" then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[utils.deep_copy(k)] = utils.deep_copy(v)
    end
    return setmetatable(copy, getmetatable(tbl))
end

--- Deep merge two tables. Second table overrides first.
---@param base table
---@param override table
---@return table
function utils.deep_merge(base, override)
    local result = utils.deep_copy(base)
    for k, v in pairs(override) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = utils.deep_merge(result[k], v)
        else
            result[k] = utils.deep_copy(v)
        end
    end
    return result
end

--- Filter keys from a table.
---@param tbl table
---@param predicate fun(key: string, value: string): boolean
---@return table
function utils.filter(tbl, predicate)
    local result = {}
    for k, v in pairs(tbl) do
        if predicate(k, v) then
            result[k] = v
        end
    end
    return result
end

--- Map values in a table.
---@param tbl table
---@param transform fun(key: string, value: string): string
---@return table
function utils.map(tbl, transform)
    local result = {}
    for k, v in pairs(tbl) do
        result[k] = transform(k, v)
    end
    return result
end

--- Flatten a nested INI table into dot-notation keys.
--- { server = { ip = "127.0.0.1" } } --> { ["server.ip"] = "127.0.0.1" }
---@param data table
---@return table
function utils.flatten(data)
    local result = {}
    for section, entries in pairs(data) do
        for key, value in pairs(entries) do
            result[section .. "." .. key] = value
        end
    end
    return result
end

--- Unflatten dot-notation keys back into nested INI table.
--- { ["server.ip"] = "127.0.0.1" } --> { server = { ip = "127.0.0.1" } }
---@param data table
---@return table
function utils.unflatten(data)
    local result = {}
    for ref, value in pairs(data) do
        local section, key = ref:match("^(.-)%.(.+)$")
        if section and key then
            if not result[section] then
                result[section] = {}
            end
            result[section][key] = value
        end
    end
    return result
end

--- Convert INI data to a JSON-compatible string (manual, no json lib needed).
---@param data table
---@param indent number? Indentation level (default 2)
---@return string
function utils.to_json(data, indent)
    indent = indent or 2
    local parts = {}
    local pad = string.rep(" ", indent)
    local pad2 = string.rep(" ", indent * 2)

    parts[#parts + 1] = "{"
    local first = true
    for section, entries in pairs(data) do
        if not first then parts[#parts + 1] = "," end
        first = false
        parts[#parts + 1] = pad2 .. '"' .. section .. '": {'
        local inner_first = true
        for key, value in pairs(entries) do
            if not inner_first then parts[#parts + 1] = "," end
            inner_first = false
            parts[#parts + 1] = pad2 .. pad .. '"' .. key .. '": "' .. value .. '"'
        end
        parts[#parts + 1] = pad2 .. "}"
    end
    parts[#parts + 1] = "}"
    return table.concat(parts, "\n")
end

return utils
