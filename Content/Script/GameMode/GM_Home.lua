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
    -- 获取UIManager
    local uiManager = GameContext:GetUIManager()
    
    if uiManager then
        -- 使用UIManager打开UI，放在WINDOW层
        -- 传递self作为WorldContextObject（BP_HelloWorld是Actor，可以作为WorldContext）
        uiManager:openUI("Menu/UI_Test.UI_Test_C", uiManager.ui_layer.WINDOW, nil, self)
        print("[BP_Home] 通过UIManager打开 UI_Test 面板")
    else
        print("[BP_Home] Error: 无法获取UIManager")
    end 
end

-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

return M
