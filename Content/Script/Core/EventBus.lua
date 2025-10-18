local EventBus = {}

function EventBus:new()
    local instance = {
        listeners = {}
    }
    setmetatable(instance, self)
    self.__index = self
    return instance
end

function EventBus:register(eventType, listener)
    if not self.listeners[eventType] then
        self.listeners[eventType] = {}
    end
    table.insert(self.listeners[eventType], listener)
end

function EventBus:trigger(eventType, ...)
    local listeners = self.listeners[eventType]
    if listeners then
        for _, listener in ipairs(listeners) do
            listener(...)
        end
    end
end

return EventBus