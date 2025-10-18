---@class CoinManager
---金币管理器
local ManagerBase = require("Core.GameLayerBase.ManagerBase")
local CoinMainSystem = require("GameLayer.Coin.CoinMainSystem")
local consts = require("Util.Consts")

---@type CoinManager
local CoinManager = setmetatable({
    ---@type CoinMainSystem
    coinMainSystem = CoinMainSystem:new()

}, {__index = ManagerBase})

---初始化
function CoinManager:init()
    -- 调用父类init，初始化systems表
    ManagerBase.init(self)
    -- 注册主系统
    self:registerSystem(consts.SystemType.COIN_MAIN, self.coinMainSystem)
end

--[[
    金币操作接口
--]]

---增加金币
---@param amount number 增加的金币数量
function CoinManager:addCoin(amount)
end

---消耗金币
---@param amount number 消耗的金币数量
---@return boolean 是否消耗成功
function CoinManager:consumeCoin(amount)
    return self:getMainSystem():consumeCoin(amount)
end

---检查金币是否足够
---@param amount number 需要检查的金币数量
---@return boolean 是否足够
function CoinManager:checkCoin(amount)
    return self:getMainSystem():checkCoin(amount)
end

---注册金币变化监听
---@param callback fun(newValue: number, oldValue: number) 回调函数
---@return function 回调函数，用于后续移除
function CoinManager:registerCoinChangeCallback(callback)
    return self:getMainSystem():registerCoinChangeCallback(callback)
end

---取消金币变化监听
---@param callback fun(newValue: number, oldValue: number) 回调函数
function CoinManager:unregisterCoinChangeCallback(callback)
    self:getMainSystem():unregisterCoinChangeCallback(callback)
end

---保存游戏数据
function CoinManager:saveGameData()
    return self:getMainSystem():saveGameData()
end

---加载游戏数据
function CoinManager:loadGameData()
    return self:getMainSystem():loadGameData()
end

return CoinManager