--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require("LuaPanda").start("127.0.0.1",8818)

-- 引入GameContext
local GameContext = require("Core.GameContext")

---@type BP_HelloWorld_C
local M = UnLua.Class()

-- function M:Initialize(Initializer)
-- end

-- function M:UserConstructionScript()
-- end

function M:ReceiveBeginPlay()
    print("Hello World")
    
    -- 通过UIManager打开 Menu/UI_Test 面板
    self:OpenUITest()
end

-- 打开UI测试面板（使用UIManager架构方案）
function M:OpenUITest()
   
end

-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

-- function M:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

-- function M:ReceiveActorBeginOverlap(OtherActor)
-- end

-- function M:ReceiveActorEndOverlap(OtherActor)
-- end

return M