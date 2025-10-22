local DataModule = require("Core.DataLayerBase.DataModule")

---故事库数据模块
---存储所有已注册的故事元信息和当前激活的故事
---@class DM_StoryLibrary : DataModule
---@field stories table 已注册的故事列表 (数组)
---@field currentStoryId string 当前激活的故事ID
---@field Fields table 数据字段定义
---@field init fun(self: DM_StoryLibrary) 初始化数据
---@field setBatch fun(self: DM_StoryLibrary, data: table) 批量设置数据
---@field reset fun(self: DM_StoryLibrary) 重置数据
---@type DM_StoryLibrary
local DM_StoryLibrary = {}
setmetatable(DM_StoryLibrary, { __index = DataModule })

DM_StoryLibrary.Fields = {
    -- 已注册的故事列表 (数组形式)
    stories = {},           -- table<number, StoryMeta>
    
    -- 当前激活的故事ID (空字符串表示未激活任何故事)
    currentStoryId = "",    -- string
}

--[[
数据结构说明：

StoryMeta = {
    id = "story_newgreen",                          -- string: 故事唯一ID
    title = "新绿镇时间循环",                        -- string: 显示标题
    description = "喜剧风格的时间循环故事...",        -- string: 故事简介
    tags = {"时间循环", "喜剧", "推理"},             -- table: 标签数组
    difficulty = "中等",                             -- string: 难度描述
    estimatedTime = "2-3小时",                       -- string: 预计游戏时长
    configPath = "Config.NewgreenTownStoryConfig",  -- string: 配置模块路径(用于require)
    thumbnail = "",                                  -- string: 封面图路径(可选,空字符串表示无图)
}

使用示例：
    -- 注册故事后,stories数组的结构:
    stories = {
        [1] = {
            id = "story_newgreen",
            title = "新绿镇时间循环",
            ...
        },
        [2] = {
            id = "story_company",
            title = "公司推理事件",
            ...
        }
    }
    
    -- 当前激活的故事ID:
    currentStoryId = "story_newgreen"  -- 表示正在玩"新绿镇时间循环"
    currentStoryId = ""                 -- 表示未激活任何故事

注意事项：
    1. stories 是数组(table<number, StoryMeta>),按注册顺序存储
    2. 每个故事的id必须唯一,由BM_StoryLibrary负责检查
    3. configPath使用点号路径格式,如"Config.NewgreenTownStoryConfig"
    4. currentStoryId应该始终是stories中某个故事的id,或为空字符串
    5. 此模块只存储数据,业务逻辑由BM_StoryLibrary实现
]]

return DM_StoryLibrary

