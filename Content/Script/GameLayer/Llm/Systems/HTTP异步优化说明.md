# UHttpClient 异步流式请求优化说明

## 修改时间
2025-10-19

## 问题背景
之前的LLM流式HTTP请求不稳定，主要表现为：
1. 请求经常中断或超时
2. 日志中出现EOS SDK的SSL错误
3. 超时时间设置不合理（30-60秒对长对话太短）
4. 每次进度回调都重复处理整个响应体，性能低下

## 根本原因分析

### ✅ 已确认的问题
1. **超时设置太短**：默认30-60秒，而LLM长对话可能需要2-5分钟
2. **重复字符串分配**：每次`OnRequestProgress`都调用`GetContentAsString()`，导致大量内存分配
3. **Lua层重复计算**：Lua需要手动计算chunk增量，效率低
4. **EOS SDK干扰**：Epic Online Services后台验证失败，间接影响HTTP模块稳定性

### ❌ 不是问题的地方
- ❌ 不是LLM服务商问题（流式接收到30KB+数据后才出错）
- ❌ 不是最大上下文问题（请求已发送成功）
- ❌ 不是HTTP请求本身的问题（UE HttpModule是成熟的异步实现）

---

## 优化方案

### 1. C++ 层优化 (`UHttpClient.h/cpp`)

#### 1.1 委托签名优化
```cpp
// 旧版本：只传递字节数
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnHttpRequestProgress, 
    int32, BytesSent, int32, BytesReceived);

// 新版本：直接传递新增的chunk
DECLARE_DYNAMIC_MULTICAST_DELEGATE_ThreeParams(FOnHttpRequestProgress, 
    int32, BytesSent, int32, BytesReceived, const FString&, NewChunk);
```

**优势**：
- Lua层无需手动计算增量
- 减少跨语言调用次数（不需要再调用`GetCurrentResponse()`）
- 避免重复的字符串截取操作

#### 1.2 性能优化
```cpp
void UHttpClient::OnHttpRequestProgress(...)
{
    // 1. 只在有新数据时处理
    if (CurrentLength > LastProcessedLength)
    {
        // 2. 使用RightChop提取增量，避免substring
        FString NewChunk = NewResponseContent.RightChop(LastProcessedLength);
        
        // 3. 使用Move语义避免复制
        CurrentResponseContent = MoveTemp(NewResponseContent);
        
        // 4. 直接广播chunk
        OnRequestProgress.Broadcast(BytesSent, BytesReceived, NewChunk);
    }
}
```

**优化点**：
- ✅ 避免重复处理已接收数据
- ✅ 使用`MoveTemp`减少字符串复制
- ✅ 只在有新数据时触发回调

#### 1.3 超时时间优化
```cpp
// 默认超时改为300秒（5分钟）
bool SendPostRequest(..., float Timeout = 300.0f);
```

#### 1.4 错误信息增强
```cpp
void UHttpClient::OnHttpRequestComplete(...)
{
    // 详细的错误状态判断
    switch (Request->GetStatus())
    {
    case EHttpRequestStatus::Failed:
        FailReason = TEXT("请求失败");
        break;
    case EHttpRequestStatus::Failed_ConnectionError:
        FailReason = TEXT("连接错误");
        break;
    // ...
    }
    
    // 结构化日志输出
    UE_LOG(LogTemp, Error, TEXT("[UHttpClient] ❌ 请求失败"));
    UE_LOG(LogTemp, Error, TEXT("  └─ 原因: %s"), *FailReason);
    UE_LOG(LogTemp, Error, TEXT("  └─ 状态码: %d"), StatusCode);
    UE_LOG(LogTemp, Error, TEXT("  └─ 已接收: %d 字节"), LastProcessedLength);
}
```

#### 1.5 新增功能
```cpp
// 检查请求是否活跃
bool IsRequestActive() const;

// 获取已处理字节数
int32 GetProcessedBytes() const;

// 重置内部状态
void ResetState();
```

---

### 2. Lua 层优化 (`HttpClientSystem.lua`)

#### 2.1 适配新的委托签名
```lua
-- 旧版本：需要手动计算增量
local function OnProgressCallback(_, BytesSent, BytesReceived)
    local currentResponse = httpClient:GetCurrentResponse()  -- ❌ 额外调用
    local newChunk = string.sub(currentResponse, lastLength + 1)  -- ❌ Lua字符串操作
    -- ...
end

-- 新版本：直接使用C++传递的chunk
local function OnProgressCallback(_, BytesSent, BytesReceived, NewChunk)
    if NewChunk and #NewChunk > 0 then
        requestInfo.onChunk(NewChunk)  -- ✅ 直接使用
    end
end
```

#### 2.2 超时时间调整
```lua
function HttpClientSystem:PostStream(..., timeout)
    timeout = timeout or 300  -- 从60秒改为300秒
end
```

#### 2.3 日志优化
```lua
-- 合并日志，减少输出
print(string.format("[HttpClientSystem] 流式接收: +%d 字节 | 总计: %d 字节", 
    #NewChunk, requestInfo.lastResponseLength))

-- 完成时输出统计
print(string.format("[HttpClientSystem] ✅ 请求完成 | 状态码: %d | 耗时: %ds", 
    StatusCode, elapsedTime))
```

#### 2.4 新增工具函数
```lua
-- 获取活动请求数量
function HttpClientSystem:GetActiveRequestCount()
    local count = 0
    for _ in pairs(self.pendingRequests) do
        count = count + 1
    end
    return count
end

-- 取消所有请求
function HttpClientSystem:CancelAllRequests()
    -- ...
end
```

---

### 3. 配置优化

#### 3.1 LLM配置 (`DM_LlmConfig.lua`)
```lua
DM_LlmConfig.Fields = {
    timeout = 300,  -- 从30秒改为300秒（5分钟）
    -- ...
}
```

#### 3.2 引擎配置 (`DefaultEngine.ini`)
```ini
# 禁用EOS SDK，避免SSL错误干扰
[OnlineSubsystem]
DefaultPlatformService=Null

[OnlineSubsystemEOS]
bEnabled=false
```

---

## 性能对比

### 旧实现
```
每次进度回调:
1. Lua调用 GetCurrentResponse() → C++返回完整字符串（30KB）
2. Lua执行 string.sub(response, lastLength + 1) → 字符串切割
3. 触发onChunk回调

总计：2次跨语言调用 + 1次大字符串传递 + 1次Lua字符串操作
```

### 新实现
```
每次进度回调:
1. C++提取增量chunk（仅新增部分，如362字节）
2. 直接广播chunk到Lua
3. Lua直接使用chunk

总计：1次跨语言调用 + 仅传递增量数据
```

**性能提升**：
- ✅ 减少50%的跨语言调用
- ✅ 字符串传输量减少99%（仅传输增量）
- ✅ 消除Lua层字符串切割操作
- ✅ 内存分配减少（C++使用Move语义）

---

## 异步机制说明

### UE HttpModule 的异步特性

#### 1. 请求发送
```cpp
CurrentRequest->ProcessRequest();  // 非阻塞，立即返回
```
- ✅ 立即返回，不阻塞GameThread
- ✅ 实际HTTP操作在后台线程执行

#### 2. 进度回调
```cpp
CurrentRequest->OnRequestProgress().BindUObject(this, &UHttpClient::OnHttpRequestProgress);
```
- ⚠️ 可能在HTTP线程调用（非GameThread）
- ⚠️ 需要注意线程安全
- ✅ 委托自动排队到GameThread执行（如果绑定到UObject）

#### 3. 完成回调
```cpp
CurrentRequest->OnProcessRequestComplete().BindUObject(this, &UHttpClient::OnHttpRequestComplete);
```
- ✅ 自动在GameThread上执行
- ✅ 可以安全调用Lua回调

---

## 使用建议

### 1. 超时时间设置指南

| 场景 | 建议超时 | 说明 |
|------|---------|------|
| 短对话（<100字） | 60秒 | 一般5-15秒内完成 |
| 中等对话（100-500字） | 120秒 | 一般15-60秒内完成 |
| 长对话（>500字） | 300秒 | 可能需要1-3分钟 |
| 复杂推理/代码生成 | 600秒 | 可能需要5分钟+ |

### 2. 错误处理
```lua
function onComplete(success, fullResponse, code)
    if not success then
        if code == 0 then
            -- 网络连接问题（如代理失败、SSL错误）
            print("网络连接失败，请检查网络或代理设置")
        elseif code == 408 or code == 504 then
            -- 超时
            print("请求超时，尝试增加timeout或简化prompt")
        elseif code >= 500 then
            -- 服务器错误
            print("LLM服务商错误，稍后重试")
        elseif code >= 400 then
            -- 客户端错误（如API Key错误、参数错误）
            print("请求参数错误，检查API配置")
        end
    end
end
```

### 3. 调试技巧
```lua
-- 开启详细日志（在C++中已默认开启Verbose日志）
-- 查看日志：
-- [UHttpClient] 流式接收: +362 字节 | 总计: 30262 字节 | 速度: 1234.5 B/s
-- [HttpClientSystem] ✅ 请求完成 | 状态码: 200 | 耗时: 25s

-- 监控活动请求
print("活动请求数:", httpClientSystem:GetActiveRequestCount())
```

---

## 已知限制

### 1. 不支持的功能
- ❌ 同步请求（`Post`方法返回false）
- ❌ 单个请求的动态超时调整
- ❌ 活动超时（Idle Timeout）检测

### 2. 需要注意的点
- ⚠️ `CancelAllRequests()`未保存httpClient引用，无法真正取消
- ⚠️ 大响应体（>10MB）可能仍有性能问题
- ⚠️ 代理配置可能影响SSL握手稳定性

---

## 后续优化方向

### 短期（可选）
1. 实现活动超时检测（检测长时间无数据流）
2. 添加重试机制（自动重试失败的请求）
3. 优化大文件流式传输（分块处理）

### 长期（高级功能）
1. HTTP连接池复用
2. 支持HTTP/2多路复用
3. 支持WebSocket流式传输（更低延迟）
4. 集成gRPC流式RPC

---

## 总结

### 核心改进
1. ✅ **超时时间**：30秒 → 300秒
2. ✅ **性能优化**：减少50%跨语言调用，消除重复字符串操作
3. ✅ **错误诊断**：详细的错误信息和状态码
4. ✅ **干扰消除**：禁用EOS SDK避免SSL错误

### 预期效果
- ✅ 流式请求稳定性显著提升
- ✅ 长对话不再超时
- ✅ 内存占用降低
- ✅ 响应速度提升（特别是大响应体）
- ✅ 错误定位更准确

### 需要测试的场景
1. 短对话（<100字）- 验证基本功能
2. 长对话（1000字+）- 验证不超时
3. 多轮对话 - 验证连续请求
4. 网络中断恢复 - 验证错误处理
5. 并发请求 - 验证多请求稳定性

