---LLM上下文管理系统
local SystemBase = require("Core.GameLayerBase.SystemBase")
local BM_LlmContext = require("DataLayer.Llm.BM_LlmContext")

---@class LlmContextSystem : SystemBase
---@type LlmContextSystem
local LlmContextSystem = {}
setmetatable(LlmContextSystem, { __index = SystemBase })

---初始化系统
function LlmContextSystem:init()
    -- 先初始化DataModule的数据
    BM_LlmContext.dataModule:init()
    -- 再初始化BusinessModule属性访问器
    BM_LlmContext:initializeProperties()
    print("[LlmContextSystem] 上下文系统初始化完成")
end

---设置游戏世界观
---@param worldSetting string 世界观设定
function LlmContextSystem:SetGameWorldSetting(worldSetting)
    BM_LlmContext.GameWorldSetting.set(worldSetting)
end

---设置游戏规则
---@param rules string 游戏规则
function LlmContextSystem:SetGameRules(rules)
    BM_LlmContext.GameRules.set(rules)
end

---设置玩家身份
---@param identity string 玩家身份
function LlmContextSystem:SetPlayerIdentity(identity)
    BM_LlmContext.PlayerIdentity.set(identity)
end

---更新玩家数据
---@param key string 数据键
---@param value any 数据值
function LlmContextSystem:UpdatePlayerData(key, value)
    local data = BM_LlmContext.PlayerPersonalData.get()
    data[key] = value
    BM_LlmContext.PlayerPersonalData.set(data)
end

---添加用户消息
---@param userMessage string 用户消息
function LlmContextSystem:AddUserMessage(userMessage)
    BM_LlmContext:AddToHistory("user", userMessage)
end

---添加助手回复
---@param assistantMessage string 助手回复
function LlmContextSystem:AddAssistantMessage(assistantMessage)
    BM_LlmContext:AddToHistory("assistant", assistantMessage)
end

---获取用于请求的消息列表
---@return table 消息列表
function LlmContextSystem:GetMessagesForRequest()
    return BM_LlmContext:GetHistoryForRequest()
end

---清空对话历史
function LlmContextSystem:ClearHistory()
    BM_LlmContext:ClearHistory()
end

return LlmContextSystem

