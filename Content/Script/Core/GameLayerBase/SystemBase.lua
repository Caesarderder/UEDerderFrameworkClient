local SystemBase = {}

function SystemBase:new()
    local instance = {}
    setmetatable(instance, self)
    self.__index = self
    return instance
end

function SystemBase:init()
    -- Initialization code for system
end

function SystemBase:dispose()
    -- dispose code for system
end

return SystemBase