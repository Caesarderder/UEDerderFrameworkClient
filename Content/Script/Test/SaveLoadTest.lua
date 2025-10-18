---@class SaveLoadTest
---存档加载测试脚本

local GameContext = require("Core.GameContext")

local SaveLoadTest = {}

---测试保存游戏
function SaveLoadTest:TestSave()
    print("[SaveLoadTest] 开始测试保存功能")
    
    -- 获取存档管理器
    local saveManager = GameContext:GetSaveManager()
    if not saveManager then
        print("[SaveLoadTest] 错误：无法获取存档管理器")
        return false
    end
    
    -- 保存游戏
    local success = saveManager:SaveGame("TestSave")
    if success then
        print("[SaveLoadTest] 游戏保存成功")
    else
        print("[SaveLoadTest] 游戏保存失败")
    end
    
    return success
end

---测试加载游戏
function SaveLoadTest:TestLoad()
    print("[SaveLoadTest] 开始测试加载功能")
    
    -- 获取存档管理器
    local saveManager = GameContext:GetSaveManager()
    if not saveManager then
        print("[SaveLoadTest] 错误：无法获取存档管理器")
        return nil
    end
    
    -- 检查存档是否存在
    local exists = saveManager:DoesSaveGameExist("TestSave")
    if not exists then
        print("[SaveLoadTest] 存档不存在")
        return nil
    end
    
    -- 加载游戏
    local saveObject = saveManager:LoadGame("TestSave")
    if saveObject then
        print("[SaveLoadTest] 游戏加载成功")
    else
        print("[SaveLoadTest] 游戏加载失败")
    end
    
    return saveObject
end

return SaveLoadTest