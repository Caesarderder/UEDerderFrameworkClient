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
    
    
    -- ==================== 打开UI ====================
    -- 获取UIManager
    local uiManager = GameContext:GetUIManager()
    uiManager:openUI("Menu/HomeLevel/UI_Home.UI_Home_C", uiManager.ui_layer.WINDOW, nil, self)
end

function M:init_Story()
    -- ==================== 初始化故事库系统 ====================
    print("[GM_Home] ========== 开始初始化故事系统 ==========")
    
    -- 1. 初始化故事库（加载所有故事元信息）
    local initSuccess, initError = StoryLibraryManager:Initialize()
    if not initSuccess then
        print("[GM_Home] 错误: 故事库初始化失败 - " .. (initError or "未知错误"))
        return
    end
    
    print("[GM_Home] ✓ 故事库初始化成功")
    
    -- 2. 加载洛阳帽妖灾劫故事
    print("[GM_Home] 开始加载洛阳帽妖灾劫故事...")
    local loadResult = StoryLibraryManager:LoadStory("story_school")
    
    if loadResult.success then
        print("[GM_Home] ✓ 洛阳帽妖灾劫故事加载成功!")
        print(string.format("[GM_Home]   故事: %s", loadResult.story.title))
        print(string.format("[GM_Home]   难度: %s", loadResult.story.difficulty))
        print(string.format("[GM_Home]   预计时长: %s", loadResult.story.estimatedTime))
        
        -- 显示当前状态
        StoryLibraryManager:DebugPrint()
    else
        print("[GM_Home] 错误: 洛阳帽妖灾劫故事加载失败 - " .. (loadResult.error or "未知错误"))
        return
    end
    
    print("[GM_Home] ========== 故事系统初始化完成 ==========")
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
