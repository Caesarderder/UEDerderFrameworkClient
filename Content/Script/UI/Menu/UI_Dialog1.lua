--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require("LuaPanda").start("127.0.0.1",8818)

local GameContext = require("Core.GameContext")
local Consts = require("Util.Consts")
local HereWeGoAgainConfig = require("Config.HereWeGoAgainConfig")
local GameStoryTools = require("GameLayer.GameStory.GameStoryTools")
local SceneStateManager = require("GameLayer.Story.SceneStateManager")

---@type UI_Dialog1_C
local M = UnLua.Class()

-- 全局实例引用（供Tools访问）
M.Instance = nil

function M:Construct()
    -- 保存实例引用
    M.Instance = self
    
    -- 初始化对话气泡列表
    self.dialogs = {}
    self.dialogIdCounter = 0
    
    -- AI 对话相关变量
    self.currentAIDialogId = nil      -- 当前AI对话气泡ID
    self.currentAIText = ""           -- 当前AI累积的文本
    self.isAIReplying = false         -- AI是否正在回复
    
    -- 角色对话状态
    self.currentNpcInfo = nil         -- 当前对话的NPC信息（用于CHARACTER_DIALOGUE）
    
    -- 组件检查
    print("[UI_Dialog] === 组件检查 ===")
    print("[UI_Dialog] VerticalBox_Dialogs:", self.VerticalBox_Dialogs ~= nil)
    print("[UI_Dialog] CW_DialogBubble:", self.CW_DialogBubble ~= nil)
    print("[UI_Dialog] CW_InputText:", self.CW_InputText ~= nil)
    print("[UI_Dialog] CW_Button:", self.CW_Button ~= nil)
    print("[UI_Dialog] HB_Character:", self.HB_Character ~= nil)
    print("[UI_Dialog] HB_SceneSelection:", self.HB_SceneSelection ~= nil)
    
    -- 验证 DialogBubble 预制体是否已设置
    if not self.CW_DialogBubble then
        print("[UI_Dialog] ❌ 错误：CW_DialogBubble 预制体未设置")
    end
    
    if not self.VerticalBox_dialogs then
        print("[UI_Dialog] ❌ 错误：VerticalBox_dialogs 未找到")
    end
    
    -- 注册输入框的发送事件监听
    if self.CW_InputText then
        self.CW_InputText:AddSendListener(function(text)
            self:OnSendInputText(text)
        end)
    end

    -- 注册生成游戏故事按钮事件
    if self.Button_GenerateGame then 
        self.Button_GenerateGame:AddListener(function()
            self:OnClickGenerateGame()
        end)
        print("[UI_Dialog] ✅ 生成游戏故事按钮已绑定")
    else
        print("[UI_Dialog] ⚠️ 未找到 Button_GenerateGame")
    end
    
    -- 初始化 LLM 管理器
    self:InitializeLLM()
    
    -- ==================== Debug展示：游戏初始化流程 ====================
    -- 1. 显示故事背景
    self:ShowStoryBackground()
    
    -- 2. 显示第一个场景信息
    self:ShowSceneInfo()
    
    -- 3. 刷新角色选择和场景抉择UI
    self:RefreshCharacterSelectionAndSceneDecision()
    
    print("[UI_Dialog] 对话界面初始化完成")
    print("[UI_Dialog] ✅ 游戏初始化流程展示完成")
end

-- 初始化 LLM 管理器
function M:InitializeLLM()
    -- 获取 LLM 管理器
    self.llmMgr = GameContext:GetLlmManager()
    
    if not self.llmMgr then
        print("[UI_Dialog] ❌ 错误：无法获取 LLM 管理器")
        return
    end
    
    -- 配置 LLM（使用通义千问）
    self.llmMgr:SetApiKey("sk-592ab9ea805f48b68940ece20b7afa39")
    self.llmMgr:UseProvider("qwen")
    self.llmMgr:SetModel("qwen-max")
    
    -- 设置游戏世界观（使用HereWeGoAgain配置）
    self.llmMgr:SetGameWorld(HereWeGoAgainConfig.gameWorld)
    self.llmMgr:SetGameRules(HereWeGoAgainConfig.gameRules)
    self.llmMgr:SetPlayerIdentity(HereWeGoAgainConfig.playerIdentity)
    
    -- 注册GameStory相关的Tools
    GameStoryTools.RegisterAllTools(self.llmMgr)
    
    print("[UI_Dialog] ✅ LLM 管理器初始化完成")
    print("[UI_Dialog] ✅ GameStory Tools 已注册")
end

-- 当用户点击发送按钮时触发
---@param text string 用户输入的文本内容
function M:OnSendInputText(text) 
    if text == "" then
        return
    end
    
    -- 防止重复发送（AI正在回复时）
    if self.isAIReplying then
        print("[UI_Dialog] ⚠️ AI正在回复中，请稍候...")
        return
    end
    
    print("[UI_Dialog] 收到用户输入:", text)
    
    -- 添加玩家消息气泡
    local playerDialogId = self:AddDialog(true, "玩家")
    self:SetDialogText(playerDialogId, text)
    
    -- 检查 LLM 管理器是否可用
    if not self.llmMgr then
        self:AddSystemMessage("❌ 错误：LLM管理器未初始化")
        return
    end
    
    -- ========== 根据对话状态选择 ChatType ==========
    local chatType = Consts.ChatType.GENERAL_CHAT
    local typeArgs = {}
    local normalArgs = {
        userInput = text
    }
    
    -- 如果正在与NPC对话，使用 CHARACTER_DIALOGUE 类型
    if self.currentNpcInfo then
        chatType = Consts.ChatType.CHARACTER_DIALOGUE
        
        -- typeArgs: CHARACTER_DIALOGUE 专属参数
        typeArgs = {
            characterName = self.currentNpcInfo.name,
            personality = self.currentNpcInfo.personality,
            motivation = self.currentNpcInfo.motivation,
            dialogueStyle = self.currentNpcInfo.dialogueStyle,
            trust = self.currentNpcInfo.currentState and self.currentNpcInfo.currentState.trust or 0,
            emotion = self.currentNpcInfo.currentState and self.currentNpcInfo.currentState.emotion or 0,
            relation = self.currentNpcInfo.currentState and self.currentNpcInfo.currentState.relation or 0
        }
        
        -- normalArgs: 通用参数（解锁条件 + 可用抉择列表）
        -- 获取当前场景的所有抉择（包括未解锁的）
        local BM_StoryConfig = require("DataLayer.Story.BM_StoryConfig")
        local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
        
        local currentSceneId = BM_StoryRuntime:GetCurrentSceneId()
        local choicesText = ""
        
        if currentSceneId and currentSceneId ~= "" then
            local sceneChoices = BM_StoryConfig:GetSceneChoices(currentSceneId)
            
            if sceneChoices and #sceneChoices > 0 then
                choicesText = "\n\n## 📋 当前场景可解锁的抉择\n"
                local unlockedCount = 0
                
                for _, choice in ipairs(sceneChoices) do
                    local isUnlocked = BM_StoryRuntime:IsChoiceUnlocked(choice.id)
                    local status = isUnlocked and "✅ 已解锁" or "🔒 未解锁（可解锁）"
                    
                    if isUnlocked then
                        unlockedCount = unlockedCount + 1
                    end
                    
                    choicesText = choicesText .. string.format("\n- **%s** (ID: `%s`) %s\n  描述: %s", 
                        choice.name, 
                        choice.id, 
                        status,
                        choice.description or "无描述"
                    )
                end
                
                choicesText = choicesText .. string.format("\n\n⚠️ **重要**: 只能解锁上面列表中存在的抉择ID，不要自己编造抉择ID！")
                choicesText = choicesText .. string.format("\n📊 进度: 已解锁 %d/%d 个抉择", unlockedCount, #sceneChoices)
            else
                choicesText = "\n\n⚠️ 当前场景没有配置抉择。"
            end
        end
        
        normalArgs.unlockConditions = [[
当对话达到以下条件时，应该解锁场景抉择：
- 玩家问到了关键问题（如灾难、仇人的计划）
- 你透露了重要信息或线索
- 玩家获得了你的信任
]] .. choicesText
        
        print(string.format("[UI_Dialog] 使用角色对话模式: %s", self.currentNpcInfo.name))
        print(string.format("[UI_Dialog] 当前状态 - 信任:%d, 情绪:%d, 关系:%d", 
            typeArgs.trust, typeArgs.emotion, typeArgs.relation))
        
        -- 添加AI消息气泡（显示NPC名称）
        self.currentAIDialogId = self:AddDialog(false, self.currentNpcInfo.name)
    else
        print("[UI_Dialog] 使用通用对话模式")
        
        -- 添加AI消息气泡（显示AI助手）
        self.currentAIDialogId = self:AddDialog(false, "AI助手")
    end
    
    self.currentAIText = ""  -- 重置累积文本
    self.isAIReplying = true  -- 标记AI正在回复
    
    -- 发送到 LLM（使用新架构：typeArgs, normalArgs）
    self.llmMgr:Chat(chatType, typeArgs, normalArgs, function(delta)
        -- 流式回调：每收到一段文字就调用
        self:OnAITextStream(delta)
    end, function(success, result)
        -- 完成回调：AI回复完成
        self:OnAIReplyComplete(success, result)
    end)
    
    print(string.format("[UI_Dialog] 已发送请求到AI (ChatType: %s)，等待回复...", chatType))
end

-- AI 流式文本回调
---@param delta string 新收到的文本片段
function M:OnAITextStream(delta)
    -- 累积文本
    self.currentAIText = self.currentAIText .. delta
    
    -- 实时更新AI对话气泡
    if self.currentAIDialogId then
        self:SetDialogText(self.currentAIDialogId, self.currentAIText)
    end
end

-- AI 回复完成回调
---@param success boolean 是否成功
---@param result string 完整文本（成功）或错误信息（失败）
function M:OnAIReplyComplete(success, result)
    self.isAIReplying = false  -- 解除回复锁定
    
    if not success then
        -- 失败：显示错误信息
        print("[UI_Dialog] ❌ AI回复失败:", result)
        local errorMsg = "❌ 错误：" .. result
        if self.currentAIDialogId then
            self:SetDialogText(self.currentAIDialogId, errorMsg)
        end
    else
        -- 成功：确保显示完整文本
        print("[UI_Dialog] ✅ AI回复完成，总计 " .. #result .. " 个字符")
        if self.currentAIDialogId then
            self:SetDialogText(self.currentAIDialogId, result)
        end
    end
    
    -- 清理
    self.currentAIDialogId = nil
    self.currentAIText = ""
    
    -- 滚动到底部（可选）
    -- self:ScrollToBottom()
end

-- 添加对话气泡
---@param isPlayer boolean 是否是玩家
---@param name string 角色名字
---@return number dialogID 对话气泡的唯一ID
function M:AddDialog(isPlayer, name) 
    if not self.CW_DialogBubble then
        print("[UI_Dialog] 错误：CW_DialogBubble 预制体未设置")
        return -1
    end
    
    if not self.VerticalBox_Dialogs then
        print("[UI_Dialog] 错误：VerticalBox_Dialogs 未找到")
        return -1
    end
    
    -- 使用预制体创建对话气泡实例
    local dialogBubble = nil
    
    -- 尝试创建，捕获可能的错误
    local success, err = pcall(function()
        -- 注意：CW_DialogBubble 必须是 Widget Class 类型，不是实例！
        local context=require("Core.GameContext")
        local playerController=context:getPlayerController()
        local bubbleClass=self.CW_DialogBubble:GetClass()
        dialogBubble = UE.UWidgetBlueprintLibrary.Create(self, bubbleClass, playerController)
        self.VerticalBox_Dialogs:AddChild(dialogBubble)
    end)
    
    if not success then
        print("[UI_Dialog] ❌ 创建对话气泡失败:", tostring(err))
        print("[UI_Dialog] 💡 检查：")
        print("[UI_Dialog]    1. CW_DialogBubble 是否设置为 Widget Class (不是实例)")
        print("[UI_Dialog]    2. CW_DialogBubble 蓝图是否存在")
        print("[UI_Dialog]    3. CW_DialogBubble 类型:", type(self.CW_DialogBubble))
        return -1
    end
    
    if not dialogBubble then
        print("[UI_Dialog] 错误：创建 DialogBubble 实例失败（返回 nil）")
        return -1
    end
    
    -- 设置角色信息（区分玩家和NPC）
    dialogBubble:SetCharacter(isPlayer, name)
    
    -- 生成唯一ID并保存
    self.dialogIdCounter = self.dialogIdCounter + 1
    local dialogId = self.dialogIdCounter
    self.dialogs[dialogId] = {
        widget = dialogBubble,
        isPlayer = isPlayer,
        name = name
    }
    
    print("[UI_Dialog] 添加对话气泡: ID=" .. dialogId .. ", 角色=" .. name .. ", 是否玩家=" .. tostring(isPlayer))
    
    return dialogId
end

-- 设置对话内容
---@param dialogID number 对话ID
---@param text string 对话文本
function M:SetDialogText(dialogID, text)
    local dialog = self.dialogs[dialogID]
    if not dialog then
        print("[UI_Dialog] 警告：未找到对话ID: " .. dialogID)
        return
    end
    
    if not dialog.widget or not UE.UObject.IsValid(dialog.widget) then
        print("[UI_Dialog] 警告：对话气泡实例已失效: ID=" .. dialogID)
        self.dialogs[dialogID] = nil
        return
    end
    
    -- 设置对话文本
    dialog.widget:SetText(text)
end

-- 滚动到底部
function M:ScrollToBottom()
    -- ⚠️ 重要：VerticalBox 没有 ScrollToEnd() 方法！
    -- VerticalBox 只是布局容器，不能滚动
    -- 如果需要滚动功能，必须在蓝图中用 ScrollBox 包裹 VerticalBox
    
    -- 检查是否有 ScrollBox（如果有就使用）
    -- if self.VerticalBox_Dialogs and UE.UObject.IsValid(self.VerticalBox_Dialogs) then
    --     UE.UKismetSystemLibrary.Delay(self, 0.01, function()
    --         if self.VerticalBox_Dialogs and UE.UObject.IsValid(self.VerticalBox_Dialogs) then
    --             self.VerticalBox_Dialogs:ScrollToEnd()
    --         end
    --     end)
    -- else
        -- 如果只有 VerticalBox，不执行滚动（避免崩溃）
        -- print("[UI_Dialog] 提示：没有 ScrollBox，无法自动滚动")
    -- end
end

-- 清空所有对话
function M:ClearDialogs()
    if not self.VerticalBox_Dialogs then
        return
    end
    
    -- 清空滚动容器
    self.VerticalBox_Dialogs:ClearChildren()
    
    -- 清空对话列表
    self.dialogs = {}
    self.dialogIdCounter = 0
    
    print("[UI_Dialog] 已清空所有对话")
end

-- 获取对话气泡信息
---@param dialogID number 对话ID
---@return table|nil 对话信息 {widget, isPlayer, name}
function M:GetDialog(dialogID)
    return self.dialogs[dialogID]
end

-- 移除指定对话
---@param dialogID number 对话ID
function M:RemoveDialog(dialogID)
    local dialog = self.dialogs[dialogID]
    if not dialog then
        return
    end
    
    if dialog.widget and UE.UObject.IsValid(dialog.widget) then
        dialog.widget:RemoveFromParent()
    end
    
    self.dialogs[dialogID] = nil
    print("[UI_Dialog] 移除对话: ID=" .. dialogID)
end

-- 点击生成游戏故事按钮
function M:OnClickGenerateGame()
    print("\n" .. string.rep("=", 50))
    print("[UI_Dialog] 生成游戏故事按钮被点击")
    print(string.rep("=", 50))
    
    -- 防止重复发送（AI正在回复时）
    if self.isAIReplying then
        print("[UI_Dialog] ⚠️ AI正在回复中，请稍候...")
        return
    end
    
    -- 检查 LLM 管理器是否可用
    if not self.llmMgr then
        print("[UI_Dialog] ❌ 错误：LLM管理器未初始化")
        self:AddSystemMessage("❌ 错误：LLM管理器未初始化")
        return
    end
    
    -- 添加系统消息
    local systemMsgId = self:AddDialog(false, "系统")
    self:SetDialogText(systemMsgId, "[系统] 开始生成游戏背景设定...")
    
    -- 添加AI消息气泡（用于流式显示生成的背景）
    self.currentAIDialogId = self:AddDialog(false, "游戏设计师AI")
    self.currentAIText = ""  -- 重置累积文本
    self.isAIReplying = true  -- 标记AI正在回复
    
    print("[UI_Dialog] 准备调用 generate_game_background ChatType")
    
    -- 调用 generate_game_background ChatType（第1步：生成背景）
    self.llmMgr:Chat("generate_game_background", {
        userInput = "生成一个有趣的游戏背景设定",
        sceneType = "校园",
        disasterType = "爆炸",
        specialRequirements = ""
    }, function(delta)
        -- 流式回调：逐步显示AI生成的背景
        -- 注意：如果AI调用工具，delta会是空的，不会显示工具调用参数
        if delta and delta ~= "" then
            self:OnAITextStream(delta)
        end
    end, function(success, result)
        -- 完成回调
        self:OnGenerateGameBackgroundComplete(success, result)
    end)
    
    print("[UI_Dialog] ✅ 已发送生成游戏背景请求")
end

-- 游戏背景生成完成回调
---@param success boolean 是否成功
---@param result string 完整文本（成功）或错误信息（失败）
function M:OnGenerateGameBackgroundComplete(success, result)
    self.isAIReplying = false  -- 解除回复锁定
    
    print("\n" .. string.rep("=", 50))
    print("[UI_Dialog] 游戏背景生成完成")
    print(string.rep("=", 50))
    
    if not success then
        -- 失败：显示错误信息
        print("[UI_Dialog] 游戏背景生成失败:", result)
        local errorMsg = "[错误] " .. result
        if self.currentAIDialogId then
            self:SetDialogText(self.currentAIDialogId, errorMsg)
        end
    else
        -- 成功
        print("[UI_Dialog] 游戏背景生成成功")
        print("[UI_Dialog] 总长度: " .. #result .. " 个字符")
        
        -- 如果result为空，说明AI调用了工具而没有返回文本
        if result == "" or not result then
            -- 显示工具调用提示
            if self.currentAIDialogId then
                self:SetDialogText(self.currentAIDialogId, "✨ 正在保存游戏背景数据...")
            end
        else
            -- 显示AI返回的文本
            if self.currentAIDialogId then
                self:SetDialogText(self.currentAIDialogId, result)
            end
        end
        
        -- 检查数据（异步回调中不能使用Delay，直接调用即可）
        -- 因为在流式完成回调中，工具已经执行完毕
        self:CheckGameBackgroundData()
    end
    
    -- 清理
    self.currentAIDialogId = nil
    self.currentAIText = ""
    
    print(string.rep("=", 50) .. "\n")
end

-- 游戏故事生成完成回调（保留，用于完整故事生成）
---@param success boolean 是否成功
---@param result string 完整文本（成功）或错误信息（失败）
function M:OnGenerateGameComplete(success, result)
    self.isAIReplying = false  -- 解除回复锁定
    
    print("\n" .. string.rep("=", 50))
    print("[UI_Dialog] 游戏故事生成完成")
    print(string.rep("=", 50))
    
    if not success then
        -- 失败：显示错误信息
        print("[UI_Dialog] 游戏故事生成失败:", result)
        local errorMsg = "[错误] " .. result
        if self.currentAIDialogId then
            self:SetDialogText(self.currentAIDialogId, errorMsg)
        end
    else
        -- 成功：确保显示完整文本
        print("[UI_Dialog] 游戏故事生成成功")
        print("[UI_Dialog] 总长度: " .. #result .. " 个字符")
        
        if self.currentAIDialogId then
            self:SetDialogText(self.currentAIDialogId, result)
        end
        
        -- 检查GameStory数据是否保存成功
        self:CheckGameStoryData()
    end
    
    -- 清理
    self.currentAIDialogId = nil
    self.currentAIText = ""
    
    print(string.rep("=", 50) .. "\n")
end

-- 检查并打印游戏背景数据（Tool调用结果）
function M:CheckGameBackgroundData()
    local BM_GameStory = GameStoryTools.GetBusinessModule()
    
    local sceneType = BM_GameStory:GetSceneType()
    local disasterType = BM_GameStory:GetDisasterType()
    local background = BM_GameStory:GetGameBackground()
    
    if background and background ~= "" then
        print("\n" .. string.rep("=", 60))
        print("[save_game_background Tool] 工具调用成功！游戏背景已保存")
        print(string.rep("=", 60))
        
        print("游戏背景:")
        print("   - 场景类型: " .. (sceneType or "未设置"))
        print("   - 灾难类型: " .. (disasterType or "未设置"))
        print("   - 背景文本长度: " .. #background .. " 字符")
        
        print("")
        print("数据已成功保存到 DataLayer/GameStory/")
        print(string.rep("=", 60) .. "\n")
        
        -- 添加成功提示消息
        local successMsgId = self:AddDialog(false, "系统")
        local successMsg = string.format(
            "✅ 游戏背景生成完成!\n场景: %s | 灾难: %s\n背景长度: %d 字符",
            sceneType or "未设置",
            disasterType or "未设置",
            #background
        )
        self:SetDialogText(successMsgId, successMsg)
    else
        print("[UI_Dialog] ⚠️ 警告：游戏背景数据未保存（可能Tool未被调用）")
    end
end

-- 检查并打印GameStory数据（Tool调用结果）
function M:CheckGameStoryData()
    local BM_GameStory = GameStoryTools.GetBusinessModule()
    
    if BM_GameStory:IsGenerated() then
        print("\n" .. string.rep("=", 60))
        print("[genrate_game Tool] 工具调用成功！游戏故事数据已保存")
        print(string.rep("=", 60))
        
        -- 获取并打印关键信息
        local protagonist = BM_GameStory:GetProtagonist()
        local enemy = BM_GameStory:GetEnemy()
        local allCharacters = BM_GameStory:GetAllCharacters()
        local keyPoints = BM_GameStory:GetKeyStoryPoints()
        
        print("游戏背景:")
        print("   - 场景类型: " .. BM_GameStory:GetSceneType())
        print("   - 灾难类型: " .. BM_GameStory:GetDisasterType())
        
        print("")
        print("角色信息:")
        print("   - 总角色数: " .. #allCharacters)
        if protagonist then
            local pName = protagonist.name or protagonist["姓名"] or "未知"
            print("   - 主角: " .. pName)
        end
        if enemy then
            local eName = enemy.name or enemy["姓名"] or "未知"
            print("   - 仇人: " .. eName)
        end
        print("   - 主要NPC: " .. #BM_GameStory.dataModule.mainNPCs)
        print("   - 次要NPC: " .. #BM_GameStory.dataModule.minorNPCs)
        
        print("")
        print("故事内容:")
        print("   - 关键剧情点数: " .. #keyPoints)
        print("   - 背景文本长度: " .. #BM_GameStory:GetGameBackground() .. " 字符")
        print("   - 故事线文本长度: " .. #BM_GameStory:GetStoryLine() .. " 字符")
        
        print("")
        print("数据已成功保存到 DataLayer/GameStory/")
        print(string.rep("=", 60) .. "\n")
        
        -- 添加成功提示消息
        local pName = "未知"
        if protagonist then
            pName = protagonist.name or protagonist["姓名"] or "未知"
        end
        local eName = "未知"
        if enemy then
            eName = enemy.name or enemy["姓名"] or "未知"
        end
        
        local successMsgId = self:AddDialog(false, "系统")
        local successMsg = string.format(
            "游戏故事生成完成!\n角色数: %d | 剧情点: %d\n主角: %s | 仇人: %s",
            #allCharacters,
            #keyPoints,
            pName,
            eName
        )
        self:SetDialogText(successMsgId, successMsg)
    else
        print("[UI_Dialog] ⚠️ 警告：游戏故事数据未保存（可能Tool未被调用）")
    end
end

-- 添加系统消息（便捷方法）
---@param message string 系统消息内容
function M:AddSystemMessage(message)
    local msgId = self:AddDialog(false, "系统")
    self:SetDialogText(msgId, message)
    return msgId
end

-- ==================== Debug工具：显示故事和场景信息 ====================

---显示故事背景（玩家视角）
---从StoryConfig中获取玩家可见的故事介绍并显示
function M:ShowStoryBackground()
    local BM_StoryConfig = require("DataLayer.Story.BM_StoryConfig")
    local BM_StoryLibrary = require("DataLayer.StoryLibrary.BM_StoryLibrary")
    
    -- 获取当前故事信息
    local currentStory = BM_StoryLibrary:GetCurrentStory()
    if not currentStory then
        self:AddSystemMessage("⚠️ 未找到当前故事")
        return
    end
    
    -- 【关键修改】获取展示层内容（玩家视角，不含剧透）
    local displayContent = BM_StoryConfig:GetDisplayContent()
    if not displayContent or displayContent == "" then
        -- 如果没有展示层，降级使用系统层（兼容旧配置）
        local backgroundPrompt = BM_StoryConfig:GetBackgroundPrompt()
        if not backgroundPrompt or backgroundPrompt == "" then
            self:AddSystemMessage("⚠️ 故事内容为空")
            return
        end
        
        -- 使用旧的显示方式（系统层）
        local bgMsgParts = {}
        table.insert(bgMsgParts, "📖 故事背景")
        table.insert(bgMsgParts, "")
        table.insert(bgMsgParts, "【" .. currentStory.title .. "】")
        table.insert(bgMsgParts, "")
        table.insert(bgMsgParts, backgroundPrompt)
        
        self:AddSystemMessage(table.concat(bgMsgParts, "\n"))
        print("[UI_Dialog] ✅ 已显示故事背景（系统层）: " .. currentStory.title)
        return
    end
    
    -- 【新方式】直接显示格式化好的展示层内容
    self:AddSystemMessage(displayContent)
    
    print("[UI_Dialog] ✅ 已显示故事介绍（玩家视角）: " .. currentStory.title)
end

---显示场景进入信息（玩家视角）
---从StoryConfig和StoryRuntime中获取当前场景信息并显示（精简版，符合玩家体验）
function M:ShowSceneInfo()
    local BM_StoryConfig = require("DataLayer.Story.BM_StoryConfig")
    local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
    
    -- 获取当前场景ID
    local currentSceneId = BM_StoryRuntime:GetCurrentSceneId()
    if not currentSceneId or currentSceneId == "" then
        self:AddSystemMessage("⚠️ 场景信息加载失败")
        return
    end
    
    -- 获取场景配置
    local sceneConfig = BM_StoryConfig:GetScene(currentSceneId)
    if not sceneConfig then
        self:AddSystemMessage("⚠️ 场景配置不存在: " .. currentSceneId)
        return
    end
    
    -- 【玩家视角】构建场景进入文本
    local sceneMsgParts = {}
    
    -- 分隔线
    table.insert(sceneMsgParts, "")
    table.insert(sceneMsgParts, "━━━━━━━━━━━━━━━━━━━━━━━━")
    
    -- 场景名称（醒目）
    table.insert(sceneMsgParts, "")
    table.insert(sceneMsgParts, "📍 " .. (sceneConfig.name or "未知地点"))
    table.insert(sceneMsgParts, "")
    
    -- 【优先显示】场景初始状态（具体的当前情况）
    if sceneConfig.initialState then
        table.insert(sceneMsgParts, sceneConfig.initialState)
        table.insert(sceneMsgParts, "")
    elseif sceneConfig.description then
        -- 如果没有initialState，降级使用description
        table.insert(sceneMsgParts, sceneConfig.description)
        table.insert(sceneMsgParts, "")
    end
    
    -- 场景氛围（感官体验）- 只在没有initialState时显示
    if not sceneConfig.initialState and sceneConfig.atmosphere then
        table.insert(sceneMsgParts, "🌫️ " .. sceneConfig.atmosphere)
        table.insert(sceneMsgParts, "")
    end
    
    -- 【精简版】场景中的角色（只显示名字，不剧透角色定位）
    if sceneConfig.npcIds and #sceneConfig.npcIds > 0 then
        local npcNames = {}
        for _, npcId in ipairs(sceneConfig.npcIds) do
            local npcConfig = BM_StoryConfig:GetNPC(npcId)
            if npcConfig then
                table.insert(npcNames, npcConfig.name or npcId)
            end
        end
        
        if #npcNames > 0 then
            table.insert(sceneMsgParts, "👥 你看到了：" .. table.concat(npcNames, "、"))
            table.insert(sceneMsgParts, "")
        end
    end
    
    -- 【循环信息】只有在第2次及以后才显示（第1次玩家还不知道自己在循环）
    local loopCount = BM_StoryRuntime:GetLoopCount()
    if loopCount > 1 then
        table.insert(sceneMsgParts, "━━━━━━━━━━━━━━━━━━━━━━━━")
        table.insert(sceneMsgParts, "")
        table.insert(sceneMsgParts, string.format("🔄 这是第 %d 次轮回...", loopCount))
        table.insert(sceneMsgParts, "你保留着前几次的记忆。")
    end
    
    table.insert(sceneMsgParts, "")
    table.insert(sceneMsgParts, "━━━━━━━━━━━━━━━━━━━━━━━━")
    
    -- 显示消息
    local sceneMsg = table.concat(sceneMsgParts, "\n")
    self:AddSystemMessage(sceneMsg)
    
    print("[UI_Dialog] ✅ 已显示场景进入（玩家视角）: " .. sceneConfig.name)
end

-- ==================== Debug工具：角色选择与场景抉择UI刷新 ====================

---刷新角色选择和场景抉择UI（完整刷新）
function M:RefreshCharacterSelectionAndSceneDecision()
    local BM_StoryConfig = require("DataLayer.Story.BM_StoryConfig")
    local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
    local GameContext = require("Core.GameContext")
    
    print("\n[UI_Dialog] ========== 刷新角色选择和场景抉择UI ==========")
    
    -- 1. 获取当前场景ID
    local currentSceneId = BM_StoryRuntime:GetCurrentSceneId()
    if not currentSceneId or currentSceneId == "" then
        print("[UI_Dialog] ⚠️ 警告：未找到当前场景ID")
        return
    end
    
    -- 2. 获取场景配置
    local sceneConfig = BM_StoryConfig:GetScene(currentSceneId)
    if not sceneConfig then
        print("[UI_Dialog] ⚠️ 警告：场景配置不存在:", currentSceneId)
        return
    end
    
    print(string.format("[UI_Dialog] 当前场景: %s (%s)", sceneConfig.name, currentSceneId))
    
    -- 3. 检查必要组件
    if not self.CW_Button then
        print("[UI_Dialog] ❌ 错误：CW_Button 预制体未设置")
        return
    end
    
    if not self.HB_Character then
        print("[UI_Dialog] ⚠️ 警告：HB_Character 未找到")
    end
    
    if not self.HB_SceneSelection then
        print("[UI_Dialog] ⚠️ 警告：HB_SceneSelection 未找到")
    end
    
    -- 4. 刷新角色按钮
    self:RefreshCharacterButtons(sceneConfig)
    
    -- 5. 刷新场景抉择按钮（基于运行时解锁状态）
    self:RefreshSceneDecisionButtons(sceneConfig)
    
    print("[UI_Dialog] ========== UI刷新完成 ==========\n")
end

---仅刷新场景抉择按钮（当AI解锁新抉择时调用）
---这是一个轻量级的刷新方法，供外部调用
function M:RefreshSceneDecisionOnly()
    print("\n" .. string.rep("=", 70))
    print("[UI_Dialog] 🔄 RefreshSceneDecisionOnly 被调用")
    print(string.rep("=", 70))
    
    local BM_StoryConfig = require("DataLayer.Story.BM_StoryConfig")
    local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
    
    local currentSceneId = BM_StoryRuntime:GetCurrentSceneId()
    print(string.format("[UI_Dialog] 当前场景ID: %s", currentSceneId or "nil"))
    
    if not currentSceneId or currentSceneId == "" then
        print("[UI_Dialog] ❌ 当前场景ID为空，无法刷新")
        print(string.rep("=", 70) .. "\n")
        return
    end
    
    local sceneConfig = BM_StoryConfig:GetScene(currentSceneId)
    if not sceneConfig then
        print(string.format("[UI_Dialog] ❌ 找不到场景配置: %s", currentSceneId))
        print(string.rep("=", 70) .. "\n")
        return
    end
    
    print(string.format("[UI_Dialog] ✅ 找到场景配置: %s", sceneConfig.name or currentSceneId))
    print("[UI_Dialog] 开始刷新场景抉择按钮...")
    
    self:RefreshSceneDecisionButtons(sceneConfig)
    
    print(string.rep("=", 70) .. "\n")
end

---刷新角色按钮
---@param sceneConfig table 场景配置
function M:RefreshCharacterButtons(sceneConfig)
    if not self.HB_Character then
        return
    end
    
    -- 清空现有按钮
    self.HB_Character:ClearChildren()
    print("[UI_Dialog] 已清空角色按钮")
    
    -- 检查场景中是否有NPC
    if not sceneConfig.npcIds or #sceneConfig.npcIds == 0 then
        print("[UI_Dialog] 当前场景无角色")
        return
    end
    
    local BM_StoryConfig = require("DataLayer.Story.BM_StoryConfig")
    local GameContext = require("Core.GameContext")
    local playerController = GameContext:getPlayerController()
    
    print(string.format("[UI_Dialog] 开始创建 %d 个角色按钮...", #sceneConfig.npcIds))
    
    -- 为每个NPC创建按钮
    for index, npcId in ipairs(sceneConfig.npcIds) do
        local npcConfig = BM_StoryConfig:GetNPC(npcId)
        
        if npcConfig then
            -- 创建按钮实例
            local success, buttonWidget = pcall(function()
                local buttonClass = self.CW_Button:GetClass()
                local widget = UE.UWidgetBlueprintLibrary.Create(self, buttonClass, playerController)
                return widget
            end)
            
            if success and buttonWidget then
                local npcName = npcConfig.name or npcId
                
                -- 先添加到HorizontalBox（触发Construct）
                self.HB_Character:AddChild(buttonWidget)
                buttonWidget:SetButtonText(npcName)
                
                -- 绑定点击事件：点击NPC开始对话
                buttonWidget:AddListener(function()
                    self:OnClickNPCButton(npcId, npcName)
                end)
                
                print(string.format("  [%d] ✓ 已创建角色按钮: %s (%s)", index, npcName, npcId))
            else
                print(string.format("  [%d] ❌ 创建角色按钮失败: %s", index, npcId))
            end
        else
            print(string.format("  [%d] ⚠️ NPC配置不存在: %s", index, npcId))
        end
    end
    
    print(string.format("[UI_Dialog] ✅ 角色按钮刷新完成，共 %d 个", #sceneConfig.npcIds))
end

---刷新场景抉择按钮（显示默认抉择 + 动态生成的抉择）
---@param sceneConfig table 场景配置
function M:RefreshSceneDecisionButtons(sceneConfig)
    if not self.HB_SceneSelection then
        return
    end
    
    -- 清空现有按钮
    self.HB_SceneSelection:ClearChildren()
    print("[UI_Dialog] 已清空场景抉择按钮")
    
    local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
    local GameContext = require("Core.GameContext")
    local playerController = GameContext:getPlayerController()
    
    local createdCount = 0
    
    -- ========== 1. 优先显示默认抉择（如果有） ==========
    if sceneConfig.defaultChoice then
        local defaultChoice = sceneConfig.defaultChoice
        local choiceText = defaultChoice.text or "默认行动"
        
        print("[UI_Dialog] 找到场景默认抉择: " .. choiceText)
        
        -- 创建默认抉择按钮
        local success, buttonWidget = pcall(function()
            local buttonClass = self.CW_Button:GetClass()
            local widget = UE.UWidgetBlueprintLibrary.Create(self, buttonClass, playerController)
            return widget
        end)
        
        if success and buttonWidget then
            -- 添加到HorizontalBox
            self.HB_SceneSelection:AddChild(buttonWidget)
            
            -- 设置按钮文本
            buttonWidget:SetButtonText(choiceText)
            
            -- 绑定点击事件：点击默认抉择
            buttonWidget:AddListener(function()
                self:OnClickDefaultChoice(defaultChoice)
            end)
            
            createdCount = createdCount + 1
            print(string.format("  [%d] ✓ 已创建默认抉择按钮: %s", createdCount, choiceText))
        else
            print("  ❌ 创建默认抉择按钮失败")
        end
    end
    
    -- ========== 2. 显示动态生成的抉择（AI生成） ==========
    local dynamicChoices = BM_StoryRuntime:GetDynamicChoices(sceneConfig.id)
    
    print(string.format("[UI_Dialog] 当前场景动态抉择数量: %d", #dynamicChoices))
    
    if #dynamicChoices > 0 then
        -- 创建抉择按钮
        for _, choiceConfig in ipairs(dynamicChoices) do
            local choiceId = choiceConfig.id
            local choiceName = choiceConfig.name or choiceId
            
            -- 创建按钮实例
            local success, buttonWidget = pcall(function()
                local buttonClass = self.CW_Button:GetClass()
                local widget = UE.UWidgetBlueprintLibrary.Create(self, buttonClass, playerController)
                return widget
            end)
            
            if success and buttonWidget then
                -- 先添加到HorizontalBox（触发Construct）
                self.HB_SceneSelection:AddChild(buttonWidget)
                
                -- 设置按钮文本（场景抉择名称）
                buttonWidget:SetButtonText(choiceName)
                
                -- 绑定点击事件：点击抉择执行
                buttonWidget:AddListener(function()
                    self:OnClickChoiceButton(choiceId, choiceName)
                end)
                
                createdCount = createdCount + 1
                print(string.format("  [%d] ✓ 已创建动态抉择按钮: %s (%s)", 
                    createdCount, choiceName, choiceId))
            else
                print(string.format("  ❌ 创建抉择按钮失败: %s", choiceId))
            end
        end
    end
    
    -- ========== 3. 显示统计信息 ==========
    print(string.format("[UI_Dialog] ✅ 场景抉择按钮刷新完成"))
    print(string.format("    默认抉择: %d", sceneConfig.defaultChoice and 1 or 0))
    print(string.format("    动态抉择: %d", #dynamicChoices))
    print(string.format("    已创建按钮总数: %d", createdCount))
    
    -- 如果没有任何抉择，显示提示
    if createdCount == 0 then
        print("[UI_Dialog] ⚠️ 当前场景无任何抉择（无默认抉择，也无AI生成的抉择）")
    end
end

-- ==================== 场景状态管理：按钮点击事件 ====================

---构建SCENE_CHOICE的完整TypeOptions参数
---@param choiceName string 抉择名称
---@param choiceDescription string 抉择描述（可选）
---@return table TypeOptions参数
function M:BuildSceneChoiceTypeOptions(choiceName, choiceDescription)
    local BM_StoryConfig = require("DataLayer.Story.BM_StoryConfig")
    local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
    
    -- 获取当前场景信息
    local currentSceneId = BM_StoryRuntime:GetCurrentSceneId()
    local sceneInfo = BM_StoryConfig:GetScene(currentSceneId)
    
    -- 构建参数
    local typeOptions = {
        -- 基础信息
        choiceName = choiceName,
        choiceDescription = choiceDescription or choiceName,
        loopCount = BM_StoryRuntime:GetLoopCount(),
        
        -- 场景详情
        currentSceneName = sceneInfo and sceneInfo.name or currentSceneId,
        sceneDescription = sceneInfo and sceneInfo.description or "未知场景",
        sceneAtmosphere = sceneInfo and sceneInfo.atmosphere or "平静",
        
        -- 游戏背景
        gameBackground = HereWeGoAgainConfig.gameWorld or "未设置游戏背景",
        
        -- 循环历史（简化）
        loopHistory = self:GetLoopHistorySummary(),
        
        -- 场景NPC
        sceneNPCs = self:GetSceneNPCsSummary(currentSceneId),
        
        -- 玩家状态
        playerState = self:GetPlayerStateSummary()
    }
    
    return typeOptions
end

---获取循环历史摘要
---@return string 循环历史文本
function M:GetLoopHistorySummary()
    local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
    local loopCount = BM_StoryRuntime:GetLoopCount()
    
    if loopCount == 1 then
        return "这是第一次循环，尚无历史记录"
    end
    
    -- 获取当前循环的选择历史
    local currentChoices = BM_StoryRuntime:GetCurrentLoopChoices()
    if #currentChoices == 0 then
        return "本次循环刚开始，尚未做出关键抉择"
    end
    
    local parts = {}
    for i, choice in ipairs(currentChoices) do
        table.insert(parts, string.format("%d. %s", i, choice.choiceId))
    end
    
    return "本次循环已做出的抉择：\n" .. table.concat(parts, "\n")
end

---获取场景NPC摘要
---@param sceneId string 场景ID
---@return string NPC摘要文本
function M:GetSceneNPCsSummary(sceneId)
    local BM_StoryConfig = require("DataLayer.Story.BM_StoryConfig")
    local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
    
    -- 获取场景中的NPC列表
    local sceneNPCs = BM_StoryConfig:GetSceneNPCs(sceneId)
    
    if not sceneNPCs or #sceneNPCs == 0 then
        return "场景中没有特定的关键角色"
    end
    
    local parts = {}
    for _, npcId in ipairs(sceneNPCs) do
        local npcInfo = BM_StoryConfig:GetNPC(npcId)
        local npcState = BM_StoryRuntime:GetNPCState(npcId)
        
        if npcInfo then
            local stateInfo = ""
            if npcState then
                stateInfo = string.format("（信任%d/情绪%d/关系%d）", 
                    npcState.trust or 0, 
                    npcState.emotion or 0, 
                    npcState.relation or 0)
            end
            
            table.insert(parts, string.format("- **%s**（%s）%s：%s", 
                npcInfo.name, 
                npcInfo.role or "未知", 
                stateInfo,
                npcInfo.personality or "性格未知"))
        end
    end
    
    return table.concat(parts, "\n")
end

---获取玩家状态摘要
---@return string 玩家状态文本
function M:GetPlayerStateSummary()
    local BM_LlmContext = require("DataLayer.Llm.BM_LlmContext")
    
    -- 获取玩家数据
    local playerData = BM_LlmContext.PlayerPersonalData.get()
    
    if not playerData or not next(playerData) then
        return "玩家状态正常，没有特殊状态记录"
    end
    
    local parts = {}
    for key, value in pairs(playerData) do
        table.insert(parts, string.format("- %s: %s", key, tostring(value)))
    end
    
    return table.concat(parts, "\n")
end

---点击默认抉择：执行场景的默认行动
---@param defaultChoice table 默认抉择配置 {text, type, consequence, isDestructive}
function M:OnClickDefaultChoice(defaultChoice)
    print("\n" .. string.rep("=", 70))
    print(string.format("[UI_Dialog] 玩家点击默认抉择: %s", defaultChoice.text or "未知"))
    print(string.rep("=", 70))
    
    -- 在UI中显示玩家的行动
    local playerDialogId = self:AddDialog(true, "玩家")
    self:SetDialogText(playerDialogId, string.format("【我的抉择】%s", defaultChoice.text))
    
    -- ========== 调用AI生成抉择后的叙事 ==========
    -- 检查 LLM 管理器是否可用
    if not self.llmMgr then
        self:AddSystemMessage("❌ 错误：LLM管理器未初始化")
        return
    end
    
    -- 防止重复发送（AI正在回复时）
    if self.isAIReplying then
        print("[UI_Dialog] ⚠️ AI正在回复中，请稍候...")
        return
    end
    
    -- 使用辅助函数构建完整的TypeOptions
    local typeOptions = self:BuildSceneChoiceTypeOptions(
        defaultChoice.text, 
        defaultChoice.consequence or defaultChoice.text
    )
    
    -- 调用AI（使用SCENE_CHOICE类型 - 新架构）
    self.llmMgr:Chat(
        Consts.ChatType.SCENE_CHOICE,  -- ChatType
        typeOptions,  -- TypeOptions：包含所有上下文信息
        -- OtherOptions：额外参数
        {
            userInput = "",  -- SCENE_CHOICE 不需要用户输入
        },
        function(delta)   -- onStream: 流式回调
            -- 第一次回复时创建AI气泡
            if not self.currentAIDialogId then
                self.currentAIDialogId = self:AddDialog(false, "旁白")
                self.currentAIText = ""
                self.isAIReplying = true
                print("[UI_Dialog] 创建AI旁白气泡")
            end
            
            -- 流式追加文本
            if delta and delta ~= "" then
                self.currentAIText = self.currentAIText .. delta
                self:SetDialogText(self.currentAIDialogId, self.currentAIText)
            end
        end,
        function(success, result)  -- onComplete: 完成回调
            if not success then
                print("[UI_Dialog] ❌ AI回复错误:", result)
                self:AddSystemMessage("AI回复出错: " .. tostring(result))
                self.isAIReplying = false
                return
            end
            
            print("[UI_Dialog] ✅ AI叙事生成完成（默认抉择）")
            
            -- 保存叙事到循环记忆
            local BM_LlmContext = require("DataLayer.Llm.BM_LlmContext")
            if self.currentAIText and self.currentAIText ~= "" then
                BM_LlmContext:AddLoopMemory({
                    type = "choice_result",
                    choiceName = defaultChoice.text,
                    content = self.currentAIText,
                    loopCount = BM_StoryRuntime:GetLoopCount()
                })
                print("[UI_Dialog] 已保存默认抉择叙事到循环记忆")
            end
            
            self.currentAIDialogId = nil
            self.currentAIText = ""
            self.isAIReplying = false
            
            print("[UI_Dialog] 等待AI的FunctionCall判定...")
        end
    )
    
    print(string.rep("=", 70) .. "\n")
end

---点击NPC按钮：开始对话
---@param npcId string NPC ID
---@param npcName string NPC名称
function M:OnClickNPCButton(npcId, npcName)
    print("\n" .. string.rep("=", 70))
    print(string.format("[UI_Dialog] 玩家点击NPC: %s (%s)", npcName, npcId))
    print(string.rep("=", 70))
    
    -- 使用 SceneStateManager 开始对话
    local result = SceneStateManager.StartDialogue(npcId)
    
    if not result.success then
        print(string.format("[UI_Dialog] ❌ 开始对话失败: %s", result.error or "未知错误"))
        self:AddSystemMessage("无法与该角色对话")
        print(string.rep("=", 70) .. "\n")
        return
    end
    
    print(string.format("[UI_Dialog] ✅ 成功开始与 %s 的对话", npcName))
    
    -- ========== 切换到该角色的对话上下文（恢复历史对话）==========
    if self.llmMgr then
        self.llmMgr:SwitchToCharacter(npcId)
        print(string.format("[UI_Dialog] ✅ 已切换到 %s 的对话上下文", npcName))
    end
    
    -- 在UI中显示提示信息
    local promptText = string.format("【开始对话】%s", npcName)
    self:AddSystemMessage(promptText)
    
    -- ========== 保存当前NPC信息，供发送消息时使用 ==========
    self.currentNpcInfo = result.npcInfo
    
    print(string.format("[UI_Dialog] ✅ 当前对话NPC: %s", npcName))
    if result.npcInfo and result.npcInfo.currentState then
        print(string.format("[UI_Dialog] 当前状态 - 信任:%d, 情绪:%d, 关系:%d",
            result.npcInfo.currentState.trust or 0,
            result.npcInfo.currentState.emotion or 0,
            result.npcInfo.currentState.relation or 0
        ))
    end
    
    print(string.rep("=", 70) .. "\n")
end

---结束当前角色对话
function M:EndCharacterDialogue()
    if not self.currentNpcInfo then
        print("[UI_Dialog] ⚠️ 当前没有进行中的角色对话")
        return
    end
    
    local npcName = self.currentNpcInfo.name
    
    -- 退出角色对话模式（自动保存历史）
    if self.llmMgr then
        self.llmMgr:ExitCharacterMode()
        print(string.format("[UI_Dialog] ✅ 已保存与 %s 的对话历史", npcName))
    end
    
    -- 清除NPC信息
    self.currentNpcInfo = nil
    
    -- 调用 SceneStateManager 结束对话
    SceneStateManager.EndDialogue()
    
    -- 显示提示
    self:AddSystemMessage(string.format("【结束对话】与 %s 的对话已结束", npcName))
    
    print(string.format("[UI_Dialog] ✅ 已结束与 %s 的对话", npcName))
end

---点击抉择按钮：执行抉择
---@param choiceId string 抉择ID
---@param choiceName string 抉择名称
function M:OnClickChoiceButton(choiceId, choiceName)
    print("\n" .. string.rep("=", 70))
    print(string.format("[UI_Dialog] 玩家点击抉择: %s (%s)", choiceName, choiceId))
    print(string.rep("=", 70))
    
    -- 使用 SceneStateManager 执行抉择（只执行效果，不判定）
    local result = SceneStateManager.ExecuteChoice(choiceId)
    
    if not result.success then
        print(string.format("[UI_Dialog] ❌ 执行抉择失败: %s", result.error or "未知错误"))
        self:AddSystemMessage("无法执行该抉择")
        return
    end
    
    print(string.format("[UI_Dialog] ✅ 抉择执行成功，准备调用AI生成后续叙事"))
    
    -- 在UI中显示抉择名称（玩家的行动）
    local playerDialogId = self:AddDialog(true, "玩家")
    self:SetDialogText(playerDialogId, string.format("【我的抉择】%s", choiceName))
    
    -- ========== 调用AI生成抉择后的叙事 ==========
    -- 检查 LLM 管理器是否可用
    if not self.llmMgr then
        self:AddSystemMessage("❌ 错误：LLM管理器未初始化")
        return
    end
    
    -- 防止重复发送（AI正在回复时）
    if self.isAIReplying then
        print("[UI_Dialog] ⚠️ AI正在回复中，请稍候...")
        return
    end
    
    -- 获取抉择模板
    local BM_StoryRuntime = require("DataLayer.Story.BM_StoryRuntime")
    local choiceTemplate = BM_StoryRuntime:GetDynamicChoice(choiceId)
    
    if not choiceTemplate then
        print(string.format("[UI_Dialog] ❌ 错误：找不到抉择模板 %s", choiceId))
        return
    end
    
    -- 使用辅助函数构建完整的TypeOptions
    local typeOptions = self:BuildSceneChoiceTypeOptions(
        choiceTemplate.name, 
        choiceTemplate.description or choiceTemplate.name
    )
    
    -- 调用AI（使用SCENE_CHOICE类型 - 新架构）
    self.llmMgr:Chat(
        Consts.ChatType.SCENE_CHOICE,  -- ChatType
        typeOptions,  -- TypeOptions：包含所有上下文信息
        -- OtherOptions：额外参数（当前不需要额外提示词）
        {
            userInput = "",  -- SCENE_CHOICE 不需要用户输入
        },
        function(delta)   -- onStream: 流式回调
            -- 第一次回复时创建AI气泡
            if not self.currentAIDialogId then
                self.currentAIDialogId = self:AddDialog(false, "旁白")
                self.currentAIText = ""
                self.isAIReplying = true
                print("[UI_Dialog] 创建AI旁白气泡")
            end
            
            -- 流式追加文本
            if delta and delta ~= "" then
                self.currentAIText = self.currentAIText .. delta
                self:SetDialogText(self.currentAIDialogId, self.currentAIText)
            end
        end,
        function(success, result)  -- onComplete: 完成回调
            if not success then
                print("[UI_Dialog] ❌ AI回复错误:", result)
                self:AddSystemMessage("AI回复出错: " .. tostring(result))
                self.isAIReplying = false
                return
            end
            
            print("[UI_Dialog] ✅ AI叙事生成完成")
            
            -- 保存叙事到循环记忆（玩家和仇人会记得）
            local BM_LlmContext = require("DataLayer.Llm.BM_LlmContext")
            if self.currentAIText and self.currentAIText ~= "" then
                BM_LlmContext:AddLoopMemory({
                    type = "choice_result",
                    choiceName = choiceName,
                    content = self.currentAIText,
                    loopCount = BM_StoryRuntime:GetLoopCount()
                })
                print("[UI_Dialog] 已保存抉择叙事到循环记忆")
            end
            
            self.currentAIDialogId = nil
            self.currentAIText = ""
            self.isAIReplying = false
            
            -- AI会通过FunctionCall来触发场景切换/循环重置等操作
            -- 这里不需要手动处理，FunctionCall Handler会自动处理
            print("[UI_Dialog] 等待AI的FunctionCall判定...")
        end
    )
    
    print(string.rep("=", 70) .. "\n")
end

--function M:PreConstruct(IsDesignTime)
--end

-- function M:Construct()
-- end

--function M:Tick(MyGeometry, InDeltaTime)
--end

return M
