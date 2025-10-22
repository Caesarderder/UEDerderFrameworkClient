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
---@param params table 参数表 {typeArgs: table, normalArgs: table}
---@return string|nil 构建后的Prompt
function BM_LlmPrompt:BuildPrompt(chatType, params)
    local template = self:GetTemplate(chatType)
    if not template then
        print("[BM_LlmPrompt] 模板不存在: " .. chatType)
        return nil
    end
    
    local systemPrompt = template.systemPrompt or ""
    
    -- 1. 使用 typeArgs 替换模板变量
    local typeArgs = params.typeArgs or {}
    systemPrompt = self:ReplaceVariables(systemPrompt, typeArgs)
    
    -- 2. 使用 normalArgs 添加通用提示
    local normalArgs = params.normalArgs or {}
    if next(normalArgs) ~= nil then
        local additionalPrompts = self:BuildNormalArgsPrompt(normalArgs)
        if additionalPrompts ~= "" then
            systemPrompt = systemPrompt .. "\n\n" .. additionalPrompts
        end
    end
    
    return systemPrompt
end

---构建通用参数的提示文本（支持 OtherOptions）
---@param normalArgs table 通用参数（OtherOptions）
---@return string 提示文本
function BM_LlmPrompt:BuildNormalArgsPrompt(normalArgs)
    local parts = {}
    
    -- 【新架构】处理 includePrompts
    local includePrompts = normalArgs.includePrompts or {}
    local customPrompts = normalArgs.customPrompts or {}
    
    for _, promptType in ipairs(includePrompts) do
        if promptType == "enemy_context" and customPrompts.enemy_context then
            table.insert(parts, "## 🎭 仇人对话上下文")
            table.insert(parts, customPrompts.enemy_context)
        elseif promptType == "loop_context" and customPrompts.loop_context then
            table.insert(parts, "## 🔄 时间循环上下文")
            table.insert(parts, customPrompts.loop_context)
        elseif promptType == "unlock_conditions" then
            -- 解锁条件（兼容旧架构）
            local conditions = normalArgs.unlockConditions or customPrompts.unlock_conditions
            if conditions then
                table.insert(parts, "## 🎯 当前解锁条件")
                table.insert(parts, conditions)
            end
        end
    end
    
    -- 【兼容旧架构】直接提供的参数
    if not next(includePrompts) then
        -- 解锁条件
        if normalArgs.unlockConditions then
            table.insert(parts, "## 🎯 当前解锁条件")
            table.insert(parts, normalArgs.unlockConditions)
        end
        
        -- 特殊指示
        if normalArgs.specialInstructions then
            table.insert(parts, "## 📌 特殊指示")
            table.insert(parts, normalArgs.specialInstructions)
        end
        
        -- 上下文信息
        if normalArgs.contextInfo then
            table.insert(parts, "## 📖 当前上下文")
            table.insert(parts, normalArgs.contextInfo)
        end
    end
    
    return table.concat(parts, "\n")
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


