local BusinessModule = require("Core.DataLayerBase.BusinessModule")
local DM_LlmConfig = require("DataLayer.Llm.DM_LlmConfig")

---@class BM_LlmConfig : BusinessModule
---@type BM_LlmConfig
local BM_LlmConfig = {
    ---@type DM_LlmConfig
    dataModule = DM_LlmConfig
}

setmetatable(BM_LlmConfig, { __index = BusinessModule })

---获取完整的请求头
---@return table 请求头
function BM_LlmConfig:GetRequestHeaders()
    return {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. self.dataModule.apiKey
    }
end

---验证配置是否有效
---@return boolean, string 是否有效，错误信息
function BM_LlmConfig:ValidateConfig()
    if self.dataModule.apiKey == "" then
        return false, "API Key未设置"
    end
    
    if self.dataModule.apiUrl == "" then
        return false, "API URL未设置"
    end
    
    if self.dataModule.temperature < 0 or self.dataModule.temperature > 2 then
        return false, "Temperature参数超出范围(0-2)"
    end
    
    return true, ""
end

---预设配置：OpenAI GPT-4
function BM_LlmConfig:SetPresetOpenAI()
    self.dataModule.apiUrl = "https://api.openai.com/v1/chat/completions"
    self.dataModule.model = "gpt-4"
end

---预设配置：Claude
function BM_LlmConfig:SetPresetClaude()
    self.dataModule.apiUrl = "https://api.anthropic.com/v1/messages"
    self.dataModule.model = "claude-3-5-sonnet-20241022"
end

---预设配置：本地LLM
---@param port number 端口号
function BM_LlmConfig:SetPresetLocal(port)
    port = port or 8080
    self.dataModule.apiUrl = "http://localhost:" .. port .. "/v1/chat/completions"
    self.dataModule.model = "local-model"
end

---预设配置：阿里云通义千问
function BM_LlmConfig:SetPresetQwen()
    self.dataModule.apiUrl = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    self.dataModule.model = "qwen-max"
end

return BM_LlmConfig

