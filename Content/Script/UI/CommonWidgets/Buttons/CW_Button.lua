require("LuaPanda").start("127.0.0.1",8818)

---@class CW_Button_C
local M = UnLua.Class()

--[[
    函数实现
--]]

-- Widget构造函数
function M:Construct()
    -- 初始化监听器列表
    self.clickListeners = {}
    
    -- 绑定按钮点击事件
    if self.Button then
        self.Button.OnClicked:Add(self, self.onButtonClicked)
    end

    print("Construct", self.ButtonTitleText)
    -- 如果有默认文本，设置按钮文本
    if self.ButtonTitleText then
        self:SetButtonText(self.ButtonTitleText)
        print("SetButtonText2", self.ButtonTitleText)
    end
end

-- 设置按钮文本
---@param Text string 要设置的文本
function M:SetButtonText(Text)
    print("[CW_Button] SetButtonText 被调用，文本:", Text)
    
    -- 方法1：通过 ButtonTitle 设置
    if self.ButtonTitle then
        self.ButtonTitleText = Text
        self.ButtonTitle:SetText(Text)
        print("[CW_Button] ✓ 通过ButtonTitle设置成功:", Text)
        return
    else
        print("[CW_Button] ⚠️ ButtonTitle 为 nil")
    end
    
    -- 方法2：尝试通过 Text_Button 设置（备用名称）
    if self.Text_Button then
        self.Text_Button:SetText(Text)
        print("[CW_Button] ✓ 通过Text_Button设置成功:", Text)
        return
    end
    
    -- 方法3：尝试通过 TextBlock 设置（备用名称）
    if self.TextBlock then
        self.TextBlock:SetText(Text)
        print("[CW_Button] ✓ 通过TextBlock设置成功:", Text)
        return
    end
    
    -- 方法4：尝试遍历所有子组件寻找TextBlock
    if self:GetChildrenCount() > 0 then
        print("[CW_Button] 尝试遍历子组件...")
        for i = 0, self:GetChildrenCount() - 1 do
            local child = self:GetChildAt(i)
            if child and child.SetText then
                child:SetText(Text)
                print("[CW_Button] ✓ 通过子组件设置成功:", Text)
                return
            end
        end
    end
    
    print("[CW_Button] ❌ 错误：无法设置按钮文本，所有方法都失败了")
    print("[CW_Button] 请检查蓝图中TextBlock的命名是否为ButtonTitle")
end

-- 获取按钮文本
---@return string 当前按钮文本
function M:GetButtonText()
    if self.ButtonTitle then
        return self.ButtonTitle:GetText()
    end
    return ""
end

-- 按钮点击事件处理
function M:onButtonClicked()
    print("onButtonClicked")
    for _, callback in ipairs(self.clickListeners) do
        callback()
    end
end

-- 添加点击事件监听器
---@param callback function 回调函数
function M:AddListener(callback)
    if type(callback) == "function" then
        table.insert(self.clickListeners, callback)
    end
end

-- 移除点击事件监听器
---@param callback function 要移除的回调函数
function M:RemoveListener(callback)
    for i, listener in ipairs(self.clickListeners) do
        if listener == callback then
            table.remove(self.clickListeners, i)
            break
        end
    end
end

return M