--- @meta
--- Built-in validators for Config:validate()

local validators = {}

--- Check if a value is a valid number.
---@return fun(value: string): boolean
function validators.is_number()
    return function(value)
        return tonumber(value) ~= nil
    end
end

--- Check if a value is a valid integer.
---@return fun(value: string): boolean
function validators.is_integer()
    return function(value)
        local n = tonumber(value)
        return n ~= nil and n == math.floor(n)
    end
end

--- Check if a value is within a numeric range.
---@param min number
---@param max number
---@return fun(value: string): boolean
function validators.in_range(min, max)
    return function(value)
        local n = tonumber(value)
        return n ~= nil and n >= min and n <= max
    end
end

--- Check if a value matches a pattern.
---@param pattern string Lua pattern
---@return fun(value: string): boolean
function validators.matches(pattern)
    return function(value)
        return value:match(pattern) ~= nil
    end
end

--- Check if a value is one of a set of allowed values.
---@param allowed string[]
---@return fun(value: string): boolean
function validators.one_of(allowed)
    local set = {}
    for _, v in ipairs(allowed) do set[v] = true end
    return function(value)
        return set[value] ~= nil
    end
end

--- Check if a value is not empty.
---@return fun(value: string): boolean
function validators.not_empty()
    return function(value)
        return value ~= nil and value ~= ""
    end
end

--- Check if a value is a valid IP address (v4).
---@return fun(value: string): boolean
function validators.is_ipv4()
    return function(value)
        return value:match("^%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?$") ~= nil
    end
end

--- Check if a value is a valid port number.
---@return fun(value: string): boolean
function validators.is_port()
    return function(value)
        local n = tonumber(value)
        return n ~= nil and n >= 1 and n <= 65535
    end
end

--- Check if a value is a valid boolean string (true/false/yes/no/on/off/1/0).
---@return fun(value: string): boolean
function validators.is_boolean()
    local valid = {
        ["true"] = true, ["false"] = true,
        ["yes"] = true, ["no"] = true,
        ["on"] = true, ["off"] = true,
        ["1"] = true, ["0"] = true,
    }
    return function(value)
        return valid[value:lower()] ~= nil
    end
end

--- Combine multiple validators with AND logic.
---@param ... fun(value: string): boolean
---@return fun(value: string): boolean
function validators.all_of(...)
    local checks = { ... }
    return function(value)
        for _, check in ipairs(checks) do
            if not check(value) then return false end
        end
        return true
    end
end

--- Combine multiple validators with OR logic.
---@param ... fun(value: string): boolean
---@return fun(value: string): boolean
function validators.any_of(...)
    local checks = { ... }
    return function(value)
        for _, check in ipairs(checks) do
            if check(value) then return true end
        end
        return false
    end
end

return validators
