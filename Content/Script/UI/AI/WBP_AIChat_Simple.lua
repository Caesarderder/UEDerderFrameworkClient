---AI聊天界面（简化版）
---最小化实现，用于快速测试
local GameContext = require("Core.GameContext")
local Consts = require("Util.Consts")

---@type WBP_AIChat_Simple_C
local M = UnLua.Class()

function M:Construct()
    print("[WBP_AIChat_Simple] 初始化")
    
    -- 获取LLM管理器
    self.llmMgr = GameContext:GetLlmManager()
    
    -- 配置通义千问
    self.llmMgr:SetApiKey("sk-592ab9ea805f48b68940ece20b7afa39")
    self.llmMgr:UseProvider("qwen")
    
    -- 绑定按钮
    self.SendButton.OnClicked:Add(self, self.OnSendClicked)
    
    -- 初始变量
    self.currentText = ""
end

function M:OnSendClicked()
    local userInput = self.InputBox:GetText():ToString()
    if userInput == "" then return end
    
    -- 清空输入框
    self.InputBox:SetText(UE.FText(""))
    
    -- 显示用户输入
    self.ChatDisplay:SetText(UE.FText("你: " .. userInput .. "\n\nAI: "))
    
    -- 重置AI回复
    self.currentText = "你: " .. userInput .. "\n\nAI: "
    
    -- 发送到LLM（流式）
    self.llmMgr:Chat(Consts.ChatType.GENERAL_CHAT, {
        userInput = userInput
    }, function(delta)
        -- 流式回调：追加文本
        self.currentText = self.currentText .. delta
        self.ChatDisplay:SetText(UE.FText(self.currentText))
    end, function(success, fullText)
        -- 完成回调
        if not success then
            self.ChatDisplay:SetText(UE.FText("错误: " .. fullText))
        end
        print("[AI] 回复完成")
    end)
end

return M

