local DataModule = require("Core.DataLayerBase.DataModule")

---@class DM_LlmTool : DataModule
---@type DM_LlmTool
local DM_LlmTool = {}
setmetatable(DM_LlmTool, { __index = DataModule })

DM_LlmTool.Fields = {
    -- 注册的工具定义
    registeredTools = {},        ---@type table 已注册的工具定义表 {toolName: toolDef}
    
    -- 启用的工具列表
    enabledTools = {},          ---@type table 已启用的工具名称列表
    
    -- 工具调用历史
    toolCallHistory = {},       ---@type table 工具调用历史记录
}

return DM_LlmTool

