---@class LevelMainSystem
---关卡主系统
local SystemBase = require("Core.GameLayerBase.SystemBase")
local BM_Level = require("DataLayer.Level.BM_Level")
local GameContext = require("Core.GameContext")

local LevelMainSystem = setmetatable({}, {__index = SystemBase})

---初始化系统
function LevelMainSystem:init()
    print("[LevelMainSystem] 关卡主系统初始化完成")
end

---切换关卡
---@param levelName string 关卡名称
function LevelMainSystem:switchLevel(levelName)
    worldContext=GameContext.worldContext
    
    if not levelName or levelName == "" then
        print("[LevelMainSystem] 错误: 无效的关卡名称")
        return false
    end
    
    -- 更新当前关卡信息
    BM_Level.setCurrentLevel(levelName)
    
    -- 执行关卡切换
    UE.UGameplayStatics.OpenLevel(worldContext, levelName)
    
    print("[LevelMainSystem] 开始切换到关卡: " .. levelName)
    return true
end

---获取当前关卡
---@return string 当前关卡名称
function LevelMainSystem:getCurrentLevel()
    return BM_Level.getCurrentLevel()
end

---获取关卡历史
---@return table 关卡历史列表
function LevelMainSystem:getLevelHistory()
    return BM_Level.getLevelHistory()
end

return LevelMainSystem