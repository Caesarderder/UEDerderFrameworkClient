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
    
    -- 对话历史
    conversationHistory = {},    ---@type table 对话历史记录
    maxHistoryLength = 20,       ---@type number 最大历史长度
    
    -- 当前会话状态
    currentSessionId = "",       ---@type string 当前会话ID
    isProcessing = false,        ---@type boolean 是否正在处理请求
}

return DM_LlmContext

