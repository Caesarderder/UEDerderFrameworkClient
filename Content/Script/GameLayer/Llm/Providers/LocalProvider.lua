---本地LLM Provider实现（兼容OpenAI格式）
local OpenAIProvider = require("GameLayer.Llm.Providers.OpenAIProvider")

---@class LocalProvider : OpenAIProvider
local LocalProvider = {}
setmetatable(LocalProvider, { __index = OpenAIProvider })

function LocalProvider:new(host, port)
    local instance = {}
    setmetatable(instance, { __index = self })
    instance.host = host or "localhost"
    instance.port = port or 8080
    return instance
end

---获取API地址（本地地址）
function LocalProvider:GetApiUrl()
    return string.format("http://%s:%d/v1/chat/completions", self.host, self.port)
end

---获取请求头（本地模型可能不需要认证）
function LocalProvider:GetHeaders(apiKey)
    local headers = {
        ["Content-Type"] = "application/json"
    }
    
    -- 如果提供了API密钥，也加上（某些本地服务可能需要）
    if apiKey and apiKey ~= "" then
        headers["Authorization"] = "Bearer " .. apiKey
    end
    
    return headers
end

return LocalProvider


