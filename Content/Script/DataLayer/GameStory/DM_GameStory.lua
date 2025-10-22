local DataModule = require("Core.DataLayerBase.DataModule")

---游戏故事数据模块
---存储AI生成的游戏背景、角色关系网、故事线等数据
---@class DM_GameStory : DataModule
---@type DM_GameStory
local DM_GameStory = {}
setmetatable(DM_GameStory, { __index = DataModule })

DM_GameStory.Fields = {
    -- 游戏背景
    gameBackground = "",                    ---@type string 完整的游戏背景设定文本
    sceneType = "校园",                     ---@type string 场景类型（校园/公司/社区/架空世界）
    disasterType = "爆炸",                  ---@type string 灾难类型（爆炸/中毒/事故/其他）
    
    -- 角色数据
    characters = {},                        ---@type table 角色关系网数据（JSON解析后的table）
    protagonist = nil,                      ---@type table 主角数据
    enemy = nil,                            ---@type table 仇人数据
    mainNPCs = {},                          ---@type table 主要NPC列表
    minorNPCs = {},                         ---@type table 次要NPC列表
    
    -- 故事线
    storyLine = "",                         ---@type string 完整的故事线文本
    keyStoryPoints = {},                    ---@type table 关键剧情点列表
    
    -- 灾难计划
    disasterPlan = "",                      ---@type string 仇人的灾难计划详情
    
    -- 元数据
    isGenerated = false,                    ---@type boolean 是否已生成游戏故事
    generatedTime = 0,                      ---@type number 生成时间戳
    version = "1.0",                        ---@type string 数据版本
}

return DM_GameStory

