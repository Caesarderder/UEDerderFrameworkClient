---阿里云通义千问测试用例
---演示如何使用通义千问(Qwen)进行对话

local GameContext = require("Core.GameContext")
local Consts = require("Util.Consts")

local QwenTest = {}

---配置通义千问
function QwenTest:Setup()
    print("\n=== 配置阿里云通义千问 ===")
    
    local llmMgr = GameContext:GetLlmManager()
    
    -- 设置API密钥
    llmMgr:SetApiKey("sk-592ab9ea805f48b68940ece20b7afa39")
    
    -- 使用通义千问Provider
    llmMgr:UseProvider("qwen")
    
    -- 设置模型（可选，默认为qwen-max）
    llmMgr:SetModel("qwen-max")
    
    -- 设置游戏上下文
    llmMgr:SetGameWorld([[
你是一个充满想象力的中国武侠世界。
江湖险恶，高手如云，各大门派纷争不断。
    ]])
    
    llmMgr:SetGameRules([[
- 武林规矩不可违背
- 每个选择都有因果
- 保持武侠风格和氛围
    ]])
    
    -- 设置玩家数据
    llmMgr:UpdatePlayerData("name", "萧峰")
    llmMgr:UpdatePlayerData("level", 10)
    llmMgr:UpdatePlayerData("sect", "丐帮")
    llmMgr:UpdatePlayerData("title", "丐帮帮主")
    
    print("配置完成！")
end

---测试1：基础对话
function QwenTest:TestBasicChat()
    print("\n=== 测试1：基础对话 ===")
    
    local llmMgr = GameContext:GetLlmManager()
    
    llmMgr:Chat(Consts.ChatType.GENERAL_CHAT, {
        userInput = "我来到了少林寺山门前"
    }, nil, function(success, result)
        if success then
            print("通义千问回复:")
            print(result)
        else
            print("错误:", result)
        end
    end)
end

---测试2：角色对话（流式）
function QwenTest:TestCharacterDialogueStream()
    print("\n=== 测试2：角色对话（流式打字机效果） ===")
    
    local llmMgr = GameContext:GetLlmManager()
    
    llmMgr:Chat(Consts.ChatType.CHARACTER_DIALOGUE, {
        characterName = "风清扬",
        mood = "淡然",
        userInput = "前辈，请指点晚辈剑法！"
    }, function(delta)
        -- 流式回调：实时显示打字机效果
        io.write(delta)
        io.flush()
    end, function(success, fullText)
        print("\n--- 对话完成 ---")
        if success then
            print("\n完整对话:", fullText)
        else
            print("\n错误:", fullText)
        end
    end)
end

---测试3：武侠旁白
function QwenTest:TestWuxiaNarrator()
    print("\n=== 测试3：武侠旁白 ===")
    
    local llmMgr = GameContext:GetLlmManager()
    
    llmMgr:Chat(Consts.ChatType.NARRATOR, {
        scene = "华山之巅",
        sceneDesc = "云海翻涌，悬崖千仞，剑气纵横"
    }, function(delta)
        io.write(delta)
        io.flush()
    end, function(success, result)
        print("\n--- 旁白完成 ---")
        if success then
            print("\n完整旁白:", result)
        else
            print("\n错误:", result)
        end
    end)
end

---测试4：NPC互动（江湖客栈）
function QwenTest:TestNPCInteraction()
    print("\n=== 测试4：NPC互动 - 客栈老板 ===")
    
    local llmMgr = GameContext:GetLlmManager()
    
    llmMgr:Chat(Consts.ChatType.NPC_INTERACTION, {
        npcName = "李老板",
        npcRole = "客栈掌柜",
        npcPersonality = "八面玲珑，消息灵通",
        relationshipLevel = "熟人",
        userInput = "最近江湖上有什么大事吗？"
    }, function(delta)
        io.write(delta)
        io.flush()
    end, function(success, fullText)
        print("\n--- NPC对话完成 ---")
        print("\n完整对话:", fullText)
    end)
end

---测试5：武器描述
function QwenTest:TestItemDescription()
    print("\n=== 测试5：武器描述 ===")
    
    local llmMgr = GameContext:GetLlmManager()
    
    llmMgr:Chat(Consts.ChatType.ITEM_DESCRIPTION, {
        itemName = "倚天剑",
        itemType = "神兵",
        itemRarity = "传说"
    }, nil, function(success, result)
        if success then
            print("物品描述:")
            print(result)
        else
            print("错误:", result)
        end
    end)
end

---测试6：故事推进
function QwenTest:TestStoryAdvance()
    print("\n=== 测试6：故事推进 ===")
    
    local llmMgr = GameContext:GetLlmManager()
    
    llmMgr:Chat(Consts.ChatType.STORY_ADVANCE, {
        storyPoint = "华山论剑前夕",
        playerChoice = "决定参加比武"
    }, function(delta)
        io.write(delta)
        io.flush()
    end, function(success, result)
        print("\n--- 故事推进完成 ---")
        print("\n", result)
    end)
end

---测试7：自定义武侠ChatType
function QwenTest:TestCustomWuxiaChatType()
    print("\n=== 测试7：自定义武侠ChatType ===")
    
    local llmMgr = GameContext:GetLlmManager()
    
    -- 注册武功传授ChatType
    llmMgr:RegisterChatType("martial_arts_teaching", {
        systemPrompt = [[你是{masterName}，一位武林宗师。

## 传授设定
武功名称：{skillName}
武功等级：{skillLevel}
玩家资质：{playerTalent}

## 教学原则
1. 采用古风对话，富有禅意
2. 根据玩家资质决定传授深浅
3. 可以设置修炼任务
4. 强调武德修养

## 教学内容
- 心法口诀
- 招式要领
- 修炼方法
- 注意事项]],
        tools = {"character_action"},
        temperature = 0.8,
        maxTokens = 600
    })
    
    -- 使用自定义ChatType
    llmMgr:Chat("martial_arts_teaching", {
        masterName = "张三丰",
        skillName = "太极拳",
        skillLevel = "宗师",
        playerTalent = "中等",
        userInput = "弟子愿学太极拳，请师父传授！"
    }, function(delta)
        io.write(delta)
        io.flush()
    end, function(success, result)
        print("\n--- 武功传授完成 ---")
        print("\n完整内容:", result)
    end)
end

---运行完整测试流程
function QwenTest:RunFullTest()
    print("=== 阿里云通义千问完整测试 ===\n")
    
    -- 1. 配置
    self:Setup()
    
    -- 等待一段时间后执行测试（模拟游戏运行）
    print("\n提示：以下测试需要网络连接和有效的API Key")
    print("流式请求需要在游戏循环中调用 llmMgr:Tick(deltaTime)\n")
    
    -- 2. 执行各种测试
    -- self:TestBasicChat()
    -- self:TestCharacterDialogueStream()
    -- self:TestWuxiaNarrator()
    -- self:TestNPCInteraction()
    -- self:TestItemDescription()
    -- self:TestStoryAdvance()
    -- self:TestCustomWuxiaChatType()
    
    print("\n=== 测试完成 ===")
end

---最小化示例
function QwenTest:MinimalExample()
    print("\n=== 通义千问最小化示例 ===")
    
    local llmMgr = GameContext:GetLlmManager()
    
    -- 1. 三行配置
    llmMgr:SetApiKey("sk-592ab9ea805f48b68940ece20b7afa39")
    llmMgr:UseProvider("qwen")
    llmMgr:SetModel("qwen-max")
    
    -- 2. 一行调用
    llmMgr:Chat(Consts.ChatType.GENERAL_CHAT, {
        userInput = "你好，请介绍一下你自己"
    }, nil, function(success, result)
        print("回复:", result)
    end)
    
    print("\n就是这么简单！")
end

---支持的通义千问模型列表
function QwenTest:PrintSupportedModels()
    print("\n=== 通义千问支持的模型 ===")
    print("1. qwen-max - 最强能力模型")
    print("2. qwen-plus - 平衡性能与成本")
    print("3. qwen-turbo - 快速响应")
    print("4. qwen-long - 长文本处理")
    print("\n使用方法:")
    print('llmMgr:SetModel("qwen-max")')
end

return QwenTest

