--[[
    时间循环叙事游戏 - 使用示例
    展示如何使用Story数据层和工具层
]]

local BM_StoryConfig = require("DataLayer.Story.BM_StoryConfig")
local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
local ConditionEvaluator = require("GameLayer.Story.Tools.ConditionEvaluator")
local StoryPromptBuilder = require("GameLayer.Story.Tools.StoryPromptBuilder")
local NewgreenConfig = require("Config.NewgreenTownStoryConfig")

---使用示例
local StoryExample = {}

---示例1：初始化游戏
function StoryExample.Example1_InitializeGame()
    print("\n========== 示例1：初始化游戏 ==========")
    
    -- 1. 加载配置
    BM_StoryConfig:ImportConfig(NewgreenConfig)
    print("✓ 配置已加载")
    
    -- 2. 初始化运行时
    BM_StoryRuntime:InitializeFromConfig(BM_StoryConfig)
    print("✓ 运行时已初始化")
    
    -- 3. 开始第一次循环
    BM_StoryRuntime:StartNewLoop()
    print("✓ 第1次循环开始")
    
    -- 4. 打印调试信息
    BM_StoryConfig:DebugPrint()
    BM_StoryRuntime:DebugPrint()
end

---示例2：构建系统Prompt并发送给LLM
function StoryExample.Example2_BuildSystemPrompt()
    print("\n========== 示例2：构建系统Prompt ==========")
    
    -- 构建完整的系统Prompt
    local systemPrompt = StoryPromptBuilder.BuildSystemPrompt(
        BM_StoryConfig,
        BM_StoryRuntime
    )
    
    print("系统Prompt内容：")
    print(systemPrompt)
    
    -- 实际使用时，发送给LLM：
    -- LlmManager:SendMessage(systemPrompt, function(response)
    --     print("AI开场白:", response)
    -- end)
end

---示例3：与NPC对话
function StoryExample.Example3_NPCDialogue()
    print("\n========== 示例3：与雷克斯对话 ==========")
    
    local npcId = "rex"
    
    -- 1. 开始对话
    BM_StoryRuntime:StartDialogue(npcId)
    
    -- 2. 构建NPC对话Prompt
    local npcPrompt = StoryPromptBuilder.BuildNPCDialoguePrompt(
        BM_StoryConfig,
        BM_StoryRuntime,
        npcId
    )
    
    print("雷克斯对话Prompt：")
    print(npcPrompt)
    
    -- 3. 玩家输入
    local playerInput = "你好，雷克斯，你在忙什么？"
    
    -- 实际使用时，发送给LLM：
    -- local fullPrompt = npcPrompt .. "\n\n玩家: " .. playerInput
    -- LlmManager:SendMessage(fullPrompt, function(response)
    --     print("雷克斯:", response)
    -- end)
    
    -- 4. 结束对话
    BM_StoryRuntime:EndDialogue()
end

---示例4：查看可用抉择
function StoryExample.Example4_AvailableChoices()
    print("\n========== 示例4：查看可用抉择 ==========")
    
    local currentSceneId = BM_StoryRuntime:GetCurrentSceneId()
    
    -- 构建可用抉择Prompt
    local choicesPrompt = StoryPromptBuilder.BuildAvailableChoicesPrompt(
        BM_StoryConfig,
        BM_StoryRuntime,
        currentSceneId
    )
    
    print("当前场景可用抉择：")
    print(choicesPrompt)
end

---示例5：条件评估
function StoryExample.Example5_ConditionEvaluation()
    print("\n========== 示例5：条件评估 ==========")
    
    -- 构建评估上下文
    local context = ConditionEvaluator.BuildContextFromRuntime(BM_StoryRuntime)
    
    -- 测试各种条件
    local conditions = {
        "loopCount >= 1",
        "loopCount >= 2",
        "getNPCStat('rex', 'trust') < 0",
        "hasItem('sunflower_seeds', 1)",
        "loopCount >= 2 and not hasTag('rex', 'angry')"
    }
    
    for _, condition in ipairs(conditions) do
        local result = ConditionEvaluator.Evaluate(condition, context)
        print(string.format("条件: %s → %s", condition, tostring(result)))
    end
end

---示例6：执行抉择
function StoryExample.Example6_MakeChoice()
    print("\n========== 示例6：执行抉择 ==========")
    
    local choiceId = "choice_feed_bean"
    
    -- 1. 先添加瓜子（满足解锁条件）
    BM_StoryRuntime:AddItem("sunflower_seeds", 1)
    print("✓ 获得瓜子 x1")
    
    -- 2. 检查条件
    local choice = BM_StoryConfig:GetChoice(choiceId)
    local context = ConditionEvaluator.BuildContextFromRuntime(BM_StoryRuntime)
    local canUnlock = ConditionEvaluator.Evaluate(choice.unlockCondition, context)
    
    print(string.format("抉择: %s", choice.name))
    print(string.format("条件: %s → %s", choice.unlockCondition, tostring(canUnlock)))
    
    if canUnlock then
        -- 3. 记录选择
        BM_StoryRuntime:RecordChoice(
            choiceId,
            BM_StoryRuntime:GetCurrentSceneId(),
            "bean"
        )
        
        -- 4. 应用效果
        if choice.effects and choice.effects.npcStates then
            for npcId, changes in pairs(choice.effects.npcStates) do
                if changes.relation then
                    BM_StoryRuntime:UpdateNPCStat(npcId, "relation", changes.relation)
                end
                if changes.tags then
                    for _, tag in ipairs(changes.tags) do
                        BM_StoryRuntime:SetNPCTag(npcId, tag, true)
                    end
                end
            end
        end
        
        -- 5. 显示结果
        print("\n结果:")
        print(choice.resultNarrative)
        
        -- 6. 查看NPC状态变化
        print("\n小豆状态:")
        print(BM_StoryRuntime:GetNPCStatePrompt("bean"))
    end
end

---示例7：循环记忆
function StoryExample.Example7_LoopMemory()
    print("\n========== 示例7：循环记忆 ==========")
    
    -- 模拟几次循环
    for i = 1, 3 do
        print(string.format("\n--- 第%d次循环 ---", i))
        
        -- 做一些选择
        BM_StoryRuntime:RecordChoice("choice_reveal_plan", "scene_center", "rex")
        BM_StoryRuntime:RecordChoice("choice_feed_bean", "scene_center", "bean")
        
        -- 结束循环（模拟死亡）
        if i < 3 then
            BM_StoryRuntime:StartNewLoop()
        end
    end
    
    -- 构建循环记忆Prompt
    local memoryPrompt = StoryPromptBuilder.BuildLoopMemoryPrompt(
        BM_StoryRuntime,
        3  -- 显示最近3次
    )
    
    print("\n循环记忆Prompt：")
    print(memoryPrompt)
end

---示例8：状态摘要（UI显示）
function StoryExample.Example8_StateSummary()
    print("\n========== 示例8：状态摘要 ==========")
    
    -- 先修改一些NPC状态
    BM_StoryRuntime:UpdateNPCStat("rex", "trust", -30)
    BM_StoryRuntime:UpdateNPCStat("rex", "relation", -40)
    BM_StoryRuntime:UpdateNPCStat("maggie", "relation", 20)
    
    -- 构建状态摘要
    local summary = StoryPromptBuilder.BuildStateSummary(BM_StoryRuntime)
    
    print("游戏状态摘要:")
    print(string.format("循环次数: %d", summary.loopCount))
    print(string.format("当前场景: %s", summary.currentScene))
    print("\nNPC关系:")
    for npcId, status in pairs(summary.npcStatuses) do
        print(string.format("  %s: %s (关系值: %d)", 
            npcId, status.status, status.relation))
    end
end

---示例9：FunctionCall处理
function StoryExample.Example9_FunctionCall()
    print("\n========== 示例9：FunctionCall处理 ==========")
    
    -- 获取FunctionCall Schema
    local functionSchema = StoryPromptBuilder.BuildFunctionCallSchema()
    
    print("支持的FunctionCall:")
    for _, func in ipairs(functionSchema) do
        print(string.format("  - %s: %s", func.name, func.description))
    end
    
    -- 模拟LLM调用 make_choice
    print("\n[模拟] LLM调用 make_choice:")
    local choiceId = "choice_pretend_support"
    local reason = "尝试接近雷克斯，获取更多信息"
    print(string.format("  choiceId: %s", choiceId))
    print(string.format("  reason: %s", reason))
    
    -- 处理调用
    local choice = BM_StoryConfig:GetChoice(choiceId)
    if choice then
        print(string.format("  ✓ 执行抉择: %s", choice.name))
        print(string.format("  结果: %s", choice.resultNarrative))
    end
    
    -- 模拟LLM调用 update_npc_state
    print("\n[模拟] LLM调用 update_npc_state:")
    print("  npcId: rex")
    print("  statChanges: {trust: 10, emotion: 5}")
    
    BM_StoryRuntime:UpdateNPCStat("rex", "trust", 10)
    BM_StoryRuntime:UpdateNPCStat("rex", "emotion", 5)
    print("  ✓ NPC状态已更新")
end

---示例10：完整游戏流程
function StoryExample.Example10_CompleteGameFlow()
    print("\n========== 示例10：完整游戏流程 ==========")
    
    -- 1. 初始化
    print("\n第1步：初始化游戏")
    BM_StoryConfig:ImportConfig(NewgreenConfig)
    BM_StoryRuntime:InitializeFromConfig(BM_StoryConfig)
    BM_StoryRuntime:StartNewLoop()
    
    -- 2. 开场
    print("\n第2步：构建开场Prompt")
    local systemPrompt = StoryPromptBuilder.BuildSystemPrompt(
        BM_StoryConfig,
        BM_StoryRuntime
    )
    print("→ 发送给LLM，AI生成开场白")
    
    -- 3. 玩家探索
    print("\n第3步：玩家询问可做什么")
    local choicesPrompt = StoryPromptBuilder.BuildAvailableChoicesPrompt(
        BM_StoryConfig,
        BM_StoryRuntime,
        "scene_center"
    )
    print("→ 显示可用抉择列表")
    
    -- 4. 玩家对话
    print("\n第4步：玩家与雷克斯对话")
    BM_StoryRuntime:StartDialogue("rex")
    local npcPrompt = StoryPromptBuilder.BuildNPCDialoguePrompt(
        BM_StoryConfig,
        BM_StoryRuntime,
        "rex"
    )
    print("→ AI扮演雷克斯回复")
    BM_StoryRuntime:EndDialogue()
    
    -- 5. 玩家做出抉择
    print("\n第5步：玩家选择'揭发雷克斯的计划'")
    local choice = BM_StoryConfig:GetChoice("choice_reveal_plan")
    BM_StoryRuntime:RecordChoice("choice_reveal_plan", "scene_center", "rex")
    
    -- 应用效果
    BM_StoryRuntime:UpdateNPCStat("rex", "trust", -20)
    BM_StoryRuntime:UpdateNPCStat("rex", "emotion", -30)
    BM_StoryRuntime:SetNPCTag("rex", "angry", true)
    BM_StoryRuntime:TriggerEvent("rex_arrested")
    BM_StoryRuntime:SetGlobalFlag("rexAngry", true)
    
    print(string.format("→ 结果: %s", choice.resultNarrative))
    
    -- 6. 玩家死亡，进入下一次循环
    print("\n第6步：灾难发生，玩家死亡")
    BM_StoryRuntime:StartNewLoop()
    print("→ 进入第2次循环")
    
    -- 7. 第二次循环，AI有了记忆
    print("\n第7步：第2次循环开始")
    local memoryPrompt = StoryPromptBuilder.BuildLoopMemoryPrompt(
        BM_StoryRuntime,
        3
    )
    print("→ AI了解玩家上次的选择")
    
    print("\n✓ 游戏流程演示完成")
end

---运行所有示例
function StoryExample.RunAll()
    -- 运行示例1-9
    StoryExample.Example1_InitializeGame()
    StoryExample.Example2_BuildSystemPrompt()
    StoryExample.Example3_NPCDialogue()
    StoryExample.Example4_AvailableChoices()
    StoryExample.Example5_ConditionEvaluation()
    StoryExample.Example6_MakeChoice()
    StoryExample.Example7_LoopMemory()
    StoryExample.Example8_StateSummary()
    StoryExample.Example9_FunctionCall()
    
    print("\n" .. string.rep("=", 60))
    print("所有示例运行完成！")
    print("提示：可以单独运行 StoryExample.Example10_CompleteGameFlow() 查看完整流程")
    print(string.rep("=", 60))
end

return StoryExample

