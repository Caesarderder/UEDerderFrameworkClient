---@class BusinessModule
---@field dataModule DataModule
---业务层基类
---作为DataProvider提供DataModule的数据加工服务
---提供加工后的数据获取方法,以及对业务数据的监听服务
local BusinessModule = {}

---初始化属性
function BusinessModule:initializeProperties()
    -- 为每个字段创建属性
    for field, _ in pairs(self.dataModule.Fields) do
        local propName = field:sub(1,1):upper() .. field:sub(2)
        self[propName] = {
            -- 获取值
            get = function()
                return self.dataModule[field]
            end,
            
            -- 设置值
            set = function(value)
                local oldValue = self.dataModule[field]
                self.dataModule[field] = value
                -- 触发事件
                if self[propName].onChange then
                    for _, handler in ipairs(self[propName].onChange) do
                        handler(value, oldValue)
                    end
                end
            end,
            
            -- 事件处理器列表
            onChange = {},
            
            -- 添加事件监听器
            AddListener = function(handler)
                local handlers = self[propName].onChange
                table.insert(handlers, handler)
                return handler  -- 返回handler以便后续移除
            end,

            -- 移除事件监听器
            RemoveListener = function(handler)
                local handlers = self[propName].onChange
                for i, h in ipairs(handlers) do
                    if h == handler then
                        table.remove(handlers, i)
                        break
                    end
                end
            end
        }
    end
end

return BusinessModule