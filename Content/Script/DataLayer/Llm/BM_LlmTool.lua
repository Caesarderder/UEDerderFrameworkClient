local BusinessModule = require("Core.DataLayerBase.BusinessModule")
local DM_LlmTool = require("DataLayer.Llm.DM_LlmTool")

---@class BM_LlmTool : BusinessModule
---@type BM_LlmTool
local BM_LlmTool = {
    ---@type DM_LlmTool
    dataModule = DM_LlmTool
}

setmetatable(BM_LlmTool, { __index = BusinessModule })

---注册工具
---@param toolDef table 工具定义
function BM_LlmTool:RegisterTool(toolDef)
    if not toolDef.name or not toolDef.description or not toolDef.execute then
        error("工具定义不完整: 需要name, description, execute")
    end
    
    self.dataModule.registeredTools[toolDef.name] = toolDef
    table.insert(self.dataModule.enabledTools, toolDef.name)
end

---获取工具定义（OpenAI格式）
---@return table 工具定义列表
function BM_LlmTool:GetToolsForRequest()
    local tools = {}
    
    for _, toolName in ipairs(self.dataModule.enabledTools) do
        local toolDef = self.dataModule.registeredTools[toolName]
        if toolDef then
            table.insert(tools, {
                type = "function",
                ["function"] = {
                    name = toolDef.name,
                    description = toolDef.description,
                    parameters = toolDef.parameters or {
                        type = "object",
                        properties = {},
                        required = {}
                    }
                }
            })
        end
    end
    
    return tools
end

---执行工具调用
---@param toolName string 工具名称
---@param arguments table 工具参数
---@return boolean, any 是否成功，执行结果
function BM_LlmTool:ExecuteTool(toolName, arguments)
    local toolDef = self.dataModule.registeredTools[toolName]
    if not toolDef then
        return false, "工具不存在: " .. toolName
    end
    
    -- 记录调用历史
    table.insert(self.dataModule.toolCallHistory, {
        toolName = toolName,
        arguments = arguments,
        timestamp = os.time()
    })
    
    -- 执行工具
    local success, result = pcall(toolDef.execute, arguments)
    return success, result
end

return BM_LlmTool


