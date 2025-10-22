// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/NoExportTypes.h"
#include "HttpModule.h"
#include "Interfaces/IHttpRequest.h"
#include "Interfaces/IHttpResponse.h"
#include "UHttpClient.generated.h"

// HTTP请求完成的委托
DECLARE_DYNAMIC_MULTICAST_DELEGATE_ThreeParams(FOnHttpRequestComplete, bool, bSuccess, const FString&, ResponseContent, int32, StatusCode);

// HTTP请求进度的委托（流式）- 增加错误信息
DECLARE_DYNAMIC_MULTICAST_DELEGATE_ThreeParams(FOnHttpRequestProgress, int32, BytesSent, int32, BytesReceived, const FString&, NewChunk);

/**
 * HTTP客户端，支持UnLua调用（优化的异步实现）
 */
UCLASS(Blueprintable, BlueprintType)
class DERDERCLIENT_API UHttpClient : public UObject
{
	GENERATED_BODY()
	
public:
	UHttpClient();
	
	// HTTP请求完成事件
	UPROPERTY(BlueprintAssignable, Category = "HTTP")
	FOnHttpRequestComplete OnRequestComplete;
	
	// HTTP请求进度事件（流式）
	UPROPERTY(BlueprintAssignable, Category = "HTTP")
	FOnHttpRequestProgress OnRequestProgress;
	
	/**
	 * 发送POST请求（完全异步）
	 * @param URL 请求URL
	 * @param Headers 请求头（格式："Key1=Value1|Key2=Value2"）
	 * @param Content 请求体内容
	 * @param Timeout 总超时时间（秒，0表示使用默认）
	 * @return 是否成功启动请求
	 */
	UFUNCTION(BlueprintCallable, Category = "HTTP")
	bool SendPostRequest(const FString& URL, const FString& Headers, const FString& Content, float Timeout = 300.0f);
	
	/**
	 * 取消当前请求
	 */
	UFUNCTION(BlueprintCallable, Category = "HTTP")
	void CancelRequest();
	
	/**
	 * 获取最后接收到的响应内容（用于流式）
	 */
	UFUNCTION(BlueprintCallable, Category = "HTTP")
	FString GetCurrentResponse() const;
	
	/**
	 * 获取已处理的字节数
	 */
	UFUNCTION(BlueprintCallable, Category = "HTTP")
	int32 GetProcessedBytes() const { return LastProcessedLength; }
	
	/**
	 * 检查请求是否正在进行
	 */
	UFUNCTION(BlueprintCallable, Category = "HTTP")
	bool IsRequestActive() const;
	
private:
	// HTTP请求对象
	TSharedPtr<IHttpRequest, ESPMode::ThreadSafe> CurrentRequest;
	
	// 当前累积的响应内容（用于流式）
	FString CurrentResponseContent;
	
	// 最后已处理的长度（避免重复处理）
	int32 LastProcessedLength;
	
	// 最后一次接收数据的时间（用于活动检测）
	double LastActivityTime;
	
	// 请求开始时间
	double RequestStartTime;
	
	// 请求完成回调（在GameThread上调用）
	void OnHttpRequestComplete(FHttpRequestPtr Request, FHttpResponsePtr Response, bool bSuccess);
	
	// 请求进度回调（优化的流式处理）
	void OnHttpRequestProgress(FHttpRequestPtr Request, int32 BytesSent, int32 BytesReceived);
	
	// 解析请求头字符串
	TMap<FString, FString> ParseHeaders(const FString& HeadersString);
	
	// 重置内部状态
	void ResetState();
};
