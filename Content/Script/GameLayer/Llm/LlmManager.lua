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

---发送Chat请求（新架构统一接口）
---@param chatType string ChatType类型
---@param typeOptions table TypeOptions - 专属参数，用于组成提示词
---   - 对于 CHARACTER_DIALOGUE: 包含 npcId, sceneId, 以及角色的其他属性
---@param otherOptions table OtherOptions - 额外参数
---   - userInput: string 用户输入（必需）
---   - includePrompts: table 需要加入的额外提示词类型列表
---   - customPrompts: table 自定义提示词内容
---@param onStream function|nil 流式回调 function(delta: string)
---@param onComplete function|nil 完成回调 function(success: boolean, result: string)
function LlmManager:Chat(chatType, typeOptions, otherOptions, onStream, onComplete)
    local reactSystem = self.systems[Consts.SystemType.LLM_REACT]
    local contextSystem = self.systems[Consts.SystemType.LLM_CONTEXT]
    
    -- 【新架构】预处理 TypeOptions
    typeOptions = typeOptions or {}
    otherOptions = otherOptions or {}
    
    -- === CharacterChat 特殊处理 ===
    if chatType == Consts.ChatType.CHARACTER_DIALOGUE then
        typeOptions = self:_ProcessCharacterTypeOptions(typeOptions, otherOptions, contextSystem)
    end
    
    -- 合并参数（兼容现有系统）
    local params = {
        typeArgs = typeOptions,      -- TypeOptions → typeArgs
        normalArgs = otherOptions    -- OtherOptions → normalArgs
    }
    
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

---【CharacterChat专用】处理角色对话的 TypeOptions
---@param typeOptions table 原始的 TypeOptions
---@param otherOptions table OtherOptions
---@param contextSystem table 上下文系统
---@return table 处理后的 TypeOptions
function LlmManager:_ProcessCharacterTypeOptions(typeOptions, otherOptions, contextSystem)
    local processed = {}
    
    -- 1. 复制所有基础属性
    for k, v in pairs(typeOptions) do
        processed[k] = v
    end
    
    -- 2. 基于 npcId 和 sceneId 添加额外信息
    local npcId = typeOptions.npcId
    local sceneId = typeOptions.sceneId
    
    -- 3. 检查是否是仇人（基于 includePrompts）
    local includePrompts = otherOptions.includePrompts or {}
    local isEnemy = false
    
    for _, promptType in ipairs(includePrompts) do
        if promptType == "enemy_context" then
            isEnemy = true
            break
        end
    end
    
    -- 4. 如果是仇人，附带特殊上下文
    if isEnemy and npcId then
        print(string.format("[LlmManager] 🎭 检测到仇人对话: %s，附加仇人上下文", npcId))
        
        -- 从上下文系统获取仇人的聊天历史
        local enemyHistory = contextSystem:GetCharacterHistory(npcId) or {}
        
        -- 将仇人历史摘要添加到 processed 中
        if #enemyHistory > 0 then
            processed.enemyHistorySummary = self:_SummarizeHistory(enemyHistory)
        end
        
        -- 如果有循环上下文，也添加进去
        for _, promptType in ipairs(includePrompts) do
            if promptType == "loop_context" then
                local customPrompts = otherOptions.customPrompts or {}
                processed.loopContext = customPrompts.loop_context or ""
                break
            end
        end
    end
    
    -- 5. 基于 sceneId 决定 unlock_choice 工具的可用性
    if sceneId then
        processed.currentScene = sceneId
        print(string.format("[LlmManager] 📍 当前场景: %s，AI可以调用 unlock_choice 工具", sceneId))
    end
    
    return processed
end

---生成聊天历史摘要
---@param history table 聊天历史
---@return string 摘要文本
function LlmManager:_SummarizeHistory(history)
    local summary = "## 之前的对话摘要\n"
    local recentCount = math.min(5, #history)  -- 最近5条
    
    for i = #history - recentCount + 1, #history do
        local msg = history[i]
        if msg.role == "user" then
            summary = summary .. string.format("- 玩家: %s\n", msg.content)
        elseif msg.role == "assistant" then
            summary = summary .. string.format("- 我: %s\n", msg.content)
        end
    end
    
    return summary
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

---切换到指定角色的对话上下文（CHARACTER_DIALOGUE专用）
---@param npcId string NPC ID
function LlmManager:SwitchToCharacter(npcId)
    self.systems[Consts.SystemType.LLM_CONTEXT]:SwitchToCharacter(npcId)
end

---退出角色对话模式
function LlmManager:ExitCharacterMode()
    self.systems[Consts.SystemType.LLM_CONTEXT]:ExitCharacterMode()
end

---清空指定角色的对话历史
---@param npcId string NPC ID
function LlmManager:ClearCharacterHistory(npcId)
    self.systems[Consts.SystemType.LLM_CONTEXT]:ClearCharacterHistory(npcId)
end

---清空所有角色的对话历史
function LlmManager:ClearAllCharacterHistories()
    self.systems[Consts.SystemType.LLM_CONTEXT]:ClearAllCharacterHistories()
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


