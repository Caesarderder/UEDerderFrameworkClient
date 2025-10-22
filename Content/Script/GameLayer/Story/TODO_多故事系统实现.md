# 多故事系统实现 - TODO与核心要点

> **文档目的**：作为开发多故事系统的核心上下文文档，供AI辅助编程时参考。
> **创建日期**：2025-10-19  
> **架构基础**：已完成单故事系统（DM/BM_StoryConfig + DM/BM_StoryRuntime）

---

## 📌 项目背景

### 当前状态
- ✅ 已实现单故事数据层（DM/BM_StoryConfig, DM/BM_StoryRuntime）
- ✅ 已实现条件评估器（ConditionEvaluator）
- ✅ 已实现Prompt构建器（StoryPromptBuilder）
- ✅ 已有完整的新绿镇故事配置示例

### 目标
实现多故事配置管理系统，支持：
1. 玩家可以选择不同故事体验
2. 同一时间只运行一个故事（单活跃故事）
3. 故事切换时重新初始化运行时
4. 所有交互通过FunctionCall实现（无关键词匹配）
5. 场景图导航（条件解锁的场景流转）
6. **暂不实现存档系统**，只管理当前游戏进度

---

## 🎯 核心设计原则

### 1. 单活跃故事模式
- 同一时间只有一个故事在运行
- 切换故事 = 清空Runtime + 加载新Config + 初始化Runtime
- 不需要保存旧故事的状态

### 2. FunctionCall驱动交互
- **完全替代关键词匹配**
- 所有玩家意图通过AI选择FunctionCall表达
- 后端只需实现FunctionCall处理器

### 3. 配置驱动开发
- 新故事只需添加配置文件
- 场景关系在配置中声明
- 条件表达式复用现有ConditionEvaluator

### 4. 复用现有架构
- 保持现有单故事系统不变
- 多故事系统作为上层封装
- 向后兼容

---

## 📂 目标文件结构

```
DataLayer/
├── Story/                          [已有] 单故事数据层
│   ├── DM_StoryConfig.lua          ✅ 保持不变
│   ├── BM_StoryConfig.lua          ✅ 保持不变
│   ├── DM_StoryRuntime.lua         🔧 需扩展（添加字段）
│   └── BM_StoryRuntime.lua         🔧 需扩展（添加方法）
│
└── StoryLibrary/                   [新增] 故事库数据层
    ├── DM_StoryLibrary.lua         ⭐ TODO
    └── BM_StoryLibrary.lua         ⭐ TODO

GameLayer/
├── Story/                          [已有] 单故事逻辑层
│   ├── Tools/
│   │   ├── ConditionEvaluator.lua  ✅ 保持不变
│   │   └── StoryPromptBuilder.lua  🔧 需扩展（添加FC）
│   └── ...
│
└── StoryLibrary/                   [新增] 多故事逻辑层
    ├── StoryLibraryManager.lua     ⭐ TODO
    ├── SceneFlowManager.lua        ⭐ TODO
    └── GameFunctionCallHandler.lua ⭐ TODO

Config/
├── StoryLibraryConfig.lua          ⭐ TODO（故事库配置）
├── NewgreenTownStoryConfig.lua     🔧 需扩展（添加场景连接）
└── CompanyMysteryStoryConfig.lua   ⭐ TODO（第二个故事示例）
```

**图例**：
- ✅ 已完成，保持不变
- 🔧 已存在，需要扩展
- ⭐ 需要新建

---

## 📋 TODO列表（按阶段）

---

## 🔷 Phase 1：故事库基础（3-4天）

**目标**：支持多故事注册、查询和切换

### ✅ TODO 1.1：创建 DM_StoryLibrary.lua

**位置**：`Content/Script/DataLayer/StoryLibrary/DM_StoryLibrary.lua`

**数据结构**：
```lua
DM_StoryLibrary.Fields = {
    -- 已注册的故事列表
    stories = {},              -- table<number, StoryMeta>
    
    -- 当前激活的故事ID
    currentStoryId = "",       -- string
}

-- StoryMeta结构
StoryMeta = {
    id = "story_newgreen",                     -- 故事唯一ID
    title = "新绿镇时间循环",                   -- 显示标题
    description = "喜剧风格的时间循环故事...",  -- 简介
    tags = {"时间循环", "喜剧"},                -- 标签数组
    difficulty = "中等",                        -- 难度
    estimatedTime = "2-3小时",                  -- 预计时长
    configPath = "Config.NewgreenTownStoryConfig",  -- 配置模块路径
    thumbnail = "",                             -- 封面图路径（可选）
}
```

**核心要点**：
- 继承`DataModule`
- `stories`是数组，按顺序存储
- `currentStoryId`用于跟踪当前激活的故事

---

### ✅ TODO 1.2：创建 BM_StoryLibrary.lua

**位置**：`Content/Script/DataLayer/StoryLibrary/BM_StoryLibrary.lua`

**必需方法**：

```lua
-- 注册故事（初始化时调用）
function BM_StoryLibrary:RegisterStory(storyMeta)
    -- 添加到stories数组
    -- 检查ID唯一性
end

-- 获取所有故事列表
function BM_StoryLibrary:GetAllStories()
    -- 返回 self.dataModule.stories
    -- 返回类型: table<number, StoryMeta>
end

-- 根据ID获取故事元信息
function BM_StoryLibrary:GetStoryMeta(storyId)
    -- 遍历stories，查找匹配ID
    -- 返回类型: StoryMeta | nil
end

-- 获取当前激活的故事ID
function BM_StoryLibrary:GetCurrentStoryId()
    -- 返回 self.dataModule.currentStoryId
end

-- 设置当前激活的故事ID
function BM_StoryLibrary:SetCurrentStoryId(storyId)
    -- 设置 self.dataModule.currentStoryId
end

-- 批量注册故事（从配置加载）
function BM_StoryLibrary:ImportStories(storiesConfig)
    -- 遍历配置，逐个调用RegisterStory
end
```

**核心要点**：
- 继承`BusinessModule`
- `RegisterStory`要检查ID唯一性
- `GetStoryMeta`找不到返回nil

---

### ✅ TODO 1.3：创建 StoryLibraryConfig.lua

**位置**：`Content/Script/Config/StoryLibraryConfig.lua`

**配置格式**：
```lua
return {
    stories = {
        -- 故事1：新绿镇
        {
            id = "story_newgreen",
            title = "新绿镇时间循环",
            description = "在新绿镇上，你和宿敌雷克斯陷入时间循环。你必须阻止他的荒诞灾难计划，并最终化解心结。",
            tags = {"时间循环", "喜剧", "推理"},
            difficulty = "中等",
            estimatedTime = "2-3小时",
            configPath = "Config.NewgreenTownStoryConfig",
            thumbnail = ""
        },
        
        -- 故事2：公司推理（TODO Phase 4创建）
        {
            id = "story_company",
            title = "公司推理事件",
            description = "公司里发生了离奇事件，你需要调查真相。",
            tags = {"推理", "悬疑"},
            difficulty = "困难",
            estimatedTime = "3-4小时",
            configPath = "Config.CompanyMysteryStoryConfig",
            thumbnail = ""
        }
    }
}
```

**核心要点**：
- 这是纯Lua table，不是模块
- `configPath`使用点号路径（用于require）
- 至少注册2个故事（新绿镇 + 一个占位故事）

---

### ✅ TODO 1.4：创建 StoryLibraryManager.lua

**位置**：`Content/Script/GameLayer/StoryLibrary/StoryLibraryManager.lua`

**职责**：
- 管理故事库和当前故事的高级操作
- 封装故事切换的完整流程

**必需方法**：

```lua
-- 初始化故事库（游戏启动时调用一次）
function StoryLibraryManager:Initialize()
    -- 加载StoryLibraryConfig
    -- 调用BM_StoryLibrary:ImportStories()
end

-- 加载并激活指定故事
function StoryLibraryManager:LoadStory(storyId)
    -- 1. 获取故事元信息
    -- 2. require(storyMeta.configPath)
    -- 3. 清空BM_StoryRuntime（如果有旧故事）
    -- 4. 调用BM_StoryConfig:ImportConfig(storyConfig)
    -- 5. 调用BM_StoryRuntime:InitializeFromConfig(BM_StoryConfig)
    -- 6. 设置BM_StoryRuntime.dataModule.currentStoryId = storyId
    -- 7. 调用BM_StoryLibrary:SetCurrentStoryId(storyId)
    -- 8. 调用BM_StoryRuntime:StartNewLoop()
    -- 返回: {success = true} 或 {success = false, error = "..."}
end

-- 获取当前故事信息
function StoryLibraryManager:GetCurrentStory()
    -- 获取currentStoryId
    -- 返回故事元信息
end

-- 重新开始当前故事
function StoryLibraryManager:RestartCurrentStory()
    -- 获取currentStoryId
    -- 调用LoadStory(currentStoryId)
end
```

**核心要点**：
- `LoadStory`是核心方法，封装了完整的故事切换流程
- 切换故事时要清空旧的Runtime（调用`BM_StoryRuntime:Clear()`，如果没有这个方法需要添加）
- 错误处理：找不到故事、配置加载失败等

---

### ✅ TODO 1.5：扩展 BM_StoryRuntime（添加Clear方法）

**位置**：`Content/Script/DataLayer/Story/BM_StoryRuntime.lua`

**新增方法**：
```lua
-- 清空所有运行时状态（用于切换故事）
function BM_StoryRuntime:Clear()
    self.dataModule.loopCount = 0
    self.dataModule.currentSceneId = ""
    self.dataModule.currentStoryId = ""  -- 新增字段
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
    self.dataModule.sceneHistory = {}  -- 新增字段
    self.dataModule.availableScenes = {}  -- 新增字段
    self.dataModule.startTime = 0
    self.dataModule.currentLoopStartTime = 0
    self.dataModule.totalPlayTime = 0
end
```

---

### ✅ TODO 1.6：扩展 DM_StoryRuntime（添加新字段）

**位置**：`Content/Script/DataLayer/Story/DM_StoryRuntime.lua`

**新增字段**：
```lua
DM_StoryRuntime.Fields = {
    -- 现有字段...
    
    -- 新增：当前故事标识
    currentStoryId = "",           -- string
    
    -- 新增：场景流转相关
    sceneHistory = {},             -- table<number, string> 场景访问历史
    availableScenes = {},          -- table<number, string> 当前可到达的场景ID列表
}
```

**更新注解**：
```lua
---@class DM_StoryRuntime : DataModule
---@field currentStoryId string 当前激活的故事ID
---@field sceneHistory table 场景访问历史
---@field availableScenes table 当前可到达的场景列表
```

---

### 📝 Phase 1 完成标准

- [ ] 可以注册多个故事
- [ ] 可以查询故事列表
- [ ] 可以切换故事（LoadStory成功执行）
- [ ] 切换后Runtime被正确清空和初始化
- [ ] 编写简单测试脚本验证

---

## 🔷 Phase 2：FunctionCall系统（4-5天）

**目标**：通过FunctionCall实现所有游戏交互

### ✅ TODO 2.1：扩展 StoryPromptBuilder（添加FunctionCall定义）

**位置**：`Content/Script/GameLayer/Story/Tools/StoryPromptBuilder.lua`

**扩展 BuildFunctionCallSchema 方法**：

在现有的3个FunctionCall基础上，新增10个：

```lua
function StoryPromptBuilder.BuildFunctionCallSchema()
    return {
        -- ========== 已有的（保留）==========
        {
            name = "make_choice",
            description = "做出一个关键抉择",
            parameters = { ... }  -- 保持不变
        },
        {
            name = "update_npc_state",
            description = "更新NPC状态（AI自动调用）",
            parameters = { ... }  -- 保持不变
        },
        {
            name = "trigger_event",
            description = "触发特定事件",
            parameters = { ... }  -- 保持不变
        },
        
        -- ========== 新增：游戏管理类 ==========
        {
            name = "list_available_stories",
            description = "查看所有可玩的故事列表",
            parameters = {
                type = "object",
                properties = {}
            }
        },
        {
            name = "switch_story",
            description = "切换到另一个故事（会结束当前游戏）",
            parameters = {
                type = "object",
                properties = {
                    storyId = {
                        type = "string",
                        description = "目标故事ID，如 'story_newgreen'"
                    }
                },
                required = {"storyId"}
            }
        },
        {
            name = "restart_current_story",
            description = "重新开始当前故事（回到第1次循环）",
            parameters = {
                type = "object",
                properties = {}
            }
        },
        {
            name = "get_game_status",
            description = "查看当前游戏进度、循环次数、场景等信息",
            parameters = {
                type = "object",
                properties = {}
            }
        },
        {
            name = "quit_game",
            description = "结束当前游戏",
            parameters = {
                type = "object",
                properties = {}
            }
        },
        
        -- ========== 新增：场景流转类 ==========
        {
            name = "list_available_scenes",
            description = "查看当前可以前往的场景列表（包括已解锁和未解锁的）",
            parameters = {
                type = "object",
                properties = {}
            }
        },
        {
            name = "switch_scene",
            description = "切换到指定场景",
            parameters = {
                type = "object",
                properties = {
                    sceneId = {
                        type = "string",
                        description = "目标场景ID"
                    }
                },
                required = {"sceneId"}
            }
        },
        {
            name = "suggest_next_scene",
            description = "AI根据当前进度建议下一个应该去的场景",
            parameters = {
                type = "object",
                properties = {}
            }
        },
        
        -- ========== 新增：循环管理类 ==========
        {
            name = "start_new_loop",
            description = "玩家死亡或主动重置，开始新的一次循环",
            parameters = {
                type = "object",
                properties = {
                    reason = {
                        type = "string",
                        description = "重置原因，如'灾难发生'、'玩家主动重置'"
                    }
                },
                required = {"reason"}
            }
        },
        {
            name = "get_loop_history",
            description = "查看之前循环中的选择历史",
            parameters = {
                type = "object",
                properties = {
                    loopCount = {
                        type = "number",
                        description = "查看第几次循环的历史，不传则查看所有循环"
                    }
                }
            }
        }
    }
end
```

**核心要点**：
- 10个新FunctionCall分为3类：游戏管理(5)、场景流转(3)、循环管理(2)
- parameters遵循OpenAI FunctionCall格式
- 每个都有清晰的description

---

### ✅ TODO 2.2：创建 GameFunctionCallHandler.lua

**位置**：`Content/Script/GameLayer/StoryLibrary/GameFunctionCallHandler.lua`

**核心结构**：
```lua
local GameFunctionCallHandler = {}

-- 依赖
local BM_StoryLibrary = require("DataLayer.StoryLibrary.BM_StoryLibrary")
local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
local StoryLibraryManager = require("GameLayer.StoryLibrary.StoryLibraryManager")
local SceneFlowManager = require("GameLayer.StoryLibrary.SceneFlowManager")

-- 主入口：处理FunctionCall
function GameFunctionCallHandler.HandleFunctionCall(functionName, args)
    if functionName == "list_available_stories" then
        return GameFunctionCallHandler.Handle_ListAvailableStories()
    elseif functionName == "switch_story" then
        return GameFunctionCallHandler.Handle_SwitchStory(args.storyId)
    elseif functionName == "restart_current_story" then
        return GameFunctionCallHandler.Handle_RestartCurrentStory()
    -- ... 其他处理器
    else
        return {
            success = false,
            error = "Unknown function: " .. functionName
        }
    end
end

return GameFunctionCallHandler
```

**每个处理器的实现要点**：

#### Handle_ListAvailableStories()
```lua
-- 返回格式
{
    success = true,
    stories = {
        {id = "story_newgreen", title = "...", description = "...", ...},
        {id = "story_company", title = "...", ...}
    }
}
```

#### Handle_SwitchStory(storyId)
```lua
-- 1. 调用StoryLibraryManager:LoadStory(storyId)
-- 2. 返回结果
{
    success = true,
    newStory = {id, title, ...},
    message = "已切换到《新绿镇时间循环》"
}
```

#### Handle_RestartCurrentStory()
```lua
-- 调用StoryLibraryManager:RestartCurrentStory()
```

#### Handle_GetGameStatus()
```lua
-- 返回当前游戏状态
{
    success = true,
    status = {
        storyId = "story_newgreen",
        storyTitle = "新绿镇时间循环",
        loopCount = 5,
        currentScene = "scene_park",
        currentSceneName = "中央公园",
        totalPlayTime = 7200
    }
}
```

#### Handle_ListAvailableScenes()
```lua
-- 调用SceneFlowManager:GetAvailableScenes()
-- 返回格式
{
    success = true,
    currentScene = {id = "scene_center", name = "社区中心"},
    availableScenes = {
        {
            id = "scene_park",
            name = "中央公园",
            unlocked = true,
            description = "去公园看看"
        },
        {
            id = "scene_lab",
            name = "雷克斯实验室",
            unlocked = false,
            reason = "需要信任度30（当前20）"
        }
    }
}
```

#### Handle_SwitchScene(sceneId)
```lua
-- 1. 调用SceneFlowManager:CanSwitchToScene(sceneId)
-- 2. 如果可以，调用SceneFlowManager:SwitchToScene(sceneId)
-- 3. 返回结果
{
    success = true,
    newScene = {id = "scene_park", name = "中央公园"},
    message = "你来到了中央公园"
}
-- 或
{
    success = false,
    reason = "需要雷克斯的信任度达到30"
}
```

#### Handle_StartNewLoop(reason)
```lua
-- 1. 调用BM_StoryRuntime:StartNewLoop()
-- 2. 返回结果
{
    success = true,
    newLoopCount = 2,
    reason = reason,
    message = "开始第2次循环"
}
```

#### Handle_GetLoopHistory(loopCount)
```lua
-- 1. 获取BM_StoryRuntime.dataModule.allLoopsHistory
-- 2. 过滤指定循环或返回全部
-- 3. 返回格式
{
    success = true,
    history = {
        {
            loopCount = 1,
            choices = [
                {choiceId = "choice_reveal", sceneId = "scene_center", ...}
            ]
        }
    }
}
```

**核心要点**：
- 所有处理器返回统一格式：`{success = true/false, ...}`
- 错误情况返回`error`或`reason`字段
- 调用底层Manager和System完成实际操作

---

### ✅ TODO 2.3：集成到 LlmManager

**位置**：需要在LlmManager中注册FunctionCall处理器

**集成方式**（伪代码）：
```lua
-- 在LlmManager的FunctionCall回调中
function OnFunctionCall(functionName, args)
    -- 现有的FunctionCall处理...
    
    -- 新增：游戏管理类FunctionCall
    local gameManagementFCs = {
        "list_available_stories",
        "switch_story",
        "restart_current_story",
        "get_game_status",
        "quit_game",
        "list_available_scenes",
        "switch_scene",
        "suggest_next_scene",
        "start_new_loop",
        "get_loop_history"
    }
    
    -- 检查是否是游戏管理类
    for _, fcName in ipairs(gameManagementFCs) do
        if functionName == fcName then
            local result = GameFunctionCallHandler.HandleFunctionCall(functionName, args)
            return result
        end
    end
    
    -- 其他FunctionCall...
end
```

**核心要点**：
- 具体集成方式取决于现有LlmManager的实现
- 确保FunctionCall Schema已传给LLM
- 确保FunctionCall结果正确返回给LLM

---

### 📝 Phase 2 完成标准

- [ ] 10个FunctionCall定义已添加
- [ ] GameFunctionCallHandler实现所有处理器
- [ ] 集成到LlmManager
- [ ] 测试每个FunctionCall的调用和返回

---

## 🔷 Phase 3：场景流转系统（3-4天）

**目标**：支持场景图和动态导航

### ✅ TODO 3.1：扩展故事配置格式（添加sceneConnections）

**位置**：修改现有的故事配置文件

**在 NewgreenTownStoryConfig.lua 中添加**：

```lua
return {
    -- 现有的 background, scenes, npcs, choices...
    
    -- 新增：场景连接关系
    sceneConnections = {
        -- 社区中心 <-> 公园（双向）
        {
            fromScene = "scene_center",
            toScene = "scene_park",
            unlockCondition = "loopCount >= 1",  -- 第一次循环后解锁
            description = "前往中央公园",
            lockedHint = "第一次循环还不能去公园"
        },
        {
            fromScene = "scene_park",
            toScene = "scene_center",
            unlockCondition = "",  -- 空条件 = 总是可用
            description = "返回社区中心"
        },
        
        -- 社区中心 -> 实验室（单向，需要信任度）
        {
            fromScene = "scene_center",
            toScene = "scene_lab",
            unlockCondition = "getNPCStat('rex', 'trust') >= 30",
            description = "进入雷克斯的秘密实验室",
            lockedHint = "雷克斯还不信任你，无法进入他的实验室"
        },
        
        -- 公园 -> 实验室（单向）
        {
            fromScene = "scene_park",
            toScene = "scene_lab",
            unlockCondition = "getNPCStat('rex', 'trust') >= 30 and hasItem('lab_key', 1)",
            description = "从后门进入实验室",
            lockedHint = "需要实验室钥匙和雷克斯的信任"
        }
    }
}
```

**SceneConnection结构**：
```lua
SceneConnection = {
    fromScene = "scene_id",           -- 起始场景ID
    toScene = "scene_id",             -- 目标场景ID
    unlockCondition = "expression",   -- 解锁条件表达式（空字符串=总是可用）
    description = "前往XXX",          -- 行动描述
    lockedHint = "需要XXX条件"        -- 未解锁时的提示（可选）
}
```

**核心要点**：
- 场景连接是有向的（A->B不等于B->A）
- 双向连接需要定义两条
- `unlockCondition`复用ConditionEvaluator
- 空条件表示总是可用

---

### ✅ TODO 3.2：扩展 BM_StoryConfig（添加场景连接相关方法）

**位置**：`Content/Script/DataLayer/Story/BM_StoryConfig.lua`

**新增方法**：

```lua
-- 获取所有场景连接
function BM_StoryConfig:GetSceneConnections()
    return self.dataModule.sceneConnections or {}
end

-- 获取从指定场景出发的连接
function BM_StoryConfig:GetConnectionsFromScene(sceneId)
    local connections = {}
    for _, conn in ipairs(self:GetSceneConnections()) do
        if conn.fromScene == sceneId then
            table.insert(connections, conn)
        end
    end
    return connections
end

-- 查找两个场景之间的连接
function BM_StoryConfig:FindConnection(fromScene, toScene)
    for _, conn in ipairs(self:GetSceneConnections()) do
        if conn.fromScene == fromScene and conn.toScene == toScene then
            return conn
        end
    end
    return nil
end
```

**同时在ImportConfig中处理sceneConnections**：
```lua
function BM_StoryConfig:ImportConfig(configData)
    -- 现有代码...
    
    -- 导入场景连接
    if configData.sceneConnections then
        self.dataModule.sceneConnections = configData.sceneConnections
    end
end
```

**扩展 DM_StoryConfig.Fields**：
```lua
DM_StoryConfig.Fields = {
    -- 现有字段...
    
    sceneConnections = {},  -- 新增：场景连接关系
}
```

---

### ✅ TODO 3.3：创建 SceneFlowManager.lua

**位置**：`Content/Script/GameLayer/StoryLibrary/SceneFlowManager.lua`

**核心方法**：

```lua
local SceneFlowManager = {}

local BM_StoryConfig = require("DataLayer.Story.BM_StoryConfig")
local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
local ConditionEvaluator = require("GameLayer.Story.Tools.ConditionEvaluator")

-- 获取当前可到达的场景列表
-- 返回：{availableScenes = {...}, lockedScenes = {...}}
function SceneFlowManager.GetAvailableScenes()
    local currentSceneId = BM_StoryRuntime:GetCurrentSceneId()
    local connections = BM_StoryConfig:GetConnectionsFromScene(currentSceneId)
    local context = ConditionEvaluator.BuildContextFromRuntime(BM_StoryRuntime)
    
    local available = {}
    local locked = {}
    
    for _, conn in ipairs(connections) do
        local unlocked = ConditionEvaluator.Evaluate(conn.unlockCondition or "", context)
        local sceneInfo = {
            id = conn.toScene,
            name = BM_StoryConfig:GetScene(conn.toScene).name,
            description = conn.description,
            unlocked = unlocked
        }
        
        if unlocked then
            table.insert(available, sceneInfo)
        else
            sceneInfo.reason = conn.lockedHint or "条件未满足"
            table.insert(locked, sceneInfo)
        end
    end
    
    return {
        availableScenes = available,
        lockedScenes = locked
    }
end

-- 检查是否可以切换到指定场景
-- 返回：{canSwitch = true/false, reason = "..."}
function SceneFlowManager.CanSwitchToScene(sceneId)
    local currentSceneId = BM_StoryRuntime:GetCurrentSceneId()
    local conn = BM_StoryConfig:FindConnection(currentSceneId, sceneId)
    
    if not conn then
        return {
            canSwitch = false,
            reason = "从当前场景无法直接到达目标场景"
        }
    end
    
    local context = ConditionEvaluator.BuildContextFromRuntime(BM_StoryRuntime)
    local unlocked = ConditionEvaluator.Evaluate(conn.unlockCondition or "", context)
    
    if unlocked then
        return {canSwitch = true}
    else
        return {
            canSwitch = false,
            reason = conn.lockedHint or "条件未满足"
        }
    end
end

-- 执行场景切换
-- 返回：{success = true/false, message = "..."}
function SceneFlowManager.SwitchToScene(sceneId)
    local canSwitch = SceneFlowManager.CanSwitchToScene(sceneId)
    
    if not canSwitch.canSwitch then
        return {
            success = false,
            message = canSwitch.reason
        }
    end
    
    -- 执行切换
    local oldSceneId = BM_StoryRuntime:GetCurrentSceneId()
    BM_StoryRuntime:ChangeScene(sceneId)
    
    -- 记录场景历史
    table.insert(BM_StoryRuntime.dataModule.sceneHistory, sceneId)
    
    -- 更新可达场景列表
    local result = SceneFlowManager.GetAvailableScenes()
    BM_StoryRuntime.dataModule.availableScenes = result.availableScenes
    
    local sceneName = BM_StoryConfig:GetScene(sceneId).name
    
    return {
        success = true,
        message = string.format("从%s来到了%s", 
            BM_StoryConfig:GetScene(oldSceneId).name,
            sceneName)
    }
end

-- AI建议下一个场景（简单实现：返回第一个可用场景）
function SceneFlowManager.SuggestNextScene()
    local result = SceneFlowManager.GetAvailableScenes()
    
    if #result.availableScenes > 0 then
        local suggested = result.availableScenes[1]
        return {
            success = true,
            suggestedScene = suggested,
            message = string.format("建议前往：%s", suggested.name)
        }
    else
        return {
            success = false,
            message = "当前没有可前往的场景"
        }
    end
end

return SceneFlowManager
```

**核心要点**：
- 所有场景切换都通过这个Manager
- 使用ConditionEvaluator评估条件
- 维护场景历史记录
- 返回格式统一

---

### ✅ TODO 3.4：扩展 BM_StoryRuntime（添加场景管理方法）

**位置**：`Content/Script/DataLayer/Story/BM_StoryRuntime.lua`

**新增方法**：

```lua
-- 获取场景访问历史
function BM_StoryRuntime:GetSceneHistory()
    return self.dataModule.sceneHistory
end

-- 获取当前可到达的场景列表（缓存）
function BM_StoryRuntime:GetCachedAvailableScenes()
    return self.dataModule.availableScenes
end

-- 检查是否访问过某个场景
function BM_StoryRuntime:HasVisitedScene(sceneId)
    for _, id in ipairs(self.dataModule.sceneHistory) do
        if id == sceneId then
            return true
        end
    end
    return false
end
```

---

### 📝 Phase 3 完成标准

- [ ] 故事配置中添加了sceneConnections
- [ ] SceneFlowManager实现并测试通过
- [ ] 可以查询可达场景
- [ ] 可以执行场景切换
- [ ] 条件评估正确工作

---

## 🔷 Phase 4：配置扩展（2-3天）

**目标**：完善配置，创建第二个故事示例

### ✅ TODO 4.1：完善 NewgreenTownStoryConfig.lua

**任务**：
- 为现有的2个场景添加完整的sceneConnections
- 确保所有场景都可达
- 添加合理的解锁条件

**检查清单**：
- [ ] 社区中心 ↔ 公园（双向连接）
- [ ] 社区中心 → 实验室（有条件）
- [ ] 所有条件表达式可以被ConditionEvaluator解析

---

### ✅ TODO 4.2：创建 CompanyMysteryStoryConfig.lua

**位置**：`Content/Script/Config/CompanyMysteryStoryConfig.lua`

**最小可用配置**：
- 1个游戏背景
- 2-3个场景（办公室、会议室、档案室）
- 3-4个NPC（同事、老板、嫌疑人）
- 2-3个抉择
- 场景连接关系

**目的**：
- 验证多故事系统工作正常
- 提供不同风格的故事示例
- 不需要非常完整，能演示即可

---

### ✅ TODO 4.3：更新 StoryLibraryConfig.lua

**确保**：
- 两个故事都已注册
- configPath正确
- 元信息完整

---

### 📝 Phase 4 完成标准

- [ ] 新绿镇配置完善（场景连接完整）
- [ ] 第二个故事配置创建（基本可玩）
- [ ] 两个故事都能正常加载和运行

---

## 🔷 Phase 5：集成测试与文档（2-3天）

**目标**：完整测试，编写使用文档

### ✅ TODO 5.1：创建测试脚本

**位置**：`Content/Script/GameLayer/StoryLibrary/多故事系统测试.lua`

**测试用例**：
```lua
local Test = {}

-- 测试1：故事库初始化
function Test.Test1_InitializeLibrary()
    StoryLibraryManager:Initialize()
    local stories = BM_StoryLibrary:GetAllStories()
    assert(#stories >= 2, "至少有2个故事")
end

-- 测试2：加载故事
function Test.Test2_LoadStory()
    local result = StoryLibraryManager:LoadStory("story_newgreen")
    assert(result.success, "加载成功")
end

-- 测试3：切换故事
function Test.Test3_SwitchStory()
    StoryLibraryManager:LoadStory("story_newgreen")
    local result = StoryLibraryManager:LoadStory("story_company")
    assert(result.success, "切换成功")
end

-- 测试4：场景流转
function Test.Test4_SceneFlow()
    StoryLibraryManager:LoadStory("story_newgreen")
    local scenes = SceneFlowManager.GetAvailableScenes()
    assert(scenes.availableScenes, "有可用场景")
end

-- 测试5：FunctionCall处理
function Test.Test5_FunctionCall()
    local result = GameFunctionCallHandler.HandleFunctionCall("list_available_stories", {})
    assert(result.success, "FunctionCall成功")
end

function Test.RunAll()
    Test.Test1_InitializeLibrary()
    Test.Test2_LoadStory()
    Test.Test3_SwitchStory()
    Test.Test4_SceneFlow()
    Test.Test5_FunctionCall()
    print("所有测试通过！")
end

return Test
```

---

### ✅ TODO 5.2：更新文档

**更新 README.md**：
- 添加多故事系统的使用说明
- 添加FunctionCall列表
- 添加场景流转示例

**更新 使用示例.lua**：
- 添加多故事相关示例
- 添加FunctionCall调用示例

---

### ✅ TODO 5.3：创建集成指南

**位置**：`Content/Script/GameLayer/StoryLibrary/集成指南.md`

**内容**：
- 如何在游戏启动时初始化
- 如何在LlmManager中集成FunctionCall
- 如何创建新故事配置
- 常见问题解答

---

### 📝 Phase 5 完成标准

- [ ] 所有测试用例通过
- [ ] 文档更新完成
- [ ] 集成指南编写完成
- [ ] 代码审查通过

---

## 🎯 总进度追踪

### Phase 完成情况

- [ ] Phase 1：故事库基础（3-4天）
  - [ ] TODO 1.1 - 1.6
- [ ] Phase 2：FunctionCall系统（4-5天）
  - [ ] TODO 2.1 - 2.3
- [ ] Phase 3：场景流转系统（3-4天）
  - [ ] TODO 3.1 - 3.4
- [ ] Phase 4：配置扩展（2-3天）
  - [ ] TODO 4.1 - 4.3
- [ ] Phase 5：集成测试与文档（2-3天）
  - [ ] TODO 5.1 - 5.3

**预计总工作量**：14-19天（约3-4周）

---

## 📚 关键技术约束

### 1. 必须遵循的规范
- 所有DataModule继承自`Core.DataLayerBase.DataModule`
- 所有BusinessModule继承自`Core.DataLayerBase.BusinessModule`
- 遵循项目的DM/BM命名规范
- 使用`---@class`和`---@field`类型注解

### 2. 不能改动的部分
- 现有的`DM_StoryConfig`和`BM_StoryConfig`核心逻辑
- 现有的`ConditionEvaluator`实现
- 现有的故事配置示例（只能扩展，不能破坏）

### 3. 依赖的现有模块
- `Core.DataLayerBase.DataModule`
- `Core.DataLayerBase.BusinessModule`
- `DataLayer.Story.*`（现有单故事系统）
- `GameLayer.Story.Tools.*`（工具层）

### 4. 条件表达式规范
- 使用ConditionEvaluator的沙箱环境
- 支持的辅助函数：hasItem, hasTag, getNPCStat, isEventTriggered, getFlag
- 可以使用Lua的基本运算符：and, or, not, >=, <=, ==, ~=

---

## 🔍 常见问题参考

### Q1: 如何添加新的故事？
**A**: 
1. 创建故事配置文件（仿照NewgreenTownStoryConfig.lua）
2. 在StoryLibraryConfig.lua中注册
3. 配置中必须包含：background, scenes, npcs, choices, sceneConnections

### Q2: 如何定义场景连接？
**A**:
- 在故事配置的sceneConnections数组中添加
- 每个连接需要：fromScene, toScene, unlockCondition, description
- 双向连接需要定义两条

### Q3: FunctionCall如何返回数据给AI？
**A**:
- 所有FunctionCall返回统一格式：`{success: true/false, ...}`
- 成功时携带数据字段
- 失败时携带error或reason字段
- LLM会解析返回值并生成回复

### Q4: 场景切换时需要做什么？
**A**:
1. 检查切换条件（SceneFlowManager.CanSwitchToScene）
2. 更新currentSceneId（BM_StoryRuntime:ChangeScene）
3. 记录场景历史
4. 更新可达场景缓存
5. 让AI生成新场景描述

### Q5: 故事切换时会丢失进度吗？
**A**:
- 是的，当前版本不保存进度
- 切换故事时会清空Runtime
- 未来可以通过Phase 6添加存档系统

---

## 💡 开发建议

### 编码建议
1. **逐个Phase开发**：完成一个Phase再开始下一个
2. **及时测试**：每完成一个TODO就测试
3. **保持注释**：所有公开方法都要有注释
4. **类型注解**：使用`---@param`和`---@return`

### 调试建议
1. 使用`print`或`UE.UKismetSystemLibrary.PrintString`输出日志
2. 在处理器中添加详细的错误信息
3. 测试条件表达式时，先用ConditionEvaluator单独测试

### 协作建议
1. 每完成一个TODO，在本文档中勾选
2. 遇到问题在文档中记录
3. 发现需要修改设计时，先更新本文档

---

## 📞 需要帮助时

### 提供以下信息
1. **当前进度**：在哪个Phase、哪个TODO
2. **遇到的问题**：具体错误信息或行为
3. **已尝试的方法**：做了什么调试
4. **相关代码**：出问题的代码片段

### 常见错误检查
- [ ] 模块路径是否正确（require路径）
- [ ] 是否调用了初始化方法
- [ ] 条件表达式语法是否正确
- [ ] FunctionCall参数是否完整
- [ ] 是否正确继承了DataModule/BusinessModule

---

## 📝 开发日志（更新记录）

| 日期 | 完成内容 | 备注 |
|------|---------|------|
| 2025-10-19 | 创建TODO文档 | 初始版本 |
| | | |

---

**END OF DOCUMENT**

请在开始开发前仔细阅读本文档，祝开发顺利！🚀

