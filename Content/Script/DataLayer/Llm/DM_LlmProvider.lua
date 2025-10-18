local DataModule = require("Core.DataLayerBase.DataModule")

---@class DM_LlmProvider : DataModule
---@type DM_LlmProvider
local DM_LlmProvider = {}
setmetatable(DM_LlmProvider, { __index = DataModule })

DM_LlmProvider.Fields = {
    currentProvider = "openai",  ---@type string 当前使用的提供商
    providers = {},              ---@type table 注册的提供商实例
}

return DM_LlmProvider

