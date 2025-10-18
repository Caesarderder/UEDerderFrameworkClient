---金币主系统
local SystemBase = require("Core.GameLayerBase.SystemBase")
local BM_Coin = require("DataLayer.Coin.BM_Coin")
local GameContext = require("Core.GameContext")

---@class CoinMainSystem : SystemBase
local CoinMainSystem = setmetatable({}, {__index = SystemBase})

---初始化系统
function CoinMainSystem:init()
    -- 先初始化DataModule的数据
    BM_Coin.dataModule:init()
    -- 再初始化BusinessModule的属性访问器
    BM_Coin:initializeProperties()
    
    BM_Coin:AddCoin(100)
    print("[CoinMainSystem] 金币主系统初始化完成")
end

---增加金币
---@param amount number 增加的金币数量
function CoinMainSystem:AddCoin(amount)
    BM_Coin.CoinNum.set(BM_Coin.CoinNum.get() + amount)
end

---消耗金币
---@param amount number 消耗的金币数量
---@return boolean 是否消耗成功
function CoinMainSystem:consumeCoin(amount)
    local current = BM_Coin.CoinNum.get()
    if current >= amount then
        BM_Coin.CoinNum.set(current - amount)
        return true
    end
    return false
end

---检查金币是否足够
---@param amount number 需要检查的金币数量
---@return boolean 是否足够
function CoinMainSystem:checkCoin(amount)
    return BM_Coin.CoinNum.get() >= amount
end

---注册金币变化监听
---@param callback fun(newValue: number, oldValue: number) 回调函数
---@return function 回调函数，用于后续移除
function CoinMainSystem:registerCoinChangeCallback(callback)
    return BM_Coin.CoinNum.AddListener(callback)
end

---取消金币变化监听
---@param callback fun(newValue: number, oldValue: number) 回调函数
function CoinMainSystem:unregisterCoinChangeCallback(callback)
    BM_Coin.CoinNum.RemoveListener(callback)
end

---保存游戏数据
function CoinMainSystem:saveGameData()
    local saveManager = GameContext:GetSaveManager()
    if saveManager then
        -- Create a save data table with current coin value
        local saveData = {
            coins = BM_Coin.CoinNum.get(),
            timestamp = UE.UKismetSystemLibrary.Now()
        }
        
        print("[CoinMainSystem] 保存游戏数据: " .. saveData.coins .. " 金币")
        return saveManager:SaveGame("PlayerSave")
    else
        print("[CoinMainSystem] 无法获取存档管理器")
        return false
    end
end

---加载游戏数据
function CoinMainSystem:loadGameData()
    local saveManager = GameContext:GetSaveManager()
    if saveManager then
        local saveObject = saveManager:LoadGame("PlayerSave")
        if saveObject then
            -- In a real implementation, you would restore the coin value from saveObject
            print("[CoinMainSystem] 加载游戏数据成功")
        else
            print("[CoinMainSystem] 无存档可加载")
        end
        return saveObject
    else
        print("[CoinMainSystem] 无法获取存档管理器")
        return nil
    end
end

return CoinMainSystem