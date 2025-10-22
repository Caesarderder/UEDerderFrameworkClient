# LLM 对话架构重构说明

## 📋 新架构概述

### 核心改变

**旧架构**:
```lua
llmMgr:Chat(chatType, params, onStream, onComplete)
-- params 混合了所有参数
```

**新架构**:
```lua
llmMgr:Chat(chatType, typeArgs, normalArgs, onStream, onComplete)
-- typeArgs: ChatType 专属参数
-- normalArgs: 通用参数
```

---

## 🎯 参数分类

### 1. typeArgs (ChatType专属参数)

针对不同的 `ChatType`，传入该类型特有的参数：

#### CHARACTER_DIALOGUE (角色对话)
```lua
typeArgs = {
    characterName = "老乔",       -- 角色名称
    personality = "友善但谨慎",   -- 性格
    motivation = "保护小镇",      -- 动机
    dialogueStyle = "朴实",       -- 对话风格
    trust = 50,                    -- 信任度
    emotion = 60,                  -- 情绪值
    relation = 40                  -- 关系值
}
```

#### GENERAL_CHAT (通用对话)
```lua
typeArgs = {}  -- 通用对话无专属参数
```

### 2. normalArgs (通用参数)

所有 `ChatType` 都可以使用的参数：

```lua
normalArgs = {
    userInput = "玩家的输入文本",          -- 必需：用户输入
    
    unlockConditions = [[                   -- 可选：解锁条件提示
        当对话达到以下条件时，应该解锁场景抉择：
        - 玩家问到了关键问题
        - 你透露了重要信息
    ]],
    
    specialInstructions = "特殊指示...",   -- 可选：特殊指示
    contextInfo = "当前上下文信息..."      -- 可选：上下文信息
}
```

---

## 🔄 完整数据流

### Step 1: UI 层调用

```lua
-- UI_Dialog1.lua: OnSendInputText
local typeArgs = {
    characterName = self.currentNpcInfo.name,
    personality = self.currentNpcInfo.personality,
    -- ... 其他角色属性
}

local normalArgs = {
    userInput = text,
    unlockConditions = [[解锁条件说明...]]
}

self.llmMgr:Chat(
    Consts.ChatType.CHARACTER_DIALOGUE, 
    typeArgs,        -- 角色专属参数
    normalArgs,      -- 通用参数
    onStream, 
    onComplete
)
```

### Step 2: LlmManager 合并参数

```lua
-- LlmManager.lua: Chat
function LlmManager:Chat(chatType, typeArgs, normalArgs, onStream, onComplete)
    local params = {
        typeArgs = typeArgs,
        normalArgs = normalArgs
    }
    
    reactSystem:ProcessStream(chatType, params, onStream, onComplete)
end
```

### Step 3: BM_LlmPrompt 构建 Prompt

```lua
-- BM_LlmPrompt.lua: BuildPrompt
function BM_LlmPrompt:BuildPrompt(chatType, params)
    local template = self:GetTemplate(chatType)
    local systemPrompt = template.systemPrompt
    
    -- 1. 使用 typeArgs 替换模板变量
    local typeArgs = params.typeArgs or {}
    systemPrompt = self:ReplaceVariables(systemPrompt, typeArgs)
    -- 例如: {characterName} → "老乔"
    
    -- 2. 使用 normalArgs 添加通用提示
    local normalArgs = params.normalArgs or {}
    if next(normalArgs) ~= nil then
        local additionalPrompts = self:BuildNormalArgsPrompt(normalArgs)
        systemPrompt = systemPrompt .. "\n\n" .. additionalPrompts
    end
    
    return systemPrompt
end
```

### Step 4: 最终 Prompt 结构

```
你是游戏中的角色 老乔。

## 角色设定
- 性格：友善但谨慎
- 动机：保护小镇
...

## 当前状态
- 信任度：50/100
- 情绪值：60/100
...

## 🔧 工具使用：unlock_choice
...

## 🎯 当前解锁条件          ← normalArgs.unlockConditions
当对话达到以下条件时，应该解锁场景抉择：
- 玩家问到了关键问题
- 你透露了重要信息
```

---

## 🐛 调试输出说明

### 当 AI 调用 unlock_choice 工具时

你会看到以下调试输出：

```
======================================================================
[Tool] 🔧 unlock_choice 被调用: choice_investigate_rex
======================================================================
[Tool] ✅ 抉择已解锁: 调查雷克斯的活动
[Tool]    抉择ID: choice_investigate_rex
[Tool]    解锁原因: 玩家触发了关键话题
[Tool] 检查UI实例: Instance=table: 0x...
[Tool] ✅ UI实例存在，调用刷新方法...
[Tool] ✅ UI抉择按钮已刷新
======================================================================

======================================================================
[UI_Dialog] 🔄 RefreshSceneDecisionOnly 被调用
======================================================================
[UI_Dialog] 当前场景ID: scene_town_square
[UI_Dialog] ✅ 找到场景配置: 小镇广场
[UI_Dialog] 开始刷新场景抉择按钮...
[UI_Dialog] 已清空场景抉择按钮
[UI_Dialog] 场景配置中共有 3 个抉择
  🔒 抉择未解锁（跳过）: choice_talk_to_mayor
  [1] ✓ 已创建抉择按钮: 调查雷克斯的活动 (choice_investigate_rex)
  🔒 抉择未解锁（跳过）: choice_leave_town
[UI_Dialog] ✅ 场景抉择按钮刷新完成
    配置抉择总数: 3
    已解锁抉择: 1
    已创建按钮: 1
======================================================================
```

### 如果 UI 没有刷新，检查这些输出

#### ❌ 场景 1: UI 实例为 nil
```
[Tool] ❌ UI_Dialog1.Instance 为 nil，无法刷新UI
```
**原因**: UI 还未初始化  
**解决**: 确保 UI_Dialog1:Construct() 已执行

#### ❌ 场景 2: 当前场景ID为空
```
[UI_Dialog] ❌ 当前场景ID为空，无法刷新
```
**原因**: 还没有进入场景  
**解决**: 调用 `SceneStateManager.EnterScene(sceneId)` 进入场景

#### ❌ 场景 3: 找不到场景配置
```
[UI_Dialog] ❌ 找不到场景配置: scene_xxx
```
**原因**: 场景配置不存在  
**解决**: 检查配置文件中是否有该场景ID

#### ❌ 场景 4: 抉择未解锁
```
  🔒 抉择未解锁（跳过）: choice_xxx
```
**原因**: 抉择ID 不匹配，或运行时状态未更新  
**解决**: 检查 AI 调用的 `choiceId` 是否与配置文件中的ID一致

---

## 🎮 实战示例

### 完整对话流程

```lua
-- 1. 进入场景
SceneStateManager.EnterScene("scene_town_square")

-- 2. 点击NPC
UI_Dialog1:OnClickNPCButton("npc_joe", "老乔")

-- 3. 发送消息
玩家输入: "老乔，你有没有注意到雷克斯的异常行为？"

-- 4. AI 处理
typeArgs = {
    characterName = "老乔",
    personality = "友善但谨慎",
    trust = 50,
    ...
}

normalArgs = {
    userInput = "老乔，你有没有注意到雷克斯的异常行为？",
    unlockConditions = [[
        当对话达到以下条件时，应该解锁场景抉择：
        - 玩家问到了关键问题（如灾难、仇人的计划）
        - 你透露了重要信息或线索
    ]]
}

-- 5. AI 回复 + 调用工具
AI回复: "嗯...你也注意到了？*犹豫* 确实有点奇怪..."
AI调用: unlock_choice({
    choiceId = "choice_investigate_rex",
    reason = "玩家触发了关于雷克斯的调查话题"
})

-- 6. UI 自动刷新
→ 【新抉择按钮出现】"调查雷克斯的活动" ✨
```

---

## 📌 关键要点

### 1. 参数清晰分离
- ✅ `typeArgs`: 仅包含该 ChatType 的专属数据
- ✅ `normalArgs`: 包含通用的提示和用户输入

### 2. Prompt 构建顺序
1. 使用 `typeArgs` 替换模板中的变量
2. 使用 `normalArgs` 追加额外的通用提示

### 3. 工具调用流程
1. AI 根据 Prompt 决定是否调用工具
2. 工具执行 → 更新游戏状态
3. 工具通知 UI → UI 刷新按钮

### 4. 调试最佳实践
- 查看完整的调试输出日志
- 确认 UI 实例存在
- 确认场景ID正确
- 确认抉择ID匹配

---

## ✅ 完成清单

- [x] 重构 `LlmManager:Chat` 接口
- [x] 重构 `BM_LlmPrompt:BuildPrompt` 方法
- [x] 添加 `BuildNormalArgsPrompt` 方法
- [x] 更新 `LlmReActSystem` 处理 `normalArgs`
- [x] 更新 `UI_Dialog1:OnSendInputText` 使用新架构
- [x] 增强 `unlock_choice` 工具的调试输出
- [x] 增强 `RefreshSceneDecisionOnly` 的调试输出

---

## 🚀 下一步

如果 UI 仍然没有刷新按钮，请：

1. 运行游戏
2. 查看完整的日志输出
3. 找到 `[Tool] 🔧 unlock_choice 被调用` 的部分
4. 根据调试输出定位问题

有任何问题，欢迎根据日志输出进一步调试！🎉

