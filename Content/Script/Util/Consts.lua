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
        LLM = "LLM",
    },

    -- 系统类型定义
    SystemType = {
        UI_LAYER = "UI_LAYER",
        COIN_MAIN = "COIN_MAIN",
        LEVEL_MAIN = "LEVEL_MAIN",
        SAVE_MAIN = "SAVE_MAIN",
        -- LLM Systems
        HTTP_CLIENT = "HTTP_CLIENT",
        LLM_STREAM = "LLM_STREAM",
        LLM_PROVIDER = "LLM_PROVIDER",
        LLM_PROMPT = "LLM_PROMPT",
        LLM_CONFIG = "LLM_CONFIG",
        LLM_CONTEXT = "LLM_CONTEXT",
        LLM_TOOL = "LLM_TOOL",
        LLM_CLIENT = "LLM_CLIENT",
        LLM_REACT = "LLM_REACT",
    },
    
    -- ChatType定义
    ChatType = {
        CHARACTER_DIALOGUE = "character_dialogue",
        NARRATOR = "narrator",
        STORY_ADVANCE = "story_advance",
        COMBAT_NARRATOR = "combat_narrator",
        NPC_INTERACTION = "npc_interaction",
        ITEM_DESCRIPTION = "item_description",
        GENERAL_CHAT = "general_chat",
    },
}

return Consts