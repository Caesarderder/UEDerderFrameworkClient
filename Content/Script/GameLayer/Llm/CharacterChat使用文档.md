# CharacterChat 新架构使用文档

## 📋 设计概述

### 新架构三参数设计

```lua
LlmManager:Chat(chatType, typeOptions, otherOptions, onStream, onComplete)
```

| 参数 | 说明 | 对应概念 |
|------|------|---------|
| `chatType` | ChatType类型 | 决定使用哪个 **TypePrompt** 模板 |
| `typeOptions` | **TypeOptions** - 专属参数 | 用于填充 TypePrompt 模板变量 |
| `otherOptions` | **OtherOptions** - 额外参数 | 动态添加额外提示词模块 |

---

## 🎯 TypePrompt（专属提示词）

TypePrompt 定义在 `LlmPromptConfig.lua` 中，以 `character_dialogue` 为例：

### 提示词结构

```lua
character_dialogue = {
    systemPrompt = [[你是 {characterName}...
    
    ## 角色身份
    - NPC ID: {npcId}
    - 所在场景: {currentScene}
    
    ## 记忆规则
    你**不知道时间循环**...
    
    {enemyHistorySummary}  -- 动态注入
    {loopContext}          -- 动态注入
    
    ## unlock_choice工具使用
    ...
    ]],
    tools = {"unlock_choice"},  -- 工具调用定义
    temperature = 0.8,
    maxTokens = 300
}
```

### TypePrompt 包含的内容

1. **角色扮演提示词**: 定义角色的身份、性格、动机
2. **工具调用说明**: 定义何时调用 `unlock_choice` 工具
3. **动态变量槽位**: `{npcId}`, `{sceneId}`, `{enemyHistorySummary}` 等

---

## 🔧 TypeOptions（专属参数）

### CharacterChat 的 TypeOptions

```lua
local typeOptions = {
    -- === 基础属性（必需） ===
    npcId = "npc_joe",              -- NPC ID
    characterName = "老乔",          -- 角色名字
    personality = "友善但谨慎",      -- 性格
    motivation = "保护小镇",         -- 动机
    
    -- === 状态属性 ===
    trust = 50,                      -- 信任度 (0-100)
    emotion = 60,                    -- 情绪值 (0-100)
    relation = 40,                   -- 关系值 (0-100)
    
    -- === 场景属性（影响工具调用） ===
    sceneId = "scene_town_square",   -- 当前场景ID
    
    -- === 动态注入属性（自动生成） ===
    -- 这些属性由 LlmManager 自动处理
    -- enemyHistorySummary: 如果是仇人，会自动添加聊天历史
    -- loopContext: 如果是循环对话，会自动添加循环上下文
}
```

### TypeOptions 的作用

1. **填充 TypePrompt 模板变量**: `{characterName}` → "老乔"
2. **触发特殊逻辑**: 
   - 如果是仇人 (`includePrompts` 包含 "enemy_context")，自动添加聊天历史
   - 如果有场景 (`sceneId`)，AI 可以调用 `unlock_choice` 工具

---

## 🎨 OtherOptions（额外参数）

### OtherOptions 结构

```lua
local otherOptions = {
    -- === 必需参数 ===
    userInput = "玩家的输入文本",
    
    -- === 可选：额外提示词类型列表 ===
    includePrompts = {
        "enemy_context",      -- 仇人上下文（自动触发历史摘要）
        "loop_context",       -- 循环上下文
        "unlock_conditions"   -- 解锁条件说明
    },
    
    -- === 可选：自定义提示词内容 ===
    customPrompts = {
        enemy_context = [[
## 🎭 仇人对话上下文
你是玩家的仇人，你正在策划一场灾难...
        ]],
        
        loop_context = [[
## 🔄 时间循环上下文
当前是第 {loopCount} 次循环...
你记得玩家之前的尝试...
        ]],
        
        unlock_conditions = [[
## 🎯 解锁条件
当玩家问到关键问题时，解锁对应的抉择...
        ]]
    },
    
    -- === 兼容旧架构（可选） ===
    unlockConditions = "...",       -- 如果不使用 includePrompts
    specialInstructions = "...",
    contextInfo = "..."
}
```

### OtherOptions 的作用

1. **提供用户输入**: `userInput`
2. **声明需要的额外提示词**: `includePrompts`
3. **提供自定义提示词内容**: `customPrompts`

---

## 🚀 完整使用示例

### 示例 1: 普通NPC对话

```lua
-- 场景：玩家与普通NPC"老乔"对话
local typeOptions = {
    npcId = "npc_joe",
    characterName = "老乔",
    personality = "友善但谨慎",
    motivation = "保护小镇",
    trust = 50,
    emotion = 60,
    relation = 40,
    sceneId = "scene_town_square"
}

local otherOptions = {
    userInput = "老乔，你知道最近发生了什么吗？",
    
    includePrompts = {
        "unlock_conditions"
    },
    
    customPrompts = {
        unlock_conditions = [[
当玩家问到关键问题时，解锁对应的抉择。
        ]]
    }
}

llmMgr:Chat(
    Consts.ChatType.CHARACTER_DIALOGUE,
    typeOptions,
    otherOptions,
    onStream,
    onComplete
)
```

### 示例 2: 仇人对话（附带历史上下文）

```lua
-- 场景：玩家与仇人对话，需要附带之前的聊天历史和循环上下文
local typeOptions = {
    npcId = "npc_enemy_rex",        -- 仇人ID
    characterName = "雷克斯",
    personality = "狡猾、执着、神经质",
    motivation = "让所有人在灾难中死亡",
    trust = 10,
    emotion = 30,
    relation = -50,
    sceneId = "scene_factory"
}

local otherOptions = {
    userInput = "雷克斯，我知道你在策划什么！",
    
    -- 声明需要附加仇人上下文和循环上下文
    includePrompts = {
        "enemy_context",    -- 🔥 触发自动添加聊天历史
        "loop_context",     -- 🔥 触发循环上下文
        "unlock_conditions"
    },
    
    customPrompts = {
        loop_context = string.format([[
## 🔄 时间循环上下文
当前是第 %d 次循环。
你记得玩家在之前的循环中多次阻止了你的计划。
你开始怀疑为什么会不断重复...
        ]], currentLoopCount),
        
        unlock_conditions = [[
当对话达到以下条件时，解锁场景抉择：
- 玩家触发了关键话题（如灾难计划）
- 你透露了计划的线索
        ]]
    }
}

llmMgr:Chat(
    Consts.ChatType.CHARACTER_DIALOGUE,
    typeOptions,
    otherOptions,
    onStream,
    onComplete
)
```

**处理流程**：

1. `LlmManager` 检测到 `includePrompts` 包含 `"enemy_context"`
2. 自动从 `LlmContextSystem` 获取 `npc_enemy_rex` 的聊天历史
3. 生成历史摘要并添加到 `typeOptions.enemyHistorySummary`
4. 将 `customPrompts.loop_context` 添加到 `typeOptions.loopContext`
5. 最终 Prompt 包含完整的上下文信息

---

## 🔄 数据流详解

### Step 1: UI 层调用

```lua
-- UI_Dialog1.lua
function UI_Dialog1:OnSendInputText(text)
    local typeOptions = {
        npcId = self.currentNpcInfo.id,
        characterName = self.currentNpcInfo.name,
        personality = self.currentNpcInfo.personality,
        motivation = self.currentNpcInfo.motivation,
        trust = self.currentNpcInfo.trust,
        emotion = self.currentNpcInfo.emotion,
        relation = self.currentNpcInfo.relation,
        sceneId = self.currentSceneId
    }
    
    local otherOptions = {
        userInput = text,
        includePrompts = {"unlock_conditions"},
        customPrompts = {
            unlock_conditions = self:GenerateUnlockConditions()
        }
    }
    
    self.llmMgr:Chat(
        Consts.ChatType.CHARACTER_DIALOGUE,
        typeOptions,
        otherOptions,
        onStream,
        onComplete
    )
end
```

### Step 2: LlmManager 预处理

```lua
-- LlmManager.lua: Chat
function LlmManager:Chat(chatType, typeOptions, otherOptions, ...)
    -- === CharacterChat 特殊处理 ===
    if chatType == Consts.ChatType.CHARACTER_DIALOGUE then
        typeOptions = self:_ProcessCharacterTypeOptions(
            typeOptions, 
            otherOptions, 
            contextSystem
        )
    end
    -- ...
end
```

#### _ProcessCharacterTypeOptions 做的事情

1. **复制基础属性**: 保留 `npcId`, `characterName` 等
2. **检查是否是仇人**: 查看 `includePrompts` 是否包含 `"enemy_context"`
3. **如果是仇人**:
   - 从 `ContextSystem` 获取聊天历史
   - 生成摘要并添加到 `typeOptions.enemyHistorySummary`
   - 如果有 `loop_context`，也添加到 `typeOptions.loopContext`
4. **处理场景信息**: 将 `sceneId` 添加到 `typeOptions.currentScene`

### Step 3: BM_LlmPrompt 构建 Prompt

```lua
-- BM_LlmPrompt.lua: BuildPrompt
function BM_LlmPrompt:BuildPrompt(chatType, params)
    local template = self:GetTemplate(chatType)
    local systemPrompt = template.systemPrompt
    
    -- 1. 使用 typeOptions 替换模板变量
    systemPrompt = self:ReplaceVariables(systemPrompt, params.typeArgs)
    -- {characterName} → "老乔"
    -- {npcId} → "npc_joe"
    -- {currentScene} → "scene_town_square"
    -- {enemyHistorySummary} → "## 之前的对话摘要..."
    
    -- 2. 使用 otherOptions 添加额外提示词
    local additionalPrompts = self:BuildNormalArgsPrompt(params.normalArgs)
    systemPrompt = systemPrompt .. "\n\n" .. additionalPrompts
    
    return systemPrompt
end
```

#### BuildNormalArgsPrompt 做的事情

1. **遍历 includePrompts**:
   - 如果包含 `"enemy_context"`，添加 `## 🎭 仇人对话上下文`
   - 如果包含 `"loop_context"`，添加 `## 🔄 时间循环上下文`
   - 如果包含 `"unlock_conditions"`，添加 `## 🎯 当前解锁条件`

2. **从 customPrompts 获取内容**: 将自定义提示词内容拼接到 Prompt

### Step 4: 最终 Prompt 结构

```
你是 老乔（性格：友善但谨慎，动机：保护小镇）。
状态：信任50/情绪60/关系40

## 角色身份
- NPC ID: npc_joe
- 所在场景: scene_town_square

## 记忆规则
你**不知道时间循环**，每次重置失去记忆。

## 对话风格
- 按性格回复，1-3句话
- 可用*动作*
- 根据信任度调整态度

## unlock_choice工具使用
当前场景: scene_town_square
当达到关键节点时调用...

## 🎯 当前解锁条件            ← 来自 otherOptions
当玩家问到关键问题时，解锁对应的抉择。
```

---

## ⚙️ 仇人对话的自动化流程

### 触发条件

```lua
otherOptions.includePrompts = {"enemy_context"}
```

### 自动执行的操作

1. **检测仇人身份**: `LlmManager:_ProcessCharacterTypeOptions` 检测到 `enemy_context`
2. **获取聊天历史**: 从 `ContextSystem:GetCharacterHistory(npcId)` 获取历史
3. **生成摘要**: `LlmManager:_SummarizeHistory` 生成最近5条对话的摘要
4. **注入到 TypeOptions**: 
   ```lua
   typeOptions.enemyHistorySummary = "## 之前的对话摘要\n- 玩家: ...\n- 我: ..."
   ```
5. **填充 TypePrompt**: `{enemyHistorySummary}` 被替换为实际内容

---

## 🛠️ 调试输出

### 当检测到仇人对话时

```
[LlmManager] 🎭 检测到仇人对话: npc_enemy_rex，附加仇人上下文
```

### 当处理场景信息时

```
[LlmManager] 📍 当前场景: scene_factory，AI可以调用 unlock_choice 工具
```

---

## ✅ 关键要点总结

### 1. 三参数分离职责清晰

| 参数 | 职责 | 何时修改 |
|------|------|---------|
| TypePrompt | 定义角色行为和工具使用 | 配置文件，少量修改 |
| TypeOptions | 提供角色数据 | 每次对话，动态数据 |
| OtherOptions | 控制额外提示词 | 每次对话，业务逻辑 |

### 2. 自动化处理

- **仇人上下文**: 自动获取聊天历史并生成摘要
- **循环上下文**: 通过 `customPrompts` 提供
- **场景信息**: 自动注入到 TypePrompt

### 3. 工具调用逻辑

- **基于 sceneId**: AI 知道当前场景，可以调用 `unlock_choice`
- **条件触发**: 通过 `unlockConditions` 告诉 AI 何时调用
- **ID 验证**: AI 调用时会检查 `choiceId` 是否属于当前场景

### 4. 兼容性

- 保持向后兼容旧架构（`typeArgs` / `normalArgs`）
- 支持新架构（`typeOptions` / `otherOptions`）
- 自动转换：`typeOptions` → `typeArgs`

---

## 📚 相关文件

- **`LlmManager.lua`**: 主接口，处理 CharacterChat 特殊逻辑
- **`BM_LlmPrompt.lua`**: Prompt 构建，支持 OtherOptions
- **`LlmPromptConfig.lua`**: TypePrompt 模板定义
- **`LlmContextSystem.lua`**: 聊天历史管理（仇人上下文来源）

---

## 🎉 完成！

现在你可以使用新的 CharacterChat 架构，享受：
- **清晰的参数分离**: TypeOptions 专注数据，OtherOptions 控制提示词
- **自动化仇人对话**: 无需手动管理聊天历史
- **灵活的提示词组合**: 通过 `includePrompts` 动态控制
- **强大的工具调用**: 基于场景的 `unlock_choice` 智能触发

