---@class BM_Level
---关卡业务模块
local dm_Level = require("DataLayer.Level.DM_Level")

local bm_Level = {}

---设置当前关卡
---@param levelName string 关卡名称
function bm_Level.setCurrentLevel(levelName)
    dm_Level.currentLevel = levelName
    table.insert(dm_Level.levelHistory, levelName)
end

---获取当前关卡
---@return string 当前关卡名称
function bm_Level.getCurrentLevel()
    return dm_Level.currentLevel
end

---获取关卡历史
---@return table 关卡历史列表
function bm_Level.getLevelHistory()
    return dm_Level.levelHistory
end

return bm_Level