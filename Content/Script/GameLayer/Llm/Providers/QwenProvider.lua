---阿里云通义千问Provider实现
---基于OpenAI兼容格式
local OpenAIProvider = require("GameLayer.Llm.Providers.OpenAIProvider")

---@class QwenProvider : OpenAIProvider
local QwenProvider = {}
setmetatable(QwenProvider, { __index = OpenAIProvider })

function QwenProvider:new()
    local instance = {}
    setmetatable(instance, { __index = self })
    return instance
end

---获取API地址（通义千问）
function QwenProvider:GetApiUrl()
    return "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
end

---获取请求头（通义千问使用Bearer Token）
function QwenProvider:GetHeaders(apiKey)
    return {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. apiKey
    }
end

---是否支持流式
function QwenProvider:SupportsStreaming()
    return true
end

return QwenProvider

