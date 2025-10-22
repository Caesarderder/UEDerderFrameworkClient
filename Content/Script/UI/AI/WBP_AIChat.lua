---AI聊天界面
---演示流式显示AI回复
local GameContext = require("Core.GameContext")
local Consts = require("Util.Consts")

---@type WBP_AIChat_C
local M = UnLua.Class()

---构造函数
function M:Construct()
    print("[WBP_AIChat] 构造AI聊天界面")
    
    -- 获取LLM管理器
    self.llmMgr = GameContext:GetLlmManager()
    
    -- 配置通义千问（首次初始化）
    self:InitializeLLM()
    
    -- 绑定按钮事件
    self.SendButton.OnClicked:Add(self, self.OnSendButtonClicked)
    
    -- 绑定输入框回车事件
    self.InputBox.OnTextCommitted:Add(self, self.OnInputCommitted)
    
    -- 初始化变量
    self.isProcessing = false
    self.currentMessageWidget = nil
    self.accumulatedText = ""
    
    -- 显示欢迎消息
    self:AddSystemMessage("欢迎使用AI助手！我是通义千问，有什么可以帮助你的吗？")
end

---初始化LLM配置
function M:InitializeLLM()
    if not self.llmMgr then
        print("[WBP_AIChat] 错误：无法获取LLM管理器")
        return
    end
    
    -- 配置通义千问
    self.llmMgr:SetApiKey("sk-592ab9ea805f48b68940ece20b7afa39")
    self.llmMgr:UseProvider("qwen")
    self.llmMgr:SetModel("qwen-max")
    
    -- 设置游戏上下文（可选）
    self.llmMgr:SetGameWorld("你是一个友好的AI助手")
    
    print("[WBP_AIChat] LLM初始化完成")
end

---发送按钮点击
function M:OnSendButtonClicked()
    self:SendMessage()
end

---输入框回车事件
function M:OnInputCommitted(Text, CommitMethod)
    -- 只有按下回车时才发送（Shift+回车换行）
    if CommitMethod == UE.ETextCommit.OnEnter then
        self:SendMessage()
    end
end

---发送消息
function M:SendMessage()
    if self.isProcessing then
        print("[WBP_AIChat] 正在处理中，请稍候...")
        return
    end
    
    -- 获取用户输入
    local userInput = self.InputBox:GetText():ToString()
    if userInput == "" then
        return
    end
    
    -- 清空输入框
    self.InputBox:SetText(UE.FText(""))
    
    -- 显示用户消息
    self:AddUserMessage(userInput)
    
    -- 显示加载状态
    self:SetProcessingState(true)
    
    -- 创建AI消息占位符
    self:CreateAIMessageWidget()
    
    -- 发送到LLM（流式）
    self.llmMgr:Chat(Consts.ChatType.GENERAL_CHAT, {
        userInput = userInput
    }, function(delta)
        -- 流式回调：每次收到新的文本片段
        self:OnStreamDelta(delta)
    end, function(success, fullText)
        -- 完成回调
        self:OnStreamComplete(success, fullText)
    end)
end

---流式回调：接收增量文本
function M:OnStreamDelta(delta)
    if not self.currentMessageWidget then
        return
    end
    
    -- 累积文本
    self.accumulatedText = self.accumulatedText .. delta
    
    -- 更新UI显示
    self.currentMessageWidget:SetText(UE.FText(self.accumulatedText))
    
    -- 滚动到底部
    self:ScrollToBottom()
end

---流式完成回调
function M:OnStreamComplete(success, fullText)
    print("[WBP_AIChat] 流式完成:", success, #fullText)
    
    -- 设置最终文本（以防万一）
    if success and self.currentMessageWidget then
        self.currentMessageWidget:SetText(UE.FText(fullText))
    elseif not success then
        -- 显示错误
        self:AddSystemMessage("错误: " .. fullText)
    end
    
    -- 重置状态
    self.currentMessageWidget = nil
    self.accumulatedText = ""
    self:SetProcessingState(false)
    
    -- 滚动到底部
    self:ScrollToBottom()
end

---创建AI消息Widget
function M:CreateAIMessageWidget()
    -- 创建消息容器
    local messageContainer = UE.UWidgetBlueprintLibrary.Create(self, UE.UHorizontalBox.Class())
    
    -- 创建AI头像（可选）
    local avatarBorder = UE.UWidgetBlueprintLibrary.Create(self, UE.UBorder.Class())
    avatarBorder:SetPadding(UE.FMargin(5, 5, 5, 5))
    
    local avatarText = UE.UWidgetBlueprintLibrary.Create(self, UE.UTextBlock.Class())
    avatarText:SetText(UE.FText("🤖"))
    avatarBorder:AddChild(avatarText)
    
    -- 创建消息气泡
    local messageBorder = UE.UWidgetBlueprintLibrary.Create(self, UE.UBorder.Class())
    messageBorder:SetPadding(UE.FMargin(10, 8, 10, 8))
    
    -- 设置气泡样式（浅蓝色背景）
    local bgColor = UE.FLinearColor(0.9, 0.95, 1.0, 1.0)
    messageBorder.Background.TintColor = UE.FSlateColor(bgColor)
    
    -- 创建文本块
    local textBlock = UE.UWidgetBlueprintLibrary.Create(self, UE.UTextBlock.Class())
    textBlock:SetAutoWrapText(true)
    textBlock:SetText(UE.FText(""))  -- 初始为空，等待流式填充
    
    -- 设置文本样式
    local textColor = UE.FLinearColor(0.1, 0.1, 0.1, 1.0)
    textBlock:SetColorAndOpacity(UE.FSlateColor(textColor))
    
    messageBorder:AddChild(textBlock)
    
    -- 组装
    messageContainer:AddChild(avatarBorder)
    messageContainer:AddChild(messageBorder)
    
    -- 添加到消息列表
    self.ScrollBox_Messages:AddChild(messageContainer)
    
    -- 保存当前消息Widget，用于流式更新
    self.currentMessageWidget = textBlock
    self.accumulatedText = ""
end

---添加用户消息
function M:AddUserMessage(text)
    -- 创建消息容器（右对齐）
    local messageContainer = UE.UWidgetBlueprintLibrary.Create(self, UE.UHorizontalBox.Class())
    
    -- 添加弹性空间（推到右边）
    local spacer = UE.UWidgetBlueprintLibrary.Create(self, UE.USpacer.Class())
    messageContainer:AddChild(spacer)
    
    -- 创建消息气泡
    local messageBorder = UE.UWidgetBlueprintLibrary.Create(self, UE.UBorder.Class())
    messageBorder:SetPadding(UE.FMargin(10, 8, 10, 8))
    
    -- 设置气泡样式（绿色背景）
    local bgColor = UE.FLinearColor(0.85, 0.95, 0.85, 1.0)
    messageBorder.Background.TintColor = UE.FSlateColor(bgColor)
    
    -- 创建文本块
    local textBlock = UE.UWidgetBlueprintLibrary.Create(self, UE.UTextBlock.Class())
    textBlock:SetAutoWrapText(true)
    textBlock:SetText(UE.FText(text))
    
    messageBorder:AddChild(textBlock)
    messageContainer:AddChild(messageBorder)
    
    -- 添加用户头像
    local avatarBorder = UE.UWidgetBlueprintLibrary.Create(self, UE.UBorder.Class())
    avatarBorder:SetPadding(UE.FMargin(5, 5, 5, 5))
    
    local avatarText = UE.UWidgetBlueprintLibrary.Create(self, UE.UTextBlock.Class())
    avatarText:SetText(UE.FText("👤"))
    avatarBorder:AddChild(avatarText)
    
    messageContainer:AddChild(avatarBorder)
    
    -- 添加到消息列表
    self.ScrollBox_Messages:AddChild(messageContainer)
    
    -- 滚动到底部
    self:ScrollToBottom()
end

---添加系统消息
function M:AddSystemMessage(text)
    -- 创建系统消息
    local messageBorder = UE.UWidgetBlueprintLibrary.Create(self, UE.UBorder.Class())
    messageBorder:SetPadding(UE.FMargin(10, 5, 10, 5))
    
    -- 灰色背景
    local bgColor = UE.FLinearColor(0.95, 0.95, 0.95, 1.0)
    messageBorder.Background.TintColor = UE.FSlateColor(bgColor)
    
    local textBlock = UE.UWidgetBlueprintLibrary.Create(self, UE.UTextBlock.Class())
    textBlock:SetAutoWrapText(true)
    textBlock:SetText(UE.FText(text))
    textBlock:SetJustification(UE.ETextJustify.Center)
    
    -- 灰色文字
    local textColor = UE.FLinearColor(0.5, 0.5, 0.5, 1.0)
    textBlock:SetColorAndOpacity(UE.FSlateColor(textColor))
    
    messageBorder:AddChild(textBlock)
    self.ScrollBox_Messages:AddChild(messageBorder)
    
    self:ScrollToBottom()
end

---设置处理状态
function M:SetProcessingState(isProcessing)
    self.isProcessing = isProcessing
    
    -- 更新按钮状态
    self.SendButton:SetIsEnabled(not isProcessing)
    
    -- 更新输入框状态
    self.InputBox:SetIsEnabled(not isProcessing)
    
    -- 显示/隐藏加载提示
    if self.TextBlock_Status then
        if isProcessing then
            self.TextBlock_Status:SetVisibility(UE.ESlateVisibility.Visible)
            self.TextBlock_Status:SetText(UE.FText("AI思考中..."))
        else
            self.TextBlock_Status:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

---滚动到底部
function M:ScrollToBottom()
    -- 延迟一帧执行，确保UI已更新
    UE.UKismetSystemLibrary.Delay(self, 0.01, function()
        if self.ScrollBox_Messages then
            self.ScrollBox_Messages:ScrollToEnd()
        end
    end)
end

---析构函数
function M:Destruct()
    print("[WBP_AIChat] 销毁AI聊天界面")
    
    -- 清理事件绑定
    if self.SendButton then
        self.SendButton.OnClicked:Clear()
    end
    if self.InputBox then
        self.InputBox.OnTextCommitted:Clear()
    end
end

return M


