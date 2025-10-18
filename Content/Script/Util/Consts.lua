require("LuaPanda").start("127.0.0.1",8818)

---@class Consts
---常量定义
local Consts = {
    -- 管理器类型定义
    ManagerType = {
        UI = "UI",
        COIN = "COIN",
        LEVEL = "LEVEL",
        SAVE = "SAVE",
    },

    -- 系统类型定义
    SystemType = {
        UI_LAYER = "UI_LAYER",
        COIN_MAIN = "COIN_MAIN",
        LEVEL_MAIN = "LEVEL_MAIN",
        SAVE_MAIN = "SAVE_MAIN",
    },
}

return Consts