local BusinessModule = require("Core.DataLayerBase.BusinessModule")
local DM_LlmContext = require("DataLayer.Llm.DM_LlmContext")

---@class BM_LlmContext : BusinessModule
---@type BM_LlmContext
local BM_LlmContext = {
    ---@type DM_LlmContext
    dataModule = DM_LlmContext
}

setmetatable(BM_LlmContext, { __index = BusinessModule })

---构建System Prompt
---@return string System Prompt
function BM_LlmContext:BuildSystemPrompt()
    local parts = {}
    
    -- 游戏世界观
    if self.dataModule.gameWorldSetting ~= "" then
        table.insert(parts, "## 游戏世界观\n" .. self.dataModule.gameWorldSetting)
    end
    
    -- 游戏规则
    if self.dataModule.gameRules ~= "" then
        table.insert(parts, "## 游戏规则\n" .. self.dataModule.gameRules)
    end
    
    -- 玩家身份
    if self.dataModule.playerIdentity ~= "" then
        table.insert(parts, "## 玩家身份\n" .. self.dataModule.playerIdentity)
    end
    
    -- 玩家个性化数据
    if next(self.dataModule.playerPersonalData) ~= nil then
        local playerData = self:FormatPlayerData(self.dataModule.playerPersonalData)
        table.insert(parts, "## 玩家数据\n" .. playerData)
    end
    
    return table.concat(parts, "\n\n")
end

---格式化玩家数据
---@param data table 玩家数据
---@return string 格式化后的数据
function BM_LlmContext:FormatPlayerData(data)
    local result = {}
    for key, value in pairs(data) do
        table.insert(result, string.format("- %s: %s", key, tostring(value)))
    end
    return table.concat(result, "\n")
end

---添加对话到历史
---@param role string 角色(user/assistant/system/tool)
---@param content string 内容
---@param extraData table|nil 额外数据（tool_calls, tool_call_id 等）
function BM_LlmContext:AddToHistory(role, content, extraData)
    local message = {
        role = role,
        content = content,
        timestamp = os.time()
    }
    
    -- 添加额外数据（如 tool_calls, tool_call_id）
    if extraData then
        if extraData.tool_calls then
            message.tool_calls = extraData.tool_calls
        end
        if extraData.tool_call_id then
            message.tool_call_id = extraData.tool_call_id
        end
        if extraData.name then
            message.name = extraData.name
        end
    end
    
    table.insert(self.dataModule.conversationHistory, message)
    
    -- 限制历史长度
    while #self.dataModule.conversationHistory > self.dataModule.maxHistoryLength do
        table.remove(self.dataModule.conversationHistory, 1)
    end
end

---获取对话历史（OpenAI格式）
---@return table 对话历史
function BM_LlmContext:GetHistoryForRequest()
    local history = {}
    
    -- 添加system prompt
    local systemPrompt = self:BuildSystemPrompt()
    if systemPrompt ~= "" then
        table.insert(history, {
            role = "system",
            content = systemPrompt
        })
    end
    
    -- 验证并清理对话历史（确保 tool 消息有配对的 tool_calls）
    local validatedHistory = self:ValidateMessageSequence(self.dataModule.conversationHistory)
    
    -- 添加历史对话
    for _, msg in ipairs(validatedHistory) do
        local historyMsg = {
            role = msg.role,
            content = msg.content
        }
        
        -- 如果消息包含 tool_calls，也要添加
        if msg.tool_calls then
            historyMsg.tool_calls = msg.tool_calls
        end
        
        -- 如果是 tool 消息，添加 tool_call_id
        if msg.role == "tool" and msg.tool_call_id then
            historyMsg.tool_call_id = msg.tool_call_id
        end
        
        table.insert(history, historyMsg)
    end
    
    return history
end

---验证消息序列，移除不配对的 tool 消息
---@param messages table 原始消息列表
---@return table 验证后的消息列表
function BM_LlmContext:ValidateMessageSequence(messages)
    local validated = {}
    local i = 1
    
    while i <= #messages do
        local msg = messages[i]
        
        -- 如果是 tool 消息，检查前一条是否有 tool_calls
        if msg.role == "tool" then
            local prevMsg = validated[#validated]
            
            if prevMsg and prevMsg.role == "assistant" and prevMsg.tool_calls then
                -- 有配对的 tool_calls，保留
                table.insert(validated, msg)
            else
                -- 没有配对的 tool_calls，丢弃这条 tool 消息
                print(string.format("[BM_LlmContext] ⚠️ 丢弃不配对的 tool 消息 (索引 %d)", i))
            end
        else
            -- 非 tool 消息，直接保留
            table.insert(validated, msg)
        end
        
        i = i + 1
    end
    
    return validated
end

---清空对话历史
function BM_LlmContext:ClearHistory()
    self.dataModule.conversationHistory = {}
end

-- ==================== 角色对话历史管理（CHARACTER_DIALOGUE专用）====================

---切换到指定角色的对话上下文
---@param npcId string NPC ID
function BM_LlmContext:SwitchToCharacter(npcId)
    -- 如果之前在和其他角色对话，保存当前历史
    if self.dataModule.currentNpcId ~= "" and self.dataModule.currentNpcId ~= npcId then
        print(string.format("[BM_LlmContext] 保存 %s 的对话历史", self.dataModule.currentNpcId))
        -- 验证并保存（移除不配对的 tool 消息）
        local validatedHistory = self:ValidateMessageSequence(self.dataModule.conversationHistory)
        self.dataModule.characterConversations[self.dataModule.currentNpcId] = validatedHistory
    end
    
    -- 切换到新角色
    self.dataModule.currentNpcId = npcId
    
    -- 加载该角色的历史对话（如果存在）
    if self.dataModule.characterConversations[npcId] then
        -- 验证历史消息序列（移除不配对的 tool 消息）
        local storedHistory = self.dataModule.characterConversations[npcId]
        self.dataModule.conversationHistory = self:ValidateMessageSequence(storedHistory)
        print(string.format("[BM_LlmContext] 恢复 %s 的对话历史，共 %d 条", npcId, #self.dataModule.conversationHistory))
    else
        -- 首次与该角色对话，清空历史
        self.dataModule.conversationHistory = {}
        print(string.format("[BM_LlmContext] 首次与 %s 对话，历史为空", npcId))
    end
end

---获取当前对话的NPC ID
---@return string NPC ID
function BM_LlmContext:GetCurrentNpcId()
    return self.dataModule.currentNpcId
end

---清空指定角色的对话历史
---@param npcId string NPC ID
function BM_LlmContext:ClearCharacterHistory(npcId)
    self.dataModule.characterConversations[npcId] = nil
    
    -- 如果当前正在和该角色对话，也清空当前历史
    if self.dataModule.currentNpcId == npcId then
        self.dataModule.conversationHistory = {}
    end
    
    print(string.format("[BM_LlmContext] 已清空 %s 的对话历史", npcId))
end

---清空所有角色的对话历史
function BM_LlmContext:ClearAllCharacterHistories()
    self.dataModule.characterConversations = {}
    self.dataModule.conversationHistory = {}
    self.dataModule.currentNpcId = ""
    print("[BM_LlmContext] 已清空所有角色的对话历史")
end

---获取所有有对话历史的角色列表
---@return table 角色ID列表
function BM_LlmContext:GetCharactersWithHistory()
    local characters = {}
    for npcId, _ in pairs(self.dataModule.characterConversations) do
        table.insert(characters, npcId)
    end
    return characters
end

---退出角色对话模式
function BM_LlmContext:ExitCharacterMode()
    -- 保存当前角色的历史
    if self.dataModule.currentNpcId ~= "" then
        self.dataModule.characterConversations[self.dataModule.currentNpcId] = self.dataModule.conversationHistory
        print(string.format("[BM_LlmContext] 保存并退出与 %s 的对话", self.dataModule.currentNpcId))
    end
    
    -- 清空当前NPC标记
    self.dataModule.currentNpcId = ""
    
    -- 清空全局历史（切换到通用对话模式）
    self.dataModule.conversationHistory = {}
end

-- ==================== 循环记忆管理（Story系统专用）====================

---添加循环记忆（抉择后的叙事等重要事件）
---@param memory table 记忆内容 {type="choice_result", content="...", loopCount=1}
function BM_LlmContext:AddLoopMemory(memory)
    table.insert(self.dataModule.loopMemories, memory)
    
    -- 限制记忆数量
    while #self.dataModule.loopMemories > self.dataModule.maxLoopMemories do
        table.remove(self.dataModule.loopMemories, 1)
    end
    
    print(string.format("[BM_LlmContext] 添加循环记忆，当前共 %d 条", #self.dataModule.loopMemories))
end

---获取循环记忆文本（用于与仇人/玩家对话时的上下文）
---@return string 格式化的循环记忆
function BM_LlmContext:GetLoopMemoriesText()
    if #self.dataModule.loopMemories == 0 then
        return ""
    end
    
    local parts = {"## 🔁 循环记忆（只有你和仇人知道）"}
    for i, memory in ipairs(self.dataModule.loopMemories) do
        local prefix = string.format("第%d次循环", memory.loopCount or i)
        table.insert(parts, string.format("- **%s**: %s", prefix, memory.content))
    end
    
    return table.concat(parts, "\n")
end

---清空循环记忆（开始新游戏时）
function BM_LlmContext:ClearLoopMemories()
    self.dataModule.loopMemories = {}
    print("[BM_LlmContext] 已清空循环记忆")
end

return BM_LlmContext


