local BusinessModule = require("Core.DataLayerBase.BusinessModule")
local DM_Coin = require("DataLayer.Coin.DM_Coin")

---金币业务模块
---@class BM_Coin : BusinessModule
---@type BM_Coin
local BM_Coin = {
    ---@type DM_Coin
    dataModule = DM_Coin 
}

setmetatable(BM_Coin, { __index = BusinessModule })

function BM_Coin:AddCoin(number)
    if number > 0 then
        self.dataModule.coinNum = self.dataModule.coinNum + number
    end
end

return BM_Coin