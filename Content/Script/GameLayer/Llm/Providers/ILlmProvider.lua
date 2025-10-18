---LLM Provider接口定义
---所有Provider必须实现这些方法
---@class ILlmProvider
local ILlmProvider = {}

---构建请求体
---@param messages table 消息列表
---@param tools table|nil 工具列表
---@param config table 配置参数
---@return table 请求体
function ILlmProvider:BuildRequest(messages, tools, config)
    error("ILlmProvider:BuildRequest() must be implemented")
end

---解析响应
---@param response table 原始响应
---@return table 标准化响应 {content: string, tool_calls: table|nil, finish_reason: string}
function ILlmProvider:ParseResponse(response)
    error("ILlmProvider:ParseResponse() must be implemented")
end

---解析流式chunk
---@param chunk string 流式数据块
---@return table|nil 解析后的数据 {delta: string, finish_reason: string|nil, tool_calls: table|nil}
function ILlmProvider:ParseStreamChunk(chunk)
    error("ILlmProvider:ParseStreamChunk() must be implemented")
end

---获取API地址
---@return string API URL
function ILlmProvider:GetApiUrl()
    error("ILlmProvider:GetApiUrl() must be implemented")
end

---获取请求头
---@param apiKey string API密钥
---@return table 请求头
function ILlmProvider:GetHeaders(apiKey)
    error("ILlmProvider:GetHeaders() must be implemented")
end

---是否支持流式
---@return boolean 是否支持
function ILlmProvider:SupportsStreaming()
    return false
end

return ILlmProvider

