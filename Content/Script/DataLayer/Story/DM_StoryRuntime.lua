local DataModule = require("Core.DataLayerBase.DataModule")

---故事运行时数据模块（动态数据）
---存储游戏运行时的动态状态：循环次数、角色状态、解锁进度
---@class DM_StoryRuntime : DataModule
---@field loopCount number 当前循环次数
---@field currentSceneId string 当前场景ID
---@field currentStoryId string 当前故事ID（多故事系统新增）
---@field inDialogue boolean 是否在对话中
---@field currentNpcId string|nil 当前对话的NPC ID
---@field unlockedScenes table 已解锁的场景
---@field unlockedChoices table 已解锁的抉择
---@field triggeredEvents table 已触发的事件
---@field npcStates table NPC当前状态
---@field relationships table 角色关系网
---@field inventory table 物品数量
---@field globalFlags table 全局标记/变量
---@field currentLoopChoices table 当前循环的选择历史
---@field allLoopsHistory table 所有循环的选择历史
---@field sceneHistory table 场景访问历史（多故事系统新增）
---@field availableScenes table 当前可到达的场景列表（多故事系统新增）
---@field startTime number 游戏开始时间戳
---@field currentLoopStartTime number 当前循环开始时间戳
---@field totalPlayTime number 总游戏时长（秒）
---@type DM_StoryRuntime
local DM_StoryRuntime = {}
setmetatable(DM_StoryRuntime, { __index = DataModule })

DM_StoryRuntime.Fields = {
    loopCount = 0,
    currentSceneId = "",
    currentStoryId = "",         -- 新增：当前故事标识
    inDialogue = false,
    currentNpcId = "",
    unlockedScenes = {},
    unlockedChoices = {},
    triggeredEvents = {},
    npcStates = {},
    relationships = {},
    inventory = {},
    globalFlags = {},
    currentLoopChoices = {},
    allLoopsHistory = {},
    sceneHistory = {},           -- 新增：场景访问历史
    availableScenes = {},        -- 新增：当前可到达的场景列表
    dynamicChoices = {},         -- 新增：AI动态生成的抉择
    startTime = 0,
    currentLoopStartTime = 0,
    totalPlayTime = 0,
}

--[[
数据结构说明：

NPCState = {
    id = "rex",                             -- NPC ID
    
    -- 数值状态
    trust = 0,                              -- 信任度 [-100, 100]
    emotion = 0,                            -- 情绪值 [-100, 100]（正=开心，负=愤怒/悲伤）
    relation = -50,                         -- 关系值 [-100, 100]
    
    -- 当前意图（AI生成）
    currentIntent = "",                     -- 如："阻止玩家", "寻求认同", "执行计划"
    
    -- 状态标记
    tags = {},                              -- 如：{"angry", "suspicious", "trusting"}
    
    -- 记忆（AI可访问）
    memories = {},                          -- 重要事件记忆
    
    -- 当前位置
    currentScene = "scene_center",
}

ChoiceRecord = {
    choiceId = "choice_reveal",             -- 抉择ID
    sceneId = "scene_center",               -- 场景ID
    timestamp = 12345678,                   -- 时间戳
    loopCount = 1,                          -- 循环次数
    npcId = "rex",                          -- 涉及的NPC（可选）
}
]]

return DM_StoryRuntime

