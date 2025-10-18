---@class SaveManager
---存档管理器
local managerBase = require("Core.GameLayerBase.ManagerBase")
local consts = require("Util.Consts")
local PP_Player = require("GameLayer.Save.PP_Player")

local SaveManager = setmetatable({}, {__index = managerBase})

-- 添加PP_Player变量
SaveManager.PP_Player = nil

---初始化
function SaveManager:init()
    -- 调用父类init，初始化systems表
    managerBase.init(self)

    -- 注册主系统
    local SaveSystem = require("GameLayer.Save.Systems.SaveLifeCircleSystem")
    self:registerSystem(consts.SystemType.SAVE_MAIN, SaveSystem)
end

---获取主系统
---@return SaveSystem
function SaveManager:getMainSystem()
    return self:getSystem(consts.SystemType.SAVE_MAIN)
end

--[[
    存档操作接口
--]]

---保存游戏
---@param slotName string 存档槽位名称，默认为"PlayerSave"
function SaveManager:SavePlayerData(slotName)
    return self:getMainSystem():SaveGame(slotName)
end

---加载游戏
---@param slotName string 存档槽位名称，默认为"PlayerSave"
function SaveManager:LoadPlayerData(slotName)
    local loadedData = self:getMainSystem():LoadGame(slotName)
    self.PP_Player = loadedData
    return loadedData
end

---检查存档是否存在
---@param slotName string 存档槽位名称，默认为"PlayerSave"
function SaveManager:DoesSaveGameExist(slotName)
    return self:getMainSystem():DoesSaveGameExist(slotName)
end

return SaveManager