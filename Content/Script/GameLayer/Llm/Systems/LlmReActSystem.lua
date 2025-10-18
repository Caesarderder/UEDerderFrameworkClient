---LLM ReAct系统（重构版）
---支持ChatType和流式响应
local SystemBase = require("Core.GameLayerBase.SystemBase")
local BM_LlmContext = require("DataLayer.Llm.BM_LlmContext")
local json = require("rapidjson")

---@class LlmReActSystem : SystemBase
---@type LlmReActSystem
local LlmReActSystem = {
    ---@type LlmClientSystem
    llmClient = nil,
    ---@type LlmContextSystem
    contextSystem = nil,
    ---@type LlmToolSystem
    toolSystem = nil,
    ---@type LlmPromptSystem
    promptSystem = nil,
    
    maxIterations = 5,  -- 最大思考-行动迭代次数
}
setmetatable(LlmReActSystem, { __index = SystemBase })

---初始化系统
---@param llmClient LlmClientSystem LLM客户端
---@param contextSystem LlmContextSystem 上下文系统
---@param toolSystem LlmToolSystem 工具系统
---@param promptSystem LlmPromptSystem Prompt系统
function LlmReActSystem:init(llmClient, contextSystem, toolSystem, promptSystem)
    self.llmClient = llmClient
    self.contextSystem = contextSystem
    self.toolSystem = toolSystem
    self.promptSystem = promptSystem
    print("[LlmReActSystem] ReAct系统初始化完成")
end

---执行ReAct循环（非流式）
---@param chatType string ChatType类型
---@param params table 参数表
---@return boolean, string 是否成功，结果或错误信息
function LlmReActSystem:Process(chatType, params)
    -- 获取模板
    local template = self.promptSystem:GetTemplate(chatType)
    if not template then
        return false, "未找到ChatType模板: " .. chatType
    end
    
    -- 设置处理状态
    BM_LlmContext.IsProcessing.set(true)
    
    -- 构建并添加Prompt
    local chatPrompt = self.promptSystem:BuildPrompt(chatType, params)
    if not chatPrompt then
        BM_LlmContext.IsProcessing.set(false)
        return false, "构建Prompt失败"
    end
    
    -- 添加用户消息（如果有userInput）
    if params.userInput then
        self.contextSystem:AddUserMessage(params.userInput)
    end
    
    local iteration = 0
    local finalResponse = ""
    
    while iteration < self.maxIterations do
        iteration = iteration + 1
        print(string.format("[LlmReActSystem] ReAct迭代 %d/%d", iteration, self.maxIterations))
        
        -- 构建消息列表
        local messages = self:BuildMessages(chatPrompt, params)
        
        -- 获取工具列表
        local toolNames = self.promptSystem:GetTemplateTools(chatType)
        local tools = self:GetToolDefinitions(toolNames)
        
        -- 获取模板配置
        local templateConfig = self.promptSystem:GetTemplateConfig(chatType)
        
        -- 发送请求到LLM
        local success, response = self.llmClient:SendChatRequest(messages, tools, templateConfig)
        
        if not success then
            BM_LlmContext.IsProcessing.set(false)
            return false, "LLM请求失败: " .. tostring(response)
        end
        
        -- 检查是否有工具调用
        if response.tool_calls then
            print("[LlmReActSystem] LLM请求调用工具，数量:", #response.tool_calls)
            
            -- 添加助手消息（带工具调用）
            self.contextSystem:AddAssistantMessage(
                "调用工具: " .. response.tool_calls[1]["function"].name
            )
            
            -- 执行工具调用
            local toolResults = self.toolSystem:ExecuteToolCalls(response.tool_calls)
            
            -- 将工具结果添加到上下文
            for _, toolResult in ipairs(toolResults) do
                BM_LlmContext:AddToHistory("tool", toolResult.content)
            end
            
            -- 继续下一轮循环
        else
            -- 没有工具调用，说明LLM已经生成了最终回复
            finalResponse = response.content
            self.contextSystem:AddAssistantMessage(finalResponse)
            break
        end
    end
    
    -- 处理完成
    BM_LlmContext.IsProcessing.set(false)
    
    if iteration >= self.maxIterations then
        print("[LlmReActSystem] 达到最大迭代次数")
    end
    
    return true, finalResponse
end

---执行ReAct循环（流式）
---@param chatType string ChatType类型
---@param params table 参数表
---@param onStream function|nil 流式回调 function(delta: string)
---@param onComplete function|nil 完成回调 function(success: boolean, fullText: string)
function LlmReActSystem:ProcessStream(chatType, params, onStream, onComplete)
    -- 获取模板
    local template = self.promptSystem:GetTemplate(chatType)
    if not template then
        if onComplete then
            onComplete(false, "未找到ChatType模板: " .. chatType)
        end
        return
    end
    
    -- 设置处理状态
    BM_LlmContext.IsProcessing.set(true)
    
    -- 构建并添加Prompt
    local chatPrompt = self.promptSystem:BuildPrompt(chatType, params)
    if not chatPrompt then
        BM_LlmContext.IsProcessing.set(false)
        if onComplete then
            onComplete(false, "构建Prompt失败")
        end
        return
    end
    
    -- 添加用户消息（如果有userInput）
    if params.userInput then
        self.contextSystem:AddUserMessage(params.userInput)
    end
    
    -- 执行一轮流式请求（暂时不支持流式 + 工具调用的多轮迭代）
    local messages = self:BuildMessages(chatPrompt, params)
    local toolNames = self.promptSystem:GetTemplateTools(chatType)
    local tools = self:GetToolDefinitions(toolNames)
    local templateConfig = self.promptSystem:GetTemplateConfig(chatType)
    
    self.llmClient:SendStreamChatRequest(messages, tools, templateConfig, onStream, function(success, fullText)
        if success then
            self.contextSystem:AddAssistantMessage(fullText)
        end
        BM_LlmContext.IsProcessing.set(false)
        if onComplete then
            onComplete(success, fullText)
        end
    end)
end

---构建消息列表
---@param chatPrompt string ChatType的Prompt
---@param params table 参数表
---@return table 消息列表
function LlmReActSystem:BuildMessages(chatPrompt, params)
    local messages = {}
    
    -- 1. 游戏世界观和规则（来自上下文系统）
    local gameWorld = BM_LlmContext.dataModule.gameWorldSetting
    local gameRules = BM_LlmContext.dataModule.gameRules
    
    if gameWorld ~= "" or gameRules ~= "" then
        local systemParts = {}
        if gameWorld ~= "" then
            table.insert(systemParts, "## 游戏世界观\n" .. gameWorld)
        end
        if gameRules ~= "" then
            table.insert(systemParts, "## 游戏规则\n" .. gameRules)
        end
        table.insert(messages, {
            role = "system",
            content = table.concat(systemParts, "\n\n")
        })
    end
    
    -- 2. ChatType的Prompt
    if chatPrompt ~= "" then
        table.insert(messages, {
            role = "system",
            content = chatPrompt
        })
    end
    
    -- 3. 玩家数据
    if next(BM_LlmContext.dataModule.playerPersonalData) ~= nil then
        local playerDataStr = BM_LlmContext:FormatPlayerData(BM_LlmContext.dataModule.playerPersonalData)
        table.insert(messages, {
            role = "system",
            content = "## 玩家当前状态\n" .. playerDataStr
        })
    end
    
    -- 4. 历史对话
    for _, msg in ipairs(BM_LlmContext.dataModule.conversationHistory) do
        table.insert(messages, {
            role = msg.role,
            content = msg.content
        })
    end
    
    return messages
end

---获取工具定义
---@param toolNames table 工具名称列表
---@return table 工具定义列表
function LlmReActSystem:GetToolDefinitions(toolNames)
    if not toolNames or #toolNames == 0 then
        return {}
    end
    
    local allTools = self.toolSystem:GetToolsForRequest()
    local filtered = {}
    
    -- 只返回指定的工具
    for _, tool in ipairs(allTools) do
        local toolName = tool["function"].name
        for _, name in ipairs(toolNames) do
            if toolName == name then
                table.insert(filtered, tool)
                break
            end
        end
    end
    
    return filtered
end

---Tick函数，驱动LlmClient
function LlmReActSystem:Tick(deltaTime)
    if self.llmClient and self.llmClient.Tick then
        self.llmClient:Tick(deltaTime)
    end
end

return LlmReActSystem

