--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require("LuaPanda").start("127.0.0.1",8818)

---@type UI_Test_C
local M = UnLua.Class()

local gameContext = require("Core.GameContext")

function M:Construct()
    print("UI_Test Beginplay")
    if self.Button_StartGame then
        -- self.Button_StartGame:AddListener(function()
        --     local levelManager = gameContext:GetLevelManager()
        --     levelManager:switchLevel(self, "L_Test")
        -- end)
        self.Button_StartGame:AddListener(M.changeLevel)
    else
        print("Warning: Button_StartGame is not bound in the blueprint")
    end
end

--function M:PreConstruct(IsDesignTime)
--end

function M:changeLevel()
    local levelManager = gameContext:GetLevelManager()
    levelManager:switchLevel("L_Test")  
end


--function M:Tick(MyGeometry, InDeltaTime)
--end

return M