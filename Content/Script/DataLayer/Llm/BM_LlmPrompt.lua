local BusinessModule = require("Core.DataLayerBase.BusinessModule")
local DM_LlmPrompt = require("DataLayer.Llm.DM_LlmPrompt")

---@class BM_LlmPrompt : BusinessModule
---@type BM_LlmPrompt
local BM_LlmPrompt = {
    ---@type DM_LlmPrompt
    dataModule = DM_LlmPrompt
}

setmetatable(BM_LlmPrompt, { __index = BusinessModule })

---注册模板
---@param chatType string ChatType名称
---@param template table 模板配置
function BM_LlmPrompt:RegisterTemplate(chatType, template)
    self.dataModule.templates[chatType] = template
    print("[BM_LlmPrompt] 注册模板: " .. chatType)
end

---获取模板
---@param chatType string ChatType名称
---@return table|nil 模板配置
function BM_LlmPrompt:GetTemplate(chatType)
    return self.dataModule.templates[chatType]
end

---模板变量替换
---@param text string 模板文本
---@param params table 参数表
---@return string 替换后的文本
function BM_LlmPrompt:ReplaceVariables(text, params)
    if not params then
        return text
    end
    
    local result = text
    for key, value in pairs(params) do
        local pattern = "{" .. key .. "}"
        result = string.gsub(result, pattern, tostring(value))
    end
    return result
end

---构建完整的Prompt
---@param chatType string ChatType名称
---@param params table 参数表
---@return string|nil 构建后的Prompt
function BM_LlmPrompt:BuildPrompt(chatType, params)
    local template = self:GetTemplate(chatType)
    if not template then
        print("[BM_LlmPrompt] 模板不存在: " .. chatType)
        return nil
    end
    
    local systemPrompt = template.systemPrompt or ""
    return self:ReplaceVariables(systemPrompt, params)
end

---获取模板的工具列表
---@param chatType string ChatType名称
---@return table 工具名称列表
function BM_LlmPrompt:GetTemplateTools(chatType)
    local template = self:GetTemplate(chatType)
    if not template then
        return {}
    end
    return template.tools or {}
end

---获取模板的配置参数
---@param chatType string ChatType名称
---@return table 配置参数
function BM_LlmPrompt:GetTemplateConfig(chatType)
    local template = self:GetTemplate(chatType)
    if not template then
        return {}
    end
    
    return {
        temperature = template.temperature,
        maxTokens = template.maxTokens,
        topP = template.topP
    }
end

return BM_LlmPrompt

