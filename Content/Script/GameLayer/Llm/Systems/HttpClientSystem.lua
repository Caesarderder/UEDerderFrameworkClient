---HTTP客户端系统（使用C++ UHttpClient）
---支持同步和流式异步请求
local SystemBase = require("Core.GameLayerBase.SystemBase")

---@class HttpClientSystem : SystemBase
---@type HttpClientSystem
local HttpClientSystem = {}
setmetatable(HttpClientSystem, { __index = SystemBase })

---初始化系统
function HttpClientSystem:init()
    -- 初始化请求列表
    self.pendingRequests = {}
    self.requestIdCounter = 0
    
    print("[HttpClientSystem] HTTP客户端系统初始化完成")
end

---发送同步POST请求
---@param urlStr string URL地址
---@param headers table 请求头
---@param body string 请求体
---@param timeout number 超时时间
---@return boolean, any, number 是否成功，响应内容，HTTP状态码
function HttpClientSystem:Post(urlStr, headers, body, timeout)
    timeout = timeout or 30
    
    print("[HttpClientSystem] 同步POST请求暂不支持，请使用PostStream")
    return false, "同步请求暂不支持", 0
end

---发送流式POST请求（使用C++ UHttpClient，完全异步）
---@param urlStr string URL地址
---@param headers table 请求头
---@param body string 请求体
---@param onChunk function chunk回调 function(chunk: string)
---@param onComplete function 完成回调 function(success: boolean, fullResponse: string, code: number)
---@param timeout number 超时时间（默认300秒，适合LLM长对话）
function HttpClientSystem:PostStream(urlStr, headers, body, onChunk, onComplete, timeout)
    timeout = timeout or 300  -- 增加默认超时到5分钟
    
    print("[HttpClientSystem] 发送异步流式请求:", urlStr)
    
    -- 生成请求ID
    self.requestIdCounter = self.requestIdCounter + 1
    local requestId = self.requestIdCounter
    
    -- 尝试加载 C++ 类（使用 LoadClass）
    local HttpClientClass = UE.UClass.Load("/Script/derderClient.HttpClient")
    if not HttpClientClass then
        print("[HttpClientSystem] [ERROR] 无法加载 HttpClient 类，请检查 C++ 代码是否已编译")
        if onComplete then
            onComplete(false, "无法加载 HttpClient 类", 0)
        end
        return
    end
    
    -- 使用 NewObject 创建实例（不传递 Outer，默认使用 TransientPackage）
    local httpClient = UE.NewObject(HttpClientClass)
    if not httpClient then
        print("[HttpClientSystem] [ERROR] 无法创建 HttpClient 实例")
        if onComplete then
            onComplete(false, "无法创建 HttpClient 实例", 0)
        end
        return
    end
    
    print("[HttpClientSystem] [OK] 创建 HttpClient 实例成功")
    
    -- 保存请求信息
    local requestInfo = {
        id = requestId,
        httpClient = httpClient,  -- 保存引用，用于检测和取消
        onChunk = onChunk,
        onComplete = onComplete,
        fullResponse = "",
        lastResponseLength = 0,
        startTime = os.time(),
        lastActivityTime = os.time(),  -- 最后活动时间
        chunkCount = 0  -- 接收的chunk数量
    }
    self.pendingRequests[requestId] = requestInfo
    
    -- 创建进度回调闭包（注意：第一个参数是 httpClient 对象本身，用 _ 忽略以避免覆盖外层 self）
    -- C++ 委托签名：FOnHttpRequestProgress(int32 BytesSent, int32 BytesReceived, const FString& NewChunk)
    local function OnProgressCallback(_, BytesSent, BytesReceived, NewChunk)
        -- 更新活动时间
        requestInfo.lastActivityTime = os.time()
        requestInfo.chunkCount = requestInfo.chunkCount + 1
        
        -- 直接使用C++传递的NewChunk，无需手动计算增量
        if NewChunk and #NewChunk > 0 then
            -- 更新状态
            requestInfo.lastResponseLength = requestInfo.lastResponseLength + #NewChunk
            requestInfo.fullResponse = requestInfo.fullResponse .. NewChunk
            
            -- 调用流式回调
            if requestInfo.onChunk then
                local success, err = pcall(requestInfo.onChunk, NewChunk)
                if not success then
                    print(string.format("[HttpClientSystem] [ERROR] onChunk回调失败: %s", tostring(err)))
                end
            end
            
            -- 详细日志
            local elapsed = os.time() - requestInfo.startTime
            print(string.format("[HttpClientSystem] 流式接收 #%d: +%d 字节 | 总计: %d 字节 | 耗时: %ds", 
                requestInfo.chunkCount, #NewChunk, requestInfo.lastResponseLength, elapsed))
            print(string.format("[HttpClientSystem] 流式接收 NewChunk: %s", NewChunk))
        end
    end
    
    -- 创建完成回调闭包（注意：第一个参数是 httpClient 对象本身，用 _ 忽略以避免覆盖外层 self）
    local function OnCompleteCallback(_, bSuccess, ResponseContent, StatusCode)
        local elapsedTime = os.time() - requestInfo.startTime
        
        if bSuccess then
            print(string.format("[HttpClientSystem] [OK] 请求完成 | 状态码: %d | 耗时: %ds | 接收 %d chunks", 
                StatusCode, elapsedTime, requestInfo.chunkCount))
        else
            print(string.format("[HttpClientSystem] [FAIL] 请求失败 | 状态码: %d | 耗时: %ds | 已接收: %d 字节 (%d chunks)", 
                StatusCode, elapsedTime, requestInfo.lastResponseLength, requestInfo.chunkCount))
            
            -- 如果有部分数据，输出最后接收的内容
            if requestInfo.lastResponseLength > 0 then
                print(string.format("[HttpClientSystem] [DEBUG] 最后接收时间: %ds 前", 
                    os.time() - requestInfo.lastActivityTime))
            end
        end
        
        -- 调用完成回调（C++已确保所有chunk都已触发）
        if requestInfo.onComplete then
            local success, err = pcall(requestInfo.onComplete, bSuccess, ResponseContent, StatusCode)
            if not success then
                print(string.format("[HttpClientSystem] [ERROR] onComplete回调失败: %s", tostring(err)))
            end
        end
        
        -- 清理请求
        self.pendingRequests[requestId] = nil
        
        -- 输出统计
        print(string.format("[HttpClientSystem] 请求 #%d 完成，剩余活动请求: %d", 
            requestId, self:GetActiveRequestCount()))
    end
    
    -- 绑定回调（使用 httpClient 作为接收者，传递函数）
    httpClient.OnRequestProgress:Add(httpClient, OnProgressCallback)
    httpClient.OnRequestComplete:Add(httpClient, OnCompleteCallback)
    
    -- 格式化请求头（转换为字符串格式："Key1=Value1|Key2=Value2"）
    local headersStr = ""
    for key, value in pairs(headers) do
        if headersStr ~= "" then
            headersStr = headersStr .. "|"
        end
        headersStr = headersStr .. key .. "=" .. value
    end
    
    print("[HttpClientSystem] 请求头:", headersStr)
    print("[HttpClientSystem] 请求体长度:", #body)
    
    -- 发送请求
    local bStarted = httpClient:SendPostRequest(urlStr, headersStr, body, timeout)
    
    if not bStarted then
        print("[HttpClientSystem] [ERROR] 启动请求失败")
        if onComplete then
            onComplete(false, "启动请求失败", 0)
        end
        self.pendingRequests[requestId] = nil
    else
        print("[HttpClientSystem] [OK] 请求已发送, ID:", requestId)
    end
end

---Tick函数，驱动协程执行（保留接口，UE HTTP是异步的）
function HttpClientSystem:Tick(deltaTime)
    -- UE HTTP是完全异步的，不需要手动驱动
    -- 但用于定期检查请求健康状态
    
    if not self.lastHealthCheckTime then
        self.lastHealthCheckTime = os.time()
    end
    
    -- 每10秒检查一次健康状态
    local currentTime = os.time()
    if currentTime - self.lastHealthCheckTime >= 10 then
        self.lastHealthCheckTime = currentTime
        
        local activeCount = self:GetActiveRequestCount()
        if activeCount > 0 then
            local timeoutCount = self:CheckRequestHealth(60)  -- 60秒空闲超时
            if timeoutCount > 0 then
                print(string.format("[HttpClientSystem] 检测到 %d 个超时请求已取消", timeoutCount))
            end
        end
    end
end

---获取活动请求数量
---@return number 活动请求数量
function HttpClientSystem:GetActiveRequestCount()
    local count = 0
    for _ in pairs(self.pendingRequests) do
        count = count + 1
    end
    return count
end

---取消所有活动请求
function HttpClientSystem:CancelAllRequests()
    local count = 0
    for requestId, requestInfo in pairs(self.pendingRequests) do
        print("[HttpClientSystem] 取消请求 #" .. requestId)
        if requestInfo.httpClient then
            requestInfo.httpClient:CancelRequest()
        end
        count = count + 1
    end
    self.pendingRequests = {}
    print(string.format("[HttpClientSystem] 已取消 %d 个请求", count))
end

---检查活动请求的健康状态（检测超时）
---@param idleTimeout number 活动超时时间（秒，默认60秒）
function HttpClientSystem:CheckRequestHealth(idleTimeout)
    idleTimeout = idleTimeout or 60
    local currentTime = os.time()
    local timeoutRequests = {}
    
    for requestId, requestInfo in pairs(self.pendingRequests) do
        local idleTime = currentTime - requestInfo.lastActivityTime
        local totalTime = currentTime - requestInfo.startTime
        
        if idleTime > idleTimeout then
            print(string.format("[HttpClientSystem] [WARNING] 请求 #%d 活动超时 (空闲 %ds, 总计 %ds, 已接收 %d 字节)", 
                requestId, idleTime, totalTime, requestInfo.lastResponseLength))
            table.insert(timeoutRequests, requestId)
        elseif totalTime > 300 then  -- 总超时
            print(string.format("[HttpClientSystem] [WARNING] 请求 #%d 总超时 (总计 %ds, 已接收 %d 字节)", 
                requestId, totalTime, requestInfo.lastResponseLength))
            table.insert(timeoutRequests, requestId)
        end
    end
    
    -- 取消超时的请求
    for _, requestId in ipairs(timeoutRequests) do
        local requestInfo = self.pendingRequests[requestId]
        if requestInfo then
            if requestInfo.httpClient then
                requestInfo.httpClient:CancelRequest()
            end
            if requestInfo.onComplete then
                requestInfo.onComplete(false, "请求超时（空闲时间过长）", 0)
            end
            self.pendingRequests[requestId] = nil
        end
    end
    
    return #timeoutRequests
end

return HttpClientSystem
