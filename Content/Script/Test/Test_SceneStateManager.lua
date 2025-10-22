---场景状态管理器测试脚本
---演示SceneStateManager的核心功能
---使用方法：在游戏中执行 require("Test.Test_SceneStateManager").RunAll()

local BM_StoryConfig = require("DataLayer.Story.BM_StoryConfig")
local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
local SceneStateManager = require("GameLayer.Story.SceneStateManager")
local NewgreenTownStoryConfig = require("Config.NewgreenTownStoryConfig")

local Test = {}

---初始化测试环境
function Test.Setup()
    print("\n" .. string.rep("=", 70))
    print("【测试环境初始化】")
    print(string.rep("=", 70))
    
    -- 1. 清空现有数据
    BM_StoryConfig:Clear()
    BM_StoryRuntime:Clear()
    
    -- 2. 加载故事配置
    local storyConfig = NewgreenTownStoryConfig()
    BM_StoryConfig:ImportConfig(storyConfig)
    
    -- 3. 初始化运行时
    BM_StoryRuntime:InitializeFromConfig(BM_StoryConfig)
    
    -- 4. 开始第1次循环
    BM_StoryRuntime:StartNewLoop()
    
    print("✅ 测试环境初始化完成\n")
end

---测试1：进入场景
function Test.Test1_EnterScene()
    print("\n" .. string.rep("=", 70))
    print("【测试1】进入场景")
    print(string.rep("=", 70))
    
    local result = SceneStateManager.EnterScene("scene_center")
    
    assert(result.success, "进入场景应该成功")
    assert(result.sceneInfo ~= nil, "应该返回场景信息")
    assert(result.sceneInfo.name == "新绿镇社区中心", "场景名称应该正确")
    assert(#result.npcs > 0, "场景应该有NPC")
    
    print("\n✅ 测试1通过：成功进入场景")
    print(string.format("   场景名称: %s", result.sceneInfo.name))
    print(string.format("   NPC数量: %d", #result.npcs))
    for i, npc in ipairs(result.npcs) do
        print(string.format("     %d. %s (%s)", i, npc.name, npc.id))
    end
end

---测试2：获取场景NPC
function Test.Test2_GetSceneNPCs()
    print("\n" .. string.rep("=", 70))
    print("【测试2】获取场景NPC")
    print(string.rep("=", 70))
    
    local npcs = SceneStateManager.GetSceneNPCs()
    
    assert(#npcs > 0, "应该有NPC")
    
    print("\n✅ 测试2通过：成功获取NPC列表")
    for i, npc in ipairs(npcs) do
        print(string.format("   %d. %s - %s", i, npc.name, npc.role))
        if npc.currentState then
            print(string.format("      trust=%+d, emotion=%+d, relation=%+d",
                npc.currentState.trust, npc.currentState.emotion, npc.currentState.relation))
        end
    end
end

---测试3：开始对话
function Test.Test3_StartDialogue()
    print("\n" .. string.rep("=", 70))
    print("【测试3】开始对话")
    print(string.rep("=", 70))
    
    local result = SceneStateManager.StartDialogue("rex")
    
    assert(result.success, "开始对话应该成功")
    assert(result.npcInfo ~= nil, "应该返回NPC信息")
    assert(result.npcInfo.name == "雷克斯·普鲁特", "NPC名称应该正确")
    
    print("\n✅ 测试3通过：成功开始对话")
    print(string.format("   对话对象: %s", result.npcInfo.name))
    print(string.format("   性格: %s", result.npcInfo.personality))
    print(string.format("   对话风格: %s", result.npcInfo.dialogueStyle))
    
    -- 验证对话状态
    local currentNpc = SceneStateManager.GetCurrentDialogueNPC()
    assert(currentNpc ~= nil, "应该有当前对话NPC")
    assert(currentNpc.id == "rex", "当前对话NPC应该是rex")
    
    print(string.format("   当前对话NPC: %s", currentNpc.name))
end

---测试4：解锁抉择
function Test.Test4_UnlockChoice()
    print("\n" .. string.rep("=", 70))
    print("【测试4】解锁抉择")
    print(string.rep("=", 70))
    
    -- 先检查可用抉择（应该为空）
    local choicesBefore = SceneStateManager.GetAvailableChoices()
    print(string.format("   解锁前可用抉择数: %d", #choicesBefore))
    
    -- 解锁一个抉择
    local result = SceneStateManager.UnlockChoice("choice_reveal_plan")
    
    assert(result.success, "解锁抉择应该成功")
    assert(result.choiceInfo ~= nil, "应该返回抉择信息")
    
    -- 再次检查可用抉择
    local choicesAfter = SceneStateManager.GetAvailableChoices()
    print(string.format("   解锁后可用抉择数: %d", #choicesAfter))
    
    assert(#choicesAfter == #choicesBefore + 1, "抉择数应该增加1")
    
    print("\n✅ 测试4通过：成功解锁抉择")
    print(string.format("   抉择名称: %s", result.choiceInfo.name))
    
    print("\n   当前可用抉择:")
    for i, choice in ipairs(choicesAfter) do
        print(string.format("     %d. %s (%s)", i, choice.name, choice.id))
    end
end

---测试5：执行抉择
function Test.Test5_ExecuteChoice()
    print("\n" .. string.rep("=", 70))
    print("【测试5】执行抉择")
    print(string.rep("=", 70))
    
    -- 确保抉择已解锁
    SceneStateManager.UnlockChoice("choice_reveal_plan")
    
    local result = SceneStateManager.ExecuteChoice("choice_reveal_plan")
    
    assert(result.success, "执行抉择应该成功")
    assert(result.judgment ~= nil, "应该返回判定结果")
    
    print("\n✅ 测试5通过：成功执行抉择")
    print(string.format("   判定类型: %s", result.judgment.type))
    print(string.format("   判定原因: %s", result.judgment.reason))
    
    if result.judgment.targetScene then
        print(string.format("   目标场景: %s", result.judgment.targetScene))
    end
    
    -- 打印应用的效果
    if result.effects then
        if #result.effects.npcChanges > 0 then
            print("\n   NPC状态变化:")
            for _, change in ipairs(result.effects.npcChanges) do
                print(string.format("     - %s: %s %+d", change.npcId, change.stat, change.delta))
            end
        end
        
        if #result.effects.eventsTriggered > 0 then
            print("\n   触发的事件:")
            for _, eventId in ipairs(result.effects.eventsTriggered) do
                print(string.format("     - %s", eventId))
            end
        end
    end
end

---测试6：结束对话
function Test.Test6_EndDialogue()
    print("\n" .. string.rep("=", 70))
    print("【测试6】结束对话")
    print(string.rep("=", 70))
    
    -- 先开始对话
    SceneStateManager.StartDialogue("rex")
    
    local result = SceneStateManager.EndDialogue()
    
    assert(result.success, "结束对话应该成功")
    
    -- 验证对话已结束
    local currentNpc = SceneStateManager.GetCurrentDialogueNPC()
    assert(currentNpc == nil, "不应该有当前对话NPC")
    
    print("\n✅ 测试6通过：成功结束对话")
end

---测试7：场景切换
function Test.Test7_SwitchScene()
    print("\n" .. string.rep("=", 70))
    print("【测试7】场景切换")
    print(string.rep("=", 70))
    
    -- 从社区中心切换到公园
    local result = SceneStateManager.EnterScene("scene_park")
    
    assert(result.success, "场景切换应该成功")
    assert(result.sceneInfo.id == "scene_park", "应该切换到公园")
    assert(result.sceneInfo.name == "新绿镇中央公园", "场景名称应该正确")
    
    print("\n✅ 测试7通过：成功切换场景")
    print(string.format("   新场景: %s", result.sceneInfo.name))
    print(string.format("   新场景NPC数: %d", #result.npcs))
    for i, npc in ipairs(result.npcs) do
        print(string.format("     %d. %s", i, npc.name))
    end
end

---测试8：开始新循环
function Test.Test8_StartNewLoop()
    print("\n" .. string.rep("=", 70))
    print("【测试8】开始新循环")
    print(string.rep("=", 70))
    
    local loopBefore = BM_StoryRuntime:GetLoopCount()
    print(string.format("   循环前次数: %d", loopBefore))
    
    local result = SceneStateManager.StartNewLoop("测试循环重置")
    
    assert(result.success, "开始新循环应该成功")
    assert(result.newLoopCount == loopBefore + 1, "循环次数应该增加1")
    
    print("\n✅ 测试8通过：成功开始新循环")
    print(string.format("   新循环次数: %d", result.newLoopCount))
    print(string.format("   重置原因: %s", result.reason))
end

---测试9：获取循环状态
function Test.Test9_GetLoopStatus()
    print("\n" .. string.rep("=", 70))
    print("【测试9】获取循环状态")
    print(string.rep("=", 70))
    
    local status = SceneStateManager.GetLoopStatus()
    
    assert(status ~= nil, "应该返回状态")
    assert(status.loopCount > 0, "循环次数应该大于0")
    assert(status.currentScene ~= "", "应该有当前场景")
    
    print("\n✅ 测试9通过：成功获取循环状态")
    print(string.format("   循环次数: %d", status.loopCount))
    print(string.format("   当前场景: %s", status.currentScene))
    print(string.format("   是否在对话: %s", status.inDialogue and "是" or "否"))
end

---测试10：完整流程
function Test.Test10_FullWorkflow()
    print("\n" .. string.rep("=", 70))
    print("【测试10】完整流程测试")
    print(string.rep("=", 70))
    
    -- 1. 进入场景
    print("\n1️⃣ 进入场景...")
    local sceneResult = SceneStateManager.EnterScene("scene_center")
    assert(sceneResult.success, "进入场景失败")
    print(string.format("   ✅ 进入场景: %s", sceneResult.sceneInfo.name))
    
    -- 2. 开始对话
    print("\n2️⃣ 与NPC对话...")
    local dialogueResult = SceneStateManager.StartDialogue("rex")
    assert(dialogueResult.success, "开始对话失败")
    print(string.format("   ✅ 开始对话: %s", dialogueResult.npcInfo.name))
    
    -- 3. 解锁抉择
    print("\n3️⃣ 解锁抉择...")
    local unlockResult = SceneStateManager.UnlockChoice("choice_reveal_plan")
    assert(unlockResult.success, "解锁抉择失败")
    print(string.format("   ✅ 解锁抉择: %s", unlockResult.choiceInfo.name))
    
    -- 4. 执行抉择
    print("\n4️⃣ 执行抉择...")
    local choiceResult = SceneStateManager.ExecuteChoice("choice_reveal_plan")
    assert(choiceResult.success, "执行抉择失败")
    print(string.format("   ✅ 执行抉择，判定: %s", choiceResult.judgment.type))
    
    -- 5. 根据判定执行后续动作
    print("\n5️⃣ 根据判定执行后续动作...")
    if choiceResult.judgment.type == "next_scene" then
        print("   → 切换场景")
        local nextSceneResult = SceneStateManager.EnterScene(choiceResult.judgment.targetScene)
        assert(nextSceneResult.success, "切换场景失败")
        print(string.format("   ✅ 切换到: %s", nextSceneResult.sceneInfo.name))
    elseif choiceResult.judgment.type == "end_loop" then
        print("   → 结束循环，开始新循环")
        local loopResult = SceneStateManager.StartNewLoop(choiceResult.judgment.reason)
        assert(loopResult.success, "开始新循环失败")
        print(string.format("   ✅ 开始第%d次循环", loopResult.newLoopCount))
    else
        print("   → 继续当前循环")
        print("   ✅ 继续在当前场景")
    end
    
    print("\n✅ 测试10通过：完整流程执行成功")
end

---运行所有测试
function Test.RunAll()
    print("\n\n")
    print(string.rep("█", 70))
    print("█" .. string.rep(" ", 68) .. "█")
    print("█" .. "        SceneStateManager 完整测试套件        " .. string.rep(" ", 23) .. "█")
    print("█" .. string.rep(" ", 68) .. "█")
    print(string.rep("█", 70))
    
    -- 初始化
    Test.Setup()
    
    -- 执行测试
    local tests = {
        {name = "进入场景", func = Test.Test1_EnterScene},
        {name = "获取场景NPC", func = Test.Test2_GetSceneNPCs},
        {name = "开始对话", func = Test.Test3_StartDialogue},
        {name = "解锁抉择", func = Test.Test4_UnlockChoice},
        {name = "执行抉择", func = Test.Test5_ExecuteChoice},
        {name = "结束对话", func = Test.Test6_EndDialogue},
        {name = "场景切换", func = Test.Test7_SwitchScene},
        {name = "开始新循环", func = Test.Test8_StartNewLoop},
        {name = "获取循环状态", func = Test.Test9_GetLoopStatus},
        {name = "完整流程", func = Test.Test10_FullWorkflow}
    }
    
    local passCount = 0
    local failCount = 0
    
    for i, test in ipairs(tests) do
        local success, err = pcall(test.func)
        if success then
            passCount = passCount + 1
        else
            failCount = failCount + 1
            print("\n❌ 测试失败: " .. test.name)
            print("   错误: " .. tostring(err))
        end
    end
    
    -- 总结
    print("\n\n" .. string.rep("█", 70))
    print("█" .. string.rep(" ", 68) .. "█")
    print("█" .. "                    测试总结                    " .. string.rep(" ", 23) .. "█")
    print("█" .. string.rep(" ", 68) .. "█")
    print(string.rep("█", 70))
    print(string.format("\n总测试数: %d", #tests))
    print(string.format("✅ 通过: %d", passCount))
    print(string.format("❌ 失败: %d", failCount))
    print(string.format("通过率: %.1f%%", (passCount / #tests) * 100))
    
    if failCount == 0 then
        print("\n🎉 所有测试通过！SceneStateManager 工作正常！")
    else
        print("\n⚠️ 有测试失败，请检查！")
    end
    
    print(string.rep("█", 70) .. "\n\n")
end

---快速测试（只测试核心功能）
function Test.Quick()
    print("\n【快速测试】SceneStateManager 核心功能\n")
    
    Test.Setup()
    
    print("1. 进入场景...")
    local result = SceneStateManager.EnterScene("scene_center")
    print(string.format("   ✅ %s，NPC数:%d\n", result.sceneInfo.name, #result.npcs))
    
    print("2. 开始对话...")
    result = SceneStateManager.StartDialogue("rex")
    print(string.format("   ✅ 与%s对话\n", result.npcInfo.name))
    
    print("3. 解锁并执行抉择...")
    SceneStateManager.UnlockChoice("choice_reveal_plan")
    result = SceneStateManager.ExecuteChoice("choice_reveal_plan")
    print(string.format("   ✅ 判定:%s\n", result.judgment.type))
    
    print("✅ 快速测试完成！")
end

return Test

