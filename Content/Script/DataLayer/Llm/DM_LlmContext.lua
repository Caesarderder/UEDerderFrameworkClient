local DataModule = require("Core.DataLayerBase.DataModule")

---@class DM_LlmContext : DataModule
---@type DM_LlmContext
local DM_LlmContext = {}
setmetatable(DM_LlmContext, { __index = DataModule })

DM_LlmContext.Fields = {
    -- System上下文
    gameWorldSetting = "",        ---@type string 游戏世界观设定
    gameRules = "",              ---@type string 游戏规则
    playerIdentity = "",         ---@type string 玩家身份定义
    playerPersonalData = {},     ---@type table 玩家个性化数据
    
    -- 对话历史（全局）
    conversationHistory = {},    ---@type table 对话历史记录
    maxHistoryLength = 20,       ---@type number 最大历史长度
    
    -- 角色对话历史（CHARACTER_DIALOGUE专用）
    characterConversations = {}, ---@type table<string, table> 按npcId存储的对话历史 {npcId: {messages}}
    currentNpcId = "",           ---@type string 当前对话的NPC ID
    
    -- 循环记忆（Story系统专用）
    loopMemories = {},           ---@type table 跨循环记忆，只有玩家和仇人知道
    maxLoopMemories = 10,        ---@type number 最大循环记忆条数
    maxCharacterHistoryLength = 30, ---@type number 每个角色的最大历史长度
    
    -- 当前会话状态
    currentSessionId = "",       ---@type string 当前会话ID
    isProcessing = false,        ---@type boolean 是否正在处理请求
}

return DM_LlmContext


