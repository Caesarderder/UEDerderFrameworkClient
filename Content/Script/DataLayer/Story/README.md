# Story数据层系统

## 概述

为时间循环叙事游戏设计的精简数据层系统，完美适配LLM架构。

## 核心特性

✅ **数据分层清晰**：配置与运行时分离  
✅ **LLM深度集成**：自动Prompt生成、FunctionCall支持  
✅ **条件驱动**：强大的表达式系统  
✅ **易于扩展**：配置文件驱动  
✅ **符合项目架构**：遵循DM/BM模式  

## 快速开始

```lua
-- 1. 导入模块
local BM_StoryConfig = require("DataLayer.Story.BM_StoryConfig")
local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
local NewgreenConfig = require("Config.NewgreenTownStoryConfig")

-- 2. 初始化
BM_StoryConfig:ImportConfig(NewgreenConfig)
BM_StoryRuntime:InitializeFromConfig(BM_StoryConfig)
BM_StoryRuntime:StartNewLoop()

-- 3. 开始游戏！
```

## 文件结构

```
DataLayer/Story/
├── DM_StoryConfig.lua      # 固定配置数据模块
├── BM_StoryConfig.lua      # 配置业务模块
├── DM_StoryRuntime.lua     # 运行时数据模块
├── BM_StoryRuntime.lua     # 运行时业务模块
└── README.md               # 本文档

GameLayer/Story/
├── Tools/
│   ├── ConditionEvaluator.lua    # 条件评估器
│   └── StoryPromptBuilder.lua    # Prompt构建器
├── README.md                      # 详细文档
├── 架构设计文档.md                 # 架构设计
└── 使用示例.lua                    # 代码示例

Config/
└── NewgreenTownStoryConfig.lua   # 新绿镇配置示例
```

## 数据结构

### 固定配置（DM_StoryConfig）
- 游戏背景
- 场景配置（描述、NPC列表、抉择列表）
- NPC模板（性格、动机、初始状态）
- 抉择模板（条件、效果、结果描述）

### 运行时状态（DM_StoryRuntime）
- 循环状态（次数、当前场景）
- NPC状态（信任度、情绪值、关系值、标记）
- 解锁进度（场景、抉择、事件）
- 选择历史（当前循环、所有循环）

## 核心API

### 配置管理
```lua
-- 导入配置
BM_StoryConfig:ImportConfig(configData)

-- 获取场景
local scene = BM_StoryConfig:GetScene("scene_center")

-- 获取NPC
local npc = BM_StoryConfig:GetNPC("rex")

-- 获取抉择
local choice = BM_StoryConfig:GetChoice("choice_reveal")
```

### 运行时管理
```lua
-- 循环管理
BM_StoryRuntime:StartNewLoop()
local loopCount = BM_StoryRuntime:GetLoopCount()

-- 场景管理
BM_StoryRuntime:ChangeScene("scene_park")
BM_StoryRuntime:UnlockScene("scene_park")

-- NPC状态
BM_StoryRuntime:UpdateNPCStat("rex", "trust", 10)
BM_StoryRuntime:SetNPCTag("rex", "angry", true)

-- 抉择记录
BM_StoryRuntime:RecordChoice("choice_id", "scene_id", "npc_id")

-- 物品管理
BM_StoryRuntime:AddItem("sunflower_seeds", 1)
local count = BM_StoryRuntime:GetItemCount("sunflower_seeds")

-- 标记管理
BM_StoryRuntime:SetGlobalFlag("rexAngry", true)
local value = BM_StoryRuntime:GetGlobalFlag("rexAngry")
```

### 条件评估
```lua
local ConditionEvaluator = require("GameLayer.Story.Tools.ConditionEvaluator")

-- 构建上下文
local context = ConditionEvaluator.BuildContextFromRuntime(BM_StoryRuntime)

-- 评估条件
local result = ConditionEvaluator.Evaluate("loopCount >= 2", context)
```

### Prompt构建
```lua
local StoryPromptBuilder = require("GameLayer.Story.Tools.StoryPromptBuilder")

-- 系统Prompt
local systemPrompt = StoryPromptBuilder.BuildSystemPrompt(
    BM_StoryConfig,
    BM_StoryRuntime
)

-- NPC对话Prompt
local npcPrompt = StoryPromptBuilder.BuildNPCDialoguePrompt(
    BM_StoryConfig,
    BM_StoryRuntime,
    "rex"
)

-- 可用抉择Prompt
local choicesPrompt = StoryPromptBuilder.BuildAvailableChoicesPrompt(
    BM_StoryConfig,
    BM_StoryRuntime,
    "scene_center"
)

-- 循环记忆Prompt
local memoryPrompt = StoryPromptBuilder.BuildLoopMemoryPrompt(
    BM_StoryRuntime,
    3  -- 显示最近3次循环
)
```

## 条件表达式

```lua
-- 循环次数
"loopCount >= 2"

-- NPC状态
"getNPCStat('rex', 'trust') >= 50"
"hasTag('rex', 'angry')"

-- 物品
"hasItem('sunflower_seeds', 1)"

-- 事件
"isEventTriggered('rex_arrested')"

-- 全局标记
"getFlag('rexAngry') == true"

-- 复合条件
"loopCount >= 2 and not hasTag('rex', 'angry')"
```

## 配置示例

见 `Config/NewgreenTownStoryConfig.lua`，包含：
- 完整的游戏背景
- 2个场景配置
- 5个NPC模板
- 8个抉择模板

## 文档

- **详细文档**：`GameLayer/Story/README.md`
- **架构设计**：`GameLayer/Story/架构设计文档.md`
- **代码示例**：`GameLayer/Story/使用示例.lua`

## 示例代码

```lua
-- 运行使用示例
local StoryExample = require("GameLayer.Story.使用示例")

-- 运行所有示例
StoryExample.RunAll()

-- 或运行单个示例
StoryExample.Example1_InitializeGame()
StoryExample.Example10_CompleteGameFlow()
```

## 集成到项目

1. **创建Manager**（待开发）
   ```lua
   -- GameLayer/Story/StoryManager.lua
   -- 封装常用操作，管理配置和运行时实例
   ```

2. **集成到UI**
   - 对话UI组件
   - 抉择选择UI
   - 状态显示UI

3. **集成到LLM系统**
   - 在LlmManager中注册FunctionCall处理器
   - 配置FunctionCall Schema

4. **集成到SaveManager**
   - 保存运行时状态
   - 支持存档/读档

## 性能考虑

- 条件评估使用沙箱环境，安全但有轻微性能开销
- 大量条件评估时建议使用缓存
- Prompt构建按需进行，避免不必要的字符串拼接

## 最佳实践

1. **配置设计**
   - 保持配置简洁，只存关键信息
   - 使用tags标记临时状态
   - 用globalFlags存储全局剧情进度

2. **条件设计**
   - 优先使用简单条件
   - 复杂逻辑拆分为多个小条件
   - 为常用判断封装辅助函数

3. **Prompt构建**
   - 只传递AI需要的信息
   - 对话时聚焦当前NPC和场景
   - 使用循环记忆让AI理解上下文

## 贡献

欢迎提出建议和改进！

## 许可

MIT License

