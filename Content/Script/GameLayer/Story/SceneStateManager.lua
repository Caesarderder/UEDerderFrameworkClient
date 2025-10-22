---场景状态管理器
---负责管理场景流转、NPC对话、抉择执行等游戏核心逻辑
---职责：
--- 1. 场景进入与信息获取
--- 2. NPC对话状态管理
--- 3. 抉择解锁与执行
--- 4. 场景切换/循环判定
---
---作者：derder
---日期：2025-10-20

local BM_StoryConfig = require("DataLayer.Story.BM_StoryConfig")
local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")

local SceneStateManager = {}

-- ==================== 场景管理 ====================

---进入场景（切换到指定场景并获取完整信息）
---@param sceneId string 场景ID
---@return table 场景状态数据 {success, sceneInfo, npcs, availableChoices, error}
function SceneStateManager.EnterScene(sceneId)
    local result = {
        success = false,
        sceneInfo = nil,
        npcs = {},
        availableChoices = {},
        error = nil
    }
    
    -- 1. 验证场景是否存在
    local sceneConfig = BM_StoryConfig:GetScene(sceneId)
    if not sceneConfig then
        result.error = "场景不存在: " .. sceneId
        print("[SceneStateManager] ❌ " .. result.error)
        return result
    end
    
    -- 2. 切换场景
    BM_StoryRuntime:ChangeScene(sceneId)
    
    -- 3. 解锁场景（如果未解锁）
    if not BM_StoryRuntime:IsSceneUnlocked(sceneId) then
        BM_StoryRuntime:UnlockScene(sceneId)
    end
    
    -- 4. 构建场景信息
    result.sceneInfo = {
        id = sceneConfig.id,
        name = sceneConfig.name,
        description = sceneConfig.description,
        atmosphere = sceneConfig.atmosphere or ""
    }
    
    -- 5. 获取场景中的NPC列表（带状态）
    if sceneConfig.npcIds then
        for _, npcId in ipairs(sceneConfig.npcIds) do
            local npcTemplate = BM_StoryConfig:GetNPC(npcId)
            local npcState = BM_StoryRuntime:GetNPCState(npcId)
            
            if npcTemplate then
                local npcInfo = {
                    id = npcId,
                    name = npcTemplate.name,
                    role = npcTemplate.role,
                    personality = npcTemplate.personality,
                    dialogueStyle = npcTemplate.dialogueStyle,
                    -- 当前状态（如果已初始化）
                    currentState = npcState and {
                        trust = npcState.trust or 0,
                        emotion = npcState.emotion or 0,
                        relation = npcState.relation or 0,
                        tags = npcState.tags or {}
                    } or nil
                }
                table.insert(result.npcs, npcInfo)
            end
        end
    end
    
    -- 6. 获取当前可用的抉择（已解锁的）
    result.availableChoices = SceneStateManager.GetAvailableChoices()
    
    result.success = true
    
    print("\n" .. string.rep("=", 70))
    print("[SceneStateManager] 进入场景")
    print(string.rep("=", 70))
    print(string.format("  场景ID: %s", sceneId))
    print(string.format("  场景名称: %s", result.sceneInfo.name))
    print(string.format("  NPC数量: %d", #result.npcs))
    print(string.format("  可用抉择: %d", #result.availableChoices))
    print(string.rep("=", 70) .. "\n")
    
    return result
end

---获取当前场景完整信息
---@return table|nil 场景状态数据 {sceneInfo, npcs, availableChoices}
function SceneStateManager.GetCurrentSceneInfo()
    local currentSceneId = BM_StoryRuntime:GetCurrentSceneId()
    
    if not currentSceneId or currentSceneId == "" then
        print("[SceneStateManager] ⚠️ 当前没有激活的场景")
        return nil
    end
    
    return SceneStateManager.EnterScene(currentSceneId)
end

---获取当前场景的所有NPC（带状态）
---@return table NPC信息数组
function SceneStateManager.GetSceneNPCs()
    local currentSceneId = BM_StoryRuntime:GetCurrentSceneId()
    if not currentSceneId or currentSceneId == "" then
        return {}
    end
    
    local sceneConfig = BM_StoryConfig:GetScene(currentSceneId)
    if not sceneConfig or not sceneConfig.npcIds then
        return {}
    end
    
    local npcs = {}
    for _, npcId in ipairs(sceneConfig.npcIds) do
        local npcTemplate = BM_StoryConfig:GetNPC(npcId)
        local npcState = BM_StoryRuntime:GetNPCState(npcId)
        
        if npcTemplate then
            table.insert(npcs, {
                id = npcId,
                name = npcTemplate.name,
                role = npcTemplate.role,
                personality = npcTemplate.personality,
                currentState = npcState
            })
        end
    end
    
    return npcs
end

-- ==================== 对话管理 ====================

---开始与NPC对话
---@param npcId string NPC ID
---@return table 结果 {success, npcInfo, error}
function SceneStateManager.StartDialogue(npcId)
    local result = {
        success = false,
        npcInfo = nil,
        error = nil
    }
    
    -- 1. 验证NPC是否存在
    local npcTemplate = BM_StoryConfig:GetNPC(npcId)
    if not npcTemplate then
        result.error = "NPC不存在: " .. npcId
        print("[SceneStateManager] ❌ " .. result.error)
        return result
    end
    
    -- 2. 验证NPC是否在当前场景
    local currentSceneId = BM_StoryRuntime:GetCurrentSceneId()
    local sceneConfig = BM_StoryConfig:GetScene(currentSceneId)
    
    local npcInScene = false
    if sceneConfig and sceneConfig.npcIds then
        for _, id in ipairs(sceneConfig.npcIds) do
            if id == npcId then
                npcInScene = true
                break
            end
        end
    end
    
    if not npcInScene then
        result.error = string.format("NPC [%s] 不在当前场景 [%s]", npcId, currentSceneId)
        print("[SceneStateManager] ⚠️ " .. result.error)
        return result
    end
    
    -- 3. 开始对话
    BM_StoryRuntime:StartDialogue(npcId)
    
    -- 4. 获取NPC完整信息
    local npcState = BM_StoryRuntime:GetNPCState(npcId)
    result.npcInfo = {
        id = npcId,
        name = npcTemplate.name,
        role = npcTemplate.role,
        personality = npcTemplate.personality,
        motivation = npcTemplate.motivation,
        background = npcTemplate.background,
        dialogueStyle = npcTemplate.dialogueStyle,
        currentState = npcState
    }
    
    result.success = true
    
    print(string.rep("-", 60))
    print("[SceneStateManager] 开始对话")
    print(string.format("  对话对象: %s (%s)", npcTemplate.name, npcId))
    print(string.format("  场景: %s", currentSceneId))
    print(string.rep("-", 60))
    
    return result
end

---结束当前对话
---@return table 结果 {success}
function SceneStateManager.EndDialogue()
    BM_StoryRuntime:EndDialogue()
    
    print(string.rep("-", 60))
    print("[SceneStateManager] 结束对话")
    print(string.rep("-", 60))
    
    return {success = true}
end

---获取当前对话的NPC
---@return table|nil NPC信息
function SceneStateManager.GetCurrentDialogueNPC()
    local npcId = BM_StoryRuntime:GetCurrentNPC()
    if not npcId then
        return nil
    end
    
    local npcTemplate = BM_StoryConfig:GetNPC(npcId)
    local npcState = BM_StoryRuntime:GetNPCState(npcId)
    
    if not npcTemplate then
        return nil
    end
    
    return {
        id = npcId,
        name = npcTemplate.name,
        role = npcTemplate.role,
        personality = npcTemplate.personality,
        currentState = npcState
    }
end

-- ==================== 抉择管理 ====================

---获取当前场景的可用抉择列表（已解锁的，包括动态抉择）
---@return table 抉择信息数组
function SceneStateManager.GetAvailableChoices()
    local currentSceneId = BM_StoryRuntime:GetCurrentSceneId()
    if not currentSceneId or currentSceneId == "" then
        return {}
    end
    
    local availableChoices = {}
    
    -- 1. 获取配置中的抉择
    local sceneChoices = BM_StoryConfig:GetSceneChoices(currentSceneId)
    for _, choiceTemplate in ipairs(sceneChoices) do
        -- 检查抉择是否已解锁
        if BM_StoryRuntime:IsChoiceUnlocked(choiceTemplate.id) then
            table.insert(availableChoices, {
                id = choiceTemplate.id,
                name = choiceTemplate.name,
                description = choiceTemplate.description,
                sceneId = choiceTemplate.sceneId,
                isDynamic = false
            })
        end
    end
    
    -- 2. 获取当前场景的动态抉择
    local dynamicChoices = BM_StoryRuntime:GetDynamicChoices(currentSceneId)
    for _, dynamicChoice in ipairs(dynamicChoices) do
        -- 检查动态抉择是否已解锁
        if BM_StoryRuntime:IsChoiceUnlocked(dynamicChoice.id) then
            table.insert(availableChoices, {
                id = dynamicChoice.id,
                name = dynamicChoice.name,
                description = dynamicChoice.description,
                sceneId = dynamicChoice.sceneId,
                isDynamic = true,
                unlockReason = dynamicChoice.unlockReason
            })
        end
    end
    
    return availableChoices
end

---解锁指定抉择（通常由AI工具调用）
---注意：现在抉择全部为动态生成，此函数仅用于验证抉择存在性
---@param choiceId string 抉择ID
---@return table 结果 {success, choiceInfo, error}
function SceneStateManager.UnlockChoice(choiceId)
    local result = {
        success = false,
        choiceInfo = nil,
        error = nil
    }
    
    -- 1. 从动态抉择中查找（现在只有动态抉择）
    local choiceTemplate = BM_StoryRuntime:GetDynamicChoice(choiceId)
    if not choiceTemplate then
        result.error = "动态抉择不存在: " .. choiceId
        print("[SceneStateManager] ❌ " .. result.error)
        return result
    end
    
    -- 2. 动态抉择默认已解锁，这里只是返回信息
    result.choiceInfo = {
        id = choiceTemplate.id,
        name = choiceTemplate.name,
        description = choiceTemplate.description,
        sceneId = choiceTemplate.sceneId
    }
    
    result.success = true
    
    print(string.rep("-", 60))
    print("[SceneStateManager] 验证动态抉择")
    print(string.format("  抉择ID: %s", choiceId))
    print(string.format("  抉择名称: %s", choiceTemplate.name))
    print(string.rep("-", 60))
    
    return result
end

---【新增】动态生成并解锁抉择（AI工具专用）
---@param choiceData table 动态抉择数据 {id, name, description, isDynamic, unlockReason}
---@return table 结果 {success, choiceInfo, error}
function SceneStateManager.UnlockDynamicChoice(choiceData)
    print("[SceneStateManager] 开始处理动态抉择...")
    
    local result = {
        success = false,
        choiceInfo = nil,
        error = nil
    }
    
    -- 1. 验证必需字段
    if not choiceData then
        result.error = "choiceData 为 nil"
        print("[SceneStateManager] ❌ " .. result.error)
        return result
    end
    
    print(string.format("[SceneStateManager] choiceData.id = %s", tostring(choiceData.id)))
    print(string.format("[SceneStateManager] choiceData.name = %s", tostring(choiceData.name)))
    print(string.format("[SceneStateManager] choiceData.description = %s", tostring(choiceData.description)))
    
    if not choiceData.id or not choiceData.name or not choiceData.description then
        result.error = "动态抉择数据不完整"
        print("[SceneStateManager] ❌ " .. result.error)
        return result
    end
    
    -- 2. 获取当前场景ID
    local currentSceneId = BM_StoryRuntime:GetCurrentSceneId()
    print(string.format("[SceneStateManager] 当前场景ID: %s", tostring(currentSceneId)))
    
    if not currentSceneId or currentSceneId == "" then
        result.error = "没有当前场景，无法创建动态抉择"
        print("[SceneStateManager] ❌ " .. result.error)
        return result
    end
    
    -- 3. 构建完整的动态抉择配置
    local dynamicChoice = {
        id = choiceData.id,
        name = choiceData.name,
        description = choiceData.description,
        sceneId = currentSceneId,
        isDynamic = true,
        unlockReason = choiceData.unlockReason,
        timestamp = os.time(),
        -- 动态抉择默认效果（可以后续通过AI的scene_choice来决定）
        effects = {},
        nextScene = nil
    }
    
    -- 4. 将动态抉择注册到Runtime（而不是Config）
    BM_StoryRuntime:RegisterDynamicChoice(dynamicChoice)
    
    -- 5. 解锁该抉择
    BM_StoryRuntime:UnlockChoice(choiceData.id)
    
    result.choiceInfo = {
        id = dynamicChoice.id,
        name = dynamicChoice.name,
        description = dynamicChoice.description,
        sceneId = currentSceneId,
        isDynamic = true
    }
    
    result.success = true
    
    print(string.rep("-", 60))
    print("[SceneStateManager] ✨ 创建动态抉择")
    print(string.format("  抉择ID: %s (动态)", dynamicChoice.id))
    print(string.format("  抉择名称: %s", dynamicChoice.name))
    print(string.format("  描述: %s", dynamicChoice.description))
    print(string.format("  所属场景: %s", currentSceneId))
    if choiceData.unlockReason then
        print(string.format("  解锁原因: %s", choiceData.unlockReason))
    end
    print(string.rep("-", 60))
    
    return result
end

---执行抉择（玩家做出选择，支持动态抉择）
---@param choiceId string 抉择ID
---@return table 结果 {success, effects, judgment, error}
function SceneStateManager.ExecuteChoice(choiceId)
    local result = {
        success = false,
        effects = nil,        -- 抉择效果描述
        judgment = nil,       -- 判定结果：next_scene/continue_loop/end_loop
        targetScene = nil,    -- 如果是next_scene，目标场景ID
        error = nil
    }
    
    -- 1. 查找动态抉择（现在只有动态抉择）
    local choiceTemplate = BM_StoryRuntime:GetDynamicChoice(choiceId)
    
    if not choiceTemplate then
        result.error = "动态抉择不存在: " .. choiceId
        print("[SceneStateManager] ❌ " .. result.error)
        return result
    end
    
    -- 2. 验证抉择是否已解锁
    if not BM_StoryRuntime:IsChoiceUnlocked(choiceId) then
        result.error = "抉择未解锁: " .. choiceId
        print("[SceneStateManager] ❌ " .. result.error)
        return result
    end
    
    -- 3. 记录选择
    local currentSceneId = BM_StoryRuntime:GetCurrentSceneId()
    local currentNpcId = BM_StoryRuntime:GetCurrentNPC()
    BM_StoryRuntime:RecordChoice(choiceId, currentSceneId, currentNpcId)
    
    -- 4. 执行抉择效果
    local effects = choiceTemplate.effects or {}
    result.effects = SceneStateManager._ApplyChoiceEffects(effects)
    
    -- 5. 判定结果
    result.judgment = SceneStateManager._JudgeChoiceResult(choiceTemplate, effects)
    
    result.success = true
    
    print("\n" .. string.rep("=", 70))
    print("[SceneStateManager] 执行动态抉择")
    print(string.rep("=", 70))
    print(string.format("  抉择ID: %s", choiceId))
    print(string.format("  抉择名称: %s", choiceTemplate.name))
    print(string.format("  类型: AI动态生成"))
    print(string.format("  场景: %s", currentSceneId))
    if currentNpcId then
        print(string.format("  相关NPC: %s", currentNpcId))
    end
    print(string.format("  判定结果: %s", result.judgment.type))
    if result.judgment.targetScene then
        print(string.format("  目标场景: %s", result.judgment.targetScene))
    end
    print(string.rep("=", 70) .. "\n")
    
    return result
end

---应用抉择效果（内部方法）
---@param effects table 效果配置
---@return table 应用的效果摘要
function SceneStateManager._ApplyChoiceEffects(effects)
    local appliedEffects = {
        npcChanges = {},
        eventsTriggered = {},
        flagsSet = {},
        itemsGained = {},
        scenesUnlocked = {},
        choicesUnlocked = {}
    }
    
    -- 1. 应用NPC状态变更
    if effects.npcStates then
        for npcId, changes in pairs(effects.npcStates) do
            -- 更新数值状态
            if changes.trust then
                BM_StoryRuntime:UpdateNPCStat(npcId, "trust", changes.trust)
                table.insert(appliedEffects.npcChanges, {
                    npcId = npcId,
                    stat = "trust",
                    delta = changes.trust
                })
            end
            if changes.emotion then
                BM_StoryRuntime:UpdateNPCStat(npcId, "emotion", changes.emotion)
                table.insert(appliedEffects.npcChanges, {
                    npcId = npcId,
                    stat = "emotion",
                    delta = changes.emotion
                })
            end
            if changes.relation then
                BM_StoryRuntime:UpdateNPCStat(npcId, "relation", changes.relation)
                table.insert(appliedEffects.npcChanges, {
                    npcId = npcId,
                    stat = "relation",
                    delta = changes.relation
                })
            end
            
            -- 更新标签
            if changes.tags then
                for _, tag in ipairs(changes.tags) do
                    BM_StoryRuntime:SetNPCTag(npcId, tag, true)
                end
            end
        end
    end
    
    -- 2. 触发事件
    if effects.sceneEvents then
        for _, eventId in ipairs(effects.sceneEvents) do
            BM_StoryRuntime:TriggerEvent(eventId)
            table.insert(appliedEffects.eventsTriggered, eventId)
        end
    end
    
    -- 3. 设置全局标记
    if effects.globalFlags then
        for flagName, value in pairs(effects.globalFlags) do
            BM_StoryRuntime:SetGlobalFlag(flagName, value)
            table.insert(appliedEffects.flagsSet, {name = flagName, value = value})
        end
    end
    
    -- 4. 添加物品
    if effects.items then
        for itemId, count in pairs(effects.items) do
            BM_StoryRuntime:AddItem(itemId, count)
            table.insert(appliedEffects.itemsGained, {id = itemId, count = count})
        end
    end
    
    -- 5. 解锁新场景
    if effects.storyProgress and effects.storyProgress.unlockScenes then
        for _, sceneId in ipairs(effects.storyProgress.unlockScenes) do
            BM_StoryRuntime:UnlockScene(sceneId)
            table.insert(appliedEffects.scenesUnlocked, sceneId)
        end
    end
    
    -- 6. 解锁新抉择
    if effects.storyProgress and effects.storyProgress.unlockChoices then
        for _, choiceId in ipairs(effects.storyProgress.unlockChoices) do
            BM_StoryRuntime:UnlockChoice(choiceId)
            table.insert(appliedEffects.choicesUnlocked, choiceId)
        end
    end
    
    return appliedEffects
end

---判定抉择结果（内部方法）
---@param choiceTemplate table 抉择配置
---@param effects table 效果配置
---@return table 判定结果 {type, targetScene, reason}
function SceneStateManager._JudgeChoiceResult(choiceTemplate, effects)
    local judgment = {
        type = "continue_loop",  -- 默认：继续当前循环
        targetScene = nil,
        reason = ""
    }
    
    -- 判定逻辑：
    -- 1. 如果配置中有nextScene，则切换场景
    if choiceTemplate.nextScene then
        judgment.type = "next_scene"
        judgment.targetScene = choiceTemplate.nextScene
        judgment.reason = "抉择指定了下一个场景"
        return judgment
    end
    
    -- 2. 如果配置中标记为导致循环重置
    if choiceTemplate.causesLoopReset then
        judgment.type = "end_loop"
        judgment.reason = choiceTemplate.loopResetReason or "抉择导致灾难发生，循环重置"
        return judgment
    end
    
    -- 3. 如果触发了特定事件（灾难相关）
    if effects.sceneEvents then
        for _, eventId in ipairs(effects.sceneEvents) do
            if string.find(eventId, "disaster") or string.find(eventId, "death") then
                judgment.type = "end_loop"
                judgment.reason = "触发灾难事件: " .. eventId
                return judgment
            end
        end
    end
    
    -- 4. 默认：继续当前循环
    judgment.reason = "抉择执行完毕，继续当前场景"
    return judgment
end

-- ==================== 循环管理 ====================

---开始新循环
---@param reason string|nil 重置原因
---@return table 结果 {success, newLoopCount}
function SceneStateManager.StartNewLoop(reason)
    reason = reason or "手动重置"
    
    BM_StoryRuntime:StartNewLoop()
    
    local newLoopCount = BM_StoryRuntime:GetLoopCount()
    
    -- ========== 清空普通NPC的对话历史（循环重置，普通NPC失去记忆）==========
    -- 注意：仇人（role="enemy"）保留记忆，不清空历史
    local GameContext = require("Core.GameContext")
    local llmMgr = GameContext:GetLlmManager()
    if llmMgr then
        local BM_LlmContext = require("DataLayer.Llm.BM_LlmContext")
        local charactersWithHistory = BM_LlmContext:GetCharactersWithHistory()
        
        local clearedCount = 0
        local preservedEnemies = {}
        
        for _, npcId in ipairs(charactersWithHistory) do
            -- 检查NPC的role
            local npcConfig = BM_StoryConfig:GetNPC(npcId)
            
            if npcConfig and npcConfig.role == "enemy" then
                -- 仇人保留记忆，不清空
                table.insert(preservedEnemies, npcConfig.name or npcId)
            else
                -- 普通NPC失去记忆，清空历史
                llmMgr:ClearCharacterHistory(npcId)
                clearedCount = clearedCount + 1
            end
        end
        
        print(string.format("[SceneStateManager] ✅ 已清空 %d 个普通NPC的对话历史（循环重置）", clearedCount))
        if #preservedEnemies > 0 then
            print(string.format("[SceneStateManager] 📝 保留仇人的记忆: %s", table.concat(preservedEnemies, ", ")))
        end
    end
    
    print("\n" .. string.rep("=", 70))
    print("[SceneStateManager] 开始新循环")
    print(string.rep("=", 70))
    print(string.format("  循环次数: %d", newLoopCount))
    print(string.format("  重置原因: %s", reason))
    print(string.rep("=", 70) .. "\n")
    
    return {
        success = true,
        newLoopCount = newLoopCount,
        reason = reason
    }
end

---获取当前循环状态
---@return table 循环信息 {loopCount, currentScene, inDialogue, playTime}
function SceneStateManager.GetLoopStatus()
    return {
        loopCount = BM_StoryRuntime:GetLoopCount(),
        currentScene = BM_StoryRuntime:GetCurrentSceneId(),
        inDialogue = BM_StoryRuntime:IsInDialogue(),
        currentNpc = BM_StoryRuntime:GetCurrentNPC(),
        playTime = BM_StoryRuntime:GetTotalPlayTime()
    }
end

-- ==================== 调试工具 ====================

---打印当前场景状态（调试用）
function SceneStateManager.DebugPrintState()
    print("\n" .. string.rep("=", 70))
    print("[SceneStateManager] 当前场景状态")
    print(string.rep("=", 70))
    
    local loopStatus = SceneStateManager.GetLoopStatus()
    print(string.format("循环次数: %d", loopStatus.loopCount))
    print(string.format("当前场景: %s", loopStatus.currentScene or "无"))
    print(string.format("是否在对话: %s", loopStatus.inDialogue and "是" or "否"))
    if loopStatus.currentNpc then
        print(string.format("对话对象: %s", loopStatus.currentNpc))
    end
    
    local npcs = SceneStateManager.GetSceneNPCs()
    print(string.format("\n场景NPC数: %d", #npcs))
    for i, npc in ipairs(npcs) do
        print(string.format("  %d. %s (%s)", i, npc.name, npc.id))
    end
    
    local choices = SceneStateManager.GetAvailableChoices()
    print(string.format("\n可用抉择数: %d", #choices))
    for i, choice in ipairs(choices) do
        print(string.format("  %d. %s (%s)", i, choice.name, choice.id))
    end
    
    print(string.rep("=", 70) .. "\n")
end

return SceneStateManager

