---@class DataModule
---数据层基类
---简单的数据结构,提供原始的持久化数据存储
---提供基础的数据操作,只可被BusinessModule调用
local DataModule = {}

---@class DataModuleFields
---数据字段定义
---继承此类的模块需要在Fields中定义具体的数据字段
---@field fieldName any 字段说明
DataModule.Fields = {
    -- 在这里定义具体的数据字段
    -- 例如：
    -- playerName = "",  ---@type string 玩家名称
    -- playerLevel = 0,  ---@type number 玩家等级
}

---初始化数据
function DataModule:init()
    -- 使用 Fields 中定义的结构进行初始化
    for field, defaultValue in pairs(self.Fields) do
        self[field] = defaultValue
    end

    -- 设置元表以支持点语法访问
    local mt = {
        __index = function(t, k)
            if DataModule.Fields[k] ~= nil then
                return rawget(t, k)
            end
            return DataModule[k]
        end,
        
        __newindex = function(t, k, v)
            if DataModule.Fields[k] ~= nil then
                rawset(t, k, v)
            else
                error("Attempt to set undefined field: " .. k)
            end
        end
    }
    setmetatable(self, mt)
end

---批量设置数据
---@param data table 数据表
function DataModule:setBatch(data)
    for field, value in pairs(data) do
        if self.Fields[field] ~= nil then
            self[field] = value
        else
            error("Attempt to set undefined field in batch: " .. field)
        end
    end
end

---重置数据
function DataModule:reset()
    self:init()
end

return DataModule