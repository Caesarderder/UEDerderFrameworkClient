require("LuaPanda").start("127.0.0.1",8818)
---@class SaveSystem
---存档系统，处理游戏的保存和加载逻辑
local systemBase = require("Core.GameLayerBase.SystemBase")
local GameContext = require("Core.GameContext")

local SaveSystem = setmetatable({}, {__index = systemBase})

---初始化系统
function SaveSystem:init()
    self:LoadGame()
end

---销毁
function SaveSystem:dispose()
    self:SaveGame()
end


---保存游戏数据
---@param slotName string 存档槽位名称，默认为"PlayerSave"
function SaveSystem:SaveGame(slotName)
    slotName = slotName or "PlayerSave"
    
    -- 获取存档类（需要在Unreal Editor中创建对应的蓝图类）
    -- local saveGameClass = UE.UClass.Load("/Game/Blueprints/SaveGames/PP_Player.PP_Player_C")
    -- if not saveGameClass then
    --     print("[SaveSystem] 无法加载存档类")
    --     return false
    -- end
    

    
    -- end
    -- 执行保存操作
    local data=GameContext:GetSaveManager().PP_Player
    success = UE.UGameplayStatics.SaveGameToSlot(data, slotName,0)
    if success then
        print("[SaveSystem] 游戏存档保存成功: " .. slotName.. data.CoinNum)
    else
        print("[SaveSystem] 游戏存档保存失败: " .. slotName)
    end
    
    return success
end

---加载游戏数据
---@param slotName string 存档槽位名称，默认为"PlayerSave"
function SaveSystem:LoadGame(slotName)
    slotName = slotName or "PlayerSave"
    
    -- 获取存档类
    local saveGameClass = UE.UClass.Load("/Game/Blueprints/SaveGames/PP_Player.PP_Player_C")
    if not saveGameClass then
        print("[SaveSystem] 无法加载存档类")
        return nil
    end
    
    local saveGameObject
    -- 检查存档是否存在
    if UE.UGameplayStatics.DoesSaveGameExist(slotName, 0) then
        -- 加载存档
        saveGameObject = UE.UGameplayStatics.LoadGameFromSlot(slotName, 0)
        if saveGameObject then
            -- 将saveGameObject转换为PP_Player_C类型
            GameContext:GetSaveManager().PP_Player =saveGameObject:Cast(UE.UClass.Load("/Game/Blueprints/SaveGames/PP_Player.PP_Player_C"))
            print("[SaveSystem] 游戏存档加载成功" .. slotName ..GameContext:GetSaveManager().PP_Player.CoinNum)
        end
    else
        print("[SaveSystem] 没有存档, 创建默认存档: " .. slotName  )
        saveGameObject = UE.UGameplayStatics.CreateSaveGameObject(saveGameClass)
    end
    
    return saveGameObject
end

---检查存档是否存在
---@param slotName string 存档槽位名称，默认为"PlayerSave"
function SaveSystem:DoesSaveGameExist(slotName)
    slotName = slotName or "PlayerSave"
    local exists = UE.UGameplayStatics.DoesSaveGameExist(slotName, 0)
    return exists
end

return SaveSystem