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

// HTTP请求进度的委托（流式）
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnHttpRequestProgress, int32, BytesSent, int32, BytesReceived);

/**
 * HTTP客户端，支持UnLua调用
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
	 * 发送POST请求
	 * @param URL 请求URL
	 * @param Headers 请求头（格式："Key1=Value1|Key2=Value2"）
	 * @param Content 请求体内容
	 * @param Timeout 超时时间（秒）
	 * @return 是否成功启动请求
	 */
	UFUNCTION(BlueprintCallable, Category = "HTTP")
	bool SendPostRequest(const FString& URL, const FString& Headers, const FString& Content, float Timeout = 60.0f);
	
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
	
private:
	// HTTP请求对象
	TSharedPtr<IHttpRequest, ESPMode::ThreadSafe> CurrentRequest;
	
	// 当前累积的响应内容（用于流式）
	FString CurrentResponseContent;
	
	// 最后记录的响应长度（用于计算增量）
	int32 LastResponseLength;
	
	// 请求完成回调
	void OnHttpRequestComplete(FHttpRequestPtr Request, FHttpResponsePtr Response, bool bSuccess);
	
	// 请求进度回调
	void OnHttpRequestProgress(FHttpRequestPtr Request, int32 BytesSent, int32 BytesReceived);
	
	// 解析请求头字符串
	TMap<FString, FString> ParseHeaders(const FString& HeadersString);
};
