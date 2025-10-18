---LLM系统测试用例
---测试多Provider、流式响应、ChatType调用等功能

local GameContext = require("Core.GameContext")
local Consts = require("Util.Consts")

local LlmStreamTest = {}

---测试1：基础配置和简单对话
function LlmStreamTest:TestBasicChat()
    print("\n=== 测试1：基础配置和简单对话 ===")
    
    -- 获取LLM管理器
    local llmMgr = GameContext:GetLlmManager()
    
    -- 配置（请替换为真实的API Key）
    llmMgr:SetApiKey("your-api-key-here")
    llmMgr:UseProvider("openai")
    
    -- 设置游戏上下文
    llmMgr:SetGameWorld([[
你是一个中世纪魔幻世界的旁白。
这个世界充满了魔法、怪物和英雄。
    ]])
    
    llmMgr:SetGameRules([[
- 玩家可以探索、战斗、对话
- 所有行动都有后果
- 保持沉浸感和故事连贯性
    ]])
    
    -- 更新玩家数据
    llmMgr:UpdatePlayerData("name", "勇士阿瑞斯")
    llmMgr:UpdatePlayerData("level", 5)
    llmMgr:UpdatePlayerData("class", "战士")
    
    -- 使用general_chat
    llmMgr:Chat(Consts.ChatType.GENERAL_CHAT, {
        userInput = "我来到了一个神秘的洞穴前"
    }, nil, function(success, result)
        if success then
            print("AI回复:", result)
        else
            print("错误:", result)
        end
    end)
end

---测试2：角色对话（流式）
function LlmStreamTest:TestCharacterDialogueStream()
    print("\n=== 测试2：角色对话（流式） ===")
    
    local llmMgr = GameContext:GetLlmManager()
    
    -- 使用character_dialogue
    llmMgr:Chat(Consts.ChatType.CHARACTER_DIALOGUE, {
        characterName = "艾莉娅",
        mood = "开心",
        userInput = "你好吗？"
    }, function(delta)
        -- 流式回调：实时显示打字机效果
        io.write(delta)
        io.flush()
    end, function(success, fullText)
        -- 完成回调
        print("\n--- 对话完成 ---")
        if success then
            print("完整对话:", fullText)
        else
            print("错误:", fullText)
        end
    end)
end

---测试3：旁白生成
function LlmStreamTest:TestNarrator()
    print("\n=== 测试3：旁白生成 ===")
    
    local llmMgr = GameContext:GetLlmManager()
    
    llmMgr:Chat(Consts.ChatType.NARRATOR, {
        scene = "神秘洞穴",
        sceneDesc = "黑暗、潮湿、回荡着未知的声音"
    }, nil, function(success, result)
        if success then
            print("旁白:", result)
        else
            print("错误:", result)
        end
    end)
end

---测试4：切换Provider
function LlmStreamTest:TestSwitchProvider()
    print("\n=== 测试4：切换Provider ===")
    
    local llmMgr = GameContext:GetLlmManager()
    
    -- 切换到Claude
    print("切换到Claude...")
    llmMgr:SetApiKey("your-claude-api-key-here")
    llmMgr:UseProvider("claude")
    
    -- 使用Claude进行对话
    llmMgr:Chat(Consts.ChatType.GENERAL_CHAT, {
        userInput = "测试Claude Provider"
    }, nil, function(success, result)
        print("Claude回复:", success, result)
    end)
    
    -- 切换到本地模型
    print("切换到本地模型...")
    llmMgr:UseProvider("local", "localhost", 8080)
    
    llmMgr:Chat(Consts.ChatType.GENERAL_CHAT, {
        userInput = "测试本地模型"
    }, nil, function(success, result)
        print("本地模型回复:", success, result)
    end)
end

---测试5：NPC互动
function LlmStreamTest:TestNPCInteraction()
    print("\n=== 测试5：NPC互动 ===")
    
    local llmMgr = GameContext:GetLlmManager()
    
    llmMgr:Chat(Consts.ChatType.NPC_INTERACTION, {
        npcName = "老铁匠汉克",
        npcRole = "铁匠",
        npcPersonality = "豪爽、健谈",
        relationshipLevel = "友好",
        userInput = "有什么好武器吗？"
    }, function(delta)
        io.write(delta)
        io.flush()
    end, function(success, fullText)
        print("\n--- NPC对话完成 ---")
        print("完整对话:", fullText)
    end)
end

---测试6：自定义ChatType
function LlmStreamTest:TestCustomChatType()
    print("\n=== 测试6：自定义ChatType ===")
    
    local llmMgr = GameContext:GetLlmManager()
    
    -- 注册自定义ChatType
    llmMgr:RegisterChatType("dungeon_master", {
        systemPrompt = [[你是游戏地下城主，负责：
1. 描述玩家探索的地下城
2. 设计陷阱和谜题
3. 控制怪物和NPC

当前地下城：{dungeonName}
难度等级：{difficulty}]],
        tools = {"trigger_event"},
        temperature = 0.8,
        maxTokens = 400
    })
    
    -- 使用自定义ChatType
    llmMgr:Chat("dungeon_master", {
        dungeonName = "遗忘之塔",
        difficulty = "困难",
        userInput = "我推开了沉重的石门"
    }, nil, function(success, result)
        print("地下城主:", result)
    end)
end

---测试7：注册自定义工具
function LlmStreamTest:TestCustomTool()
    print("\n=== 测试7：注册自定义工具 ===")
    
    local llmMgr = GameContext:GetLlmManager()
    
    -- 注册自定义工具
    llmMgr:RegisterTool({
        name = "roll_dice",
        description = "投掷骰子，用于游戏中的随机判定",
        parameters = {
            type = "object",
            properties = {
                diceType = {
                    type = "string",
                    enum = {"d6", "d20", "d100"},
                    description = "骰子类型"
                },
                count = {
                    type = "number",
                    description = "投掷次数"
                }
            },
            required = {"diceType"}
        },
        execute = function(args)
            local diceType = args.diceType
            local count = args.count or 1
            local maxValue = tonumber(string.match(diceType, "%d+"))
            
            local results = {}
            for i = 1, count do
                table.insert(results, math.random(1, maxValue))
            end
            
            return {
                success = true,
                results = results,
                total = table.concat(results, " + ") .. " = " .. (function()
                    local sum = 0
                    for _, v in ipairs(results) do sum = sum + v end
                    return sum
                end)()
            }
        end
    })
    
    print("已注册roll_dice工具")
end

---运行所有测试
function LlmStreamTest:RunAllTests()
    print("=== LLM系统测试开始 ===\n")
    
    -- 注意：实际运行前请设置真实的API Key
    print("提示：请在测试代码中设置真实的API Key\n")
    
    -- self:TestBasicChat()
    -- self:TestCharacterDialogueStream()
    -- self:TestNarrator()
    -- self:TestSwitchProvider()
    -- self:TestNPCInteraction()
    -- self:TestCustomChatType()
    -- self:TestCustomTool()
    
    print("\n=== 测试完成 ===")
    print("注意：流式请求需要在游戏循环中调用 llmMgr:Tick(deltaTime)")
end

---简单示例：最小化使用
function LlmStreamTest:MinimalExample()
    print("\n=== 最小化使用示例 ===")
    
    local llmMgr = GameContext:GetLlmManager()
    
    -- 1. 简单配置
    llmMgr:SetApiKey("your-api-key")
    llmMgr:UseProvider("openai")
    
    -- 2. 一行调用
    llmMgr:Chat(Consts.ChatType.GENERAL_CHAT, {
        userInput = "你好"
    }, nil, function(success, result)
        print("回复:", result)
    end)
    
    print("就是这么简单！")
end

return LlmStreamTest

