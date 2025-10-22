---故事Prompt构建器
---将配置和运行时数据转换为LLM所需的Prompt格式
---@class StoryPromptBuilder
local StoryPromptBuilder = {}

---构建完整的系统Prompt
---@param bmStoryConfig table BM_StoryConfig实例
---@param bmStoryRuntime table BM_StoryRuntime实例
---@return string System Prompt
function StoryPromptBuilder.BuildSystemPrompt(bmStoryConfig, bmStoryRuntime)
    local parts = {}
    
    -- 1. 游戏背景
    table.insert(parts, bmStoryConfig:GetBackgroundPrompt())
    
    -- 2. 当前场景
    local currentSceneId = bmStoryRuntime:GetCurrentSceneId()
    if currentSceneId and currentSceneId ~= "" then
        table.insert(parts, "\n" .. bmStoryConfig:GetScenePrompt(currentSceneId))
        
        -- 场景内NPC
        table.insert(parts, bmStoryConfig:GetSceneNPCsPrompt(currentSceneId))
    end
    
    -- 3. 运行时状态
    table.insert(parts, "\n" .. bmStoryRuntime:GetRuntimeStatePrompt())
    
    return table.concat(parts, "\n")
end

---构建NPC对话Prompt（用于NPC扮演）
---@param bmStoryConfig table BM_StoryConfig实例
---@param bmStoryRuntime table BM_StoryRuntime实例
---@param npcId string NPC ID
---@return string NPC对话Prompt
function StoryPromptBuilder.BuildNPCDialoguePrompt(bmStoryConfig, bmStoryRuntime, npcId)
    local parts = {}
    
    -- 1. NPC基础信息
    table.insert(parts, bmStoryConfig:GetNPCPrompt(npcId))
    
    -- 2. NPC当前状态
    table.insert(parts, "\n" .. bmStoryRuntime:GetNPCStatePrompt(npcId))
    
    -- 3. 场景抉择生成指导（新增！）
    local currentSceneId = bmStoryRuntime:GetCurrentSceneId()
    if currentSceneId and currentSceneId ~= "" then
        local choiceGuidance = bmStoryConfig:GetSceneChoiceGuidancePrompt(currentSceneId)
        if choiceGuidance then
            table.insert(parts, "\n" .. choiceGuidance)
        end
    end
    
    -- 4. 对话指导
    table.insert(parts, "\n## 对话指导")
    table.insert(parts, "请以该角色的身份与玩家对话，表现出角色的性格和当前状态。")
    table.insert(parts, "根据信任度、情绪值和关系值调整对话态度。")
    
    -- 根据状态值提供提示
    local npcState = bmStoryRuntime:GetNPCState(npcId)
    if npcState then
        if npcState.trust < -30 then
            table.insert(parts, "- 当前信任度很低，表现出警惕和怀疑")
        elseif npcState.trust > 30 then
            table.insert(parts, "- 当前信任度较高，可以透露更多信息")
        end
        
        if npcState.emotion < -30 then
            table.insert(parts, "- 当前情绪低落/愤怒，语气消极")
        elseif npcState.emotion > 30 then
            table.insert(parts, "- 当前情绪愉悦，语气友好")
        end
    end
    
    return table.concat(parts, "\n")
end

---构建可用抉择列表Prompt
---@param bmStoryConfig table BM_StoryConfig实例
---@param bmStoryRuntime table BM_StoryRuntime实例
---@param sceneId string 场景ID
---@return string 抉择列表Prompt
function StoryPromptBuilder.BuildAvailableChoicesPrompt(bmStoryConfig, bmStoryRuntime, sceneId)
    local ConditionEvaluator = require("GameLayer.Story.Tools.ConditionEvaluator")
    
    -- 获取场景的所有抉择
    local allChoices = bmStoryConfig:GetSceneChoices(sceneId)
    
    -- 过滤出可用的抉择
    local availableChoices = {}
    local context = ConditionEvaluator.BuildContextFromRuntime(bmStoryRuntime)
    
    for _, choice in ipairs(allChoices) do
        -- 检查解锁条件
        local unlocked = ConditionEvaluator.Evaluate(choice.unlockCondition or "", context)
        if unlocked then
            table.insert(availableChoices, choice)
        end
    end
    
    -- 构建Prompt
    if #availableChoices == 0 then
        return "## 当前无可用抉择\n观察环境或与NPC对话以解锁新选项。"
    end
    
    local parts = {}
    table.insert(parts, "## 可用抉择")
    
    for i, choice in ipairs(availableChoices) do
        table.insert(parts, string.format(
            "\n### %d. %s\n%s",
            i, choice.name, choice.description
        ))
    end
    
    return table.concat(parts, "\n")
end

---构建循环记忆Prompt（用于AI理解玩家历史选择）
---@param bmStoryRuntime table BM_StoryRuntime实例
---@param maxLoops number|nil 最多显示几次循环（默认3）
---@return string 循环记忆Prompt
function StoryPromptBuilder.BuildLoopMemoryPrompt(bmStoryRuntime, maxLoops)
    maxLoops = maxLoops or 3
    
    local allHistory = bmStoryRuntime.dataModule.allLoopsHistory
    local historyCount = #allHistory
    
    if historyCount == 0 then
        return "## 循环记忆\n这是第一次循环。"
    end
    
    local parts = {}
    table.insert(parts, "## 循环记忆")
    
    -- 显示最近N次循环
    local startIdx = math.max(1, historyCount - maxLoops + 1)
    for i = startIdx, historyCount do
        local loopData = allHistory[i]
        table.insert(parts, string.format("\n### 第%d次循环", loopData.loopCount))
        
        if #loopData.choices > 0 then
            for _, choice in ipairs(loopData.choices) do
                table.insert(parts, string.format("- %s (场景: %s)", 
                    choice.choiceId, choice.sceneId))
            end
        else
            table.insert(parts, "- 未做出关键选择")
        end
    end
    
    -- 当前循环
    local currentChoices = bmStoryRuntime:GetCurrentLoopChoices()
    table.insert(parts, string.format("\n### 当前循环（第%d次）", bmStoryRuntime:GetLoopCount()))
    if #currentChoices > 0 then
        for _, choice in ipairs(currentChoices) do
            table.insert(parts, string.format("- %s (场景: %s)", 
                choice.choiceId, choice.sceneId))
        end
    else
        table.insert(parts, "- 循环刚开始")
    end
    
    return table.concat(parts, "\n")
end

---构建简化的状态摘要（用于UI显示）
---@param bmStoryRuntime table BM_StoryRuntime实例
---@return table 状态摘要 {loopCount, sceneCount, npcStatuses}
function StoryPromptBuilder.BuildStateSummary(bmStoryRuntime)
    local summary = {
        loopCount = bmStoryRuntime:GetLoopCount(),
        currentScene = bmStoryRuntime:GetCurrentSceneId(),
        npcStatuses = {}
    }
    
    -- 提取NPC简要状态
    for npcId, npcState in pairs(bmStoryRuntime.dataModule.npcStates) do
        local status = "中立"
        if npcState.relation > 30 then
            status = "友好"
        elseif npcState.relation < -30 then
            status = "敌对"
        end
        
        summary.npcStatuses[npcId] = {
            relation = npcState.relation,
            status = status,
            tags = npcState.tags
        }
    end
    
    return summary
end

---构建FunctionCall的Schema（用于LLM调用）
---@return table FunctionCall定义数组
function StoryPromptBuilder.BuildFunctionCallSchema()
    return {
        {
            name = "make_choice",
            description = "做出一个关键抉择",
            parameters = {
                type = "object",
                properties = {
                    choiceId = {
                        type = "string",
                        description = "抉择ID"
                    },
                    reason = {
                        type = "string",
                        description = "做出此选择的理由"
                    }
                },
                required = {"choiceId"}
            }
        },
        {
            name = "update_npc_state",
            description = "更新NPC状态（AI自动调用）",
            parameters = {
                type = "object",
                properties = {
                    npcId = {
                        type = "string",
                        description = "NPC ID"
                    },
                    statChanges = {
                        type = "object",
                        description = "状态变化，如 {trust: 10, emotion: -5}",
                        properties = {
                            trust = {type = "number"},
                            emotion = {type = "number"},
                            relation = {type = "number"}
                        }
                    },
                    addTags = {
                        type = "array",
                        description = "添加的标记",
                        items = {type = "string"}
                    },
                    removeTags = {
                        type = "array",
                        description = "移除的标记",
                        items = {type = "string"}
                    }
                },
                required = {"npcId", "statChanges"}
            }
        },
        {
            name = "trigger_event",
            description = "触发特定事件",
            parameters = {
                type = "object",
                properties = {
                    eventId = {
                        type = "string",
                        description = "事件ID"
                    }
                },
                required = {"eventId"}
            }
        },
        {
            name = "start_new_loop",
            description = "结束当前循环，开始新的一次循环（用于灾难/死亡事件）",
            parameters = {
                type = "object",
                properties = {
                    reason = {
                        type = "string",
                        description = "重置原因，如'灾难发生'、'玩家死亡'"
                    }
                },
                required = {"reason"}
            }
        },
        {
            name = "switch_scene",
            description = "切换到另一个场景",
            parameters = {
                type = "object",
                properties = {
                    sceneId = {
                        type = "string",
                        description = "目标场景ID，如'scene_park'"
                    },
                    reason = {
                        type = "string",
                        description = "切换原因，如'追踪雷克斯'"
                    }
                },
                required = {"sceneId"}
            }
        },
        {
            name = "continue_scene",
            description = "继续当前场景（抉择影响轻微，不需要切换场景或循环）",
            parameters = {
                type = "object",
                properties = {
                    reason = {
                        type = "string",
                        description = "继续原因，如'轻微互动，继续对话'"
                    }
                },
                required = {"reason"}
            }
        }
    }
end

--[[
使用示例：

-- 1. 构建完整系统Prompt（游戏开始时）
local systemPrompt = StoryPromptBuilder.BuildSystemPrompt(bmStoryConfig, bmStoryRuntime)

-- 2. 构建NPC对话Prompt（进入对话时）
local npcPrompt = StoryPromptBuilder.BuildNPCDialoguePrompt(bmStoryConfig, bmStoryRuntime, "rex")

-- 3. 构建可用抉择列表（玩家请求时）
local choicesPrompt = StoryPromptBuilder.BuildAvailableChoicesPrompt(bmStoryConfig, bmStoryRuntime, "scene_center")

-- 4. 构建循环记忆（AI理解上下文）
local memoryPrompt = StoryPromptBuilder.BuildLoopMemoryPrompt(bmStoryRuntime, 3)

-- 5. 构建状态摘要（UI显示）
local summary = StoryPromptBuilder.BuildStateSummary(bmStoryRuntime)

-- 6. 获取FunctionCall Schema（配置LLM）
local functionSchema = StoryPromptBuilder.BuildFunctionCallSchema()
]]

return StoryPromptBuilder

