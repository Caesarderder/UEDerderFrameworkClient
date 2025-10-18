---@class ManagerBase
---Manager基类，所有Manager继承此类
local ManagerBase = {}

---初始化Manager
function ManagerBase:init()
    -- 初始化系统表
    if not self.systems then
        self.systems = {}
    end
end

---注册系统
---@param systemType string 系统类型
---@param systemClass table 系统类
function ManagerBase:registerSystem(systemType, systemClass)
    -- 确保systems表存在
    if not self.systems then
        self.systems = {}
    end
    
    -- 创建系统实例
    self.systems[systemType] = systemClass:new()
    
    -- 调用系统的Init方法
    if self.systems[systemType].init then
        self.systems[systemType]:init()
    end
end

---销毁Manager
function ManagerBase:dispose()
    ---遍历managers表，并调用manager的Init方法
    for _, system in pairs(self.systems) do
        system:dispose()
    end
end


---获取系统
---@param systemType string 系统类型
---@return table 系统实例
function ManagerBase:getSystem(systemType)
    return self.systems and self.systems[systemType] or nil
end

---获取所有系统
---@return table 所有系统
function ManagerBase:getAllSystems()
    return self.systems or {}
end

return ManagerBase