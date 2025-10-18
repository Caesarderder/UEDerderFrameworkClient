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
        print("SetButtonText", self.ButtonTitleText)
    end
end

-- 设置按钮文本
---@param Text string 要设置的文本
function M:SetButtonText(Text)
    if self.ButtonTitle then
        self.ButtonTitle:SetText(Text)
    end
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