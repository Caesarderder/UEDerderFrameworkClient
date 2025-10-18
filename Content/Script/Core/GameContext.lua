---@class GameContext
---游戏上下文全局类
local EventBus = require("Core.EventBus")
local Consts = require("Util.Consts")

local GameContext = {
    _isInitialized = false,
    worldContext = nil,  -- 公开的worldContext属性
    systems = {},
    managers = {},
    eventCenter = nil,
    businessModule = nil,
}

---初始化GameContext
---@param worldContext userdata World上下文对象
function GameContext:initialize(worldContext)
    -- 如果已经初始化，则直接返回
    if self._isInitialized then
        return
    end

    -- 保存WorldContext供后续使用
    self.worldContext = worldContext
    self.eventCenter = EventBus:new()

    self:startUpManagers()
    self._isInitialized = true
    print("[GameContext] 初始化完成")
end

---销毁GameContext
function GameContext:dispose()
    for _, manager in pairs(self.managers) do
        manager:dispose()
    end
end

---初始化所有Manager
function GameContext:startUpManagers()
    self:registerManagers()
    self:initManagers()
end

---注册Manager
function GameContext:registerManagers()
    -- 初始化UIManager
    self.managers[Consts.ManagerType.SAVE] = require("GameLayer.Save.SaveManager")
    self.managers[Consts.ManagerType.UI] = require("GameLayer.UI.UIManager")
    self.managers[Consts.ManagerType.COIN] = require("GameLayer.Coin.CoinManager")
    self.managers[Consts.ManagerType.LEVEL] = require("GameLayer.Level.LevelManager")
end

---初始化Manager
function GameContext:initManagers()
    ---遍历managers表，并调用manager的Init方法
    for _, manager in pairs(self.managers) do
        manager:init()
    end
end

---获取系统
---@param name string 系统名称
---@return table 系统实例
function GameContext:GetSystem(name)
    return self.systems[name]
end

---注册系统
---@param name string 系统名称
---@param system table 系统实例
function GameContext:RegisterSystem(name, system)
    self.systems[name] = system
end

---获取管理器
---@param managerType string 管理器类型
---@return table 管理器实例
function GameContext:Manager(managerType)
    return self.managers[managerType]
end

---获取UI管理器
---@return table UI管理器实例
function GameContext:GetUIManager()
    return self.managers[Consts.ManagerType.UI]
end

---获取金币管理器
---@return table 金币管理器实例
function GameContext:GetCoinManager()
    return self.managers[Consts.ManagerType.COIN]
end

---获取关卡管理器
---@return table 关卡管理器实例
function GameContext:GetLevelManager()
    return self.managers[Consts.ManagerType.LEVEL]
end

---获取存档管理器
---@return table 存档管理器实例
function GameContext:GetSaveManager()
    return self.managers[Consts.ManagerType.SAVE]
end

---获取事件中心
---@return table 事件中心实例
function GameContext:GetEventCenter()
    return self.eventCenter
end

return GameContext