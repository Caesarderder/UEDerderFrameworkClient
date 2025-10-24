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
    
    -- 添加用户消息（从 normalArgs 中提取）
    local normalArgs = params.normalArgs or {}
    if normalArgs.userInput then
        self.contextSystem:AddUserMessage(normalArgs.userInput)
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
        
        -- 【新增】打印完整的上下文信息
        self:PrintFullContext(messages, tools, chatType)
        
        -- 发送请求到LLM
        local success, response = self.llmClient:SendChatRequest(messages, tools, templateConfig)
        
        if not success then
            BM_LlmContext.IsProcessing.set(false)
            return false, "LLM请求失败: " .. tostring(response)
        end
        
        -- 检查是否有工具调用
        if response.tool_calls then
            print("[LlmReActSystem] LLM请求调用工具，数量:", #response.tool_calls)
            
            -- 1. 添加 assistant 消息（带 tool_calls）
            local toolCallsText = "调用工具:"
            for i, toolCall in ipairs(response.tool_calls) do
                if i > 1 then toolCallsText = toolCallsText .. ", " end
                toolCallsText = toolCallsText .. " " .. toolCall["function"].name
            end
            
            -- 保存 assistant 消息，包含 tool_calls 对象
            BM_LlmContext:AddToHistory("assistant", toolCallsText, {
                tool_calls = response.tool_calls
            })
            print(string.format("[LlmReActSystem] ✅ 已保存 assistant 消息（带 %d 个 tool_calls）", #response.tool_calls))
            
            -- 2. 执行工具调用
            local toolResults = self.toolSystem:ExecuteToolCalls(response.tool_calls)
            
            -- 3. 将工具结果添加到上下文（带 tool_call_id）
            for _, toolResult in ipairs(toolResults) do
                BM_LlmContext:AddToHistory("tool", toolResult.content, {
                    tool_call_id = toolResult.tool_call_id,
                    name = toolResult.name
                })
                print(string.format("[LlmReActSystem] ✅ 已保存 tool 消息: %s (id=%s)", 
                    toolResult.name, toolResult.tool_call_id))
            end
            
            print("[LlmReActSystem] ✅ 工具调用历史保存完成")
            
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
    
    -- 添加用户消息（从 normalArgs 中提取）
    local normalArgs = params.normalArgs or {}
    if normalArgs.userInput then
        self.contextSystem:AddUserMessage(normalArgs.userInput)
    end
    
    -- 执行一轮流式请求（支持流式 + 工具调用）
    local messages = self:BuildMessages(chatPrompt, params)
    local toolNames = self.promptSystem:GetTemplateTools(chatType)
    local tools = self:GetToolDefinitions(toolNames)
    local templateConfig = self.promptSystem:GetTemplateConfig(chatType)
    
    -- 【新增】打印完整的上下文信息
    self:PrintFullContext(messages, tools, chatType)
    
    self.llmClient:SendStreamChatRequest(
        messages, 
        tools, 
        templateConfig, 
        onStream,  -- 文本流式回调
        function(success, fullText)
            -- HTTP完成回调
            if success then
                if fullText ~= "" then
                    self.contextSystem:AddAssistantMessage(fullText)
                end
            end
            BM_LlmContext.IsProcessing.set(false)
            if onComplete then
                onComplete(success, fullText)
            end
        end,
        function(toolCalls)
            -- 工具调用回调
            print("[LlmReActSystem] 流式工具调用，数量:", #toolCalls)
            
            -- 1. 先添加 assistant 消息（带 tool_calls）
            local toolCallsText = "调用工具:"
            for i, toolCall in ipairs(toolCalls) do
                if i > 1 then toolCallsText = toolCallsText .. ", " end
                toolCallsText = toolCallsText .. " " .. toolCall["function"].name
            end
            
            -- 保存 assistant 消息，包含 tool_calls 对象
            BM_LlmContext:AddToHistory("assistant", toolCallsText, {
                tool_calls = toolCalls
            })
            print(string.format("[LlmReActSystem] ✅ 已保存 assistant 消息（带 %d 个 tool_calls）", #toolCalls))
            
            -- 2. 执行工具
            local toolResults = self.toolSystem:ExecuteToolCalls(toolCalls)
            
            -- 3. 将工具结果添加到上下文（带 tool_call_id）
            for _, toolResult in ipairs(toolResults) do
                BM_LlmContext:AddToHistory("tool", toolResult.content, {
                    tool_call_id = toolResult.tool_call_id,
                    name = toolResult.name
                })
                print(string.format("[LlmReActSystem] ✅ 已保存 tool 消息: %s (id=%s)", 
                    toolResult.name, toolResult.tool_call_id))
            end
            
            print("[LlmReActSystem] ✅ 工具调用历史保存完成")
            
            -- 可以在这里继续下一轮对话（如果需要）
            -- 但目前先让它在工具执行后完成
        end
    )
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
    
    -- 3.5. 循环记忆（仅在与仇人对话时提供）
    -- 检查 params 中是否有 characterName，且角色是仇人
    local typeArgs = params.typeArgs or {}
    local characterName = typeArgs.characterName
    if characterName then
        -- 检查是否是仇人（可以通过 role == "enemy" 或特定的 characterName 判断）
        -- 这里简化处理：如果角色名包含"仇人"相关关键词，或者需要在配置中标记
        local BM_StoryConfig = require("DataLayer.Story.BM_StoryConfig")
        local npcInfo = BM_StoryConfig:GetNPC(BM_LlmContext.dataModule.currentNpcId or "")
        
        if npcInfo and npcInfo.role == "enemy" then
            local loopMemoriesText = BM_LlmContext:GetLoopMemoriesText()
            if loopMemoriesText ~= "" then
                table.insert(messages, {
                    role = "system",
                    content = loopMemoriesText
                })
                print("[LlmReActSystem] 添加循环记忆到上下文（与仇人对话）")
            end
        end
    end
    
    -- 4. 历史对话（完整保留，包括 tool_calls 和 tool 消息）
    -- 使用 ValidateMessageSequence 确保消息序列正确
    local validatedHistory = BM_LlmContext:ValidateMessageSequence(BM_LlmContext.dataModule.conversationHistory)
    
    for _, msg in ipairs(validatedHistory) do
        local historyMsg = {
            role = msg.role,
            content = msg.content or ""
        }
        
        -- ⭐ 如果是 assistant 消息且包含 tool_calls，必须保留
        if msg.role == "assistant" and msg.tool_calls then
            historyMsg.tool_calls = msg.tool_calls
        end
        
        -- ⭐ 如果是 tool 消息，必须包含 tool_call_id 和 name
        if msg.role == "tool" then
            if msg.tool_call_id then
                historyMsg.tool_call_id = msg.tool_call_id
            end
            if msg.name then
                historyMsg.name = msg.name
            end
        end
        
        table.insert(messages, historyMsg)
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

---打印完整的对话上下文（用于调试）
---@param messages table 消息列表
---@param tools table 工具定义列表
---@param chatType string ChatType类型
function LlmReActSystem:PrintFullContext(messages, tools, chatType)
    print("=" .. string.rep("=", 78))
    print("📋 LLM对话上下文打印 - ChatType: " .. (chatType or "unknown"))
    print("=" .. string.rep("=", 78))
    
    -- 打印消息列表
    print("\n📝 消息列表（共 " .. #messages .. " 条）:")
    print("-" .. string.rep("-", 78))
    
    for i, msg in ipairs(messages) do
        print(string.format("\n[消息 %d] Role: %s", i, msg.role))
        
        -- 打印内容（完整内容，不截断）
        if msg.content and msg.content ~= "" then
            print("Content: (" .. #msg.content .. " 字符)")
            print(msg.content)
        end
        
        -- 打印 tool_calls（如果有）
        if msg.tool_calls then
            print(string.format("Tool Calls: (%d 个)", #msg.tool_calls))
            for j, toolCall in ipairs(msg.tool_calls) do
                local funcName = toolCall["function"].name
                local funcArgs = toolCall["function"].arguments
                print(string.format("  [%d] %s(%s)", j, funcName, funcArgs))
            end
        end
        
        -- 打印 tool_call_id（如果有）
        if msg.tool_call_id then
            print("Tool Call ID: " .. msg.tool_call_id)
        end
        
        -- 打印 name（工具名称）
        if msg.name then
            print("Tool Name: " .. msg.name)
        end
    end
    
    -- 打印工具列表（完整内容）
    print("\n" .. string.rep("-", 78))
    if tools and #tools > 0 then
        print("\n🔧 可用工具列表（共 " .. #tools .. " 个）:")
        for i, tool in ipairs(tools) do
            local funcDef = tool["function"]
            print(string.format("\n  [%d] %s", i, funcDef.name))
            print("      描述: " .. (funcDef.description or "无描述"))
            
            -- 打印完整的参数定义
            if funcDef.parameters then
                local json = require("rapidjson")
                local paramsJson = json.encode(funcDef.parameters, {
                    pretty = true,
                    sort_keys = true,
                    indent = "      "
                })
                print("      参数定义:")
                print(paramsJson)
            end
        end
    else
        print("\n🔧 可用工具列表: 无")
    end
    
    -- 统计信息（增加token估算）
    print("\n" .. string.rep("-", 78))
    print("📊 统计信息:")
    
    local systemCount = 0
    local userCount = 0
    local assistantCount = 0
    local toolCount = 0
    local totalChars = 0
    
    for _, msg in ipairs(messages) do
        if msg.role == "system" then
            systemCount = systemCount + 1
        elseif msg.role == "user" then
            userCount = userCount + 1
        elseif msg.role == "assistant" then
            assistantCount = assistantCount + 1
        elseif msg.role == "tool" then
            toolCount = toolCount + 1
        end
        
        if msg.content then
            totalChars = totalChars + #msg.content
        end
    end
    
    -- Token估算：混合中英文按平均2.5字符=1token计算
    local estimatedTokens = math.ceil(totalChars / 2.5)
    
    -- 工具定义也会占用token，简单估算每个工具约100-200 tokens
    local toolTokens = (#tools > 0) and (#tools * 150) or 0
    local totalEstimatedTokens = estimatedTokens + toolTokens
    
    print(string.format("  - System 消息: %d 条", systemCount))
    print(string.format("  - User 消息: %d 条", userCount))
    print(string.format("  - Assistant 消息: %d 条", assistantCount))
    print(string.format("  - Tool 消息: %d 条", toolCount))
    print(string.format("  - 总字符数: %d", totalChars))
    print(string.format("  - 消息 Token 估算: ~%d tokens", estimatedTokens))
    print(string.format("  - 可用工具数: %d", tools and #tools or 0))
    print(string.format("  - 工具定义 Token 估算: ~%d tokens", toolTokens))
    print(string.format("  - 总 Token 估算: ~%d tokens", totalEstimatedTokens))
    
    print("\n" .. string.rep("=", 78))
    print("✅ 上下文打印完成")
    print(string.rep("=", 78) .. "\n")
end

---Tick函数，驱动LlmClient
function LlmReActSystem:Tick(deltaTime)
    if self.llmClient and self.llmClient.Tick then
        self.llmClient:Tick(deltaTime)
    end
end

return LlmReActSystem


