local BusinessModule = require("Core.DataLayerBase.BusinessModule")
local DM_StoryLibrary = require("DataLayer.StoryLibrary.DM_StoryLibrary")

---故事库业务模块
---提供故事注册、查询和管理接口
---@class BM_StoryLibrary : BusinessModule
---@type BM_StoryLibrary
local BM_StoryLibrary = {
    ---@type DM_StoryLibrary
    dataModule = DM_StoryLibrary
}

setmetatable(BM_StoryLibrary, { __index = BusinessModule })

-- ==================== 故事注册 ====================

---注册故事（添加到故事库）
---@param storyMeta table 故事元信息
---@return boolean success 是否注册成功
---@return string|nil error 错误信息（如果失败）
function BM_StoryLibrary:RegisterStory(storyMeta)
    -- 验证必需字段
    if not storyMeta.id or storyMeta.id == "" then
        return false, "故事ID不能为空"
    end
    
    if not storyMeta.title or storyMeta.title == "" then
        return false, "故事标题不能为空"
    end
    
    if not storyMeta.configPath or storyMeta.configPath == "" then
        return false, "配置路径不能为空"
    end
    
    -- 检查ID唯一性
    for _, existingStory in ipairs(self.dataModule.stories) do
        if existingStory.id == storyMeta.id then
            return false, "故事ID已存在: " .. storyMeta.id
        end
    end
    
    -- 确保必需字段有默认值
    local story = {
        id = storyMeta.id,
        title = storyMeta.title,
        description = storyMeta.description or "",
        tags = storyMeta.tags or {},
        difficulty = storyMeta.difficulty or "未知",
        estimatedTime = storyMeta.estimatedTime or "未知",
        configPath = storyMeta.configPath,
        thumbnail = storyMeta.thumbnail or ""
    }
    
    -- 添加到stories数组
    table.insert(self.dataModule.stories, story)
    
    print(string.format("[BM_StoryLibrary] 注册故事: %s (%s)", story.title, story.id))
    
    return true
end

-- ==================== 故事查询 ====================

---获取所有故事列表
---@return table 故事元信息数组 table<number, StoryMeta>
function BM_StoryLibrary:GetAllStories()
    return self.dataModule.stories
end

---根据ID获取故事元信息
---@param storyId string 故事ID
---@return table|nil 故事元信息，找不到返回nil
function BM_StoryLibrary:GetStoryMeta(storyId)
    for _, story in ipairs(self.dataModule.stories) do
        if story.id == storyId then
            return story
        end
    end
    return nil
end

---根据索引获取故事元信息
---@param index number 索引（从1开始）
---@return table|nil 故事元信息，找不到返回nil
function BM_StoryLibrary:GetStoryByIndex(index)
    return self.dataModule.stories[index]
end

---获取故事数量
---@return number 故事总数
function BM_StoryLibrary:GetStoryCount()
    return #self.dataModule.stories
end

---检查故事是否存在
---@param storyId string 故事ID
---@return boolean 是否存在
function BM_StoryLibrary:HasStory(storyId)
    return self:GetStoryMeta(storyId) ~= nil
end

---根据标签过滤故事
---@param tag string 标签名
---@return table 符合条件的故事数组
function BM_StoryLibrary:GetStoriesByTag(tag)
    local result = {}
    for _, story in ipairs(self.dataModule.stories) do
        for _, storyTag in ipairs(story.tags) do
            if storyTag == tag then
                table.insert(result, story)
                break
            end
        end
    end
    return result
end

-- ==================== 当前故事管理 ====================

---获取当前激活的故事ID
---@return string 当前故事ID（空字符串表示未激活任何故事）
function BM_StoryLibrary:GetCurrentStoryId()
    return self.dataModule.currentStoryId
end

---设置当前激活的故事ID
---@param storyId string 故事ID（空字符串表示清空）
---@return boolean success 是否设置成功
---@return string|nil error 错误信息（如果失败）
function BM_StoryLibrary:SetCurrentStoryId(storyId)
    -- 允许设置为空字符串（表示未激活任何故事）
    if storyId == "" then
        self.dataModule.currentStoryId = ""
        print("[BM_StoryLibrary] 清空当前故事")
        return true
    end
    
    -- 检查故事是否存在
    if not self:HasStory(storyId) then
        return false, "故事不存在: " .. storyId
    end
    
    self.dataModule.currentStoryId = storyId
    local story = self:GetStoryMeta(storyId)
    print(string.format("[BM_StoryLibrary] 设置当前故事: %s (%s)", story.title, storyId))
    
    return true
end

---获取当前激活的故事元信息
---@return table|nil 故事元信息，如果未激活任何故事返回nil
function BM_StoryLibrary:GetCurrentStory()
    if self.dataModule.currentStoryId == "" then
        return nil
    end
    return self:GetStoryMeta(self.dataModule.currentStoryId)
end

---检查是否有激活的故事
---@return boolean 是否有激活的故事
function BM_StoryLibrary:HasCurrentStory()
    return self.dataModule.currentStoryId ~= ""
end

-- ==================== 批量导入 ====================

---批量注册故事（从配置加载）
---@param storiesConfig table 故事配置数组 {stories = {...}}
---@return number successCount 成功注册的数量
---@return table errors 错误信息数组
function BM_StoryLibrary:ImportStories(storiesConfig)
    local successCount = 0
    local errors = {}
    
    -- 确保配置格式正确
    local storyList = storiesConfig.stories or storiesConfig
    
    if type(storyList) ~= "table" then
        table.insert(errors, "配置格式错误：stories必须是table")
        return successCount, errors
    end
    
    -- 逐个注册
    for index, storyMeta in ipairs(storyList) do
        local success, error = self:RegisterStory(storyMeta)
        if success then
            successCount = successCount + 1
        else
            table.insert(errors, string.format("索引%d: %s", index, error))
        end
    end
    
    print(string.format("[BM_StoryLibrary] 批量导入完成: 成功%d个，失败%d个", 
        successCount, #errors))
    
    return successCount, errors
end

-- ==================== 数据管理 ====================

---清空所有故事
function BM_StoryLibrary:Clear()
    self.dataModule.stories = {}
    self.dataModule.currentStoryId = ""
    print("[BM_StoryLibrary] 已清空所有故事")
end

---移除指定故事
---@param storyId string 故事ID
---@return boolean success 是否移除成功
function BM_StoryLibrary:RemoveStory(storyId)
    for i, story in ipairs(self.dataModule.stories) do
        if story.id == storyId then
            table.remove(self.dataModule.stories, i)
            
            -- 如果移除的是当前故事，清空currentStoryId
            if self.dataModule.currentStoryId == storyId then
                self.dataModule.currentStoryId = ""
            end
            
            print(string.format("[BM_StoryLibrary] 移除故事: %s (%s)", story.title, storyId))
            return true
        end
    end
    
    return false
end

-- ==================== 调试工具 ====================

---调试打印故事库信息
function BM_StoryLibrary:DebugPrint()
    print("==================== 故事库 ====================")
    print("故事总数:", self:GetStoryCount())
    print("当前故事:", self.dataModule.currentStoryId)
    print("")
    print("已注册的故事:")
    for i, story in ipairs(self.dataModule.stories) do
        local tags = table.concat(story.tags, ", ")
        print(string.format("  %d. [%s] %s", i, story.id, story.title))
        print(string.format("     难度: %s | 时长: %s | 标签: %s", 
            story.difficulty, story.estimatedTime, tags))
        print(string.format("     配置: %s", story.configPath))
    end
    print("==============================================")
end

---获取故事库摘要信息（用于显示）
---@return table 摘要信息
function BM_StoryLibrary:GetSummary()
    return {
        totalStories = self:GetStoryCount(),
        currentStoryId = self.dataModule.currentStoryId,
        currentStoryTitle = self:HasCurrentStory() and self:GetCurrentStory().title or "无",
        stories = self.dataModule.stories
    }
end

return BM_StoryLibrary

