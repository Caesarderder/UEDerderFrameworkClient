# GameStory 系统使用指南

> 游戏故事生成与管理系统 - 基于LLM的AI驱动故事创作

---

## 📖 系统概述

**GameStory系统** 负责生成和管理"HereWeGoAgain"游戏的完整故事框架，包括：
- 游戏背景设定
- 角色关系网
- 故事线与关键剧情点
- 仇人的灾难计划

数据按照项目架构存储在 `DataLayer/GameStory/` 中。

---

## 📁 文件结构

```
Content/Script/
├── DataLayer/
│   └── GameStory/
│       ├── DM_GameStory.lua          # 数据模块（存储）
│       └── BM_GameStory.lua          # 业务模块（逻辑）
├── GameLayer/
│   └── GameStory/
│       └── GameStoryTools.lua        # Tools注册
└── GamePlay/
    └── GameStory/
        ├── GameStoryInitializer.lua  # 初始化器
        └── README.md                 # 本文档
```

---

## 🚀 快速开始

### 1. 在GameMode中初始化

```lua
-- Content/Script/GameMode/GM_YourGame.lua
local GameStoryInitializer = require("GamePlay.GameStory.GameStoryInitializer")

function M:ReceiveBeginPlay()
    -- 初始化GameStory系统
    local apiKey = "your-api-key-here"
    GameStoryInitializer.Initialize(apiKey, "qwen")
    
    -- 生成游戏故事
    self:GenerateGameStory()
end

function M:GenerateGameStory()
    GameStoryInitializer.GenerateStory(
        "我想要一个校园背景的故事，主角是普通学生，仇人因为校园霸凌而心理扭曲",
        "校园",    -- 场景类型
        "爆炸",    -- 灾难类型
        function(delta)
            -- 流式显示生成过程
            print(delta, "")
        end,
        function(success, result)
            print("\n")
            if success then
                print("✓ 游戏故事生成完成！")
                print(result)
                
                -- 查看生成的数据
                self:ShowGeneratedStory()
            else
                print("✗ 生成失败：", result)
            end
        end
    )
end

function M:ShowGeneratedStory()
    local storyData = GameStoryInitializer.GetGeneratedStory()
    if storyData then
        print("\n========== 生成的游戏故事 ==========")
        print("背景:", storyData.background:sub(1, 100) .. "...")
        print("主角:", storyData.protagonist.name or storyData.protagonist.姓名)
        print("仇人:", storyData.enemy.name or storyData.enemy.姓名)
        print("主要NPC数:", #storyData.mainNPCs)
        print("关键剧情点数:", #storyData.keyPoints)
        print("====================================\n")
    end
end

-- 必须！驱动LLM系统
function M:ReceiveTick(DeltaSeconds)
    local GameContext = require("Core.GameContext")
    local llmMgr = GameContext:GetLlmManager()
    if llmMgr then
        llmMgr:Tick(DeltaSeconds)
    end
end
```

### 2. 访问生成的数据

```lua
local GameStoryTools = require("GameLayer.GameStory.GameStoryTools")
local BM_GameStory = GameStoryTools.GetBusinessModule()

-- 检查是否已生成
if BM_GameStory:IsGenerated() then
    -- 获取游戏背景
    local background = BM_GameStory:GetGameBackground()
    
    -- 获取主角信息
    local protagonist = BM_GameStory:GetProtagonist()
    print("主角名字:", protagonist.name or protagonist.姓名)
    
    -- 获取仇人信息
    local enemy = BM_GameStory:GetEnemy()
    print("仇人名字:", enemy.name or enemy.姓名)
    print("仇人动机:", enemy.动机 or enemy.motive)
    
    -- 获取所有角色
    local allCharacters = BM_GameStory:GetAllCharacters()
    for i, character in ipairs(allCharacters) do
        print(i, character.name or character.姓名)
    end
    
    -- 获取故事线
    local storyLine = BM_GameStory:GetStoryLine()
    
    -- 获取关键剧情点
    local keyPoints = BM_GameStory:GetKeyStoryPoints()
    for i, point in ipairs(keyPoints) do
        print(string.format("剧情点%d: %s", i, point.name or point.标题))
    end
end
```

---

## 🔧 DataLayer 架构说明

### DM_GameStory（数据模块）

存储所有游戏故事相关的原始数据：

```lua
Fields = {
    gameBackground = "",        -- 游戏背景文本
    sceneType = "校园",         -- 场景类型
    disasterType = "爆炸",      -- 灾难类型
    characters = {},            -- 所有角色（JSON解析后）
    protagonist = nil,          -- 主角数据
    enemy = nil,                -- 仇人数据
    mainNPCs = {},             -- 主要NPC列表
    minorNPCs = {},            -- 次要NPC列表
    storyLine = "",            -- 故事线文本
    keyStoryPoints = {},       -- 关键剧情点列表
    disasterPlan = "",         -- 灾难计划详情
    isGenerated = false,       -- 是否已生成
    generatedTime = 0,         -- 生成时间戳
    version = "1.0"            -- 数据版本
}
```

### BM_GameStory（业务模块）

提供业务操作接口：

| 方法 | 说明 |
|------|------|
| `SaveGameStory(...)` | 保存完整游戏故事（由AI调用） |
| `GetGameBackground()` | 获取游戏背景 |
| `GetProtagonist()` | 获取主角信息 |
| `GetEnemy()` | 获取仇人信息 |
| `GetCharacterByName(name)` | 根据名称获取角色 |
| `GetStoryLine()` | 获取故事线 |
| `GetKeyStoryPoints()` | 获取关键剧情点列表 |
| `IsGenerated()` | 检查是否已生成 |
| `ExportToJSON()` | 导出为JSON（保存用） |
| `ImportFromJSON(json)` | 从JSON导入（读档用） |
| `DebugPrint()` | 打印调试信息 |

---

## 🛠️ 注册的Tools

系统自动注册了以下Tools供AI调用：

### 1. genrate_game（核心）

**功能**：保存AI生成的完整游戏故事

**参数**：
- `gameBackground` (string, 必需) - 游戏背景设定
- `roleRelationShip` (string, 必需) - 角色关系网JSON
- `StoryLine` (string, 必需) - 故事线文本
- `keySotryPoints` (string, 可选) - 关键剧情点JSON

**返回**：
```json
{
    "success": true,
    "message": "游戏世界已创建完成！",
    "data": {
        "charactersCount": 8,
        "hasProtagonist": true,
        "hasEnemy": true,
        "storyPointsCount": 12
    }
}
```

### 2. get_character_info

**功能**：获取指定角色的详细信息

**参数**：
- `characterName` (string) - 角色名称

### 3. get_story_point

**功能**：获取指定索引的剧情点

**参数**：
- `index` (number) - 剧情点索引（从1开始）

### 4. save_disaster_plan

**功能**：保存灾难计划详情

**参数**：
- `planDetails` (string) - 灾难计划描述

---

## 💾 数据持久化

### 导出游戏故事（保存）

```lua
local BM_GameStory = GameStoryTools.GetBusinessModule()

-- 导出为JSON
local jsonString = BM_GameStory:ExportToJSON()

-- 保存到文件（需要实现文件系统接口）
SaveToFile("GameStory.json", jsonString)
```

### 导入游戏故事（读档）

```lua
local BM_GameStory = GameStoryTools.GetBusinessModule()

-- 从文件读取
local jsonString = LoadFromFile("GameStory.json")

-- 导入数据
BM_GameStory:ImportFromJSON(jsonString)

-- 验证
if BM_GameStory:IsGenerated() then
    print("游戏故事加载成功")
    BM_GameStory:DebugPrint()
end
```

---

## 🎯 实际应用示例

### 示例1：在UI中显示角色信息

```lua
-- WBP_CharacterPanel.lua
local BM_GameStory = require("GameLayer.GameStory.GameStoryTools").GetBusinessModule()

function M:ShowProtagonist()
    local protagonist = BM_GameStory:GetProtagonist()
    if protagonist then
        self.NameText:SetText(protagonist.name or protagonist.姓名)
        self.AgeText:SetText(tostring(protagonist.age or protagonist.年龄))
        self.PersonalityText:SetText(protagonist.personality or protagonist.性格)
    end
end

function M:ShowEnemy()
    local enemy = BM_GameStory:GetEnemy()
    if enemy then
        self.EnemyNameText:SetText(enemy.name or enemy.姓名)
        self.MotiveText:SetText(enemy.motive or enemy.动机)
    end
end
```

### 示例2：触发剧情点

```lua
-- StoryProgressionSystem.lua
local BM_GameStory = require("GameLayer.GameStory.GameStoryTools").GetBusinessModule()

function StorySystem:TriggerStoryPoint(index)
    local point = BM_GameStory:GetStoryPointByIndex(index)
    if point then
        print("触发剧情点:", point.name or point.标题)
        print("描述:", point.description or point.描述)
        
        -- 触发对应的游戏事件
        self:ExecuteStoryPointEvent(point)
    end
end
```

### 示例3：根据角色关系调整对话

```lua
-- DialogueSystem.lua
local BM_GameStory = require("GameLayer.GameStory.GameStoryTools").GetBusinessModule()

function DialogueSystem:GetNPCDialogue(npcName, context)
    local character = BM_GameStory:GetCharacterByName(npcName)
    if not character then
        return "..." -- 默认对话
    end
    
    -- 根据角色性格生成对话
    local personality = character.personality or character.性格
    local relationship = character.relationship or character.关系
    
    -- 调用LLM生成对话，传入角色信息
    -- ...
end
```

---

## 🐛 调试技巧

### 查看完整数据

```lua
local BM_GameStory = require("GameLayer.GameStory.GameStoryTools").GetBusinessModule()

-- 打印调试信息
BM_GameStory:DebugPrint()
```

输出示例：
```
==================== 游戏故事数据 ====================
是否已生成: true
生成时间: 2024-10-19 15:30:45
场景类型: 校园
灾难类型: 爆炸
角色总数: 8
  - 主角: 林晨
  - 仇人: 秦墨
  - 主要NPC: 3
  - 次要NPC: 2
关键剧情点数: 12
背景文本长度: 1523
故事线文本长度: 3847
====================================================
```

### 检查数据完整性

```lua
local BM_GameStory = require("GameLayer.GameStory.GameStoryTools").GetBusinessModule()

if not BM_GameStory:IsGenerated() then
    print("警告：游戏故事尚未生成")
    return
end

if not BM_GameStory:GetProtagonist() then
    print("警告：缺少主角数据")
end

if not BM_GameStory:GetEnemy() then
    print("警告：缺少仇人数据")
end

if #BM_GameStory:GetKeyStoryPoints() == 0 then
    print("警告：没有关键剧情点")
end
```

---

## ❓ 常见问题

### Q1: 如何重新生成游戏故事？

A: 调用 `BM_GameStory:Clear()` 清空现有数据，然后重新调用生成：

```lua
local BM_GameStory = require("GameLayer.GameStory.GameStoryTools").GetBusinessModule()
BM_GameStory:Clear()

-- 重新生成
GameStoryInitializer.GenerateStory(...)
```

### Q2: 角色数据的字段名不统一怎么办？

A: AI可能生成中文或英文字段名，建议同时检查：

```lua
local name = character.name or character.姓名
local age = character.age or character.年龄
```

### Q3: 如何修改场景类型或灾难类型？

A: 在生成前设置：

```lua
local BM_GameStory = require("GameLayer.GameStory.GameStoryTools").GetBusinessModule()
BM_GameStory:SetSceneType("公司")
BM_GameStory:SetDisasterType("中毒")
```

### Q4: 生成的数据太大，如何优化？

A: 可以限制AI生成的内容长度，在ChatType中调整 `maxTokens`：

```lua
-- 在 LlmPromptConfig.lua 中
generate_game_story = {
    ...
    maxTokens = 3000  -- 减少到3000
}
```

---

## 📚 相关文档

- **LLM系统总文档**: `GameLayer/Llm/LLM系统文档.md`
- **ChatType配置**: `Config/LlmPromptConfig.lua`
- **游戏配置**: `Config/HereWeGoAgainConfig.lua`

---

**完成！** 现在你可以使用GameStory系统生成和管理游戏故事了。🎉

