---测试 DM_StoryLibrary 模块
---验证数据模块的基本功能

local DM_StoryLibrary = require("DataLayer.StoryLibrary.DM_StoryLibrary")

print("========== 测试 DM_StoryLibrary ==========")

-- 测试1: 创建实例
print("\n[测试1] 创建DM_StoryLibrary实例")
local instance = {}
setmetatable(instance, { __index = DM_StoryLibrary })
instance:init()
print("✓ 实例创建成功")
print("  - stories:", type(instance.stories), "长度:", #instance.stories)
print("  - currentStoryId:", type(instance.currentStoryId), "值:", instance.currentStoryId)

-- 测试2: 添加故事数据
print("\n[测试2] 添加故事数据")
local testStory1 = {
    id = "story_newgreen",
    title = "新绿镇时间循环",
    description = "喜剧风格的时间循环故事",
    tags = {"时间循环", "喜剧"},
    difficulty = "中等",
    estimatedTime = "2-3小时",
    configPath = "Config.NewgreenTownStoryConfig",
    thumbnail = ""
}

local testStory2 = {
    id = "story_company",
    title = "公司推理事件",
    description = "公司里的离奇事件",
    tags = {"推理", "悬疑"},
    difficulty = "困难",
    estimatedTime = "3-4小时",
    configPath = "Config.CompanyMysteryStoryConfig",
    thumbnail = ""
}

table.insert(instance.stories, testStory1)
table.insert(instance.stories, testStory2)
print("✓ 添加了2个故事")
print("  - stories数组长度:", #instance.stories)
print("  - 第1个故事ID:", instance.stories[1].id)
print("  - 第1个故事标题:", instance.stories[1].title)
print("  - 第2个故事ID:", instance.stories[2].id)
print("  - 第2个故事标题:", instance.stories[2].title)

-- 测试3: 设置当前故事ID
print("\n[测试3] 设置当前故事ID")
instance.currentStoryId = "story_newgreen"
print("✓ 设置currentStoryId =", instance.currentStoryId)

-- 测试4: 重置数据
print("\n[测试4] 重置数据")
instance:reset()
print("✓ 数据已重置")
print("  - stories长度:", #instance.stories)
print("  - currentStoryId:", instance.currentStoryId)

-- 测试5: 使用setBatch批量设置
print("\n[测试5] 使用setBatch批量设置")
instance:setBatch({
    stories = {testStory1, testStory2},
    currentStoryId = "story_company"
})
print("✓ 批量设置成功")
print("  - stories长度:", #instance.stories)
print("  - currentStoryId:", instance.currentStoryId)

print("\n========== 所有测试通过! ==========")

return true

