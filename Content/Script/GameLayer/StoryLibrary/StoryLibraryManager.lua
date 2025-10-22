---故事库管理器
---管理多故事系统，封装故事切换的完整流程
---职责：
---  1. 初始化故事库（从配置加载）
---  2. 加载和切换故事
---  3. 重启当前故事
---  4. 提供故事查询接口

local StoryLibraryManager = {}

-- 依赖模块
local BM_StoryLibrary = require("DataLayer.StoryLibrary.BM_StoryLibrary")
local BM_StoryConfig = require("DataLayer.Story.BM_StoryConfig")
local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")

-- ==================== 初始化 ====================

---初始化故事库（游戏启动时调用一次）
---从配置文件加载所有故事元信息
---@return boolean success 是否初始化成功
---@return string|nil error 错误信息
function StoryLibraryManager:Initialize()
    print("[StoryLibraryManager] 开始初始化故事库...")
    
    -- 初始化故事库的 dataModule
    BM_StoryLibrary.dataModule:init()
    
    -- 清空现有数据
    BM_StoryLibrary:Clear()
    
    -- 加载故事库配置
    local success, config = pcall(require, "Config.StoryLibraryConfig")
    if not success then
        local error = "无法加载故事库配置: " .. tostring(config)
        print("[StoryLibraryManager] 错误: " .. error)
        return false, error
    end
    
    -- 导入故事列表
    local successCount, errors = BM_StoryLibrary:ImportStories(config)
    
    if successCount == 0 then
        local error = "未能成功导入任何故事"
        print("[StoryLibraryManager] 错误: " .. error)
        if #errors > 0 then
            print("  错误详情:")
            for _, err in ipairs(errors) do
                print("  - " .. err)
            end
        end
        return false, error
    end
    
    -- 显示导入结果
    print(string.format("[StoryLibraryManager] 故事库初始化完成: %d个故事可用", successCount))
    if #errors > 0 then
        print(string.format("  警告: %d个故事导入失败", #errors))
    end
    
    -- 调试输出
    BM_StoryLibrary:DebugPrint()
    
    return true
end

-- ==================== 故事加载与切换 ====================

---加载并激活指定故事
---这是核心方法，封装了完整的故事切换流程
---@param storyId string 故事ID
---@return table result {success: boolean, error: string|nil, story: table|nil}
function StoryLibraryManager:LoadStory(storyId)
    print(string.format("[StoryLibraryManager] 开始加载故事: %s", storyId))
    
    -- 1. 获取故事元信息
    local storyMeta = BM_StoryLibrary:GetStoryMeta(storyId)
    if not storyMeta then
        local error = "故事不存在: " .. storyId
        print("[StoryLibraryManager] 错误: " .. error)
        return {
            success = false,
            error = error
        }
    end
    
    print(string.format("[StoryLibraryManager] 找到故事: %s", storyMeta.title))
    
    -- 2. 加载故事配置
    local success, storyConfig = pcall(require, storyMeta.configPath)
    if not success then
        local error = "无法加载故事配置: " .. tostring(storyConfig)
        print("[StoryLibraryManager] 错误: " .. error)
        return {
            success = false,
            error = error
        }
    end
    
    -- 如果配置是函数，调用它获取配置数据
    if type(storyConfig) == "function" then
        storyConfig = storyConfig()
    end
    
    print("[StoryLibraryManager] 故事配置加载成功")
    
    -- 3. 重新初始化配置和运行时模块
    print("[StoryLibraryManager] 重新初始化配置和运行时模块...")
    -- 先初始化 dataModule，确保数据结构存在
    BM_StoryConfig.dataModule:init()
    BM_StoryRuntime.dataModule:init()
    
    -- 然后清空数据（现在 dataModule 已经初始化，清空是安全的）
    BM_StoryConfig:Clear()
    BM_StoryRuntime:Clear()
    
    -- 4. 导入新故事的配置
    print("[StoryLibraryManager] 导入故事配置...")
    BM_StoryConfig:ImportConfig(storyConfig)
    
    -- 5. 初始化运行时
    print("[StoryLibraryManager] 初始化运行时...")
    BM_StoryRuntime:InitializeFromConfig(BM_StoryConfig)
    
    -- 6. 设置当前故事ID（在Runtime和Library中都要设置）
    BM_StoryRuntime.dataModule.currentStoryId = storyId
    local setSuccess, setError = BM_StoryLibrary:SetCurrentStoryId(storyId)
    if not setSuccess then
        print("[StoryLibraryManager] 警告: 设置当前故事ID失败: " .. (setError or ""))
    end
    
    -- 7. 开始第一次循环
    print("[StoryLibraryManager] 开始第一次循环...")
    BM_StoryRuntime:StartNewLoop()
    
    -- 8. 打印数据层状态（Debug）
    print("\n[StoryLibraryManager] 打印故事数据层...")
    BM_StoryConfig:DebugPrint()     -- 固定数据层
    BM_StoryRuntime:DebugPrint()    -- 变化数据层
    
    print(string.format("[StoryLibraryManager] ✓ 故事 '%s' 加载完成", storyMeta.title))
    
    return {
        success = true,
        story = storyMeta
    }
end

---重新开始当前故事
---相当于重新加载当前故事（回到第1次循环）
---@return table result {success: boolean, error: string|nil}
function StoryLibraryManager:RestartCurrentStory()
    local currentStoryId = BM_StoryLibrary:GetCurrentStoryId()
    
    if currentStoryId == "" then
        local error = "当前没有激活的故事"
        print("[StoryLibraryManager] 错误: " .. error)
        return {
            success = false,
            error = error
        }
    end
    
    print(string.format("[StoryLibraryManager] 重新开始故事: %s", currentStoryId))
    
    -- 直接调用LoadStory，它会清空并重新加载
    return self:LoadStory(currentStoryId)
end

-- ==================== 查询接口 ====================

---获取当前故事信息
---@return table|nil story 当前故事元信息，如果没有激活的故事返回nil
function StoryLibraryManager:GetCurrentStory()
    return BM_StoryLibrary:GetCurrentStory()
end

---获取当前故事ID
---@return string storyId 当前故事ID（空字符串表示未激活）
function StoryLibraryManager:GetCurrentStoryId()
    return BM_StoryLibrary:GetCurrentStoryId()
end

---获取所有可用故事列表
---@return table stories 故事数组
function StoryLibraryManager:GetAllStories()
    return BM_StoryLibrary:GetAllStories()
end

---获取指定故事的元信息
---@param storyId string 故事ID
---@return table|nil story 故事元信息
function StoryLibraryManager:GetStoryMeta(storyId)
    return BM_StoryLibrary:GetStoryMeta(storyId)
end

---检查是否有激活的故事
---@return boolean hasStory 是否有激活的故事
function StoryLibraryManager:HasCurrentStory()
    return BM_StoryLibrary:HasCurrentStory()
end

---获取故事总数
---@return number count 故事总数
function StoryLibraryManager:GetStoryCount()
    return BM_StoryLibrary:GetStoryCount()
end

-- ==================== 便捷方法 ====================

---快速加载第一个故事（用于测试）
---@return table result 加载结果
function StoryLibraryManager:LoadFirstStory()
    local stories = self:GetAllStories()
    if #stories == 0 then
        return {
            success = false,
            error = "故事库中没有任何故事"
        }
    end
    
    return self:LoadStory(stories[1].id)
end

---根据标签查找故事
---@param tag string 标签名
---@return table stories 符合条件的故事数组
function StoryLibraryManager:GetStoriesByTag(tag)
    return BM_StoryLibrary:GetStoriesByTag(tag)
end

-- ==================== 调试工具 ====================

---调试输出故事库状态
function StoryLibraryManager:DebugPrint()
    print("==================== StoryLibraryManager ====================")
    
    local summary = BM_StoryLibrary:GetSummary()
    print(string.format("故事总数: %d", summary.totalStories))
    print(string.format("当前故事: %s (%s)", summary.currentStoryTitle, summary.currentStoryId))
    
    if self:HasCurrentStory() then
        print("\n当前运行时状态:")
        print(string.format("  循环次数: %d", BM_StoryRuntime:GetLoopCount()))
        print(string.format("  当前场景: %s", BM_StoryRuntime:GetCurrentSceneId()))
        print(string.format("  NPC数量: %d", BM_StoryRuntime:GetNPCCount()))
    else
        print("\n(未激活任何故事)")
    end
    
    print("==========================================================")
end

---获取管理器状态摘要
---@return table summary 状态摘要
function StoryLibraryManager:GetSummary()
    local librarySummary = BM_StoryLibrary:GetSummary()
    
    local result = {
        library = librarySummary,
        runtime = nil
    }
    
    if self:HasCurrentStory() then
        result.runtime = {
            loopCount = BM_StoryRuntime:GetLoopCount(),
            currentSceneId = BM_StoryRuntime:GetCurrentSceneId(),
            npcCount = BM_StoryRuntime:GetNPCCount(),
            playTime = BM_StoryRuntime:GetTotalPlayTime()
        }
    end
    
    return result
end

return StoryLibraryManager

