local DataModule = require("Core.DataLayerBase.DataModule")

---故事配置数据模块（固定数据）
---存储游戏的固定配置：背景、场景、NPC模板、抉择模板
---@class DM_StoryConfig : DataModule
---@field background string 故事背景文本
---@field theme string 主题/类型
---@field mainConflict string 主要冲突
---@field scenes table 场景配置表
---@field npcTemplates table NPC模板表
---@field choiceTemplates table 抉择模板表
---@field startScene string 初始场景ID
---@field configData table 原始配置数据（包含display层和GetDisplayContent方法）
---@field version string 版本号
---@field isConfigured boolean 是否已配置
---@type DM_StoryConfig
local DM_StoryConfig = {}
setmetatable(DM_StoryConfig, { __index = DataModule })

DM_StoryConfig.Fields = {
    background = "",
    theme = "时间循环",
    mainConflict = "",
    scenes = {},
    npcTemplates = {},
    choiceTemplates = {},
    startScene = "",          -- 新增：初始场景ID（默认为场景数组第一个）
    configData = nil,         -- 新增：原始配置数据（用于访问display层）
    version = "1.0",
    isConfigured = false,
}

--[[
数据结构说明：

SceneConfig = {
    id = "scene_center",                    -- 场景ID
    name = "新绿镇社区中心",                 -- 场景名称
    description = "多功能社区空间...",       -- 场景描述
    atmosphere = "轻松爵士乐，公告板...",    -- 氛围描述
    npcIds = {"rex", "maggie", "bean"},     -- 该场景的NPC列表
    choiceIds = {"choice_reveal", ...},     -- 该场景的抉择列表
}

NPCTemplate = {
    id = "rex",                             -- NPC ID
    name = "雷克斯·普鲁特",                  -- NPC名称
    role = "enemy",                         -- 角色定位（enemy/ally/neutral）
    personality = "偏执狂天才",              -- 性格描述
    motivation = "净化世界",                 -- 动机
    background = "前同事，因职场争执...",    -- 背景故事
    dialogueStyle = "挑衅、炫耀、偶尔孤独",  -- 对话风格
    
    -- 初始状态值
    initialStates = {
        trust = 0,              -- 信任度 [-100, 100]
        emotion = 0,            -- 情绪值 [-100, 100]
        relation = -50,         -- 关系值 [-100, 100]
    },
    
    -- 特殊标记
    tags = {"genius", "lonely", "dangerous"},
}

ChoiceTemplate = {
    id = "choice_reveal",                   -- 抉择ID
    name = "揭发雷克斯的计划",               -- 抉择名称
    sceneId = "scene_center",               -- 所属场景
    description = "向镇长揭发...",          -- 详细描述
    
    -- 解锁条件（Lua表达式字符串）
    unlockCondition = "loopCount >= 1 or not rexAngry",
    
    -- 执行结果（状态变更）
    effects = {
        -- NPC状态变更
        npcStates = {
            rex = {
                trust = -20,        -- 信任度 -20
                emotion = -30,      -- 情绪值 -30（愤怒）
                tags = {"angry"}    -- 添加标记
            }
        },
        
        -- 场景状态变更
        sceneEvents = {
            "rex_arrested",         -- 触发事件
            "disaster_upgraded"
        },
        
        -- 全局状态变更
        globalFlags = {
            rexAngry = true,
            disasterLevel = 2
        },
        
        -- 故事线推进
        storyProgress = {
            unlockChoices = {},     -- 解锁新抉择
            unlockScenes = {},      -- 解锁新场景
        }
    },
    
    -- 结果描述（用于LLM生成叙事）
    resultNarrative = "雷克斯被捕，当晚越狱并升级灾难...",
}
]]

return DM_StoryConfig

