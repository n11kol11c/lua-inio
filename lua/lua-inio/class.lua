--- @meta
--- Python-like class system for Lua

local class = {}

--- Create a new class with optional __init constructor.
--- Usage:
---   local Animal = class("Animal")
---   function Animal:__init(name, sound)
---       self.name = name
---       self.sound = sound
---   end
---   function Animal:speak()
---       return self.name .. " says " .. self.sound
---   end
---   local dog = Animal("Rex", "Woof")
---   print(dog:speak())  --> Rex says Woof
---@param name string? Optional class name for debugging
---@return table cls The class table
function class.new(name)
    local cls = {}
    cls.__index = cls
    cls.__name = name or "AnonymousClass"

    function cls:__tostring()
        return cls.__name .. "()"
    end

    -- Make the class callable: MyClass(args) calls MyClass:__init(args)
    setmetatable(cls, {
        __call = function(self, ...)
            local instance = setmetatable({}, cls)
            if instance.__init then
                instance:__init(...)
            end
            return instance
        end,
    })

    return cls
end

--- Check if an object is an instance of a class.
---@param obj table The object to check
---@param cls table The class to check against
---@return boolean
function class.isinstance(obj, cls)
    if type(obj) ~= "table" then return false end
    local mt = getmetatable(obj)
    while mt do
        if mt == cls then return true end
        mt = getmetatable(mt)
    end
    return false
end

--- Get the class name of an object.
---@param obj table
---@return string
function class.classname(obj)
    if type(obj) ~= "table" then return type(obj) end
    local mt = getmetatable(obj)
    if mt and mt.__name then return mt.__name end
    return "Unknown"
end

return class
