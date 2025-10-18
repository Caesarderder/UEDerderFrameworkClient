--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type CW_InputText_C
local M = UnLua.Class()

-- 确保 sendListeners 已初始化（惰性初始化）
local function ensureSendListeners(self)
    if not self.sendListeners then
        self.sendListeners = {}
    end
end

-- Widget构造函数
function M:Construct()
    -- 初始化发送事件监听器列表
    ensureSendListeners(self)
    
    -- 绑定发送按钮点击事件
    if self.Button_Send then
        self.Button_Send:AddListener(function()
            self:OnSendButtonClicked()
        end)
    end
end

-- 发送按钮点击事件处理
function M:OnSendButtonClicked()
    -- 确保 sendListeners 已初始化
    ensureSendListeners(self)
    
    -- 获取输入框的文本内容
    local inputText = ""
    if self.EText_Input then
        inputText = self.EText_Input:GetText()
    end
    
    -- 调用所有注册的监听器，将文本内容传递出去
    for _, callback in ipairs(self.sendListeners) do
        callback(inputText)
    end
    
    -- 清空输入框（可选，根据需求决定是否保留）
    if self.EText_Input then
        self.EText_Input:SetText("")
    end
end

-- 添加发送事件监听器
---@param callback function 回调函数，参数为输入的文本内容
function M:AddSendListener(callback)
    -- 确保 sendListeners 已初始化（重要！支持在 OnInitialized 等早期生命周期调用）
    ensureSendListeners(self)
    
    if type(callback) == "function" then
        table.insert(self.sendListeners, callback)
    end
end

-- 移除发送事件监听器
---@param callback function 要移除的回调函数
function M:RemoveSendListener(callback)
    -- 确保 sendListeners 已初始化
    ensureSendListeners(self)
    
    for i, listener in ipairs(self.sendListeners) do
        if listener == callback then
            table.remove(self.sendListeners, i)
            break
        end
    end
end

-- 获取当前输入框的文本
---@return string 当前输入框的文本
function M:GetInputText()
    if self.EText_Input then
        return self.EText_Input:GetText()
    end
    return ""
end

-- 设置输入框的文本
---@param text string 要设置的文本
function M:SetInputText(text)
    if self.EText_Input then
        self.EText_Input:SetText(text)
    end
end

--function M:PreConstruct(IsDesignTime)
--end

--function M:Tick(MyGeometry, InDeltaTime)
--end

return M
