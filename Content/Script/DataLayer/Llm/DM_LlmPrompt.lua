local DataModule = require("Core.DataLayerBase.DataModule")

---@class DM_LlmPrompt : DataModule
---@type DM_LlmPrompt
local DM_LlmPrompt = {}
setmetatable(DM_LlmPrompt, { __index = DataModule })

DM_LlmPrompt.Fields = {
    templates = {},  ---@type table 存储所有ChatType的模板配置
}

return DM_LlmPrompt

