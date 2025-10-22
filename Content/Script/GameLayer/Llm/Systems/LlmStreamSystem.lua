---LLM流式响应处理系统
local SystemBase = require("Core.GameLayerBase.SystemBase")

---@class LlmStreamSystem : SystemBase
---@type LlmStreamSystem
local LlmStreamSystem = {}
setmetatable(LlmStreamSystem, { __index = SystemBase })

---初始化系统
function LlmStreamSystem:init()
    self.buffer = ""  -- 缓冲区，用于处理不完整的chunk
    self.toolCallsBuffer = {}  -- 工具调用缓冲区
    self.isToolCalling = false  -- 是否正在进行工具调用
    print("[LlmStreamSystem] 流式处理系统初始化完成")
end

---解析SSE格式的流式数据（OpenAI格式）
---@param chunk string 原始chunk数据
---@param provider table Provider实例
---@param onDelta function 增量回调 function(delta: string)
---@param onComplete function 完成回调 function()
---@param onToolCall function|nil 工具调用回调 function(toolCalls: table)
function LlmStreamSystem:ParseSSEStream(chunk, provider, onDelta, onComplete, onToolCall)
    -- 将chunk添加到缓冲区
    self.buffer = self.buffer .. chunk
    
    -- 按行分割
    local lines = {}
    for line in string.gmatch(self.buffer, "([^\n]*)\n") do
        table.insert(lines, line)
    end
    
    -- 保留最后一行（可能不完整）
    local lastNewline = string.find(self.buffer, "\n[^\n]*$")
    if lastNewline then
        self.buffer = string.sub(self.buffer, lastNewline + 1)
    end
    
    -- 处理每一行
    for _, line in ipairs(lines) do
        -- 移除回车符
        line = string.gsub(line, "\r", "")
        
        -- SSE格式：data: {...}
        if string.sub(line, 1, 6) == "data: " then
            local data = string.sub(line, 7)
            
            -- 检查结束标记
            if data == "[DONE]" then
                if onComplete then
                    onComplete()
                end
                self.buffer = ""
                return
            end
            
            -- 解析chunk
            local parsed = provider:ParseStreamChunk(data)
            if parsed then
                -- 处理工具调用
                if parsed.tool_calls then
                    self.isToolCalling = true
                    self:AccumulateToolCalls(parsed.tool_calls)
                -- 处理文本内容（只有在非工具调用时才显示）
                elseif parsed.delta and parsed.delta ~= "" and not self.isToolCalling then
                    if onDelta then
                        onDelta(parsed.delta)
                    end
                end
                
                -- 检查finish_reason（完成）
                if parsed.finish_reason and type(parsed.finish_reason) == "string" and parsed.finish_reason ~= "" then
                    -- 如果有工具调用，执行工具
                    if self.isToolCalling and onToolCall then
                        onToolCall(self.toolCallsBuffer)
                    end
                    
                    if onComplete then
                        onComplete()
                    end
                    self.buffer = ""
                    self:ResetToolCallsBuffer()
                    return
                end
            end
        end
    end
end

---解析流式JSON（Claude格式）
---@param chunk string 原始chunk数据
---@param provider table Provider实例
---@param onDelta function 增量回调
---@param onComplete function 完成回调
function LlmStreamSystem:ParseStreamJSON(chunk, provider, onDelta, onComplete)
    -- 将chunk添加到缓冲区
    self.buffer = self.buffer .. chunk
    
    -- 按行分割JSON
    local lines = {}
    for line in string.gmatch(self.buffer, "([^\n]*)\n") do
        table.insert(lines, line)
    end
    
    -- 保留最后一行（可能不完整）
    local lastNewline = string.find(self.buffer, "\n[^\n]*$")
    if lastNewline then
        self.buffer = string.sub(self.buffer, lastNewline + 1)
    end
    
    -- 处理每一行
    for _, line in ipairs(lines) do
        -- 移除回车符
        line = string.gsub(line, "\r", "")
        
        if line ~= "" then
            -- 解析chunk
            local parsed = provider:ParseStreamChunk(line)
            if parsed then
                if parsed.delta and parsed.delta ~= "" then
                    if onDelta then
                        onDelta(parsed.delta)
                    end
                end
                
                -- 检查是否真正完成（排除JSON null）
                local isDone = parsed.done == true
                local hasFinishReason = parsed.finish_reason and type(parsed.finish_reason) == "string" and parsed.finish_reason ~= ""
                
                if isDone or hasFinishReason then
                    if onComplete then
                        onComplete()
                    end
                    self.buffer = ""
                    return
                end
            end
        end
    end
end

---根据Provider类型自动选择解析方式
---@param chunk string 原始chunk数据
---@param provider table Provider实例
---@param onDelta function 增量回调
---@param onComplete function 完成回调
---@param onToolCall function|nil 工具调用回调
function LlmStreamSystem:ParseStream(chunk, provider, onDelta, onComplete, onToolCall)
    -- 根据provider类型选择解析方式
    local providerName = provider.GetApiUrl and provider:GetApiUrl() or ""
    
    if string.find(providerName, "anthropic") then
        -- Claude格式
        self:ParseStreamJSON(chunk, provider, onDelta, onComplete)
    else
        -- OpenAI格式（默认）
        self:ParseSSEStream(chunk, provider, onDelta, onComplete, onToolCall)
    end
end

---累积工具调用参数
---@param toolCalls table 工具调用增量数据
function LlmStreamSystem:AccumulateToolCalls(toolCalls)
    for _, toolCall in ipairs(toolCalls) do
        -- 注意：OpenAI的index从0开始，转换为Lua的1开始
        local index = (toolCall.index or 0) + 1
        
        -- 初始化buffer槽位
        if not self.toolCallsBuffer[index] then
            self.toolCallsBuffer[index] = {
                id = "",
                type = "function",
                ["function"] = {
                    name = "",
                    arguments = ""
                }
            }
        end
        
        -- 累积数据（确保类型转换为Lua字符串）
        if toolCall.id and toolCall.id ~= "" then
            self.toolCallsBuffer[index].id = tostring(toolCall.id)
        end
        
        if toolCall["function"] then
            local func = toolCall["function"]
            if func.name and func.name ~= "" then
                self.toolCallsBuffer[index]["function"].name = tostring(func.name)
            end
            if func.arguments and func.arguments ~= "" then
                -- 确保都是字符串类型再连接
                local existingArgs = tostring(self.toolCallsBuffer[index]["function"].arguments or "")
                local newArgs = tostring(func.arguments)
                self.toolCallsBuffer[index]["function"].arguments = existingArgs .. newArgs
            end
        end
        
        -- 安全的日志输出
        local funcName = tostring(self.toolCallsBuffer[index]["function"].name or "")
        local funcArgs = tostring(self.toolCallsBuffer[index]["function"].arguments or "")
        print(string.format("[LlmStreamSystem] 累积工具调用 #%d: %s, 参数长度: %d", 
            index, 
            funcName,
            #funcArgs
        ))
    end
end

---重置缓冲区
function LlmStreamSystem:ResetBuffer()
    self.buffer = ""
end

---重置工具调用缓冲区
function LlmStreamSystem:ResetToolCallsBuffer()
    self.toolCallsBuffer = {}
    self.isToolCalling = false
end

return LlmStreamSystem

