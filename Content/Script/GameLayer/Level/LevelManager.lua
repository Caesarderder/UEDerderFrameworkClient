---@class LevelManager
---关卡管理器
local ManagerBase = require("Core.GameLayerBase.ManagerBase")
local LevelMainSystem = require("GameLayer.Level.LevelMainSystem")
local consts = require("Util.Consts")

local LevelManager = setmetatable({}, {__index = ManagerBase})

---@type LevelMainSystem
LevelManager.mainSystem = LevelMainSystem:new() 


---初始化
function LevelManager:init()
    -- 调用父类init，初始化systems表
    ManagerBase.init(LevelManager)
    
    -- 注册主系统
    LevelManager:registerSystem(consts.SystemType.LEVEL_MAIN, self.mainSystem)
    
end

---获取主系统
---@return LevelMainSystem
function LevelManager:getMainSystem()
    return LevelManager:getSystem(consts.SystemType.LEVEL_MAIN)
end

--[[
    关卡操作接口
--]]

---切换关卡
---@param levelName string 关卡名称
function LevelManager:switchLevel(levelName)
    return LevelManager:getMainSystem():switchLevel(levelName)
end

---获取当前关卡
---@return string 当前关卡名称
function LevelManager:getCurrentLevel()
    return LevelManager:getMainSystem():getCurrentLevel()
end

---获取关卡历史
---@return table 关卡历史列表
function LevelManager:getLevelHistory()
    return LevelManager:getMainSystem():getLevelHistory()
end

return LevelManager