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
    
    -- 创建C++ HTTP客户端类
    local HttpClientClass = UE.UClass.Load("/Script/derderClient.HttpClient")
    if not HttpClientClass then
        print("[HttpClientSystem] ❌ 无法加载 UHttpClient 类")
        return
    end
    
    print("[HttpClientSystem] HTTP客户端系统初始化完成（使用C++ UHttpClient）")
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

---发送流式POST请求（使用C++ UHttpClient）
---@param urlStr string URL地址
---@param headers table 请求头
---@param body string 请求体
---@param onChunk function chunk回调 function(chunk: string)
---@param onComplete function 完成回调 function(success: boolean, fullResponse: string, code: number)
---@param timeout number 超时时间
function HttpClientSystem:PostStream(urlStr, headers, body, onChunk, onComplete, timeout)
    timeout = timeout or 60
    
    print("[HttpClientSystem] 发送HTTP请求:", urlStr)
    
    -- 生成请求ID
    self.requestIdCounter = self.requestIdCounter + 1
    local requestId = self.requestIdCounter
    
    -- 创建 C++ HTTP 客户端实例
    local HttpClientClass = UE.UClass.Load("/Script/derderClient.HttpClient")
    if not HttpClientClass then
        print("[HttpClientSystem] ❌ 无法加载 UHttpClient 类")
        if onComplete then
            onComplete(false, "无法加载 UHttpClient 类", 0)
        end
        return
    end
    
    -- 使用 NewObject 创建实例（不传递名字，避免 UnLua 绑定查找）
    local httpClient = UE.NewObject(HttpClientClass)
    if not httpClient then
        print("[HttpClientSystem] ❌ 无法创建 UHttpClient 实例")
        if onComplete then
            onComplete(false, "无法创建 UHttpClient 实例", 0)
        end
        return
    end
    
    print("[HttpClientSystem] ✅ 创建 UHttpClient 实例成功")
    
    -- 保存请求信息
    local requestInfo = {
        id = requestId,
        onChunk = onChunk,
        onComplete = onComplete,
        fullResponse = "",
        lastResponseLength = 0,
        startTime = os.time()
    }
    self.pendingRequests[requestId] = requestInfo
    
    -- 创建进度回调闭包（注意：第一个参数是 httpClient 对象本身，用 _ 忽略以避免覆盖外层 self）
    local function OnProgressCallback(_, BytesSent, BytesReceived)
        -- 获取当前响应内容
        local currentResponse = httpClient:GetCurrentResponse()
        
        -- 计算新增的内容
        local lastLength = requestInfo.lastResponseLength
        local currentLen = #currentResponse
        if currentLen > lastLength then
            local newChunk = string.sub(currentResponse, lastLength + 1)
            requestInfo.lastResponseLength = currentLen
            requestInfo.fullResponse = currentResponse
            
            -- 调用流式回调
            if requestInfo.onChunk then
                requestInfo.onChunk(newChunk)
            end
            
            print("[HttpClientSystem] 流式接收:", newChunk)
            print("[HttpClientSystem] 流式接收:", lastLength, "→", currentLen, "新增:", #newChunk)
        end
    end
    
    -- 创建完成回调闭包（注意：第一个参数是 httpClient 对象本身，用 _ 忽略以避免覆盖外层 self）
    local function OnCompleteCallback(_, bSuccess, ResponseContent, StatusCode)
        print("[HttpClientSystem] 请求完成, 成功:", bSuccess, "状态码:", StatusCode)
        
        -- 确保最终响应被处理
        if bSuccess and requestInfo.onChunk and #ResponseContent > requestInfo.lastResponseLength then
            local finalChunk = string.sub(ResponseContent, requestInfo.lastResponseLength + 1)
            if #finalChunk > 0 then
                requestInfo.onChunk(finalChunk)
            end
        end
        
        -- 调用完成回调
        if requestInfo.onComplete then
            requestInfo.onComplete(bSuccess, ResponseContent, StatusCode)
        end
        
        -- 清理请求
        self.pendingRequests[requestId] = nil
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
        print("[HttpClientSystem] ❌ 启动请求失败")
        if onComplete then
            onComplete(false, "启动请求失败", 0)
        end
        self.pendingRequests[requestId] = nil
    else
        print("[HttpClientSystem] ✅ 请求已发送, ID:", requestId)
    end
end

---Tick函数，驱动协程执行（保留接口，UE HTTP是异步的）
function HttpClientSystem:Tick(deltaTime)
    -- UE HTTP是完全异步的，不需要手动驱动
    -- 但保留此函数以保持接口一致
end

return HttpClientSystem
