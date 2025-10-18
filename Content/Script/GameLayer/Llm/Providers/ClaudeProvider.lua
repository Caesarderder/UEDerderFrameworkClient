---Claude Provider实现
local ILlmProvider = require("GameLayer.Llm.Providers.ILlmProvider")
local json = require("rapidjson")

---@class ClaudeProvider : ILlmProvider
local ClaudeProvider = {}
setmetatable(ClaudeProvider, { __index = ILlmProvider })

function ClaudeProvider:new()
    local instance = {}
    setmetatable(instance, { __index = self })
    return instance
end

---构建请求体（Claude格式）
function ClaudeProvider:BuildRequest(messages, tools, config)
    -- Claude需要分离system消息
    local systemMessages = {}
    local conversationMessages = {}
    
    for _, msg in ipairs(messages) do
        if msg.role == "system" then
            table.insert(systemMessages, msg.content)
        else
            table.insert(conversationMessages, msg)
        end
    end
    
    local request = {
        model = config.model or "claude-3-5-sonnet-20241022",
        messages = conversationMessages,
        max_tokens = config.maxTokens or 2000,
        temperature = config.temperature or 0.7,
        top_p = config.topP or 1.0,
        stream = config.stream or false
    }
    
    -- 合并system消息
    if #systemMessages > 0 then
        request.system = table.concat(systemMessages, "\n\n")
    end
    
    -- 添加工具定义（Claude使用tools字段）
    if tools and #tools > 0 then
        request.tools = self:ConvertToolsToClaude(tools)
    end
    
    return request
end

---转换OpenAI格式的工具为Claude格式
function ClaudeProvider:ConvertToolsToClaude(tools)
    local claudeTools = {}
    
    for _, tool in ipairs(tools) do
        if tool["function"] then
            table.insert(claudeTools, {
                name = tool["function"].name,
                description = tool["function"].description,
                input_schema = tool["function"].parameters
            })
        end
    end
    
    return claudeTools
end

---解析响应
function ClaudeProvider:ParseResponse(response)
    if not response.content or #response.content == 0 then
        return {
            content = "",
            tool_calls = nil,
            finish_reason = "error"
        }
    end
    
    local content = ""
    local tool_calls = {}
    
    -- Claude的响应可能包含多个content块
    for _, block in ipairs(response.content) do
        if block.type == "text" then
            content = content .. block.text
        elseif block.type == "tool_use" then
            -- 转换为OpenAI格式的tool_call
            table.insert(tool_calls, {
                id = block.id,
                type = "function",
                ["function"] = {
                    name = block.name,
                    arguments = json.encode(block.input)
                }
            })
        end
    end
    
    return {
        content = content,
        tool_calls = (#tool_calls > 0) and tool_calls or nil,
        finish_reason = response.stop_reason
    }
end

---解析流式chunk
function ClaudeProvider:ParseStreamChunk(chunk)
    -- Claude的流式格式：每行一个事件
    local success, data = pcall(json.decode, chunk)
    if not success or not data then
        return nil
    end
    
    local eventType = data.type
    
    if eventType == "content_block_delta" then
        local delta = data.delta
        if delta.type == "text_delta" then
            return {
                delta = delta.text or "",
                finish_reason = nil
            }
        elseif delta.type == "input_json_delta" then
            -- 工具调用的增量
            return {
                delta = "",
                tool_calls = delta.partial_json
            }
        end
    elseif eventType == "message_delta" then
        return {
            delta = "",
            finish_reason = data.delta.stop_reason
        }
    elseif eventType == "message_stop" then
        return {
            delta = "",
            finish_reason = "stop",
            done = true
        }
    end
    
    return nil
end

---获取API地址
function ClaudeProvider:GetApiUrl()
    return "https://api.anthropic.com/v1/messages"
end

---获取请求头
function ClaudeProvider:GetHeaders(apiKey)
    return {
        ["Content-Type"] = "application/json",
        ["x-api-key"] = apiKey,
        ["anthropic-version"] = "2023-06-01"
    }
end

---是否支持流式
function ClaudeProvider:SupportsStreaming()
    return true
end

return ClaudeProvider

