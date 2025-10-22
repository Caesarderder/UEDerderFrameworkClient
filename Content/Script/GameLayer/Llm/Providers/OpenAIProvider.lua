---OpenAI Provider实现
local ILlmProvider = require("GameLayer.Llm.Providers.ILlmProvider")
local json = require("rapidjson")

---@class OpenAIProvider : ILlmProvider
local OpenAIProvider = {}
setmetatable(OpenAIProvider, { __index = ILlmProvider })

function OpenAIProvider:new()
    local instance = {}
    setmetatable(instance, { __index = self })
    return instance
end

---构建请求体
function OpenAIProvider:BuildRequest(messages, tools, config)
    local request = {
        model = config.model or "gpt-4",
        messages = messages,
        temperature = config.temperature or 0.7,
        max_tokens = config.maxTokens or 2000,
        top_p = config.topP or 1.0,
        stream = config.stream or false
    }
    
    -- 添加工具定义
    if tools and #tools > 0 then
        request.tools = tools
        request.tool_choice = "auto"
    end
    
    return request
end

---解析响应
function OpenAIProvider:ParseResponse(response)
    if not response.choices or #response.choices == 0 then
        return {
            content = "",
            tool_calls = nil,
            finish_reason = "error"
        }
    end
    
    local choice = response.choices[1]
    local message = choice.message
    
    return {
        content = message.content or "",
        tool_calls = message.tool_calls,
        finish_reason = choice.finish_reason
    }
end

---解析流式chunk
function OpenAIProvider:ParseStreamChunk(chunk)
    -- 移除 "data: " 前缀
    if string.sub(chunk, 1, 6) == "data: " then
        chunk = string.sub(chunk, 7)
    end
    
    -- 检查结束标记
    if chunk == "[DONE]" then
        return {
            delta = "",
            finish_reason = "stop",
            done = true
        }
    end
    
    -- 解析JSON
    local success, data = pcall(json.decode, chunk)
    if not success or not data then
        return nil
    end
    
    if not data.choices or #data.choices == 0 then
        return nil
    end
    
    local choice = data.choices[1]
    local delta = choice.delta
    
    -- 确保 delta.content 是字符串类型
    local content = ""
    if delta.content then
        if type(delta.content) == "string" then
            content = delta.content
        elseif type(delta.content) == "userdata" then
            -- 如果是 userdata，尝试转换为字符串
            content = tostring(delta.content)
        end
    end
    
    local result = {
        delta = content,
        finish_reason = choice.finish_reason,
        tool_calls = delta.tool_calls
    }
    
    return result
end

---获取API地址
function OpenAIProvider:GetApiUrl()
    return "https://api.openai.com/v1/chat/completions"
end

---获取请求头
function OpenAIProvider:GetHeaders(apiKey)
    return {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. apiKey
    }
end

---是否支持流式
function OpenAIProvider:SupportsStreaming()
    return true
end

return OpenAIProvider


