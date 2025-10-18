---LLM Provider管理系统
local SystemBase = require("Core.GameLayerBase.SystemBase")
local BM_LlmProvider = require("DataLayer.Llm.BM_LlmProvider")

-- Provider实现
local OpenAIProvider = require("GameLayer.Llm.Providers.OpenAIProvider")
local ClaudeProvider = require("GameLayer.Llm.Providers.ClaudeProvider")
local LocalProvider = require("GameLayer.Llm.Providers.LocalProvider")
local QwenProvider = require("GameLayer.Llm.Providers.QwenProvider")

---@class LlmProviderSystem : SystemBase
---@type LlmProviderSystem
local LlmProviderSystem = {}
setmetatable(LlmProviderSystem, { __index = SystemBase })

---初始化系统
function LlmProviderSystem:init()
    -- 先初始化DataModule的数据
    BM_LlmProvider.dataModule:init()
    -- 再初始化BusinessModule属性访问器
    BM_LlmProvider:initializeProperties()
    
    -- 注册内置Provider
    self:RegisterBuiltInProviders()
    
    print("[LlmProviderSystem] Provider系统初始化完成")
end

---注册内置Provider
function LlmProviderSystem:RegisterBuiltInProviders()
    -- OpenAI
    BM_LlmProvider:RegisterProvider("openai", OpenAIProvider:new())
    
    -- Claude
    BM_LlmProvider:RegisterProvider("claude", ClaudeProvider:new())
    
    -- 通义千问 (Qwen)
    BM_LlmProvider:RegisterProvider("qwen", QwenProvider:new())
    
    -- Local (默认localhost:8080)
    BM_LlmProvider:RegisterProvider("local", LocalProvider:new("localhost", 8080))
end

---注册自定义Provider
---@param name string Provider名称
---@param providerInstance table Provider实例
function LlmProviderSystem:RegisterProvider(name, providerInstance)
    BM_LlmProvider:RegisterProvider(name, providerInstance)
end

---切换Provider
---@param name string Provider名称
---@return boolean 是否切换成功
function LlmProviderSystem:SwitchProvider(name)
    return BM_LlmProvider:SwitchProvider(name)
end

---获取当前Provider
---@return table|nil Provider实例
function LlmProviderSystem:GetCurrentProvider()
    return BM_LlmProvider:GetCurrentProvider()
end

---配置Local Provider的地址
---@param host string 主机地址
---@param port number 端口号
function LlmProviderSystem:ConfigureLocalProvider(host, port)
    local localProvider = LocalProvider:new(host, port)
    BM_LlmProvider:RegisterProvider("local", localProvider)
    print(string.format("[LlmProviderSystem] 配置Local Provider: %s:%d", host, port))
end

return LlmProviderSystem

