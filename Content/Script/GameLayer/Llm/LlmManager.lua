---LLM管理器（重构版）
---提供简化的统一接口
local ManagerBase = require("Core.GameLayerBase.ManagerBase")
local Consts = require("Util.Consts")

-- Systems
local HttpClientSystem = require("GameLayer.Llm.Systems.HttpClientSystem")
local LlmStreamSystem = require("GameLayer.Llm.Systems.LlmStreamSystem")
local LlmProviderSystem = require("GameLayer.Llm.Systems.LlmProviderSystem")
local LlmPromptSystem = require("GameLayer.Llm.Systems.LlmPromptSystem")
local LlmClientSystem = require("GameLayer.Llm.Systems.LlmClientSystem")
local LlmConfigSystem = require("GameLayer.Llm.Systems.LlmConfigSystem")
local LlmContextSystem = require("GameLayer.Llm.Systems.LlmContextSystem")
local LlmToolSystem = require("GameLayer.Llm.Systems.LlmToolSystem")
local LlmReActSystem = require("GameLayer.Llm.Systems.LlmReActSystem")

---@class LlmManager : ManagerBase
---@type LlmManager
local LlmManager = setmetatable({}, {__index = ManagerBase})

---初始化
function LlmManager:init()
    -- 调用父类init，初始化systems表
    ManagerBase.init(self)
    
    -- 创建系统实例
    local httpClient = HttpClientSystem:new()
    local streamSystem = LlmStreamSystem:new()
    local providerSystem = LlmProviderSystem:new()
    local promptSystem = LlmPromptSystem:new()
    local configSystem = LlmConfigSystem:new()
    local contextSystem = LlmContextSystem:new()
    local toolSystem = LlmToolSystem:new()
    
    -- 初始化基础系统
    httpClient:init()
    streamSystem:init()
    providerSystem:init()
    promptSystem:init()
    configSystem:init()
    contextSystem:init()
    toolSystem:init()
    
    -- 初始化依赖系统
    local llmClient = LlmClientSystem:new()
    llmClient:init(httpClient, providerSystem, streamSystem)
    
    local reactSystem = LlmReActSystem:new()
    reactSystem:init(llmClient, contextSystem, toolSystem, promptSystem)
    
    -- 注册所有系统
    self.systems[Consts.SystemType.HTTP_CLIENT] = httpClient
    self.systems[Consts.SystemType.LLM_STREAM] = streamSystem
    self.systems[Consts.SystemType.LLM_PROVIDER] = providerSystem
    self.systems[Consts.SystemType.LLM_PROMPT] = promptSystem
    self.systems[Consts.SystemType.LLM_CONFIG] = configSystem
    self.systems[Consts.SystemType.LLM_CONTEXT] = contextSystem
    self.systems[Consts.SystemType.LLM_TOOL] = toolSystem
    self.systems[Consts.SystemType.LLM_CLIENT] = llmClient
    self.systems[Consts.SystemType.LLM_REACT] = reactSystem
    
    print("[LlmManager] LLM管理器初始化完成")
end

--[[
    核心Chat接口 - 简化的业务调用
--]]

---发送Chat请求（统一接口）
---@param chatType string ChatType类型
---@param params table 参数表
---@param onStream function|nil 流式回调 function(delta: string)
---@param onComplete function|nil 完成回调 function(success: boolean, result: string)
function LlmManager:Chat(chatType, params, onStream, onComplete)
    local reactSystem = self.systems[Consts.SystemType.LLM_REACT]
    
    -- 如果提供了流式回调，使用流式模式
    if onStream then
        reactSystem:ProcessStream(chatType, params, onStream, onComplete)
    else
        -- 非流式模式
        local success, result = reactSystem:Process(chatType, params)
        if onComplete then
            onComplete(success, result)
        end
    end
end

--[[
    配置接口
--]]

---设置API密钥
---@param apiKey string API密钥
function LlmManager:SetApiKey(apiKey)
    self.systems[Consts.SystemType.LLM_CONFIG]:SetApiKey(apiKey)
end

---设置模型
---@param model string 模型名称
function LlmManager:SetModel(model)
    self.systems[Consts.SystemType.LLM_CONFIG]:SetModel(model)
end

---设置温度
---@param temperature number 温度值
function LlmManager:SetTemperature(temperature)
    self.systems[Consts.SystemType.LLM_CONFIG]:SetTemperature(temperature)
end

---使用Provider
---@param provider string Provider名称 (openai/claude/local)
---@param ... any 额外参数（如local的host和port）
function LlmManager:UseProvider(provider, ...)
    local providerSystem = self.systems[Consts.SystemType.LLM_PROVIDER]
    
    -- 特殊处理：配置local provider
    if provider == "local" then
        local host = select(1, ...) or "localhost"
        local port = select(2, ...) or 8080
        providerSystem:ConfigureLocalProvider(host, port)
    end
    
    providerSystem:SwitchProvider(provider)
end

--[[
    上下文接口
--]]

---设置游戏世界观
---@param worldSetting string 世界观设定
function LlmManager:SetGameWorld(worldSetting)
    self.systems[Consts.SystemType.LLM_CONTEXT]:SetGameWorldSetting(worldSetting)
end

---设置游戏规则
---@param rules string 游戏规则
function LlmManager:SetGameRules(rules)
    self.systems[Consts.SystemType.LLM_CONTEXT]:SetGameRules(rules)
end

---设置玩家身份
---@param identity string 玩家身份
function LlmManager:SetPlayerIdentity(identity)
    self.systems[Consts.SystemType.LLM_CONTEXT]:SetPlayerIdentity(identity)
end

---更新玩家数据
---@param key string 数据键
---@param value any 数据值
function LlmManager:UpdatePlayerData(key, value)
    self.systems[Consts.SystemType.LLM_CONTEXT]:UpdatePlayerData(key, value)
end

---清空对话历史
function LlmManager:ClearHistory()
    self.systems[Consts.SystemType.LLM_CONTEXT]:ClearHistory()
end

--[[
    模板接口
--]]

---注册自定义ChatType模板
---@param chatType string ChatType名称
---@param template table 模板配置
function LlmManager:RegisterChatType(chatType, template)
    self.systems[Consts.SystemType.LLM_PROMPT]:RegisterTemplate(chatType, template)
end

--[[
    工具接口
--]]

---注册自定义工具
---@param toolDef table 工具定义
function LlmManager:RegisterTool(toolDef)
    self.systems[Consts.SystemType.LLM_TOOL]:RegisterTool(toolDef)
end

--[[
    Tick驱动
--]]

---Tick函数，驱动异步系统
---@param deltaTime number 帧间隔时间
function LlmManager:Tick(deltaTime)
    -- 驱动ReAct系统（会级联驱动Client和Http）
    local reactSystem = self.systems[Consts.SystemType.LLM_REACT]
    if reactSystem and reactSystem.Tick then
        reactSystem:Tick(deltaTime)
    end
end

return LlmManager

