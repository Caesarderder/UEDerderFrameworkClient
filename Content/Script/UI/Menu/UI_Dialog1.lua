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

---@type UI_Dialog1_C
local M = UnLua.Class()

function M:Construct()
    -- 初始化对话气泡列表
    self.dialogs = {}
    self.dialogIdCounter = 0
    
    -- AI 对话相关变量
    self.currentAIDialogId = nil      -- 当前AI对话气泡ID
    self.currentAIText = ""           -- 当前AI累积的文本
    self.isAIReplying = false         -- AI是否正在回复
    
    -- 组件检查
    print("[UI_Dialog] === 组件检查 ===")
    print("[UI_Dialog] VerticalBox_Dialogs:", self.VerticalBox_Dialogs ~= nil)
    print("[UI_Dialog] CW_DialogBubble:", self.CW_DialogBubble ~= nil)
    print("[UI_Dialog] CW_InputText:", self.CW_InputText ~= nil)
    
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
    
    -- 初始化 LLM 管理器
    self:InitializeLLM()
    
    print("[UI_Dialog] 对话界面初始化完成")
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
    
    -- 设置游戏世界观（可选）
    self.llmMgr:SetGameWorld([[
你是一个友好、乐于助人的AI助手。
你可以和玩家自由对话，提供帮助和建议。
    ]])
    
    print("[UI_Dialog] ✅ LLM 管理器初始化完成")
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
    
    -- 添加AI消息气泡（初始为空，等待流式填充）
    self.currentAIDialogId = self:AddDialog(false, "AI助手")
    self.currentAIText = ""  -- 重置累积文本
    self.isAIReplying = true  -- 标记AI正在回复
    
    -- 检查 LLM 管理器是否可用
    if not self.llmMgr then
        self:SetDialogText(self.currentAIDialogId, "❌ 错误：LLM管理器未初始化")
        self.isAIReplying = false
        return
    end
    
    -- 发送到 LLM（使用流式输出）
    self.llmMgr:Chat(Consts.ChatType.GENERAL_CHAT, {
        userInput = text
    }, function(delta)
        -- 流式回调：每收到一段文字就调用
        self:OnAITextStream(delta)
    end, function(success, result)
        -- 完成回调：AI回复完成
        self:OnAIReplyComplete(success, result)
    end)
    
    print("[UI_Dialog] 已发送请求到AI，等待回复...")
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

--function M:PreConstruct(IsDesignTime)
--end

-- function M:Construct()
-- end

--function M:Tick(MyGeometry, InDeltaTime)
--end

return M
