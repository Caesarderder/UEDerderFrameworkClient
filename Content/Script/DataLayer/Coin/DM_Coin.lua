local DataModule = require("Core.DataLayerBase.DataModule")

---金币数据模块
---@class DM_Coin : DataModule
---@type DM_Coin
local DM_Coin = {}
setmetatable(DM_Coin, { __index = DataModule })

DM_Coin.Fields = {
    coinNum = 0,  ---@type number 金币数量
}

return DM_Coin