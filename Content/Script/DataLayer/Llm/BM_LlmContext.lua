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
---@param role string 角色(user/assistant/system)
---@param content string 内容
function BM_LlmContext:AddToHistory(role, content)
    local message = {
        role = role,
        content = content,
        timestamp = os.time()
    }
    
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
    
    -- 添加历史对话
    for _, msg in ipairs(self.dataModule.conversationHistory) do
        table.insert(history, {
            role = msg.role,
            content = msg.content
        })
    end
    
    return history
end

---清空对话历史
function BM_LlmContext:ClearHistory()
    self.dataModule.conversationHistory = {}
end

return BM_LlmContext

