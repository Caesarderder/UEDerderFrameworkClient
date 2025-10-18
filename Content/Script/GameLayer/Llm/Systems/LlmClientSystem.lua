---LLM客户端系统（重构版）
---支持多Provider和流式请求
local SystemBase = require("Core.GameLayerBase.SystemBase")
local BM_LlmConfig = require("DataLayer.Llm.BM_LlmConfig")
local json = require("rapidjson")

---@class LlmClientSystem : SystemBase
---@type LlmClientSystem
local LlmClientSystem = {
    ---@type HttpClientSystem
    httpClient = nil,
    ---@type LlmProviderSystem
    providerSystem = nil,
    ---@type LlmStreamSystem
    streamSystem = nil
}
setmetatable(LlmClientSystem, { __index = SystemBase })

---初始化系统
---@param httpClient HttpClientSystem HTTP客户端
---@param providerSystem LlmProviderSystem Provider系统
---@param streamSystem LlmStreamSystem 流式处理系统
function LlmClientSystem:init(httpClient, providerSystem, streamSystem)
    self.httpClient = httpClient
    self.providerSystem = providerSystem
    self.streamSystem = streamSystem
    print("[LlmClientSystem] LLM客户端系统初始化完成")
end

---发送聊天请求（非流式）
---@param messages table 消息列表
---@param tools table|nil 工具列表
---@param config table|nil 配置参数（可选）
---@return boolean, table|string 是否成功，响应数据或错误信息
function LlmClientSystem:SendChatRequest(messages, tools, config)
    -- 验证配置
    local isValid, errorMsg = BM_LlmConfig:ValidateConfig()
    if not isValid then
        return false, errorMsg
    end
    
    -- 获取当前Provider
    local provider = self.providerSystem:GetCurrentProvider()
    if not provider then
        return false, "未找到可用的Provider"
    end
    
    -- 合并配置
    local finalConfig = {
        model = config and config.model or BM_LlmConfig.dataModule.model,
        temperature = config and config.temperature or BM_LlmConfig.dataModule.temperature,
        maxTokens = config and config.maxTokens or BM_LlmConfig.dataModule.maxTokens,
        topP = config and config.topP or BM_LlmConfig.dataModule.topP,
        stream = false
    }
    
    -- 构建请求体
    local requestBody = provider:BuildRequest(messages, tools, finalConfig)
    local bodyJson = json.encode(requestBody)
    
    -- 发送请求
    local success, response, code = self.httpClient:Post(
        provider:GetApiUrl(),
        provider:GetHeaders(BM_LlmConfig.dataModule.apiKey),
        bodyJson,
        BM_LlmConfig.dataModule.timeout
    )
    
    if not success then
        return false, "HTTP请求失败: " .. tostring(response)
    end
    
    -- 解析响应
    local responseData = json.decode(response)
    if not responseData then
        return false, "无法解析响应数据"
    end
    
    -- 使用Provider解析响应
    local parsedResponse = provider:ParseResponse(responseData)
    
    return true, parsedResponse
end

---发送流式聊天请求
---@param messages table 消息列表
---@param tools table|nil 工具列表
---@param config table|nil 配置参数
---@param onDelta function 增量回调 function(delta: string)
---@param onComplete function 完成回调 function(success: boolean, fullText: string)
function LlmClientSystem:SendStreamChatRequest(messages, tools, config, onDelta, onComplete)
    -- 验证配置
    local isValid, errorMsg = BM_LlmConfig:ValidateConfig()
    if not isValid then
        if onComplete then
            onComplete(false, errorMsg)
        end
        return
    end
    
    -- 获取当前Provider
    local provider = self.providerSystem:GetCurrentProvider()
    if not provider then
        if onComplete then
            onComplete(false, "未找到可用的Provider")
        end
        return
    end
    
    -- 检查是否支持流式
    if not provider:SupportsStreaming() then
        if onComplete then
            onComplete(false, "当前Provider不支持流式请求")
        end
        return
    end
    
    -- 合并配置
    local finalConfig = {
        model = config and config.model or BM_LlmConfig.dataModule.model,
        temperature = config and config.temperature or BM_LlmConfig.dataModule.temperature,
        maxTokens = config and config.maxTokens or BM_LlmConfig.dataModule.maxTokens,
        topP = config and config.topP or BM_LlmConfig.dataModule.topP,
        stream = true
    }
    
    -- 构建请求体
    local requestBody = provider:BuildRequest(messages, tools, finalConfig)
    local bodyJson = json.encode(requestBody)
    
    -- 重置流式系统的缓冲区
    self.streamSystem:ResetBuffer()
    
    local fullText = ""
    
    -- 发送流式请求
    self.httpClient:PostStream(
        provider:GetApiUrl(),
        provider:GetHeaders(BM_LlmConfig.dataModule.apiKey),
        bodyJson,
        function(chunk)
            -- 处理流式chunk
            self.streamSystem:ParseStream(chunk, provider, function(delta)
                fullText = fullText .. delta
                if onDelta then
                    onDelta(delta)
                end
            end, function()
                -- 流式完成
                if onComplete then
                    onComplete(true, fullText)
                end
            end)
        end,
        function(success, fullResponse, code)
            -- HTTP请求完成
            if not success then
                if onComplete then
                    onComplete(false, "HTTP请求失败: " .. tostring(fullResponse))
                end
            end
        end,
        BM_LlmConfig.dataModule.timeout
    )
end

---Tick函数，驱动HTTP协程
function LlmClientSystem:Tick(deltaTime)
    if self.httpClient and self.httpClient.Tick then
        self.httpClient:Tick(deltaTime)
    end
end

return LlmClientSystem

