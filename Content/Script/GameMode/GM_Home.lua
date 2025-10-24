--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type GM_Home_C
local M = UnLua.Class()

local GameContext = require("Core.GameContext")
local StoryLibraryManager = require("GameLayer.StoryLibrary.StoryLibraryManager")

-- function M:UserConstructionScript()
-- end

function M:ReceiveBeginPlay()    
    -- 初始化GameContext
    if not GameContext._isInitialized then
        GameContext:initialize(self)
    end
    
    GameContext:SetGameMode(self)
    
    -- 🔥 初始化故事系统（必须在打开UI之前）
    self:init_Story()
    
    -- ==================== 打开UI ====================
    -- 获取UIManager
    local uiManager = GameContext:GetUIManager()
    uiManager:openUI("Menu/HomeLevel/UI_Home.UI_Home_C", uiManager.ui_layer.WINDOW, nil, self)
end

function M:init_Story()
    -- ==================== 初始化故事库系统 ====================
    print("[GM_Home] ========== 开始初始化故事库 ==========")
    
    -- 只初始化故事库（加载所有故事元信息），不加载具体故事
    -- 具体故事将在 UI_StoryScene 中根据用户选择动态加载
    local initSuccess, initError = StoryLibraryManager:Initialize()
    if not initSuccess then
        print("[GM_Home] ❌ 错误: 故事库初始化失败 - " .. (initError or "未知错误"))
        return false
    end
    
    print("[GM_Home] ✅ 故事库初始化成功")
    print("[GM_Home] 💡 等待用户在 UI_Home 中选择故事...")
    print("[GM_Home] ========== 故事库初始化完成 ==========")
    
    return true
end

-- function M:ReceiveEndPlay()
-- end

-- Tick函数 - 驱动LLM异步系统（关键！流式响应必须）
function M:ReceiveTick(DeltaSeconds)
    -- 驱动LLM Manager的Tick
    local llmMgr = GameContext:GetLlmManager()
    if llmMgr and llmMgr.Tick then
        llmMgr:Tick(DeltaSeconds)
    end
end

return M
