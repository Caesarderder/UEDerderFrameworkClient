---@type GI_CoreGame_C
local GContext = UnLua.Class()

local GameContext = require("Core.GameContext")


---初始化游戏上下文
function GContext:ReceiveInit()
    -- 初始化GameContext，并将自身作为WorldContext传递
    GameContext:initialize(self)
end

function GContext:ReceiveShutdown()
    -- 销毁GameContext，释放资源
    GameContext:dispose()
end

return GContext