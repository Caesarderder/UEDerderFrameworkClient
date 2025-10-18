---LLM Prompt模板管理系统
local SystemBase = require("Core.GameLayerBase.SystemBase")
local BM_LlmPrompt = require("DataLayer.Llm.BM_LlmPrompt")
local LlmPromptConfig = require("Config.LlmPromptConfig")

---@class LlmPromptSystem : SystemBase
---@type LlmPromptSystem
local LlmPromptSystem = {}
setmetatable(LlmPromptSystem, { __index = SystemBase })

---初始化系统
function LlmPromptSystem:init()
    -- 先初始化DataModule的数据
    BM_LlmPrompt.dataModule:init()
    -- 再初始化BusinessModule属性访问器
    BM_LlmPrompt:initializeProperties()
    
    -- 加载默认模板
    self:LoadDefaultTemplates()
    
    print("[LlmPromptSystem] Prompt模板系统初始化完成")
end

---加载默认模板
function LlmPromptSystem:LoadDefaultTemplates()
    for chatType, template in pairs(LlmPromptConfig) do
        BM_LlmPrompt:RegisterTemplate(chatType, template)
    end
    print("[LlmPromptSystem] 加载默认模板完成")
end

---注册自定义模板
---@param chatType string ChatType名称
---@param template table 模板配置
function LlmPromptSystem:RegisterTemplate(chatType, template)
    BM_LlmPrompt:RegisterTemplate(chatType, template)
end

---获取模板
---@param chatType string ChatType名称
---@return table|nil 模板配置
function LlmPromptSystem:GetTemplate(chatType)
    return BM_LlmPrompt:GetTemplate(chatType)
end

---构建Prompt
---@param chatType string ChatType名称
---@param params table 参数表
---@return string|nil 构建后的Prompt
function LlmPromptSystem:BuildPrompt(chatType, params)
    return BM_LlmPrompt:BuildPrompt(chatType, params)
end

---获取模板的工具列表
---@param chatType string ChatType名称
---@return table 工具名称列表
function LlmPromptSystem:GetTemplateTools(chatType)
    return BM_LlmPrompt:GetTemplateTools(chatType)
end

---获取模板的配置参数
---@param chatType string ChatType名称
---@return table 配置参数
function LlmPromptSystem:GetTemplateConfig(chatType)
    return BM_LlmPrompt:GetTemplateConfig(chatType)
end

return LlmPromptSystem

