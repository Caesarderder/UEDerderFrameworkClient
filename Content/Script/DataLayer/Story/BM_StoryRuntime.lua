local BusinessModule = require("Core.DataLayerBase.BusinessModule")
local DM_StoryRuntime = require("DataLayer.Story.DM_StoryRuntime")

---故事运行时业务模块
---提供运行时数据的访问、修改和状态管理接口
---@class BM_StoryRuntime : BusinessModule
---@type BM_StoryRuntime
local BM_StoryRuntime = {
    ---@type DM_StoryRuntime
    dataModule = DM_StoryRuntime
}

setmetatable(BM_StoryRuntime, { __index = BusinessModule })

-- ==================== 循环管理 ====================

---开始新循环
function BM_StoryRuntime:StartNewLoop()
    print("\n" .. string.rep("=", 70))
    print("[数据变化] 开始新循环")
    print(string.rep("=", 70))
    
    -- 保存当前循环的选择历史
    if #self.dataModule.currentLoopChoices > 0 then
        table.insert(self.dataModule.allLoopsHistory, {
            loopCount = self.dataModule.loopCount,
            choices = self.dataModule.currentLoopChoices
        })
        print(string.format("  上一循环（第%d次）的选择已保存: %d次选择", 
            self.dataModule.loopCount, #self.dataModule.currentLoopChoices))
    end
    
    -- 重置运行时状态
    local oldLoopCount = self.dataModule.loopCount
    self.dataModule.loopCount = self.dataModule.loopCount + 1
    self.dataModule.currentLoopStartTime = os.time()
    self.dataModule.currentLoopChoices = {}
    self.dataModule.triggeredEvents = {}
    
    print(string.format("  循环次数: %d -> %d", oldLoopCount, self.dataModule.loopCount))
    
    -- 重置NPC状态（恢复初始值，但保留某些记忆）
    print("  重置NPC状态:")
    for npcId, npcState in pairs(self.dataModule.npcStates) do
        local oldTrust = npcState.trust
        local oldEmotion = npcState.emotion
        local oldRelation = npcState.relation
        
        -- 保留核心记忆，重置数值
        npcState.trust = npcState.initialTrust or 0
        npcState.emotion = npcState.initialEmotion or 0
        npcState.relation = npcState.initialRelation or 0
        npcState.tags = {}
        
        print(string.format("    [%s] trust:%+d->%+d, emotion:%+d->%+d, relation:%+d->%+d", 
            npcId, oldTrust, npcState.trust, oldEmotion, npcState.emotion, oldRelation, npcState.relation))
    end
    
    print(string.format("\n✅ 第 %d 次循环开始！", self.dataModule.loopCount))
    print(string.rep("=", 70) .. "\n")
end

---获取当前循环次数
---@return number
function BM_StoryRuntime:GetLoopCount()
    return self.dataModule.loopCount
end

---获取总游戏时长
---@return number 游戏时长（秒）
function BM_StoryRuntime:GetTotalPlayTime()
    return self.dataModule.totalPlayTime + (os.time() - self.dataModule.startTime)
end

-- ==================== 场景管理 ====================

---切换场景
---@param sceneId string 场景ID
function BM_StoryRuntime:ChangeScene(sceneId)
    local oldSceneId = self.dataModule.currentSceneId
    self.dataModule.currentSceneId = sceneId
    
    print(string.rep("-", 60))
    print("[数据变化] 场景切换")
    print(string.format("  旧场景: %s", oldSceneId or "(无)"))
    print(string.format("  新场景: %s", sceneId))
    print(string.rep("-", 60))
end

---获取当前场景ID
---@return string
function BM_StoryRuntime:GetCurrentSceneId()
    return self.dataModule.currentSceneId
end

---解锁场景
---@param sceneId string 场景ID
function BM_StoryRuntime:UnlockScene(sceneId)
    if not self.dataModule.unlockedScenes[sceneId] then
        self.dataModule.unlockedScenes[sceneId] = true
        print("[BM_StoryRuntime] 解锁场景:", sceneId)
    end
end

---检查场景是否解锁
---@param sceneId string 场景ID
---@return boolean
function BM_StoryRuntime:IsSceneUnlocked(sceneId)
    return self.dataModule.unlockedScenes[sceneId] == true
end

-- ==================== 抉择管理 ====================

---解锁抉择
---@param choiceId string 抉择ID
function BM_StoryRuntime:UnlockChoice(choiceId)
    if not self.dataModule.unlockedChoices[choiceId] then
        self.dataModule.unlockedChoices[choiceId] = true
        print("[BM_StoryRuntime] 解锁抉择:", choiceId)
    end
end

---检查抉择是否解锁
---@param choiceId string 抉择ID
---@return boolean
function BM_StoryRuntime:IsChoiceUnlocked(choiceId)
    -- 1. 检查是否在已解锁列表中（静态抉择）
    if self.dataModule.unlockedChoices[choiceId] == true then
        return true
    end
    
    -- 2. 检查是否是动态抉择（动态抉择默认解锁）
    local dynamicChoice = self:GetDynamicChoice(choiceId)
    if dynamicChoice then
        return true
    end
    
    return false
end

---记录玩家选择
---@param choiceId string 抉择ID
---@param sceneId string 场景ID
---@param npcId string|nil 相关NPC ID
function BM_StoryRuntime:RecordChoice(choiceId, sceneId, npcId)
    local record = {
        choiceId = choiceId,
        sceneId = sceneId,
        npcId = npcId,
        timestamp = os.time(),
        loopCount = self.dataModule.loopCount
    }
    table.insert(self.dataModule.currentLoopChoices, record)
    
    print(string.rep("-", 60))
    print("[数据变化] 记录玩家选择")
    print(string.format("  抉择ID: %s", choiceId))
    print(string.format("  场景: %s", sceneId))
    if npcId then
        print(string.format("  相关NPC: %s", npcId))
    end
    print(string.format("  循环次数: %d", self.dataModule.loopCount))
    print(string.format("  当前循环已做 %d 次选择", #self.dataModule.currentLoopChoices))
    print(string.rep("-", 60))
end

---获取当前循环的选择历史
---@return table
function BM_StoryRuntime:GetCurrentLoopChoices()
    return self.dataModule.currentLoopChoices
end

-- ==================== NPC状态管理 ====================

---初始化NPC状态（从配置模板）
---@param npcId string NPC ID
---@param initialStates table 初始状态值
function BM_StoryRuntime:InitNPCState(npcId, initialStates)
    if self.dataModule.npcStates[npcId] then
        return -- 已初始化
    end
    
    self.dataModule.npcStates[npcId] = {
        id = npcId,
        trust = initialStates.trust or 0,
        emotion = initialStates.emotion or 0,
        relation = initialStates.relation or 0,
        initialTrust = initialStates.trust or 0,
        initialEmotion = initialStates.emotion or 0,
        initialRelation = initialStates.relation or 0,
        currentIntent = "",
        tags = {},
        memories = {},
        currentScene = ""
    }
end

---获取NPC状态
---@param npcId string NPC ID
---@return table|nil NPC状态
function BM_StoryRuntime:GetNPCState(npcId)
    return self.dataModule.npcStates[npcId]
end

---更新NPC数值状态
---@param npcId string NPC ID
---@param stateName string 状态名（trust/emotion/relation）
---@param delta number 变化值
function BM_StoryRuntime:UpdateNPCStat(npcId, stateName, delta)
    local npcState = self.dataModule.npcStates[npcId]
    if not npcState then
        print("[BM_StoryRuntime] 警告：NPC状态不存在:", npcId)
        return
    end
    
    local oldValue = npcState[stateName] or 0
    local newValue = math.max(-100, math.min(100, oldValue + delta))
    npcState[stateName] = newValue
    
    print(string.rep("-", 60))
    print("[数据变化] NPC状态更新")
    print(string.format("  NPC: %s", npcId))
    print(string.format("  属性: %s", stateName))
    print(string.format("  变化: %d -> %d (%+d)", oldValue, newValue, delta))
    print(string.rep("-", 60))
end

---设置NPC状态标记
---@param npcId string NPC ID
---@param tag string 标记名
---@param add boolean 添加或移除
function BM_StoryRuntime:SetNPCTag(npcId, tag, add)
    local npcState = self.dataModule.npcStates[npcId]
    if not npcState then return end
    
    local changed = false
    
    if add then
        -- 添加标记（去重）
        local exists = false
        for _, t in ipairs(npcState.tags) do
            if t == tag then exists = true break end
        end
        if not exists then
            table.insert(npcState.tags, tag)
            changed = true
        end
    else
        -- 移除标记
        for i = #npcState.tags, 1, -1 do
            if npcState.tags[i] == tag then
                table.remove(npcState.tags, i)
                changed = true
            end
        end
    end
    
    if changed then
        print(string.rep("-", 60))
        print("[数据变化] NPC标签变更")
        print(string.format("  NPC: %s", npcId))
        print(string.format("  操作: %s 标签 [%s]", add and "添加" or "移除", tag))
        print(string.format("  当前标签: %s", table.concat(npcState.tags, ", ")))
        print(string.rep("-", 60))
    end
end

---检查NPC是否有标记
---@param npcId string NPC ID
---@param tag string 标记名
---@return boolean
function BM_StoryRuntime:HasNPCTag(npcId, tag)
    local npcState = self.dataModule.npcStates[npcId]
    if not npcState then return false end
    
    for _, t in ipairs(npcState.tags) do
        if t == tag then return true end
    end
    return false
end

---获取NPC状态Prompt（用于LLM）
---@param npcId string NPC ID
---@return string NPC当前状态描述
function BM_StoryRuntime:GetNPCStatePrompt(npcId)
    local npcState = self.dataModule.npcStates[npcId]
    if not npcState then return "" end
    
    local parts = {}
    table.insert(parts, string.format("# %s 当前状态", npcId))
    table.insert(parts, string.format("- 信任度: %d/100", npcState.trust))
    table.insert(parts, string.format("- 情绪值: %d/100", npcState.emotion))
    table.insert(parts, string.format("- 关系值: %d/100", npcState.relation))
    
    if #npcState.tags > 0 then
        table.insert(parts, "- 当前状态: " .. table.concat(npcState.tags, ", "))
    end
    
    if npcState.currentIntent ~= "" then
        table.insert(parts, "- 当前意图: " .. npcState.currentIntent)
    end
    
    return table.concat(parts, "\n")
end

-- ==================== 物品/条件管理 ====================

---添加物品
---@param itemId string 物品ID
---@param count number 数量
function BM_StoryRuntime:AddItem(itemId, count)
    local oldCount = self.dataModule.inventory[itemId] or 0
    local newCount = oldCount + count
    self.dataModule.inventory[itemId] = newCount
    
    print(string.rep("-", 60))
    print("[数据变化] 获得物品")
    print(string.format("  物品: %s", itemId))
    print(string.format("  数量: %d -> %d (+%d)", oldCount, newCount, count))
    print(string.rep("-", 60))
end

---移除物品
---@param itemId string 物品ID
---@param count number 数量
---@return boolean 是否成功
function BM_StoryRuntime:RemoveItem(itemId, count)
    local current = self.dataModule.inventory[itemId] or 0
    if current >= count then
        local newCount = current - count
        self.dataModule.inventory[itemId] = newCount
        
        print(string.rep("-", 60))
        print("[数据变化] 失去物品")
        print(string.format("  物品: %s", itemId))
        print(string.format("  数量: %d -> %d (-%d)", current, newCount, count))
        print(string.rep("-", 60))
        
        return true
    else
        print(string.format("[BM_StoryRuntime] 警告：物品数量不足 - %s (需要%d, 拥有%d)", itemId, count, current))
        return false
    end
end

---检查物品数量
---@param itemId string 物品ID
---@return number 物品数量
function BM_StoryRuntime:GetItemCount(itemId)
    return self.dataModule.inventory[itemId] or 0
end

---设置全局标记
---@param flagName string 标记名
---@param value any 值
function BM_StoryRuntime:SetGlobalFlag(flagName, value)
    local oldValue = self.dataModule.globalFlags[flagName]
    self.dataModule.globalFlags[flagName] = value
    
    print(string.rep("-", 60))
    print("[数据变化] 全局标记设置")
    print(string.format("  标记名: %s", flagName))
    print(string.format("  旧值: %s", tostring(oldValue)))
    print(string.format("  新值: %s", tostring(value)))
    print(string.rep("-", 60))
end

---获取全局标记
---@param flagName string 标记名
---@return any
function BM_StoryRuntime:GetGlobalFlag(flagName)
    return self.dataModule.globalFlags[flagName]
end

-- ==================== 事件管理 ====================

---触发事件
---@param eventId string 事件ID
function BM_StoryRuntime:TriggerEvent(eventId)
    if not self.dataModule.triggeredEvents[eventId] then
        self.dataModule.triggeredEvents[eventId] = true
        print("[BM_StoryRuntime] 触发事件:", eventId)
    end
end

---检查事件是否已触发
---@param eventId string 事件ID
---@return boolean
function BM_StoryRuntime:IsEventTriggered(eventId)
    return self.dataModule.triggeredEvents[eventId] == true
end

-- ==================== 对话状态 ====================

---开始对话
---@param npcId string NPC ID
function BM_StoryRuntime:StartDialogue(npcId)
    self.dataModule.inDialogue = true
    self.dataModule.currentNpcId = npcId
end

---结束对话
function BM_StoryRuntime:EndDialogue()
    self.dataModule.inDialogue = false
    self.dataModule.currentNpcId = nil
end

---检查是否在对话中
---@return boolean
function BM_StoryRuntime:IsInDialogue()
    return self.dataModule.inDialogue
end

---获取当前对话NPC
---@return string|nil
function BM_StoryRuntime:GetCurrentNPC()
    return self.dataModule.currentNpcId
end

-- ==================== 数据导出（用于Prompt） ====================

---获取完整的运行时状态Prompt
---@return string 状态描述
function BM_StoryRuntime:GetRuntimeStatePrompt()
    local parts = {}
    
    table.insert(parts, string.format("# 游戏状态 (第%d次循环)", self.dataModule.loopCount))
    table.insert(parts, "当前场景: " .. (self.dataModule.currentSceneId or "未设置"))
    
    -- NPC状态
    table.insert(parts, "\n## NPC状态")
    for npcId, npcState in pairs(self.dataModule.npcStates) do
        table.insert(parts, self:GetNPCStatePrompt(npcId))
    end
    
    -- 物品
    if next(self.dataModule.inventory) then
        table.insert(parts, "\n## 物品")
        for itemId, count in pairs(self.dataModule.inventory) do
            table.insert(parts, string.format("- %s: %d", itemId, count))
        end
    end
    
    return table.concat(parts, "\n")
end

-- ==================== 工具函数 ====================

---初始化游戏（从配置创建初始状态）
---@param storyConfig table BM_StoryConfig实例
function BM_StoryRuntime:InitializeFromConfig(storyConfig)
    -- 初始化所有NPC状态
    local npcCount = 0
    for npcId, npcTemplate in pairs(storyConfig.dataModule.npcTemplates) do
        self:InitNPCState(npcId, npcTemplate.initialStates or {})
        npcCount = npcCount + 1
    end
    
    -- 设置初始场景（使用配置中指定的初始场景）
    local startSceneId = storyConfig:GetStartScene()
    if startSceneId and startSceneId ~= "" then
        self:UnlockScene(startSceneId)
        self:ChangeScene(startSceneId)
        print(string.format("  - 初始场景: %s (%s)", 
            startSceneId, 
            storyConfig:GetScene(startSceneId).name or "未命名"))
    else
        print("[BM_StoryRuntime] 警告：未设置初始场景！")
    end
    
    self.dataModule.startTime = os.time()
    self.dataModule.currentLoopStartTime = os.time()
    self.dataModule.loopCount = 0  -- 初始状态为0，由StartNewLoop()开始第1次循环
    
    print("[BM_StoryRuntime] 游戏初始化完成")
    print(string.format("  - 初始化NPC数: %d", npcCount))
end

---调试打印（详细版）
function BM_StoryRuntime:DebugPrint()
    print("\n" .. string.rep("=", 70))
    print("【变化数据层】BM_StoryRuntime - 运行时状态数据")
    print(string.rep("=", 70))
    
    -- 基本信息
    print("\n[基本信息]")
    print("  当前故事ID:", self.dataModule.currentStoryId)
    print("  循环次数:", self.dataModule.loopCount)
    print("  当前场景:", self.dataModule.currentSceneId)
    print("  是否在对话中:", self.dataModule.inDialogue)
    if self.dataModule.currentNpcId then
        print("  对话对象:", self.dataModule.currentNpcId)
    end
    
    -- NPC状态
    print("\n[NPC状态] 共", self:GetNPCCount(), "个NPC")
    local npcIndex = 1
    for npcId, npcState in pairs(self.dataModule.npcStates) do
        print(string.format("  %d. [%s]", npcIndex, npcId))
        print(string.format("     trust=%+d, emotion=%+d, relation=%+d", 
            npcState.trust or 0, npcState.emotion or 0, npcState.relation or 0))
        if npcState.tags and #npcState.tags > 0 then
            print(string.format("     标签: %s", table.concat(npcState.tags, ", ")))
        end
        if npcState.currentScene and npcState.currentScene ~= "" then
            print(string.format("     当前位置: %s", npcState.currentScene))
        end
        npcIndex = npcIndex + 1
    end
    
    -- 解锁状态
    print("\n[解锁状态]")
    print("  已解锁场景数:", self:GetUnlockedSceneCount())
    local unlockedScenes = {}
    for sceneId, _ in pairs(self.dataModule.unlockedScenes) do
        table.insert(unlockedScenes, sceneId)
    end
    if #unlockedScenes > 0 then
        print("    场景列表:", table.concat(unlockedScenes, ", "))
    end
    
    print("  已解锁抉择数:", self:GetUnlockedChoiceCount())
    
    -- 物品背包
    local itemCount = self:GetItemTypeCount()
    if itemCount > 0 then
        print("\n[物品背包] 共", itemCount, "种物品")
        for itemId, count in pairs(self.dataModule.inventory) do
            print(string.format("  - %s: %d", itemId, count))
        end
    else
        print("\n[物品背包] 空")
    end
    
    -- 全局标记
    local flagCount = 0
    for _ in pairs(self.dataModule.globalFlags) do flagCount = flagCount + 1 end
    if flagCount > 0 then
        print("\n[全局标记] 共", flagCount, "个标记")
        for flagName, value in pairs(self.dataModule.globalFlags) do
            print(string.format("  - %s = %s", flagName, tostring(value)))
        end
    else
        print("\n[全局标记] 无")
    end
    
    -- 当前循环选择历史
    local choiceCount = #self.dataModule.currentLoopChoices
    print("\n[当前循环选择历史] 共", choiceCount, "次选择")
    if choiceCount > 0 then
        for i, choice in ipairs(self.dataModule.currentLoopChoices) do
            print(string.format("  %d. [%s] 在场景 %s", i, choice.choiceId, choice.sceneId))
        end
    end
    
    -- 历史循环记录
    local historyCount = #self.dataModule.allLoopsHistory
    if historyCount > 0 then
        print("\n[历史循环记录] 共经历了", historyCount, "次循环")
    end
    
    print("\n" .. string.rep("=", 70) .. "\n")
end

---获取NPC数量
---@return number
function BM_StoryRuntime:GetNPCCount()
    local count = 0
    for _ in pairs(self.dataModule.npcStates) do count = count + 1 end
    return count
end

---获取已解锁场景数
---@return number
function BM_StoryRuntime:GetUnlockedSceneCount()
    local count = 0
    for _ in pairs(self.dataModule.unlockedScenes) do count = count + 1 end
    return count
end

---获取已解锁抉择数
---@return number
function BM_StoryRuntime:GetUnlockedChoiceCount()
    local count = 0
    for _ in pairs(self.dataModule.unlockedChoices) do count = count + 1 end
    return count
end

---获取物品种类数
---@return number
function BM_StoryRuntime:GetItemTypeCount()
    local count = 0
    for _ in pairs(self.dataModule.inventory) do count = count + 1 end
    return count
end

-- ==================== 场景历史管理（多故事系统新增）====================

---获取场景访问历史
---@return table 场景ID数组
function BM_StoryRuntime:GetSceneHistory()
    return self.dataModule.sceneHistory
end

---获取当前可到达的场景列表（缓存）
---@return table 场景信息数组
function BM_StoryRuntime:GetCachedAvailableScenes()
    return self.dataModule.availableScenes
end

---检查是否访问过某个场景
---@param sceneId string 场景ID
---@return boolean 是否访问过
function BM_StoryRuntime:HasVisitedScene(sceneId)
    for _, id in ipairs(self.dataModule.sceneHistory) do
        if id == sceneId then
            return true
        end
    end
    return false
end

---获取当前故事ID
---@return string 故事ID
function BM_StoryRuntime:GetCurrentStoryId()
    return self.dataModule.currentStoryId
end

-- ==================== 多故事系统支持 ====================

---清空所有运行时状态（用于切换故事）
---重置所有字段到初始状态，为加载新故事做准备
function BM_StoryRuntime:Clear()
    self.dataModule.loopCount = 0
    self.dataModule.currentSceneId = ""
    self.dataModule.currentStoryId = ""
    self.dataModule.inDialogue = false
    self.dataModule.currentNpcId = nil
    self.dataModule.unlockedScenes = {}
    self.dataModule.unlockedChoices = {}
    self.dataModule.triggeredEvents = {}
    self.dataModule.npcStates = {}
    self.dataModule.relationships = {}
    self.dataModule.inventory = {}
    self.dataModule.globalFlags = {}
    self.dataModule.currentLoopChoices = {}
    self.dataModule.allLoopsHistory = {}
    self.dataModule.sceneHistory = {}
    self.dataModule.availableScenes = {}
    self.dataModule.dynamicChoices = {}
    self.dataModule.startTime = 0
    self.dataModule.currentLoopStartTime = 0
    self.dataModule.totalPlayTime = 0
    
    print("[BM_StoryRuntime] 运行时状态已清空")
end

-- ==================== 动态抉择管理 ====================

---注册AI动态生成的抉择
---@param choiceData table 动态抉择数据
function BM_StoryRuntime:RegisterDynamicChoice(choiceData)
    if not choiceData.id or not choiceData.sceneId then
        print("[BM_StoryRuntime] ❌ 动态抉择数据不完整")
        return
    end
    
    -- 使用 sceneId 作为 key 来组织动态抉择
    if not self.dataModule.dynamicChoices[choiceData.sceneId] then
        self.dataModule.dynamicChoices[choiceData.sceneId] = {}
    end
    
    -- 存储动态抉择（使用 id 作为 key）
    self.dataModule.dynamicChoices[choiceData.sceneId][choiceData.id] = choiceData
    
    print(string.format("[BM_StoryRuntime] ✅ 注册动态抉择: %s (场景: %s)", 
        choiceData.name, choiceData.sceneId))
end

---获取指定场景的所有动态抉择
---@param sceneId string 场景ID
---@return table 动态抉择数组
function BM_StoryRuntime:GetDynamicChoices(sceneId)
    local sceneChoices = self.dataModule.dynamicChoices[sceneId] or {}
    local result = {}
    
    for _, choice in pairs(sceneChoices) do
        table.insert(result, choice)
    end
    
    return result
end

---获取指定ID的动态抉择
---@param choiceId string 抉择ID
---@return table|nil 动态抉择数据
function BM_StoryRuntime:GetDynamicChoice(choiceId)
    -- 遍历所有场景的动态抉择查找
    for sceneId, sceneChoices in pairs(self.dataModule.dynamicChoices) do
        if sceneChoices[choiceId] then
            return sceneChoices[choiceId]
        end
    end
    
    return nil
end

---清空指定场景的动态抉择（通常在场景切换或循环重置时调用）
---@param sceneId string 场景ID
function BM_StoryRuntime:ClearDynamicChoices(sceneId)
    if sceneId then
        self.dataModule.dynamicChoices[sceneId] = {}
        print(string.format("[BM_StoryRuntime] 清空场景 %s 的动态抉择", sceneId))
    else
        self.dataModule.dynamicChoices = {}
        print("[BM_StoryRuntime] 清空所有动态抉择")
    end
end

return BM_StoryRuntime

