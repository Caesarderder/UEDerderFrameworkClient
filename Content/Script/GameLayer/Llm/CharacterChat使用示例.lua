--[[
    CharacterChat 新架构使用示例
    展示如何使用新的三参数设计
--]]

local Consts = require("Util.Consts")

local CharacterChatExamples = {}

--[[
    ========================================
    示例 1: 普通NPC对话
    ========================================
--]]

function CharacterChatExamples.Example1_NormalNPC(llmMgr)
    print("=== 示例 1: 普通NPC对话 ===")
    
    -- TypeOptions: 专属参数，用于组成提示词
    local typeOptions = {
        npcId = "npc_joe",
        characterName = "老乔",
        personality = "友善但谨慎",
        motivation = "保护小镇",
        currentIntention = "观察主角的态度，如果主角表现出善意则愿意提供线索",
        background = "老乔是小镇的老居民，经历过很多事情，对镇上的人和事都很熟悉。他本质善良但因为见过太多事情而变得谨慎。",
        sceneId = "scene_town_square"
    }
    
    -- OtherOptions: 额外参数，表示需要加入哪些额外提示词类型
    local otherOptions = {
        userInput = "老乔，你知道最近发生了什么吗？",
        
        includePrompts = {
            "unlock_conditions"
        },
        
        customPrompts = {
            unlock_conditions = [[
当玩家问到关键问题（如灾难、雷克斯的计划）时，解锁对应的抉择。
            ]]
        }
    }
    
    llmMgr:Chat(
        Consts.ChatType.CHARACTER_DIALOGUE,
        typeOptions,
        otherOptions,
        function(delta)
            -- 流式回调
            print("AI: " .. delta)
        end,
        function(success, result)
            -- 完成回调
            if success then
                print("对话完成！")
            else
                print("对话失败: " .. result)
            end
        end
    )
end

--[[
    ========================================
    示例 2: 仇人对话（附带历史上下文）
    ========================================
--]]

function CharacterChatExamples.Example2_EnemyWithHistory(llmMgr, currentLoopCount)
    print("=== 示例 2: 仇人对话（附带历史上下文）===")
    
    -- TypeOptions: 仇人的专属参数
    local typeOptions = {
        npcId = "npc_enemy_rex",
        characterName = "雷克斯",
        personality = "狡猾、执着、神经质",
        motivation = "让所有人在灾难中死亡",
        currentIntention = "掩饰自己的灾难计划，同时试探主角是否察觉到异常，必要时威胁或误导主角",
        background = [[雷克斯曾经是镇上受人尊敬的科学家，但在一次实验事故后失去了家人。
他将责任归咎于镇上的所有人，认为大家的冷漠导致了悲剧。
现在他策划着让所有人都陪葬的疯狂计划，并且记得每次循环的经历。]],
        sceneId = "scene_factory"
    }
    
    -- OtherOptions: 包含仇人上下文和循环上下文
    local otherOptions = {
        userInput = "雷克斯，我知道你在策划什么！",
        
        -- 🔥 关键：includePrompts 包含 "enemy_context"
        -- 这会触发 LlmManager 自动附加聊天历史摘要
        includePrompts = {
            "enemy_context",    -- 自动附加与仇人的聊天历史
            "loop_context",     -- 附加循环上下文
            "unlock_conditions"
        },
        
        customPrompts = {
            loop_context = string.format([[
## 🔄 时间循环上下文
当前是第 %d 次循环。
你记得玩家在之前的循环中多次阻止了你的计划：
- 第1次：玩家找到了炸弹
- 第2次：玩家切断了电源
- 第3次：玩家说服了你的帮手

你开始怀疑为什么会不断重复，感到疲惫和困惑。
            ]], currentLoopCount),
            
            unlock_conditions = [[
当对话达到以下条件时，解锁场景抉择：
- 玩家触发了关键话题（如灾难计划、动机）
- 你透露了计划的线索
- 玩家表现出理解或同情
            ]]
        }
    }
    
    -- 🎉 LlmManager 会自动：
    -- 1. 检测到 includePrompts 包含 "enemy_context"
    -- 2. 从 ContextSystem 获取 npc_enemy_rex 的聊天历史
    -- 3. 生成摘要并注入到 typeOptions.enemyHistorySummary
    -- 4. 将 loop_context 注入到 typeOptions.loopContext
    
    llmMgr:Chat(
        Consts.ChatType.CHARACTER_DIALOGUE,
        typeOptions,
        otherOptions,
        function(delta)
            print("雷克斯: " .. delta)
        end,
        function(success, result)
            if success then
                print("对话完成！仇人可能解锁了新的抉择...")
            end
        end
    )
end

--[[
    ========================================
    示例 3: 新旧架构对比
    ========================================
--]]

function CharacterChatExamples.ComparisonOldVsNew()
    print("=== 新旧架构对比 ===")
    
    -- 【旧架构】
    local typeArgs_old = {
        characterName = "老乔",
        personality = "友善但谨慎",
        motivation = "保护小镇",
        currentIntention = "观察主角，根据对话内容做出自然反应",
        background = "老乔是小镇的老居民，经验丰富，对镇上的事情很了解。"
    }
    
    local normalArgs_old = {
        userInput = "你好",
        unlockConditions = "当玩家问到关键问题..."
    }
    
    -- llmMgr:Chat(chatType, typeArgs_old, normalArgs_old, ...)
    
    
    -- 【新架构】
    local typeOptions_new = {
        npcId = "npc_joe",           -- ✨ 新增：NPC ID
        sceneId = "scene_town",      -- ✨ 新增：场景ID
        characterName = "老乔",
        personality = "友善但谨慎",
        motivation = "保护小镇",
        currentIntention = "观察主角，根据对话内容做出自然反应",
        background = "老乔是小镇的老居民，经验丰富，对镇上的事情很了解。"
    }
    
    local otherOptions_new = {
        userInput = "你好",
        
        -- ✨ 新增：声明式的提示词组合
        includePrompts = {
            "unlock_conditions"
        },
        
        -- ✨ 新增：自定义提示词内容
        customPrompts = {
            unlock_conditions = "当玩家问到关键问题..."
        }
    }
    
    -- llmMgr:Chat(chatType, typeOptions_new, otherOptions_new, ...)
end

--[[
    ========================================
    示例 4: SceneChoice 使用示例
    ========================================
--]]

function CharacterChatExamples.Example4_SceneChoice(llmMgr, choiceName, loopCount, sceneName)
    print("=== 示例 4: SceneChoice 使用示例 ===")
    
    -- TypeOptions：专属参数，用于组成提示词
    local typeOptions = {
        choiceName = choiceName,       -- 抉择名字
        loopCount = loopCount,          -- 当前循环次数
        currentScene = sceneName        -- 当前场景名字
    }
    
    -- OtherOptions：额外参数（SceneChoice 通常不需要额外提示词）
    local otherOptions = {
        userInput = "",  -- 不需要用户输入
    }
    
    -- 调用 Chat
    llmMgr:Chat(
        Consts.ChatType.SCENE_CHOICE,
        typeOptions,
        otherOptions,
        function(delta)
            print("旁白: " .. delta)
        end,
        function(success, result)
            if success then
                print("抉择处理完成！")
            end
        end
    )
end

--[[
    ========================================
    示例 5: 实际UI集成示例（CharacterChat）
    ========================================
--]]

function CharacterChatExamples.Example5_UIIntegration(ui_dialog)
    print("=== 示例 5: UI集成示例 ===")
    
    -- 假设这是在 UI_Dialog1:OnSendInputText 中
    local function OnSendInputText(self, text)
        local currentNpcInfo = self.currentNpcInfo
        local currentSceneId = self.currentSceneId
        local llmMgr = self.llmMgr
        
        -- 判断当前NPC是否是仇人
        local isEnemy = currentNpcInfo.isEnemy or false
        
        -- 构建 TypeOptions
        local typeOptions = {
            npcId = currentNpcInfo.id,
            characterName = currentNpcInfo.name,
            personality = currentNpcInfo.personality,
            motivation = currentNpcInfo.motivation,
            currentIntention = currentNpcInfo.currentIntention or "观察主角，根据对话内容做出自然反应",
            background = currentNpcInfo.background or "",
            sceneId = currentSceneId
        }
        
        -- 构建 OtherOptions
        local otherOptions = {
            userInput = text,
            includePrompts = {},
            customPrompts = {}
        }
        
        -- 如果是仇人，附加仇人上下文
        if isEnemy then
            table.insert(otherOptions.includePrompts, "enemy_context")
            table.insert(otherOptions.includePrompts, "loop_context")
            
            -- 提供循环上下文
            otherOptions.customPrompts.loop_context = string.format([[
当前是第 %d 次循环。
你记得玩家之前的行为。
            ]], self.gameState.loopCount or 1)
        end
        
        -- 添加解锁条件
        table.insert(otherOptions.includePrompts, "unlock_conditions")
        otherOptions.customPrompts.unlock_conditions = self:GenerateUnlockConditions()
        
        -- 发送Chat请求
        llmMgr:Chat(
            Consts.ChatType.CHARACTER_DIALOGUE,
            typeOptions,
            otherOptions,
            function(delta)
                self:OnAITextStream(delta)
            end,
            function(success, result)
                self:OnAIReplyComplete(success, result)
            end
        )
    end
end

--[[
    ========================================
    核心设计理念总结
    ========================================
--]]

--[[
## CharacterChat（角色对话）

### TypePrompt（专属提示词）
- 定义在 LlmPromptConfig.lua 的 character_dialogue
- 包含：角色扮演提示词、工具调用说明（unlock_choice）
- 通过模板变量注入动态内容

### TypeOptions（专属参数，用于组成提示词）
- npcId: 角色ID
  * 如果是仇人，LlmManager 自动附加聊天历史
- sceneId: 场景ID
  * 决定 AI 可以调用哪些 unlock_choice
- 其他角色属性：characterName, personality, trust 等
  * 用于填充 TypePrompt 模板变量

### OtherOptions（额外参数，表示需要加入哪些额外提示词类型）
- userInput: 用户输入（必需）
- includePrompts: 声明需要的额外提示词类型
  * "enemy_context": 触发自动附加聊天历史
  * "loop_context": 附加循环上下文
  * "unlock_conditions": 附加解锁条件
- customPrompts: 提供自定义提示词内容
  * 对应 includePrompts 中的每个类型

---

## SceneChoice（场景抉择）

### TypePrompt（专属提示词）
- 定义在 LlmPromptConfig.lua 的 scene_choice
- 旁白/推动故事线的提示词
- 工具调用：AI必须在三个工具中选择一个
  * continue_cur_loop：继续当前循环，故事继续
  * start_new_loop：开启新循环（灾难发生）
  * end_loop：结束循环，故事结束

### TypeOptions（专属参数，用于组成提示词）
- choiceName: 抉择名字，表示玩家做了这个抉择
- loopCount: 当前循环次数
- currentScene: 当前场景名字

### OtherOptions（额外参数）
- userInput: 空字符串（SceneChoice不需要用户输入）
- 通常不需要额外提示词

### 工具调用逻辑
AI会根据抉择后果，自动判定并调用以下工具之一：
1. continue_cur_loop - 抉择后果不触发重置，故事继续
2. start_new_loop - 抉择导致灾难/死亡，循环重置
3. end_loop - 抉择导致循环终止，游戏结束

---

## 自动化逻辑（CharacterChat）
1. 如果 includePrompts 包含 "enemy_context"
   → LlmManager 自动获取 npcId 的聊天历史
   → 生成摘要并注入到 typeOptions.enemyHistorySummary

2. 如果提供了 sceneId
   → AI 知道当前场景
   → 可以调用 unlock_choice 工具（动态生成抉择）

3. 如果提供了 customPrompts
   → 对应的提示词内容会被添加到最终 Prompt
--]]

return CharacterChatExamples

