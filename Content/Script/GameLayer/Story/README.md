# 故事系统使用文档

## 概述

这是一个基于时间循环的叙事游戏系统，完美集成LLM能力，支持：
- 动态NPC状态管理
- 条件驱动的抉择系统
- 循环记忆与历史追踪
- 自动Prompt生成

## 架构概览

```
DataLayer/Story/          # 数据层
├── DM_StoryConfig        # 固定配置（场景、NPC模板、抉择模板）
├── BM_StoryConfig        # 配置业务模块
├── DM_StoryRuntime       # 运行时状态（循环、NPC状态、解锁进度）
└── BM_StoryRuntime       # 运行时业务模块

GameLayer/Story/          # 游戏逻辑层
├── Tools/
│   ├── ConditionEvaluator    # 条件评估器
│   └── StoryPromptBuilder    # Prompt构建器
└── StoryManager              # 故事管理器（待实现）

Config/                   # 配置文件
└── NewgreenTownStoryConfig.lua  # 新绿镇故事配置示例
```

## 数据结构

### 固定数据（DM_StoryConfig）

#### 场景配置
```lua
{
    id = "scene_center",
    name = "新绿镇社区中心",
    description = "多功能社区空间...",
    atmosphere = "轻快爵士乐...",
    npcIds = {"rex", "maggie", "bean"},
    choiceIds = {"choice_reveal", ...}
}
```

#### NPC模板
```lua
{
    id = "rex",
    name = "雷克斯·普鲁特",
    role = "enemy",                 -- enemy/ally/neutral
    personality = "偏执狂天才",
    motivation = "净化世界",
    background = "前同事...",
    dialogueStyle = "挑衅、炫耀...",
    initialStates = {
        trust = 0,       -- [-100, 100]
        emotion = 0,     -- [-100, 100]
        relation = -50   -- [-100, 100]
    },
    tags = {"genius", "lonely"}
}
```

#### 抉择模板
```lua
{
    id = "choice_reveal",
    name = "揭发雷克斯的计划",
    sceneId = "scene_center",
    description = "向镇长揭发...",
    unlockCondition = "loopCount >= 1 or not getFlag('rexAngry')",
    effects = {
        npcStates = {
            rex = {trust = -20, emotion = -30, tags = {"angry"}}
        },
        sceneEvents = {"rex_arrested"},
        globalFlags = {rexAngry = true}
    },
    resultNarrative = "雷克斯被捕..."
}
```

### 运行时数据（DM_StoryRuntime）

#### 循环状态
```lua
{
    loopCount = 1,              -- 当前循环次数
    currentSceneId = "scene_center",
    inDialogue = false,
    currentNpcId = nil
}
```

#### NPC状态
```lua
{
    id = "rex",
    trust = 0,
    emotion = 0,
    relation = -50,
    currentIntent = "阻止玩家",
    tags = {"angry", "suspicious"},
    memories = {},
    currentScene = "scene_center"
}
```

## 使用指南

### 1. 初始化故事系统

```lua
local BM_StoryConfig = require("DataLayer.Story.BM_StoryConfig")
local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
local NewgreenConfig = require("Config.NewgreenTownStoryConfig")

-- 加载配置
BM_StoryConfig:ImportConfig(NewgreenConfig)

-- 初始化运行时
BM_StoryRuntime:InitializeFromConfig(BM_StoryConfig)

-- 开始第一次循环
BM_StoryRuntime:StartNewLoop()
```

### 2. 条件评估

```lua
local ConditionEvaluator = require("GameLayer.Story.Tools.ConditionEvaluator")

-- 构建上下文
local context = ConditionEvaluator.BuildContextFromRuntime(BM_StoryRuntime)

-- 评估条件
local canUnlock = ConditionEvaluator.Evaluate(
    "loopCount >= 2 and getNPCStat('rex', 'trust') > 0",
    context
)
```

#### 常用条件表达式

```lua
-- 循环次数
"loopCount >= 2"

-- NPC状态
"getNPCStat('rex', 'trust') >= 50"
"hasTag('rex', 'angry')"

-- 物品
"hasItem('sunflower_seeds', 1)"

-- 事件和标记
"isEventTriggered('rex_arrested')"
"getFlag('rexAngry') == true"

-- 复合条件
"loopCount >= 2 and not hasTag('rex', 'angry') and getNPCStat('maggie', 'relation') > 30"
```

### 3. Prompt构建

```lua
local StoryPromptBuilder = require("GameLayer.Story.Tools.StoryPromptBuilder")

-- 构建系统Prompt（游戏开始）
local systemPrompt = StoryPromptBuilder.BuildSystemPrompt(
    BM_StoryConfig,
    BM_StoryRuntime
)

-- 构建NPC对话Prompt（进入对话）
local npcPrompt = StoryPromptBuilder.BuildNPCDialoguePrompt(
    BM_StoryConfig,
    BM_StoryRuntime,
    "rex"
)

-- 构建可用抉择Prompt
local choicesPrompt = StoryPromptBuilder.BuildAvailableChoicesPrompt(
    BM_StoryConfig,
    BM_StoryRuntime,
    "scene_center"
)

-- 构建循环记忆Prompt
local memoryPrompt = StoryPromptBuilder.BuildLoopMemoryPrompt(
    BM_StoryRuntime,
    3  -- 显示最近3次循环
)
```

### 4. 执行抉择

```lua
-- 玩家做出选择
local choiceId = "choice_reveal_plan"
local choice = BM_StoryConfig:GetChoice(choiceId)

-- 记录选择
BM_StoryRuntime:RecordChoice(
    choiceId,
    BM_StoryRuntime:GetCurrentSceneId(),
    "rex"
)

-- 应用效果
if choice.effects then
    -- 更新NPC状态
    if choice.effects.npcStates then
        for npcId, changes in pairs(choice.effects.npcStates) do
            if changes.trust then
                BM_StoryRuntime:UpdateNPCStat(npcId, "trust", changes.trust)
            end
            if changes.emotion then
                BM_StoryRuntime:UpdateNPCStat(npcId, "emotion", changes.emotion)
            end
            if changes.tags then
                for _, tag in ipairs(changes.tags) do
                    BM_StoryRuntime:SetNPCTag(npcId, tag, true)
                end
            end
        end
    end
    
    -- 触发事件
    if choice.effects.sceneEvents then
        for _, eventId in ipairs(choice.effects.sceneEvents) do
            BM_StoryRuntime:TriggerEvent(eventId)
        end
    end
    
    -- 设置全局标记
    if choice.effects.globalFlags then
        for flagName, value in pairs(choice.effects.globalFlags) do
            BM_StoryRuntime:SetGlobalFlag(flagName, value)
        end
    end
end
```

### 5. 循环重置

```lua
-- 玩家死亡，进入下一次循环
BM_StoryRuntime:StartNewLoop()

-- 此时：
-- - loopCount +1
-- - NPC状态重置为初始值
-- - 当前循环的选择历史被保存
-- - 触发事件清空
```

## LLM集成

### FunctionCall配置

```lua
local functionSchema = StoryPromptBuilder.BuildFunctionCallSchema()

-- 返回的Schema包含：
-- 1. make_choice: 做出抉择
-- 2. update_npc_state: 更新NPC状态（AI自动调用）
-- 3. trigger_event: 触发事件
```

### 处理FunctionCall

```lua
-- AI调用 make_choice
function OnMakeChoice(choiceId, reason)
    print("AI选择:", choiceId, "理由:", reason)
    -- 执行抉择逻辑...
end

-- AI调用 update_npc_state
function OnUpdateNPCState(npcId, statChanges, addTags, removeTags)
    if statChanges then
        for statName, delta in pairs(statChanges) do
            BM_StoryRuntime:UpdateNPCStat(npcId, statName, delta)
        end
    end
    
    if addTags then
        for _, tag in ipairs(addTags) do
            BM_StoryRuntime:SetNPCTag(npcId, tag, true)
        end
    end
    
    if removeTags then
        for _, tag in ipairs(removeTags) do
            BM_StoryRuntime:SetNPCTag(npcId, tag, false)
        end
    end
end

-- AI调用 trigger_event
function OnTriggerEvent(eventId)
    BM_StoryRuntime:TriggerEvent(eventId)
end
```

## 配置新故事

### 创建配置文件

参考 `Content/Script/Config/NewgreenTownStoryConfig.lua`

```lua
return {
    background = {
        text = "你的故事背景...",
        theme = "时间循环",
        mainConflict = "主要冲突"
    },
    
    scenes = {
        {id = "scene_1", name = "场景名", ...}
    },
    
    npcs = {
        {id = "npc_1", name = "NPC名", ...}
    },
    
    choices = {
        {id = "choice_1", name = "抉择名", ...}
    }
}
```

### 条件表达式设计原则

1. **简单明确**：`loopCount >= 2`
2. **可组合**：`loopCount >= 2 and not hasTag('rex', 'angry')`
3. **语义清晰**：使用辅助函数如 `hasItem()`, `hasTag()`
4. **避免复杂计算**：条件只做判断，不做复杂逻辑

### 状态值设计

- **trust**（信任度）：[-100, 100]
  - < -50: 完全不信任
  - -50 ~ 0: 不太信任
  - 0 ~ 50: 略有信任
  - > 50: 高度信任

- **emotion**（情绪值）：[-100, 100]
  - < -50: 愤怒/悲伤
  - -50 ~ 0: 略微消极
  - 0 ~ 50: 平静/略微愉悦
  - > 50: 非常开心

- **relation**（关系值）：[-100, 100]
  - < -50: 敌对
  - -50 ~ 0: 疏远
  - 0 ~ 50: 友好
  - > 50: 亲密

## 最佳实践

### 1. 数据设计
- 保持配置简洁，只存关键信息
- 使用tags标记临时状态
- 用globalFlags存储全局剧情进度

### 2. 条件设计
- 优先使用简单条件
- 复杂逻辑拆分为多个小条件
- 为常用判断封装辅助函数

### 3. Prompt构建
- 只传递AI需要的信息
- 对话时聚焦当前NPC和场景
- 使用循环记忆让AI理解上下文

### 4. 性能优化
- 大量条件评估时使用缓存
- 避免在条件中调用复杂函数
- 定期清理不需要的历史数据

## 调试

```lua
-- 打印配置信息
BM_StoryConfig:DebugPrint()

-- 打印运行时状态
BM_StoryRuntime:DebugPrint()

-- 查看NPC状态
local npcState = BM_StoryRuntime:GetNPCState("rex")
print(require("rapidjson").encode(npcState))

-- 测试条件
local context = ConditionEvaluator.BuildContextFromRuntime(BM_StoryRuntime)
local result = ConditionEvaluator.Evaluate("loopCount >= 2", context)
print("条件结果:", result)
```

## 扩展

### 添加新的辅助函数

在 `ConditionEvaluator.CreateSafeEnv` 中添加：

```lua
env.customFunction = function(param)
    -- 你的逻辑
    return result
end
```

### 添加新的FunctionCall

在 `StoryPromptBuilder.BuildFunctionCallSchema` 中添加：

```lua
{
    name = "your_function",
    description = "功能描述",
    parameters = {...}
}
```

## 常见问题

**Q: 条件表达式不生效？**
A: 检查变量名是否正确，使用 `ConditionEvaluator.BuildContextFromRuntime` 查看可用变量。

**Q: NPC状态重置不正确？**
A: 确保在 `InitNPCState` 时保存了 `initialXXX` 字段。

**Q: 循环记忆太长影响性能？**
A: 使用 `BuildLoopMemoryPrompt` 的 `maxLoops` 参数限制显示数量。

**Q: 如何保存游戏进度？**
A: 可以使用 `BM_StoryRuntime` 的 dataModule 直接序列化存储，或集成到现有的SaveManager。

