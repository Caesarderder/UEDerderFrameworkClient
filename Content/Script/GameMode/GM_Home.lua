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

-- function M:UserConstructionScript()
-- end

function M:ReceiveBeginPlay()    
    -- 初始化GameContext
    if not GameContext._isInitialized then
        GameContext:initialize(self)
    end
    
    GameContext:SetGameMode(self)
    
    -- 获取UIManager
    local uiManager = GameContext:GetUIManager()
    
    if uiManager then
        -- 使用UIManager打开UI，放在WINDOW层
        -- 传递self作为WorldContextObject（BP_HelloWorld是Actor，可以作为WorldContext）
        uiManager:openUI("Menu/UI_Dialog1.UI_Dialog1_C", uiManager.ui_layer.WINDOW, nil, self)
        print("[GM_Home] 通过UIManager打开 UI_Dialog 面板")
    else
        print("[GM_Home] Error: 无法获取UIManager")
    end 
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
