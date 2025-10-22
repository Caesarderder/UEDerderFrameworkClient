---条件评估器
---用于评估抉择的解锁条件、事件触发条件等
---支持表达式求值和复杂逻辑判断
---@class ConditionEvaluator
local ConditionEvaluator = {}

---评估条件表达式
---@param conditionStr string 条件表达式字符串
---@param context table 上下文数据（提供变量值）
---@return boolean 是否满足条件
function ConditionEvaluator.Evaluate(conditionStr, context)
    if not conditionStr or conditionStr == "" then
        return true -- 空条件视为总是满足
    end
    
    -- 创建安全的求值环境
    local env = ConditionEvaluator.CreateSafeEnv(context)
    
    -- 构建可执行的Lua代码
    local code = "return " .. conditionStr
    
    -- 安全执行
    local func, err = load(code, "condition", "t", env)
    if not func then
        print("[ConditionEvaluator] 条件语法错误:", conditionStr)
        print("  错误信息:", err)
        return false
    end
    
    local success, result = pcall(func)
    if not success then
        print("[ConditionEvaluator] 条件执行错误:", conditionStr)
        print("  错误信息:", result)
        return false
    end
    
    return result == true
end

---创建安全的求值环境
---@param context table 上下文数据
---@return table 环境表
function ConditionEvaluator.CreateSafeEnv(context)
    local env = {
        -- 基础运算符和逻辑
        math = math,
        string = string,
        table = table,
        
        -- 自定义辅助函数
        hasItem = function(itemId, count)
            return (context.inventory[itemId] or 0) >= count
        end,
        
        hasTag = function(npcId, tag)
            local npcState = context.npcStates[npcId]
            if not npcState then return false end
            for _, t in ipairs(npcState.tags or {}) do
                if t == tag then return true end
            end
            return false
        end,
        
        getNPCStat = function(npcId, statName)
            local npcState = context.npcStates[npcId]
            if not npcState then return 0 end
            return npcState[statName] or 0
        end,
        
        isEventTriggered = function(eventId)
            return context.triggeredEvents[eventId] == true
        end,
        
        getFlag = function(flagName)
            return context.globalFlags[flagName]
        end,
        
        isSceneUnlocked = function(sceneId)
            return context.unlockedScenes[sceneId] == true
        end,
        
        isChoiceUnlocked = function(choiceId)
            return context.unlockedChoices[choiceId] == true
        end,
    }
    
    -- 添加上下文的直接变量
    -- loopCount, currentSceneId 等可以直接访问
    for key, value in pairs(context) do
        if type(value) ~= "table" or key == "loopCount" then
            env[key] = value
        end
    end
    
    return env
end

---批量评估多个条件（AND关系）
---@param conditions table 条件字符串数组
---@param context table 上下文数据
---@return boolean 是否全部满足
function ConditionEvaluator.EvaluateAll(conditions, context)
    for _, condition in ipairs(conditions) do
        if not ConditionEvaluator.Evaluate(condition, context) then
            return false
        end
    end
    return true
end

---批量评估多个条件（OR关系）
---@param conditions table 条件字符串数组
---@param context table 上下文数据
---@return boolean 是否有任一满足
function ConditionEvaluator.EvaluateAny(conditions, context)
    for _, condition in ipairs(conditions) do
        if ConditionEvaluator.Evaluate(condition, context) then
            return true
        end
    end
    return false
end

---从BM模块构建评估上下文
---@param bmRuntime table BM_StoryRuntime实例
---@return table 上下文数据
function ConditionEvaluator.BuildContextFromRuntime(bmRuntime)
    local dm = bmRuntime.dataModule
    return {
        -- 基础状态
        loopCount = dm.loopCount,
        currentSceneId = dm.currentSceneId,
        
        -- 解锁状态
        unlockedScenes = dm.unlockedScenes,
        unlockedChoices = dm.unlockedChoices,
        
        -- NPC状态
        npcStates = dm.npcStates,
        
        -- 物品和标记
        inventory = dm.inventory,
        globalFlags = dm.globalFlags,
        
        -- 事件
        triggeredEvents = dm.triggeredEvents,
    }
end

--[[
使用示例：

-- 1. 简单条件
local condition1 = "loopCount >= 2"
local result1 = ConditionEvaluator.Evaluate(condition1, context)

-- 2. 复杂条件
local condition2 = "loopCount >= 1 and getNPCStat('rex', 'trust') < 0"
local result2 = ConditionEvaluator.Evaluate(condition2, context)

-- 3. 使用辅助函数
local condition3 = "hasItem('sunflower_seeds', 1) and hasTag('rex', 'angry')"
local result3 = ConditionEvaluator.Evaluate(condition3, context)

-- 4. 从运行时构建上下文
local context = ConditionEvaluator.BuildContextFromRuntime(bmStoryRuntime)
local result = ConditionEvaluator.Evaluate("loopCount >= 2", context)

-- 5. 常见条件表达式示例：
-- "loopCount >= 1"                                 -- 循环次数 >= 1
-- "loopCount >= 2 and not hasTag('rex', 'angry')" -- 循环>=2且雷克斯未愤怒
-- "hasItem('sunflower_seeds', 1)"                  -- 拥有瓜子
-- "getNPCStat('rex', 'trust') >= 50"              -- 雷克斯信任度>=50
-- "isEventTriggered('rex_arrested')"              -- 事件已触发
-- "getFlag('rexAngry') == true"                   -- 全局标记为true
]]

return ConditionEvaluator

